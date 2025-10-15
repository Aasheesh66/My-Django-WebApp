import subprocess
import sys

try:
	out = subprocess.check_output([sys.executable, '-m', 'pip', 'freeze'], text=True)
	open('django_web_app/requirements.txt','w',encoding='utf-8').write(out)
	print('wrote django_web_app/requirements.txt')
except subprocess.CalledProcessError as e:
	print('pip freeze failed', e)
