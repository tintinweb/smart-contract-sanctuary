pragma solidity ^0.4.10;

contract Token{
	function transfer(address to, uint value) returns (bool ok);
}

contract Faucet {

	address public tokenAddress;
	Token token;

	function Faucet(address _tokenAddress) {
		tokenAddress = _tokenAddress;
		token = Token(tokenAddress);
	}
  
	function getToken() {
		if(!token.transfer(msg.sender, 1)) throw;
	}

	function () {
		getToken();
	}

}