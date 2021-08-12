pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IGOBToken.sol";
import "./IGOBVault.sol";

contract GOBVault is IGOBVault, Ownable {
    
  uint _currentRound = 0;
  IGOBToken _tokenContract;

  mapping(uint => mapping(address => bool)) _alreadyPaid;
  mapping(uint => uint) _roundBalances;
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;

  event Withdrawn(address indexed payee, uint256 weiAmount);

  constructor() {
    _status = _NOT_ENTERED;
  }

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

  function getCurrentRound() public view virtual override returns (uint currentRound) {
    return _currentRound;
  }

  function nextRound() public onlyOwner {
    _currentRound++;
    _roundBalances[_currentRound] = 0;
  }

  function setTokenContract(address tokenContract) public onlyOwner {
    _tokenContract = IGOBToken(tokenContract);
  }

  function getCurrentUserSupply() public view returns(uint) {
    uint balance = _tokenContract.getSupplyByRoundAndUser(_currentRound, msg.sender);
    return balance;
  }

  function getVaultBalanceByRound(uint round) public view returns(uint) {
    return _roundBalances[round];
  }

  function getCurrentVaultBalance() public view returns(uint) {
    return _roundBalances[_currentRound];
  }

  function getUserBalance(uint round) public view returns(uint) {
    uint units = _tokenContract.getSupplyByRoundAndUser(round, msg.sender);
    return _roundBalances[_currentRound] * units;
  }
  
  function withdraw(uint round) public nonReentrant() {
    require(round < _currentRound, "Current round is not eligible to withdraw");
    require(_alreadyPaid[round][msg.sender] == false, "Has already been withdrawn");
    require(round >= 0, "Round number can not be negative");

    _alreadyPaid[round][msg.sender] = true;
    uint userBalance = getUserBalance(round);

    require(address(this).balance >= userBalance, "Address: insufficient balance");
    (bool success, ) = msg.sender.call{value: userBalance}("");
    require(success, "Address: unable to send value, recipient may have reverted");

    emit Withdrawn(msg.sender, userBalance);
  }

  function forceWithdraw(address userAddress) public onlyOwner {
    uint toTransfer = 0;
    for(uint i = 0; i < _currentRound; i++) {
      if(_alreadyPaid[i][userAddress] == false) {
          _alreadyPaid[i][userAddress] = true;
          uint userBalance = getUserBalance(i);
          toTransfer += userBalance;
      }          
    }

    if (toTransfer > 0) {
      require(address(this).balance >= toTransfer, "Address: insufficient balance");
      (bool success, ) = userAddress.call{value: toTransfer}("");
      require(success, "Address: unable to send value, recipient may have reverted");
      emit Withdrawn(userAddress, toTransfer);
    }
  }

  receive() external payable {
    _roundBalances[_currentRound] += msg.value;
  }

}

pragma solidity ^0.8.2;

interface IGOBToken {
  function getSupplyByRoundAndUser(uint round, address user) external view returns(uint);
}

pragma solidity ^0.8.2;

interface IGOBVault {
    function getCurrentRound() external view returns(uint currentRound);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}