/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

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


    uint public tokenSellPrice=0.005 ether;
    uint public tokenBuyPrice=0.007 ether;
    uint public minBuy=10;
    uint public maxBuy=1000;
    uint public minSale=10;
    uint public maxSale=50;
    event Bought(address user,uint256 amount,uint price);
    event Sold(address user,uint256 amount,uint price);
    

    IERC20 public token;
    address public owner;
    constructor(IERC20 _hexa) public {
        owner=msg.sender;
        token = _hexa;
    }

    function buy(uint amount) payable public {
         address _user=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(_user)
        }
        require(size == 0, "cannot be a contract");
        uint256 eVal=(amount*tokenBuyPrice);
        require(msg.value>=eVal,"Invalid Amount");
        uint256 dexBalance = token.balanceOf(address(this));
        require(amount >=minBuy && amount <=maxBuy, "Check Quantity");
        uint256 amountTobuy = amount*100000000;
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(msg.sender,amount,tokenBuyPrice);
    }

    function sell(uint256 amount) public {
        address _user=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(_user)
        }
        require(size == 0, "cannot be a contract");
        require(amount >=minSale && amount<=maxSale, "Check Quantity");
        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 amountToSell = amount*100000000;
        require(allowance >= amountToSell, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amountToSell);
        uint256 eVal=(amount*tokenSellPrice);
        msg.sender.transfer(eVal);
        emit Sold(msg.sender,amount,tokenSellPrice);
    }
    
    function updateSetting(uint bprice, uint sprice, uint miBuy, uint mxBuy, uint miSell, uint mxSell) public
    {
        address _user=msg.sender;
        uint32 size;
        assembly {
            size := extcodesize(_user)
        }
        require(size == 0, "cannot be a contract");

        require(msg.sender==owner,"Only Owner");
        if(bprice>0)
        tokenBuyPrice=bprice;
        if(sprice>0)
        tokenSellPrice=sprice;
        if(miBuy>0)
        minBuy=miBuy;
        if(mxBuy>0)
        maxBuy=mxBuy;
        if(miSell>0)
        minSale=miSell;
        if(mxSell>0)
        maxSale=mxSell;
        
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