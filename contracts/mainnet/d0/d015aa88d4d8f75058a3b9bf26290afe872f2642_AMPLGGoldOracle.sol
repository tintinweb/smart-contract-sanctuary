// SPDX-License-Identifier: MIT

/* 

    _    __  __ ____  _     ____       _     _       _       
   / \  |  \/  |  _ \| |   / ___| ___ | | __| |     (_) ___  
  / _ \ | |\/| | |_) | |  | |  _ / _ \| |/ _` |     | |/ _ \ 
 / ___ \| |  | |  __/| |__| |_| | (_) | | (_| |  _  | | (_) |
/_/   \_\_|  |_|_|   |_____\____|\___/|_|\__,_| (_) |_|\___/ 
                                

    Ample Gold $AMPLG is a goldpegged defi protocol that is based on Ampleforths elastic tokensupply model. 
    AMPLG is designed to maintain its base price target of 0.01g of Gold with a progammed inflation adjustment (rebase).
    
    Forked from Ampleforth: https://github.com/ampleforth/uFragments (Credits to Ampleforth team for implementation of rebasing on the ethereum network)
    
    GPL 3.0 license
    
    AMPLG_GoldOracle.sol - AMPLG $AMPLG Oracle
  
*/

pragma solidity ^0.6.12;

interface IGoldOracle {
    function getGoldPrice() external view returns (uint256, bool);
    function getMarketPrice() external view returns (uint256, bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
  address private _owner;

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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract AMPLGGoldOracle is IGoldOracle, Ownable {
  
    uint256 goldPrice;
    uint256 marketPrice;

    function setGoldPrice(uint256 _goldprice) external onlyOwner {
        goldPrice = _goldprice;
    }

    function setMarketPrice(uint256 _marketprice) external onlyOwner {
        marketPrice = _marketprice;
    }
    
    function getGoldPrice() external override view returns (uint256, bool) {
        return (goldPrice, true);
    }

    function getMarketPrice() external override view returns (uint256, bool) {
        return (marketPrice, true);
    }
}