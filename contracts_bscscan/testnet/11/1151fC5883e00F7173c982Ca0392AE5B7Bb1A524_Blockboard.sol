// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/UintArrayUtils.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Blockboard is Ownable, ReentrancyGuard {

    using UintArrayUtils for uint64[];

    // messageData is a single string composed of multiple fields that can be dissected to create a listing card.

    // Global Variabes
    bool public pauseBillboard = false;

    uint256 public constant denominator = 10000;
    uint256 public postCreationMin = 1000000;
    uint256 public totalEthStaked;
    uint256 public totalShares;
    uint256 public vaultRate;
    uint256 public numAdvertisements;

    address public vault;
    address public lendingVault;
    address public withdrawAddr;

    struct Account {
      uint64[] boardIdsInvested;
      mapping(uint => uint) storedEthById;
    }

    struct Advertisement {
        uint256 value;
        uint256 inst_value;
        uint64 timestamp;
        address op;
        bool exists;
        string messageData;
    }

    mapping (uint => Advertisement) private advertisements;
    mapping (address => Account) private accounts;

    event NewAdvertisementAdded(uint advertisementID, string _messageData, address _op, uint value, uint inst_value, uint timestamp);
    event ValueToAdvertisementUpdated(uint advertisementID, string _messageData, address _op, uint value, uint inst_value, uint timestamp);

    constructor() {
    }

    function getAdvertisement(uint adId) public view returns (Advertisement memory) {
      return advertisements[adId];
    }

    function getAccountInvestedIds(address user) public view returns (uint64[] memory) {
      return accounts[user].boardIdsInvested;
    }

    function getAccountInvestmentsById(address user, uint adId) public view returns (uint) {
      return accounts[user].storedEthById[adId];
    }

    function addNewAdvertisement(string memory _messageData) external payable returns (uint advertisementID) {
        require(pauseBillboard == false, "Billboard is paused");
        require(msg.value >= postCreationMin, "Post fee below minimum");
        advertisementID = numAdvertisements++;

        uint initialValue = msg.value - postCreationMin;
        if (initialValue > 0){
          totalEthStaked += initialValue;
          accounts[msg.sender].boardIdsInvested.push(uint64(advertisementID));
          accounts[msg.sender].storedEthById[advertisementID] += initialValue;
        }

        advertisements[advertisementID] = Advertisement({
            messageData: _messageData,
            op: tx.origin,
            value: initialValue,
            inst_value: initialValue,
            timestamp: uint64(block.timestamp),
            exists: true
        });
        emit NewAdvertisementAdded(
          advertisementID,
          _messageData,
          tx.origin,
          initialValue,
          initialValue,
          block.timestamp);
    }

    function addValueToAdvertisement(uint advertisementID, uint amount) internal {
        require(pauseBillboard == false, "Billboard is paused");
        Advertisement storage advertisement = advertisements[advertisementID];
        require(advertisement.exists == true, "No post at this index");
        uint postValue = amount;
        advertisement.value += postValue;
        advertisement.inst_value = postValue;
        advertisement.timestamp = uint64(block.timestamp);

        emit ValueToAdvertisementUpdated(
          advertisementID,
          advertisement.messageData,
          advertisement.op,
          advertisement.value,
          advertisement.inst_value,
          advertisement.timestamp);
    }

    function removeValueFromAdvertisement(uint advertisementID, uint amount) internal {
        require(pauseBillboard == false, "Billboard is paused");
        Advertisement storage advertisement = advertisements[advertisementID];
        require(advertisement.exists == true, "No post at this index");
        advertisement.value -= amount;

        emit ValueToAdvertisementUpdated(
          advertisementID,
          advertisement.messageData,
          advertisement.op,
          advertisement.value,
          advertisement.inst_value,
          advertisement.timestamp);
    }

    function enterStaking(uint adId) public payable {
      require(pauseBillboard == false, "Billboard is paused");

      uint amount = msg.value;
      totalEthStaked += amount;

      uint currentInvest = accounts[msg.sender].storedEthById[adId];
      if (currentInvest > 0) {
        accounts[msg.sender].boardIdsInvested.push(uint64(adId));
      }

      addValueToAdvertisement(adId, amount);
      accounts[msg.sender].storedEthById[adId] += amount;
    }

    function leaveStaking(uint amount, uint adId) external nonReentrant {

      // Do withdraw from liq route

      require(amount > 0, "Zero withdraw");
      require(pauseBillboard == false, "Billboard is paused");
      uint currentInvest = accounts[msg.sender].storedEthById[adId];
      require(currentInvest >= amount, "Withdraw over account balance");

      uint newBal = currentInvest - amount;

      if (newBal == 0) {
        accounts[msg.sender].boardIdsInvested.RemoveByValue(adId);
      }

      accounts[msg.sender].storedEthById[adId] -= amount;
      totalEthStaked -= amount;

      uint256 vaultFee = amount * vaultRate / denominator;
      uint256 transferAmt = amount - vaultFee;

      removeValueFromAdvertisement(adId, amount);

      (bool success, ) = (vault).call{value:vaultFee}("");
      require(success, "Transfer failed.");
      (success, ) = (msg.sender).call{value:transferAmt}("");
      require(success, "Transfer failed.");
    }

    // The below function can be very gas expensive, depending on the array length.
    // Make sure to return gas-related error reporting on the frontend!

    function leaveStakingAll() external nonReentrant {

      // Do withdraw from liq route

      uint withdrawAmt;
      uint64[] memory positions = accounts[msg.sender].boardIdsInvested;

      for (uint i; i < positions.length; i++) {
        uint adId = accounts[msg.sender].boardIdsInvested[i];
        uint amount = accounts[msg.sender].storedEthById[adId];

        accounts[msg.sender].storedEthById[adId] -= amount;
        withdrawAmt += amount;
      }

      totalEthStaked -= withdrawAmt;
      uint256 vaultFee = withdrawAmt * vaultRate / denominator;
      uint256 transferAmt = withdrawAmt - vaultFee;
      delete(accounts[msg.sender].boardIdsInvested);

      (bool success, ) = (vault).call{value:vaultFee}("");
      require(success, "Transfer failed.");
      (success, ) = (msg.sender).call{value:transferAmt}("");
      require(success, "Transfer failed.");
    }

    function setPostCreationMin(uint _postCreationMin) external onlyOwner {
      postCreationMin = _postCreationMin;
    }

    function setBillboardPause(bool _pauseBillboard) external onlyOwner {
        pauseBillboard = _pauseBillboard;
    }

    function setVaultRate(uint _vaultRate) external onlyOwner {
        vaultRate = _vaultRate;
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vault = _vaultAddress;
    }

    function setLendingVaultAddress(address _lendingVaultAddress) external onlyOwner {
        lendingVault = _lendingVaultAddress;
    }

    function withdrawToVault(uint amount) external {
      require(vault == _msgSender(), "Vault: caller is not the Vault");
      (bool success, ) = (vault).call{value:amount}("");
      require(success, "Transfer failed.");
    }

    function withdrawToLendingVault(uint amount) external {
      require(lendingVault == _msgSender(), "Vault: caller is not the Vault");
      (bool success, ) = (vault).call{value:amount}("");
      require(success, "Transfer failed.");
    }

    function getBalance() internal view returns(uint) {
        return address(this).balance;
    }

    // important to receive ETH
    receive() payable external {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.9;

library UintArrayUtils {

  /** Finds the index of a given value in an array. */
  function IndexOf(uint64[] storage values, uint value) internal view returns(uint) {
    uint64 index;
    uint64 i;
    for (i=0; i<values.length; i++){
        if (values[i] == value){
            index = i;
        }
    }
    return index;
  }

  /** Removes the value at the given index in an array. */
  function RemoveByIndex(uint64[] storage values, uint index) internal {
    values[index] = values[values.length-1];
    values.pop();
  }

  /** Removes the given value in an array. */
  function RemoveByValue(uint64[] storage values, uint value) internal {
    uint index = IndexOf(values, value);
    RemoveByIndex(values, index);
  }

}