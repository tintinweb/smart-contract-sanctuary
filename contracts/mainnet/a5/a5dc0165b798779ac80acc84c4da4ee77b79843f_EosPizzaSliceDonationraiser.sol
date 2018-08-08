pragma solidity ^0.4.18;

/**
*
*    I  N    P  I  Z  Z  A     W  E     C  R  U  S  T
*  
*    ______ ____   _____       _____ _
*   |  ____/ __ \ / ____|     |  __ (_)
*   | |__ | |  | | (___       | |__) | __________ _
*   |  __|| |  | |\___ \      |  ___/ |_  /_  / _` |
*   | |___| |__| |____) |  _  | |   | |/ / / / (_| |
*   |______\____/|_____/  (_) |_|   |_/___/___\__,_|
*
*
*
*   CHECK HTTPS://EOS.PIZZA ON HOW TO GET YOUR SLICE
*   END: 18 MAY 2018
*
*   This is for the fun. Thank you token factory for your smart contract inspiration.
*   Jummy & crusty. Get your &#127829;EPS while it&#39;s hot. 
*
*   https://eos.pizza
*
*
**/

// File: contracts\configs\EosPizzaSliceConfig.sol


/**
 * @title EosPizzaSliceConfig
 *
 * @dev The static configuration for the EOS Pizza Slice.
 */
contract EosPizzaSliceConfig {
    // The name of the token.
    string constant NAME = "EOS.Pizza";

    // The symbol of the token.
    string constant SYMBOL = "EPS";

    // The number of decimals for the token.
    uint8 constant DECIMALS = 18;  // Same as ethers.

    // Decimal factor for multiplication purposes.
    uint constant DECIMALS_FACTOR = 10 ** uint(DECIMALS);
}

// File: contracts\interfaces\ERC20TokenInterface.sol

/**
 * @dev The standard ERC20 Token interface.
 */
contract ERC20TokenInterface {
    uint public totalSupply;  /* shorthand for public function and a property */
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

}

// File: contracts\libraries\SafeMath.sol

/**
 * @dev Library that helps prevent integer overflows and underflows,
 * inspired by https://github.com/OpenZeppelin/zeppelin-solidity
 */
library SafeMath {
    function plus(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);

        return c;
    }

    function minus(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);

        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;

        return c;
    }
}

// File: contracts\traits\ERC20Token.sol

/**
 * @title ERC20Token
 *
 * @dev Implements the operations declared in the `ERC20TokenInterface`.
 */
