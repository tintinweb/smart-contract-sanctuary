pragma solidity ^0.4.24;

contract HelloWorldContact {
	string word = "Hello World";
	address owner;
	
	function HelloWorldContract() {
		owner = msg.sender;
	}

	function getWord() constant returns(string) {
		return word;
	}

	function setWord(string newWord) constant returns(string) {
		if (owner !=msg.sender) {
			return &#39;You shall not pass&#39;;
		}
		word = newWord;
		return &#39;You successfully changed the variable word&#39;;
	}
}