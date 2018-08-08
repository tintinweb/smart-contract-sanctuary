pragma solidity ^0.4.21;

// Project: alehub.io
// v11, 2018-07-17
// This code is the property of CryptoB2B.io
// Copying in whole or in part is prohibited.
// Authors: Ivan Fedorov and Dmitry Borodin
// Do you want the same TokenSale platform? www.cryptob2b.io

contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}

contract IFinancialStrategy{

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    event Deposited(address indexed beneficiary, uint256 weiAmount);
    event Receive(address indexed beneficiary, uint256 weiAmount);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Started();
    event Closed();
    event RefundsEnabled();
    function freeCash() view public returns(uint256);
    function deposit(address _beneficiary) external payable;
    function refund(address _investor) external;
    function setup(uint8 _state, bytes32[] _params) external;
    function getBeneficiaryCash() external;
    function getPartnerCash(uint8 _user, address _msgsender) external;
}

contract IAllocation {
    function addShare(address _beneficiary, uint256 _proportion, uint256 _percenForFirstPart) external;
}

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
    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b>=a) return 0;
        return a - b;
    }
}

contract GuidedByRoles {
    IRightAndRoles public rightAndRoles;
    function GuidedByRoles(IRightAndRoles _rightAndRoles) public {
        rightAndRoles = _rightAndRoles;
    }
}

contract Pausable is GuidedByRoles {

    mapping (address => bool) public unpausedWallet;

    event Pause();
    event Unpause();

    bool public paused = true;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused(address _to) {
        require(!paused||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        _;
    }

    function onlyAdmin() internal view {
        require(rightAndRoles.onlyRoles(msg.sender,3));
    }

    // Add a wallet ignoring the "Exchange pause". Available to the owner of the contract.
    function setUnpausedWallet(address _wallet, bool mode) public {
        onlyAdmin();
        unpausedWallet[_wallet] = mode;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function setPause(bool mode)  public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        if (!paused && mode) {
            paused = true;
            emit Pause();
        }else
        if (paused && !mode) {
            paused = false;
            emit Unpause();
        }
    }

}

contract IRightAndRoles {
    address[][] public wallets;
    mapping(address => uint16) public roles;

    event WalletChanged(address indexed newWallet, address indexed oldWallet, uint8 indexed role);
    event CloneChanged(address indexed wallet, uint8 indexed role, bool indexed mod);

    function changeWallet(address _wallet, uint8 _role) external;
    function setManagerPowerful(bool _mode) external;
    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool);
}

contract IToken{
    function setUnpausedWallet(address _wallet, bool mode) public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function totalSupply() public view returns (uint256);
    function setPause(bool mode) public;
    function setMigrationAgent(address _migrationAgent) public;
    function migrateAll(address[] _holders) public;
    function rejectTokens(address _beneficiary, uint256 _value) public;
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount);
    function defrostDate(address _beneficiary) public view returns (uint256 Date);
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public;
}

contract ICreator{
    IRightAndRoles public rightAndRoles;
    function createAllocation(IToken _token, uint256 _unlockPart1, uint256 _unlockPart2) external returns (IAllocation);
    function createFinancialStrategy() external returns(IFinancialStrategy);
    function getRightAndRoles() external returns(IRightAndRoles);
}

contract ERC20Provider is GuidedByRoles {
    function transferTokens(ERC20Basic _token, address _to, uint256 _value) public returns (bool){
        require(rightAndRoles.onlyRoles(msg.sender,2));
        return _token.transfer(_to,_value);
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
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

contract KycToken is BasicToken, GuidedByRoles {

    event TokensRejected(address indexed beneficiary, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function rejectTokens(address _beneficiary, uint256 _value) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(_value <= balances[_beneficiary]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_beneficiary] = balances[_beneficiary].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit TokensRejected(_beneficiary, _value);
        emit Transfer(_beneficiary, address(0), _value);
    }
}

contract MigratableToken is BasicToken,GuidedByRoles {

    uint256 public totalMigrated;
    address public migrationAgent;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    function setMigrationAgent(address _migrationAgent) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(totalMigrated == 0);
        migrationAgent = _migrationAgent;
    }


    function migrateInternal(address _holder) internal{
        require(migrationAgent != 0x0);

        uint256 value = balances[_holder];
        balances[_holder] = 0;

        totalSupply_ = totalSupply_.sub(value);
        totalMigrated = totalMigrated.add(value);

        MigrationAgent(migrationAgent).migrateFrom(_holder, value);
        emit Migrate(_holder,migrationAgent,value);
    }

    function migrateAll(address[] _holders) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        for(uint i = 0; i < _holders.length; i++){
            migrateInternal(_holders[i]);
        }
    }

    // Reissue your tokens.
    function migrate() public
    {
        require(balances[msg.sender] > 0);
        migrateInternal(msg.sender);
    }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract MintableToken is StandardToken, GuidedByRoles {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public returns (bool) {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}

contract FreezingToken is PausableToken {
    struct freeze {
    uint256 amount;
    uint256 when;
    }


    mapping (address => freeze) freezedTokens;

    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

    function defrostDate(address _beneficiary) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }

    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        freeze storage _freeze = freezedTokens[_beneficiary];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function masFreezedTokens(address[] _beneficiary, uint256[] _amount, uint256[] _when) public {
        onlyAdmin();
        require(_beneficiary.length == _amount.length && _beneficiary.length == _when.length);
        for(uint16 i = 0; i < _beneficiary.length; i++){
            freeze storage _freeze = freezedTokens[_beneficiary[i]];
            _freeze.amount = _amount[i];
            _freeze.when = _when[i];
        }
    }


    function transferAndFreeze(address _to, uint256 _value, uint256 _when) external {
        require(unpausedWallet[msg.sender]);
        require(freezedTokenOf(_to) == 0);
        if(_when > 0){
            freeze storage _freeze = freezedTokens[_to];
            _freeze.amount = _value;
            _freeze.when = _when;
        }
        transfer(_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender).add(_value));
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from).add(_value));
        return super.transferFrom( _from,_to,_value);
    }
}

contract Token is IToken, FreezingToken, MintableToken, MigratableToken, KycToken,ERC20Provider {
    function Token(ICreator _creator) GuidedByRoles(_creator.rightAndRoles()) public {}
    string public constant name = "Ale Coin";
    string public constant symbol = "ALE";
    uint8 public constant decimals = 18;
}