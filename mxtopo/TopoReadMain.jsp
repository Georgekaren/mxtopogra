<%@ page language="java" import="java.util.*" pageEncoding="utf-8"%>
<%@page import="com.ztesoft.resmaster.sys.user.UserContext"%>
<%@page import="com.ztesoft.resmaster.sys.CommonConst"%>
<%@page import="com.ztesoft.resmaster.sys.globalize.GlobalizeUtil"%>
<%
    UserContext user = (UserContext) session.getAttribute(CommonConst.USER_CONTEXT);
    String staffId = "";
    if (user != null)
        staffId = user.getUserId();
    if (staffId == null || staffId.trim().equalsIgnoreCase("")) {
        staffId = "1";
    }
    String staff_name = (String) user.getCustomProp().get("userCode");
    String pwd=user.getVoucher().getPassword();
    Map roleMap=user.getGrantedRole();	
    Locale locale =GlobalizeUtil.getLan();
    String lang="",country="";
    if (locale!= null ){
    	lang = locale.getLanguage();
    	country = locale.getCountry(); 	
    }	
    
    String path =request.getContextPath();
    String sfFunctionName =request.getParameter("sfFunctionName");
    String resId =request.getParameter("resId");
    String topoDefId = request.getParameter("topoDefId");
    String intype =request.getParameter("intype");
%>
<head>
    <title>拓扑入口</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=10" /> 
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/jquery-1.6.2.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/jquery-ui-1.8.16.custom.min.js"></script>
    <link rel="stylesheet" type="text/css" href="styles/grapheditor.css">
    <link   href="styles/ui.css" type="text/css" rel="stylesheet" />
    <script src="js/grid.js" type="text/javascript"></script>
    <link   href="styles/grid.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript">
        //全局变量
        var MAX_REQUEST_SIZE = 10485760;
        var MAX_WIDTH = 6000;
        var MAX_HEIGHT = 6000;
    
        //保存地址或导入地址
        var EXPORT_URL = '/visecMc/ExportServlet';
        var SAVE_URL = '/visecMc/SaveMapServlet';
        var OPEN_URL = '/open';
        var RESOURCES_PATH = 'resources';
        var RESOURCE_BASE = RESOURCES_PATH + '/grapheditor';
        var STENCIL_PATH = 'stencils';
        var IMAGE_PATH = 'images';
        var STYLE_PATH = 'styles';
        var CSS_PATH = 'styles';
        var OPEN_FORM = 'open.html';
    
        //指定连接模式为触摸设备(至少有一个应该是正确的)
        var tapAndHoldStartsConnection = true;
        var showConnectorImg = true;
        
        var befor_sel_cell;
        // 解析URL参数。支持参数:
        // - lang = xy:指定用户界面的语言。
        // - 触摸= 1:使touch-style用户界面。
        // - 存储=当地:支持HTML5本地存储。
        var urlParams = (function(url)
        {
            var result = new Object();
            var idx = url.lastIndexOf('?');
    
            if (idx > 0)
            {
                var params = url.substring(idx + 1).split('&');
                
                for (var i = 0; i < params.length; i++)
                {
                    idx = params[i].indexOf('=');
                    
                    if (idx > 0)
                    {
                        result[params[i].substring(0, idx)] = params[i].substring(idx + 1);
                    }
                }
            }
            
            return result;
        })(window.location.href);

        // 设置用户界面语言的基本路径,通过URL参数和配置
        // 支持的语言,以避免404年代。装运的所有核心语言
        // 资源是禁用grapheditor所需的所有资源。
        // 属性。注意,在这个例子中两个资源的加载
        // 文件(特殊包,默认包)是禁用的
        // 保存一个GET请求。这就要求所有资源存在
        // 每个属性文件,因为只有一个文件被加载。
        mxLoadResources = false;
        mxBasePath = '<%=request.getContextPath()%>/topo/mxtopo/';
        mxLanguage = urlParams['lang'];
        mxLanguages = ['de'];
        var topoDefId = '<%=topoDefId%>';
        
        var sfFunctionName = '<%=sfFunctionName%>';
        var inResId = '<%=resId%>';
        var intype = '<%=intype%>';
        if(intype==null){
           //没有传入类型则 默认 使用1 以当前资源为根节点加载下级资源
           intype ="1";
        }
        var current_text ="";
        var head_text ="<mxGraphModel grid=\"0\" guides=\"1\" tooltips=\"1\" connect=\"1\" fold=\"1\" page=\"0\" pageScale=\"1\" pageWidth=\"826\" pageHeight=\"1169\"><root><mxCell id=\"0\" /><mxCell id=\"1\" parent=\"0\" />";
        var end_text ="</root></mxGraphModel>";
        var beforxml = "" ;
        var currentNeedSelNode;
        var currentNeedSelNodeiny = 0;
        var currentNeedSelNodeinx = 0;
        var currentNeedSelGraph ;
        var currentObject ;
        var currentSelCellObject ;
        
    </script>

