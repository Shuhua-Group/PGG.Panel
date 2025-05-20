import itertools, gzip, sys, os

infile  = sys.argv[1]#two col, no  header
outlist = sys.argv[2]

#read
d = {}
samples = {}
f = open( infile )
for line in f:
	y = line.split()
	s1, s2 = y[0], y[1]
	d[ s1 + ':' + s2 ] = ''
	if s1 not in samples:
		samples[ s1 ] = 1
	else:
		samples[ s1 ] += 1
	if s2 not in samples:
		samples[ s2 ] = 1
	else:
		samples[ s2 ] += 1
f.close()



#statis and rm one sample 重复次数最多的人删掉
def statis_and_rm_most( d_, rm_list ):
	print( 'statistic', len(rm_list) )
	statis = {}
	for mem in d_:
		s1 = mem.split(':')[0]
		s2 = mem.split(':')[1]
		if s1 not in statis:
			statis[ s1 ] = 1
		else:
			statis[ s1 ] += 1
		if s2 not in statis:
			statis[ s2 ] = 1
		else:
			statis[ s2 ] += 1
	d_s = sorted( statis.items(), key = lambda x:x[1], reverse = True )
	print( d_s[0] )
	target = d_s[0][0].split(':')[0] #id
	rm_list[ target ] = ''

	keys_ = list( d_.keys() )
	dt = {}
	for mem in keys_:
		s1 = mem.split(':')[0]
		s2 = mem.split(':')[1]
		if s1 == target or s2 == target:
			pass
		else:
			dt[ mem ] = ''

	return dt, rm_list

#检查是否存在在多个组合中出现的重复个体
def check( d_ ):
	print( 'check', len(rm_list) )
	counts = {}
	for mem in d_:
		s1 = mem.split(':')[0]
		s2 = mem.split(':')[1]
		if s1 not in counts:
			counts[ s1 ] = ''
		else:
			return 'no'
		if s2 not in counts:
			counts[ s2 ] = ''
		else:
			return 'no'
	return 'ok'

#预处理，组合中两个样本均只出现一次的去掉前一个；组合中两个样本一个只出现一次，另一个出现多次的，去掉多次的样本。
rm_list = {}
d_ = {}
for mem in d:
	s1 = mem.split(':')[0]
	s2 = mem.split(':')[1]
	if samples[ s1 ] == 1 and samples[ s2 ] == 1:
		rm_list[ s1 ] = ''
	elif samples[ s1 ] == 1 and samples[ s2 ] > 1:
		rm_list[ s2 ] = ''
	elif samples[ s1 ] > 1 and samples[ s2 ] == 1:
		rm_list[ s1 ] = ''
	else:
		d_[ mem ] = ''

#开始循环
while 1:
	results = check( d_ )
	if results == 'no':
		d_, rm_list = statis_and_rm_most( d_, rm_list )
	else:
		break


#end
for mem in d_:
	s1 = mem.split(':')[0]
	s2 = mem.split(':')[1]
	rm_list[ s1 ] = ''
fout = open( outlist, 'w' )
for mem in rm_list:
	fout.write( mem + '\n' )
fout.close()
