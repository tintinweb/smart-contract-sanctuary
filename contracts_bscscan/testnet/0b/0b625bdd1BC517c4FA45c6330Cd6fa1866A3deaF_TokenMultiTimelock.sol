/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IBEP20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenMultiTimelock is Ownable {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    mapping(address => uint256) private _allocated;
    mapping(address => uint256) private _claimed;
    
    struct Release {
        uint256 fromTimestamp;
        uint256 toTimestamp;
        uint256 interval;
        uint256 percent; //2 DECIMALS, eg. 33.33% = 3333
    }
    
    Release[] private _releases;
    
    IBEP20 private _token;

    constructor (IBEP20 token) public {
        _token = token;
    }
    
    function setupReleases(uint256[] memory fromTimestamps, uint256[] memory toTimestamps, uint256[] memory intervals, uint256[] memory percents) external onlyOwner {
        require(fromTimestamps.length == toTimestamps.length, "TokenTimelock: Invalid releases");
        require(toTimestamps.length == intervals.length, "TokenTimelock: Invalid releases");
        require(intervals.length == percents.length, "TokenTimelock: Invalid releases");
        
        delete _releases;
        
        for (uint256 i = 0; i < fromTimestamps.length; i++) {
            _releases.push(Release(fromTimestamps[i], toTimestamps[i], intervals[i], percents[i]));
        }

    }
    
    function setupAllocations(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "TokenTimelock: Invalid allocations");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            _allocated[addresses[i]] = amounts[i];
        }

    }
    
    function setClaimed(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(addresses.length == amounts.length, "TokenTimelock: Invalid claimed");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            _claimed[addresses[i]] = amounts[i];
        }

    }

    function token() public view virtual returns (IBEP20) {
        return _token;
    }
    
    function infoAllocation(address wallet) external view virtual returns (string memory, string memory, string memory) {
        
        (uint256 allocated, uint256 unlocked, uint256 claimed, uint256 claimable) = _infoAllocation(wallet);
        
        uint256 decimals = _token.decimals();
        
        string memory whole = _uintToStr(unlocked.div(10 ** decimals));
        string memory fract = _uintToStr(unlocked.sub(unlocked.div(10 ** decimals).mul(10 ** decimals)));
    
        string memory unlockedText = string(abi.encodePacked(whole, ".", fract, " / "));
        
        whole = _uintToStr(allocated.div(10 ** decimals));
        fract = _uintToStr(allocated.sub(allocated.div(10 ** decimals).mul(10 ** decimals)));
        
        unlockedText = string(abi.encodePacked(unlockedText, whole, ".", fract, " ", _token.symbol(), " Unlocked"));
        
        whole = _uintToStr(claimed.div(10 ** decimals));
        fract = _uintToStr(claimed.sub(claimed.div(10 ** decimals).mul(10 ** decimals)));
        
        string memory claimedText = string(abi.encodePacked(whole, ".", fract, " ", _token.symbol(), " Claimed already"));        

        whole = _uintToStr(claimable.div(10 ** decimals));
        fract = _uintToStr(claimable.sub(claimable.div(10 ** decimals).mul(10 ** decimals)));
        
        string memory claimableText = string(abi.encodePacked(whole, ".", fract, " ", _token.symbol(), " Claimable NOW"));
        
        return (unlockedText, claimedText, claimableText);
        
    }
        

    function _infoAllocation(address a) internal view virtual returns (uint256 allocated, uint256 unlocked, uint256 claimed, uint256 claimable) {
        
        allocated = _allocated[a];
        
        if(allocated > 0) {
            
            claimed = _claimed[a];
        
            for (uint256 i = 0; i < _releases.length; i++) {
                
                Release memory r = _releases[i];
                
                if(block.timestamp < r.fromTimestamp)
                    break;
                    
                uint256 total = _allocated[a].mul(r.percent).div(10000);
                
                if(r.toTimestamp > r.fromTimestamp && block.timestamp < r.toTimestamp) {
                    
                    uint256 elapsed = 0;
    
                    if(block.timestamp > r.fromTimestamp) {
                        elapsed = block.timestamp.sub(r.fromTimestamp);
                        if(r.interval > 0)
                            elapsed = elapsed.sub(elapsed.mod(r.interval));
                    }
                    
                    unlocked += total.mul(elapsed).div(r.toTimestamp.sub(r.fromTimestamp));
                    
                } else {
                    unlocked += total;
                }
                
            }
            
            if(unlocked > claimed)
                claimable = unlocked.sub(claimed);
        
        }
        
        return (allocated, unlocked, claimed, claimable);
    }

    function claim() public virtual {
        
        (, , , uint256 claimable) = _infoAllocation(msg.sender);
        
        require(claimable > 0,"TokenTimelock: no tokens to claim");
        require(_token.balanceOf(address(this)) >= claimable, "TokenTimelock: insufficient tokens held by contract");
        
        _claimed[msg.sender] = _claimed[msg.sender].add(claimable);
        
        _token.safeTransfer(msg.sender, claimable);
    }
    
    /// @notice converts number to string
    /// @dev source: https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol#L1045
    /// @param _i integer to convert
    /// @return _uintAsString
    function _uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        uint number = _i;
        if (number == 0) {
            return "0";
        }
        uint j = number;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }
}