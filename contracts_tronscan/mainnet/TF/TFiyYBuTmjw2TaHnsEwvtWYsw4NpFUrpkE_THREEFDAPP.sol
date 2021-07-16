//SourceUnit: THREEFDAPP.sol

pragma solidity ^0.4.25;

interface TokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract THREEFDAPP is SafeMath,owned{
    struct UserInfo {
        address userAddress;
        uint256 investmentAmount;
        uint256 serialNumber;
    }
    mapping(uint256 => UserInfo) public userInfos;
    
    struct User {
        address userAddress;
        address referrerAddress;
        uint256 investmentAmount;
        uint256 rewardAmount;
        uint256 dynamicProfitAmount;
        uint256 staticProfitAmount;
        uint256 totalReleaseAmount;
        uint256 waitReleaseAmount;
        uint256 alreadyReleaseAmount;
        uint256 gradeAmount;
        uint256 withdrawalTime;
    }

    address tokenAddress;
    TokenTransfer public tokenTransfers; 
    
    mapping(address => User) public users;
    mapping (address => uint256) public investmentOf;
    
    uint8 decimals = 6;
    uint totalUserId = 0;
    uint256 totalInAmount = 0 ;
    uint256 totalOutAmount = 0 ;
    uint256 totalRewardAmount = 0 ;
    uint256 totalTokenAmount = 0 ;
    uint256 mixInvestmentAmount = 100 * 10 ** uint256(decimals) ;
    address subcoinAddress;
    uint256 miningTotalAmount = 0;
    mapping (address => uint256) public userMiningAmount;
    
    constructor() public {
        tokenAddress = 0xA614F803B6FD780986A42C78EC9C7F77E6DED13C;
        subcoinAddress = 0x78D8E5713F6D5FFAD212E7F30E3A06D70BF26FF8;
        tokenTransfers = TokenTransfer(tokenAddress);
    }
    function registration(uint256 amount,uint256 serialNumber) external {
        require(userInfos[serialNumber].userAddress == address(0), "Repeated serial number");
        require(amount >= mixInvestmentAmount, "Minimum investment: 100u");
        tokenTransfers.transferFrom(msg.sender,subcoinAddress,amount);
        UserInfo memory userInfo = UserInfo({
            userAddress: msg.sender,
            investmentAmount:amount,
            serialNumber:serialNumber
        });
        userInfos[serialNumber] = userInfo;
    }
     function registrationExt(address _referrerAddress,uint256 amount,uint256 serialNumber) external {
        require(userInfos[serialNumber].userAddress == address(0), "Repeated serial number");
        require(amount >= mixInvestmentAmount, "Minimum investment: 100u");
       tokenTransfers.transferFrom(msg.sender,subcoinAddress,amount);
        UserInfo memory userInfo = UserInfo({
            userAddress: msg.sender,
            investmentAmount:amount,
            serialNumber:serialNumber
        });
        userInfos[serialNumber] = userInfo;
        
        User memory user = User({
            userAddress: msg.sender,
            referrerAddress:_referrerAddress,
            investmentAmount:msg.value,
            rewardAmount: uint(0),
            dynamicProfitAmount: uint(0),
            staticProfitAmount:uint(0),
            totalReleaseAmount: SafeMath.safeMul(msg.value,2),
            waitReleaseAmount: SafeMath.safeMul(msg.value,2),
            alreadyReleaseAmount: uint(0),
            gradeAmount:uint(0),
            withdrawalTime:now
        });
        users[msg.sender] = user;
        totalUserId++;
    }
   
    function rankingTransfer(address[] toAddress) external payable onlyOwner {
         require(toAddress.length == 4, "Array of address group 5 is required");
       
        uint256 oneSendAmount = SafeMath.safeDiv(SafeMath.safeMul(msg.value , 40) ,100);
        toAddress[0].transfer(oneSendAmount);
        
        uint256 twoSendAmount = SafeMath.safeDiv(SafeMath.safeMul(msg.value , 30) ,100);
        toAddress[1].transfer(twoSendAmount);
       
        uint256 threeSendAmount = SafeMath.safeDiv(SafeMath.safeMul(msg.value , 20) ,100);
        toAddress[2].transfer(threeSendAmount);
       
        uint256 fourSendAmount = SafeMath.safeDiv(SafeMath.safeMul(msg.value , 10) ,100);
        toAddress[3].transfer(fourSendAmount);
        
    }
    function userProfitWithdraw() external {
        User storage _user = users[msg.sender];
        require(_user.userAddress != address(0), "Users are not involved in the investment");
        uint256 payAmount = 0;
        if(_user.userAddress != address(0)){
           uint256 dayAmount = SafeMath.safeDiv(SafeMath.safeMul(_user.investmentAmount , 1) ,100);
           uint256 dayNumber = (now-_user.withdrawalTime);
           payAmount = SafeMath.safeMul(dayAmount,dayNumber);
        }
        require(payAmount > 0, "The balance of withdrawal quantity is 0");
        require(_user.waitReleaseAmount>0,"The quantity that can be released is 0" );
        if(payAmount > _user.waitReleaseAmount){
           payAmount = _user.waitReleaseAmount;
           _user.userAddress = address(0);
        }
        _user.waitReleaseAmount -= payAmount;
        _user.alreadyReleaseAmount += payAmount;
        _user.withdrawalTime = now;
        _user.userAddress.transfer(payAmount);
        totalOutAmount+=payAmount;
        
    }
   
    function setSubcoinAddress(address _subcoinAddress) external onlyOwner{
        subcoinAddress = _subcoinAddress;
    }
 
    function getUserData(address userAddress) external view returns(uint256 _investmentAmount, uint256 _totalAmount,uint256 _waitAmount,uint256 _alreadyAmount,uint256 _payAmount,uint256 _withdrawalTime){
       User storage _user = users[userAddress];
       uint256 payAmount = 0;
       if(_user.waitReleaseAmount>0){
           if(_user.userAddress != address(0)){
               uint256 dayAmount = SafeMath.safeDiv(SafeMath.safeMul(_user.investmentAmount , 1) ,100);
               uint256 dayNumber = (now-_user.withdrawalTime);
               payAmount = SafeMath.safeMul(dayAmount,dayNumber);
           }
           if(payAmount > _user.waitReleaseAmount){
               payAmount = _user.waitReleaseAmount;
           }
       }
        return(_user.investmentAmount,_user.totalReleaseAmount,_user.waitReleaseAmount,_user.alreadyReleaseAmount,payAmount,_user.withdrawalTime);
    }
    function getGlobalData() external view returns(uint _totalUserId,uint256 _totalRewardAmount,
    uint256 _totalInAmount,uint256 _totalOutAmount){
         return(totalUserId,totalRewardAmount,totalInAmount,totalOutAmount);
    }
	function querDappBalance()public view returns(address _subcoinAddress,uint256 _trxBalance,uint256 _tokenBalance){
	     uint256 tokenBalance = tokenTransfers.balanceOf(address(this));
         return (subcoinAddress,this.balance,tokenBalance);
    }
    function() payable {}
}