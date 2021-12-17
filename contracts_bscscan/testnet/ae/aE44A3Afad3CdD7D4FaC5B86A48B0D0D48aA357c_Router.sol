// SPDX-License-Identifier: GNU GPL

pragma solidity ^0.8.9;

import "./utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Router is ReentrancyGuard, Ownable {

  uint private totalEthDistributed;
  uint private totalShares = 1; //Contract has one share to prevent failed withdrawls due to rounding errors

  mapping(address => Acct) private accts;
  address[] private acctList;

  event AcctAdded(address addr, uint256 shares);
  event AcctRemoved(address addr);
  event EmergencyWithdraw(bool success);

  struct Acct {
    uint256 initAt;
    uint256 totalWithdrawn;
    uint256 acctShares;
  }

  function initAcct(address _addr, uint256 _acctShares) external onlyOwner {
    require(accts[_addr].acctShares == 0, "Acct already exists");
    accts[_addr] = Acct({
      initAt: address(this).balance,
      totalWithdrawn: 0,
      acctShares: _acctShares
      });
    totalShares += _acctShares;
    acctList.push(_addr);
    emit AcctAdded(_addr, _acctShares);
  }

  function removeAcct(address addr) external onlyOwner {
    Acct memory acct = getAcctInfo(addr);
    require(acct.acctShares > 0, "No account");
    uint index = _indexOfAcctList(addr);
    _removeIndex(index);
    delete(accts[addr]);
    totalShares -= acct.acctShares;
    emit AcctRemoved(addr);
  }

  function withdraw() external nonReentrant {
    require(address(this).balance >= 0, "zero withdraw");
    require(accts[msg.sender].acctShares > 0, "no shares");
    uint amt = getPendingWithdrawl(msg.sender);
    require(amt > 0, "Nothing to withdraw");
    accts[msg.sender].totalWithdrawn += amt;
    totalEthDistributed += amt;
    _withdraw(msg.sender, amt);
  }

  function getPendingWithdrawl(address addr) public view returns(uint) {
    Acct memory acct = getAcctInfo(addr);
    uint contractBal = address(this).balance;
    uint userApplicableBal = (totalEthDistributed + contractBal) - acct.initAt;
    uint userTotalAmt = userApplicableBal * acct.acctShares / totalShares;
    uint userPendingAmt = userTotalAmt - acct.totalWithdrawn;
    return userPendingAmt;
  }

  function getAcctInfo(address addr) public view returns(Acct memory) {
    return accts[addr];
  }

  function getTotalShares() public view returns(uint) {
    return totalShares;
  }

  function getAcctList() public view returns(address[] memory) {
    return acctList;
  }

  function _indexOfAcctList(address _addr) private view returns(uint i) {
    for(i = 0; i<acctList.length; i++){
      if(_addr == acctList[i]) return i;
    }
    return i+1;
  }

  function _removeIndex(uint index) private {
    require(index < acctList.length);
    acctList[index] = acctList[acctList.length-1];
    acctList.pop();
  }

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  function emergencyWithdraw() external onlyOwner {
      uint amt = address(this).balance;
      (bool success, ) = owner().call{value: amt}("");
      require(success, "Transfer failed.");
      emit EmergencyWithdraw(success);
  }

  receive() external payable {}
}

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}