pragma solidity 0.4.24;

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

// File: contracts/flavours/Whitelisted.sol

contract Whitelisted is Ownable {

    /// @dev True if whitelist enabled
    bool public whitelistEnabled = true;

    /// @dev ICO whitelist
    mapping(address => bool) public whitelist;

    event ICOWhitelisted(address indexed addr);
    event ICOBlacklisted(address indexed addr);

    modifier onlyWhitelisted {
        require(!whitelistEnabled || whitelist[msg.sender]);
        _;
    }

    /**
     * Add address to ICO whitelist
     * @param address_ Investor address
     */
    function whitelist(address address_) external onlyOwner {
        whitelist[address_] = true;
        emit ICOWhitelisted(address_);
    }

    /**
     * Remove address from ICO whitelist
     * @param address_ Investor address
     */
    function blacklist(address address_) external onlyOwner {
        delete whitelist[address_];
        emit ICOBlacklisted(address_);
    }

    /**
     * @dev Returns true if given address in ICO whitelist
     */
    function whitelisted(address address_) public view returns (bool) {
        if (whitelistEnabled) {
            return whitelist[address_];
        } else {
            return true;
        }
    }

    /**
     * @dev Enable whitelisting
     */
    function enableWhitelist() public onlyOwner {
        whitelistEnabled = true;
    }

    /**
     * @dev Disable whitelisting
     */
    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
    }
}

// File: contracts/interface/ERC20Token.sol

interface ERC20Token {
    function balanceOf(address owner_) external returns (uint);
    function allowance(address owner_, address spender_) external returns (uint);
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
}

// File: contracts/base/BaseICO.sol

/**
 * @dev Base abstract smart contract for any ICO
 */
