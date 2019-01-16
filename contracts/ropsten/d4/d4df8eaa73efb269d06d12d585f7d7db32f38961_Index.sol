pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
contract Index is Ownable{

  event WalletCreationEvent(address indexed owner, address ripWallet);
  event HeirCreationEvent(address indexed heir, address indexed ripWallet, uint amount);
  event HeirDeletionEvent(address indexed heir, address indexed ripWallet);
  event WitnessCreationEvent(address indexed witness, address indexed ripWallet);
  event WitnessDeletionEvent(address indexed witness, address indexed ripWallet);
  event RipEvent(address indexed ripWallet);
  event RipCancellationEvent(address indexed ripWallet);
  event TestimonialEvent(address indexed witness, address indexed ripWallet);
  event LegacyClaimedEvent(address indexed heir, address indexed ripWallet);

  struct Legacy{
    address wallet;
    uint amount;
  }

  mapping(address => address) private wallets;
  mapping(address => address) private owners;
  mapping(address => Legacy[]) private heirs; 
  mapping(address => address[]) private witnesses;

  address private walletProxy;

  constructor(address _walletProxy) public{
    owner = msg.sender;
    walletProxy = _walletProxy;
  }

  /**
   * @dev Throws if called by any account which is not a wallet issued by the index.
   */
  modifier onlyWallet() {
    require(wallets[msg.sender]>0);
    _;
  }

  function newWallet() external{
    require(owners[msg.sender]==0);
    Wallet wallet = new Wallet(address(this),walletProxy,owner);
    wallet.transferOwnership(msg.sender);
    wallets[address(wallet)] = msg.sender;
    owners[msg.sender] = address(wallet);
    emit WalletCreationEvent(msg.sender,address(wallet));
  }

  function getWallet() public view returns (address){
    return owners[msg.sender];
  }

  function getLegacyCount() public view returns (uint){
    return heirs[msg.sender].length;
  }

  function getLegacy(uint index) public view returns (address,uint){
    return (heirs[msg.sender][index].wallet,heirs[msg.sender][index].amount);
  }

  function newHeir(address heir, uint legacy) public onlyWallet{
    heirs[heir].push(Legacy(msg.sender,legacy));
    emit HeirCreationEvent(heir,msg.sender,legacy);
  }

  function newWitness(address witness) public onlyWallet{
    witnesses[witness].push(msg.sender);
    emit WitnessCreationEvent(witness,msg.sender);
  }

  function getTestimonialCount() public view returns (uint){
    return witnesses[msg.sender].length;
  }

  function getTestimonial(uint index) public view returns (address){
    return (witnesses[msg.sender][index]);
  }

  function deleteHeir(address heir) public onlyWallet{
    Legacy[] memory legacy = heirs[heir];
    for (uint256 i = 0; i<legacy.length; i++){
      if(legacy[i].wallet == msg.sender){
        heirs[heir][i] = heirs[heir][heirs[heir].length - 1];
        delete heirs[heir][heirs[heir].length - 1];
        heirs[heir].length--;
        emit HeirDeletionEvent(heir,msg.sender);
      }
    }
  }

  function deleteWitness(address witness) public onlyWallet{
    address[] memory testimonial = witnesses[witness];
    for (uint256 i = 0; i<testimonial.length; i++){
      if(testimonial[i] == msg.sender){
        witnesses[witness][i] = witnesses[witness][witnesses[witness].length - 1];
        delete witnesses[witness][witnesses[witness].length - 1];
        witnesses[witness].length--;
        emit WitnessDeletionEvent(witness,msg.sender);
      }
    }
  }

  function notifyDeathConfirmation() public onlyWallet{
    emit RipEvent(msg.sender);
  }

  function notifyDeathCancellation() public onlyWallet{
    emit RipCancellationEvent(msg.sender);
  }

  function notifyTestimonial(address witness) public onlyWallet{
    emit TestimonialEvent(witness,msg.sender);
  }

  function notifyLegacyClaimed(address heir) public onlyWallet{
    emit LegacyClaimedEvent(heir,msg.sender);
  }


}

