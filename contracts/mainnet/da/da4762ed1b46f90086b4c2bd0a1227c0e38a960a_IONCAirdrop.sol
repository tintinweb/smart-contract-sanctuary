pragma solidity 0.4.24;

// File: contracts/commons/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/flavours/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

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
}

// File: contracts/flavours/Lockable.sol

/**
 * @title Lockable
 * @dev Base contract which allows children to
 *      implement main operations locking mechanism.
 */
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

    /**
     * @dev Modifier to make a function callable
    *       only when the contract is not locked.
     */
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev Modifier to make a function callable
     *      only when the contract is locked.
     */
    modifier whenLocked() {
        require(locked);
        _;
    }

    /**
     * @dev called by the owner to locke, triggers locked state
     */
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

    /**
     * @dev called by the owner
     *      to unlock, returns to unlocked state
     */
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

// File: contracts/base/ERC20Token.sol

interface ERC20Token {
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
}

// File: contracts/base/BaseAirdrop.sol

contract BaseAirdrop is Lockable {
    using SafeMath for uint;

    ERC20Token public token;

    address public tokenHolder;

    mapping(address => bool) public users;

    event AirdropToken(address indexed to, uint amount);

    constructor(address _token, address _tokenHolder) public {
        require(_token != address(0) && _tokenHolder != address(0));
        token = ERC20Token(_token);
        tokenHolder = _tokenHolder;
    }

    function airdrop(uint8 v, bytes32 r, bytes32 s) public whenNotLocked {
        if (ecrecover(keccak256("Signed for Airdrop", address(this), address(token), msg.sender), v, r, s) != owner
            || users[msg.sender]) {
            revert();
        }
        users[msg.sender] = true;
        uint amount = getAirdropAmount(msg.sender);
        token.transferFrom(tokenHolder, msg.sender, amount);
        emit AirdropToken(msg.sender, amount);
    }

    function getAirdropStatus(address user) public constant returns (bool success) {
        return users[user];
    }

    function getAirdropAmount(address user) public constant returns (uint amount);
}

// File: contracts/IONCAirdrop.sol

/**
 * @title IONC token airdrop contract.
 */
contract IONCAirdrop is BaseAirdrop {

    uint public constant PER_USER_AMOUNT = 20023e6;

    constructor(address _token, address _tokenHolder) public BaseAirdrop(_token, _tokenHolder) {
        locked = true;
    }

    // Disable direct payments
    function() external payable {
        revert();
    }

    function getAirdropAmount(address user) public constant returns (uint amount) {
        require(user != address(0));
        return PER_USER_AMOUNT;
    }
}