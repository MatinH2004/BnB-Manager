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
       INNER JOIN tenants t ON a.id = t.apartment_id
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
           INNER JOIN tenants t ON t.apartment_id = a.id
           WHERE t.apartment_id = $1
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

  def add_apartment
  end

  def delete_apartment(id)
    sql = "DELETE FROM apartments WHERE id = $1"
    query(sql, id)
  end

  def edit_apartment
  end

  def add_tenant
  end

  def delete_tenant(id)
    sql = "DELETE FROM tenants WHERE id = $1"
    query(sql, id)
  end

  def edit_tenant
  end

  def disconnect
    @db.close
  end
end