contract ERC20Token is ERC20TokenInterface {
    using SafeMath for uint;

    // Token account balances.
    mapping (address => uint) balances;

    // Delegated number of tokens to transfer.
    mapping (address => mapping (address => uint)) allowed;



    /**
     * @dev Checks the balance of a certain address.
     *
     * @param _account The address which&#39;s balance will be checked.
     *
     * @return Returns the balance of the `_account` address.
     */
    function balanceOf(address _account) public constant returns (uint balance) {
        return balances[_account];
    }

    /**
     * @dev Transfers tokens from one address to another.
     *
     * @param _to The target address to which the `_value` number of tokens will be sent.
     * @param _value The number of tokens to send.
     *
     * @return Whether the transfer was successful or not.
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        if (balances[msg.sender] < _value || _value == 0) {

            return false;
        }

        balances[msg.sender] -= _value;
        balances[_to] = balances[_to].plus(_value);


        Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Send `_value` tokens to `_to` from `_from` if `_from` has approved the process.
     *
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _value The number of tokens to be transferred.
     *
     * @return Whether the transfer was successful or not.
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value || _value == 0) {
            return false;
        }

        balances[_to] = balances[_to].plus(_value);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;


        Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Allows another contract to spend some tokens on your behalf.
     *
     * @param _spender The address of the account which will be approved for transfer of tokens.
     * @param _value The number of tokens to be approved for transfer.
     *
     * @return Whether the approval was successful or not.
     */
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev Shows the number of tokens approved by `_owner` that are allowed to be transferred by `_spender`.
     *
     * @param _owner The account which allowed the transfer.
     * @param _spender The account which will spend the tokens.
     *
     * @return The number of tokens to be transferred.
     */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

// File: contracts\traits\HasOwner.sol

/**
 * @title HasOwner
 *
 * @dev Allows for exclusive access to certain functionality.
 */
contract HasOwner {
    // Current owner.
    address public owner;

    // Conditionally the new owner.
    address public newOwner;

    /**
     * @dev The constructor.
     *
     * @param _owner The address of the owner.
     */
    function HasOwner(address _owner) internal {
        owner = _owner;
    }

    /**
     * @dev Access control modifier that allows only the current owner to call the function.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev The event is fired when the current owner is changed.
     *
     * @param _oldOwner The address of the previous owner.
     * @param _newOwner The address of the new owner.
     */
    event OwnershipTransfer(address indexed _oldOwner, address indexed _newOwner);

    /**
     * @dev Transfering the ownership is a two-step process, as we prepare
     * for the transfer by setting `newOwner` and requiring `newOwner` to accept
     * the transfer. This prevents accidental lock-out if something goes wrong
     * when passing the `newOwner` address.
     *
     * @param _newOwner The address of the proposed new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /**
     * @dev The `newOwner` finishes the ownership transfer process by accepting the
     * ownership.
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner);

        OwnershipTransfer(owner, newOwner);

        owner = newOwner;
    }
}

// File: contracts\traits\Freezable.sol

/**
 * @title Freezable
 * @dev This trait allows to freeze the transactions in a Token
 */
contract Freezable is HasOwner {
  bool public frozen = false;

  /**
   * @dev Modifier makes methods callable only when the contract is not frozen.
   */
  modifier requireNotFrozen() {
    require(!frozen);
    _;
  }

  /**
   * @dev Allows the owner to "freeze" the contract.
   */
  function freeze() onlyOwner public {
    frozen = true;
  }

  /**
   * @dev Allows the owner to "unfreeze" the contract.
   */
  function unfreeze() onlyOwner public {
    frozen = false;
  }
}

// File: contracts\traits\FreezableERC20Token.sol

/**
 * @title FreezableERC20Token
 *
 * @dev Extends ERC20Token and adds ability to freeze all transfers of tokens.
 */
contract FreezableERC20Token is ERC20Token, Freezable {
    /**
     * @dev Overrides the original ERC20Token implementation by adding whenNotFrozen modifier.
     *
     * @param _to The target address to which the `_value` number of tokens will be sent.
     * @param _value The number of tokens to send.
     *
     * @return Whether the transfer was successful or not.
     */
    function transfer(address _to, uint _value) public requireNotFrozen returns (bool success) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Send `_value` tokens to `_to` from `_from` if `_from` has approved the process.
     *
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _value The number of tokens to be transferred.
     *
     * @return Whether the transfer was successful or not.
     */
    function transferFrom(address _from, address _to, uint _value) public requireNotFrozen returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Allows another contract to spend some tokens on your behalf.
     *
     * @param _spender The address of the account which will be approved for transfer of tokens.
     * @param _value The number of tokens to be approved for transfer.
     *
     * @return Whether the approval was successful or not.
     */
    function approve(address _spender, uint _value) public requireNotFrozen returns (bool success) {
        return super.approve(_spender, _value);
    }

}

// File: contracts\EosPizzaSlice.sol

/**
 * @title EOS Pizza Slice
 *
 * @dev A standard token implementation of the ERC20 token standard with added
 *      HasOwner trait and initialized using the configuration constants.
 */
contract EosPizzaSlice is EosPizzaSliceConfig, HasOwner, FreezableERC20Token {
    // The name of the token.
    string public name;

    // The symbol for the token.
    string public symbol;

    // The decimals of the token.
    uint8 public decimals;

    /**
     * @dev The constructor. Initially sets `totalSupply` and the balance of the
     *      `owner` address according to the initialization parameter.
     */
    function EosPizzaSlice(uint _totalSupply) public
        HasOwner(msg.sender)
    {
        name = NAME;
        symbol = SYMBOL;
        decimals = DECIMALS;
        totalSupply = _totalSupply;
        balances[owner] = _totalSupply;
    }
}

// File: contracts\configs\EosPizzaSliceDonationraiserConfig.sol

/**
 * @title EosPizzaSliceDonationraiserConfig
 *
 * @dev The static configuration for the EOS Pizza Slice donationraiser.
 */
contract EosPizzaSliceDonationraiserConfig is EosPizzaSliceConfig {
    // The number of &#127829; per 1 ETH.
    uint constant CONVERSION_RATE = 100000;

    // The public sale hard cap of the donationraiser.
    uint constant TOKENS_HARD_CAP = 95 * (10**7) * DECIMALS_FACTOR;

    // The start date of the donationraiser: Friday, 9 March 2018 21:22:22 UTC.
    uint constant START_DATE = 1520630542;

    // The end date of the donationraiser:  May 18, 2018, 12:35:20 AM UTC - Bitcoin Pizza 8th year celebration moment.
    uint constant END_DATE =  1526603720;


    // Total number of tokens locked for the &#127829; core team.
    uint constant TOKENS_LOCKED_CORE_TEAM = 35 * (10**6) * DECIMALS_FACTOR;

    // Total number of tokens locked for &#127829; advisors.
    uint constant TOKENS_LOCKED_ADVISORS = 125 * (10**5) * DECIMALS_FACTOR;

    // The release date for tokens locked for the &#127829; core team.
    uint constant TOKENS_LOCKED_CORE_TEAM_RELEASE_DATE = END_DATE + 1 days;

    // The release date for tokens locked for &#127829; advisors.
    uint constant TOKENS_LOCKED_ADVISORS_RELEASE_DATE = END_DATE + 1 days;

    // Total number of tokens locked for bounty program.
    uint constant TOKENS_BOUNTY_PROGRAM = 25 * (10**5) * DECIMALS_FACTOR;

    // Maximum gas price limit
    uint constant MAX_GAS_PRICE = 90000000000 wei; // 90 gwei/shanon

    // Minimum individual contribution
    uint constant MIN_CONTRIBUTION =  0.05 ether;

    // Individual limit in ether
    uint constant INDIVIDUAL_ETHER_LIMIT =  4999 ether;
}

// File: contracts\traits\TokenSafe.sol

/**
 * @title TokenSafe
 *
 * @dev A multi-bundle token safe contract that contains locked tokens released after a date for the specific bundle type.
 */
contract TokenSafe {
    using SafeMath for uint;

    struct AccountsBundle {
        // The total number of tokens locked.
        uint lockedTokens;
        // The release date for the locked tokens
        // Note: Unix timestamp fits uint32, however block.timestamp is uint
        uint releaseDate;
        // The balances for the &#127829; locked token accounts.
        mapping (address => uint) balances;
    }

    // The account bundles of locked tokens grouped by release date
    mapping (uint8 => AccountsBundle) public bundles;

    // The `ERC20TokenInterface` contract.
    ERC20TokenInterface token;

    /**
     * @dev The constructor.
     *
     * @param _token The address of the EOS Pizza Slices (donation) contract.
     */
    function TokenSafe(address _token) public {
        token = ERC20TokenInterface(_token);
    }

    /**
     * @dev The function initializes the bundle of accounts with a release date.
     *
     * @param _type Bundle type.
     * @param _releaseDate Unix timestamp of the time after which the tokens can be released
     */
    function initBundle(uint8 _type, uint _releaseDate) internal {
        bundles[_type].releaseDate = _releaseDate;
    }

    /**
     * @dev Add new account with locked token balance to the specified bundle type.
     *
     * @param _type Bundle type.
     * @param _account The address of the account to be added.
     * @param _balance The number of tokens to be locked.
     */
    function addLockedAccount(uint8 _type, address _account, uint _balance) internal {
        var bundle = bundles[_type];
        bundle.balances[_account] = bundle.balances[_account].plus(_balance);
        bundle.lockedTokens = bundle.lockedTokens.plus(_balance);
    }

    /**
     * @dev Allows an account to be released if it meets the time constraints.
     *
     * @param _type Bundle type.
     * @param _account The address of the account to be released.
     */
    function releaseAccount(uint8 _type, address _account) internal {
        var bundle = bundles[_type];
        require(now >= bundle.releaseDate);
        uint tokens = bundle.balances[_account];
        require(tokens > 0);
        bundle.balances[_account] = 0;
        bundle.lockedTokens = bundle.lockedTokens.minus(tokens);
        if (!token.transfer(_account, tokens)) {
            revert();
        }
    }
}

// File: contracts\EosPizzaSliceSafe.sol

/**
 * @title EosPizzaSliceSafe
 *
 * @dev The EOS Pizza Slice safe containing all details about locked tokens.
 */
contract EosPizzaSliceSafe is TokenSafe, EosPizzaSliceDonationraiserConfig {
    // Bundle type constants
    uint8 constant CORE_TEAM = 0;
    uint8 constant ADVISORS = 1;

    /**
     * @dev The constructor.
     *
     * @param _token The address of the EOS Pizza (donation) contract.
     */
    function EosPizzaSliceSafe(address _token) public
        TokenSafe(_token)
    {
        token = ERC20TokenInterface(_token);

        /// Core team.
        initBundle(CORE_TEAM,
            TOKENS_LOCKED_CORE_TEAM_RELEASE_DATE
        );

        // Accounts with tokens locked for the &#127829; core team.
        addLockedAccount(CORE_TEAM, 0x3ce215b2e4dC9D2ba0e2fC5099315E4Fa05d8AA2, 35 * (10**6) * DECIMALS_FACTOR);


        // Verify that the tokens add up to the constant in the configuration.
        assert(bundles[CORE_TEAM].lockedTokens == TOKENS_LOCKED_CORE_TEAM);

        /// Advisors.
        initBundle(ADVISORS,
            TOKENS_LOCKED_ADVISORS_RELEASE_DATE
        );

        // Accounts with &#127829; tokens locked for advisors.
        addLockedAccount(ADVISORS, 0xC0e321E9305c21b72F5Ee752A9E8D9eCD0f2e2b1, 25 * (10**5) * DECIMALS_FACTOR);
        addLockedAccount(ADVISORS, 0x55798CF234FEa760b0591537517C976FDb0c53Ba, 25 * (10**5) * DECIMALS_FACTOR);
        addLockedAccount(ADVISORS, 0xbc732e73B94A5C4a8f60d0D98C4026dF21D500f5, 25 * (10**5) * DECIMALS_FACTOR);
        addLockedAccount(ADVISORS, 0x088EEEe7C4c26041FBb4e83C10CB0784C81c86f9, 25 * (10**5) * DECIMALS_FACTOR);
        addLockedAccount(ADVISORS, 0x52d640c9c417D9b7E3770d960946Dd5Bd2EB63db, 25 * (10**5) * DECIMALS_FACTOR);


        // Verify that the tokens add up to the constant in the configuration.
        assert(bundles[ADVISORS].lockedTokens == TOKENS_LOCKED_ADVISORS);
    }

    /**
     * @dev Returns the total locked tokens. This function is called by the donationraiser to determine number of tokens to create upon finalization.
     *
     * @return The current total number of locked EOS Pizza Slices.
     */
    function totalTokensLocked() public constant returns (uint) {
        return bundles[CORE_TEAM].lockedTokens.plus(bundles[ADVISORS].lockedTokens);
    }

    /**
     * @dev Allows core team account &#127829; tokens to be released.
     */
    function releaseCoreTeamAccount() public {
        releaseAccount(CORE_TEAM, msg.sender);
    }

    /**
     * @dev Allows advisors account &#127829; tokens to be released.
     */
    function releaseAdvisorsAccount() public {
        releaseAccount(ADVISORS, msg.sender);
    }
}

// File: contracts\traits\Whitelist.sol

contract Whitelist is HasOwner
{
    // Whitelist mapping
    mapping(address => bool) public whitelist;

    /**
     * @dev The constructor.
     */
    function Whitelist(address _owner) public
        HasOwner(_owner)
    {

    }

    /**
     * @dev Access control modifier that allows only whitelisted address to call the method.
     */
    modifier onlyWhitelisted {
        require(whitelist[msg.sender]);
        _;
    }

    /**
     * @dev Internal function that sets whitelist status in batch.
     *
     * @param _entries An array with the entries to be updated
     * @param _status The new status to apply
     */
    function setWhitelistEntries(address[] _entries, bool _status) internal {
        for (uint32 i = 0; i < _entries.length; ++i) {
            whitelist[_entries[i]] = _status;
        }
    }

    /**
     * @dev Public function that allows the owner to whitelist multiple entries
     *
     * @param _entries An array with the entries to be whitelisted
     */
    function whitelistAddresses(address[] _entries) public onlyOwner {
        setWhitelistEntries(_entries, true);
    }

    /**
     * @dev Public function that allows the owner to blacklist multiple entries
     *
     * @param _entries An array with the entries to be blacklist
     */
    function blacklistAddresses(address[] _entries) public onlyOwner {
        setWhitelistEntries(_entries, false);
    }
}

// File: contracts\EosPizzaSliceDonationraiser.sol

/**
 * @title EosPizzaSliceDonationraiser
 *
 * @dev The EOS Pizza Slice donationraiser contract.
 */
contract EosPizzaSliceDonationraiser is EosPizzaSlice, EosPizzaSliceDonationraiserConfig, Whitelist {
    // Indicates whether the donationraiser has ended or not.
    bool public finalized = false;

    // The address of the account which will receive the funds gathered by the donationraiser.
    address public beneficiary;

    // The number of &#127829; participants will receive per 1 ETH.
    uint public conversionRate;

    // Donationraiser start date.
    uint public startDate;

    // Donationraiser end date.
    uint public endDate;

    // Donationraiser tokens hard cap.
    uint public hardCap;

    // The `EosPizzaSliceSafe` contract.
    EosPizzaSliceSafe public eosPizzaSliceSafe;

    // The minimum amount of ether allowed in the public sale
    uint internal minimumContribution;

    // The maximum amount of ether allowed per address
    uint internal individualLimit;

    // Number of tokens sold during the donationraiser.
    uint private tokensSold;



    /**
     * @dev The event fires every time a new buyer enters the donationraiser.
     *
     * @param _address The address of the buyer.
     * @param _ethers The number of ethers sent.
     * @param _tokens The number of tokens received by the buyer.
     * @param _newTotalSupply The updated total number of tokens currently in circulation.
     * @param _conversionRate The conversion rate at which the tokens were bought.
     */
    event FundsReceived(address indexed _address, uint _ethers, uint _tokens, uint _newTotalSupply, uint _conversionRate);

    /**
     * @dev The event fires when the beneficiary of the donationraiser is changed.
     *
     * @param _beneficiary The address of the new beneficiary.
     */
    event BeneficiaryChange(address _beneficiary);

    /**
     * @dev The event fires when the number of &#127829;EPS per 1 ETH is changed.
     *
     * @param _conversionRate The new number of &#127829;EPS per 1 ETH.
     */
    event ConversionRateChange(uint _conversionRate);

    /**
     * @dev The event fires when the donationraiser is successfully finalized.
     *
     * @param _beneficiary The address of the beneficiary.
     * @param _ethers The number of ethers transfered to the beneficiary.
     * @param _totalSupply The total number of tokens in circulation.
     */
    event Finalized(address _beneficiary, uint _ethers, uint _totalSupply);

    /**
     * @dev The constructor.
     *
     * @param _beneficiary The address which will receive the funds gathered by the donationraiser.
     */
    function EosPizzaSliceDonationraiser(address _beneficiary) public
        EosPizzaSlice(0)
        Whitelist(msg.sender)
    {
        require(_beneficiary != 0);

        beneficiary = _beneficiary;
        conversionRate = CONVERSION_RATE;
        startDate = START_DATE;
        endDate = END_DATE;
        hardCap = TOKENS_HARD_CAP;
        tokensSold = 0;
        minimumContribution = MIN_CONTRIBUTION;
        individualLimit = INDIVIDUAL_ETHER_LIMIT * CONVERSION_RATE;

        eosPizzaSliceSafe = new EosPizzaSliceSafe(this);

        // Freeze the transfers for the duration of the donationraiser. Removed this, you can immediately transfer your &#127829;EPS to any ether address you like!
        // freeze();
    }

    /**
     * @dev Changes the beneficiary of the donationraiser.
     *
     * @param _beneficiary The address of the new beneficiary.
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != 0);

        beneficiary = _beneficiary;

        BeneficiaryChange(_beneficiary);
    }

    /**
     * @dev Sets converstion rate of 1 ETH to &#127829;EPS. Can only be changed before the donationraiser starts.
     *
     * @param _conversionRate The new number of EOS Pizza Slices per 1 ETH.
     */
    function setConversionRate(uint _conversionRate) public onlyOwner {
        require(now < startDate);
        require(_conversionRate > 0);

        conversionRate = _conversionRate;
        individualLimit = INDIVIDUAL_ETHER_LIMIT * _conversionRate;

        ConversionRateChange(_conversionRate);
    }



    /**
     * @dev The default function which will fire every time someone sends ethers to this contract&#39;s address.
     */
    function() public payable {
        buyTokens();
    }

    /**
     * @dev Creates new tokens based on the number of ethers sent and the conversion rate.
     */
    //function buyTokens() public payable onlyWhitelisted {
    function buyTokens() public payable {
        require(!finalized);
        require(now >= startDate);
        require(now <= endDate);
        require(tx.gasprice <= MAX_GAS_PRICE);  // gas price limit
        require(msg.value >= minimumContribution);  // required minimum contribution
        require(tokensSold <= hardCap);

        // Calculate the number of tokens the buyer will receive.
        uint tokens = msg.value.mul(conversionRate);
        balances[msg.sender] = balances[msg.sender].plus(tokens);

        // Ensure that the individual contribution limit has not been reached
        require(balances[msg.sender] <= individualLimit);



        tokensSold = tokensSold.plus(tokens);
        totalSupply = totalSupply.plus(tokens);

        Transfer(0x0, msg.sender, tokens);

        FundsReceived(
            msg.sender,
            msg.value,
            tokens,
            totalSupply,
            conversionRate
        );
    }



    /**
     * @dev Finalize the donationraiser if `endDate` has passed or if `hardCap` is reached.
     */
    function finalize() public onlyOwner {
        require((totalSupply >= hardCap) || (now >= endDate));
        require(!finalized);

        address contractAddress = this;
        Finalized(beneficiary, contractAddress.balance, totalSupply);

        /// Send the total number of ETH gathered to the beneficiary.
        beneficiary.transfer(contractAddress.balance);

        /// Allocate locked tokens to the `EosPizzaSliceSafe` contract.
        uint totalTokensLocked = eosPizzaSliceSafe.totalTokensLocked();
        balances[address(eosPizzaSliceSafe)] = balances[address(eosPizzaSliceSafe)].plus(totalTokensLocked);
        totalSupply = totalSupply.plus(totalTokensLocked);

        // Transfer the funds for the bounty program.
        balances[owner] = balances[owner].plus(TOKENS_BOUNTY_PROGRAM);
        totalSupply = totalSupply.plus(TOKENS_BOUNTY_PROGRAM);

        /// Finalize the donationraiser. Keep in mind that this cannot be undone.
        finalized = true;

        // Unfreeze transfers
        unfreeze();
    }

    /**
     * @dev allow owner to collect balance of contract during donation period
     */

    function collect() public onlyOwner {

        address contractAddress = this;
        /// Send the total number of ETH gathered to the beneficiary.
        beneficiary.transfer(contractAddress.balance);

    }
}