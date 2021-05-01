/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-29
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
 
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}



contract angrybowserHelper is Context, Ownable {
    using SafeMath for uint256;
    
    struct WhitelistRound {
        uint256 duration;
        mapping(address => bool) addresses;
        mapping(address => uint256) purchased;
    }
  
    WhitelistRound[] public _lgeWhitelistRounds;
    bool public isLGEWhitelistEnabled = true;
    
    uint256 public _lgeTimestamp;
    address public _lgePairAddress;
    address public angrybowserToken = address(0);
    
    uint256 public cooldownSeconds = 60;
    
    mapping (address => uint256) public cooldown;
    mapping (address => bool) public isWhitelisted;
    
    /*
     * createLGEWhitelist - Call this after initial Token Generation Event (TGE) 
     * 
     * pairAddress - address generated from createPair() event on DEX
     * durations - array of durations (seconds) for each whitelist rounds
     * 
     */
  
    function createLGEWhitelist(address pairAddress, uint256[] calldata durations) external onlyOwner {
        
        require(_lgePairAddress == pairAddress, "Wrong pair address");
        
        if(durations.length > 0) {
            
            delete _lgeWhitelistRounds;
        
            for (uint256 i = 0; i < durations.length; i++) {
                _lgeWhitelistRounds.push(WhitelistRound(durations[i]));
            }
        
        }
    }
    
    /*
     * modifyLGEWhitelistAddresses - Define what addresses are included/excluded from a whitelist round
     * 
     * index - 0-based index of round to modify whitelist
     * duration - period in seconds from LGE event or previous whitelist round
     * 
     */
    
    function modifyLGEWhitelist(uint256 index, uint256 duration, address[] calldata addresses, bool enabled) external onlyOwner {
        require(index < _lgeWhitelistRounds.length, "Invalid index");

        if(duration != _lgeWhitelistRounds[index].duration)
            _lgeWhitelistRounds[index].duration = duration;
        
        for (uint256 i = 0; i < addresses.length; i++) {
            _lgeWhitelistRounds[index].addresses[addresses[i]] = enabled;
        }
    }
    
    /*
     *  getLGEWhitelistRound
     *
     *  returns:
     *
     *  1. whitelist round number ( 0 = no active round now )
     *  2. duration, in seconds, current whitelist round is active for
     *  3. timestamp current whitelist round closes at
     *  4. is caller whitelisted
     *  5. how much caller has purchased in current whitelist round
     *
     */
    
    function getLGEWhitelistRound() public view returns (uint256, uint256, uint256, bool, uint256) {
        if(_lgeTimestamp > 0) {
            
            uint256 wlCloseTimestampLast = _lgeTimestamp;
        
            for (uint256 i = 0; i < _lgeWhitelistRounds.length; i++) {
                
                WhitelistRound storage wlRound = _lgeWhitelistRounds[i];
                
                wlCloseTimestampLast = wlCloseTimestampLast.add(wlRound.duration);
                if(now <= wlCloseTimestampLast)
                    return (i.add(1), wlRound.duration, wlCloseTimestampLast, wlRound.addresses[_msgSender()], wlRound.purchased[_msgSender()]);
            }
        }
        return (0, 0, 0, false, 0);
    }
    
    
    function _applyLGEWhitelist(address sender, address recipient, uint256 amount) internal {
        
        if(_lgePairAddress == address(0) || _lgeWhitelistRounds.length == 0)
            return;
        
        if(_lgeTimestamp == 0 && sender != _lgePairAddress && recipient == _lgePairAddress && amount > 0)
            _lgeTimestamp = now;
        
        if(sender == _lgePairAddress && recipient != _lgePairAddress) {
            //buying
            
            (uint256 wlRoundNumber,,,,) = getLGEWhitelistRound();
        
            if(wlRoundNumber > 0) {
                
                WhitelistRound storage wlRound = _lgeWhitelistRounds[wlRoundNumber.sub(1)];
                
                require(wlRound.addresses[recipient], "LGE - Buyer is not whitelisted");
                
                wlRound.purchased[recipient] = wlRound.purchased[recipient].add(amount);
                
            }
        }
    }
    
    function setangrybowserAddress(address newangrybowser) public onlyOwner returns(bool) {
        require(angrybowserToken == address(0), "angrybowser already set up");
        angrybowserToken = newangrybowser;
        isWhitelisted[angrybowserToken] = true;
        
        return true;
    }
    
    function setangrybowserPairAddress(address newangrybowserPair) public onlyOwner returns(bool) {
        require(_lgePairAddress == address(0), "angrybowser Pair already set up");
        _lgePairAddress = newangrybowserPair;
        isWhitelisted[_lgePairAddress] = true;
        
        return true;
    }
    
    function engageMechanicsOnTransfer(address sender, address recipient, uint256 amount) external returns(bool) {
        
        require(msg.sender == angrybowserToken, "Message sender is not angrybowser Token");
        
        address toCooldown;
        
        if(sender == _lgePairAddress) {
            toCooldown = recipient;
        } else {
            toCooldown = sender;
        }
        
        if(isWhitelisted[toCooldown] == false) {
            require(cooldown[toCooldown] < now, "angrybowser Cooldown: user cooldown active");
            
            cooldown[toCooldown] = now.add(cooldownSeconds);
        }
        
        if(isLGEWhitelistEnabled == true) {
            _applyLGEWhitelist(sender, recipient, amount);
        }
        
        return true;
    }
    
    function whitelistSet(address account, bool newState) onlyOwner public {
        isWhitelisted[account] = newState;
    }
    
    function updateCooldownSeconds(uint256 newSeconds) onlyOwner public {
        require(newSeconds <= 10*60, "Cooldown cannot be more than 10 minutes");
        
        cooldownSeconds = newSeconds;
    }
    
    function setLGEWhitelistEnabled(bool newState) onlyOwner public {
        isLGEWhitelistEnabled = newState;
    }
    
    function isAddressLGEWhitelisted(address account, uint256 whitelistId) public view returns(bool) {
        WhitelistRound storage wlRound = _lgeWhitelistRounds[whitelistId];
        return wlRound.addresses[account];
    }
    
}