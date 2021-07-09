/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    require(c / a == b, "SafeMath: multiplication overflow");

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
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
contract Ownable is Context {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Purchase is Ownable {
    using SafeMath for uint256;
    address public takeToken = 0x2076A228E6eB670fd1C604DE574d555476520DB7;
    IBEP20 public BUSD = IBEP20(0x013345B20fe7Cf68184005464FBF204D9aB88227);
    uint price; // number of token per 1 ether BUSD;
    struct purchase {
        address token;
        uint start;
        uint end;
        uint min;
    }
    mapping(address => purchase) public purchases;
    address[] public purchaseIndex;
    struct submit {
        IBEP20 token;
        uint amount;
    }
    struct userSell {
        uint[] submitLength;
        mapping(uint => submit) submits;
    }
    mapping(address => userSell) userSells;
    event Sell(address _user, IBEP20 _token, uint _amount, uint _type, uint _block); // _type == 1 => sell now, 2 => waiting
    event Buy(address user, uint submitLengthIndex);
    function token2BUSD(address _token, uint _amount) public view returns(uint) {
        return _amount.mul(10**uint(BUSD.decimals())).div(price);
    }
    function openPurchase(address _token,
        uint _start,
        uint _end,
        uint _min, uint _price) public onlyOwner {
            require(_price > 0 && _start < _end && _end > now, 'datetime invalid');
            if(purchases[address(_token)].min == 0) purchaseIndex.push(_token);
            purchases[_token] = purchase(_token,
            _start,
            _end,
            _min);
            price = _price;
        
    }
    function closePurchase(uint _purchaseIndex) public onlyOwner {
        purchases[purchaseIndex[_purchaseIndex]].end = now;
        purchases[purchaseIndex[_purchaseIndex]].min = 0;
    }
    function getPurchaseIndex() public view returns(address[] memory _purchaseIndex) {
        return purchaseIndex; 
    }
    function getSeller(address _guy) public view returns(uint[] memory _submitLength) {
        _submitLength = userSells[_guy].submitLength; 
    }
    function getSeller(address _guy, uint submitIndex) public view returns(submit memory _submit) {
        _submit = userSells[_guy].submits[submitIndex]; 
    }
    function removeArr(address _user, uint submitLengthIndex) internal {
        userSells[_user].submits[userSells[_user].submitLength[submitLengthIndex]] = submit(IBEP20(0), 0);
        userSells[_user].submitLength[submitLengthIndex] = userSells[_user].submitLength[userSells[_user].submitLength.length - 1];
        userSells[_user].submitLength.length--;
    }
    function refundToken(uint submitLengthIndex) internal {
        uint index = userSells[msg.sender].submitLength[submitLengthIndex];
        require(userSells[msg.sender].submits[index].amount > 0, 'caller is not owner');
        require(userSells[msg.sender].submits[index].token.transfer(msg.sender, userSells[msg.sender].submits[index].amount));
    }
    function _buy(address user, uint submitLengthIndex) internal {
        uint index = userSells[user].submitLength[submitLengthIndex];
        uint _amount = userSells[user].submits[index].amount;
        address _token = address(userSells[user].submits[index].token);
        require(_amount > 0, 'index not exist');
        uint busdAmount = token2BUSD(_token, _amount);
        require(BUSD.transferFrom(msg.sender, user, busdAmount), 'insufficient-allowance');
        require(userSells[user].submits[index].token.transfer(takeToken, _amount), 'insufficient-allowance');
        emit Buy(user, submitLengthIndex);
    }
    function buy(address user, uint submitLengthIndex) public onlyOwner {
        _buy(user, submitLengthIndex);
        removeArr(user, submitLengthIndex);
    }
    function buys(address[] memory _uses, uint[][] memory submitLengthIndexs) public onlyOwner {
        require(_uses.length <= 200, 'array too large');
        for(uint i = 0; i < _uses.length; i++) {
            for(uint j = 0; j < submitLengthIndexs[i].length; j++) {
                _buy(_uses[i], submitLengthIndexs[i][j]);
                userSells[_uses[i]].submits[userSells[_uses[i]].submitLength[submitLengthIndexs[i][j]]] = submit(IBEP20(0), 0);
                userSells[_uses[i]].submitLength[submitLengthIndexs[i][j]] = userSells[_uses[i]].submitLength[userSells[_uses[i]].submitLength.length - (j + 1)];
            }
            userSells[_uses[i]].submitLength.length -= submitLengthIndexs[i].length;
        }
        
    }
    function cancelSell(uint submitLengthIndex) public {
        refundToken(submitLengthIndex);
        removeArr(msg.sender, submitLengthIndex);
    }
    function cancelSells(uint[] memory indexs) public {
        for(uint i = 0; i < indexs.length; i++) {
            refundToken(indexs[i]);
            userSells[msg.sender].submits[userSells[msg.sender].submitLength[indexs[i]]] = submit(IBEP20(0), 0);
            userSells[msg.sender].submitLength[indexs[i]] = userSells[msg.sender].submitLength[userSells[msg.sender].submitLength.length - (i + 1)];
        }
        userSells[msg.sender].submitLength.length -= indexs.length;
        
    }
    function sell(IBEP20 _token, uint _amount) public {
        require(purchases[address(_token)].min > 0 && purchases[address(_token)].min <= _amount && purchases[address(_token)].end > now);
        uint busdAmount = token2BUSD(address(_token), _amount);
        if(getRemainingToken(BUSD) >= busdAmount) {
            require(_token.transferFrom(msg.sender, takeToken, _amount), 'insufficient-allowance');
            BUSD.transfer(msg.sender, busdAmount);
            emit Sell(msg.sender, _token, _amount, 1, block.number);
        } else {
            require(_token.transferFrom(msg.sender, address(this), _amount), 'insufficient-allowance');
            userSells[msg.sender].submits[block.number] = submit(_token, _amount);
            userSells[msg.sender].submitLength.push(block.number);
            emit Sell(msg.sender, _token, _amount, 2, block.number);
        }
    }
    
    function config(address _takeToken, uint _price) public onlyOwner {
        takeToken = _takeToken;
        price = _price;
    }
    function getRemainingToken(IBEP20 _token) public view returns (uint) {
        return _token.balanceOf(address(this));
    }
    function withdrawBEP20(address _to, IBEP20 _bep20, uint _amount) public onlyOwner {
        _bep20.transfer(_to, _amount);
    }
    function withdraw(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}