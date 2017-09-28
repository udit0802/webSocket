<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<html>
<head>
<!-- <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"> -->

<title>Chat Application</title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

<!-- Latest compiled and minified JavaScript -->
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>

<!-- for select menu -->
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>


<!-- toaster -->   
<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
  <!--  <script src="http://www.jqueryscript.net/demo/jQuery-Bootstrap-Based-Toast-Notification-Plugin-toaster/jquery.toaster.js"></script>
    --><script src="resources/jquery.toaster.js"></script>
   
   
   <!-- notification_titlebar -->
   <script type="text/javascript" src="resources/notification_titlebar.js"></script>
   
   <style type="text/css">
#nav{width:100%;}
#right{float:right;width:100px;color: white;margin-right: 9px;}
#center{margin:0 auto;width:200px;color: white;}
h4{
text-align: center;
color: white;
}
body{
background: rgb(52, 73, 94);
}
.form-control {
border-radius: 5px;
background-color: rgba(8, 8, 8, 0.87);
color: white;
}
.btn{
border-radius: 5px;
background: rgba(8, 8, 8, 0.87); 
color: white;
width: 100%;
}
.form{
background: rgba(236, 236, 236, 0.98);
padding: 30px;
border-radius: 5px;
box-shadow: 0 0px 12px rgba(0, 0, 0, .74);
}
</style>
    <script src="resources/sockjs-0.3.4.js"></script>
    <script src="resources/stomp.js"></script>
    <script type="text/javascript">
    
    document.addEventListener('visibilitychange', function(){
    	titlenotifier.reset();
    })
    
    document.addEventListener('DOMContentLoaded', function () {
  	  if (!Notification) {
  	    alert('Desktop notifications not available in your browser. Try Chromium.'); 
  	    return;
  	  }
  	  if (Notification.permission !== "granted")
  	    Notification.requestPermission();
  	});
  	function notifyMe(title,text) {
  		if (Notification.permission !== "granted")
  	    Notification.requestPermission();
  	  else {
  	    /* var notification = new Notification(title, {
  	      icon: 'http://cdn.sstatic.net/stackexchange/img/logos/so/so-icon.png',
  	      body: text,
  	    }); */
  	  var notification = new Notification(title,{
  	      body: text,
  	    });
  	     notification.onclick = function () {
  	      window.open("http://localhost:8080/ChatApp/dummy-queue");      
  	    }; 
  	  }
  	}
  
  
  
  
  var vis = (function(){
      var stateKey, eventKey, keys = {
          hidden: "visibilitychange",
          webkitHidden: "webkitvisibilitychange",
          mozHidden: "mozvisibilitychange",
          msHidden: "msvisibilitychange"
      };
      for (stateKey in keys) {
          if (stateKey in document) {
              eventKey = keys[stateKey];
              break;
          }
      }
      return function(c) {
          if (c) document.addEventListener(eventKey, c);
          return !document[stateKey];
      }
  })();
  
    </script>
    <script type="text/javascript">
    
   		var stompClient= null;
        var subscriptions={};
        
        function clearAll(){
        	document.getElementById('')
        }
        
        function toast(text)
        {
        	var res = text.split(":");
    	   	var priority = 'success';
   			var title    = res[0];
   			var message  = res[1];
   			var count = (title.match(/${username}/g) || []).length;
   			
   			if(title.indexOf('${username}') == -1)
   				{
   				$.toaster({ priority : priority, title : title, message : message });
   				}
   			if(title.indexOf('group')!=-1)
   				{
   					if(count<2 && title.indexOf('group') < title.indexOf('${username}'))
	   				{
	   					$.toaster({ priority : priority, title : title, message : message });  				
	   				}
   				}
        }
        function connect()
        {
        	var socket = new SockJS('/Spring4WebSocket/add');
            stompClient = Stomp.over(socket);
            stompClient.connect({},function(frame){
        		console.log('Connected'+frame);
        		stompClient.subscribe('/user/queue/private', function(message) {
        	       console.log('message ' + message.body);
        	       showChat(message.body);
        	      });
        		stompClient.subscribe('/topic/publicgroups', function(message) {
        			showgroups(message.body);
                });
        		stompClient.subscribe('/topic/public', function(message) {
        			showusers(message.body);
                });
        		
        		stompClient.subscribe('/user/queue/groupnames', function(message) {
        			getGroups(message.body);
                });
        		
        		stompClient.subscribe('/topic/offline', function(message) {
        			showofflineusers(message.body);
                });
        		/* stompClient.send("/calcApp/send9",{},"");
        		stompClient.send("/calcApp/send8",{},"");
        		stompClient.send("/calcApp/send7",{},""); */
        		
        		
        		stompClient.send("/calcApp/send10",{},"");
        		});
        } 
        function getGroups(message)
        {
        	var message = message.replace("[", "");
        	var message = message.replace("]", "");
        	var res = message.split(", ");
        	var i;
        	for (i = 0; i < res.length; i++) { 
        	    subscriptions[res[i]]=stompClient.subscribe('/topic/'+res[i], function(message) {
           	      showChat(message.body);
           	      });
        	}
        	showjoinedgroups();
        }
        function disconnect()
        {
        	if (stompClient != null) {
        		 stompClient.disconnect();
        		 clearstorage();
            }
            console.log("Disconnected");
        }
        function sendText()
        {
        	/* var sender_name = document.getElementById('name').value; */
        	var text = document.getElementById('input').value;
        	var receiver_name = document.getElementById('receiver').value;
        	if(text!=""&&receiver_name!=""){
        	var group=false;
        	var e = document.getElementById("selectoption");
        	var strUser = e.options[e.selectedIndex].value;
        	if(strUser=="user")
        		{
        		stompClient.send("/calcApp/send3",{}, JSON.stringify({ 'text': text,'receiver_name' : receiver_name, 'group':group}));
        		}
        	if(strUser=="group" && (receiver_name in subscriptions))
        		{
        		group=true;
        		stompClient.send("/calcApp/send3",{}, JSON.stringify({ 'text': text,'receiver_name' : receiver_name, 'group':group}));
        		}
        	}
        }
        
        function showChat(message) {
        	
        if(vis())
        toast(message);
        if(!vis())
        {
        	titlenotifier.add();
        	var res = message.split(":");
        	notifyMe(res[0],res[1]);
        }
        
        var text= document.getElementById('chats').value;
        if(text)
        {text = text +"\r\n" +message;}
        else
        	{text=message;}
        document.getElementById('chats').value=text;
        chatlocal();
    	} 
        
        function creategroup(){
        	var groupname = document.getElementById('creategroupname').value;
        	if(!(groupname in subscriptions))
        	{subscriptions[groupname]=stompClient.subscribe('/topic/'+groupname, function(message) {
     	      console.log('message ' + message.body);
     	      showChat(message.body);
     	      });
        	stompClient.send("/calcApp/send5",{},groupname);
        	}
        	showjoinedgroups();
        }
        function leavegroup(){
        	 var groupname= document.getElementById('leavegroupname').value;
        	 if(groupname in subscriptions)
         	{subscriptions[groupname].unsubscribe();
         	stompClient.send("/calcApp/send6",{},groupname);
         	delete subscriptions[groupname];
         	}
        	 showjoinedgroups();
         }
        function showgroups(message) {
        	var message = message.replace("[", "");
        	var message = message.replace("]", "");
        	var message = message.replace(/,/g, "<br />");
        	if(message=="")
    		{
    		message="No Groups Available";
    		}
        	document.getElementById('groups').innerHTML=message;
        } 
        
        function showusers(message) {
        	 
        	 var message = message.replace("${username}<br />", "");
        	if(message=="")
        		{
        		message="No Online Users";
        		}
        	document.getElementById('users').innerHTML=message;  
        	
             /* var message = message.replace("${username}", "");
        	var message = message.replace("[", "");
        	var message = message.replace("]", "");
        	var message = message.replace(/,/g, "<br />");
        	if(message=="")
    		{
    		message="No Online Users";
    		}
        	document.getElementById('users').innerHTML=message;   */   
        	}
       
         function showjoinedgroups() {
 			
        	var text= "";
 	        for (var key in subscriptions) {
 	        	if (subscriptions.hasOwnProperty(key)) {
 	        	text = text+"<br />"+key;
 	        	 }
 	        }
 	       if(text=="<br />")
 	        	{text="No Groups Joined";}
 	        document.getElementById('joinedgroups').innerHTML=text;
        }
  		function showofflineusers(message) {
  			
  			var message = message.replace("[", "");
        	var message = message.replace("]", "");
        	var message = message.replace(/,/g, "<br />");
        	if(message=="")
    		{
    		message="No Users";
    		}
        	
        	document.getElementById('offline').innerHTML=message; 
  		}
  		
  	    function chatlocal()
  		{
  			localStorage.setItem("chat", document.getElementById("chats").value);
  			console.log("Value is : "+localStorage.getItem("$chat"));
  		} 
  	    function clearstorage()
  	    {
  	    	localStorage.removeItem("chat");
  	    }
  	  </script>
