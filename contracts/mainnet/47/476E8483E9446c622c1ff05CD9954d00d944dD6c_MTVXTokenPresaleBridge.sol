/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT
/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



contract Ownable is Context {
    address private _owner;

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

contract MTVXTokenPresaleBridge is Ownable {
    
    mapping (address => bool) public walletWhitelisted;
    mapping (address => uint256) public purchasedAmount;
    event TokensBought(uint256 tokenAmount, uint256 indexed ethAmount, address indexed sender);
    uint256 public tokensPerEth =  13333333*1e18;
    uint256 public maxEthAmount = 0.4 ether;
    uint256 public minEthAmount = 0.1 ether;
    uint256 public totalEthCap = 15 ether;
    uint256 public totalPurchasedAmount;
    bool public isInitialized = false;
    bool public isWhitelistPresale = false;
    address public tokenAddress;
    
    constructor() {
        address token = address(0x3505355aBC42683ed3114e3773190B646B77a1ba); // MTVX Token
        
        tokenAddress = token;
    }
    
    receive() external payable {
        buyTokens();
    }
    
    function buyTokens() payable public {
        require(isInitialized, "Private sale not active");
        if(isWhitelistPresale){
            require(walletWhitelisted[msg.sender], "User is not whitelisted");
        }
        require(msg.value > 0, "Must send ETH to get tokens");
        require(msg.value % minEthAmount == 0, "Must buy in increments of Minimum ETH Amount (0.1)");
        require(msg.value + purchasedAmount[msg.sender] <= maxEthAmount, "Cannot buy more than MaxETH Amount");
        require(msg.value + totalPurchasedAmount <= totalEthCap, "No more tokens available for presale");
        
        purchasedAmount[msg.sender] += msg.value;
        totalPurchasedAmount += msg.value;
        
        uint256 tokenAmount = (msg.value * tokensPerEth)/1e18;
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens on contract to send");
        token.transfer(msg.sender, tokenAmount);
        emit TokensBought(tokenAmount, msg.value, msg.sender);
    }
    
    function initialize() external onlyOwner {
        require(!isInitialized, "May not initialize contract again");
        // Exclude the pair from fees so that users don't get taxed when selling.
        isInitialized = true;
    }
    
    // only use in case of emergency
    function emergencyTokenAddressUpdate(address newToken) external onlyOwner{
        tokenAddress = newToken;
    }
    
    function updateMinEthAmount(uint256 newAmt) external onlyOwner{
        require(!isInitialized, "can't change the rules after presale starts");
        minEthAmount = newAmt;
        require(maxEthAmount >= minEthAmount, "can't set the max lower than the min");
    }
    
    function updateMaxEthAmount(uint256 newAmt) external onlyOwner{
        require(!isInitialized, "can't change the rules after presale starts");
        maxEthAmount = newAmt;
        require(maxEthAmount >= minEthAmount, "can't set the max lower than the min");
    }
    
    function updateTotalCap(uint256 newCap) external onlyOwner{
        require(!isInitialized, "can't change the rules after presale starts");
        totalEthCap = newCap;
    }
    
    function setWhiteListPresale(bool isWhitelist) external onlyOwner {
        isWhitelistPresale = isWhitelist;
    }
    
    // only use in case of emergency or after presale is over
    function emergencyWithdrawTokens() external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function whitelistWallet(address wallet, bool value) public onlyOwner {
        walletWhitelisted[wallet] = value;
    }
    
    function whitelistWallets(address[] memory wallets) public onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            whitelistWallet(wallets[i], true);
        }
    }
    
    // owner can withdraw ETH after people get tokens
    function withdrawETH() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal was not successful");
    }
}