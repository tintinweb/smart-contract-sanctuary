pragma solidity ^0.4.13;

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    /// @notice Transfer ownership from `owner` to `newOwner`
    /// @param _newOwner The new contract owner
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }

    /// @notice accept ownership of the contract
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract LegolasBase is Ownable {

    mapping (address => uint256) public balances;

    // Initial amount received from the pre-sale (doesn&#39;t include bonus)
    mapping (address => uint256) public initialAllocations;
    // Initial amount received from the pre-sale (includes bonus)
    mapping (address => uint256) public allocations;
    // False if part of the allocated amount is spent
    mapping (uint256 => mapping(address => bool)) public eligibleForBonus;
    // unspent allocated amount by period
    mapping (uint256 => uint256) public unspentAmounts;
    // List of founders addresses
    mapping (address => bool) public founders;
    // List of advisors addresses
    mapping (address => bool) public advisors;

    // Release dates for adviors: one twelfth released each month.
    uint256[12] public ADVISORS_LOCK_DATES = [1521072000, 1523750400, 1526342400,
                                       1529020800, 1531612800, 1534291200,
                                       1536969600, 1539561600, 1542240000,
                                       1544832000, 1547510400, 1550188800];
    // Release dates for founders: After one year, one twelfth released each month.
    uint256[12] public FOUNDERS_LOCK_DATES = [1552608000, 1555286400, 1557878400,
                                       1560556800, 1563148800, 1565827200,
                                       1568505600, 1571097600, 1573776000,
                                       1576368000, 1579046400, 1581724800];

    // Bonus dates: each 6 months during 2 years
    uint256[4] public BONUS_DATES = [1534291200, 1550188800, 1565827200, 1581724800];

    /// @param _address The address from which the locked amount will be retrieved
    /// @return The amount locked for _address.
    function getLockedAmount(address _address) internal view returns (uint256 lockedAmount) {
        // Only founders and advisors have locks
        if (!advisors[_address] && !founders[_address]) return 0;
        // Determine release dates
        uint256[12] memory lockDates = advisors[_address] ? ADVISORS_LOCK_DATES : FOUNDERS_LOCK_DATES;
        // Determine how many twelfths are locked
        for (uint8 i = 11; i >= 0; i--) {
            if (now >= lockDates[i]) {
                return (allocations[_address] / 12) * (11 - i);
            }
        }
        return allocations[_address];
    }

    function updateBonusEligibity(address _from) internal {
        if (now < BONUS_DATES[3] &&
            initialAllocations[_from] > 0 &&
            balances[_from] < allocations[_from]) {
            for (uint8 i = 0; i < 4; i++) {
                if (now < BONUS_DATES[i] && eligibleForBonus[BONUS_DATES[i]][_from]) {
                    unspentAmounts[BONUS_DATES[i]] -= initialAllocations[_from];
                    eligibleForBonus[BONUS_DATES[i]][_from] = false;
                }
            }
        }
    }
}