<script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/mxClient.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Editor.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Graph.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Shapes.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/EditorUiController.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Actions.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/MenusController.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Sidebar.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Toolbar.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/js/Dialogs.js"></script>
    <script type="text/javascript" src="<%=request.getContextPath()%>/topo/mxtopo/jscolor/jscolor.js"></script>
</head>
<body class="geEditor">
    <input type="hidden" id="mapTp" value="dzj"/>
    <input type="hidden" id="path" value="<%=path %>"/>
    <script type="text/javascript">
         // EditorUi更新扩展I / O操作状态
        (function()
        {
            var editorUiInit = EditorUi.prototype.init;
            
            EditorUi.prototype.init = function()
            {
                editorUiInit.apply(this, arguments);
                //this.actions.get('export').setEnabled(false);
                //需要一个后端更新动作状态
               /* if (!useLocalStorage)
                {
                    mxUtils.post(OPEN_URL, '', mxUtils.bind(this, function(req)
                    {
                        var enabled = req.getStatus() != 404;
                        this.actions.get('open').setEnabled(enabled || fileSupport);
                        this.actions.get('import').setEnabled(enabled || fileSupport);
                        this.actions.get('save').setEnabled(true);
                    }));
                }*/ 
            };
        })();
    
        new EditorUi(new Editor());        

			window.onload = function() {
			
			 var sidebardata='<div  id="divSubResPropertyGrid" style ="position: absolute;top: 100px;right: 15px;z-index: 9902;width: 250;height: 300px;overflow: auto;display: block;" ><table><tr><td rowspan="1" colspan="1"></td></tr></table> <div class="grid-content-attr" style="overflow: hidden;"></div></div>';
	         // $(".geSidebarContainer").html(sidebardata);
	          
			  $(".geSidebarContainer").after(sidebardata);
			  $("#divSubResPropertyGrid").hide();
			 //altRows('alternatecolor');
			 var divSubResDetailGrid='<div  id="divSubResDetailGrid" style ="position:absolute;bottom:5px;z-index:9903;left:20px;z-index:9903;width:95%;height:300px;overflow:auto;" ><table><tr><td rowspan="1" colspan="1"></td></tr></table> <div class="grid-content"></div></div>';
	          
	         $(".geDiagramContainer").css("background-color","").css("background-image","");
			 
			  $(".grid-content-attr").llygrid({
				 columns:[
		           	{align:"center",key:"ATTR_NAME",label:"资源属性", width:"100"},
		            {align:"center",key:"ATTR_VALUE",label:"属性值", width:"100"}
		         ],
		         ds:{type:"data",records:[
		           	// {"ATTR_NAME":"编码","ATTR_VALUE":"73834398DEJES0001"}
 				 ]},
				 limit:100,
				 pager: true,
				 width:180,
				 height:180,
				 title:"",
				 querys:{name:"h"},
				 loadMsg:"数据加载中，请稍候......"
			   }) ;
			//  $(".grid-toolbar-div").hide();
			  
			  $(".geMenubarContainer").css("height","0px");
			  $(".geToolbarContainer").css("top","0px");
			  
			  $(".geSidebarContainer").css("overflow","");
			  $(".geSidebarContainer").after(divSubResDetailGrid);
			  $("#divSubResDetailGrid").hide();
			  $(".geHsplit").hide();
			  $(".geVsplit").hide();
			  $(".geSidebarContainer").hide();
			  
			  $(".geDiagramContainer").css("top","50px");
			  $(".geDiagramContainer").css("right","0px");
			  $(".geDiagramContainer").css("width","100%");
			  
			  $(".geOutlineContainer").css("z-index","9901");
			  $(".geOutlineContainer").css("bottom","20px");
			  $(".geOutlineContainer").css("border","1px solid #96c2f1");
			  //$(".geOutlineContainer").css("background","#eff7ff");
			 // border:1px solid #96c2f1;background:#eff7ff
			  $("svg").css("padding-bottom","128px").css("padding-left","50px");
			   $(".grid-content").llygrid({
				columns:[
		           	{align:"center",key:"SERVICE_ID",label:"业务代码", width:"100"}
		         ],
		         ds:{type:"data",records:[]},
				 limit:20,
				 pageSizes:[10,20,30,40],
				 height:180,
				 title:"数据列表",
				 //indexColumn:true,
				 querys:{name:"h"},
				 loadMsg:"数据加载中，请稍候......"
			  }) ;
			  
			  
	       }
    </script>
</body>