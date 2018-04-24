/**
*$id：Action 。JS，V 2017-12-19
*$author shen.zhi
*/
/**
*结构对于给定的UI操作的对象。
*编辑函数方法管理
*/
function Actions(editorUi)
{
	this.editorUi = editorUi;
	this.actions = new Object();
	this.init();
};
/**
 * 添加默认的函数
 */
Actions.prototype.init = function()
{
	var ui = this.editorUi;
	var editor = ui.editor;
	var graph = editor.graph;
	graph.cellsMovable=!0;				//设置不可移动
	graph.cellsDisconnectable=!0;		//设置边不可编辑
	graph.cellsResizable=!0;			//设置不可改变大小
	var icw = (ui.container.clientWidth-190-20)/2;
	var ich = 30;
	currentObject = this ;
	
	//文件操作
	this.addAction('new', function() { window.open(ui.getUrl());});
	this.addAction('open', function()
	{
		window.openNew = true;
		window.openKey = 'open';
		ui.openFile();
	});
	
	this.addAction('import', function()
	{
		window.openNew = false;
		window.openKey = 'import';
		
		//关闭对话框后打开
		window.openFile = new OpenFile(mxUtils.bind(this, function()
		{
			ui.hideDialog();
		}));
		
		window.openFile.setConsumer(mxUtils.bind(this, function(xml, filename)
		{
			try
			{
				var doc = mxUtils.parseXml(xml);
				var model = new mxGraphModel();
				var codec = new mxCodec(doc);
				codec.decode(doc.documentElement, model);
				
				var children = model.getChildren(model.getChildAt(model.getRoot(), 0));
				//editor.graph.setSelectionCells(editor.graph.importCells(children));
				editor.graph.importCells(children);
			}
			catch (e)
			{
				mxUtils.alert(mxResources.get('invalidOrMissingFile') + ': ' + e.message);
			}
		}));

		//如果删除打开文件对话框关闭
		ui.showDialog(new OpenDialog(this).container, 300, 180, true, true, function()
		{
			window.openFile = null;
		});
	});
	this.addAction('save', function() { ui.save(); }, null, null, 'Ctrl+S');
	
	//this.addAction('saveAs', function() { ui.saveFile(true); }, null, null, 'Ctrl+Shift-S');
	//this.addAction('export', function() { ui.showDialog(new ExportDialog(ui).container, 300, 200, true, true); }, null, null, 'Ctrl+E');
	//this.put('editFile', new Action(mxResources.get('edit'), mxUtils.bind(this, function()
	//{  
		//this.editorUi.showDialog(new EditFileDialog(ui).container, 620, 420, true, true);
	//})));
	this.addAction('pageSetup', function() { ui.showDialog(new PageSetupDialog(ui).container, 300, 200, true, true); });
	
	//打印
	this.addAction('print', function() { ui.showDialog(new PrintDialog(ui).container, 300, 200, true, true); }, null, 'sprite-print', 'Ctrl+P');
	
	this.addAction('preview', function() { mxUtils.show(graph, null, 10, 10); });
	
	//编辑操作
	this.addAction('undo', function() { editor.undoManager.undo(); }, null, 'sprite-undo', 'Ctrl+Z');
	this.addAction('redo', function() { editor.undoManager.redo(); }, null, 'sprite-redo', 'Ctrl+Y');
	this.addAction('cut', function() { mxClipboard.cut(graph); }, null, 'sprite-cut', 'Ctrl+X');
	this.addAction('copy', function() { mxClipboard.copy(graph); }, null, 'sprite-copy', 'Ctrl+C');
	this.addAction('paste', function() { mxClipboard.paste(graph); }, false, 'sprite-paste', 'Ctrl+V');
	this.addAction('delete', function() { graph.removeCells(); }, null, null, 'Delete');
	this.addAction('duplicate', function()
    {
		var s = graph.gridSize;
		graph.setSelectionCells(graph.moveCells(graph.getSelectionCells(), s, s, true));
    }, null, null, 'Ctrl+D');
	this.addAction('selectVertices', function() { graph.selectVertices(); }, null, null, 'Ctrl+Shift+V');
	this.addAction('selectEdges', function() { graph.selectEdges(); }, null, null, 'Ctrl+Shift+E');
	this.addAction('selectAll', function() { graph.selectAll(); }, null, null, 'Ctrl+A');

	//导航行动 
	this.addAction('home', function() { graph.home(); }, null, null, 'Home');
	this.addAction('exitGroup', function() { graph.exitGroup(); }, null, null, 'Page Up');
	this.addAction('enterGroup', function() { graph.enterGroup(); }, null, null, 'Page Down');
	this.addAction('expand', function() { graph.foldCells(false); }, null, null, 'Enter');
	this.addAction('collapse', function() { graph.foldCells(true); }, null, null, 'Backspace');

	//安排行动 
	this.addAction('toFront', function() { graph.orderCells(false); }, null, null, 'Ctrl+F');
	this.addAction('toBack', function() { graph.orderCells(true); }, null, null, 'Ctrl+B');
	this.addAction('group', function() { graph.setSelectionCell(graph.groupCells(null, 0)); }, null, null, 'Ctrl+G');
	this.addAction('ungroup', function() { graph.setSelectionCells(graph.ungroupCells()); }, null, null, 'Ctrl+U');
	this.addAction('removeFromGroup', function() { graph.removeCellsFromParent(); });
	this.addAction('editLink', function()
	{
		var cell = graph.getSelectionCell();
		var link = graph.getLinkForCell(cell);
		
		if (link == null)
		{
			link = '';
		}
		
		link = mxUtils.prompt(mxResources.get('enterValue'), link);
		
		if (link != null)
		{
			graph.setLinkForCell(cell, link);
		}
	});
	this.addAction('openLink', function()
	{
		var cell = graph.getSelectionCell();
		var link = graph.getLinkForCell(cell);
		
		if (link != null)
		{
			window.open(link);
		}
	});
	this.addAction('autosize', function()
	{
		var cells = graph.getSelectionCells();
		
		if (cells != null)
		{
			graph.getModel().beginUpdate();
			try
			{
				for (var i = 0; i < cells.length; i++)
				{
					var cell = cells[i];
					
					if (graph.getModel().getChildCount(cell))
					{
						graph.updateGroupBounds([cell], 20);
					}
					else
					{
						graph.updateCellSize(cell);
					}
				}
			}
			finally
			{
				graph.getModel().endUpdate();
			}
		}
	});
	this.addAction('rotation', function()
	{
		var value = '0';
    	var state = graph.getView().getState(graph.getSelectionCell());
    	
    	if (state != null)
    	{
    		value = state.style[mxConstants.STYLE_ROTATION] || value;
    	}

		value = mxUtils.prompt(mxResources.get('enterValue') + ' (' +
				mxResources.get('rotation') + ' 0-360)', value);
        	
    	if (value != null)
    	{
        	graph.setCellStyles(mxConstants.STYLE_ROTATION, value);
        }
	});
	this.addAction('rotate', function()
	{
		var cells = graph.getSelectionCells();
		
		if (cells != null)
		{
			graph.getModel().beginUpdate();
			try
			{
				for (var i = 0; i < cells.length; i++)
				{
					var cell = cells[i];
					
					if (graph.getModel().isVertex(cell) && graph.getModel().getChildCount(cell) == 0)
					{
						var geo = graph.getCellGeometry(cell);
			
						if (geo != null)
						{
							//旋转的几何尺寸及位置 
							geo = geo.clone();
							geo.x += geo.width / 2 - geo.height / 2;
							geo.y += geo.height / 2 - geo.width / 2;
							var tmp = geo.width;
							geo.width = geo.height;
							geo.height = tmp;
							graph.getModel().setGeometry(cell, geo);
							
							//方向和进展90度读 
							var state = graph.view.getState(cell);
							
							if (state != null)
							{
								var dir = state.style[mxConstants.STYLE_DIRECTION] || 'east'/*default*/;
								
								if (dir == 'east')
								{
									dir = 'south';
								}
								else if (dir == 'south')
								{
									dir = 'west';
								}
								else if (dir == 'west')
								{
									dir = 'north';
								}
								else if (dir == 'north')
								{
									dir = 'east';
								}
								
								graph.setCellStyles(mxConstants.STYLE_DIRECTION, dir, [cell]);
							}
						}
					}
				}
			}
			finally
			{
				graph.getModel().endUpdate();
			}
		}
	}, null, null, 'Ctrl+R');
	
	//查看下级
	this.addAction('initNext', mxUtils.bind(this, function(subRootId,opttype)
	{ 
		var intype = opttype ;
		var incurrentResId = subRootId ;
		var currentObje = this ;
		if(subRootId&&subRootId!=""&&subRootId!="null"&&subRootId!="undefined"
			&&opttype&&opttype!=""&&opttype!="null"&&opttype!="undefined"){
			incurrentResId = subRootId ;
		}else{
			var edges = graph.getSelectionCell().edges;
			incurrentResId = graph.getSelectionCell().id;
			if(incurrentResId.length>10&&"2736"==incurrentResId.substring(5,9)){
				alert("ONT无下级资源");
				return;
			}
			for(var e_i = 0;edges&&e_i<edges.length; e_i++){
				if(edges[e_i].source.id==incurrentResId){
					//已经有了下级，不重新加载，避免重复生成子节点
					return;
				}
			}
			if(opttype&&opttype&&opttype!=""&&opttype!="null"&&opttype!="undefined"){
				intype = opttype ;
			}else{
				intype = "2" ;
			}
		}
		if(intype=="6"&&incurrentResId.length>10&&"2736"!=incurrentResId.substring(5,9)&&"2530"!=incurrentResId.substring(5,9)){
			alert("只有OBD和ONT支持查看上联通路");
			return;
		}
		graph.getModel().beginUpdate();
		try
		{
			    $.getJSON($("#path").val()+"/topo/topo.spr?method=getMxTopoById",{"params":incurrentResId,"sfFunctionName":sfFunctionName,"type":intype,"inx":"0","iny":"0","topoDefId":topoDefId},function(data){
			    	var cels = null;//graph.getSelectionCell();
			        var inx= 0 ;//cels.geometry.x;
				    var iny= 0 ;//cels.geometry.y;
				    var iwidth = 40 ;
				    var iheight = 40 ;
				    var isroot = 0;
				    if(data&&data.root==1){
				    	isroot = 1;
				    	inx=icw;
				    	graph.selectAll();
				    	graph.removeCells();
				    }else if(data&&data.root==3){
				    	isroot = 3;
				    	inx=icw;
				    	graph.selectAll();
				    	graph.removeCells();
				    }else{
				    	 
				    	 cels = graph.getSelectionCell();
				         inx=cels.geometry.x;
					     iny=cels.geometry.y;
					     if(befor_sel_cell&&befor_sel_cell.length>0){
					    	 graph.setCellStyle(befor_sel_cell [0].style.replace("_sel.png",".png"), befor_sel_cell);
					     }
					    
						var cells = graph.getSelectionCells();
						if (cells != null && cells.length > 0)
						{
							graph.setCellStyle(cells[0].style.replace(".png","_sel.png"), cells);
							befor_sel_cell = graph.getSelectionCells();
						}
						
						if(data==null||data==""||data=="null"){
				    		 alert("无下级资源");
				    		 return;
				    	 }
						     
				    }
				    currentNeedSelNodeiny = iny;
					currentNeedSelNodeinx = inx;
					currentNeedSelGraph   = graph;
					currentSelCellObject  = cels;
				    if(isroot==0&&data&&data.nodes.length>0){
				    var  subdata = new Array();
				    for(var di=0;data&&di<data.nodes.length;di++){
				    	var sobj = {"ID":data.nodes[di].id,"NAME":data.nodes[di].value,"CHECK":data.nodes[di].id};
				    	subdata.push(sobj);
				    }
				    cleanGrid();
				    $(".grid-content").llygrid({
				    	columns:[
				           	{align:"center",key:"ID",label:"ID", width:"0"},
				            {align:"center",key:"CHECK",  width:"50",format:{type:"checkbox"}},
				            {align:"center",key:"NAME",label:"资源名称", width:"250"}
				            
				         ],
				         ds:{type:"data",records:subdata},
				    	 limit:20,
				    	 pageSizes:[10,20,30,40],
				    	 height:180,
				    	 title:"请选择需要展示的资源",
				    	 indexColumn:false,
				    	 querys:{name:""},
				    	 options:"reload",
				    	 loadMsg:"数据加载中，请稍候......"
				      }) ;
					
					 var ibttonhtml = '选择需要展示的资源     <button style="margin-left: 50px;" onclick="viewSelectRes()"> 确认</button><button style="margin-left: 50px;"  onclick="hideSelectRes()"> 关闭</button>';
					 $(".grid-content .ui-corner-all .ui-helper-clearfix").html(ibttonhtml);
					 currentNeedSelNode = data.nodes;
					 //下级数量小于7时直接展示，多的时候才弹出选项框
					 if(data.nodes.length<7){
						 viewSelectRes(1);
					 }else{
						 $('#divSubResDetailGrid').slideDown("slow");
					 }
			    	}else if(isroot==3&&data&&data.nodes.length>0){
			    		var rootCel;
				    	for(var di=0;data&&di<data.nodes.length;di++){
				    		iny = iny+120 ;
				    		var linx = inx;
				    		var liny = iny;
				    		var dataNode =  data.nodes[di]; 
		    				var newcells =  graph.insertVertex(graph.getDefaultParent(), dataNode.id,dataNode.value, linx, liny, iwidth, iheight,"image;image=stencils/clipart/"+dataNode.type+".png");
		    				if(di==0){
		    					rootCel=newcells;
		    				}else{
		    					var newEdge = graph.insertEdge(graph.getDefaultParent(), "edge"+dataNode.id, "", currentSelCellObject, newcells, "edgeStyle=topToBottomEdgeStyle;");
		    				}
		    				currentSelCellObject = newcells;
				    	}
				    	editor.graph.setSelectionCells([rootCel]);
				    	currentObject.get('initResProperties').funct();
			    	}else{
			    		iny = iny+120 ;
				    	for(var di=0;data&&di<data.nodes.length;di++){
				    		var linx = inx;
				    		var liny = iny;
				    		if(di%2==0){
				    			linx = inx+60*di;
				    		}else{
				    			linx = inx-60*di;
				    		}
				    		var dataNode =  data.nodes[di]; 
		    				var newcells =  graph.insertVertex(graph.getDefaultParent(), dataNode.id,dataNode.value, linx, liny, iwidth, iheight,"image;image=stencils/clipart/"+dataNode.type+".png");
		    				editor.graph.setSelectionCells([newcells]);
				    	}
						
						if(isroot==1){
							currentObject.get('initNext').funct(subRootId,"2");
						}
						
					}
					
			    	
			    });
		}
		finally
		{
			graph.getModel().endUpdate();
		}
	}));
	this.get('initNext').funct(inResId,intype);
	//刷新-重新加载
	this.addAction('refreshView', function()
	{ 
		graph.getModel().beginUpdate();
		try
		{
			var icw = (ui.container.clientWidth-190-20)/2;
			var ich = 30;
			$.getJSON($("#path").val()+"/topo/topo.spr?method=getMxTopoById",{"params":inResId,"sfFunctionName":sfFunctionName,"type":"1","inx":"0","iny":"0","topoDefId":topoDefId},function(data){
			    	var cels = null;//graph.getSelectionCell();
			        var inx= icw ;//cels.geometry.x;
				    var iny= ich ;//cels.geometry.y;
				    var iwidth = 40 ;
				    var iheight = 40 ;
				    var isroot = 0;
				    if(data&&data.root==1){
				    	isroot = 1;
				    }else{
				    	 cels = graph.getSelectionCell();
				         inx=cels.geometry.x;
					     iny=cels.geometry.y;
				    }
				    iny = iny+120 ;
			    	for(var di=0;data&&di<data.nodes.length;di++){
			    		var linx = inx
			    		if(di%2==0){
			    			linx = inx+50*di;
			    		}else{
			    			linx = inx-50*di;
			    		}
			    		var dataNode =  data.nodes[di]; 
						var newcells =  graph.insertVertex(graph.getDefaultParent(), dataNode.id,dataNode.value, linx, iny, iwidth, iheight,"image;image=stencils/clipart/"+dataNode.type+".png");
						if(isroot==0){
							//根节点不需要创建连线
							var newEdge = graph.insertEdge(graph.getDefaultParent(), "edge"+dataNode.id, "", cels, newcells, "edgeStyle=topToBottomEdgeStyle;");
						}
						
			    	}
			    	
			    });
			
		}
		finally
		{
			graph.getModel().endUpdate();
		}
	});
	//查看资源属性
	this.addAction('initResProperties', function()
	{ 
		graph.getModel().beginUpdate();
		try
		{
			$.getJSON($("#path").val()+"/topo/topo.spr?method=getMxTopoById",{"params":graph.getSelectionCell().id,"sfFunctionName":sfFunctionName,"type":"3","inx":"0","iny":"0"},function(data){
				 $(".grid-content-attr").html("");
			     if($('.grid-content-attr').data("cacheDs")&&$('.grid-content-attr').data("cacheDs").records){
			    	$('.grid-content-attr').data("cacheDs").records=[];
			     }
				 $(".grid-content-attr").llygrid({
					 columns:[
			           	{align:"center",key:"ATTR_NAME",label:"资源属性", width:"80"},
			            {align:"center",key:"ATTR_VALUE",label:"属性值", width:"160"}
			         ],
			         ds:{type:"data",records:data},
					 limit:100,
					 pager: true,
					 height:200,
					 title:"点击收起",
					 loadMsg:"数据加载中，请稍候......"
				   }) ;
				 $('#divSubResPropertyGrid').show("slide", {direction : "right" }, 500,function(){});
				 $(".grid-content-attr .ui-corner-all .ui-helper-clearfix").click(function () {
					  $('#divSubResPropertyGrid').hide("slide", {direction : "right" }, 500,function(){});
	             });
			});
		}
		finally
		{
			graph.getModel().endUpdate();
		}
	});
	//查看资源端口端子信息
	this.addAction('initSubRes', function()
	{ 
		graph.getModel().beginUpdate();
		try
		{
			$.getJSON($("#path").val()+"/topo/topo.spr?method=getMxTopoById",{"params":graph.getSelectionCell().id,"sfFunctionName":sfFunctionName,"type":"4","inx":"0","iny":"0"},function(data){
				 cleanGrid();
				 $(".grid-content").llygrid({
					 columns:data.heard,
			         ds:{type:"data",records:data.body},
			         limit:20,
					 pageSizes:[10,20,30,40],
					 height:180,
					 title:"数据列表-点击收起",
					 loadMsg:"数据加载中，请稍候......"
				   }) ;
				 $('#divSubResDetailGrid').slideDown("slow");
				 $(".grid-content .ui-corner-all .ui-helper-clearfix").click(function () {
	                  $("#divSubResDetailGrid").slideUp("slow");
	             });
			});
		}
		finally
		{
			graph.getModel().endUpdate();
		}
	});
	//查看上级连接信息
	this.addAction('viewLink', function()
	{ 
		graph.getModel().beginUpdate();
		try
		{
			var target = graph.getSelectionCell().target;
			$.getJSON($("#path").val()+"/topo/topo.spr?method=getMxTopoById",{"params":target.id,"sfFunctionName":sfFunctionName,"type":"5","inx":"0","iny":"0"},function(data){
				 cleanGrid();
				 $(".grid-content").llygrid({
					 columns:data.heard,
			         ds:{type:"data",records:data.body},
			         limit:20,
					 pageSizes:[10,20,30,40],
					 height:180,
					 title:"数据列表-点击收起",
					 loadMsg:"数据加载中，请稍候......"
				   }) ;
				 $('#divSubResDetailGrid').slideDown("slow");
				 $(".grid-content .ui-corner-all .ui-helper-clearfix").click(function () {
	                  $("#divSubResDetailGrid").slideUp("slow");
	             });
			});
		}
		finally
		{
			graph.getModel().endUpdate();
		}
	});
	//查看上级全程路由
	this.addAction('viewSuperRoute', function()
	{ 
		var target = graph.getSelectionCell();
		//6 从下往上 找全程路由
		currentObject.get('initNext').funct(target.id,"6");
		
	});
	this.addAction('invisibleSub', function() { 
		var needRemoveCells = [];		
		needRemoveCells.push.apply(needRemoveCells,getTarget(graph.getSelectionCell(),null));
		graph.removeCells(needRemoveCells); 
	});
	this.addAction('invisibleOrther',mxUtils.bind(this, function() { 
		var currentObjectCell = graph.getSelectionCell();
		var parentObjectCell = null ;
		var isroot = 0;
		if(currentObjectCell&&currentObjectCell.edges&&currentObjectCell.edges.length>0){
			if(currentObjectCell.edges.length==0){
				isroot = 1;
			}
			for(var c_i = 0; c_i <currentObjectCell.edges.length;c_i++ ){
				if(currentObjectCell.edges[c_i]&&currentObjectCell.edges[c_i].target&&currentObjectCell.edges[c_i].target==currentObjectCell){
					parentObjectCell = currentObjectCell.edges[c_i].source;
					break;
				}
			}
		}
		var needRemoveCells = [];
		needRemoveCells.push.apply(needRemoveCells,getTarget(parentObjectCell,currentObjectCell));
		graph.removeCells(needRemoveCells); 
		if(isroot == 1){
			editor.graph.setSelectionCells([parentObjectCell]);
			var layout_mx = new mxCompactTreeLayout(graph, false);
	  	    layout_mx.edgeRouting = false;
	  	    layout_mx.levelDistance = 30;
	  	    this.editorUi.executeLayout(layout_mx, true, true);
		}
		
	}));
	
	this.addAction('zoomIn', function() { graph.zoomIn(); }, null, null, 'Add');
	this.addAction('zoomOut', function() { graph.zoomOut(); }, null, null, 'Subtract');
	this.addAction('fitWindow', function() { graph.fit(); });

	//视图的操作
	this.addAction('actualSize', function()
	{
		graph.zoomTo(1);
	});
	
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
	
	//选择行动 
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
	
	//帮助行为 
	this.addAction('help', function()
	{
		var ext = '';
		
		if (mxResources.isLanguageSupported(mxClient.language))
		{
			ext = '_' + mxClient.language;
		}
		
		window.open(RESOURCES_PATH + '/help' + ext + '.html');
	});
	this.put('about', new Action(mxResources.get('about') + ' Graph Editor', function()
	{
		ui.showDialog(new AboutDialog(ui).container, 320, 280, true, true);
	}, null, null, 'F1'));
	
	//字体风格的动作 
	var toggleFontStyle = mxUtils.bind(this, function(key, style)
	{
		this.addAction(key, function()
		{
			graph.toggleCellStyleFlags(mxConstants.STYLE_FONTSTYLE, style);
		});
	});
	
	toggleFontStyle('bold', mxConstants.FONT_BOLD);
	toggleFontStyle('italic', mxConstants.FONT_ITALIC);
	toggleFontStyle('underline', mxConstants.FONT_UNDERLINE);
	
	//颜色动作 
	this.addAction('fontColor', function() { ui.menus.pickColor(mxConstants.STYLE_FONTCOLOR); });
	this.addAction('strokeColor', function() { ui.menus.pickColor(mxConstants.STYLE_STROKECOLOR); });
	this.addAction('fillColor', function() { ui.menus.pickColor(mxConstants.STYLE_FILLCOLOR); });
	this.addAction('gradientColor', function() { ui.menus.pickColor(mxConstants.STYLE_GRADIENTCOLOR); });
	this.addAction('backgroundColor', function() { ui.menus.pickColor(mxConstants.STYLE_LABEL_BACKGROUNDCOLOR); });
	this.addAction('borderColor', function() { ui.menus.pickColor(mxConstants.STYLE_LABEL_BORDERCOLOR); });
	
	//格式的行为 
	this.addAction('shadow', function() { graph.toggleCellStyles(mxConstants.STYLE_SHADOW); });
	this.addAction('dashed', function() { graph.toggleCellStyles(mxConstants.STYLE_DASHED); });
	this.addAction('rounded', function() { graph.toggleCellStyles(mxConstants.STYLE_ROUNDED); });
	this.addAction('style', function()
	{
		var cells = graph.getSelectionCells();
		
		if (cells != null && cells.length > 0)
		{
			var model = graph.getModel();
			var style = mxUtils.prompt(mxResources.get('enterValue')+ ' (' + mxResources.get('style') + ')',
					model.getStyle(cells[0]) || '');

			if (style != null)
			{
				graph.setCellStyle(style, cells);
			}
		}
	});
	this.addAction('setAsDefaultEdge', function()
	{
		var cell = graph.getSelectionCell();
		
		if (cell != null && graph.getModel().isEdge(cell))
		{
			//采取快照的细胞在调用的时刻 
			var proto = graph.getModel().cloneCells([cell])[0];
			
			//删除输入/ exitxy风格 
			var style = proto.getStyle();
			style = mxUtils.setStyle(style, mxConstants.STYLE_ENTRY_X, '');
			style = mxUtils.setStyle(style, mxConstants.STYLE_ENTRY_Y, '');
			style = mxUtils.setStyle(style, mxConstants.STYLE_EXIT_X, '');
			style = mxUtils.setStyle(style, mxConstants.STYLE_EXIT_Y, '');
			proto.setStyle(style);
			
			//使用边缘模板连接预览 
			graph.connectionHandler.createEdgeState = function(me)
			{
	    		return graph.view.createState(proto);
		    };
	
		    //创建新的连接边缘模板 
		    graph.connectionHandler.factoryMethod = function()
		    {
	    		return graph.cloneCells([proto])[0];
		    };
		}
	});
	this.addAction('image', function()
	{
		function updateImage(value, w, h)
		{
			var select = null;
			var cells = graph.getSelectionCells();
			
			graph.getModel().beginUpdate();
        	try
        	{
        		//没有选中单元格
    			if (cells.length == 0)
    			{
    				var gs = graph.getGridSize();
    				cells = [graph.insertVertex(graph.getDefaultParent(), null, '', gs, gs, w, h)];
    				select = cells;
    			}
    			
        		graph.setCellStyles(mxConstants.STYLE_IMAGE, value, cells);
	        	graph.setCellStyles(mxConstants.STYLE_SHAPE, 'image', cells);
	        	
	        	if (graph.getSelectionCount() == 1)
	        	{
		        	if (w != null && h != null)
		        	{
		        		var cell = cells[0];
		        		var geo = graph.getModel().getGeometry(cell);
		        		
		        		if (geo != null)
		        		{
		        			geo = geo.clone();
			        		geo.width = w;
			        		geo.height = h;
			        		graph.getModel().setGeometry(cell, geo);
		        		}
		        	}
	        	}
        	}
        	finally
        	{
        		graph.getModel().endUpdate();
        	}
        	
        	if (select != null)
        	{
        		graph.setSelectionCells(select);
        		graph.scrollCellToVisible(select[0]);
        	}
		};

    	var value = '';
    	var state = graph.getView().getState(graph.getSelectionCell());
    	
    	if (state != null)
    	{
    		value = state.style[mxConstants.STYLE_IMAGE] || value;
    	}

    	value = mxUtils.prompt(mxResources.get('enterValue') + ' (' + mxResources.get('url') + ')', value);

    	if (value != null)
    	{
    		if (value.length > 0)
    		{
	    		var img = new Image();
	    		
	    		img.onload = function()
	    		{
	    			updateImage(value, img.width, img.height);
	    		};
	    		img.onerror = function()
	    		{
	    			mxUtils.alert(mxResources.get('fileNotFound'));
	    		};
	    		img.src = value;
    		}
        }
	});
};

