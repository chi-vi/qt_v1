require "./_ctrl_base"

class QT::QtranCtrl < AC::Base
  base "/qtran"

  @[AC::Route::POST("/")]
  def qtran(wn_id : Int32 = 0, title : Int32 = 0)
    input = request.body.try(&.gets_to_end) || ""
    lines = input.split(/\R/, remove_empty: true)

    otext = String.build do |io|
      qcore = MtCore.init(wn_id)
      lines.each_with_index do |line, i|
        line = line.strip
        if title == 2 || (title == 1 && i == 0)
          qcore.cv_title(line).to_txt(io)
        else
          qcore.cv_plain(line).to_txt(io)
        end
      end
    end

    render text: otext
  rescue ex
    Log.error(exception: ex) { ex.message }
    render 500, ex.message
  end
end
