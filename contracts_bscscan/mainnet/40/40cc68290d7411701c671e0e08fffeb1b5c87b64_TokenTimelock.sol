/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-03
*/

pragma solidity ^0.5.0;

/*****************************************************************************
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");

        return a - b;
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}


/*****************************************************************************
 * @dev Interface of the KRC20 standard as defined in the EIP.
 */
interface ERC20 {
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/*****************************************************************************
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time.
 */
contract TokenTimelock is Ownable {
    using SafeMath for uint256;

    uint256 constant public PERIOD = 2592000; // 30 days, 
    uint256 constant public START_TIME = 1627344000; // 12:00:00 GMT 27/7/2021
    address public DPET_TOKEN = 0xfb62AE373acA027177D1c18Ee0862817f9080d08;

    mapping(address => uint256) public countRelease;
    mapping(address => uint256) private balanceOf;
    mapping(address => uint256) private numberOfToken;
    mapping(address => uint256) public nextRelease;
    
    constructor(address _addr, uint256 _amount) public {
            balanceOf[_addr] = _amount;
            numberOfToken[_addr] = _amount;
            nextRelease[_addr] = START_TIME;
    }
    
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(balanceOf[msg.sender] > 0, "Invalid amount");
        require(block.timestamp >= START_TIME + PERIOD.mul(countRelease[msg.sender]), "TokenTimelock: current time is before release time");
        require(ERC20(DPET_TOKEN).balanceOf(address(this)) > 0, "TokenTimelock: no tokens to release");
        
        uint256 cliff = block.timestamp.sub(nextRelease[msg.sender]).div(PERIOD) + 1;
        uint256 amount = numberOfToken[msg.sender].mul(cliff).div(19);
        if (countRelease[msg.sender] + cliff >= 19){
            ERC20(DPET_TOKEN).transfer(msg.sender, balanceOf[msg.sender]);
            balanceOf[msg.sender] = 0;
        } else {
            nextRelease[msg.sender] = nextRelease[msg.sender] + PERIOD.mul(cliff);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);

            ERC20(DPET_TOKEN).transfer(msg.sender, amount); 

        }
        
        countRelease[msg.sender] += cliff;
    }
    
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }
    
    function getTimeReleaseNext() public view returns(uint256) {
        return START_TIME + PERIOD.mul(countRelease[msg.sender]);
    }

    function setTokenAddress(address _addr) external onlyOwner {
        DPET_TOKEN = _addr;
    }
	
	function emergencyWithdrawToken(uint256 _amount) external onlyOwner {
	    ERC20(DPET_TOKEN).transfer(owner(), _amount); 
	}
	
    function getBalance() public view returns (uint256) {
        return ERC20(DPET_TOKEN).balanceOf(address(this));
    }

}