/**
 * 寄存器的作用在给定的名称.
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
 * 对于给定的参数的一种新的活动构造。
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

//行动继承mxeventsource 
mxUtils.extend(Action, mxEventSource);


Action.prototype.setEnabled = function(value)
{
	if (this.enabled != value)
	{
		this.enabled = value;
		this.fireEvent(new mxEventObject('stateChanged'));
	}
};

/**
 *套动作启用状态statechanged事件。 
 */
Action.prototype.setToggleAction = function(value)
{
	this.toggleAction = value;
};

/**
 *套动作启用状态statechanged事件。 
 */
Action.prototype.setSelectedCallback = function(funct)
{
	this.selectedCallback = funct;
};

/**
 * 套动作启用状态statechanged事件。
 */
Action.prototype.isSelected = function()
{
	return this.selectedCallback();
};

function getTarget(selTarget,ortherObjectCell){
	var needRemoveCells = [];
	for(var e_i = 0;selTarget&&selTarget.edges&&e_i<selTarget.edges.length; e_i++){
		var target = selTarget.edges[e_i].target;
		if(ortherObjectCell&&ortherObjectCell!=null&&target==ortherObjectCell){
			continue;
		}else if(target==selTarget){
			continue;
		}
		needRemoveCells.push(target);
		if(target.edges&&target.edges.length>1){
			needRemoveCells.push.apply(needRemoveCells,getTarget(target,null));
		} 
	}
	return needRemoveCells;
};

