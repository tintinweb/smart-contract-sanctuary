/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity >=0.5.0 <0.6.0;
contract IERC20 {
    function balanceOf(address account) external view returns (uint){}
    function transfer(address recipient, uint amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint){}
    function approve(address spender, uint amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint amount) external returns (bool){}
    function decimals() public view returns (uint8) {}
}


contract buyToken{
    using SafeMath for uint;
    uint currentTRXPrice;
    // uint currentUSDTPrice;
    address payable owner;
    address payable tokenSender;
    uint public tokenPrice;
    IERC20 public token;
    IERC20 usdtToken;
    IERC20 busdToken;
    modifier onlyOwner(){
        require(msg.sender == owner, "Not Owner");
        _;
    }
    
    constructor() public{
        tokenPrice = 7e12;
        token = IERC20(0xFB896E6dF6493be4A0e07e489DEd1515fD75d594);
        usdtToken = IERC20(0x0080a0189c7c5739eCE3eD850070485fE2c3F0c1);
        busdToken = IERC20(0x0080a0189c7c5739eCE3eD850070485fE2c3F0c1);
        owner = msg.sender;
    }

    function changeOwner(address payable newOwner) external onlyOwner{
        owner = newOwner;
    }
    
    function buyLGTwithUSDT(uint amountOfTokens) external{
        require(usdtToken.transferFrom(msg.sender, owner, amountOfTokens), "Amount not transferred");
        token.transfer(msg.sender, (amountOfTokens.div(tokenPrice)));
    }

    function buyLGTwithBUSD(uint amountOfTokens) external{
        require(busdToken.transferFrom(msg.sender, owner, amountOfTokens), "Amount not transferred");
        token.transfer(msg.sender, (amountOfTokens.div(tokenPrice)));
    }

    function withdrawRemainingLGT(uint amount) external onlyOwner{
        token.transfer(owner, amount);
    }
}


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}