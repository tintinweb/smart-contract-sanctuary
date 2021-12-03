// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Presale is Ownable {

    IERC20 kataToken;

    uint256 constant maxTokenAmount = 1000000 * 10**18;    // 1M $KATA
    uint256 public fundingGoal = 200 ether;    // 200 ETH

    uint256 public soldAmount;
    uint256 public ethRaised;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public minETHAmount = 0.05 ether;
    uint256 public maxETHAmount = 5 ether;

    uint256 public price = 1000;       // 1 ETH = 1000 $KATA

    mapping(address => uint256) public buyTokens;
    mapping(address => uint256) public claimedTokens;

    uint256 public tgeAmount = 50;
    uint256 public tgeTime;
    uint256 public duration = 60 * 60 * 24 * 30 * 6;    // 6 months (180 days)

    constructor(uint256 _startTime, uint256 _endTime, uint256 _tgeTime) {
        startTime = _startTime;
        endTime = _endTime;
        tgeTime = _tgeTime;
    }

    function buy() payable external {
        require(msg.value > 0, "Zero ETH sent");
        require(msg.value >= minETHAmount && msg.value <= maxETHAmount,
            "Invalid ETH amount");

        require(block.timestamp >= startTime && block.timestamp <= endTime,
            "Sales not live");

        require(soldAmount < maxTokenAmount, "sales completed");
        
        ethRaised = ethRaised + msg.value;
        uint256 amount = price * msg.value;
        
        soldAmount = soldAmount + amount;
        buyTokens[msg.sender] = buyTokens[msg.sender] + amount;
    }

    function getClaimable() public view returns(uint256) {
        if (block.timestamp < tgeTime) return 0;
        if (buyTokens[msg.sender] <= 0) return 0;
        if (buyTokens[msg.sender] <= claimedTokens[msg.sender]) return 0;

        uint256 timeElapsed = block.timestamp - tgeTime;

        if (timeElapsed > duration)
            timeElapsed = duration;
        
        uint256 _tge = 100 - tgeAmount;
        uint256 unlockedPercent = _tge * timeElapsed / duration;
        unlockedPercent = unlockedPercent + tgeAmount;

        uint256 unlockedAmount = buyTokens[msg.sender] * unlockedPercent / 100;

        uint256 claimable = unlockedAmount - claimedTokens[msg.sender];

        return claimable;
    }
    
    function claim() external {
        require(block.timestamp > endTime, "Sales not ended yet");
        require(buyTokens[msg.sender] > 0, "No token purcahsed");
        require(buyTokens[msg.sender] > claimedTokens[msg.sender], "You already claimed all");

        uint256 claimable = getClaimable();

        require (claimable > 0, "No token to claim");

        kataToken.transfer(msg.sender, claimable);

        claimedTokens[msg.sender] = claimedTokens[msg.sender] + claimable;
    }

    function withdrawETH() external onlyOwner {
        uint256 ethAmount = address(this).balance;
        payable(msg.sender).transfer(ethAmount);
    }

    function setSalesTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Invalid time");

        startTime = _startTime;
        endTime = _endTime;
    }

    function setETHrange(uint256 _minETHAmount, uint256 _maxETHAmount) external onlyOwner {
        require(minETHAmount < maxETHAmount, "Invalid range");
        minETHAmount = _minETHAmount;
        maxETHAmount = _maxETHAmount;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setVesting(uint256 _tgeAmount, uint256 _tgeTime, uint256 _duration) external onlyOwner {
        tgeAmount = _tgeAmount;
        tgeTime = _tgeTime;
        duration = _duration;
    }

    function setKataToken(address _kata) external onlyOwner {
        kataToken = IERC20(_kata);
    }

    function setFundingGoal(uint256 _fundingGoal) external onlyOwner {
        fundingGoal = _fundingGoal;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}