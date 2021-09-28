/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: privatePresale.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;



contract PrivatePresale is Ownable {
    address public AGO  = 0x4e125214Db26128B35c24c66113C63A83029e433;
    address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    
    uint256 public allTimeAllocatedAmount;
    uint256 public allTimeDistributedAmount;
    
    mapping(address => uint256) public registration;

    uint256 public minimalAmount = 100e6;
    uint256 public countOfParticipated = 0;
    bool public launched;
    
    uint256 public presaleLimit;
    uint256 public price;
    
    event allocated(uint256 allocateAmount);
    event newPresaleLimitAndPrice(uint256 limit, uint256 price);
    event presaleBegin();
    event presaleFinished();
    
    modifier launchStatus(bool _launchedRequiered){
        if (_launchedRequiered){
            require(launched, 'Launched');
        }else{
            require(!launched, 'Launched');
        }
 
        _;
    }
    
    function installPresaleLimitAndPrice(uint256 _limit, uint256 _price) launchStatus(false) external onlyOwner{
        price = _price;
        presaleLimit = _limit;
        emit newPresaleLimitAndPrice(presaleLimit, price);
    }
    
    function allocate(uint256 _allocateAmount) launchStatus(false) external onlyOwner{
        IERC20(AGO).transferFrom(msg.sender, address(this), _allocateAmount);
        allTimeAllocatedAmount += _allocateAmount;
        emit allocated(_allocateAmount);
    }
    
    function allocatedAmount() public view returns(uint256 amount){
        return IERC20(AGO).balanceOf(address(this));
    }
    
    function register(address user) launchStatus(false) public onlyOwner{
        registration[user] = presaleLimit;
        countOfParticipated++;
    }
    
    function registerSome(address[] memory users) external onlyOwner{
        for (uint i = 0; i < users.length; i++) register(users[i]);
    }
    
    function launch() launchStatus(false) external onlyOwner{
        launched = true;
        emit presaleBegin();
    }
    
    function finish() launchStatus(true) external onlyOwner{
        launched = false;
        IERC20(USDT).transfer(owner(), IERC20(USDT).balanceOf(address(this)));
        IERC20(AGO).transfer(owner(), IERC20(AGO).balanceOf(address(this)));
        emit presaleFinished();
    }
    
    function buyByUsdt(uint256 _amout) launchStatus(true) external{
        require(_amout <= registration[msg.sender], 'Presale limit for user is exceeded or reached limit'); 
        require((presaleLimit - registration[msg.sender]) + _amout >= minimalAmount, 'Minimal amount not reached'); 

        registration[msg.sender] -= _amout;

        uint256 receivedTokens = _amout * 1e18 / price;
        
        IERC20(USDT).transferFrom(msg.sender, address(this), _amout);
        IERC20(AGO).transfer(msg.sender, receivedTokens);
        
        allTimeDistributedAmount += _amout;
    }
}