</head>


<body onload="connect();">
<div id="nav">
<div id="right"><a class="btn btn-default" onclick="disconnect();" href="<c:url value='/logout' />" role="button">Logout</a></div> 
  <div id="center"><h3>Welcome ${username}</h3></div>
  </div>    
<div class="container">
	<div class="row">
	<div class="col-lg-3 col-md-3 col-sm-6 col-xs-12">
	
	<div class="form">
	<div class="form-group">
    <label>Create or Join a Group :</label>
    <input type="text" class="form-control" id="creategroupname" placeholder="Enter name of group" />
    <center><button id="creategroup" onclick="creategroup();" class="btn btn-default">Submit</button><br/>
        	</center>
   </div>
   <div class="form-group">
    <label>Leave a Group :</label>
    <input type="text" class="form-control" id="leavegroupname" placeholder="Enter name of group" />
    <center><button id="leavegroup" onclick="leavegroup();" class="btn btn-default">Submit</button><br/>
        	</center>
   </div>
   </div>
   </div>
	
	<div class="col-lg-3 col-md-3 col-sm-6 col-xs-12">
	<div class="form">
	<div class="form-group">
    <label>Enter Text :</label>
    <input type="text" class="form-control" id="input" placeholder="Enter Text Here" required="true"  />
   </div>
   <div class="form-group">
    <label>Select :</label>
     <select class="form-control" id="selectoption">
        <option value="user">User</option>
        <option value="group">Group</option>
      </select>
    </div>
   <div class="form-group">
    <label>Send To :</label>
    <input type="text" class="form-control" id="receiver" required="true" placeholder="Enter destination" />
   </div>
   <center><button id="sendText" onclick="sendText();" class="btn btn-default">Submit</button><br/>
        	</center>
    </div>
   </div>
			
	
	<div class="col-lg-6 col-md-6 col-sm-10 col-xs-12">
	<div class="form">
	<div class="form-group">
	<textarea class="form-control" rows="10" id="chats"></textarea>
    </div>
    </div>
	</div>
	</div>
	
	
	<div class="row">
	
	<div class="col-lg-3 col-md-3 col-sm-6 col-xs-12""><h4>Joined Groups</h4>
	<div class="form">
	<div class="form-group">
	<div id="joinedgroups"></div>
	</div>
    </div>
	</div>
	
	
	<div class="col-lg-3 col-md-3 col-sm-6 col-xs-12""><h4>Show Online Users</h4>
	<div class="form">
	<div class="form-group">
	<div id="users"></div>
	</div>
    </div>
	</div>
	<div class="col-lg-3 col-md-3 col-sm-6 col-xs-12""><h4>Show Groups</h4>
	<div class="form">
	<div class="form-group">
	<div id="groups"></div>
	</div>
    </div>
	</div>
	
	<div class="col-lg-3 col-md-3 col-sm-6 col-xs-12""><h4>Offline Users</h4>
	<div class="form">
	<div class="form-group">
	<div id="offline"></div>
	</div>
    </div>
	</div>
	</div>
</div>		
</body>
<script>
if(localStorage.getItem("chat"))
	{
		document.getElementById("chats").value = localStorage.getItem("chat");
	}
</script>
</html>