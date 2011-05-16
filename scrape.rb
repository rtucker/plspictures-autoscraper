#!/usr/bin/ruby

# A Firewatir script to download my pictures from plspictures, and then
# re-upload them to my Gallery2.

# Ryan Tucker <rtucker@gmail.com>

require 'rubygems'
require 'firewatir'
require 'yaml'

# Get our config
config = YAML.load_file('secrets.yaml')

# Start with the download...
b = Watir::Browser.start('https://www.plspictures.com/login.do')

puts "Logging into plspictures."
b.text_field(:name, 'loginName').set(config['plspictures']['username'].to_s)
b.text_field(:name, 'password').set(config['plspictures']['password'].to_s)
b.button(:type, 'image').click()

b.link(:name, 'a_albums').click()
b.link(:name, 'a_general.menu.hyperlink.uploads_album').click()

items = b.div(:id, 'num_of_item').text.split(' ')[0].to_i

puts "Photos to download: " + items.to_s

b.link(:name, 'a_download').click()
b.checkbox(:name, 'selectAll').set()
b.link(:href, 'javascript:download()').click()

oldfilename = config['downloadpath'] + '/Uploads.zip'
newfilename = config['downloadpath'] + '/Uploads-' + Time.now.to_i.to_s + '.zip'

puts "Waiting for download to begin."
tries = 0
until File.exists?(oldfilename) do
    sleep 1
    tries += 1
end
puts "Download in progress..."

tries = 0
until File.size?(oldfilename) > 0 do
    sleep 1
    tries += 1
end
puts "File downloaded."

File.rename(oldfilename, newfilename)

b.link(:name, 'a_general.menu.hyperlink.uploads_album').click()
b.link(:name, 'a_move').click()
b.checkbox(:name, 'selectAll').set()
b.radio(:value, '1').set()    # An existing album
b.select_list(:name, 'destinationContainerID').select('Moved')

b.button(:name, 'a_move').click()

# And now for the upload...
b.goto('http://photo.hoopycat.com/')

unless b.link(:text, 'Logout').exists? then
    puts "Logging into Gallery2."
    b.link(:text, 'Login').click()
    b.text_field(:name, 'g2_form[username]').set(config['gallery2']['username'].to_s)
    b.text_field(:name, 'g2_form[password]').set(config['gallery2']['password'].to_s)
    b.button(:name, 'g2_form[action][login]').click()
end

puts "Uploading photos to Gallery2."
b.goto('https://photo.hoopycat.com/v/Incoming/')
b.link(:text, 'Add Items').click()
b.file_field(:name, 'g2_form[1]').set(newfilename)
b.button(:type, 'submit').click()

b.close
