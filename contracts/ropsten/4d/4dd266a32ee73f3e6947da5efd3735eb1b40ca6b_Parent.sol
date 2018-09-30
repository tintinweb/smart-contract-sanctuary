pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public ;
}

contract Deposit is owned {
	event deposit_eth(uint amount);
	event deposit_token(address token, uint amount);

    function returnTokensAll(address token) public onlyOwner {
        uint256 amount = ERC20(token).balanceOf( address(this) );
	emit deposit_token(token, amount);
        ERC20(token).transfer(owner, amount);
    }
    function () public payable {
	emit deposit_eth(address(this).balance);
        owner.transfer(address(this).balance);
    }
}

contract Parent {

  address public owner;
  address[] public investorlist;


  constructor () public {
    owner = msg.sender;
  }

    function createChild(uint num) public {
        for(uint i=0;i<num;i++){
            Deposit deposit = new Deposit();
            investorlist.push(address(deposit)) -1;
        }
    }
}