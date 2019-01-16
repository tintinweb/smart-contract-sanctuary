pragma solidity ^0.4.25;

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner);
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);}
  function owner() public view returns(address) {
    return _owner;}
  modifier onlyOwner() {
    require(isOwner());
    _;}
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;}
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);}
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);}
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;}}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;}
    uint256 c = a * b;
    require(c / a == b);
    return c;}
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;}
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;}
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;}
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;}}
contract distribution is Ownable {
    using SafeMath for uint256;
    event OnDepositeReceived(address investorAddress, uint value);
    event OnPaymentSent(address investorAddress, uint value);
    uint public minDeposite = 10000000000000000; // 0.01 eth
    uint public maxDeposite = 10000000000000000000000; // 10000 eth
    uint public currentPaymentIndex = 0;
    uint public amountForDistribution = 0;
    uint public amountRaised;
    uint public depositorsCount;
    uint public percent = 120;
    address distributorWallet;    // wallet for initialize distribution
    address promoWallet;    
    address techWallet1;
    address techWallet2;
    struct Deposite {
        address depositor;
        uint amount;
        uint depositeTime;
        uint paimentTime;}
    Deposite[] public deposites;
    mapping ( address => uint[]) public depositors;
    modifier onlyDistributor () {
        require (msg.sender == distributorWallet);
        _;}
    function setDistributorAddress(address newDistributorAddress) public onlyOwner {
        require (newDistributorAddress!=address(0));
        distributorWallet = newDistributorAddress;}
    function setNewMinDeposite(uint newMinDeposite) public onlyOwner {
        minDeposite = newMinDeposite;}
    function setNewMaxDeposite(uint newMaxDeposite) public onlyOwner {
        maxDeposite = newMaxDeposite;}
    function setNewWallets(address newWallet1, address newWallet2) public onlyOwner {
        techWallet1 = newWallet1;
        techWallet2 = newWallet2;}
    function setPromoWallet(address newPromoWallet) public onlyOwner {
        require (newPromoWallet != address(0));
        promoWallet = newPromoWallet;}
    constructor () public {
        distributorWallet = address(0xD9C310E7C8B0D5D71e6f8Ef27D040ccf662D676b);
        promoWallet = address(0x9dAe93630Fdf1EA30A72842E945fd2af244bB772);
        techWallet1 = address(0x59614e272fD797d58a7a151bc035404Dd823654E);
        techWallet2 = address(0x123BEf936F03386Fe980183DAaef3340254e084d);}
    function () public payable {
        require ( (msg.value >= minDeposite) && (msg.value <= maxDeposite) );
        Deposite memory newDeposite = Deposite(msg.sender, msg.value, now, 0);
        deposites.push(newDeposite);
        if (depositors[msg.sender].length == 0) depositorsCount+=1;
        depositors[msg.sender].push(deposites.length - 1);
        amountForDistribution = amountForDistribution.add(msg.value);
        amountRaised = amountRaised.add(msg.value);
        emit OnDepositeReceived(msg.sender,msg.value);}
    function distribute (uint numIterations) public onlyDistributor {
        promoWallet.transfer(amountForDistribution.mul(3).div(100));
        distributorWallet.transfer(amountForDistribution.mul(1).div(100));
        techWallet1.transfer(amountForDistribution.mul(3).div(100));
        techWallet2.transfer(amountForDistribution.mul(3).div(100));
        uint i = 0;
        uint toSend = deposites[currentPaymentIndex].amount.mul(percent).div(100);    // 120% of user deposite
        while ( (i <= numIterations) && ( address(this).balance > toSend)  ) {
            deposites[currentPaymentIndex].depositor.transfer(toSend);
            deposites[currentPaymentIndex].paimentTime = now;
            emit OnPaymentSent(deposites[currentPaymentIndex].depositor,toSend);
            currentPaymentIndex = currentPaymentIndex.add(1);
            i = i.add(1);
            if(currentPaymentIndex < deposites.length)
            toSend = deposites[currentPaymentIndex].amount.mul(percent).div(100);    // 120% of user deposite
        }
        amountForDistribution = 0;}
    function getAllDepositorsCount() public view returns(uint) {
        return depositorsCount;}
    function getAllDepositesCount() public view returns (uint) {
        return deposites.length;}
    function getLastDepositId() public view returns (uint) {
        return deposites.length - 1;}
    function getDeposit(uint _id) public view returns (address, uint, uint, uint){
        return (deposites[_id].depositor, deposites[_id].amount, deposites[_id].depositeTime, deposites[_id].paimentTime);}
    function getDepositesCount(address depositor) public view returns (uint) {
        return depositors[depositor].length;}
    function getAmountRaised() public view returns (uint) {
        return amountRaised;}
    function getLastPayments(uint lastIndex) public view returns (address, uint, uint) {
        uint depositeIndex = currentPaymentIndex.sub(lastIndex).sub(1);
        require ( depositeIndex >= 0 );
        return ( deposites[depositeIndex].depositor , deposites[depositeIndex].paimentTime , deposites[depositeIndex].amount.mul(percent).div(100) );}
    function getUserDeposit(address depositor, uint depositeNumber) public view returns(uint, uint, uint) {
        return (deposites[depositors[depositor][depositeNumber]].amount,
                deposites[depositors[depositor][depositeNumber]].depositeTime,
                deposites[depositors[depositor][depositeNumber]].paimentTime);}
    function getDepositeTime(address depositor, uint depositeNumber) public view returns(uint) {
        return deposites[depositors[depositor][depositeNumber]].depositeTime;}
    function getPaimentTime(address depositor, uint depositeNumber) public view returns(uint) {
        return deposites[depositors[depositor][depositeNumber]].paimentTime;}
    function getPaimentStatus(address depositor, uint depositeNumber) public view returns(bool) {
        if ( deposites[depositors[depositor][depositeNumber]].paimentTime == 0 ) return false;
        else return true;}}