/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;


library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
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
    emit OwnershipTransferred(_owner, address(0));
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}

contract IBEP721 {
    function transferFrom(address from, address to, uint256 tokenId) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
}
contract MultiTransfer is Ownable {
    using SafeMath for uint256;
    
    modifier checkArrayArgument(address [] _receivers, uint256[] _amounts) {
        require(_receivers.length == _amounts.length && _receivers.length > 0);
        _;
    }


    function transferMultiToken(IBEP20 token, address[] _addresses, uint256 [] amounts) checkArrayArgument(_addresses, amounts) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], amounts[i]);

        }
    }


    function transferMultiToken721(IBEP721 token, address[] _addresses, uint256[] _tokenIds) checkArrayArgument(_addresses, _tokenIds) public {
        require(token.isApprovedForAll(msg.sender, address(this)));
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _tokenIds[i]);

        }
    }
    function transferMulti(address[] receivers, uint256[] amounts) checkArrayArgument(receivers, amounts) public payable {
        for (uint256 j = 0; j < amounts.length; j++) {
            receivers[j].transfer(amounts[j]);
        }
    }
    
    function transferMulti2(address[] receivers, uint256 amount) public payable {
        for (uint256 j = 0; j < receivers.length; j++) {
            receivers[j].transfer(amount);
        }
    }
}