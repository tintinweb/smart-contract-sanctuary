pragma solidity ^0.4.24;

interface ERCToken {
    
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract AirdropContract {
    
    address public owner;
    
    ERCToken token;
    
    modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}
    
    constructor() public {
      owner = msg.sender;
    }
    
    function send(address _tokenAddr, address from, address[] dests, uint256[] values) public onlyOwner returns(uint256) {
        uint256 i = 0;
        token = ERCToken(_tokenAddr);
        while (i < dests.length) {
            token.transferFrom(from, dests[i], values[i]);
            i += 1;
        }
        return i;
    }
}