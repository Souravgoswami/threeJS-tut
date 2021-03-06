#!/usr/bin/env ruby
# Frozen_String_Literal: true

# User Modifiable:
$-v = true

# Extensions to watch for.
# This value will get replaced if:
#    1. the --watch=ext1,ext2 argument is used.
#    2. the -w=ext1,ext2 argument is used.
# Where ext1,ext2 stands for the extensions.
# for example -w=html,html.erb
EXT = %w(html.erb html)

# Output file name
OUTPUT_FILE = File.join(__dir__, 'index.html')

# Code:
%w(io/console webrick erb).each(&method(:require))
COLOUR_SUCCESS = "\e[1;38;2;0;165;45m"
COLOUR_INFO = "\e[1;38;2;255;255;0m"
COLOUR_ERROR = "\e[1;38;2;215;80;90m"
COLOUR_WARNING = "\e[1;38;2;255;180;0m"
COLOUR_PRIMARY = "\e[1;38;2;0;125;255m"

arg_ext = ARGV.select { |x| x[/^\-(\-watch)|(w)=.*$/] }[-1].to_s.split(?=)[1].to_s.split(?,)
EXT.replace(arg_ext) unless arg_ext.empty?

def minify!(lines)
	output = []
	state1 = state2 = false

	lines.each do |x|
		x.strip!
		reject_conditions = x[/^<\s*!\s*--.*--\s*>$/]

		unless reject_conditions
			if state1
				output.push(output.pop << x)
			elsif state2
				output.push(output.pop << ?\s << x)
			else
				output.push(x)
			end

			state1 = x[/^.*<\s*\/?.*>$/]
			state2 = x[/^<.*$/] && !x[/>/]
		end
	end

	output
end

