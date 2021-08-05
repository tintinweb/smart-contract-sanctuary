/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

pragma solidity ^0.6.2;

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

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title ERC1132 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1132
 */

abstract contract ERC1132 {
    /**
     * @dev Reasons why a user's tokens have been locked
     */
    mapping(address => bytes32[]) public lockReason;

    /**
     * @dev locked token structure
     */
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    /**
     * @dev Holds number & validity of tokens locked for a given reason for
     *      a specified address
     */
    mapping(address => mapping(bytes32 => lockToken)) public locked;

    /**
     * @dev Records data of all the tokens Locked
     */
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );
    
    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be locked
     * @param _time Lock time in seconds
     */
    function lock(string memory _reason, uint256 _amount, uint256 _time)
        public virtual returns (bool);
  
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, string memory _reason)
        public virtual view returns (uint256 amount);
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, string memory _reason, uint256 _time)
        public virtual view returns (uint256 amount);
    
    /**
     * @dev Returns total tokens held by an address (locked + transferable)
     * @param _of The address to query the total balance of
     */
    function totalBalanceOf(address _of)
        public virtual view returns (uint256 amount);
    
    /**
     * @dev Extends lock for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _time Lock extension time in seconds
     */
    function extendLock(string memory _reason, uint256 _time)
        public virtual returns (bool);
    
    /**
     * @dev Increase number of tokens locked for a specified reason
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be increased
     */
    function increaseLockAmount(string memory _reason, uint256 _amount)
        public virtual returns (bool);

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, string memory _reason)
        public virtual view returns (uint256 amount);
 
    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens
     */
    function unlock(address _of)
        public virtual returns (uint256 unlockableTokens);

    /**
     * @dev Gets the unlockable tokens of a specified address
     * @param _of The address to query the the unlockable token count of
     */
    function getUnlockableTokens(address _of)
        public virtual view returns (uint256 unlockableTokens);

}

interface SocialRocketContrat{
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}



contract SocialRocketLock is Ownable , ERC1132 {

    using SafeMath for uint256;

    mapping (address => uint256) private _released;

    SocialRocketContrat private rocks;
    address private token;
    
    string internal constant ALREADY_LOCKED = 'Tokens already locked';
    string internal constant NOT_LOCKED = 'No tokens locked';
    string internal constant AMOUNT_ZERO = 'Amount can not be 0';

     
    constructor(address socialRocketContract) public {
        rocks = SocialRocketContrat(socialRocketContract);
        token = socialRocketContract;
        
    }
    
    /********
    TEAM LOCK
    ********/
    
    function lock(string memory _reason, uint256 _amount, uint256 _time)
        public override onlyOwner
        returns (bool)
    {
        bytes32 reason = stringToBytes32(_reason);
        uint256 validUntil = now.add(_time); //solhint-disable-line

        // If tokens are already locked, then functions extendLock or
        // increaseLockAmount should be used to make any changes
        require(tokensLocked(msg.sender, bytes32ToString(reason)) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[msg.sender][reason].amount == 0)
            lockReason[msg.sender].push(reason);

        rocks.transferFrom(msg.sender, address(this), _amount);

        locked[msg.sender][reason] = lockToken(_amount, validUntil, false);

        emit Locked(msg.sender, reason, _amount, validUntil);
        return true;
    }
    
    function transferWithLock(address _to, string memory _reason, uint256 _amount, uint256 _time)
        public onlyOwner
        returns (bool)
    {
        bytes32 reason = stringToBytes32(_reason);
        uint256 validUntil = now.add(_time); //solhint-disable-line

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][reason].amount == 0)
            lockReason[_to].push(reason);

        rocks.transferFrom(msg.sender, address(this), _amount);

        locked[_to][reason] = lockToken(_amount, validUntil, false);
        
        emit Locked(_to, reason, _amount, validUntil);
        return true;
    }

    function tokensLocked(address _of, string memory _reason)
        public override
        view
        returns (uint256 amount)
    {
        bytes32 reason = stringToBytes32(_reason);
        if (!locked[_of][reason].claimed)
            amount = locked[_of][reason].amount;
    }
    
    function tokensLockedAtTime(address _of, string memory _reason, uint256 _time)
        public override
        view
        returns (uint256 amount)
    {
        bytes32 reason = stringToBytes32(_reason);
        if (locked[_of][reason].validity > _time)
            amount = locked[_of][reason].amount;
    }

    function totalBalanceOf(address _of)
        public override
        view
        returns (uint256 amount)
    {
        amount = rocks.balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(tokensLocked(_of, bytes32ToString(lockReason[_of][i])));
        }   
    }    
    
    function extendLock(string memory _reason, uint256 _time)
        public override onlyOwner
        returns (bool)
    {
        bytes32 reason = stringToBytes32(_reason);
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        locked[msg.sender][reason].validity = locked[msg.sender][reason].validity.add(_time);

        emit Locked(msg.sender, reason, locked[msg.sender][reason].amount, locked[msg.sender][reason].validity);
        return true;
    }
    
    function increaseLockAmount(string memory _reason, uint256 _amount)
        public override onlyOwner
        returns (bool)
    {
        bytes32 reason = stringToBytes32(_reason);
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        rocks.transfer(address(this), _amount);

        locked[msg.sender][reason].amount = locked[msg.sender][reason].amount.add(_amount);

        emit Locked(msg.sender, reason, locked[msg.sender][reason].amount, locked[msg.sender][reason].validity);
        return true;
    }

    function tokensUnlockable(address _of, string memory _reason)
        public override
        view
        returns (uint256 amount)
    {
        bytes32 reason = stringToBytes32(_reason);
        if (locked[_of][reason].validity <= now && !locked[_of][reason].claimed) //solhint-disable-line
            amount = locked[_of][reason].amount;
    }

    function unlock(address _of)
        public override onlyOwner
        returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, bytes32ToString(lockReason[_of][i]));
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }  

        if (unlockableTokens > 0)
            rocks.transfer(_of, unlockableTokens);
    }

    function getUnlockableTokens(address _of)
        public override
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, bytes32ToString(lockReason[_of][i])));
        }  
    }
    
    function getremainingLockTime(address _of, string memory _reason) public view returns (uint256 remainingTime) {
        bytes32 reason = stringToBytes32(_reason);
        if (locked[_of][reason].validity > now && !locked[_of][reason].claimed) //solhint-disable-line
            remainingTime = locked[_of][reason].validity.sub(now);
    }
    
    function getremainingLockDays(address _of, string memory _reason) public view returns (uint256 remainingDays) {
        bytes32 reason = stringToBytes32(_reason);
        if (locked[_of][reason].validity > now && !locked[_of][reason].claimed) //solhint-disable-line
            remainingDays = (locked[_of][reason].validity.sub(now)) / 86400;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function bytes32ToString(bytes32 x) public pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}