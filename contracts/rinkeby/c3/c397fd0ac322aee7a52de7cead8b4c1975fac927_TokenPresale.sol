/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
/**
 * @dev Collection of functions related to the address type
 */
 
pragma solidity >=0.6.0 <0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity >= 0.6.0 < 0.8.0;

/**
 * @dev Provides information about the current execution context, including the sender of the transaction and its data.
 * While these are generally available via msg.sender and msg.data, they should not be accessed in such a direct manner,
 * since when dealing with GSN meta-transactions the account sending and paying for execution may not be the actual sender.
 **/
 
contract Context {
    constructor () public {}
    
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >= 0.6.0 < 0.8.0;

/**
 * @dev Wrappers over SOlidity's arithmetich operations with added overflow checks.
 **/
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }   
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >= 0.6.0 < 0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where there is an account (an owner)
 * that can be granted exclusive access to specific functions.
 **/
 
contract Ownable is Context {
 address private _owner;
 
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 constructor () public {
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
}


pragma solidity >=0.6.0 < 0.8.0;

interface LibertyToken {
    function transfer(address to, uint256 value) external;
    function balanceOf(address account) external view returns (uint256);
}

contract TokenPresale is Ownable {
    using SafeMath for uint256;
    using Address for address;
    LibertyToken public token;
    address payable public presale;
    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public softCapEthAmount = 5 ether;
    uint256 public hardCapEthAmount = 500 ether;
    uint256 public totalDepositedEthBalance;
    uint256 public minimumDepositEthAmount = 0.01 ether;
    uint256 public maximumDepositEthAmount = 2 ether;
    uint256 public rewardTokenCount = 0.000119 ether;
    
    mapping(address => uint256) public deposits;
    event Received(address, uint);
    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    
    constructor(LibertyToken _token) public {
        token = _token;
        presale = 0xf7C2593292b4C6C399ebEabBa4d45e8466415E95;
        presaleStartTimestamp = now;
        presaleEndTimestamp = now.add(30 days + 1 hours + 30 minutes);
    }
    
    receive () external payable {
        deposit();
    }
    
    function deposit() public payable {
        require(now >= presaleStartTimestamp && now <= presaleEndTimestamp, "presale is not active");
        require(totalDepositedEthBalance.add(msg.value) <= hardCapEthAmount, "deposit limits reached");
        require(deposits[msg.sender].add(msg.value) >= minimumDepositEthAmount && deposits[msg.sender].add(msg.value) <= maximumDepositEthAmount, "incorrect amount");
        
        uint256 bnbvalue = msg.value;
        
        uint256 tokenAmount = bnbvalue.mul(1e8).div(rewardTokenCount, "");
        
        token.transfer(msg.sender, tokenAmount);             
        presale.transfer(address(this).balance);
        totalDepositedEthBalance = totalDepositedEthBalance.add(bnbvalue);
        deposits[msg.sender] = deposits[msg.sender].add(bnbvalue);
        emit Deposited(msg.sender, bnbvalue);
    }
    
    function setWithdrawAddress(address payable _address) external onlyOwner {
        presale = _address;
    }
    
    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
    
    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }
    
    function getLeftTimeAmount() public view returns (uint256) {
        if(now > presaleEndTimestamp) {
            return 0;
        } else {
            return (presaleEndTimestamp - now);
        }
    }
    
    function setRewardTokenCount(uint256 _count) external onlyOwner {
        rewardTokenCount = _count;
    }
    
    function getRewardTokenCount() public view returns (uint256) {
        return rewardTokenCount;
    }
}