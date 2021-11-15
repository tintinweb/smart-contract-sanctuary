pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import "https://raw.githubusercontent.com/UniLend/flashloan_interface/main/contracts/UnilendFlashLoanReceiverBase.sol";





interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}




contract uBoost is UnilendFlashLoanReceiverBase {
    using SafeMath for uint256;
    
    uint public fee;
    address public feeAddress;
    address public owner;
    
    
    constructor() {
        owner = msg.sender;
        fee = 0;
        feeAddress = msg.sender;
    }
    
    
    
    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }
    
    
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        
        
        address token;
        address exchange;
        address baseToken;
        address payable sender;
        (exchange, token, baseToken, sender) = abi.decode(_params, (address, address, address, address));
        
        
        uint[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = baseToken;
        
        
        if(IERC20(token).allowance(address(this), exchange) < _amount){
            IERC20(token).approve(exchange, uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
        
        
        amounts = IUniswapV2Router01(exchange).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 10
        );
        
        if(IERC20(baseToken).allowance(address(this), exchange) < amounts[1]){
            IERC20(baseToken).approve(exchange, uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
        
        path[0] = baseToken;
        path[1] = token;
        
        amounts = IUniswapV2Router01(exchange).swapExactTokensForTokens(
            amounts[1],
            0,
            path,
            address(this),
            block.timestamp + 10
        );
        
        uint totalDebt = _amount.add(_fee);
        
        uint _userFee = totalDebt.sub(amounts[1]);
        
        IERC20(token).transferFrom(sender, address(this), _userFee);
        
        transferInternal(getUnilendCoreAddress(), _reserve, totalDebt);
    }
    
    function executeTrade(address _exchange, address token, address baseToken, uint _amount) external {
        bytes memory data = abi.encode(address(_exchange), address(token), address(baseToken), address(msg.sender));
        
        if(fee > 0){
            uint feeAmount = (_amount.mul(fee)).div(10000);
            IERC20(token).transferFrom(msg.sender, feeAddress, feeAmount.mul(2));
        }
        
        // IERC20(token).transferFrom(msg.sender, address(this), _totfee.add(feeAmount));
        
        flashLoan(address(this), token, _amount, data);
    }
    
    
    function updateFee(address payable newAddress, uint newFee) external onlyOwner {
        fee = newFee;
        feeAddress = newAddress;
    }
    
    
    function withdrawTokens(address token, address to, uint amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}

pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

import "./IERC20.sol";


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IUnilendFlashLoanCoreBase {
    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes memory _params) external;
}



contract UnilendFlashLoanReceiverBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    mapping(uint => address payable) private coreAddress;
    address payable public unilendFlashLoanCore;
    
    constructor() {
        coreAddress[1] = payable(0x13A145D215182924c89F2aBc7D358DCc72F8F788);
        coreAddress[3] = payable(0x13A145D215182924c89F2aBc7D358DCc72F8F788);
        coreAddress[56] = payable(0x13A145D215182924c89F2aBc7D358DCc72F8F788);
        coreAddress[97] = payable(0x13A145D215182924c89F2aBc7D358DCc72F8F788);
        coreAddress[137] = payable(0x13A145D215182924c89F2aBc7D358DCc72F8F788);
    }
    
    receive() payable external {}
    
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
    
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    
    function getUnilendCoreAddress() internal view returns(address payable) {
        require(coreAddress[getChainID()] != address(0), "UnilendV1: Chain not supported");
        return coreAddress[getChainID()];
    }
    
    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == ethAddress()) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
    
    function transferInternal(address payable _destination, address _reserve, uint256 _amount) internal {
        if(_reserve == ethAddress()) {
            (bool success, ) = _destination.call{value: _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_reserve).safeTransfer(_destination, _amount);
    }
    
    function flashLoan(address _target, address _asset, uint256 _amount, bytes memory _params) internal {
        IUnilendFlashLoanCoreBase(getUnilendCoreAddress()).flashLoan(_target, _asset, _amount, _params);
    }
    
}

pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

