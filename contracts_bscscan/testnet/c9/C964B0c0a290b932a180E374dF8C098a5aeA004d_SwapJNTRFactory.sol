/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: No License (None)
pragma solidity =0.6.12;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"Not Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0),"Zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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


interface IGatewayVault {
    function vaultTransfer(address token, address recipient, uint256 amount) external returns (bool);
    function vaultApprove(address token, address spender, uint256 amount) external returns (bool);
}

interface IDegen {
        enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
        function callbackCrossExchange(OrderType orderType, address[] memory path,uint256 assetInOffered, address user) external returns(bool);
}


interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns(bool);
}

contract SwapJNTRFactory is Ownable {
    using SafeMath for uint256;
    
    address USDT = address(0x536Ed4aaf8fBe8e35CDDd04b1928882FA292C282); // USDT address on BSC chain

    uint256 _nonce = 0;
    mapping(uint256 => bool) public nonceProcessed;
    
    mapping(uint8 => IDegen.OrderType) private _orderType;

    address public system;  // system address mey change fee amount
    bool public paused;
    address public gatewayVault; // GatewayVault contract
    address public degenContract;
    
    event SwapRequest(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount,uint8 crossOrderType, uint256 nonce);

    // event ClaimRequest(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);
    event ClaimApprove(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount, uint8 crossOrderType);

    modifier notPaused() {
        require(!paused,"Swap paused");
        _;
    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(msg.sender == system || owner() == msg.sender,"Caller is not the system");
        _;
    }

    constructor (address _system, address _vault) public {
        system = _system;
        gatewayVault = _vault;
        _orderType[0] = IDegen.OrderType.TokensForTokens;
        _orderType[1] = IDegen.OrderType.TokensForEth;
        _orderType[2] = IDegen.OrderType.TokensForTokens;
        _orderType[3] = IDegen.OrderType.TokensForEth;
    }


    function setDegenContract(address _degenContract) external onlyOwner returns(bool) {
        degenContract = _degenContract;
        return true;
    }

    function setSystem(address _system) external onlyOwner returns(bool) {
        system = _system;
        return true;
    }

    
    function setPause(bool pause) external onlyOwner returns(bool) {
        paused = pause;
        return true;
    }

    function getTransactionStatus(uint256 nonce)external view returns (bool){
      return nonceProcessed[nonce];
    }


    //user should approve tokens transfer before calling this function.
    // for local swap (tokens on the same chain): pair = address(1) when TokenA = JNTR, and address(2) when TokenB = JNTR
    function swap(address tokenA, address tokenB, uint256 amount, address user, uint8 crossOrderType) external payable notPaused returns (bool) {
        require(msg.sender == degenContract, "Only Degen");
        require(amount != 0, "Zero amount");
       
        require(gatewayVault != address(0), "No vault address");
        IBEP20(tokenA).transferFrom(msg.sender, gatewayVault, amount);
        
        _nonce = _nonce+1;
        emit SwapRequest(tokenA, tokenB, user, amount,crossOrderType,_nonce);
            
        return true;
    }

   

    function claimTokenBehalf(address[] memory path, address user,uint256 amount,uint8 crossOrderType, uint256 nonce) external onlySystem notPaused returns (bool) {
        require(!nonceProcessed[nonce], "Exchange already processed");
        nonceProcessed[nonce] = true;
        _claim(path, user,amount,crossOrderType);
        return true;
    }

    function _claim (address[] memory path, address user, uint256 amount, uint8 crossOrderType) internal returns(bool) {
      
        if(path[path.length-1] == USDT) {
            IGatewayVault(gatewayVault).vaultTransfer(USDT, user, amount); 
        } 
        else {
            
            IGatewayVault(gatewayVault).vaultTransfer(USDT, degenContract, amount); 
            IDegen(degenContract).callbackCrossExchange(_orderType[crossOrderType],path,amount, user);
        }
        
        emit ClaimApprove(path[0], path[path.length-1], user, amount, crossOrderType);

        // emit ClaimRequest(tokenA, tokenB, user,amount);

        return true;
    }
}