contract BaseICO is Ownable, Whitelisted {

    /// @dev ICO state
    enum State {

        // ICO is not active and not started
        Inactive,

        // ICO is active, tokens can be distributed among investors.
        // ICO parameters (end date, hard/low caps) cannot be changed.
        Active,

        // ICO is suspended, tokens cannot be distributed among investors.
        // ICO can be resumed to `Active state`.
        // ICO parameters (end date, hard/low caps) may changed.
        Suspended,

        // ICO is terminated by owner, ICO cannot be resumed.
        Terminated,

        // ICO goals are not reached,
        // ICO terminated and cannot be resumed.
        NotCompleted,

        // ICO completed, ICO goals reached successfully,
        // ICO terminated and cannot be resumed.
        Completed
    }

    /// @dev Token which controlled by this ICO
    ERC20Token public token;

    /// @dev Current ICO state.
    State public state;

    /// @dev ICO start date seconds since epoch.
    uint public startAt;

    /// @dev ICO end date seconds since epoch.
    uint public endAt;

    /// @dev Minimal amount of investments in wei needed for successful ICO
    uint public lowCapWei;

    /// @dev Maximal amount of investments in wei for this ICO.
    /// If reached ICO will be in `Completed` state.
    uint public hardCapWei;

    /// @dev Minimal amount of investments in wei per investor.
    uint public lowCapTxWei;

    /// @dev Maximal amount of investments in wei per investor.
    uint public hardCapTxWei;

    /// @dev Number of investments collected by this ICO
    uint public collectedWei;

    /// @dev Number of sold tokens by this ICO
    uint public tokensSold;

    /// @dev Team wallet used to collect funds
    address public teamWallet;

    // ICO state transition events
    event ICOStarted(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
    event ICOResumed(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
    event ICOSuspended();
    event ICOTerminated();
    event ICONotCompleted();
    event ICOCompleted(uint collectedWei);
    event ICOInvestment(address indexed from, uint investedWei, uint tokens, uint8 bonusPct);

    modifier isSuspended() {
        require(state == State.Suspended);
        _;
    }

    modifier isActive() {
        require(state == State.Active);
        _;
    }

    /**
     * @dev Trigger start of ICO.
     * @param endAt_ ICO end date, seconds since epoch.
     */
    function start(uint endAt_) public onlyOwner {
        require(endAt_ > block.timestamp && state == State.Inactive);
        endAt = endAt_;
        startAt = block.timestamp;
        state = State.Active;
        emit ICOStarted(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
    }

    /**
     * @dev Suspend this ICO.
     * ICO can be activated later by calling `resume()` function.
     * In suspend state, ICO owner can change basic ICO parameter using `tune()` function,
     * tokens cannot be distributed among investors.
     */
    function suspend() public onlyOwner isActive {
        state = State.Suspended;
        emit ICOSuspended();
    }

    /**
     * @dev Terminate the ICO.
     * ICO goals are not reached, ICO terminated and cannot be resumed.
     */
    function terminate() public onlyOwner {
        require(state != State.Terminated &&
        state != State.NotCompleted &&
        state != State.Completed);
        state = State.Terminated;
        emit ICOTerminated();
    }

    /**
     * @dev Change basic ICO parameters. Can be done only during `Suspended` state.
     * Any provided parameter is used only if it is not zero.
     * @param endAt_ ICO end date seconds since epoch. Used if it is not zero.
     * @param lowCapWei_ ICO low capacity. Used if it is not zero.
     * @param hardCapWei_ ICO hard capacity. Used if it is not zero.
     * @param lowCapTxWei_ Min limit for ICO per transaction
     * @param hardCapTxWei_ Hard limit for ICO per transaction
     */
    function tune(uint endAt_,
        uint lowCapWei_,
        uint hardCapWei_,
        uint lowCapTxWei_,
        uint hardCapTxWei_) public onlyOwner isSuspended {
        if (endAt_ > block.timestamp) {
            endAt = endAt_;
        }
        if (lowCapWei_ > 0) {
            lowCapWei = lowCapWei_;
        }
        if (hardCapWei_ > 0) {
            hardCapWei = hardCapWei_;
        }
        if (lowCapTxWei_ > 0) {
            lowCapTxWei = lowCapTxWei_;
        }
        if (hardCapTxWei_ > 0) {
            hardCapTxWei = hardCapTxWei_;
        }
        require(lowCapWei <= hardCapWei && lowCapTxWei <= hardCapTxWei);
        touch();
    }

    /**
     * @dev Resume a previously suspended ICO.
     */
    function resume() public onlyOwner isSuspended {
        state = State.Active;
        emit ICOResumed(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
        touch();
    }

    /**
     * @dev Recalculate ICO state based on current block time.
     * Should be called periodically by ICO owner.
     */
    function touch() public;

    /**
     * @dev Buy tokens
     */
    function buyTokens() public payable;

    /**
     * @dev Send ether to the fund collection wallet
     */
    function forwardFunds() internal {
        teamWallet.transfer(msg.value);
    }
}

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

// File: contracts/IonChainICO.sol

/**
 * @title IONC tokens ICO contract.
 */
contract IonChainICO is BaseICO {
    using SafeMath for uint;

    /// @dev 6 decimals for token
    uint internal constant ONE_TOKEN = 1e6;

    /// @dev 1e18 WEI == 1ETH == 125000 tokens
    uint public constant ETH_TOKEN_EXCHANGE_RATIO = 125000;

    /// @dev Token holder
    address public tokenHolder;

    // @dev personal cap for first 48 hours
    uint public constant PERSONAL_CAP = 1.6 ether;

    // @dev timestamp for end of personal cap
    uint public personalCapEndAt;

    // @dev purchases till personal cap limit end
    mapping(address => uint) internal personalPurchases;

    constructor(address icoToken_,
            address teamWallet_,
            address tokenHolder_,
            uint lowCapWei_,
            uint hardCapWei_,
            uint lowCapTxWei_,
            uint hardCapTxWei_) public {
        require(icoToken_ != address(0) && teamWallet_ != address(0));
        token = ERC20Token(icoToken_);
        teamWallet = teamWallet_;
        tokenHolder = tokenHolder_;
        state = State.Inactive;
        lowCapWei = lowCapWei_;
        hardCapWei = hardCapWei_;
        lowCapTxWei = lowCapTxWei_;
        hardCapTxWei = hardCapTxWei_;
    }

    /**
     * Accept direct payments
     */
    function() external payable {
        buyTokens();
    }


    function start(uint endAt_) onlyOwner public {
        uint requireTokens = hardCapWei.mul(ETH_TOKEN_EXCHANGE_RATIO).mul(ONE_TOKEN).div(1 ether);
        require(token.balanceOf(tokenHolder) >= requireTokens
            && token.allowance(tokenHolder, address(this)) >= requireTokens);
        personalCapEndAt = block.timestamp + 48 hours;
        super.start(endAt_);
    }

    /**
     * @dev Recalculate ICO state based on current block time.
     * Should be called periodically by ICO owner.
     */
    function touch() public {
        if (state != State.Active && state != State.Suspended) {
            return;
        }
        if (collectedWei >= hardCapWei) {
            state = State.Completed;
            endAt = block.timestamp;
            emit ICOCompleted(collectedWei);
        } else if (block.timestamp >= endAt) {
            if (collectedWei < lowCapWei) {
                state = State.NotCompleted;
                emit ICONotCompleted();
            } else {
                state = State.Completed;
                emit ICOCompleted(collectedWei);
            }
        }
    }

    function buyTokens() public onlyWhitelisted payable {
        require(state == State.Active &&
            block.timestamp <= endAt &&
            msg.value >= lowCapTxWei &&
            msg.value <= hardCapTxWei &&
            collectedWei + msg.value <= hardCapWei);
        uint amountWei = msg.value;

        // check personal cap
        if (block.timestamp <= personalCapEndAt) {
            personalPurchases[msg.sender] = personalPurchases[msg.sender].add(amountWei);
            require(personalPurchases[msg.sender] <= PERSONAL_CAP);
        }

        uint itokens = amountWei.mul(ETH_TOKEN_EXCHANGE_RATIO).mul(ONE_TOKEN).div(1 ether);
        collectedWei = collectedWei.add(amountWei);

        emit ICOInvestment(msg.sender, amountWei, itokens, 0);
        // Transfer tokens to investor
        token.transferFrom(tokenHolder, msg.sender, itokens);
        forwardFunds();
        touch();
    }
}