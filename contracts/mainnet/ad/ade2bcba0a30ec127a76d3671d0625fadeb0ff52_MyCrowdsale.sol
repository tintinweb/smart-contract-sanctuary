pragma solidity ^0.4.18;


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
contract owned {


	    address public owner;


	    function owned() payable public {
	        owner = msg.sender;
	    }
	    
	    modifier onlyOwner {
	        require(owner == msg.sender);
	        _;
	    }


	    function changeOwner(address _owner) onlyOwner public {
	        owner = _owner;
	    }
	}
contract Crowdsale is owned {
	    
	    uint256 public totalSupply;
	    mapping (address => uint256) public balanceOf;


	    event Transfer(address indexed from, address indexed to, uint256 value);


	    function Crowdsale() payable owned() public {
	        totalSupply = 10000000000;
	        balanceOf[this] = 1000000000;
	        balanceOf[owner] = totalSupply - balanceOf[this];
	        Transfer(this, owner, balanceOf[owner]);
	    }




	    function () payable public {
	        require(balanceOf[this] > 0);
	        uint256 tokensPerOneEther = 10000;
	        uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
	        if (tokens > balanceOf[this]) {
	            tokens = balanceOf[this];
	            uint valueWei = tokens * 1000000000000000000 / tokensPerOneEther;
	            msg.sender.transfer(msg.value - valueWei);
	        }
	        require(tokens > 0);
	        balanceOf[msg.sender] += tokens;
	        balanceOf[this] -= tokens;
	        Transfer(this, msg.sender, tokens);
	    }
	}
contract MyToken is Crowdsale {
	    
	    string  public standard    = &#39;Token 0.1&#39;;
	    string  public name        = &#39;MARIO Fans Token&#39;;
	    string  public symbol      = "MARIO";
	    uint8   public decimals    = 0;


	    function MyToken() payable Crowdsale() public {}


	    function transfer(address _to, uint256 _value) public {
	        require(balanceOf[msg.sender] >= _value);
	        balanceOf[msg.sender] -= _value;
	        balanceOf[_to] += _value;
	        Transfer(msg.sender, _to, _value);
	    }
	}
contract MyCrowdsale is MyToken {


	    function MyCrowdsale() payable MyToken() public {}
	    
	    function withdraw() public onlyOwner {
	        owner.transfer(this.balance);
	    }
	    
	    function killMe() public onlyOwner {
	        selfdestruct(owner);
	    }
	}