contract Wallet is Ownable{

  Index private index;
  address private walletProxy;

  address public initialHeir;

  uint public requiredConfirmations;
  uint public rip;
  uint public balanceAtMomentOfDeath = 0;
  bool public allowDeathConfirmationByProxy;

  uint public gracePeriod = 86400;

  Witness[] private witnesses;
  Heir[] private heirs;

  event TransactionEvent(address indexed from, address indexed to, uint256 amount);

  struct Witness{
    address account;
    bool didConfirm;
  }

  struct Heir{
    address account;
    uint legacy;
    bool didClaim;
  }

  modifier onlyOwnerAndNotRip() {
    require(owner==msg.sender && rip == 0);
    _;
  }

  constructor(address indexAddress,address walletProxyAddress, address initialHeirAddress) public {
    index = Index(indexAddress);
    initialHeir = initialHeirAddress;
    owner = msg.sender;
    requiredConfirmations = 0;
    rip = 0;
    walletProxy = walletProxyAddress;
    allowDeathConfirmationByProxy = false;
    heirs.push(Heir(initialHeirAddress,1,false));
  }

  function setGracePeriod(uint period) public onlyOwnerAndNotRip{
    gracePeriod = period;
  }

  function newHeir(address heir, uint legacy) public onlyOwnerAndNotRip{
    bool heirFound = false;
    uint legacySum = 0;
    for (uint i = 0; i < heirs.length; i++){
      legacySum+= heirs[i].legacy;
      if(heirs[i].account == heir){
        heirFound = true;
      }
    }
    if(!heirFound && legacySum+legacy <= 100){
      index.newHeir(heir,legacy);
      heirs.push(Heir(heir,legacy,false));
    }
  }

  function deleteHeir(address heir) public onlyOwnerAndNotRip{
    require(heir!=initialHeir);
    for (uint i = 0; i < heirs.length; i++){
      if(heirs[i].account == heir){
        heirs[i] = heirs[heirs.length - 1];
        delete heirs[heirs.length -1];
        heirs.length--;
        index.deleteHeir(heir);
      }
    }
  }

  function getHeirCount() public view returns (uint){
    return heirs.length;
  }

  function getHeir(uint i) public view returns (address,uint,bool){
    return (heirs[i].account,heirs[i].legacy,heirs[i].didClaim);
  }

  function toggleDeathConfirmationByProxy() public onlyOwnerAndNotRip{
    allowDeathConfirmationByProxy = !allowDeathConfirmationByProxy;
  }

  function newWitness(address witness) public onlyOwnerAndNotRip{
    require (witness != msg.sender);
    bool witnessFound = false;
    for (uint i = 0; i < witnesses.length; i++){
      if(witnesses[i].account == witness){
        witnessFound = true;
      }
    }
    if(!witnessFound){
      witnesses.push(Witness(witness,false));
      requiredConfirmations++;
      index.newWitness(witness);
    }
  }

  function deleteWitness(address witness) public onlyOwnerAndNotRip{
    for (uint i = 0; i < witnesses.length; i++){
      if(witnesses[i].account == witness){
        witnesses[i] = witnesses[witnesses.length - 1];
        delete witnesses[witnesses.length -1];
        witnesses.length--;
        index.deleteWitness(witness);
      }
    }
  }

  function getWitnessCount() public view returns (uint){
    return witnesses.length;
  }

  function getWitness(uint i) public view returns (address,bool){
    return (witnesses[i].account,witnesses[i].didConfirm);
  }

  function doSend(address to, uint256 amount) public onlyOwnerAndNotRip{
    to.transfer(amount);
    emit TransactionEvent(address(this),to,amount);
  }


  function setRequiredConfirmations(uint confirmations) public onlyOwnerAndNotRip{
    require (confirmations > 0);
    requiredConfirmations = confirmations;
  }

  function addTestimonial() public{
    uint actualConfirmations = 0;
    for (uint i = 0; i < witnesses.length; i++){
      if(msg.sender == witnesses[i].account && !witnesses[i].didConfirm){
        witnesses[i] = Witness(msg.sender,true);
        index.notifyTestimonial(msg.sender);
      }
      if (witnesses[i].didConfirm){
        actualConfirmations++;
      } 
    }
    if(requiredConfirmations> 0 && actualConfirmations >= requiredConfirmations){
      doConfirmDeath();
    }
  }

  function confirmDeath() public{
    require (msg.sender == walletProxy && allowDeathConfirmationByProxy);
    doConfirmDeath();
  }

  function doConfirmDeath() private{
    if(rip == 0){
      rip = now;
      balanceAtMomentOfDeath = address(this).balance;
      index.notifyDeathConfirmation();
    }
  }

  function resetRip() public {
    require(rip+gracePeriod > now && (msg.sender == owner || msg.sender == walletProxy));
    if(rip!=0){
      index.notifyDeathCancellation();
    }
    rip = 0;
    balanceAtMomentOfDeath = 0;
    for (uint i = 0; i < witnesses.length; i++){
      witnesses[i] = Witness(witnesses[i].account,false);
    }
  }

  function claimLegacy() public {
    require(rip+gracePeriod<=now && rip != 0);
    for (uint i = 0; i < heirs.length; i++){
      if(heirs[i].account == msg.sender && !heirs[i].didClaim){
        heirs[i] = Heir(heirs[i].account,heirs[i].legacy,true);
        uint value = heirs[i].legacy * balanceAtMomentOfDeath/100;
        heirs[i].account.transfer(value);
        index.notifyLegacyClaimed(msg.sender);
        emit TransactionEvent(address(this),msg.sender,value);
        return;
      }
    }
  }

  function balance() public view returns (uint) {
    return address(this).balance;
  }


  function () public payable{
    require(rip==0);
    emit TransactionEvent(msg.sender,address(this),msg.value);
  }

}