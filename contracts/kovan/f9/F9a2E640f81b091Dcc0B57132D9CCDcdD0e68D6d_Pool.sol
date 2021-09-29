/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    // function decimals() external view returns (uint8);
    // function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    // function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Pool is Ownable{
    
    using SafeMath for uint256;
    
    mapping(address=>bool) public supportedTokens;
    uint256 supportedTokensCount = 0;
    address[] public tokenAddresses;
    address public walletAddress;
    
    constructor () {
        walletAddress = msg.sender;
    }
    
    event Deposit(address indexed from, address indexed to, address token_address, uint256 value);
    event Withdraw(address indexed from, address indexed to, address token_address, uint256 value);

    function updateWalletAddress(address addr) public onlyOwner {
        walletAddress = addr;
    }

    function checkTokenAddressExists(address token_address) internal view returns (bool) {
        for (uint i = 0 ; i < tokenAddresses.length ; i ++ ) {
            if (tokenAddresses[i] == token_address ) {
                return true;
            }
        }
        return false;
    }
    
    function setToken(address token) public onlyOwner {
        require(checkTokenAddressExists(token) == false, "Token already set");
        supportedTokens[token] = true;
        tokenAddresses.push(token);
        supportedTokensCount = supportedTokensCount + 1;
    }
    
    function enableToken(address token) public onlyOwner {
        require(checkTokenAddressExists(token) == true, "Token not yet exists");
        require(supportedTokens[token] == false, "Token is already enabled");
        supportedTokens[token] = true;
        if ( ! checkTokenAddressExists(token) ) {
            tokenAddresses.push(token);
        }
        supportedTokensCount = supportedTokensCount + 1;
    }

    function disableToken(address token) public onlyOwner {
        (checkTokenAddressExists(token) == true, "Token not yet exists");
        require(supportedTokens[token] == true, "Token is already disabled");
        supportedTokens[token] = false;
        supportedTokensCount = supportedTokensCount - 1;
    }
    
    // get the tokens that we supports
    function getSupportedTokenAddresses() public view returns (address[] memory){
        address[] memory supportedTokenAddresses = new address[](supportedTokensCount);
        uint16 count = 0;
        for ( uint256 i = 0 ; i < tokenAddresses.length ; i ++ ){
            if (supportedTokens[tokenAddresses[i]]) {
                supportedTokenAddresses[count] = tokenAddresses[i];
                count = count + 1;
            }
        }
        return supportedTokenAddresses;
    }
    
    function deposit(address token, uint256 amount) public {
        require(supportedTokens[token], "TOKEN ADDRESS IS NOT SUPPORTED");
        
        uint256 balance = IERC20(token).balanceOf(address(msg.sender));
        require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, address(this), token, amount);
    }

    function depositNative() public payable {
        require(supportedTokens[address(0)], "NATIVE TOKEN IS NOT SUPPORTED");
        emit Deposit(msg.sender, address(this), address(0), msg.value);
    }
    
    function withdrawToken(address token) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));   
        IERC20(token).transfer(walletAddress, balance);
        emit Withdraw(address(this), walletAddress, token, balance);
    }

    function withdrawNativeToken() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(walletAddress).transfer(balance);
        emit Withdraw(address(this), walletAddress, address(0), balance);
    }
    
    function balanceOfToken(address token) public view onlyOwner returns (uint256 amount) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return balance;
    }

    function balanceOfNativeToken() public view onlyOwner returns (uint256 amount) {
        uint256 balance = address(this).balance;
        return balance;
    }
}