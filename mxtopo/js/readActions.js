/**
*$id：Action 。JS，V 2017-12-19
*$author shen.zhi
*/
/**
 * 构建了用户界面操作的对象。
 */
var baseGraph,baseXml;
function Actions(editorUi)
{
	this.editorUi = editorUi;
	this.actions = new Object();
	this.init();
};

/**
 * 添加默认的行为。
 */
Actions.prototype.init = function()
{
	var ui = this.editorUi;
	var editor = ui.editor;
	var graph = editor.graph;
	baseGraph = graph;
	doChangeMap();
	var path = $("#path").val();

	this.addAction('deviceInfo', function(){ 
		var cell = graph.getSelectionCell();
		var rem = cell.getRemark();
		if(rem==null||rem==""){
			alert("可能无绑定系统设备，暂无设备信息！");
		}else{
			$.post($("#path").val()+"/GetDeviceInfoOfMapServlet",{"devInfo":rem},function(text){
				$("#deviceInfo",window.parent.document).html(text);
				$("#deviceInfo",window.parent.document).css("font-size","12px");
				$("#deviceInfo tr",window.parent.document).attr("height","23");
				$("#deviceInfo td[align=right]",window.parent.document).css("padding-right","15px");
				window.parent.openDialog("de");
			});
		}
	}, null, null, '');
	this.addAction('cpuInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal",window.parent.document).val(cellVal);
			$("#oneFram",window.parent.document).attr("src",path+"/monitorCenter/devices/mapData/runningMonitor.jsp");
			window.parent.openDialog("jk");
		}
	}, null, null, '');
	
	/*this.addAction('haInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal").val(cellVal.substr(0,cellVal.indexOf("—")));
			$("#oneFram").attr("src",path+"/monitorCenter/devices/mapData/haStatusRunningMonitor.jsp");
			$("#jkInfo").dialog({
				title:"监控——HA状态"
			});
			$("#jkInfo").dialog("open");
		}
	}, null, null, '');*/
	
	this.addAction('memInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal",window.parent.document).val(cellVal);
			$("#oneFram",window.parent.document).attr("src",path+"/monitorCenter/devices/mapData/memRunningMonitor.jsp");
			window.parent.openDialog("jk");
		} 
	}, null, null, '');
	
	this.addAction('sessionInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal",window.parent.document).val(cellVal);
			$("#oneFram",window.parent.document).attr("src",path+"/monitorCenter/devices/mapData/sessionRunningMonitor.jsp");
			window.parent.openDialog("jk");
		}  
	}, null, null, '');
	
	this.addAction('userInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal",window.parent.document).val(cellVal);
			$("#oneFram",window.parent.document).attr("src",path+"/monitorCenter/devices/mapData/onLineRunningMonitor.jsp");
			window.parent.openDialog("jk");
		}  
	}, null, null, '');
	
	this.addAction('diskInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal",window.parent.document).val(cellVal);
			$("#oneFram",window.parent.document).attr("src",path+"/monitorCenter/devices/mapData/diskRunningMonitor.jsp");
			window.parent.openDialog("jk");
		}  
	}, null, null, '');
	
	this.addAction('ifInfo', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无监控信息！");
		}else{
			$("#idVal",window.parent.document).val(cellVal);
			$("#oneFram",window.parent.document).attr("src",path+"/monitorCenter/devices/mapData/ifInfoRunningMonitor.jsp");
			window.parent.openDialog("jk");
		}  
	}, null, null, '');

	this.addAction('gdSyslog', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无日志信息！");
		}else{
			$("#oneFram",window.parent.document).attr("src",path+"/com/visec/monitorCenter/syslog/fixlog/action/FixLogAction.do?mhd=toPathUser&fid="+cellVal+"&rm=0");
			window.parent.openDialog("log");
		}
	}, null, null, '');

	this.addAction('fgdSyslog', function() { 
		var cellVal = graph.getSelectionCell().getRemark();
		if(cellVal==null||cellVal==""){
			alert("可能无绑定系统设备，暂无日志信息！");
		}else{
			var id = cellVal;
			$("#idVal",window.parent.document).val(id);
			$("#oneFram",window.parent.document).attr("src",path+"/com/visec/monitorCenter/syslog/varlog/action/VarlogAction.do?mhd=toListOfMap&dev_id="+id);
			window.parent.openDialog("log");
		}
	}, null, null, '');


	this.addAction('fitPage', mxUtils.bind(this, function()
			{
		if (!graph.pageVisible)
		{
			this.get('pageView').funct();
		}

		var fmt = graph.pageFormat;
		var ps = graph.pageScale;
		var cw = graph.container.clientWidth - 20;
		var ch = graph.container.clientHeight - 20;

		var scale = Math.floor(100 * Math.min(cw / fmt.width / ps, ch / fmt.height / ps)) / 100;
		graph.zoomTo(scale);

		graph.container.scrollLeft = Math.round(graph.view.translate.x * scale - Math.max(10, (graph.container.clientWidth - fmt.width * ps * scale) / 2));
		graph.container.scrollTop = Math.round(graph.view.translate.y * scale - Math.max(10, (graph.container.clientHeight - fmt.height * ps * scale) / 2));
			}));
	this.addAction('fitPageWidth', mxUtils.bind(this, function()
			{
		if (!graph.pageVisible)
		{
			this.get('pageView').funct();
		}

		var fmt = graph.pageFormat;
		var ps = graph.pageScale;
		var cw = graph.container.clientWidth - 20;

		var scale = Math.floor(100 * cw / fmt.width / ps) / 100;
		graph.zoomTo(scale);

		graph.container.scrollLeft = Math.round(graph.view.translate.x * scale - Math.max(10, (graph.container.clientWidth - fmt.width * ps * scale) / 2));
		graph.container.scrollTop = Math.round(graph.view.translate.y * scale - Math.max(10, (graph.container.clientHeight - fmt.height * ps * scale) / 2));
			}));
	this.put('customZoom', new Action(mxResources.get('custom'), function()
			{
		var value = mxUtils.prompt(mxResources.get('enterValue') + ' (%)', parseInt(graph.getView().getScale() * 100));

		if (value != null && value.length > 0 && !isNaN(parseInt(value)))
		{
			graph.zoomTo(parseInt(value) / 100);
		}
			}));

	// Option actions
	var action = null;
	action = this.addAction('grid', function()
			{
		graph.setGridEnabled(!graph.isGridEnabled());
		editor.updateGraphComponents();
			}, null, null, 'Ctrl+Shift+G');
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.isGridEnabled(); });
	action = this.addAction('guides', function() { graph.graphHandler.guidesEnabled = !graph.graphHandler.guidesEnabled; });
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.graphHandler.guidesEnabled; });
	action = this.addAction('tooltips', function()
			{
		graph.tooltipHandler.setEnabled(!graph.tooltipHandler.isEnabled());
			});
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.tooltipHandler.isEnabled(); });
	action = this.addAction('navigation', function()
			{
		graph.foldingEnabled = !graph.foldingEnabled;
		graph.view.revalidate();
			});
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.foldingEnabled; });
	action = this.addAction('scrollbars', function()
			{
		graph.scrollbars = !graph.scrollbars;
		editor.updateGraphComponents();

		if (!graph.scrollbars)
		{
			var t = graph.view.translate;
			graph.view.setTranslate(t.x - graph.container.scrollLeft / graph.view.scale, t.y - graph.container.scrollTop / graph.view.scale);
			graph.container.scrollLeft = 0;
			graph.container.scrollTop = 0;
			graph.sizeDidChange();
		}
		else
		{
			var dx = graph.view.translate.x;
			var dy = graph.view.translate.y;

			graph.view.translate.x = 0;
			graph.view.translate.y = 0;
			graph.sizeDidChange();
			graph.container.scrollLeft -= Math.round(dx * graph.view.scale);
			graph.container.scrollTop -= Math.round(dy * graph.view.scale);
		}
			}, !mxClient.IS_TOUCH);
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.container.style.overflow == 'auto'; });
	action = this.addAction('pageView', mxUtils.bind(this, function()
			{
		graph.pageVisible = !graph.pageVisible;
		graph.pageBreaksVisible = graph.pageVisible; 
		graph.preferPageSize = graph.pageBreaksVisible;
		graph.view.validate();
		graph.sizeDidChange();

		editor.updateGraphComponents();
		editor.outline.update();

		if (mxUtils.hasScrollbars(graph.container))
		{
			if (graph.pageVisible)
			{
				graph.container.scrollLeft -= 20;
				graph.container.scrollTop -= 20;
			}
			else
			{
				graph.container.scrollLeft += 20;
				graph.container.scrollTop += 20;
			}
		}
			}));
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.pageVisible; });
	this.put('pageBackgroundColor', new Action(mxResources.get('backgroundColor'), function()
			{
		var apply = function(color)
		{
			graph.background = color;
			editor.updateGraphComponents();
		};

		var cd = new ColorDialog(ui, graph.background || 'none', apply);
		ui.showDialog(cd.container, 220, 360, true, false);

		if (!mxClient.IS_TOUCH)
		{
			cd.colorInput.focus();
		}
			}));
	action = this.addAction('connect', function()
			{
		graph.setConnectable(!graph.connectionHandler.isEnabled());
			}, null, null, 'Ctrl+Q');
	action.setToggleAction(true);
	action.setSelectedCallback(function() { return graph.connectionHandler.isEnabled(); });



	// Font style actions
	var toggleFontStyle = mxUtils.bind(this, function(key, style)
			{
		this.addAction(key, function()
				{
			graph.toggleCellStyleFlags(mxConstants.STYLE_FONTSTYLE, style);
				});
			});
};

