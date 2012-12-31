from burp import IBurpExtender
from burp import IMenuItemHandler
from java.awt.datatransfer import Clipboard,StringSelection
from java.awt import Toolkit
class BurpExtender(IBurpExtender, IMenuItemHandler):
	def registerExtenderCallbacks(self, callbacks):
		self._helpers = callbacks.getHelpers()
		callbacks.setExtensionName('sqldude')
		callbacks.registerMenuItem('sqldude', self)
		self.mCallBacks = callbacks
		return
	
	def menuItemClicked(self, caption, messageInfo):
		msg = messageInfo[0]
		request = ''.join(map(chr, (msg.getRequest())))
		headers, body = request.split('\r\n\r\n')
		headers = dict(item.split(': ') for item in headers.split('\r\n')[1:])
		payload = ('python sqlmap.py -u "%s" --cookie="%s"' % (msg.getUrl(), headers['Cookie']))
		if body is not None and len(body) > 0: #query string is in body
			payload = '%s --data="%s"' % (payload, body)
		s = StringSelection(payload)
		Toolkit.getDefaultToolkit().getSystemClipboard().setContents(s,s) #put string on clipboard
		print(payload) #print string
		return
