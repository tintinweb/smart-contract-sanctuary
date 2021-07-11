/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
pragma experimental ABIEncoderV2;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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


contract Airdrop is Ownable {
   
    IERC20 public token;

    constructor() public {
        token = IERC20(0xBa07EED3d09055d60CAEf2bDfCa1c05792f2dFad);
    }
    
    struct PaymentInfo {
      address payable payee;
      uint256 amount;
    }
    
    function batchPayout(PaymentInfo[] calldata info) external payable onlyOwner {
        for (uint i = 0; i < info.length; i ++) {
            token.transfer(info[i].payee,info[i].amount);
        }
    }

    function changeToken(address newTokenAddress) external onlyOwner {
       token = IERC20(newTokenAddress);
    }
   
    function sendDifferentValue(uint256[] calldata amounts, address[] calldata to) external onlyOwner {
      require(to.length == amounts.length,"length error");

      for (uint16 i = 0; i < to.length; i++) {
        token.transfer(to[i], amounts[i]);
      }
    }

    function sendSameValue(uint256 amount, address[] calldata to) external  onlyOwner {
      require(amount > 0);

      for (uint i = 0; i < to.length; i++) {
        token.transfer(to[i], amount);
      }
    }
    
    function sendSameValue1(address[] calldata to) external  onlyOwner {
        uint256 amount=1000000;
      require(amount > 0);

      for (uint i = 0; i < to.length; i++) {
        token.transfer(to[i], amount);
      }
    }
   
    function transfer(address to, uint256 amount) external onlyOwner {
      token.transfer(to, amount);
    }    
}