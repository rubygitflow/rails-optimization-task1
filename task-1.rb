# Deoptimized version of homework task
require 'json'
require 'pry'
require 'date'
require 'ruby-progressbar'

def parse_user(cols)
  {
    'id' => cols[1],
    'first_name' => cols[2],
    'last_name' => cols[3],
    'age' => cols[4]
  }
end

def parse_session(cols)
  {
    'user_id' => cols[1],
    'session_id' => cols[2],
    'browser' => cols[3],
    'time' => cols[4].to_i,
    'date' => cols[5][0...-1]
  }
end

def work(filename = 'data.txt', disable_gc: true)
  GC.disable if disable_gc

  users = []
  sessions = {}
  uniqueBrowsers = []
  file_name = ENV['DATA_FILE'] || filename

  puts("#{Time.now} Чтение данных") if ENV['PRINT_STATUS']=='TRUE' 

  if ENV['PRINT_STATUS']=='TRUE' 
    lines_count = `wc -l "#{file_name}"`.split.first.chomp.to_i # 
    puts("lines_count=#{lines_count}") 
    if lines_count>100 
      parts_of_work_inp = 100
      tile_inp =  lines_count / parts_of_work_inp + 1
    else
      parts_of_work_inp = lines_count
      tile_inp = 0
    end
    progressbar_inp = ProgressBar.create(
      total: parts_of_work_inp,
      format: '%a, %J, %E %B' # elapsed time, percent complete, estimate, bar
    )
  end

  inp = 0
  File.open(file_name, 'r').each_line do |line|
    cols = line.split(',')
    case cols[0]
    when 'user'
      users << parse_user(cols)
    when'session'
      cols[3].upcase!
      sessions[cols[1]] ||= []
      sessions[cols[1]] << parse_session(cols)
      uniqueBrowsers << cols[3]
    end  
    if progressbar_inp
      if tile_inp == 0 
        progressbar_inp.increment 
      elsif (inp % tile_inp) == 0
        progressbar_inp.increment 
      end
      inp += 1 
    end
  end

  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +

  puts("#{Time.now} Построение отчета") if ENV['PRINT_STATUS']=='TRUE' 

  report = {}

  report[:totalUsers] = users.count

  # Преобразование наименований и списка браузеров
  browsersList = uniqueBrowsers.uniq.sort

  # Подсчёт количества уникальных браузеров
  report['uniqueBrowsersCount'] = browsersList.count

  report['totalSessions'] = sessions.values.flatten.count

  report['allBrowsers'] = browsersList.join(',')

  report['usersStats'] = {}

  if ENV['PRINT_STATUS']=='TRUE'
    puts("users.count=#{users.count}") 
    if users.count>100 
      parts_of_work_out = 100
      tile_out =  users.count / parts_of_work_out + 1
    else
      parts_of_work_out = users.count
      tile_out = 0
    end

    progressbar_out = ProgressBar.create(
      total: parts_of_work_out,
      format: '%a, %J, %E %B' # elapsed time, percent complete, estimate, bar
    )
  end

  out = 0
  users.each do |user|
    user_sessions = sessions[user['id']]
    user_key = "#{user['first_name']} #{user['last_name']}"

    user_sessions_map_time = user_sessions.map {|s| s['time']}
    user_sessions_map_browser = user_sessions.map {|s| s['browser']}.sort
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key].merge!(
      # Собираем количество сессий по пользователям
      { 'sessionsCount' => user_sessions.count },
      # Собираем количество времени по пользователям
      { 'totalTime' => user_sessions_map_time.sum.to_s + ' min.' },
      # Выбираем самую длинную сессию пользователя
      { 'longestSession' => user_sessions_map_time.max.to_s + ' min.' },
      # Браузеры пользователя через запятую
      { 'browsers' => user_sessions_map_browser.join(', ') },
      # Хоть раз использовал IE?
      { 'usedIE' => user_sessions_map_browser.any? { |b| b =~ /INTERNET EXPLORER/ } },
      # Всегда использовал только Chrome?
      { 'alwaysUsedChrome' => user_sessions_map_browser.all? { |b| b =~ /CHROME/ } },
      # Даты сессий через запятую в обратном порядке в формате iso8601
      { 'dates' => user_sessions.map{|s| s['date']}.sort.reverse }
    )
    if progressbar_out
      if tile_out == 0 
        progressbar_out.increment 
      elsif (out % tile_out) == 0
        progressbar_out.increment 
      end
      out += 1 
    end
  end

  puts("#{Time.now} Сохранение отчета") if ENV['PRINT_STATUS']=='TRUE' 
  File.write('result.json', "#{report.to_json}\n")
end
