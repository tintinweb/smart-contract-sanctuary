/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity ^0.8.4;

interface TOken{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract preSale{
     TOken public token;
    using SafeMath for uint256;

    address payable public owner;
    
    uint256 public tokenPerBnb;
    uint256 public preSaleTime;
    uint256 public amountRaised;
    uint256 public soldToken;
    uint256 public maxSell;

    modifier onlyOwner() {
        require(msg.sender == owner,"BEP20: Not an owner");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);

    constructor() {
   //     owner = payable(0x64cB30A482e15F27e2db28c64DBB12D247F1f33c);
        token = TOken(0x9e37a9853e5F15C42Ff5453864f874323f0fd7eD);
        tokenPerBnb = 10000000;
        preSaleTime = block.timestamp + 30 days;
    }
    
  //  receive() payable external{}
 
    function buyToken() payable public {
        require(block.timestamp < preSaleTime,"BEP20: PreSale over");
        
        uint256 numberOfTokens = bnbToToken(msg.value);
        token.transferFrom(owner, msg.sender, numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        soldToken = soldToken.add(numberOfTokens);
        
        emit BuyToken(msg.sender, numberOfTokens);
    }
    
    // to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPerBnb).div(1e10);
        return numberOfTokens;
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
   
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}