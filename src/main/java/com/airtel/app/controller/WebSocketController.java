package com.airtel.app.controller;

import java.security.Principal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.airtel.app.vo.CalcInput;
import com.airtel.app.vo.ReceiveMessage;
import com.airtel.app.vo.Result;
import com.airtel.app.vo.User_groups;
import com.airtel.app.vo.Users;

@Controller
public class WebSocketController {
	
	@Autowired
	public SimpMessagingTemplate template;
	
	@Autowired
	public JdbcTemplate jdbcTemplate;
	
	@Autowired
	protected AuthenticationManager authenticationManager;
	
	@Autowired
	@Qualifier("sessionRegistry")
	private SessionRegistry sessionRegistry;
	
	@RequestMapping("/login")
    public String loginPage()
    {    
    	return"login";
    }
	
	@RequestMapping("/register")
    public String registerPage()
    {
    	return "registration";
    }
	
	@RequestMapping("/dummy-queue")
    public String chat_start3(Model model,Principal principale) {
        model.addAttribute("username", principale.getName());
		return "dummy-queue";
    }
	
	@RequestMapping(value="/registration", method=RequestMethod.POST)
    public String registerPage2(@RequestParam Map<String,String> requestParams,Model model,HttpServletRequest request2,
            HttpServletResponse response2)
    {    	
    	String username = requestParams.get("username");
    	String password = requestParams.get("password");
    	String password2 = requestParams.get("password2");
    	if(!password.equals(password2))
    	{
    		model.addAttribute("error", "Passwords do not match");
    		return "registration";
    	}

    	Users user = null;
    	try{
    		String sql = "select * from userdetails where username = ?";
        	user = (Users)jdbcTemplate.queryForObject(sql, new Object[]{username}, new BeanPropertyRowMapper(Users.class));
    	}catch (EmptyResultDataAccessException e) {
		}
    	if(user!=null)
    	{
    		model.addAttribute("error", "User already exists");
    		return "registration";
    	}
        String sqlSave = "INSERT INTO `userdetails`(`username`, `password`) VALUES (?,?)";
        jdbcTemplate.update(sqlSave, new Object[]{username,password});
    	model.addAttribute("username",username);
		
    	SecurityContext context = SecurityContextHolder.getContext();
    	Authentication request = new UsernamePasswordAuthenticationToken(username, password);
        Authentication result = authenticationManager.authenticate(request);
        context.setAuthentication(result);
        
        sessionRegistry.registerNewSession(request2.getSession().getId(), context.getAuthentication().getPrincipal());
        return "redirect:/dummy-queue";
    }
	
	@RequestMapping(value = "/logout", method = RequestMethod.GET)
    public String logout(HttpServletRequest request,
            HttpServletResponse response,Principal principal) {
        Authentication auth = SecurityContextHolder.getContext()
                .getAuthentication();
        if (auth != null) {
            new SecurityContextLogoutHandler().logout(request, response, auth);
        }
        	
        String usersNamesList = getOnlineUsers();
 		this.template.convertAndSend("/topic/public",usersNamesList);
      
 		String offlineusers = getOfflineUsers();
		this.template.convertAndSend("/topic/offline",offlineusers);
		
 		return "redirect:/dummy-queue";
    }
	
	@MessageMapping("/send3")//sending message
	public void send3(ReceiveMessage message,Principal principal) throws Exception {
		       
		if(message.isGroup())
		{
			this.template.convertAndSend("/topic/"+message.getReceiver_name(), "(From "+principal.getName()+" in group "+message.getReceiver_name()+ "):"+ message.getText());
			return;
		}
		if(!principal.getName().equals(message.getReceiver_name()))
       	{
			this.template.convertAndSendToUser(message.getReceiver_name(), "/queue/private", principal.getName()+" : "+message.getText());
			this.template.convertAndSendToUser(principal.getName(), "/queue/private", principal.getName()+" : "+message.getText());
       	}
	}
	
