pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Return true if sender is owner or super-owner of the contract
    function isOwner() internal view returns(bool success) {
        if (msg.sender == owner) return true;
        return false;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].safeAdd(_value);
        balances[_from] = balances[_from].safeSub(_value);
        allowed[_from][msg.sender] = _allowance.safeSub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].safeAdd(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.safeSub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/**
 * @title ENTA is Standard ERC20 token
 */
contract ENTA is StandardToken,Owned {

    string public name = "ENTA";
    string public symbol = "ENTA";
    uint256 public decimals = 8;
    uint256 public INITIAL_SUPPLY = 2000000000 * (10 ** decimals); // Two billion
    uint256 public publicSell = 1530374400;//2018-07-01

    bool public allowTransfers = true; // if true then allow coin transfers
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address indexed target, bool frozen);
    event MinedBalancesUnlocked(address indexed target, uint256 amount);

    struct MinedBalance {
        uint256 total;
        uint256 left;
    }

    mapping(address => MinedBalance) minedBalances;

    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transferMined(address to, uint256 tokens) public onlyOwner returns (bool success) {
        balances[msg.sender] = balances[msg.sender].safeSub(tokens);
        minedBalances[to].total = minedBalances[to].total.safeAdd(tokens);
        minedBalances[to].left = minedBalances[to].left.safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // - @dev override
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[msg.sender]);                                        // Check if sender is frozen
            require(!frozenAccount[to]);                                               // Check if recipient is frozen
        }
        
        if (now >= publicSell) {
            uint256 month = (now-publicSell)/(30 days);
            if(month>=7){
                unlockMinedBalances(100);
            } else if(month>=6){
                unlockMinedBalances(90);
            } else if(month>=3){
                unlockMinedBalances(80);
            } else if(month>=2){
                unlockMinedBalances(60);
            } else if(month>=1){
                unlockMinedBalances(40);
            } else if(month>=0){
                unlockMinedBalances(20);
            }
        }
        return super.transfer(to,tokens);
    }

    function unlockMinedBalances(uint256 unlockPercent) internal {
        uint256 lockedMinedTokens = minedBalances[msg.sender].total*(100-unlockPercent)/100;
        if(minedBalances[msg.sender].left > lockedMinedTokens){
            uint256 unlock = minedBalances[msg.sender].left.safeSub(lockedMinedTokens);
            minedBalances[msg.sender].left = lockedMinedTokens;
            balances[msg.sender] = balances[msg.sender].safeAdd(unlock);
            emit MinedBalancesUnlocked(msg.sender,unlock);
        }
    }

    function setAllowTransfers(bool _allowTransfers) onlyOwner public {
        allowTransfers = _allowTransfers;
    }

    function destroyToken(address target, uint256 amount) onlyOwner public {
        balances[target] = balances[target].safeSub(amount);
        totalSupply = totalSupply.safeSub(amount);
        emit Transfer(target, this, amount);
        emit Transfer(this, 0, amount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    // @dev override
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[_from]);                                          // Check if sender is frozen
            require(!frozenAccount[_to]);                                            // Check if recipient is frozen
        }
        return super.transferFrom(_from, _to, _value);
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner].safeAdd(minedBalances[tokenOwner].left);
    }
}