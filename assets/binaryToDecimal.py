# Shawn Jain
# Python script to generate LUT for BCD.v

for i in range(100):
	print str(i) + ': begin ' + 'ones <= ' + str(i%10) + '; ' + 'tens <= ' + str(i/10) + ';' + ' end'
print 'default: begin ones <= 0; tens <= 0; end'