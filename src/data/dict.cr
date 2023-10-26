require "crorm"

class QT::Zvdict
  class_getter db_path = "data/dicts.db"
  class_getter init_sql = <<-SQL
    CREATE TABLE IF NOT EXISTS dicts (
      id integer PRIMARY KEY,
      --
      dname varchar NOT NULL,
      --
      label varchar NOT NULL DEFAULT '',
      brief text NOT NULL DEFAULT '',
      --
      privi integer NOT NULL DEFAULT 1,
      dtype integer NOT NULL DEFAULT 0,
      --
      term_total integer NOT NULL DEFAULT 0,
      term_avail integer NOT NULL DEFAULT 0,
      --
      main_terms integer NOT NULL DEFAULT 0,
      temp_terms integer NOT NULL DEFAULT 0,
      user_terms integer NOT NULL DEFAULT 0,
      --
      users text NOT NULL DEFAULT '',
      mtime integer NOT NULL DEFAULT 0
    );

    CREATE UNIQUE INDEX IF NOT EXISTS dicts_name_idx ON dicts (dname);
    CREATE INDEX IF NOT EXISTS dicts_size_idx ON dicts (term_total);
    CREATE INDEX IF NOT EXISTS dicts_time_idx ON dicts (mtime);
    SQL

  ######

  include Crorm::Model
  schema "dicts"

  field id : Int32, pkey: true

  field dname : String = ""

  field label : String = ""
  field brief : String = ""

  field privi : Int32 = 0
  field dtype : Int32 = 0

  field term_total : Int32 = 0
  field term_avail : Int32 = 0

  field main_terms : Int32 = 0
  field temp_terms : Int32 = 0
  field user_terms : Int32 = 0

  field users : String = ""
  field mtime : Int64 = 0

  def initialize(@id, @dname, @label = "", @brief = "", @privi = 1, @dtype = 0)
  end

  def bump_stats!(@mtime : Int64, @term_total : Int32)
    query = "update dicts set mtime = $1, term_total = $2 where id = $3"
    @@db.exec query, mtime, term_total, self.id!
  end

  def bump_stats!(@mtime : Int64)
    update_smt = <<-SQL
      update dicts set mtime = $1, term_total = term_total + 1 where id = $2
      returning term_total
      SQL

    @term_total = @@db.write_one(update_smt, mtime, @id, as: Int32)
  end

  def to_json(jb)
    {@dname, @label, @term_total, @brief}.to_json(jb)
  end

  ####

  DICT_IDS = {} of String => Int32

  def self.get_id(dname : String) : Int32
    DICT_IDS[dname] ||= begin
      query = "select id from dicts where dname = $1"
      self.db.query_one?(query, dname, as: Int32) || 0
    end
  end

  def self.get_dname(id : Int32) : String
    get!(id).dname rescue "combine"
  end

  CACHED = {} of Int32 => self

  def self.load(id : Int32)
    CACHED[id] ||= find_by_id!(id)
  end

  def self.load(dname : String)
    load(get_id(dname))
  end

  def self.find(dname : String) : self | Nil
    self.get(dname, &.<< " where dname = $1")
  end

  def self.find!(dname : String) : self
    self.get!(dname, &.<< " where dname = $1")
  end

  def self.count : Int32
    query = "select count(*) from #{@@schema.table} where term_total > 0"
    @@db.query_one(query, as: Int32)
  end

  def self.books_count : Int32
    query = "select count(*) from #{@@schema.table} where term_total > 0 and id > 0"
    @@db.query_one(query, as: Int32)
  end

  def self.all(limit : Int32, offset = 0) : Array(self)
    self.get_all limit, offset, &.<< " where term_total > 0 order by mtime desc limit $1 offset $2"
  end

  def self.all_cores
    self.get_all &.<< " where dtype = 0 or dtype = 1 order by id asc"
  end

  def self.all_books(limit : Int32, offset = 0)
    self.get_all limit, offset, &.<< " where id > 0 and term_total > 0 order by mtime desc limit $1 offset $2"
  end
end