/**
 * 寄存器的作用在给定的名称。
 */
Actions.prototype.addAction = function(key, funct, enabled, iconCls, shortcut)
{
	return this.put(key, new Action(mxResources.get(key), funct, enabled, iconCls, shortcut));
};

/**
 * 寄存器的作用在给定的名称。
 */
Actions.prototype.put = function(name, action)
{
	this.actions[name] = action;

	return action;
};

/**
 * 返回给定名称或空如果没有这样的行动存在的动作。
 */
Actions.prototype.get = function(name)
{
	return this.actions[name];
};

/**
 * Constructs a new action for the given parameters.
 */
function Action(label, funct, enabled, iconCls, shortcut)
{
	mxEventSource.call(this);
	this.label = label;
	this.funct = funct;
	this.enabled = (enabled != null) ? enabled : true;
	this.iconCls = iconCls;
	this.shortcut = shortcut;
};

//Action inherits from mxEventSource
mxUtils.extend(Action, mxEventSource);

/**
 * Sets the enabled state of the action and fires a stateChanged event.
 */
Action.prototype.setEnabled = function(value)
{
	if (this.enabled != value)
	{
		this.enabled = value;
		this.fireEvent(new mxEventObject('stateChanged'));
	}
};

/**
 * Sets the enabled state of the action and fires a stateChanged event.
 */
