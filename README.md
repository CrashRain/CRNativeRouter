# CRNativeRouter
统跳协议的实现，主要用来降低模块间的耦合度，通过一个公共的组件来切换视图显示和传递数据，支持代码生成、XIB、StoryBoard界面的管理。

[TOC]

##使用方法
###1、设置统跳协议需要辨识的路径正则表达式
Router需要一个Internal URL来辨识需要显示的界面和要传递的参数，并且需要对传入的URL判断其合法性。在使用前需要先传入一个URL通配的正则表达式给Router。正则表达式可以用如下的模板：

```
^(Module://)(\\w+\\.md)(\\?(([a-zA-Z]+\\w*=\\w+)(&[a-zA-Z]+\\w*=\\w+)*)|([a-zA-Z]+\\w*=\\w+))?$
```

###2、注册ViewController到Router
之后需要注册已有的或者需要显示的ViewController到Router，注册针对实现有三种方法，分别对应代码生成界面、Xib或者Nib、StoryBoard。

1. 代码生成界面注册API    

	`registerNewModule(_ name: String, type: AnyClass, parameters: [String]?)`
	
	通过这个函数传入该ViewController对应的Module名称、类型以及需要传入的参数名称。

2. Xib或者Nib注册API
	
	`registerNewModule(_ name: String, type: AnyClass, nib: String, parameters: [String]?)`
	
	通过这个函数传入该ViewController的Module名称、类型、对应的nib名称以及需要传入的参数名称。

3. StoryBoard注册API

	`registerNewModule(_ name: String, type: AnyClass, storyboard: String, identifier: String, parameters: [String]?)`
	
	通过这个函数传入该ViewController的Module名称、类型、对应的storyboard名称和其中的identifier字符串，以及需要传入的参数名称。
	
####团队协作

考虑到开发过程中会多人团队协作，如果单纯用代码进行注册会碰到git容易冲突的情况，因此引入用plist文件来整体管理每名成员的模块并进行批量注册。

1. 指定全局管理开发成员plist文件名称的plist文件    

	这个plist文件管理项目中需要注册的子文件，只有文件名称在这个plist文件中才会被Router进行注册。该plist文件内容为一个数组即可，示例内容如下：
	
	```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>NativeRouter</string>
</array>
</plist>
```

2. 每名成员生成自己的plist文件，将模块添加到该文件中，并将文件名称注册到全局plist文件    

	 项目中的每位成员需要生成自己的plist文件，并且将自己开发的模块注册到该plist文件中。plist文件首先需要指定一个名为Modules的array类型数组，之后将每个ViewController注册到文件中。name和type是必须指定的字段，parameters为可选字段，若没有则默认不需要参数。StoryBoard组件额外需要storyboard和identifier字段，nib组件额外需要nib字段。示例内容如下：
	 
	 ```plist
	 <?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Modules</key>
	<array>
		<dict>
			<key>parameters</key>
			<array>
				<string>value</string>
				<string>test</string>
			</array>
			<key>identifier</key>
			<string>ViewController4</string>
			<key>storyboard</key>
			<string>Main</string>
			<key>type</key>
			<string>ViewController4</string>
			<key>name</key>
			<string>vc4.md</string>
		</dict>
		<dict>
			<key>parameters</key>
			<array>
				<string>url</string>
				<string>test</string>
				<string>temp</string>
			</array>
			<key>identifier</key>
			<string>ViewController3</string>
			<key>storyboard</key>
			<string>Main</string>
			<key>type</key>
			<string>ViewController3</string>
			<key>name</key>
			<string>vc3.md</string>
		</dict>
	</array>
</dict>
</plist>
	 ```
3. 调用API进行注册    
之后调用如下API，传入全局plist文件名进行注册即可：
`registerModulesFromDeveloperGroupConfiguration(_ filename: String)`    

###3、界面跳转

之后界面切换调用API即可，支持navigation的Show、ShowDetail、Popup三种方式，另外支持Modally显示方式，具体查看API名称即可。    

同时也支持是否传入当前navigation的选项，如果不传入则会递归查找当前显示的navigation，建议传入减少性能开销。

###4、统跳原理
敬请期待下回分解
