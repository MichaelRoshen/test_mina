# test_mina


启动：
./config/unicorn_init.sh stop
./config/unicorn_init.sh start
./config/unicorn_init.sh restart


什么是unicorn?
1. 为 Rack 应用程序设计的 HTTP server
2. 是一个利用Unix的高级特性开发的
3. 为具备低延迟，高带宽的连接的客户服务
4. 类似的工具有 passenger, thin 等。

unicorn原理：
它的工作模式是master/worker多进程模式。 简单地说， 首先建立一个master进程， 然后fork出来worker进程。worker进程处理进来的请求，master负责管控，当worker消耗内存过多，或者相应时间太长， 杀掉worker进程。

unicorn特性：
1. 为 Rack， Unix， 快速的客户端和易调试而设计。
2. 完全兼容 Ruby 1.8 和 1.9。
3. 进程管理：Unicorn会获取和重启因应用程序出错导致死亡的任务，不需要自己管理多个进程和端	   口。Unicorn 可以产生和管理任何数量的任务进程。
4. 负载均衡完全由操作系统(Unix)核心完成。在繁忙的任务进程时，请求也不会堆积。
5. 不需要关心应用程序是否是线程安全的，workers运行在特们自己独立的地址空间，且一次只为一
   个客户端服务。
6. 支持所有的 Rack 应用程序。
7. 使用 USR1 信号来固定重复打开应用程序的所有日志文件。Unicorn也可以逐步的确定一个请求的
   多行日志放在同一个文件中。
8. nginx 式的二进制升级，不丢失连接。你可以升级 Unicorn、你的整个应用程序、库、甚至 
   Ruby 编辑器而不丢失客户端连接。
9. 在 fork 进程时如果由特殊需求可以使用 before_fork 和 after_
   fork。如果“preload_app“ 为 false 时，则不能使用。
10. 可以使用 copy-on-wirte-friendly 内存管理来节约内容（通过设置 “preload_app" 
   为true ）。
11. 可以监听多接口，包括：UNIX sockets，每个 worker process 也可以在简单调试时通过 
   after_fork 钩子绑定到私有的端口。
12. 配置使用简单易用的 Ruby DSL。


unicorn配置：
# -*- coding: utf-8 -*-
rails_env = ENV['RAILS_ENV'] || 'production'
# 需要设置一下rail的路径
RAILS_ROOT = "/rails/path"

# 设置生产和开发环境下面跑的worker数量
worker_processes (rails_env == 'production' ? 16 : 4)

# rails环境是需要预先加载的， 节省时间和内存
preload_app true

# 每个请求最长的响应时间， 超过了就杀掉worker
timeout 30

# 监听端口设置， 可以设置成unix socket或者tcp， 这里是用tcp, 因为开发环境可以直接看网站
# listen '/data/github/current/tmp/sockets/unicorn.sock', :backlog => 2048
listen 8080, backlog: 2048

after_fork do |server, worker|
  # fork了之后， 原先开启的socket就不能用了， 重新开启
  ActiveRecord::Base.establish_connection
  # Redis 和 Memcached 的连接是按需的， 不需要重新开启
end

这里是实现重启的时候无缝衔接的代码。首先unicorn提供了这样一个机制：
当我们发送 USR2 信号给master的时候， unicorn就会把旧的pidfile加上.oldbin后缀，
然后启动一个新的master， 新的master也会fork worker出来。
下面的代码就是当新的master起来的时候， 检查oldbin这个文件， 告诉旧的master退出（发送QUIT信号）。这样我们保证了无缝重启。

before_fork do |server, worker|
  old_pid = RAILS_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

参数说明：
1. unicorn 会默认绑定到8080端口，可以使用 --listen/-l 来选择到不同的 address:port 或者使用 UNIX socket.
2. -D 以Deamon 形式启动
3. -c 设定配置文件，如我们的 /workspace/project_name/config/unicorn.rb
4. -E 设定生产环境或开发环境，如 -E production



