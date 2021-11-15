// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DefiPool is Ownable {
    
    event Output(uint output);
    
    event convertEthToTokenEvent(address sender, uint ethInput, uint tokenOutput, address tokenAddress);
    
    using SafeMath for uint;
    
    uint16[5] public defaultAllocation;
    
    address payable[5] public defaultTokenAddress;
    
    address payable public walletTo;
    
    bool public returnToSender;
    
    address public wETHAddress;
    
    address internal UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;
    
    uint16 public goodWill;
    
    constructor() public {
        
        walletTo = 0xA2E00FBd1e9315f490aE356F69c1f6624e2ed992;
        
        returnToSender = true;
        
        goodWill = 100;
        
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        
        defaultAllocation[0] = 4000;
        defaultAllocation[1] = 2500;
        defaultAllocation[2] = 1000;
        defaultAllocation[3] = 2500;
        defaultAllocation[4] = 0;
        
        //MAINNET
        //Contract deployed at: 0x33800fd4d99da92d5320fdd7858dbe6eb7909298
        //Metadata: dweb:/ipfs/Qmd67f4PPHrNapZmk5KznDpMhYoPsSCtUQqpgZS2FdMhiD
        wETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        defaultTokenAddress[0] = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b; //DPI
        defaultTokenAddress[1] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; //WBTC
        defaultTokenAddress[2] = 0x514910771AF9Ca656af840dff83E8264EcF986CA; //LINK
        defaultTokenAddress[3] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH
        defaultTokenAddress[4] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        
        //GOERLI
        //Contract deployed at: 0xfa795a8623527c8d88a2044ac7ab20f28229419a
        //wETHAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        //defaultTokenAddress[0] = 0x92B30dF9b169FAC44c86983B2aAAa465FDC2CDB8; //FARM
        //defaultTokenAddress[1] = 0x3ec9D3236C25e71c01057C37cE41423360565812; //DBTC
        //defaultTokenAddress[2] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; //UNI
        //defaultTokenAddress[3] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //WETH
        //defaultTokenAddress[4] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        
    }
    
    function changeAllocation(uint16 _index, uint16 _allocation) public onlyOwner {
        defaultAllocation[_index] = _allocation;
    }

    function changeTokenAddress(uint16 _index, address payable _address) public onlyOwner {
        defaultTokenAddress[_index] = _address;
    }
    
    function changeWalletTo(address payable _address) public onlyOwner {
        walletTo = _address;
    }
    
    function changeUniswapRouter(address _address) public onlyOwner {
        UNISWAP_ROUTER_ADDRESS = _address;
         uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }
    
    function changeReturnToSender(bool _returnToSender) public onlyOwner {
        returnToSender = _returnToSender;
    }

    function changeGoodWill(uint16 _amount) public onlyOwner {
        goodWill = _amount;
    }

    function doMagic(uint16[5] memory _allocations, address payable[5] memory _defaultTokenAddress) public payable {

        uint _amountRecieved = msg.value;
        
        //do goodWill
        uint _amountGoodWill = _amountRecieved.mul(goodWill).div(10000);
        uint _amountToConvert = _amountRecieved.sub(_amountGoodWill);
        
        uint tokens;
        
        uint[5] memory amount;
        
        //check that allocations sum up to 100
        uint _num1 = 0;
        for (uint i = 0; i < 5; ++i) {
            _num1 = _num1 + _allocations[i];
        }
        require(_num1 == 10000,"Error in Allocations");

        amount[0] = _amountToConvert.mul(_allocations[0]).div(10000);
        amount[1] = _amountToConvert.mul(_allocations[1]).div(10000);
        amount[2] = _amountToConvert.mul(_allocations[2]).div(10000);
        amount[3] = _amountToConvert.mul(_allocations[3]).div(10000);
        amount[4] = _amountToConvert.mul(_allocations[4]).div(10000);
        
        for (uint256 i = 0; i < 5; ++i) {
            //Convert to the appropiate tokens
            if (defaultAllocation[i] > 0) {
                tokens = convertEthToToken(amount[i], _defaultTokenAddress[i], 0);
                emit convertEthToTokenEvent(msg.sender, amount[i], tokens, _defaultTokenAddress[i]);
                //emit Output(tokens);
            }
        }
        
        
        
    }
     
     
     
    //UNISWAP STUFF
    function convertEthToToken(uint _ethAmount, address _addressToken, uint _amountTokenMin) public payable returns(uint){
        
        uint _outputTokenCount;
        address payable _walletTo;
        
        if (returnToSender) {
            _walletTo = msg.sender;
        } else {
            _walletTo = walletTo;
        }
        
        if (_addressToken == wETHAddress) {
            _walletTo.transfer(_ethAmount);
            _outputTokenCount = _ethAmount;
        } else {
            uint _deadline = block.timestamp + 300; // using 'now' for convenience, for mainnet pass deadline from frontend!
            uint[] memory _amounts = uniswapRouter.swapExactETHForTokens{value: _ethAmount }(_amountTokenMin, getPathForETHtoToken(_addressToken), _walletTo, _deadline);
            _outputTokenCount = uint256(_amounts[1]);
        }
        
        return _outputTokenCount;
    }
    
    function getPathForETHtoToken(address _addressToken) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _addressToken;
        
        return path;
    }
     
    // - to withdraw any ETH balance sitting in the contract
    function withdrawAllEth(address payable _returnAddress) public onlyOwner {
        uint256 balance = address(this).balance;
        _returnAddress.transfer(balance);
    }
 
    function withdrawEth(address payable _returnAddress, uint _amount) public onlyOwner {
        require(_amount <= address(this).balance, "There are not enough funds stored in the contract");
        _returnAddress.transfer(_amount);
    }
 
    receive () external payable {
        doMagic(defaultAllocation,defaultTokenAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