Action.prototype.setToggleAction = function(value)
{
	this.toggleAction = value;
};

/**
 * Sets the enabled state of the action and fires a stateChanged event.
 */
Action.prototype.setSelectedCallback = function(funct)
{
	this.selectedCallback = funct;
};

/**
 * 套动作启用状态和火灾statechanged事件。
 */
Action.prototype.isSelected = function()
{
	return this.selectedCallback();
};

//加载拓扑图像 顺便添加警告信息
function doChangeMap(){
	$.post($("#path").val()+"/SaveToXmlServlet",{"tp":$("#mapTp").val(),"type":"get"},function(text){
		if(text=="0"){
			alert("文件加载失败！");
		}else{
			var xml = text;
			var doc = mxUtils.parseXml(xml);
			baseXml = doc;
			var nodes = doc.documentElement.getElementsByTagName('mxCell');
			var id,value,index=0;
			for(var i = 0;i<nodes.length;i++){
				value = nodes[i].getAttribute('value');
				id = nodes[i].getAttribute('id');
				if(value==null||value==""){
					continue;
				}
				//判断边
				if(nodes[i].getAttribute('edge')=="1"){
					//增加线条样式
					//nodes[i].setAttribute('style',"entryX=0;entryY=0.5;edgeStyle=entityRelationEdgeStyle;endSize=9;endArrow=block;strokeColor=#FF3333;strokeWidth=2;dashed=1");
					continue;
				}
				index = value.indexOf("\n");
				if(index>0){
					nodes[i].setAttribute('value',value.substr(0,index));
					nodes[i].setAttribute('text',value.substr(index+1).replace("\n"," / "));
					continue;
				}

				nodes[i].setAttribute('text',value);
			}
			//装载加入到显示区域
			var codec = new mxCodec(doc);
			codec.decode(doc.documentElement, baseGraph.getModel());

			//baseGraph.getModel().beginUpdate();

			//baseGraph.getModel().endUpdate();
			//doLoadAlert();
		}		
	});
}
window.setInterval("doLoadAlert()",8000);
//检测警告信息
function doLoadAlert(){
	var model = baseGraph.getModel();
	if(baseXml != null && baseXml.documentElement != null){
		var nodes = baseXml.documentElement.getElementsByTagName('mxCell');
		var val,val2,id,result="";
		for(var i = 0;i<nodes.length;i++){
			if(nodes[i].getAttribute('edge')=="1"){
				continue;
			}
			val = nodes[i].getAttribute('text');
			if(val != null && val != ""){
				if(val.indexOf("/")>0){
					val2=val.substring(val.lastIndexOf(":")+2);
					val=val.substring(val.indexOf(":")+1,val.indexOf("/")-2);
				}
				if(checkIP(val)){
					id = nodes[i].getAttribute("id");
					result+=id+"-"+val+"-"+val2+"=";
				}
			}
		}

		//ping操作获取状态
		$.post($("#path").val()+"/CheckMapIpServlet",{"ip":result},function(text){
			var data = text.split("#");
			var ifData = $.parseJSON(data[1]);
			var statData = data[0].split("=");
			model.beginUpdate();
			try{
				var sd = null,ce = null;
				$.each(statData,function(index,sds){
					if(sds!=null && sds!=""){
						sd = sds.split("-");
						ce = model.getCell(sd[0]);
						//判断业务口和通讯口都中断
						if(sd[1]!="0" &&　sd[2]!="0"){
							baseGraph.addCellOverlay(ce, new mxCellOverlay(baseGraph.warningImage,'警告: 网络连接不通'));
							//显示数据流向
							//showDataLine(nodes,sd[0],model);
						}
						//判断通讯口中断业务口正常
						if(sd[1]!="0" &&　sd[2]=="0"){
							baseGraph.addCellOverlay(ce, new mxCellOverlay(baseGraph.warningImage,'警告: 通讯口连接不通'));
							//显示数据流向
							//showDataLine(nodes,sd[0],model);
							//显示流量信息
							showIf(ce,ifData,sd[0]);
						}
						//判断通讯口正常业务口中断
						if(sd[1]=="0" &&　sd[2]!="0"){
							baseGraph.addCellOverlay(ce, new mxCellOverlay(baseGraph.warningImage,'警告: 业务口连接不通'));
							//显示数据流向
							//showDataLine(nodes,sd[0],model);
							//显示流量信息
							showIf(ce,ifData,sd[0]);

						}
					}
				});
			}finally{
				model.endUpdate();
			}
		});
	}
}

