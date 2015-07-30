root = "/Users/umeng/RailsProjects/test_rails4"
working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"

listen "/tmp/unicorn.test_rails4.sock"
worker_processes 4
timeout 30
