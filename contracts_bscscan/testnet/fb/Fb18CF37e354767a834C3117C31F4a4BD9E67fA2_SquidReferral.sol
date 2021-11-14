/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

/**
 * BEP20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IReferral {
    function addReferrer(address) external;
    function updateReferralStatus(address, uint256) external;
    function isActiveAccount(address) external view returns (bool);
    function calculateBonus(address, uint256) external view returns (uint256);
}


contract SquidReferral is Ownable {
    using SafeMath for uint;

    /**
     * @dev The struct of account information
     * @param referrer The referrer addresss
     * @param referredCount The total referral amount of an address
     * @param lastActiveTimestamp The last active timestamp of an address
     */
    struct Account {
        address referrer;
        uint referredCount;
        uint lastActiveTimestamp;
        bool signedUp;
    }

    /**
     * @dev Max referral bonus
     */
    uint8 constant MAX_REFERAL_BONUS = 50;

    uint256 MIN_TOKEN_THRESHOLD = 10 * 10**9 * 10**9; // 10 billion

    mapping(address => Account) public accounts;
    mapping(address => bool) public activeAccounts; // to keep track if this user is active
    uint256 referralBonus;
    uint256 referrerBonus;
    uint256 decimals;
    address _token;
    mapping (address => bool) defaultParents;

    event RegisteredReferer(address referer, address referree);
    event RegisterRefererFailed(address referee, address referrer, string reason);

    /**
     * @param _decimals The base decimals for float calc, for example 1000
     * @param _referralBonus The total referral bonus rate, which will be divided by decimals. For example, If you will like to set as 5%, it can set as 50 when decimals is 1000.
     * @param _referrerBonus The bonus rate if user has valid referrer, which will be divided by decimals. E.G. 20 with decimals as 1000 will yield 2%.
     * @param token The ERC-20 token contract address
     */
    constructor(uint _decimals, uint _referralBonus, uint _referrerBonus, address token) {
        decimals = _decimals;
        referralBonus = _referralBonus;
        referrerBonus = _referrerBonus;
        _token = token;
    }

    modifier onlyToken() {
        require(_token == _msgSender(), "Ownable: caller is not the token");
        _;
    }

   /**
     * @dev Add default parent
     * @param addr address of default parent
     */
    function addDefaultParent(address addr) external onlyOwner {
        defaultParents[addr] = true;
    }

    /**
     * @dev Set the bonus multiplier for each downline that an address has
     * @param _referralBonus The total referral bonus rate, which will be divided by decimals. For example, If you will like to set as 5%, it can set as 50 when decimals is 1000.
     */
    function setReferralBonus(uint _referralBonus) external onlyOwner {
        referralBonus = _referralBonus;
    }
    
    /**
     * @dev Set the bonus for address that has a valid upline
     * @param _referrerBonus The bonus rate if user has valid referrer, which will be divided by decimals. E.G. 20 with decimals as 1000 will yield 2%.
     */
    function setReferrerBonus(uint _referrerBonus) external onlyOwner {
        referrerBonus = _referrerBonus;
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function hasReferrer(address addr) public view returns(bool) {
        return accounts[addr].referrer != address(0);
    }

    function isCircularReference(address referrer, address referee) internal view returns(bool) {
        return accounts[referrer].referrer == referee;
    }

    /**
     * @dev Add an address as referrer
     * @param referrer The address would set as referrer of msg.sender
     */
    function addReferrer(address referrer, address referree) external onlyToken{
        // Check for MIN_TOKEN_THRESHOLD
        uint256 balance = IERC20(_token).balanceOf(referree);
        require(balance >= MIN_TOKEN_THRESHOLD, "Minimum token holdings not met");

        require(!isCircularReference(referrer, referree), "Referrer and referee cannot be the same");
        require(accounts[referree].referrer == address(0) || defaultParents[accounts[referree].referrer], "Address has registered upline");

        Account storage userAccount = accounts[referree];
        Account storage parentAccount = accounts[referrer];

        userAccount.referrer = referrer;
        userAccount.signedUp = true;
        activeAccounts[referree] = true;
        parentAccount.referredCount = parentAccount.referredCount.add(1);

        emit RegisteredReferer(referrer, referree);
    }

    /**
     * @dev this function should be called whenever a transfer occurs, and it should be called for both sender and recipient
     * @param referee address of the sender/recipient
     * @param balance the IERC20 token balance of referee
     */
    function updateReferralStatus(address referee, uint256 balance) external onlyToken {
        // Only update registered referee
        if (!accounts[referee].signedUp) {
            return;
        }

        address parentAddress = accounts[referee].referrer;
        Account storage parentAccount = accounts[parentAddress];

        if (activeAccounts[referee] && balance < MIN_TOKEN_THRESHOLD) {
            activeAccounts[referee] = false;
            parentAccount.referredCount = parentAccount.referredCount.sub(1);
        } else if (!activeAccounts[referee] && balance >= MIN_TOKEN_THRESHOLD) {
            activeAccounts[referee] = true;
            parentAccount.referredCount = parentAccount.referredCount.add(1);
        }
    }

    function setToken(address token) external onlyOwner {
        _token = token;
    }

    function tokenAddress() external view returns (address) {
        return _token;
    }

    function referrer(address addr) external view returns (address) {
        return accounts[addr].referrer;
    }

    function referralCount(address addr) external view returns (uint) {
        return accounts[addr].referredCount;
    }

    /**
     * @dev Calculate the amount an address should receive after applying bonus
     * @param addr Address of the recipient
     * @param value The original amount
     * @return The total amount after calculaing referrer and referral bonus
     */
    function calculateBonus(address addr, uint256 value) external view returns (uint256) {
        Account storage userAccount = accounts[addr];
        uint totalValue = value;

        // Calculate referrer bonus
        // TODO: check for defaultParents
        if (userAccount.referrer != address(0) && !defaultParents[userAccount.referrer]) {
            totalValue += value.mul(referrerBonus).div(decimals);
        }

        // Calculate referral bonus
        uint totalReferal;

        if (userAccount.referredCount > MAX_REFERAL_BONUS) {
            totalReferal = MAX_REFERAL_BONUS;
        } else {
            totalReferal = userAccount.referredCount;
        }

        totalValue += value.mul(totalReferal.mul(referralBonus)).div(decimals);

        return totalValue;
    }

    function isActiveAccount(address account) external view returns (bool) {
        return activeAccounts[account];
    }
}