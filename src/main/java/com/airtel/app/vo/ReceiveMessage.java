package com.airtel.app.vo;

public class ReceiveMessage {

	private String text;
	
	private String receiver_name;
	
	private boolean group;

	public String getText() {
		return text;
	}

	public void setText(String text) {
		this.text = text;
	}

	public String getReceiver_name() {
		return receiver_name;
	}

	public void setReceiver_name(String receiver_name) {
		this.receiver_name = receiver_name;
	}

	public boolean isGroup() {
		return group;
	}

	public void setGroup(boolean group) {
		this.group = group;
	}

	@Override
	public String toString() {
		return "ReceiveMessage [text=" + text + ", receiver_name=" + receiver_name + ", group=" + group + "]";
	}
	
	
}
