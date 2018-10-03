require 'nokogiri'
require 'cgi'
require 'uri'

`wget -q -N https://e-trust.gosuslugi.ru/CA/DownloadTSL?schemaVersion=0 -O /tmp/TSLExt.xml`

cert_list='/tmp/TSLExt.xml'
doc = Nokogiri::XML(CGI.unescapeHTML(File.read(cert_list)))
i=1; x=1

doc.xpath('//УдостоверяющийЦентр/ПрограммноАппаратныеКомплексы/ПрограммноАппаратныйКомплекс/КлючиУполномоченныхЛиц/Ключ/Сертификаты/ДанныеСертификата/Отпечаток').each do |cer|
   `wget -q --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" --timeout=3 --tries=3 -N https://e-trust.gosuslugi.ru/Shared/DownloadCert?thumbprint=#{cer.text} -O /tmp/certs/#{cer.text}.cer`
   i+=1
end

puts "Всего сертификатов: #{i}"
`for file in /tmp/certs/*.cer; do sudo /opt/cprocsp/bin/amd64/certmgr -inst -store mroot -f $file; done`
puts "Сертификаты установлены"

doc.xpath('//УдостоверяющийЦентр/ПрограммноАппаратныеКомплексы/ПрограммноАппаратныйКомплекс/КлючиУполномоченныхЛиц/Ключ/АдресаСписковОтзыва/Адрес').each do |crl|
    `wget -q --timeout=3 --tries=3 -N #{crl.text} -P /tmp/certs/`
    #puts x.to_s + ": " + File.basename(URI.parse(crl.text).path) + " (CRL)"
    x+=1
end

puts "Всего отзывных: #{x}"
`for file in /tmp/certs/*.crl; do sudo /opt/cprocsp/bin/amd64/certmgr -inst -crl -f $file; done`
puts "Списки отзывов установлены"
