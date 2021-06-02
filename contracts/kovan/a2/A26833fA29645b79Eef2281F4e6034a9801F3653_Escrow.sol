// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';

contract Escrow is Ownable {

  /** Oracles */

  mapping(address => string) public oraclesByAddress;
  mapping(string => address) public oraclesById;

  function addOracle(address _address, string calldata _repoId) external onlyOwner {
    require(oraclesById[oraclesByAddress[_address]] == address(0), "Oracle does already exist.");
    oraclesByAddress[_address] = _repoId;
    oraclesById[_repoId] = _address;
  }

  function removeOracle(address _address) external onlyOwner {
    require(oraclesById[oraclesByAddress[_address]] != address(0), "Oracle does not exist.");
    delete oraclesById[oraclesByAddress[_address]];
    delete oraclesByAddress[_address];
  }

  modifier onlyOracle() {
    require(oraclesById[oraclesByAddress[msg.sender]] == msg.sender, "Only allowed for oracles.");
    _;
  }
  
  /** Deposits */

  struct Deposit {
    address from;
    uint256 value;
    string githubId;
  }

  mapping(uint256 => Deposit) public deposits;
  uint256 private nextDepositId = 0;

  event DepositEvent(address from, uint256 value, string githubId, uint256 depositId);

  function deposit(string calldata _githubId) external payable {
    require(msg.value > 0, 'You must send ETH.');

    nextDepositId++;
    deposits[nextDepositId] = Deposit(
      msg.sender,
      msg.value,
      _githubId
    );

    emit DepositEvent(msg.sender, msg.value, _githubId, nextDepositId);
  }

  event ReleaseEvent(uint256 depositId, uint256 value, address to);

  function release(uint256 _depositId, uint256 _value, address _to) external onlyOracle {
    require(deposits[_depositId].value >= _value, "Deposit is smaller than _value.");
    
    // transfer to 98% recipient and 2% and oracle
    payable(_to).transfer(_value * 98  / 100);
    payable(msg.sender).transfer(_value * 2 / 100);

    // reduce deposit
    deposits[_depositId].value -= _value;

    emit ReleaseEvent(_depositId, _value, _to);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100
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