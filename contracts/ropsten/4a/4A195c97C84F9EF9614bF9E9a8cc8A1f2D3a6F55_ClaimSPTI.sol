pragma solidity ^0.4.25;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Token {
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}


contract ClaimSPTI {
    
    using SafeMath for uint256;
    
    Token public newTokenReward;
    Token  public oldToken;
    address public creator;
    address public owner = 0x1Ab98C0833e034b1E81F4F0282914C615d795299;
    uint256 public startDate;
    uint256 public endDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);
    constructor() public {
        creator = msg.sender;
        startDate = 1537647506;
        endDate = startDate + 1 hours;
        newTokenReward = Token(0x9f3dbad342b15aef8f8db5d2dec0db9a3c6678df); //Instantiate the new reward
        oldToken = Token(0xd1eb8731efb751f52bd048cd87c60e421d07cefb); //instantiate old token to be replaced
    }
    
    function() public payable {
        
        require(now > startDate);
        require(now < endDate);
        require(msg.value == 0); // Only 0 ether accepted, This is not an IC Oh!
        uint oldSptiUserBal;
        oldSptiUserBal = getBalance(msg.sender); //Get Old SPTI balance
        require(oldSptiUserBal > 0); // Make sure claimant actually possesses Old SPTI
        require(oldToken.transferFrom(msg.sender, address(this), oldSptiUserBal));
        
        //If all of the above happens accordingly, go ahead and release new token
        //to old token holders
        uint256 amount = oldSptiUserBal.div(8);
        newTokenReward.transfer(msg.sender, amount);
        emit FundTransfer(msg.sender, amount, true);

    }
    
    function getBalance(address userAddress) public view returns (uint256){
        uint bal = oldToken.balanceOf(userAddress);
        return bal;
    }
    
    function transferToken(address _to, uint256 _value) isCreator public {
        newTokenReward.transfer(_to, _value);      
    }

    function kill() isCreator public {
        selfdestruct(owner);
    }

}