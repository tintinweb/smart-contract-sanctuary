/**
 *Submitted for verification at arbiscan.io on 2021-09-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IEscrow {
    function convertToEth() external;
    function updateRecipient(address newRecipient) external;
}


interface IRouter {
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(address token, uint amountTokenDesired, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountAVAX);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}


interface INonCompliantStrategy {
    function updateAdmin(address newAdmin) external;
}

contract SushiEscrow is Ownable, IEscrow {
    address public recipient;
    IERC20 token;
    IERC20 wETH;
    IRouter sushiRouter;
    uint256 public MIN_TOKENS_TO_SWAP = 10;
    
    
    constructor( address token_) {
        recipient = msg.sender;
        token = IERC20(token_);
        wETH = IERC20( 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        sushiRouter = IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        setAllowances();
    }
    
     function setAllowances() public onlyOwner {
        token.approve(address(sushiRouter), token.totalSupply());
        wETH.approve(address(sushiRouter), wETH.totalSupply());
      }
    
    /**
   * @notice Update minimum threshold for external callers
   * @param newValue min threshold in wei
   */
  function updateMinTokensToReinvest(uint newValue) external onlyOwner {
    MIN_TOKENS_TO_SWAP = newValue;
  }
    
    function convertToEth() external override {
        uint256 pending = token.balanceOf(address(this));
        require(pending >= MIN_TOKENS_TO_SWAP, "MIN_TOKENS_TO_SWAP not met");
         // swap to wETH
        address[] memory path0 = new address[](2);
        path0[0] = address(token);
        path0[1] = address(wETH);
        uint[] memory amountsOutToken0 = sushiRouter.getAmountsOut(pending, path0);
        uint amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
        sushiRouter.swapExactTokensForTokens(pending, amountOutToken0, path0, address(this), block.timestamp);
        
       //send to recipient
       wETH.transfer(recipient, wETH.balanceOf(address(this)));
    }
    
    function updateRecipient(address newRecipient) external override onlyOwner {
        recipient = newRecipient;
    }
    
    function revertStrategyOwnership(address strategy) external onlyOwner {
        Ownable instance = Ownable(strategy);
        instance.transferOwnership(owner);
    }
    
     function revertStrategyOwnershipNonCompliant(address strategy) external onlyOwner {
        INonCompliantStrategy instance = INonCompliantStrategy(strategy);
        instance.updateAdmin(owner);
    }
    
    /**
   * @notice Recover ETH from contract (there should never be any left over in this contract)
   * @param amount amount
   */
  function recoverETH(uint amount) external onlyOwner {
    require(amount > 0, 'amount too low');
    payable(owner).transfer(amount);
  }
  
   /**
   * @notice Recover ERC20 from contract (there should never be any left over in this contract)
   * @param tokenAddress address of erc20 to recover (can not = token)
   */
  function recoverERC20(address tokenAddress) external onlyOwner {
    require(tokenAddress != address(token), "cant recover main token");
    require(tokenAddress != address(wETH), "cant recover weth token");
    IERC20 instance = IERC20(tokenAddress);
    instance.transfer(owner, instance.balanceOf(address(this)));
  }
}