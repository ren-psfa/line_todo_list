class LineBotsController < ApplicationController
  require 'line/bot'
  protect_from_forgery with: :null_session
  # skip_before_action :verify_authenticity_token

  def callback
    # binding.pry
    # LINEで送られてきたメッセージを取得
    body = request.body.read
    # LINE以外からリクエストが来た場合、Errorを返す
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request and return
      # binding.pry
    end

    # LINEで送られてきたメッセージを適切な形式に変形
    events = client.parse_events_from(body)
    events.each do |event|
      # ユーザーIDを取得
      user_id = event["source"]["userId"]
      # binding.pry
      # 取得したユーザーIDをname に格納
      user = User.find_or_create_by(
        name: user_id
      )
      # binding.pry


      # LINEからテキストが送信された場合
      if (event.type === Line::Bot::Event::MessageType::Text)
        message = event["message"]["text"]
        # binding.pry
        # event.message["text"]で送られてきたメッセージを取得
        # それぞれの条件で、responseにメッセージを格納
        # binding.pry
        if event.message["text"].include?("一覧")
          # DBからタスクを全て取得
          tasks = user.tasks
          # 取得したデータを表示
          response =
          tasks.map.with_index do |task, i|
            "#{i+1}:" + task.body
            # binding.pry
          end
          response = response.join("\r\n") + "\r\n\r\nタスクを削除する場合は、番号 削除 と打ってください"
          # binding.pry
        elsif event.message["text"].include?("削除")
          # データを取得
          # データを配列にする findメソッドを使うため。
          index = message.to_i
          tasks = user.tasks.to_a
          # find メソッドで条件に合致するものを返す。
          # with_index を使って要素順でデータを取得する。
          task = tasks.find.with_index(1) {|task, i|index == i }
          binding.pry
          task.destroy!
          response = "タスクを削除しました"
            # messageに格納されている、LINEから送られてきたメッセージの中にtask.idがあるか判定
          #   if message.include?("#{task.id}")
          #     # binding.pry
          #     task.destroy
          #     response = "タスクが削除されました。"
          #   else
          #     response = "タスクがありません"
          #   end
          # end
        elsif event.message["text"].present?
            # タグの登録
            user.tasks.find_or_create_by!(
              body: message
            )
            response = "タスク:「#{message}」が登録されました。"
        end
        # binding.pry
        reply_message = {
          type: "text",
          text: response
        }
        client.reply_message(event["replyToken"], reply_message)
      end
    end














    # LINEの webhook API との連携をするために status cose 200 を返す。
    render json: { status: :ok }

  end


  private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      end
    end




end
