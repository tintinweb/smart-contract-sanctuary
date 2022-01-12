/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-12
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
    mapping (address => bool) authorized;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        authorized[_msgSender()] = true; 
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
        require(owner() == _msgSender() || authorized[_msgSender()] == true , "Ownable: caller is not the owner");
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

contract CasinoCoinPresale is Ownable {
    
    address public tokenAddress = 0xA6d2aFF30B197cdfc28F1F76FA8D5bf6A264260D; // Token address
    IBEP20 token = IBEP20(tokenAddress);
    
    
    //Main net
    address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public wBnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    IPancakeRouter02 private router = IPancakeRouter02(routerAddress);
    
    mapping (address => uint256) presaleInvestments;
    uint256 public presaleInvestorsCount;
    uint256 public tokenSold;
    uint256 public fundsRaised;
    uint256 public fundsClaimed;
    
    uint256 public softcap = 150 * 10**18; // 250 BNB
    uint256 public hardcap = 300 * 10**18; // 250 BNB
    
    uint256 public baseRate = 1 * 10**18; // 1 BNB on weis
    uint256 public presaleRate = 12000000 * 10**token.decimals(); // 1 BNB = 415 thousand tokens
    uint256 public dexListingRate = 9000000 * 10**token.decimals(); // 1 BNB = 275 thousand tokens

    uint256 public startTime = 1642219200;
    uint256 public endTime = 1642824000;
    uint256 public lockedBNBbalance;
    bool public presaleFinalized = false;
   
    event TokensPurchased(address indexed buyer, uint256 amount);
    
    function buy() public payable returns (bool) {
        require (startTime <= block.timestamp,'Presale is not started yet');
        require (presaleFinalized == false,'Presale is over and finalized you can trade on Pancakeswap');
        require(endTime >= block.timestamp, "Presale has ended");
        require(fundsRaised <= hardcap, "Presale target is reached");
        
        uint amount = (msg.value * presaleRate)/baseRate;
        
        require(
            token.balanceOf(address(this)) >= amount,
            "Contract does not have sufficient token balance"
        );
        
        address investor = msg.sender;
        
        if(presaleInvestments[investor] > 0){
            presaleInvestorsCount++;
        }
        
        presaleInvestments[investor] = presaleInvestments[investor] + msg.value;
        
        fundsRaised += msg.value;
        tokenSold += amount;
        token.transfer(investor, amount);
        emit TokensPurchased(investor, amount);
        return true;
    }

    function getContractTokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
    
    function getUserTokenBalance() public view returns(uint){
        return token.balanceOf(msg.sender);
    }
    
    function getBNBInvestment(address _address) external view returns(uint256){
        return presaleInvestments[_address];
    }

    function getTokenDecimals() external view returns(uint256){
        return token.decimals();
    }
    
    function authorize (address _authorizedAddress) external onlyOwner{
        authorized[_authorizedAddress] = true;
    }

    function unauthorize (address _authorizedAddress) external onlyOwner{
        authorized[_authorizedAddress] = false;
    }

    function setStartTime(uint256 _startTime) external onlyOwner{
        startTime = _startTime;
    }

    function quickStartICO() external onlyOwner{
        startTime = block.timestamp;
    }
    
    function setEndTime(uint256 _endTime) external onlyOwner{
        endTime = _endTime;
    }

    function quickEndICO() external onlyOwner{ //If anything goes wrong the ICO can be ended quickly to stop new investments and can be resumed later as required
        endTime = block.timestamp;
    }
    
    function setPresaleRate(uint256 _presaleRate) external onlyOwner{
        presaleRate = _presaleRate;
    }

    function setDexListingRate(uint256 _dexListingRate) external onlyOwner{
        dexListingRate = _dexListingRate;
    }
    
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
        token = IBEP20(_tokenAddress);
    }
    
    function withdrawUnsoldToken(address _withdrawAddress) external onlyOwner {
        require(token.balanceOf(address(this)) > 0,"Insufficient token balance");
        bool success = token.transfer(_withdrawAddress,token.balanceOf(address(this)));
        require(success, "Token Transfer failed.");
    }

    function withdrawLPTokens(address _withdrawAddress) external onlyOwner returns (bool) {
        address lpTokenAddress = IUniswapV2Factory(factory).getPair(tokenAddress, wBnb);
        IBEP20 lpToken = IBEP20(lpTokenAddress);
        uint256 lpBalance = lpToken.balanceOf(address(this));

        require(lpBalance > 0,"Insufficient token balance");
        bool success = lpToken.transfer(_withdrawAddress,lpBalance);
        require(success, "Token Transfer failed.");

        return true;
    }

    function addLiquidity() external onlyOwner{
        require(block.timestamp > endTime, "Presale Is not ended yet");
        require (presaleFinalized == false,'Presale is already finalized you can trade on Pancakeswap');
        
        uint256 liquidableTokens = (address(this).balance * dexListingRate)/baseRate;
        
        uint256 liquidableBNBbalance = address(this).balance;
        
        token.approve(routerAddress, liquidableTokens);
        router.addLiquidityETH{value: liquidableBNBbalance}(
            address(token),
            liquidableTokens,
            liquidableTokens,
            liquidableBNBbalance,
            address(this),
            block.timestamp + 10 minutes
        );
        
        lockedBNBbalance = lockedBNBbalance + liquidableBNBbalance;
        presaleFinalized = true;
    }
    
    function claimInvestment() external { // In case some problem occures and liquidity is not added on DEX (Pancakeswap), Investors can claim back the invested amount.
        require (block.timestamp > endTime + 3 days, 'Presale is not finalized yet');
        require (presaleFinalized == false,'Presale is finalized you can trade on Pancakeswap');
        require(presaleInvestments[msg.sender] > 0, 'You do not have any Presale investments');
        (bool success, ) = msg.sender.call{value: presaleInvestments[msg.sender]}("");
        require(success, "Transfer failed.");
    }

    function refundInvestment(address _address) external onlyOwner { // In case some problem occures and liquidity is not added on DEX (Pancakeswap), Admin can refund back the invested amount.
        require(presaleInvestments[_address] > 0, 'User do not have any Presale investments');
        (bool success, ) = msg.sender.call{value: presaleInvestments[_address]}("");
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

    receive() external payable {
        buy();
    }
}