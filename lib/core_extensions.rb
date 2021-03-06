# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).

# There is a problem with $CACHE returning frozen objects.  The following two patches should fix it:
#
# https://rails.lighthouseapp.com/projects/8994/tickets/2860
# https://rails.lighthouseapp.com/projects/8994/tickets/2859
#
# Discussion about the problem:
# https://rails.lighthouseapp.com/projects/8994/tickets/2655-railscache-freezes-all-objects-passed-to-it

module ActiveReload
  class MasterDatabase < ActiveRecord::Base
    # This makes the MasterDatabase work as expected in the test and dev environments.
  end
end

module ActiveRecord
  class Base
    def dup
      obj = super
      obj.instance_variable_set('@attributes', instance_variable_get('@attributes').dup)
      obj
    end
  end
end

module ActiveSupport
  module Cache
    class MemoryStore < Store
      def write(name, value, options = nil)
        super
        # ORIGINAL: @data[name] = value.freeze
        # NEW:
        @data[name] = (value.duplicable? ? value.dup : value).freeze
      end
    end
  end

  class TimeWithZone
    def mysql_timestamp
      # 2010-12-31 03:50:09
      return strftime("%Y-%m-%d %H:%M:%S")
    end
    def solr_timestamp
      # 2010-12-31T03:50:09Z
      return strftime("%Y-%m-%dT%H:%M:%SZ")
    end
  end
end

class Time
  def mysql_timestamp
    # 2010-12-31 03:50:09
    return strftime("%Y-%m-%d %H:%M:%S")
  end
  def solr_timestamp
    # 2010-12-31T03:50:09Z
    return strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end



# This is a fix for EOLINFRASTRUCTURE-1606 ... NewRelic appears to be calling [] on a Nil somewhere, and this avoids the
# problem.
class NilClass
  def [](a,b=nil)
    return '[DATA MISSING]'
  end
  def balance_tags
    return nil
  end
end