//显示流量方法
function showIf(ce,ifData,ceId){
	$.each(ifData,function(ind,vo){
		if(ceId==vo.tempId){
			ce.setValue(vo.name+vo.remark);
			return false;
		}
	});
}

//显示数据流向
function showDataLine(nodes,ceId,model){
	for(var i = 0;i<nodes.length;i++){
		if(nodes[i].getAttribute('edge')!="1"){
			continue;
		}
		var cee = model.getCell(nodes[i].getAttribute('id')).getTerminal(1);
		if(cee!=null){
			if(cee.getId()==ceId){
				nodes[i].setAttribute('value',"AA");
				//alert(nodes[i].getAttribute('value'))
				//nodes[i].setAttribute('style',"entryX=0;entryY=0.5;edgeStyle=entityRelationEdgeStyle;endSize=9;endArrow=block;strokeColor=#FF3333;strokeWidth=2;dashed=1");
			}
		}
	}
}

//添加告警标识
function addAlert(text,cell){
	baseGraph.getModel().beginUpdate();
	try{
		if(text=="0"){
			baseGraph.addCellOverlay(cell, new mxCellOverlay(baseGraph.warningImage,'警告: 网络连接不通'));
		}else{
			baseGraph.removeCellOverlays(cell);//删除当前元素的警告标识
		}
	}finally{
		baseGraph.getModel().endUpdate();
	}
}

//验证是否为IP地址
function checkIP(ip){
	var re=/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;//正则表达式   
	if(re.test(ip))   
	{   
		if( RegExp.$1<256 && RegExp.$2<256 && RegExp.$3<256 && RegExp.$4<256) 
			return true;   
	}else{
		return false;
	}
}
