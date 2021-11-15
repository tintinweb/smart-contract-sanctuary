// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "../libraries/SafeMath.sol";
import "../libraries/Ownable.sol";

interface ISubscription {
    function getAmountsOut(uint256 _amountIn)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MainPool is Ownable {
    constructor(
        address _IDOLAddress,
        address _PEACHAddress,
        address _feeAddress,
        uint256 _IDOLFee,
        uint256 _PEACHFee,
        uint256 _claimPeriod
    ) public {
        FeeAddress = _feeAddress;
        IDOLAddress = _IDOLAddress;
        PEACHAddress = _PEACHAddress;
        IDOLFee = _IDOLFee;
        PEACHFee = _PEACHFee;
        claimPeriod = _claimPeriod;
    }

    using SafeMath for uint256;

    mapping(address => uint256) private creatorBalance;
    mapping(address => uint256) private creatorTipBalance;
    mapping(address => uint256) private creatorLastClaim;
    address private IDOLAddress;
    address private PEACHAddress;
    address private FeeAddress;
    uint256 private claimPeriod;
    uint256 private IDOLFee;
    uint256 private PEACHFee;

    event Claim(
        address creator,
        uint256 amount,
        uint256 feeAmount,
        uint256 finalAmount
    );
    event ClaimTip(
        address creator,
        uint256 amount,
        uint256 feeAmount,
        uint256 finalAmount
    );
    
    event TransferToPool(
        address user,
        address creator,
        uint256 amount
    );
    
    event TransferTipToPool(
        address user,
        address creator,
        uint256 amount
    );

    function setClaimPeriod(uint256 _claimPeriod) public onlyOwner {
        claimPeriod = _claimPeriod;
    }

    function setIDOLFee(uint256 _IDOLFee) public onlyOwner {
        IDOLFee = _IDOLFee;
    }

    function setPEACHFee(uint256 _PEACHFee) public onlyOwner {
        PEACHFee = _PEACHFee;
    }

    function setIDOLAddress(address _idolAddress) external onlyOwner {
        IDOLAddress = _idolAddress;
    }

    function setPEACHAddress(address _peachAddress) external onlyOwner {
        PEACHAddress = _peachAddress;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        FeeAddress = _feeAddress;
    }

    function transferToPool(
        address _userAddress,
        address _creatorAddress,
        uint256 _amount
    ) external {
        IERC20 token = IERC20(IDOLAddress);
        uint256 userBalance = token.balanceOf(_userAddress);
        require(userBalance != 0, "insufficient amount");
        require(userBalance > _amount, "insufficient amount to transfer");
        token.transferFrom(_userAddress, address(this), _amount);
        
        emit TransferToPool(_userAddress, _creatorAddress, _amount);
        // add balance to creator for future creator withdraw
        creatorBalance[_creatorAddress] = creatorBalance[_creatorAddress].add(
            _amount
        );
    }

    function transferTipToPool(
        address _userAddress,
        address _creatorAddress,
        uint256 _amount
    ) external {
        IERC20 token = IERC20(PEACHAddress);
        uint256 userBalance = token.balanceOf(_userAddress);
        require(userBalance != 0, "insufficient amount");
        require(userBalance > _amount, "insufficient amount to transfer");
        token.transferFrom(_userAddress, address(this), _amount);
        
        emit TransferTipToPool(_userAddress, _creatorAddress, _amount);
        // add balance to creator tip  for future creator withdraw ti[]
        creatorTipBalance[_creatorAddress] = creatorTipBalance[_creatorAddress]
            .add(_amount);
    }

    function checkIDOLBalance(address _address)
        public
        view
        returns (uint256 balance)
    {
        IERC20 token = IERC20(IDOLAddress);
        return token.balanceOf(_address);
    }

    function checkPEACHBalance(address _address)
        public
        view
        returns (uint256 balance)
    {
        IERC20 token = IERC20(PEACHAddress);
        return token.balanceOf(_address);
    }

    function checkCreatorLastClaim(address _creatorAddress)
        public
        view
        returns (uint256 lastClaimBlock)
    {
        return creatorLastClaim[_creatorAddress];
    }

    function checkClaim(address _creatorAddress)
        public
        view
        returns (
            uint256 withdrawAmount,
            uint256 fee,
            uint256 actualWithdrawAmount
        )
    {
        require(
            creatorBalance[_creatorAddress] != 0,
            "creator insufficient amount"
        );

        uint256 blockPassed = block.number.sub(
            creatorLastClaim[_creatorAddress]
        );
        uint256 claimAmount;

        if (blockPassed / claimPeriod >= 1) {
            claimAmount = creatorBalance[_creatorAddress];
        } else {
            claimAmount = (creatorBalance[_creatorAddress].mul(blockPassed))
                .div(claimPeriod);
        }

        uint256 feeAmount = (claimAmount.mul(IDOLFee)).div(100);
        uint256 finalClaimAmount = claimAmount.sub(feeAmount);
        return (claimAmount, feeAmount, finalClaimAmount);
    }

    function checkTipClaim(address _creatorAddress)
        public
        view
        returns (
            uint256 withdrawAmount,
            uint256 fee,
            uint256 actualWithdrawAmount
        )
    {
        require(
            creatorTipBalance[_creatorAddress] != 0,
            "creator insufficient amount"
        );
        uint256 claimAmount = creatorTipBalance[_creatorAddress];
        uint256 feeAmount = (claimAmount.mul(IDOLFee)).div(100);
        uint256 finalClaimAmount = claimAmount.sub(feeAmount);

        return (claimAmount, feeAmount, finalClaimAmount);
    }

    function viewIDOLFee() public view returns (uint256 feeAmount) {
        return IDOLFee;
    }

    function viewPEACHFee() public view returns (uint256 feeAmount) {
        return PEACHFee;
    }

    function viewClaimPeriod() public view returns (uint256 period) {
        return claimPeriod;
    }

    function claim() external {
        require(creatorBalance[msg.sender] != 0, "creator insufficient amount");
        uint256 blockPassed = block.number.sub(creatorLastClaim[msg.sender]);
        uint256 claimAmount;

        if (blockPassed / claimPeriod >= 1) {
            claimAmount = creatorBalance[msg.sender];
        } else {
            claimAmount = (creatorBalance[msg.sender].mul(blockPassed)).div(
                claimPeriod
            );
        }

        uint256 feeAmount = (claimAmount.mul(IDOLFee)).div(100);
        uint256 finalClaimAmount = claimAmount.sub(feeAmount);
        IERC20 token = IERC20(IDOLAddress);
        uint256 bal = token.balanceOf(address(this));
        require(bal != 0, "pool has insufficient amount");
        require(
            bal >= finalClaimAmount,
            "pool has insufficient amount to transfer"
        );
        token.transfer(msg.sender, finalClaimAmount);
        token.transfer(msg.sender, feeAmount);

        emit Claim(msg.sender, claimAmount, feeAmount, finalClaimAmount);
        creatorBalance[msg.sender] = creatorBalance[msg.sender].sub(
            claimAmount
        );
        creatorLastClaim[msg.sender] = block.number;
    }

    function claimTip() external {
        require(
            creatorTipBalance[msg.sender] != 0,
            "creator insufficient amount"
        );

        uint256 claimAmount = creatorTipBalance[msg.sender];
        uint256 feeAmount = (claimAmount.mul(PEACHFee)).div(100);
        uint256 finalClaimAmount = claimAmount.sub(feeAmount);

        IERC20 token = IERC20(PEACHAddress);
        uint256 bal = token.balanceOf(address(this));
        require(bal != 0, "pool has insufficient amount");
        require(
            bal >= finalClaimAmount,
            "pool has insufficient amount to transfer"
        );
        token.transfer(msg.sender, finalClaimAmount);
        token.transfer(msg.sender, feeAmount);

        emit ClaimTip(msg.sender, claimAmount, feeAmount, finalClaimAmount);
        creatorTipBalance[msg.sender] = creatorTipBalance[msg.sender].sub(
            claimAmount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
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
    return add(a, b, "SafeMath: addition overflow");
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
  function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);

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

pragma solidity ^0.5.16;

import "./Context.sol";

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

pragma solidity 0.5.16;

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

