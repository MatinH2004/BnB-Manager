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

  def all_apartments
    sql = <<~SQL
    SELECT a.id,
           a.name,
           a.address, 
           COUNT(t.apartment_id) AS tenants 
    FROM apartments a
    LEFT JOIN tenants t ON a.id = t.apartment_id
    GROUP BY a.id, a.name, a.address
    ORDER BY a.name;
    SQL
    result = query(sql)

    result.map do |tuple|
      {
        id: tuple["id"],
        name: tuple["name"],
        address: tuple["address"],
        tenants: tuple["tenants"]
      }
    end
  end

  def find_apartment(apartment_id)
    sql = <<~SQL
    SELECT a.id AS apartment_id,
           a.name AS apartment_name,
           a.address,
           t.id AS tenant_id,
           t.name AS tenant_name,
           rent
    FROM apartments a
    LEFT JOIN tenants t ON t.apartment_id = a.id
    WHERE a.id = $1
    ORDER BY tenant_name;
    SQL
    result = query(sql, apartment_id)

    result.map do |tuple|
      {
        apartment_id: tuple["apartment_id"],
        apartment_name: tuple["apartment_name"],
        apartment_address: tuple["address"],
        tenant_id: tuple["tenant_id"],
        tenant_name: tuple["tenant_name"],
        tenant_rent: tuple["rent"]
      }
    end
  end

  def apartment_details(id)
    sql = "SELECT * FROM apartments WHERE id = $1"
    result = query(sql, id)

    result.map do |tuple|
      {
        id: tuple[:id],
        name: tuple["name"],
        address: tuple["address"]
      }
    end.first
  end

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

  def tenant_details(id)
    sql = "SELECT name, rent FROM tenants WHERE id = $1"
    result = query(sql, id)

    result.map do |tuple|
      {
        name: tuple["name"],
        rent: tuple["rent"]
      }
    end.first
  end

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

  def disconnect
    @db.close
  end
end