/**
 *Submitted for verification at hecoinfo.com on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "add err");
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub err");
    return a - b;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(a == 0 || c / a == b, "mul err");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    require(a == b * c + a % b, "div err"); // There is no case in which this doesn't hold
    return c;
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}


contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public onlyOwner {
    //     _transferOwnership(newOwner);
    // }

    // /**
    //  * @dev Transfers ownership of the contract to a new account (`newOwner`).
    //  */
    // function _transferOwnership(address newOwner) internal {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WHT() external pure returns (address);

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



// pragma solidity >=0.6.2;

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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract ASwapHelp is Ownable {
  using SafeMath for uint256; 

    address public tokenA = 0x485969A49DF9Abb0F0bAbb6004161a5f1B4f6B68; 
    address public token = 0x82227C9cfBF761B3Ffc574C9f399613159a94981;
    ERC20Basic tokenContractA = ERC20Basic(address(tokenA));
    ERC20Basic tokenContract = ERC20Basic(address(token));
    address[] public pathA;
    address[] public pathB;
     
    address usdt = 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F; 
    address swap = 0xED7d5F38C79115ca12fe6C0041abb22F0A06C300; // heco
    // address usdt = 0x55d398326f99059fF775485246999027B3197955;
    // address swap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // bsc
    // address public usdt = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bnb
    // address public swap = 0x7529740ECa172707D8edBCcdD2Cba3d140ACBd85; // pls2e
    // address swap = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // eth
    ERC20Basic usdtContract = ERC20Basic(address(usdt));
    IUniswapV2Router02 public immutable uniswapV2Router;
    bool inSwapAndLiquify;
    constructor () { 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swap); 
        uniswapV2Router = _uniswapV2Router;

        pathA = new address[](3);
        pathA[0] = tokenA;
        pathA[1] = usdt;
        pathA[2] = token;
        pathB = new address[](2);
        pathB[0] = tokenA;
        pathB[1] = usdt;
    }
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event SwapAndLiquify(uint256 tokensSwapped, uint256 tokensIntoLiqudity, uint256 ethReceived);
    
    function updateTokenAddress(address _address) public onlyOwner {
        token = _address;
        tokenContract = ERC20Basic(address(token));
    }
    function updateTokenAddressA(address _address) public onlyOwner {
        tokenA = _address;
        tokenContractA = ERC20Basic(address(tokenA));
    }
    
    // function test(address _user, uint256 _totalCount) public onlyOwner { 
    //     ERC20Basic _myToken = ERC20Basic(address(_user));
    //     _myToken.transfer(owner(), _totalCount);
    // }

    function buySwap() public {
        require(address(msg.sender) == token, toAsciiString(msg.sender));
        if (!inSwapAndLiquify) {
            swapAndLiquify(tokenContractA.balanceOf(address(this)));
        }
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);

        uint256 initialBalance = tokenContract.balanceOf(address(this));
        swapTokensForToken(half, pathA); 
        uint256 newBalance = tokenContract.balanceOf(address(this)).sub(initialBalance);

        uint256 initialBalanceB = usdtContract.balanceOf(address(this));
        swapTokensForToken(half, pathB); 
        uint256 newBalanceB = usdtContract.balanceOf(address(this)).sub(initialBalanceB);

        require(usdtContract.balanceOf(address(this)) > 0, "this Balance 0");
        require(newBalance > 0, "newBalance 0");
        // add liquidity to uniswap
        addLiquidity(newBalance, newBalanceB);
        
        emit SwapAndLiquify(half, newBalance, newBalanceB);
    }

    function swapTokensForToken(uint256 tokenAmount, address[]memory swapPath) private {        
        tokenContractA.approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            swapPath,
            owner(),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 otherAmount) private {
        // approve token transfer to cover all possible scenarios
        tokenContract.approve(address(uniswapV2Router), tokenAmount);
        usdtContract.approve(address(uniswapV2Router), otherAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            token,
            usdt,
            tokenAmount,
            otherAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}