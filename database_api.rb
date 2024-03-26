require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "bnb_manager")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  # Return all apartments and its tenant count
  def all_apartments(offset: 0, limit: 5)
    sql = <<~SQL
    SELECT a.id,
           a.name,
           a.address, 
           COUNT(t.apartment_id) AS tenants 
    FROM apartments a
    LEFT JOIN tenants t ON a.id = t.apartment_id
    GROUP BY a.id, a.name, a.address
    ORDER BY a.name
    OFFSET $1 LIMIT $2;
    SQL
    result = query(sql, offset, limit)

    result.map do |tuple|
      {
        id: tuple["id"],
        name: tuple["name"],
        address: tuple["address"],
        tenants: tuple["tenants"]
      }
    end
  end

  # Return all tenants for the specified apartment id
  def all_tenants(offset: 0, limit: 5, id: nil)
    sql = <<~SQL
    SELECT t.id,
           t.name,
           t.rent
    FROM apartments a
    LEFT JOIN tenants t ON t.apartment_id = a.id
    WHERE a.id = $1
    ORDER BY t.name
    OFFSET $2 LIMIT $3;
    SQL
  
    result = query(sql, id, offset, limit)
    result.map do |tuple|
      {
        id: tuple["id"],
        name: tuple["name"],
        rent: tuple["rent"]
      }
    end
  end

  # Return apartment details
  def fetch_apartment(id)
    sql = "SELECT * FROM apartments WHERE id = $1"
    result = query(sql, id)
  
    result.map do |tuple|
      {
        id: tuple["id"],
        name: tuple["name"],
        address: tuple["address"]
      }
    end.first
  end

  # Return tenant details
  def fetch_tenant(id, apartment_id)
    sql = "SELECT name, rent FROM tenants WHERE id = $1 AND apartment_id = $2"
    result = query(sql, id, apartment_id)

    result.map do |tuple|
      {
        name: tuple["name"],
        rent: tuple["rent"]
      }
    end.first
  end

  def total_apartment_count
    sql = "SELECT COUNT(id) FROM apartments"
    result = query(sql)
    result.first["count"].to_i
  end

  def total_tenant_count(id)
    sql = "SELECT COUNT(id) FROM tenants WHERE apartment_id = $1"
    result = query(sql, id)
    result.first["count"].to_i
  end

  def monthly_revenue(id)
    sql = "SELECT SUM(rent) FROM tenants WHERE apartment_id = $1"
    result = query(sql, id)
    result.first["sum"].to_i
  end

  # Apartment modification methods

  def new_apartment(name, address)
    sql = "INSERT INTO apartments (name, address) VALUES ($1, $2)"
    query(sql, name, address)
  end

  def delete_apartment(id)
    sql = "DELETE FROM apartments WHERE id = $1"
    query(sql, id)
  end

  def edit_apartment(name, address, id)
    sql = <<~SQL
    UPDATE apartments
    SET "name" = $1, 
        "address" = $2 
    WHERE id = $3;
    SQL
    result = query(sql, name, address, id)
  end

  # Tenant modification methods

  def new_tenant(name, rent, apartment_id)
    sql = "INSERT INTO tenants (name, rent, apartment_id) VALUES ($1, $2, $3)"
    query(sql, name, rent, apartment_id)
  end

  def delete_tenant(apartment_id, tenant_id)
    sql = "DELETE FROM tenants WHERE id = $1 AND apartment_id = $2"
    query(sql, tenant_id, apartment_id)
  end

  def edit_tenant(name, rent, id)
    sql = <<~SQL
    UPDATE tenants
    SET "name" = $1,
        "rent" = $2
    WHERE id = $3;
    SQL
    result = query(sql, name, rent, id)
  end

  # Teardown code

  def disconnect
    @db.close
  end
end