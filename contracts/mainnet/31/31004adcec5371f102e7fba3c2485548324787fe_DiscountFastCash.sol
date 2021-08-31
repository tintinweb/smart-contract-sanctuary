/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.8.2;


interface IFastCashMoneyPlus {
   function transfer(address _to, uint _amount) external returns (bool success);
   function balanceOf(address addr) external returns (uint256 balance);
}

contract DiscountFastCash {
   IFastCashMoneyPlus public fastcashContract;
   address public owner;
   bool public isLocked;
   uint256 public priceInWei;
   mapping(address => bool) luckyParticipants;

   address platformAddress;
   uint256 platformPercent;

   address charityAddress;
   uint charityPercent;


   constructor(address _fastcashContract, address _platformAddress, address _charityAddress) {
      owner = msg.sender;
      platformAddress = _platformAddress;
      platformPercent = 10;
      charityAddress = _charityAddress;
      charityPercent = 25;
      fastcashContract = IFastCashMoneyPlus(_fastcashContract);
      isLocked = false;
      priceInWei = 250000000000000000;
   }

   modifier onlyOwner(string memory _msg) {
      require(msg.sender == owner, _msg);
      _;
   }

   function transferOwnership(address newOwner) external onlyOwner("Only owner can transfer ownership") {
      owner = newOwner;
   }

   function flipIsLocked() external onlyOwner("Only owner can flip the lock") {
      isLocked = !isLocked;
   }

   function updatePrice(uint256 _newPrice) external onlyOwner("Only owner can update the price") {
      priceInWei = _newPrice;
   }

   function withdraw(uint256 _fastcashAmount) external onlyOwner("Only owner can withdraw") {
      fastcashContract.transfer(msg.sender, _fastcashAmount);
      payable(owner).transfer(address(this).balance);
   }

   function updatePlatform(address _platformAddress, uint256 _platformPercent) external onlyOwner("Only owner can update platform info") {
      platformAddress = _platformAddress;
      platformPercent = _platformPercent;
   }

   function updateCharity(address _charityAddress, uint256 _charityPercent) external onlyOwner("Only owner can update charity info") {
      charityAddress = _charityAddress;
      charityPercent = _charityPercent;
   }

   function updateFastCashContract(address _fastCashContract) external onlyOwner("Only owner can update fast cash address") {
      fastcashContract = IFastCashMoneyPlus(_fastCashContract);
   }

   function buy() external payable {
      require(!isLocked, "Discounts are locked up at the moment");
      require(!luckyParticipants[msg.sender] && fastcashContract.balanceOf(msg.sender) == 0, "Your luck has run out");
      require(fastcashContract.balanceOf(address(this)) > 0, "FastCash balance has run dry");
      require(msg.value >= priceInWei, "Attempted discount too large");
      luckyParticipants[msg.sender] = true;

      uint _platformFee = msg.value * platformPercent / 100;
      uint _charityFee = (msg.value - _platformFee) * charityPercent / 100;
      payable(platformAddress).transfer(_platformFee);
      payable(charityAddress).transfer(_charityFee);
      payable(owner).transfer(msg.value - _platformFee - _charityFee);
      fastcashContract.transfer(msg.sender, 1000000000000000000);
   }

   function donate() external payable {
      payable(owner).transfer(msg.value);
   }
}