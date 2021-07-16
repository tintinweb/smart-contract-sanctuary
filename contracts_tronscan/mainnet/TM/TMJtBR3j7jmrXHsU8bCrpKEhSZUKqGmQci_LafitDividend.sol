//SourceUnit: LafitDividend.sol

pragma solidity ^0.5.10;

contract IToken{

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}


contract ILafit{


  function userInfo3(address _addr) view external returns (uint256 bonus,uint256 partnerBonusTotal,uint256 partnerAmount,uint256 partnerWithdrawn,bool isPartner);

}


contract LafitDividend{
  using SafeMath for uint256;


  struct User {

    uint256 partnerWithdrawn;
    uint256 userTotalWithdraw;
    bool isPartner;
  }

  IToken token;
  ILafit lafit;
  address owner;


  constructor(IToken _token,ILafit _lafit) public payable{
    owner = msg.sender;
    token = _token;
    lafit = _lafit;
  }
  function() external payable{}

  mapping (address => User) public users;


  function dividend(address _addr) external returns(bool res){
    (uint256 bonus,uint256 partnerBonusTotal,uint256 partnerAmount,uint256 partnerWithdrawn,bool isPartner) = lafit.userInfo3(_addr);
    User storage user =users[_addr];
    user.partnerWithdrawn = partnerWithdrawn;
    if(isPartner){
      uint amount;
      if(user.userTotalWithdraw <= partnerWithdrawn){
        amount = partnerWithdrawn - user.userTotalWithdraw ;
      }

      bool flag = token.transfer(msg.sender,amount);
      if(flag == true){
        user.userTotalWithdraw += amount;
      }
      user.isPartner =isPartner;
    }

  }







  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}



library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}