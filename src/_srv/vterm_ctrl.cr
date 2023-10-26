require "./_ctrl_base"
require "./vterm_form"

class QT::VtermCtrl < AC::Base
  base "/terms"

  @[AC::Route::POST("/", body: :form)]
  def create(form : VtermForm)
    defn = form.save!

    rebuild_trie(defn)
    update_stats(defn)

    render json: defn
  end

  private def rebuild_trie(defn : Zvterm)
    case defn.tab
    when 0, 1 # add to main dict
      MtDict::MAINS[defn.dic]?.try(&.add_defn(defn))
    when 2, 3 # add to user dict
      MtDict::USERS["#{defn.dic}/#{defn.uname}"]?.try(&.add_defn(defn))
    end
  end

  private def update_stats(defn : Zvterm)
    Zvdict.load(defn.dic).bump_stats!(defn.mtime)
  rescue ex
    Log.error { ex.message }
  end
end
