require "./_ctrl_base"

class QT::QtranCtrl < AC::Base
  base "/qtran"

  @[AC::Route::POST("/")]
  def qtran(wn_id : Int32 = 0, title : Int32 = 0)
    qcore = MtCore.init(wn_id)

    otext = String.build do |io|
      _read_body.split(/\R+/, remove_empty: true).each_with_index do |line, i|
        if title == 2 || (title == 1 && i == 0)
          qcore.cv_title(line).to_txt(io)
        else
          qcore.cv_plain(line).to_txt(io)
        end
      end
    end

    render text: otext
  end
end
