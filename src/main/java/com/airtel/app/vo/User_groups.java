package com.airtel.app.vo;

public class User_groups {

	private String username;
	
	private String groupname;

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getGroupname() {
		return groupname;
	}

	public void setGroupname(String groupname) {
		this.groupname = groupname;
	}

	@Override
	public String toString() {
		return "User_groups [username=" + username + ", groupname=" + groupname + "]";
	}
	
	
}
