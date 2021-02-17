/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract HEXA_DEX{


    uint public tokenPrice=0.007 ether;
    event Bought(address user,uint256 amount);
    event Sold(address user,uint256 amount);


    IERC20 public token;
    address public owner;
    constructor(IERC20 _hexa) public {
        owner=msg.sender;
        token = _hexa;
    }

    function buy(uint amount) payable public {
        uint256 eVal=(amount*tokenPrice);
        require(msg.value>=eVal,"Invalid Amount");
        uint256 dexBalance = token.balanceOf(address(this));
        require(amount >=10, "You need to send some Ether");
        uint256 amountTobuy = amount*100000000;
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(msg.sender,amount);
    }

    function sell(uint256 amount) public {
        require(amount >=10, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 amountToSell = amount*100000000;
        require(allowance >= amountToSell, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amountToSell);
        uint256 eVal=(amount*tokenPrice);
        msg.sender.transfer(eVal);
        emit Sold(msg.sender,amount);
    }
    
    function changeTokenPrice(uint price) public
    {
        require(msg.sender==owner,"Only Owner");
        tokenPrice=price;
    }
    
    function withdrawBalance(uint _type, uint amt,address payable user) public
    {
        require(msg.sender==owner,"Only Owner");
        require(_type==1 || _type==2, "Invalid Request");
        if(_type==1)
        {
          user.transfer(amt);  
        }
        else
        {
          token.transfer(user, amt);  
        }
        
    }
    

}