/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//File Context.sol
contract Context {

    /**
     * @dev returns address executing the method
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev returns data passed into the method
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//File Ownable.sol
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
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//File IERC20.sol
interface IERC20 {
    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     
     
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


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

interface UNIVE {
    function claim(address sender, address receiver) external ;
    function getHolderStatus(address address_) external view returns (uint, bool);
}

//File UniveReward.sol

contract UniveReward is Ownable {

    address public univeToken;
    IUniswapV2Router02 public uniswapV2Router;
    //address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswap router2 address
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswap router2 address for 4 main testnet
    //address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //pancakeswap router2 address
    //address public routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //pancakeswap router2 testnet address
    
    address public USDTaddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 public rewardThreshold = 1000 * 10**8;    
    
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Router = _uniswapV2Router;

    }   

    //to recieve ETH(BNB) from uniswapV2Router when swaping
    receive() external payable {}

    function claim(address _to) public returns(bool){
        (uint reward, bool status) = UNIVE(univeToken).getHolderStatus(_msgSender());
        require(status, "The reward is not allowed");
        require(reward > rewardThreshold, "Reward insufficient to withdraw");
        
        uint256 initialBalance = address(this).balance;

        UNIVE(univeToken).claim(_msgSender(), address(this));

        uint256 newBalance = address(this).balance-initialBalance;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = USDTaddress;
        //_approve(address(this), address(uniswapV2Router), );

        //make the swap to get the token required from ETH
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:newBalance}(
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );
        return true;
    }

    function claim1(address _to) public returns(bool){
        (uint reward, bool status) = UNIVE(univeToken).getHolderStatus(_msgSender());
        require(status, "The reward is not allowed");
        require(reward > rewardThreshold, "Reward insufficient to withdraw");
        
        UNIVE(univeToken).claim(_msgSender(), address(this));     
        payable(_to).transfer(address(this).balance);   
        return true;
    }

    function claim2() public returns(bool){
        (uint reward, bool status) = UNIVE(univeToken).getHolderStatus(_msgSender());
        require(status, "The reward is not allowed");
        require(reward > rewardThreshold, "Reward insufficient to withdraw");
        
        UNIVE(univeToken).claim(_msgSender(), address(this));        
        return true;
    }

    function claim3() public returns(bool){
        (uint reward, bool status) = UNIVE(univeToken).getHolderStatus(_msgSender());
        require(status, "The reward is not allowed");
        require(reward > rewardThreshold, "Reward insufficient to withdraw");
        
        uint256 initialBalance = address(this).balance;

        UNIVE(univeToken).claim(_msgSender(), address(this));

        uint256 newBalance = address(this).balance-initialBalance;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = USDTaddress;
        IERC20(uniswapV2Router.WETH()).approve(address(uniswapV2Router), newBalance);
        
        return true;
    }

    function claim4(address _to) public returns(bool){
         (uint reward, bool status) = UNIVE(univeToken).getHolderStatus(_msgSender());
        require(status, "The reward is not allowed");
        require(reward > rewardThreshold, "Reward insufficient to withdraw");
        
        uint256 initialBalance = address(this).balance;

        UNIVE(univeToken).claim(_msgSender(), address(this));

        uint256 newBalance = address(this).balance-initialBalance;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = USDTaddress;
        IERC20(uniswapV2Router.WETH()).approve(address(uniswapV2Router), newBalance);

        //make the swap to get the token required from ETH
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:newBalance}(
            0, // accept any amount of the token
            path,
            _to,
            block.timestamp
        );
        return true;
    }

    function claim5(address _to) public returns(bool){
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = USDTaddress;
        IERC20(uniswapV2Router.WETH()).approve(address(uniswapV2Router), address(this).balance);

        //make the swap to get the token required from ETH
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:address(this).balance}(
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );
        return true;
    }

    function setToken(address newToken_) external onlyOwner {
        USDTaddress = newToken_;
    }

    function setRewardThreshold(uint256 rewardThreshold_) external onlyOwner {
        rewardThreshold = rewardThreshold_;
    }

    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

}