function cleanGrid(){
	$(".grid-content").html("");
    if($('.grid-content').data("cacheDs")&&$('.grid-content').data("cacheDs").records){
    	$('.grid-content').data("cacheDs").records=[];
    }
};

function viewSelectRes(initype){
	 var iwidth = 40 ;
	 var iheight = 40 ;
	 var iny = currentNeedSelNodeiny;
	 var inx = currentNeedSelNodeinx;
	 
	 var data =currentNeedSelNode;
	 var seldata = $('.grid-content').llygrid('getSelectedValue','CHECK');
	 iny = iny+120 ;
	 graph   = currentNeedSelGraph;
 	 for(var di=0;data&&di<data.length;di++){
 		var needView = 0;
 		for(var vi=0;vi<seldata.length;vi++){
 			if(data[di].id==seldata[vi]){
 				needView = 1;
 				vi = 999999999;
 			}
 		}
 		//1 代表加载当页所有
 		if(initype==1){
 			needView = 1;
 		}
 		if(needView==0){
 			continue;
 		}
 		var linx = inx;
 		var liny = iny;
 		if(di%2==0){
 			linx = inx+60*di;
 		}else{
 			linx = inx-60*di;
 		}
 		var dataNode =  data[di]; 
		var newcells =  graph.insertVertex(graph.getDefaultParent(), dataNode.id,dataNode.value, linx, liny, iwidth, iheight,"image;image=stencils/clipart/"+dataNode.type+".png");
		var newEdge = graph.insertEdge(graph.getDefaultParent(), "edge"+dataNode.id, "", currentSelCellObject, newcells, "edgeStyle=topToBottomEdgeStyle;");
			
 	}
	  var layout_mx = new mxCompactTreeLayout(graph, false);
	  layout_mx.edgeRouting = false;
	  layout_mx.levelDistance = 120;
	  currentObject.editorUi.executeLayout(layout_mx, true, true);
	  hideSelectRes();
};

function hideSelectRes(){
  $("#divSubResDetailGrid").slideUp("slow");
};
 
