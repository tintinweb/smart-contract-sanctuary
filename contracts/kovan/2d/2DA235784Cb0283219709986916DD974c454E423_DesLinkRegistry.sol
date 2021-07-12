//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DesLinkRegistry is Ownable {

    struct EthPair {
        string ticker;
        uint8 decimals;
        address proxy;
    }

    //token address to EthPair struct
    mapping(address => EthPair) private addressToEthPair;

    event ProxyAdded(
        address indexed owner, 
        address indexed token,
        string ticker,
        address proxy
    );

    event ProxyRemoved(
        address indexed owner, 
        address indexed token,
        string ticker,
        address proxy
    );

    function addProxy(
        string memory _ticker,
        address _token,
        uint8 _decimals,
        address _proxy
        ) external onlyOwner returns(bool added) {
        
        EthPair storage ethPair = addressToEthPair[_token];
        require(
            ethPair.proxy == address(0), 
            "Error: already exists"
        );
        
        ethPair.ticker = _ticker;
        ethPair.proxy = _proxy;
        ethPair.decimals = _decimals;

        emit ProxyAdded(msg.sender, _token, _ticker, _proxy);
        return true;
    }

    function removeProxy(
        address _token
        ) external onlyOwner returns(bool removed) {
        
        EthPair storage ethPair = addressToEthPair[_token];
        require(
            ethPair.proxy != address(0), 
            "Error: does not exist"
        );

        string memory ticker = ethPair.ticker;
        address proxy = ethPair.proxy;

        delete addressToEthPair[_token];

        emit ProxyRemoved(msg.sender, _token, ticker, proxy);
        return true;
    }

    function getProxy(
        address _token
        ) external view returns(address proxy, uint8 tokenDecimals) {
        
        return (
            addressToEthPair[_token].proxy,
            addressToEthPair[_token].decimals
        );
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