	@MessageMapping("/send5")//for creating groups
	public void send5(String name,Principal principal) throws Exception {
		String sql = "INSERT INTO `User_groups`(`username`, `groupname`) VALUES (?,?)";
		jdbcTemplate.update(sql, new Object[]{principal.getName(),name});
		showGroups();
	}
	
	@MessageMapping("/send6")//for leaving group
	public void send6(String name,Principal principal) throws Exception {
		           
		String sql = "select * from User_groups where username = ? and groupname = ?";
		User_groups group = (User_groups)jdbcTemplate.queryForObject(sql, new Object[]{principal.getName(),name}, new BeanPropertyRowMapper<>(User_groups.class));
		
		String sqlDelete = "delete from User_groups where username = ? and groupname = ?";
		jdbcTemplate.update(sqlDelete, new Object[]{principal.getName(),name});
		
		
		showGroups();
	}
	
	@MessageMapping("/send10")//for showing everything
	public void send10(Principal principale) throws Exception {
    	
    	String usersNamesList = getOnlineUsers();
		System.out.println(usersNamesList);
 		this.template.convertAndSend("/topic/public",usersNamesList);
 		
 		String offlineusers = getOfflineUsers();
		this.template.convertAndSend("/topic/offline",offlineusers);
 		
		showGroups();
		
		List<String> groupnames = new ArrayList<String>();
		
		String sql = "select * from User_groups where username = ?";
		List<User_groups> groups = jdbcTemplate.query(sql, new Object[]{principale.getName()}, new BeanPropertyRowMapper(User_groups.class));
	   	for(User_groups group:groups)
	   	{
	   		groupnames.add(group.getGroupname());
		}
		String names = Arrays.toString(groupnames.toArray());
		this.template.convertAndSendToUser(principale.getName(), "/queue/groupnames", names);
	
    }
	
	@MessageMapping("/send7")//for showing available groups
	public void send7(Principal principale) throws Exception {
		showGroups();
	}
	
	
	private void showGroups() {
		
		List<String> groupnames = new ArrayList<String>();
		String query= "select * from User_groups";
		List<User_groups> groups = jdbcTemplate.query(query, new BeanPropertyRowMapper(User_groups.class));
	   	for(User_groups group:groups)
	   	{
	   		if(!groupnames.contains(group.getGroupname()))
	   		groupnames.add(group.getGroupname());
		}
		String names = Arrays.toString(groupnames.toArray());
		this.template.convertAndSend("/topic/publicgroups",names);
	}
	

	private String getOnlineUsers() {
		List<Object> principals = sessionRegistry.getAllPrincipals();
 		String usersNamesList = "";
 		for (Object principal: principals) {
 		    if (principal instanceof User) {
 		    		usersNamesList=((User) principal).getUsername()+"<br />"+usersNamesList;
 		    }
 		}
 		
		return usersNamesList;
	}
	
	private String getOfflineUsers() {
    	
    	String usersNamesList = getOnlineUsers();
    	List<String> offline = new ArrayList<String>();
    	String query= "select * from User_groups";
		List<Users> users = jdbcTemplate.query(query, new BeanPropertyRowMapper(Users.class));
	   	for(Users user:users)
	   	{
	   		if(!usersNamesList.contains(user.getUsername()))
	   		{
	   			offline.add(user.getUsername());
	   		}
	   		
		}
		String offlineusers=Arrays.toString(offline.toArray());
		return offlineusers;
	}

	@MessageMapping("/add" )
    @SendTo("/topic/showResult")
    public Result addNum(CalcInput input) throws Exception {
        Thread.sleep(2000);
        Result result = new Result(input.getNum1()+"+"+input.getNum2()+"="+(input.getNum1()+input.getNum2())); 
        return result;
    }
    @RequestMapping("/start")
    public String start() {
        return "start";
    }
}
