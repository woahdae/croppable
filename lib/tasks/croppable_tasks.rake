desc "Setup croppable"
task "croppable:install" do
  Rails::Command.invoke :generate, ["croppable:install"]
end
