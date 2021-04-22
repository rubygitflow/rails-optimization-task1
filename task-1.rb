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
    'date' => Date.parse(cols[5])
  }
end

def work(filename = 'data.txt', disable_gc: true)
  GC.disable if disable_gc

  users = []
  sessions = {}
  uniqueBrowsers = []

  puts("#{Time.now} Чтение данных") if ENV['PRINT_STATUS']=='TRUE' 

  File.open(ENV['DATA_FILE'] || filename, 'r').each do |line|
    cols = line.split(',')
    users = users + [parse_user(cols)] if cols[0] == 'user'
    if cols[0] == 'session'
      cols[3].upcase!
      sessions[cols[1]] ||= []
      sessions[cols[1]] << parse_session(cols)
      uniqueBrowsers << cols[3]
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
    parts_of_work = users.count
    progressbar = ProgressBar.create(
      total: parts_of_work,
      format: '%a, %J, %E %B' # elapsed time, percent complete, estimate, bar
    )
  end

  users.each do |user|
    user_sessions = sessions[user['id']]
    user_key = "#{user['first_name']}" + ' ' + "#{user['last_name']}"
    user_sessions_map_time = user_sessions.map {|s| s['time']}
    user_sessions_map_browser = user_sessions.map {|s| s['browser']}.sort
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(
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
      { 'dates' => user_sessions.map{|s| s['date']}.sort.reverse.map { |d| d.iso8601 } }
    )
    progressbar.increment if ENV['PRINT_STATUS']=='TRUE'
  end

  puts("#{Time.now} Сохранение отчета") if ENV['PRINT_STATUS']=='TRUE' 
  File.write('result.json', "#{report.to_json}\n")
end
