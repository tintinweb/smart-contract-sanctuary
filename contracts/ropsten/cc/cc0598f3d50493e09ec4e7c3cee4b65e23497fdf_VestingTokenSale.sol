pragma solidity 0.4.24;
 
/**
 * Copyright 2018, Flowchain.co
 *
 * The FlowchainCoin (FLC) token contract for vesting sale
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface Token {
    /// @dev Mint an amount of tokens and transfer to the backer
    /// @param to The address of the backer who will receive the tokens
    /// @param amount The amount of rewarded tokens
    /// @return The result of token transfer
    function mintToken(address to, uint amount) external returns (bool success);  

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);    
}

contract MintableSale {
    // @notice Create a new mintable sale
    /// @param rate The exchange rate
    /// @param fundingGoalInEthers The funding goal in ethers
    /// @param durationInMinutes The duration of the sale in minutes
    /// @return 
    function createMintableSale(uint256 rate, uint256 fundingGoalInEthers, uint durationInMinutes) external returns (bool success);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;

    Token public tokenReward;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    address public _addressOfTokenUsedAsReward;

    mapping (address => uint256) private _released;

    /**
     * @dev Creates a vesting contract that vests its balance of FLC token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param addressOfTokenUsedAsReward where is the token contract
     */
    function createVesting(address beneficiary, uint256 start, uint256 cliffDuration, uint256 duration, address addressOfTokenUsedAsReward) public {
        require(beneficiary != address(0));
        require(cliffDuration <= duration);
        require(duration > 0);
        require(start.add(duration) > block.timestamp);

        _beneficiary = beneficiary;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
        _addressOfTokenUsedAsReward = addressOfTokenUsedAsReward;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /**
     * @notice Mints and transfers tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(address token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0);

        _released[token] = _released[token].add(unreleased);

        tokenReward.transfer(_beneficiary, unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     * @param token ERC20 token which is being vested
     */
    function _releasableAmount(address token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[token]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function _vestedAmount(address token) private view returns (uint256) {
        uint256 currentBalance = tokenReward.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[token]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}

contract VestingTokenSale is MintableSale, TokenVesting {
    using SafeMath for uint256;
    uint256 public fundingGoal;
    uint256 public tokensPerEther;
    uint public deadline;
    address public multiSigWallet;
    uint256 public amountRaised;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    address public creator;
    address public addressOfTokenUsedAsReward;
    bool public isFunding = false;

    /* accredited investors */
    mapping (address => uint256) public accredited;

    event FundTransfer(address backer, uint amount);

    uint256 constant public   VESTING_DURATION    =  31536000; // 1 Year in second
    uint256 constant public   CLIFF_DURATION      =   2592000; // 1 months (30 days) in second

    /* Constrctor function */
    function VestingTokenSale(
        address _addressOfTokenUsedAsReward
    ) payable {
        creator = msg.sender;
        multiSigWallet = 0x9581973c54fce63d0f5c4c706020028af20ff723;
        // Token Contract
        addressOfTokenUsedAsReward = _addressOfTokenUsedAsReward;
        tokenReward = Token(addressOfTokenUsedAsReward);
        // Setup accredited investors
        setupAccreditedAddress(0xec7210E3db72651Ca21DA35309A20561a6F374dd, 1000);
    }

    // @dev Start a new mintable sale.
    // @param rate The exchange rate in ether, for example 1 ETH = 6400 FLC
    // @param fundingGoalInEthers
    // @param durationInMinutes
    function createMintableSale(uint256 rate, uint256 fundingGoalInEthers, uint durationInMinutes) external returns (bool success) {
        require(msg.sender == creator);
        require(isFunding == false);
        require(rate <= 6400 && rate >= 1);                   // rate must be between 1 and 6400
        require(fundingGoalInEthers >= 1000);        
        require(durationInMinutes >= 60 minutes);

        deadline = now + durationInMinutes * 1 minutes;
        fundingGoal = amountRaised + fundingGoalInEthers * 1 ether;
        tokensPerEther = rate;
        isFunding = true;
        return true;    
    }

    modifier afterDeadline() { if (now > deadline) _; }
    modifier beforeDeadline() { if (now <= deadline) _; }

    /// @param _accredited The address of the accredited investor
    /// @param _amountInEthers The amount of remaining ethers allowed to invested
    /// @return Amount of remaining tokens allowed to spent
    function setupAccreditedAddress(address _accredited, uint _amountInEthers) public returns (bool success) {
        require(msg.sender == creator);    
        accredited[_accredited] = _amountInEthers * 1 ether;
        return true;
    }

    /// @dev This function returns the amount of remaining ethers allowed to invested
    /// @return The amount
    function getAmountAccredited(address _accredited) view returns (uint256) {
        uint256 amount = accredited[_accredited];
        return amount;
    }

    function closeSale() beforeDeadline {
        require(msg.sender == creator);    
        isFunding = false;
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender == creator);
        creator = _creator;
    }

    /// @dev This function returns the current exchange rate during the sale
    /// @return The address of token creator
    function getRate() beforeDeadline view returns (uint) {
        return tokensPerEther;
    }

    /// @dev This function returns the amount raised in wei
    /// @return The address of token creator
    function getAmountRaised() view returns (uint) {
        return amountRaised;
    }

    function () payable {
        // check if we can offer the private sale
        require(isFunding == true && amountRaised < fundingGoal);

        // the minimum deposit is 1 ETH
        uint256 amount = msg.value;        
        require(amount >= 1 ether);

        require(accredited[msg.sender] - amount >= 0); 

        multiSigWallet.transfer(amount);      
        balanceOf[msg.sender] += amount;
        accredited[msg.sender] -= amount;
        amountRaised += amount;
        FundTransfer(msg.sender, amount);

        // total releasable tokens
        uint256 value = amount.mul(tokensPerEther);

        // the beneficiary
        address currentBeneficiary = address(this);
        
        // Mint tokens and keep it in the contract
        tokenReward.mintToken(currentBeneficiary, value);

        // Create a vest
        uint256 start;
        uint256 cliffDuration = CLIFF_DURATION;
        uint256 vestingDuration = VESTING_DURATION;

        createVesting(msg.sender, start, cliffDuration, vestingDuration, addressOfTokenUsedAsReward);
    }   
}