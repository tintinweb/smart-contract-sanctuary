/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT
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
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract ICO_Mainnet is Ownable {
    
    address public tokenAddress = 0x5400EdD0e597527C7e9651fC4A48f1b1f3Aa0d17; // Token address
    IBEP20 token = IBEP20(tokenAddress);
    
    //Main net
    address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public wBnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  
    /*
    //Test net
    address public factory = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
    address public wBnb = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    */

    IPancakeRouter02 private router = IPancakeRouter02(routerAddress);

    
    mapping (address => uint256) icoBuyersInvestment;
    uint256 public icoBuyersCount;
    uint256 public tokenSold;
    uint256 public fundsRaised;
    uint256 public fundsClaimed;
    
    uint256 public ICOTarget = 250000000000000000000; // 250 BNB
    uint256 public baseRate = 1000000000000000000; // 1 BNB on weis
    uint256 public ICOPrice = 415000000000000000000000; // 1 BNB = 415 thousand tokens
    uint256 public dexListingRate = 275000000000000000000000; // 1 BNB = 275 thousand tokens

    uint256 public startTime = 1640228400;
    uint256 public endTime = 1640833200;
    uint256 public lockedBNBbalance;
    bool public icoFinalized = false;
   
    event TokensPurchased(address indexed buyer, uint256 amount);
    
    function buy() external payable returns (bool) {
        require (startTime <= block.timestamp,'ICO is not started yet');
        require (icoFinalized == false,'ICO is over and finalized you can trade on Pancakeswap');
        require(endTime >= block.timestamp, "ICO has ended");
        require(fundsRaised <= ICOTarget, "ICO target is reached");
        
        uint totalICOSupply = token.balanceOf(address(this));
        
        uint amount = (msg.value * ICOPrice)/baseRate;
        
        require(
            totalICOSupply >= tokenSold + amount,
            "Exceeds total token allocated for presale"
        );
        require(
            token.balanceOf(address(this)) >= amount,
            "Contract does not have sufficient token balance"
        );
        
        address buyer = msg.sender;
        
        if(icoBuyersInvestment[buyer] > 0){
            icoBuyersCount++;
        }
        
        icoBuyersInvestment[buyer] = icoBuyersInvestment[buyer] + msg.value;
        
        fundsRaised += msg.value;
        tokenSold += amount;
        token.transfer(buyer, amount);
        emit TokensPurchased(buyer, amount);
        return true;
    }

    function getContractTokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
    
    function getUserTokenBalance() public view returns(uint){
        return token.balanceOf(msg.sender);
    }
    
    function getBNBInvestment(address _address) external view returns(uint256){
        return icoBuyersInvestment[_address];
    }
    
    function setStartTime(uint256 _startTime) external onlyOwner{
        startTime = _startTime;
    }
    
    function setEndTime(uint256 _endTime) external onlyOwner{
        endTime = _endTime;
    }
    
    function setDexListingRate(uint256 _dexListingRate) external onlyOwner{
        dexListingRate = _dexListingRate;
    }
    
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IBEP20(_tokenAddress);
    }
    
    function setTokenAddress2(address _tokenAddress) external onlyOwner{
        tokenAddress = _tokenAddress;
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

    function withdrawLPTokens() external returns (bool) {
        address lpTokenAddress = IUniswapV2Factory(factory).getPair(tokenAddress, wBnb);
        IBEP20 lpToken = IBEP20(lpTokenAddress);
        uint256 lpBalance = lpToken.balanceOf(address(this));

        require(
            lpBalance > 0,
            "Insufficient token balance"
        );
        bool success = lpToken.transfer(
            msg.sender,
            lpBalance
        );
        require(success, "Token Transfer failed.");

        return true;
    }

    function addLiquidity()
        external onlyOwner
    {
        require(block.timestamp > endTime, "ICO Is not ended yet");
        require (icoFinalized == false,'ICO is already finalized you can trade on Pancakeswap');
        
        uint256 liquidableTokens = (address(this).balance * dexListingRate)/baseRate;
        
        uint256 liquidableBNBbalance = address(this).balance;
        
        IBEP20(tokenAddress).approve(routerAddress, liquidableTokens);
        router.addLiquidityETH{value: liquidableBNBbalance}(
            address(token),
            liquidableTokens,
            liquidableTokens,
            liquidableBNBbalance,
            address(this),
            block.timestamp + 10 minutes
        );
        
        lockedBNBbalance = lockedBNBbalance + liquidableBNBbalance;
        icoFinalized = true;
    }
    
    function claimInvestment() external { // In case some problem occures and liquidity is not added on DEX (Pancakeswap), Investors can claim back the invested amount.
        require (block.timestamp > endTime + 3 days, 'ICO is not finalized yet');
        require (icoFinalized == false,'ICO is finalized you can trade on Pancakeswap');
        require(icoBuyersInvestment[msg.sender] > 0, 'You do not have any ICO investments');
        (bool success, ) = msg.sender.call{value: icoBuyersInvestment[msg.sender]}("");
        require(success, "Transfer failed.");
    }
    
    function getPancakePairAddress() external view returns (address _pair){
        return IUniswapV2Factory(factory).getPair(tokenAddress, wBnb);
    }

    function getLPLockedTokensBalance() external view returns (uint256 liquidity) {
        require (block.timestamp >= endTime + 180 days, 'Liquidity is locked');
        address pair = IUniswapV2Factory(factory).getPair(tokenAddress, wBnb);
        liquidity = IBEP20(pair).balanceOf(address(this));
    }
}