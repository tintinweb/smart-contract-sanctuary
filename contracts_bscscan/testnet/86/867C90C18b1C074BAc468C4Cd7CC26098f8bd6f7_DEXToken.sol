//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DEXToken {
  uint8 LOCK_TIME_MIN_MONTH = 12;
  uint8 LOCK_TIME_MAX_MONTH = 60; 

  struct LockedWallet {
    address userAddress;
    uint256 Amount;
    uint256 InitialLockTime;
    uint256 EndLockTime;
    uint256 AvailableAmount;
    uint8 Percentage;
    bool Exist;
  }


  /**
  * Define List mapped wallets to be locked inside the contract itself
  * Those wallets can be incremeneted in number in future to expose 
  * new projects to the community.
   */
  mapping(address => LockedWallet) _ownerLockedWallet;
  mapping(address => LockedWallet)  _BasicLockedWallet;
  mapping(address => LockedWallet) _ProjectPhaseWallet;

  /**Events */
   event ReadFromLockeData(address _addr, uint256 lockStart, uint256 lockEnd);
   event ExtendedLockExpirationWallet(address _addr, uint256 previousLock, uint256 newlockEnd);
   event StoredLockeData(address _addr, uint256 lockStart, uint256 lockEnd);
   event RunConstructor(string _value);
   event GenericError(string error);

   address[] private ownersWallets = new address[](1);
   address[] private basicWallets = new address[](1);

  /**
  * @dev Base constructor of token
  * @param lockTimeOwnerAddresses total month for lock wallets min value 12 month max 60 month
  * @param locktimeBasicWallets total month for lock wallets min value 12 month max 60 month
  */
  constructor(uint lockTimeOwnerAddresses,uint locktimeBasicWallets) {
  
    emit RunConstructor("Passed data to constructor and finished check");

   
    ownersWallets[0]=0x7F6BD00F6611ad908c1db04e576182833657AE7B;
    basicWallets[0]=0x5757CaaaEe4dD2F9b117782FBc6D0328D398f890;

    InitOwnerWallet(GetLockTime(lockTimeOwnerAddresses));
    emit RunConstructor("Initwallet called");
    InitBasicWallet(GetLockTime(locktimeBasicWallets));
    emit RunConstructor("InitBasic finished");
  }


  /**
  * Create mapped list of lockedWallet for Owners. Those wallet will contains
  * locked funds of initial owners and will be locked for a min of 12 month to a max of 5 years
  * funds locked within this wallet will be relased in percentage each month after first 12 month.
   */
  function InitOwnerWallet(uint256[] memory data) private {
    for (uint256 i = 0; i < ownersWallets.length; i++) {
      _ownerLockedWallet[ownersWallets[i]]=LockedWallet(ownersWallets[i],10000000,data[0],data[1],0,0,true);
      emit StoredLockeData(ownersWallets[i], data[0], data[1]);
    }
  }

  
 function GetLockedWallet() public view returns (LockedWallet[] memory){
    uint totalWallet= (ownersWallets.length + basicWallets.length);
    LockedWallet[] memory lw = new LockedWallet[](totalWallet);
    lw[0]=_ownerLockedWallet[ownersWallets[0]];
    lw[1]=_BasicLockedWallet[basicWallets[0]];
    return lw;
  }
  
  function ExtendWalletLock(uint walletid, uint _days) public {
      require(_days > 0,"Days must be at least 1");
      uint previousLock = _ownerLockedWallet[ownersWallets[walletid]].EndLockTime;
      _ownerLockedWallet[ownersWallets[walletid]].EndLockTime += IncreaseLockTime(_days);
      emit ExtendedLockExpirationWallet(_ownerLockedWallet[ownersWallets[walletid]].userAddress, previousLock, _ownerLockedWallet[ownersWallets[walletid]].EndLockTime);
  }


  function ReleaseFund() public  {
     for (uint256 index = 0; index <= ownersWallets.length-1; index++) {
       if (_ownerLockedWallet[ownersWallets[index]].Percentage < 100) {
         _ownerLockedWallet[ownersWallets[index]].Percentage += 10;
       }
       _ownerLockedWallet[ownersWallets[index]].AvailableAmount = (
         (_ownerLockedWallet[ownersWallets[index]].Amount * _ownerLockedWallet[ownersWallets[index]].Percentage)/100);
     }
    
    for (uint256 index = 0; index <= basicWallets.length -1; index++) {
       if (_BasicLockedWallet[basicWallets[index]].Percentage < 100) {
         _BasicLockedWallet[basicWallets[index]].Percentage += 10;
       }
       _BasicLockedWallet[basicWallets[index]].AvailableAmount = (
         (_BasicLockedWallet[basicWallets[index]].Amount * _BasicLockedWallet[basicWallets[index]].Percentage)
         /100);
     }
  }

  /**
  * Create mapped list of lockedWallet for Owners. Those wallet will contains
  * locked funds of initial owners and will be locked for a min of 12 month to a max of 5 years
  * funds locked within this wallet will be relased in percentage each month after first 12 month.
   */
  function InitBasicWallet(uint256[] memory data) private {
    for (uint256 i = 0; i < basicWallets.length; i++) {
      _BasicLockedWallet[basicWallets[i]]=LockedWallet(basicWallets[i],10000000,data[0],data[1],0,0,true);
      emit StoredLockeData(basicWallets[i], data[0], data[1]);
    }
  }

  function CanSpendToken() public view returns(bool){
    if (ValidateAddressAcrossLimitedWallets() !=true) return true;
    require(_ownerLockedWallet[msg.sender].EndLockTime < block.timestamp,"WALLET LIMITED FROM CONTRACT");
    return true;
  }
  function ValidateAddressAcrossLimitedWallets() private view returns(bool){
    return _ownerLockedWallet[msg.sender].Exist;
  }
   function GetLockTime(uint lockTime) private view returns (uint256[] memory){
    uint256[] memory data = new uint256[](2);
    data[0]=block.timestamp;
    data[1]=data[0] + lockTime * 30 * 24 * 60 * 60;
    return data;
  }
  function IncreaseLockTime(uint _day) private pure returns (uint256){
      return (_day * 24 * 60 * 60);
  }
}