def print_help
	puts <<~EOF
		This program generates html or html.erb (embedded ruby) codes primarily.
		Run this program without any argument and go to the given port for another manual
		in case this isn't much clear to you!

		This program might come in handy when:
			1. You have multiple html files and you are working on one
			2. You don't want to switch browser tabs on and avoid opening multiple files

		The reasons are:
			1. When run this program it will  watch for the files (default html, html.erb).
			2. When it matches the files, it will compile it and write the contents to
			index.html in the root directory of the project (currently #{__dir__}.
			3. It also initiates WEBRick server, so, open 0.0.0.0:port
			(8080, or provided by this program if 8080 is busy) to get render your
			recently saved pages.

		This program saves a lot of hassles, and makes learning web development easier.
	EOF

	exit
end

print_help if ARGV.any? { |x| x[/^\-(\-help)|h$/] }

def compile(string, file)
	<<~EOF
		<!Doctype HTML>
		<html>
		<!-- This file is generated by #{File.basename(Process.argv0)} -->
		<!-- Read #{file} for source code. -->
		#{string}
		</html>
	EOF
end

def get_files(dir = __dir__)
	Dir["#{dir}/**/*.{#{EXT.join(?,)}}"].tap do |x|
		x.reject! { |x| File.dirname(x) == dir && File.split(x)[-1] == File.split(OUTPUT_FILE)[-1] }
	end
end

def first_run_html(f = File.basename(Process.argv0), emojis)
	<<~EOF.delete(?\n)
		<head><meta charset="utf-8"><title>Welcome to #{f}</title><style>
		::selection {background-color: #0a0;color: #fff}
		body {height: 100vh;display: flex;justify-content: center;align-items: center;
		flex-direction: column}
		h2, .text {background: linear-gradient(45deg, #fa0, #f55, #f5f, #55f);-webkit-background-clip: text;
		color: transparent} .btn {transition: all 0.25s ease;
		position: relative;text-decoration: none;font-size: 20px;color: #912BFF;
		padding: 10px 20px;border: 3px solid #912BFF;border-radius: 4px;cursor: pointer;
		overflow: hidden;background-color: transparent}
		.btn::before {z-index: 1;content: attr(data-content);color: #fff;display: flex;
		align-items: center;justify-content: center;position: absolute;top: 0;
		left: 0;width: 100%;height: 100%;
		background-color: #912BFF;transition: all 0.25s ease;transform: scale(5);opacity: 0}
		.btn:hover {filter: drop-shadow(4px 4px 2px #2225)}
		.rotate {animation: rotate 2s ease-in-out infinite;display: inline-block}
		@keyframes rotate {100% {transform: rotate(0deg)} 0% {transform: rotate(360deg)}}
		.btn:hover::before {transform: scale(1.0125);opacity: 1;filter: blur(0px)}
		#x {background-color: #fff;border-radius: 4px;filter: drop-shadow(0px 0px 6px #22222266);
		transition: all 0.25s ease;margin-bottom: 20px} #x:hover {filter: drop-shadow(4px 4px 6px #222222aa)}
		#w {margin: 20px;max-width: 75vw} .btn:active::before,
		.btn:focus::before {background-color: #00A32C} .btn:active, .btn:focus {border-color: #00A32C;color: #f55 }
		</style></head><body><div id="x"><div id="w"><h2>This dummy file is generated by #{f}</h2>
		<p>#{emojis.shift} <span class="text">Please create a file with .#{EXT.join(', ')} extension#{EXT.length == 1 ? '' : 's'} to reload it on the browser.</span></p>
		<p>#{emojis.shift} <span class="text">You can create the file in #{__dir__}/</span></p>
		<p>#{emojis.shift} <span class="text">But remember to have #{EXT.join(' or ')} extension.</span></p>
		<p>#{emojis.shift} <span class="text">This is handy when you are creating lots of html files and want to test them out.</span></p>
		<p>#{emojis.shift} <span class="text">Just remember to place your stylesheets, js files, assets, and other stuff in the #{__dir__}/</span></p>
		<p>#{emojis.shift} <span class="text">I am watching for files! Please reload the page once you are done!</span></p>
		<center><button class="btn" href="#" data-content="Reload" onclick="window.location.reload()">
		<span class="rotate">&#x2B6F;</span>&nbsp;Reload</button></center>
		</div></div></body>
	EOF
end

def error_html(file, e)
	<<~EOF.delete(?\n)
		<head><meta charset="utf-8"><title>Welcome to #{File.basename(Process.argv0)}</title><style>
		::selection {background-color: #f55;color: #fff}
		h2 { color: #f55 } pre.code .code {white-space: pre-wrap ; background-color: #55f5}
		pre.code::before {counter-reset: listing} pre.code code {counter-increment: listing}
		pre.code code::before { content: counter(listing) '. ' ; display: inline-block ; margin-right: 8px ; }
		body {height: 100vh;display: flex;justify-content: center;align-items: center;
		flex-direction: column} .btn {transition: all 0.25s ease;
		position: relative;text-decoration: none;font-size: 20px;color: #912BFF;
		padding: 10px 20px;border: 3px solid #912BFF;border-radius: 4px;cursor: pointer;
		overflow: hidden;background-color: transparent}
		.btn::before {z-index: 1;content: attr(data-content);color: #fff;display: flex;
		align-items: center;justify-content: center;position: absolute;top: 0;
		left: 0;width: 100%;height: 100%;
		background-color: #912BFF;transition: all 0.25s ease;transform: scale(5);opacity: 0}
		.btn:hover {filter: drop-shadow(4px 4px 2px #2225)}
		.rotate {animation: rotate 2s ease-in-out infinite;display: inline-block}
		@keyframes rotate {100% {transform: rotate(0deg)} 0% {transform: rotate(360deg)}}
		.btn:hover::before {transform: scale(1.0125);opacity: 1;filter: blur(0px)}
		#x {background-color: #fff;border-radius: 4px;filter: drop-shadow(0px 0px 6px #22222266);
		transition: all 0.25s ease;margin-bottom: 20px} #x:hover {filter: drop-shadow(4px 4px 6px #222222aa)}
		#w {margin: 20px;max-width: 75vw} .btn:active::before,
		.btn:focus::before {background-color: #00A32C} .btn:active,
		.btn:focus {border-color: #00A32C;color: #f55 }</style></head><body><div id="x">
		<div id="w"><h2>Error Occurred When Trying to Process #{file}</h2><pre class="code">
		#{e.to_s.each_line.map.with_index { |x, i|%Q[<code>#{x}</code>]}.join('<br>')}
		</pre><center><button class="btn" href="#" data-content="Reload" onclick="window.location.reload()">
		<span class="rotate">&#x2B6F;</span>&nbsp;Reload</button></center>
		</div></div><script>
		for(let i of document.getElementsByClassName('code')) i.innerHTML=i.innerHTML.replace(/^\\s+/mg, '')
		</script></body>
	EOF
end

def init
	unless File.exist?(OUTPUT_FILE)
		emojis = %W(
			\xF0\x9F\x90\xB9 \xF0\x9F\x90\xAD \xF0\x9F\x90\xB1
			\xF0\x9F\x90\xA3 \xF0\x9F\x90\xB5 \xF0\x9F\x90\xBC
		).map! { |x| "&#x#{x.dump[3..-2].delete('{}')};" }.shuffle!

		IO.write(OUTPUT_FILE, first_run_html(emojis))
	end

	n_files = get_files.count
	puts "#{COLOUR_PRIMARY}:: Watching for modified or new #{EXT.join(', ')} files in #{__dir__}\e[0m"
	puts "#{COLOUR_SUCCESS}:: Found #{n_files} #{EXT.join(', ')} file#{n_files == 1 ? '' : 's' } so far...\e[0m\n\n"
end

def start_server
	port = 8080
	bind_address = '0.0.0.0'

	begin
		Thread.new do
			WEBrick::HTTPServer.new(
				Port: port,
				DocumentRoot: __dir__,
				BindAddress: bind_address,
				Logger: WEBrick::Log.new(File::NULL)
			).start
		end

		puts "#{COLOUR_INFO}:: Server started successfully! Please visit http://#{bind_address}:#{port}\e[0m"
	rescue Errno::EADDRINUSE
		puts "#{COLOUR_INFO}:: Error: Port #{port} is unavailable! Retrying to http://0.0.0.0:#{port += 1}\e[0m"
		sleep 0.05
		retry
	end
end

def main
	updated_at = Time.now.to_i
	output_file = OUTPUT_FILE
	anim = %W(\xE2\xA0\x82 \xE2\xA0\x90 \xE2\xA0\xA0 \xE2\xA0\xA4 \xE2\xA0\x86)
	ellipses = %w(. .. ...)

	while files = get_files.tap(&:sort!)
		files.each do |file|
			begin
				mtime = File.mtime(file)
			rescue Errno::ENOENT
				next
			end

			w = STDOUT.winsize[1]

			if (mtime_i = mtime.to_i) > updated_at# || File.basename(file) == 'test.html.erb'
				sleep 0.125
				updated_at = mtime_i
				contents = IO.read(output_file) if File.readable?(output_file)
				puts "\n\e[1;38;2;0;180;0m:: Compiling a newly modified file #{file}...\e[0m"

				compiled_contents =  begin
					if File.basename(file).end_with?('.erb')
						ERB.new(IO.readlines(file).each(&:strip!).join(?\n)).result.split(?\n).tap { |x| x.reject!(&:empty?) }.join(?\n)
					else
						IO.readlines(file).each(&:strip!).tap { |x| x.reject!(&:empty?) }.join(?\n)
					end
				rescue Exception => e
					puts "#{COLOUR_ERROR}#{' :: Error '.center(w, ?-)}\e[0m"
					puts e
					puts "\e[1;38;2;255;80;80m#{?- * w}\e[0m"
					error_html(file, e)
				end

				compiled_html = compile(compiled_contents, file)

				minified_html = minify!(compiled_html.lines)
				4.times { minified_html.replace(minify!(minified_html))}
				output = minified_html.join(?\n)

				if contents != output
					IO.write(output_file.tap { |f| puts "\n#{?\s.*((w / 2 - f.length / 2 - 4).clamp(0, Float::INFINITY))}#{COLOUR_PRIMARY}\e[4mUpdating #{f}\e[0m\n" + "\e[0m" }, output)
					puts "\e[38;2;255;170;40m#{output}\e[0m"
					puts "#{COLOUR_SUCCESS}:: Successfully updated #{file} at #{mtime}".center(w) + "\e[0m"
				else
					puts "\n#{COLOUR_WARNING}:: Skipped, File has same content...\e[0m"
				end

				puts "\e[1m#{?-.*(3).center(w)}\e[0m"
			end
		end

		print " \e[2K#{COLOUR_PRIMARY}#{anim.rotate![0]} Watching for file changes#{ellipses.rotate![0]}\e[0m\r"
		sleep(0.25)
	end
end

begin
	init
	start_server
	main
rescue Interrupt, SystemExit, SignalException
	puts "\n:: Good Bye!"
rescue Exception
	abort $!.full_message
end
