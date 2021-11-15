// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "../libraries/SafeMath.sol";
import "../libraries/Ownable.sol";

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

contract LockToken is Ownable {

    using SafeMath for uint256;

    struct Token {
        address tokenAddress;
        uint256 tokenAmount;
        uint256 lastClaim;
    }

    mapping(address => Token[]) public userBalance;
    // 18 months
    uint256 private claimPeriod = 20 * 60 * 24  * 30 * 18;
    address[] tokenList;

    event Claim(
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 actualAmount
    );
    event Deposit(
        address user,
        address token,
        uint256 amount
    );

    function viewClaimPeriod() public view returns (uint256 period) {
       return claimPeriod;
    }
    
    function viewTokenContract() public view returns (address[] memory list) {
        return tokenList;
    }

    function checkContractTokenBalance(address _tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(address(this));
    }

    function checkTokenBalance(address _tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(msg.sender);
    }

    function checkClaim(address _tokenAddress)
        public
        view
        returns (
            uint256 balance,
            uint256 actualClaim
        )
    {
        Token[] memory tokens = userBalance[msg.sender];
        Token memory token;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory tok = tokens[i];
            if (tok.tokenAddress == _tokenAddress) {
                token = tok;
            }
        }
        
        require(token.lastClaim != 0, "no token in your account");
        require(token.tokenAmount != 0, "insufficient token amount");

        uint256 blockPassed = block.number.sub(token.lastClaim);
        uint256 claimAmount;

        if (blockPassed / claimPeriod >= 1) {
            claimAmount = token.tokenAmount;
        } else {
            claimAmount = (token.tokenAmount.mul(blockPassed))
                .div(claimPeriod);
        }

        return (token.tokenAmount, claimAmount);
    }

    function deposit(
        address _tokenAddress,
        uint256 _amount
    ) external {
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(msg.sender);
        require(bal != 0, "insufficient amount");
        require(bal > _amount, "insufficient amount to transfer");
        token.transferFrom(msg.sender, address(this), _amount);
        
        emit Deposit(msg.sender, _tokenAddress, _amount);

        // add balance for future claim
        Token[] memory tokens = userBalance[msg.sender];
        bool isTokenExist = false;
        for(uint256 i; i < tokens.length; i ++) {
            Token memory t = tokens[i];
            if (t.tokenAddress == _tokenAddress) {
                t.tokenAmount = t.tokenAmount.add(_amount);
                t.lastClaim = block.number;
                isTokenExist = true;
            }
        }
        
        if (!isTokenExist) {
            userBalance[msg.sender].push(Token(_tokenAddress, _amount, block.number));
        }
        
        tokenList.push(_tokenAddress);
    }
    
    function claim(address _tokenAddress) external {
        Token[] memory tokens = userBalance[msg.sender];
        bool tokenExist = false;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            Token memory t = tokens[i];
            if (t.tokenAddress == _tokenAddress) {
                require(t.tokenAmount != 0, "insufficient token amount");
        
                uint256 blockPassed = block.number.sub(t.lastClaim);
                uint256 claimAmount;
        
                if (blockPassed / claimPeriod >= 1) {
                    claimAmount = t.tokenAmount;
                } else {
                    claimAmount = (t.tokenAmount.mul(blockPassed))
                        .div(claimPeriod);
                }
                
                IERC20 token = IERC20(_tokenAddress);
                uint256 bal = token.balanceOf(address(this));
                require(bal != 0, "pool has insufficient amount");
                require(
                    bal >= claimAmount,
                    "pool has insufficient amount to transfer"
                );
                token.transfer(msg.sender, claimAmount);
                emit Claim(msg.sender, _tokenAddress, t.tokenAmount, claimAmount);
                tokenExist = true;
            }
        }
        
       require(tokenExist, "no token in your account");
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

