# Deoptimized version of homework task
require 'json'
require 'pry'
require 'date'
require 'set'

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(cols)
  {
    'id' => cols[1],
    'first_name' => cols[2],
    'last_name' => cols[3],
    'age' => cols[4],
  }
end

def parse_session(cols)
  {
    'user_id' => cols[1],
    'session_id' => cols[2],
    'browser' => cols[3],
    'time' => cols[4].to_i,
    'date' => cols[5],
  }
end

def collect_stats_from_users(report, users_objects)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    user_sessions_map_time = user.sessions.map {|s| s['time']}
    user_sessions_map_browser = user.sessions.map {|s| s['browser']}.sort
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(
      # Собираем количество сессий по пользователям
      { 'sessionsCount' => user.sessions.count },
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
      { 'dates' => user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 } }
    )
  end
end

def work(filename = 'data.txt', disable_gc: true)
  GC.disable if disable_gc
  file_lines = File.read(ENV['DATA_FILE'] || filename).split("\n")

  users = []
  sessions = {}
  uniqueBrowsers = Set[]

  file_lines.each do |line|
    cols = line.split(',')
    users = users + [parse_user(cols)] if cols[0] == 'user'
    if cols[0] == 'session'
      cols[3].upcase!
      sessions[cols[1]] ||= []
      sessions[cols[1]] << parse_session(cols)
      uniqueBrowsers.add(cols[3])
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

  report = {}

  report[:totalUsers] = users.count

  # Преобразование наименований и списка браузеров
  browsersList = uniqueBrowsers.to_a.sort

  # Подсчёт количества уникальных браузеров
  report['uniqueBrowsersCount'] = browsersList.count

  report['totalSessions'] = sessions.values.flatten.count

  report['allBrowsers'] = browsersList.join(',')

  # Статистика по пользователям
  users_objects = []

  users.each do |user|
    users_objects << User.new(attributes: user, sessions: sessions[user['id']])
  end

  report['usersStats'] = {}

  collect_stats_from_users(report, users_objects)

  File.write('result.json', "#{report.to_json}\n")
end
