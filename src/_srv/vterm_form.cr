require "../data/*"
require "../util/char_util"

class QT::VtermForm
  include JSON::Serializable

  getter key : String
  getter val : String

  getter ptag : String = ""
  getter prio : Int32 = 2

  getter dic : Int32 = 0
  getter tab : Int32 = 1

  def after_initialize
    old_key = key
    @key = @key.gsub(/[\p{C}\s]+/, " ").strip
    @key = CharUtil.to_canon(@key, upcase: true)

    # TODO: correct vietnamese tone marks
    @val = @val.gsub(/[\p{C}\s]+/, " ").strip.unicode_normalize(:nfkc)
    @val = @val.split(/[|ǀ]/, remove_empty: true).map!(&.strip).join('\t')

    @dic = -1 if @dic < 0
    @tab = 1 if @tab < 1
  end

  def save!(mtime = Zvterm.mtime) : Zvterm
    defn = Zvterm.new

    defn.dic = @dic
    defn.tab = @tab

    defn.key = @key
    defn.val = @val

    defn.ptag = @ptag
    defn.prio = @prio
    defn.mtime = mtime

    defn.tap(&.insert!)
  end
end
