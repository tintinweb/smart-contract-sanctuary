pragma solidity 0.4.18;

/**
 * @title ReceivingContract Interface
 * @dev ReceivingContract handle incoming token transfers.
 */
contract ReceivingContract {

    /**
     * @dev Handle incoming token transfers.
     * @param _from The token sender address.
     * @param _value The amount of tokens.
     */
    function tokenFallback(address _from, uint _value) public;

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        if (_a == 0) {
            return 0;
        }
    
        uint c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        // Solidity automatically throws when dividing by 0
        uint c = _a / _b;
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        uint c = _a + _b;
        assert(c >= _a);
        return c;
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

    /**
     * Events
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Constructor
     * Sets the original `owner` of the contract to the sender account.
     */
    function Ownable() public {
        owner = msg.sender;
        OwnershipTransferred(0, owner);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner)
        public
        onlyOwner
    {
        require(_newOwner != 0);

        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

/**
 * @title Standard ERC20 token
 */
contract StandardToken is Ownable {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) internal allowed;

    /**
     * Events
     */
    event ChangeTokenInformation(string name, string symbol);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * Owner can update token information here.
     *
     * It is often useful to conceal the actual token association, until
     * the token operations, like central issuance or reissuance have been completed.
     *
     * This function allows the token owner to rename the token after the operations
     * have been completed and then point the audience to use the token contract.
     */
    function changeTokenInformation(string _name, string _symbol)
        public
        onlyOwner
    {
        name = _name;
        symbol = _symbol;
        ChangeTokenInformation(_name, _symbol);
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value)
        public
        returns (bool)
    {
        require(_to != 0);
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _value The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(_to != 0);
        require(_value > 0);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     *
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue)
        public
        returns (bool)
    {
        require(_addedValue > 0);

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     *
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        returns (bool)
    {
        require(_subtractedValue > 0);

        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;

        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner The address which owns the funds.
     * @param _spender The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

}

/**
 * @title Pausable token
 * @dev Token that can be freeze "Transfer" function
 */
contract PausableToken is StandardToken {

    bool public isTradable = true;

    /**
     * Events
     */
    event FreezeTransfer();
    event UnfreezeTransfer();

    modifier canTransfer() {
        require(isTradable);
        _;
    }

    /**
     * Disallow to transfer token from an address to other address
     */
    function freezeTransfer()
        public
        onlyOwner
    {
        isTradable = false;
        FreezeTransfer();
    }

    /**
     * Allow to transfer token from an address to other address
     */
    function unfreezeTransfer()
        public
        onlyOwner
    {
        isTradable = true;
        UnfreezeTransfer();
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value)
        public
        canTransfer
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _value The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value)
        public
        canTransfer
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value)
        public
        canTransfer
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     *
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue)
        public
        canTransfer
        returns (bool)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     *
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        canTransfer
        returns (bool)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

/**
 * @title UpgradeAgent Interface
 * @dev Upgrade agent transfers tokens to a new contract. Upgrade agent itself can be the
 * token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {

    bool public isUpgradeAgent = true;

    function upgradeFrom(address _from, uint _value) public;

}

/**
 * @title Upgradable token
 */
contract UpgradableToken is StandardToken {

    address public upgradeMaster;

    // The next contract where the tokens will be migrated.
    UpgradeAgent public upgradeAgent;

    bool public isUpgradable = false;

    // How many tokens we have upgraded by now.
    uint public totalUpgraded;

    /**
     * Events
     */
    event ChangeUpgradeMaster(address newMaster);
    event ChangeUpgradeAgent(address newAgent);
    event FreezeUpgrade();
    event UnfreezeUpgrade();
    event Upgrade(address indexed from, address indexed to, uint value);

    modifier onlyUpgradeMaster() {
        require(msg.sender == upgradeMaster);
        _;
    }

    modifier canUpgrade() {
        require(isUpgradable);
        _;
    }

    /**
     * Change the upgrade master.
     * @param _newMaster New upgrade master.
     */
    function changeUpgradeMaster(address _newMaster)
        public
        onlyOwner
    {
        require(_newMaster != 0);

        upgradeMaster = _newMaster;
        ChangeUpgradeMaster(_newMaster);
    }

    /**
     * Change the upgrade agent.
     * @param _newAgent New upgrade agent.
     */
    function changeUpgradeAgent(address _newAgent)
        public
        onlyOwner
    {
        require(totalUpgraded == 0);

        upgradeAgent = UpgradeAgent(_newAgent);

        require(upgradeAgent.isUpgradeAgent());

        ChangeUpgradeAgent(_newAgent);
    }

    /**
     * Disallow to upgrade token to new smart contract
     */
    function freezeUpgrade()
        public
        onlyOwner
    {
        isUpgradable = false;
        FreezeUpgrade();
    }

    /**
     * Allow to upgrade token to new smart contract
     */
    function unfreezeUpgrade()
        public
        onlyOwner
    {
        isUpgradable = true;
        UnfreezeUpgrade();
    }

    /**
     * Token holder upgrade their tokens to a new smart contract.
     */
    function upgrade()
        public
        canUpgrade
    {
        uint amount = balanceOf[msg.sender];

        require(amount > 0);

        processUpgrade(msg.sender, amount);
    }

    /**
     * Upgrader upgrade tokens of holder to a new smart contract.
     * @param _holders List of token holder.
     */
    function forceUpgrade(address[] _holders)
        public
        onlyUpgradeMaster
        canUpgrade
    {
        uint amount;

        for (uint i = 0; i < _holders.length; i++) {
            amount = balanceOf[_holders[i]];

            if (amount == 0) {
                continue;
            }

            processUpgrade(_holders[i], amount);
        }
    }

    function processUpgrade(address _holder, uint _amount)
        private
    {
        balanceOf[_holder] = balanceOf[_holder].sub(_amount);

        // Take tokens out from circulation
        totalSupply = totalSupply.sub(_amount);
        totalUpgraded = totalUpgraded.add(_amount);

        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(_holder, _amount);
        Upgrade(_holder, upgradeAgent, _amount);
    }

}

/**
 * @title QNTU 1.0 token
 */
contract QNTU is UpgradableToken, PausableToken {

    /**
     * @dev Constructor
     */
    function QNTU(address[] _wallets, uint[] _amount)
        public
    {
        require(_wallets.length == _amount.length);

        symbol = "QNTU";
        name = "QNTU Token";
        decimals = 18;

        uint num = 0;
        uint length = _wallets.length;
        uint multiplier = 10 ** uint(decimals);

        for (uint i = 0; i < length; i++) {
            num = _amount[i] * multiplier;

            balanceOf[_wallets[i]] = num;
            Transfer(0, _wallets[i], num);

            totalSupply += num;
        }
    }

    /**
     * @dev Transfer token for a specified contract
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transferToContract(address _to, uint _value)
        public
        canTransfer
        returns (bool)
    {
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        ReceivingContract receiver = ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

}