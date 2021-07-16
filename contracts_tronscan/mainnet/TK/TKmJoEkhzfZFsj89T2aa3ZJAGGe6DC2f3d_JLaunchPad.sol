//SourceUnit: ITRC20.sol

/// TRC20.sol -- API for the TRC20 token standard

// See <https://github.com/tronprotocol/tips/blob/master/tip-20.md>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity ^0.5.9;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: JLaunchPad.sol

pragma solidity 0.5.9;

import './SafeMath.sol';
import './ITRC20.sol';
import './ReentrancyGuard.sol';


contract JLaunchPad is ReentrancyGuard {
  using SafeMath for uint256;
  // Info of each user.
  struct UserInfo {
      uint256 amount;   // How many tokens the user has provided.
  }

  // admin address
  address public adminAddress;
  // The offering token
  ITRC20 public offeringToken;
  // The raising token
  ITRC20 public raisingToken;
  // The block number when IFO starts
  uint256 public startBlock;
  // The block number when IFO ends
  uint256 public endBlock;
  // total amount of raising tokens need to be raised
  uint256 public raisingAmount;
  // total amount of offeringToken that will offer
  uint256 public offeringAmount;
  // total amount of raising tokens that have already raised
  uint256 public totalAmount;
  // address => amount
  mapping (address => UserInfo) public userInfo;
  // participators
  address[] public addressList;


  event Deposit(address indexed user, uint256 amount);
  event Harvest(address indexed user, uint256 offeringAmount);

  constructor(
      ITRC20 _offeringToken,
      ITRC20 _raisingToken,
      uint256 _startBlock,
      uint256 _offeringAmount,
      uint256 _raisingAmount,
      address _adminAddress
  ) public {
      offeringToken = _offeringToken;
      startBlock = _startBlock;
      offeringAmount = _offeringAmount;
      raisingAmount= _raisingAmount;
      totalAmount = 0;
      adminAddress = _adminAddress;
      raisingToken = _raisingToken;
  }

  modifier onlyAdmin() {
    require(msg.sender == adminAddress, "admin: wut?");
    _;
  }

  function setOfferingAmount(uint256 _offerAmount) public onlyAdmin {
    require (block.number < startBlock, 'no');
    offeringAmount = _offerAmount;
  }
  
  function setAdminWallet(address _addr) public onlyAdmin {
    adminAddress = _addr;
  }

  function setRaisingAmount(uint256 _raisingAmount) public onlyAdmin {
    require (block.number < startBlock, 'no');
    raisingAmount= _raisingAmount;
  }

  function deposit(uint256 _amount) public payable {
    require (block.number > startBlock, 'not ifo time');
    require (_amount > 1, 'need _amount > 1');
    require(totalAmount <= raisingAmount, "Total Raising was maximum");
	require(raisingToken.allowance(msg.sender, address(this)) >= _amount, "Token allowance too low");
	
    _safeTransferFrom(msg.sender, adminAddress, _amount);
    
    if (userInfo[msg.sender].amount == 0) {
      addressList.push(address(msg.sender));
    }
    
    userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(_amount);
    totalAmount = totalAmount.add(_amount);
    
    emit Deposit(msg.sender, _amount);
    uint256 offeringTokenAmount = getOfferingAmount(msg.sender, _amount);
    
    offeringToken.transfer(address(msg.sender), offeringTokenAmount);
    emit Harvest(msg.sender, offeringTokenAmount);
  }
  
  function _safeTransferFrom(address _sender, address _recipient, uint _amount) private {
        bool sent = raisingToken.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
  }

  // allocation 100000 means 0.1(10%), 1 meanss 0.000001(0.0001%), 1000000 means 1(100%)
  function getUserAllocation(address _user) public view returns(uint256) {
    return userInfo[_user].amount.mul(1e12).div(totalAmount).div(1e6);
  }

  // get the amount of IFO token you will get
  function getOfferingAmount(address _user, uint256 _amount) public view returns(uint256) {
    if (totalAmount > raisingAmount) {
      uint256 allocation = getUserAllocation(_user);
      return offeringAmount.mul(allocation).div(1e6);
    }
    else {
      // userInfo[_user] / (raisingAmount / offeringAmount)
      return _amount.mul(offeringAmount).div(raisingAmount);
    }
  }


  function getAddressListLength() external view returns(uint256) {
    return addressList.length;
  }

  function finalWithdraw(uint256 _offerAmount, address payable _addr) public onlyAdmin {
    require (address(this).balance > 0, 'not enough token 0');
    require (_offerAmount < offeringToken.balanceOf(address(this)), 'not enough token 1');
    (bool success, ) = _addr.call.value(address(this).balance)("");
    require(success, 'Failed');
    offeringToken.transfer(address(msg.sender), _offerAmount);
  }
}


//SourceUnit: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}