class String

  # Note that I change strong to b, 'cause strong appears to be overridden in our CSS.  Hrmph.
  def allow_some_html
    # inline RegEx passed to gsub calls leak memory! We declare them first:
    @allowed_attributes_in_allow_some_html = /\s*\/|\s+href=['"][^'"]+['"]/
    start_tag   = /</
    end_tag     = />/
    line_breaks = /\r\n/
    text = self.gsub(start_tag, '&lt;')
    text.gsub!(end_tag, '&gt;')
    ['a', 'b', 'blockquote', 'br', 'em', 'i', 'p', 'small', 'strong', 'cite'].each do |tag|
      tag_regex = /&lt;(\/)?#{tag}(#{@allowed_attributes_in_allow_some_html})?\s*&gt;/i
      text.gsub!(tag_regex, "<\\1#{tag.gsub(/strong/, 'b')}\\2>")
    end
    return text.gsub(line_breaks, '<br/>')
  end

  def firstcap
    @firstcap_regex = /^(<[^>]*>)?(['"])?([^ ]+)( |$)/
    self.gsub(@firstcap_regex) { $1.to_s + $2.to_s + $3.capitalize + $4 }
  end

  def firstcap!
    @firstcap_regex = /^(<[^>]*>)?(['"])?([^ ]+)( |$)/
    self.gsub!(@firstcap_regex) { $1.to_s + $2.to_s + $3.capitalize + $4 }
  end


  #  old list from gem:
  # [ 'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col', 'colgroup', 'dd', 'dl', 'dt', 'em', 'embed', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'i', 'img', 'li', 'ol', 'p', 'pre', 'q', 'small', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr', 'u', 'ul' ],
  # more full list:
  def appropriate_html_tags
    ['address', 'applet', 'area', 'a', 'base', 'basefont', 'big', 'blockquote', 'br', 'b', 'caption', 'center', 'cite', 'code', 'dd', 'dfn', 'dir', 'div', 'dl', 'dt', 'em', 'embed', 'font', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'img', 'input', 'isindex', 'i', 'kbd', 'link', 'li', 'map', 'menu', 'meta', 'ol', 'option', 'param', 'pre', 'p', 'samp', 'script', 'select', 'small', 'span', 'strike', 'strong', 'style', 'sub', 'sup', 'table', 'td', 'textarea', 'th', 'title', 'tr', 'tt', 'ul', 'u', 'var', 'legend', 'fieldset']
  end

  # this method is designed to make sure a text string has equal numbers of opening and closing forms of certain
  # tags in the proper order (shouln't open one after closing one for example - that is not balanced)
  def balance_tags
    text = self.clone
    ['b', 'i', 'div', 'p'].each do |tag|
      # this will match <T_, <T>, </_T>, </T>
      open_and_close_tags = text.scan(/\<(#{tag}[\> ]|\/ *#{tag}\>)/)
      number_of_opening_tags_needed = 0
      total_open = 0
      total_closed = 0
      current_balance = 0
      previous_balance = 0
      open_and_close_tags.each do |match|
        t = match[0]
        if t[0, 1] == "/"  # its a closing tag
          total_closed += 1
          current_balance -= 1
        else
          total_open += 1
          current_balance += 1
        end

        if current_balance < 0 && current_balance < previous_balance
          number_of_opening_tags_needed += 1
          current_balance += 1
        end
        previous_balance = current_balance
      end
      # adding to the beginning opening tags if there are close tags before open tags of the same type
      text = "<#{tag}>" * number_of_opening_tags_needed + text
      total_open += number_of_opening_tags_needed

      difference = total_open - total_closed
      if difference < 0  # more closed tags than open
        text = "<#{tag}>" * difference.abs + text
      elsif difference > 0  # more open tags than closed
        text += "</#{tag}>" * difference
      end
    end
    return text.gsub(/<em\/>/, '')
  end

  def truncate(length)
    if self.length >= length
      self[0..length-1] + "..."
    else
      self
    end
  end

  def remove_diacritics
    self.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s
  end

  def word_count
    split(/ /).length
  end

  def is_numeric?
    begin
      Float(self)
    rescue
      false # not numeric
    else
      true # numeric
    end
  end

  def is_int?
    begin
      Integer(self)
    rescue
      false # not numeric
    else
      true # numeric
    end
  end

  def cleanup_for_presentation
    self.gsub(/[_]{20,}/, ' ')
  end

end

class Array

  # some methods on Hash return an Array like [ [key,value], [key,value] ] instead
  # of returning a Hash.  this turns an Array of that style back into a Hash.
  def hashify
    inject({}) do |all,this|
      all[this.first] = this.last
      all
    end
  end

  # expects an array of Hashes
  # [ {'id' => 1 , 'label' => first},
  #   {'id' => 2 , 'label' => first}]
  # will create a new array where $attribute is unique by taking the first instance and deleting the rest
  # mimics some of what the MySQL GROUP BY does
  def group_hashes_by!(attribute)
    used_values = []
    hashes_to_delete = []
    self.each_with_index do |h, index|
      hashes_to_delete << h if used_values.include?(h[attribute])
      used_values << h[attribute]
    end
    for h in hashes_to_delete
      self.delete(h)
    end
  end

  # expects an array of objects
  # will create a new array where $attribute is unique by taking the first instance and deleting the rest
  # mimics some of what the MySQL GROUP BY does
  def group_objects_by(attribute)
    grouped_array = []
    used_values = {}
    self.each do |obj|
      value = obj.send(attribute.to_sym)
      grouped_array << obj if used_values[value].blank?
      used_values[value] = true
    end
    grouped_array
  end

end

class Hash

  # does the same as Array#hashify.
  #
  # assumes an Array like [ [key,value], [key,value] ]
  def self.from_array array
    array.hashify
  end

  # creates an entirely new Hash with new keys and values with the same information but not pointing
  # to the same place in memory. For some reason neither Hash.dup nor Hash.clone were making a true deep copy
  def deepcopy
    Marshal::load(Marshal::dump(self))
  end


end

class ActiveRecord::Migration
  def self.not_okay_in_production
    # Perhaps not the right error class to throw, but I'm not aware of good alternatives:
    raise ActiveRecord::IrreversibleMigration.new("It is not okay to run this migration on a production database.") if
      $PRODUCTION_MODE
  end
end


# I need this to sanitize SQL into strings:
class << ActiveRecord::Base
  public :sanitize_sql_array
end

module ActiveRecord
  class Base
    class << self

      # returns the full table name of this ActiveRecord::Base,
      # including the database name.
      #
      #   >> User.full_table_name
      #   => "eol_development.users"
      #
      def full_table_name
        database_name + '.' + table_name
      end

      # returns a hash of configuration variables for this ActiveRecord::Base's connection adapter
      def database_config
        # in production, we have a ConnectionProxy with many adapters
        # otherwise #connection directly returns the adapter
        adapter = self.connection.instance_eval { @current } || self.connection
        adapter.instance_eval { @config }
      end

      def reset_database_name
        @database_name = nil
      end

      # returns the name of the database for this ActiveRecord::Base
      def database_name
        @database_name ||= self.connection.execute('select database()').fetch_row[0]
      end

      def reload
        self.with_master do
          super
        end
      end

    end

    def self.with_master(&block)
      if self.connection.respond_to? 'with_master'
        self.connection.set_to_master!
        something = yield
        self.connection.set_to_slave!
        something
      else
        yield
      end
    end
  end

  module ConnectionAdapters
    class MysqlAdapter
      def config
        return @config
      end

      def command_line_parameters
        mysql_params = "--host='#{@config[:host]}' --user='#{@config[:username]}' --password='#{@config[:password]}'"
        mysql_params += " --port='#{@config[:port]}'" unless @config[:port].blank?
        mysql_params += " --default-character-set='#{@config[:encoding]}'" unless @config[:encoding].blank?
        return mysql_params
      end
    end
  end
end


class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end

# We don't want the code poking around ifconfig (that's dangerous), and we don't mind terribly if this is random:
module Mac
  def self.addr
    addr = (0..5).map { sprintf("%02x", rand(256)) }.join(':')
  end
  def self.address
    addr = (0..5).map { sprintf("%02x", rand(256)) }.join(':')
  end
end
