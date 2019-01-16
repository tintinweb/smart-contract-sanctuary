pragma solidity ^0.4.25;

contract Ownable {
    
    address public owner = 0x0;
    
    constructor() public {
        owner = msg.sender;
    }
}

contract TokenSale is Ownable{
    struct DataBase{
        uint256 deposit;
        uint256 soulValue;
    }
    
    mapping(address => DataBase) wallets;
    
    uint8 public usersCount = 0;
    uint8 public depositsCount = 0;
    
    uint256 public constant soulCap = 25000000;
    
    uint256 public collectedFunds = 0;
    uint256 public distributedTokens = 0;
    
    uint256 internal constant soulReward0 = 20000;
    uint256 internal constant soulReward1 = 22000;
    uint256 internal constant soulReward2 = 25000;
    
    uint256 public constant minDeposit = 0.5 ether;
    uint256 internal constant ethPriceLvl0 = 2.99 ether;
    uint256 internal constant ethPriceLvl1 = 9.99 ether;
    
    function() external payable{
        require(msg.value >= minDeposit &&
        distributedTokens < soulCap);
        uint256 ethValue = msg.value;
        uint256 soulValue = getSoulByEth(ethValue);     
        uint256 totalSoulValue = distributedTokens + soulValue;
        if (totalSoulValue > soulCap){
            soulValue = soulCap - distributedTokens;
            ethValue = getResidualEtherAmount(ethValue, soulValue);
            uint256 etherNickel = msg.value - ethValue;
            msg.sender.transfer(etherNickel);
        }
        owner.transfer(ethValue);
        depositsCount++;
        countUser(msg.sender);
        wallets[msg.sender].deposit += ethValue;
        wallets[msg.sender].soulValue += soulValue;
        collectedFunds += ethValue;
        distributedTokens += soulValue;
    }
  
  function getDepositValue(address _owner) public view returns(uint256){
      return wallets[_owner].deposit;
  }
  
  function balanceOf(address _owner) public view returns(uint256){
      return wallets[_owner].soulValue;
  }
  
  function getResidualEtherAmount(uint256 _ethValue, uint256 _soulResidual) internal pure returns(uint256){
      return _soulResidual * 10 ** 18 / getRewardLevel(_ethValue);
  }
  
   function getSoulByEth(uint256 _ethValue) internal pure returns(uint256){
       return (_ethValue * getRewardLevel(_ethValue)) / 10 ** 18;
   }
   
   function getRewardLevel(uint256 _ethValue) internal pure returns(uint256){
        if (_ethValue <= ethPriceLvl0){
           return soulReward0;
       } else if (_ethValue > ethPriceLvl0 && _ethValue <= ethPriceLvl1){
           return soulReward1;
       } else if (_ethValue > ethPriceLvl1){
           return soulReward2;
       }
   }
   
   function countUser(address _owner) internal{
       if (wallets[_owner].deposit == 0){
           usersCount++;
       }
   }
   
}