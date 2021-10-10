/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: MIT
// Author : iBlockchainer (Telegram)
pragma solidity 0.8.7;

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
    function allowance(address _owner, address spender)
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

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeRouter02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
         uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )   external returns (uint amountETH);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract MambaICO is Ownable {
    IBEP20 public token;
    address public tokenAddress = 0xf02B1a0A9a98D43c9e772bB04500EA3F0693A164;
    
    IPancakeRouter02 private router;
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    uint256 public basePrice = 0.01 ether; //0.01 ether
    bool public icoState;
    mapping(address => uint256) public icoBuyers;
    uint256 public ICOTarget = 240000000000000000000000000000;
    uint public baseRate = 1000000000000000000;
    uint256 public ICOPrice = 425000000;
    uint256 public tokenSold;
    uint256 public startTime;
    uint256 public endTime;
    
    address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public wBnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor() {
        token = IBEP20(tokenAddress);
        router = IPancakeRouter02(routerAddress);
        //totalICOSupply = token.balanceOf(address(this));
        //startTime = block.timestamp + 1 days;
        //endTime = block.timestamp + 8 days
        startTime = block.timestamp;
        endTime = block.timestamp+7 days;
    }

  
    function buy() external payable returns (bool) {
        //require(icoState, "ICO has not started yet");
        require(block.timestamp >= startTime, "ICO has not stared yet");
        require(endTime >= block.timestamp, "ICO has ended");
        
        uint amount = (msg.value * ICOPrice)/baseRate;
        
        require(
            token.balanceOf(address(this)) >= tokenSold + amount,
            "Exceeds total token allocated for presale"
        );
        require(
            token.balanceOf(address(this)) >= amount,
            "Contract does not have sufficient token balance"
        );
        
        token.transfer(msg.sender, amount);
        emit TokensPurchased(msg.sender, amount);
        return true;
    }

    function getTokenSupply() public view returns(uint){
        return token.balanceOf(address(this));
    }
    
    function getUserTokenBalance() public view returns(uint){
        return token.balanceOf(msg.sender);
    }
    
    function updateStartTime(uint256 _time) external onlyOwner {
        startTime = _time;
    }

    function updateEndTime(uint256 _time) external onlyOwner {
        endTime = _time;
    }
    
    function updateTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        token = IBEP20(tokenAddress);
    }
    
    function updateFactoryAddress(address _factoryAddress) public onlyOwner {
        factory = _factoryAddress;
    }
    
    function updateWBNBAddress(address _wBNBAddress) public onlyOwner {
        wBnb = _wBNBAddress;
    }
    
    function updateRouterAddress(address _routerAddress) public onlyOwner {
        routerAddress = _routerAddress;
    }
    
    function updateICOPrice(uint _ICOPrice) public onlyOwner {
        ICOPrice = _ICOPrice;
    }
    
    function updateICOTarget(uint _ICOTarget) public onlyOwner {
        ICOTarget = _ICOTarget;
    }
    
    
    function withdrawToken() external onlyOwner {
        require(
            token.balanceOf(address(this)) > 0,
            "Insufficient token balance"
        );
        bool success = token.transfer(
            msg.sender,
            token.balanceOf(address(this))
        );
        require(success, "Token Transfer failed.");
    }

    function withdrawBnb() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
   
    function addLiquidity(uint256 _amountTokenDesired, uint256 _amountETHMin)
        external
        onlyOwner
    {
        require(
            token.balanceOf(address(this)) >= _amountTokenDesired,
            "Insufficient token balance"
        );
        require(
            address(this).balance >= _amountETHMin,
            "Insufficient BNB balance"
        );
        IBEP20(tokenAddress).approve(routerAddress, _amountTokenDesired);
        router.addLiquidityETH{value: _amountETHMin}(
            address(token),
            _amountTokenDesired,
            _amountTokenDesired,
            _amountETHMin,
            address(this),
            block.timestamp + 10 minutes
        );
    }
    
    function removeLiquidityETH(
        uint256 _lpTokens,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _pair
    ) external onlyOwner {
        IBEP20(_pair).approve(routerAddress, _lpTokens);
        router.removeLiquidityETHSupportingFeeOnTransferTokens(
            tokenAddress,
            _lpTokens,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function getLPTokensBalance() external view returns (address _pair, uint256 liquidity) {
        address pair = IUniswapV2Factory(factory).getPair(tokenAddress, wBnb);
        liquidity = IBEP20(pair).balanceOf(address(this));
        return(pair,liquidity);
    }
}