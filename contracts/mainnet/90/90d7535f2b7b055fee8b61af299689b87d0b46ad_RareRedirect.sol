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
        return msg.data;
    }
}

/*
 *
 *
                                                             
                                                             
                                                             
888d888 8888b.  888d888 .d88b.                               
888P"      "88b 888P"  d8P  Y8b                              
888    .d888888 888    88888888                              
888    888  888 888    Y8b.                                  
888    "Y888888 888     "Y8888                               
                                                             
                                                             
                                                             
                     888 d8b                          888    
                     888 Y8P                          888    
                     888                              888    
888d888 .d88b.   .d88888 888 888d888 .d88b.   .d8888b 888888 
888P"  d8P  Y8b d88" 888 888 888P"  d8P  Y8b d88P"    888    
888    88888888 888  888 888 888    88888888 888      888    
888    Y8b.     Y88b 888 888 888    Y8b.     Y88b.    Y88b.  
888     "Y8888   "Y88888 888 888     "Y8888   "Y8888P  "Y888 
                                                             


 This contract is unaudited. It's basically a ponzi.
 It's worse than a ponzi. It's definitely not "trustless".
 DNS is centralized. I'll change the URL if I deem it
 harmful/illegal/etc. No guarantees, no refunds.                                                          



 *
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RareRedirect is Ownable {
    // minimum price required to change the `currentUrl`
    uint256 public priceFloor;
    // current URL where site will be redirected
    string currentUrl = "";

    event redirectChange(string currentURL, uint256 priceFloor);

    function getUrl() public view returns (string memory) {
        return currentUrl;
    }

    function setUrlPayable(string memory newRedirectUrl)
        external
        payable
        returns (string memory)
    {
        require(
            msg.value > priceFloor,
            "Value must be greater than priceFloor"
        );
        currentUrl = newRedirectUrl;
        priceFloor = msg.value;

        emit redirectChange(currentUrl, priceFloor);
        return currentUrl;
    }

    function setUrlForOwner(string memory ownerUrl)
        public
        onlyOwner
        returns (string memory)
    {
        currentUrl = ownerUrl;

        emit redirectChange(currentUrl, priceFloor);
        return currentUrl;
    }

    function getPriceFloor() public view returns (uint256) {
        return priceFloor;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
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