pragma solidity ^0.4.25;

contract Ownable {
    
    address public owner = 0x0;
    
    constructor() public {
        owner = msg.sender;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract CryptoSoulPresale is Ownable{
    struct DataBase{
        uint256 deposit;
        uint256 soulValue;
    }
    
    event Deposit(address indexed _from, uint256 _value);
    
    mapping(address => DataBase) walletsData;
    address[] internal wallets;
    
    uint24 public depositsCount = 0;
    
    uint256 public soulCap = 83300000;
    
    uint256 public collectedFunds = 0;
    uint256 public distributedTokens = 0;
    
    uint256 public soulReward0 = 125000;
    uint256 public soulReward1 = 142800;
    uint256 public soulReward2 = 166600;
    
    uint256 public minDeposit = 0.01 ether;
    uint256 public ethPriceLvl0 = 0.99 ether;
    uint256 public ethPriceLvl1 = 6.99 ether;
    
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
        walletsData[msg.sender].deposit += ethValue;
        walletsData[msg.sender].soulValue += soulValue;
        collectedFunds += ethValue;
        distributedTokens += soulValue;
        emit Deposit(msg.sender, msg.value);
    }
  
  function getDepositValue(address _owner) public view returns(uint256){
      return walletsData[_owner].deposit;
  }
  
  function balanceOf(address _owner) public view returns(uint256){
      return walletsData[_owner].soulValue;
  }
   
   function changeSoulReward(uint256 _value0, uint256 _value1, uint256 _value2) public onlyOwner{
      soulReward0 = _value0;
      soulReward1 = _value1;
      soulReward2 = _value2;
      recountUsersBalance();
   }
   
   function changeMinDeposit(uint256 _value) public onlyOwner{
       minDeposit = _value;
   }
   
   function changeSoulCap(uint256 _value) public onlyOwner{
       soulCap = _value;
   }
   
   function addUser(address _wallet, uint256 _depositValue) public onlyOwner{
       require(walletsData[_wallet].deposit == 0);
       saveUserWallet(_wallet);
       walletsData[_wallet].deposit = _depositValue;
       uint256 soulValue = getSoulByEth(_depositValue);
       walletsData[_wallet].soulValue = soulValue;
       distributedTokens += soulValue;
       collectedFunds += _depositValue;
   }
   
   function recountUsersBalance() internal{
       int256 distributeDiff = 0; 
       for(uint24 i = 0; i < wallets.length; i++){
           address wallet = wallets[i];
           uint256 originalValue = walletsData[wallet].soulValue;
           walletsData[wallet].soulValue = getSoulByEth(walletsData[wallet].deposit);
           distributeDiff += int256(walletsData[wallet].soulValue - originalValue);
       }
       if(distributeDiff < 0){
           uint256 uDistrributeDiff = uint256(-distributeDiff);
           require(distributedTokens >= uDistrributeDiff);
           distributedTokens -= uDistrributeDiff;
       }else{
            uint256 totalSoul = distributedTokens + uint256(distributeDiff);
            require(totalSoul <= soulCap);
            distributedTokens = totalSoul;
       }
   }
   
   function assignOldUserFunds(address[] _oldUsersWallets, uint256[] _values) public onlyOwner{
       wallets = _oldUsersWallets;
       for(uint24 i = 0; i < wallets.length; i++){
           uint256 depositValue = _values[i];
           uint256 soulValue = getSoulByEth(_values[i]);
           walletsData[wallets[i]].deposit = depositValue;
           walletsData[wallets[i]].soulValue = soulValue;
           collectedFunds += depositValue;
           distributedTokens += soulValue;
       }
   }
   
   function saveUserWallet(address _address) internal{
       wallets.push(_address);
   }
   
   function getResidualEtherAmount(uint256 _ethValue, uint256 _soulResidual) internal view returns(uint256){
      return _soulResidual * 10 ** 18 / getRewardLevel(_ethValue);
  }
  
   function getSoulByEth(uint256 _ethValue) internal view returns(uint256){
       return (_ethValue * getRewardLevel(_ethValue)) / 10 ** 18;
   }
   
   function getRewardLevel(uint256 _ethValue) internal view returns(uint256){
        if (_ethValue <= ethPriceLvl0){
           return soulReward0;
       } else if (_ethValue > ethPriceLvl0 && _ethValue <= ethPriceLvl1){
           return soulReward1;
       } else if (_ethValue > ethPriceLvl1){
           return soulReward2;
       }
   }
   
   function countUser(address _owner) internal{
       if (walletsData[_owner].deposit == 0){
           saveUserWallet(_owner);
       }
   }
   
   function getUsersCount() public view returns(uint256){
       return wallets.length;
   }
}