contract EIP20 is EIP20Interface, LegolasBase {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => mapping (address => uint256)) public allowed;


    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        // Check locked amount
        require(balances[msg.sender] - _value >= getLockedAmount(msg.sender));
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Bonus lost if balance is lower than the original allocation
        updateBonusEligibity(msg.sender);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

        // Check locked amount
        require(balances[_from] - _value >= getLockedAmount(_from));

        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }

        // Bonus lost if balance is lower than the original allocation
        updateBonusEligibity(_from);

        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Legolas is EIP20 {

    // Standard ERC20 information
    string  constant NAME = "LGO Token";
    string  constant SYMBOL = "LGO";
    uint8   constant DECIMALS = 8;
    uint256 constant UNIT = 10**uint256(DECIMALS);

    uint256 constant onePercent = 181415052000000;

    // 5% for advisors
    uint256 constant ADVISORS_AMOUNT =   5 * onePercent;
    // 15% for founders
    uint256 constant FOUNDERS_AMOUNT =  15 * onePercent;
    // 60% sold in pre-sale
    uint256 constant HOLDERS_AMOUNT  =  60 * onePercent;
    // 20% reserve
    uint256 constant RESERVE_AMOUNT  =  20 * onePercent;
    // ADVISORS_AMOUNT + FOUNDERS_AMOUNT + HOLDERS_AMOUNT +RESERVE_AMOUNT
    uint256 constant INITIAL_AMOUNT  = 100 * onePercent;
    // 20% for holder bonus
    uint256 constant BONUS_AMOUNT    =  20 * onePercent;
    // amount already allocated to advisors
    uint256 public advisorsAllocatedAmount = 0;
    // amount already allocated to funders
    uint256 public foundersAllocatedAmount = 0;
    // amount already allocated to holders
    uint256 public holdersAllocatedAmount = 0;
    // list of all initial holders
    address[] initialHolders;
    // not distributed because the defaut value is false
    mapping (uint256 => mapping(address => bool)) bonusNotDistributed;

    event Allocate(address _address, uint256 _value);

    function Legolas() EIP20( // EIP20 constructor
        INITIAL_AMOUNT + BONUS_AMOUNT,
        NAME,
        DECIMALS,
        SYMBOL
    ) public {}

    /// @param _address The address of the recipient
    /// @param _amount Amount of the allocation
    /// @param _type Type of the recipient. 0 for advisor, 1 for founders.
    /// @return Whether the allocation was successful or not
    function allocate(address _address, uint256 _amount, uint8 _type) public onlyOwner returns (bool success) {
        // one allocations by address
        require(allocations[_address] == 0);

        if (_type == 0) { // advisor
            // check allocated amount
            require(advisorsAllocatedAmount + _amount <= ADVISORS_AMOUNT);
            // increase allocated amount
            advisorsAllocatedAmount += _amount;
            // mark address as advisor
            advisors[_address] = true;
        } else if (_type == 1) { // founder
            // check allocated amount
            require(foundersAllocatedAmount + _amount <= FOUNDERS_AMOUNT);
            // increase allocated amount
            foundersAllocatedAmount += _amount;
            // mark address as founder
            founders[_address] = true;
        } else {
            // check allocated amount
            require(holdersAllocatedAmount + _amount <= HOLDERS_AMOUNT + RESERVE_AMOUNT);
            // increase allocated amount
            holdersAllocatedAmount += _amount;
        }
        // set allocation
        allocations[_address] = _amount;
        initialAllocations[_address] = _amount;

        // increase balance
        balances[_address] += _amount;

        // update variables for bonus distribution
        for (uint8 i = 0; i < 4; i++) {
            // increase unspent amount
            unspentAmounts[BONUS_DATES[i]] += _amount;
            // initialize bonus eligibility
            eligibleForBonus[BONUS_DATES[i]][_address] = true;
            bonusNotDistributed[BONUS_DATES[i]][_address] = true;
        }

        // add to initial holders list
        initialHolders.push(_address);

        Allocate(_address, _amount);

        return true;
    }

    /// @param _address Holder address.
    /// @param _bonusDate Date of the bonus to distribute.
    /// @return Whether the bonus distribution was successful or not
    function claimBonus(address _address, uint256 _bonusDate) public returns (bool success) {
        /// bonus date must be past
        require(_bonusDate <= now);
        /// disrtibute bonus only once
        require(bonusNotDistributed[_bonusDate][_address]);
        /// disrtibute bonus only if eligible
        require(eligibleForBonus[_bonusDate][_address]);

        // calculate the bonus for one holded LGO
        uint256 bonusByLgo = (BONUS_AMOUNT / 4) / unspentAmounts[_bonusDate];

        // distribute the bonus
        uint256 holderBonus = initialAllocations[_address] * bonusByLgo;
        balances[_address] += holderBonus;
        allocations[_address] += holderBonus;

        // set bonus as distributed
        bonusNotDistributed[_bonusDate][_address] = false;
        return true;
    }
}