/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// File: solidity/solidity/Owned.sol

pragma solidity ^0.4.10;

contract Owned {
    address public owner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /*
        allows transferring the contract ownership
        can only be called by the contract owner
    */
    function setOwner(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        address prevOwner = owner;
        owner = _newOwner;
        OwnerUpdate(prevOwner, owner);
    }
}

// File: solidity/solidity/ERC20TokenInterface.sol

pragma solidity ^0.4.10;

/*
    ERC20 Standard Token interface
*/
contract ERC20TokenInterface {
    // these functions aren't abstract since the compiler doesn't recognize automatically generated getter functions as functions
    function totalSupply() public constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: solidity/solidity/ERC20Token.sol

pragma solidity ^0.4.10;

/*
    ERC20 Standard Token implementation
*/
contract ERC20Token is ERC20TokenInterface {
    string public standard = 'Token 0.1';
    string public name = '';
    string public symbol = '';
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ERC20Token(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        assert(_address != 0x0);
        _;
    }

    /*
        send coins
        note that the function slightly deviates from the ERC20 standard and will throw on any error rather then return a boolean return value to minimize user errors
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        require(_value <= balanceOf[msg.sender]); // balance check
        assert(balanceOf[_to] + _value >= balanceOf[_to]); // overflow protection

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /*
        an account/contract attempts to get the coins
        note that the function slightly deviates from the ERC20 standard and will throw on any error rather then return a boolean return value to minimize user errors
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        require(_value <= balanceOf[_from]); // balance check
        require(_value <= allowance[_from][msg.sender]); // allowance check
        assert(balanceOf[_to] + _value >= balanceOf[_to]); // overflow protection

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /*
        allow another account/contract to spend some tokens on your behalf
        note that the function slightly deviates from the ERC20 standard and will throw on any error rather then return a boolean return value to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

// File: solidity/solidity/BancorEventsInterface.sol

pragma solidity ^0.4.10;

/*
    Bancor events interface
*/
contract BancorEventsInterface {
    event NewToken(address _token);
    event TokenOwnerUpdate(address indexed _token, address _prevOwner, address _newOwner);
    event TokenChangerUpdate(address indexed _token, address _prevChanger, address _newChanger);
    event TokenTransfer(address indexed _token, address indexed _from, address indexed _to, uint256 _value);
    event TokenApproval(address indexed _token, address indexed _owner, address indexed _spender, uint256 _value);
    event TokenChange(address indexed _sender, address indexed _fromToken, address indexed _toToken, address _changer, uint256 _amount, uint256 _return);

    function newToken() public;
    function tokenOwnerUpdate(address _prevOwner, address _newOwner) public;
    function tokenChangerUpdate(address _prevChanger, address _newChanger) public;
    function tokenTransfer(address _from, address _to, uint256 _value) public;
    function tokenApproval(address _owner, address _spender, uint256 _value) public;
    function tokenChange(address _fromToken, address _toToken, address _changer, uint256 _amount, uint256 _return) public;
}

// File: solidity/solidity/SmartToken.sol

pragma solidity ^0.4.10;

/*
    Smart Token v0.1
*/
contract SmartToken is Owned, ERC20Token {
    string public version = '0.1';
    uint8 public numDecimalUnits = 0;   // for display purposes only
    address public events = 0x0;        // bancor events contract address
    address public changer = 0x0;       // changer contract address
    bool public transfersEnabled = true;

    // events, can be used to listen to the contract directly, as opposed to through the events contract
    event ChangerUpdate(address _prevChanger, address _newChanger);

    /*
        _name               token name
        _symbol             token short symbol, 1-6 characters
        _numDecimalUnits    for display purposes only
        _formula            address of a bancor formula contract
        _events             optional, address of a bancor events contract
    */
    function SmartToken(string _name, string _symbol, uint8 _numDecimalUnits, address _events)
        ERC20Token(_name, _symbol)
    {
        require(bytes(_name).length != 0 && bytes(_symbol).length >= 1 && bytes(_symbol).length <= 6); // validate input

        numDecimalUnits = _numDecimalUnits;
        events = _events;
        if (events == 0x0)
            return;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.newToken();
    }

    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    // allows execution by the owner if there's no changer defined or by the changer contract if a changer is defined
    modifier managerOnly {
        assert((changer == 0x0 && msg.sender == owner) ||
               (changer != 0x0 && msg.sender == changer)); // validate state & permissions
        _;
    }

    function setOwner(address _newOwner)
        public
        ownerOnly
        validAddress(_newOwner)
    {
        address prevOwner = owner;
        super.setOwner(_newOwner);
        if (events == 0x0)
            return;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.tokenOwnerUpdate(prevOwner, owner);
    }

    /*
        sets the number of display decimal units
        can only be called by the token owner

        _numDecimalUnits    new number of decimal units
    */
    function setNumDecimalUnits(uint8 _numDecimalUnits) public ownerOnly {
        numDecimalUnits = _numDecimalUnits;
    }

    /*
        disables/enables transfers
        can only be called by the token owner (if no changer is defined) or the changer contract (if a changer is defined)

        _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public managerOnly {
        transfersEnabled = !_disable;
    }

    /*
        increases the token supply and sends the new tokens to an account
        can only be called by the token owner (if no changer is defined) or the changer contract (if a changer is defined)

        _to         account to receive the new amount
        _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        managerOnly
        validAddress(_to)
        returns (bool success)
    {
         // validate input
        require(_to != address(this) && _amount != 0);
         // supply overflow protection
        assert(totalSupply + _amount >= totalSupply);
        // target account balance overflow protection
        assert(balanceOf[_to] + _amount >= balanceOf[_to]);

        totalSupply += _amount;
        balanceOf[_to] += _amount;
        dispatchTransfer(this, _to, _amount);
        return true;
    }

    /*
        removes tokens from an account and decreases the token supply
        can only be called by the token owner (if no changer is defined) or the changer contract (if a changer is defined)

        _from       account to remove the new amount from
        _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount)
        public
        managerOnly
        validAddress(_from)
        returns (bool success)
    {
        require(_from != address(this) && _amount != 0 && _amount <= balanceOf[_from]); // validate input

        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
        dispatchTransfer(_from, this, _amount);
        return true;
    }

    /*
        sets a changer contract address
        can only be called by the token owner (if no changer is defined) or the changer contract (if a changer is defined)
        the changer can be set to null to transfer ownership from the changer to the owner

        _changer            new changer contract address (can also be set to 0x0 to remove the current changer)
    */
    function setChanger(address _changer) public managerOnly returns (bool success) {
        require(_changer != changer);
        address prevChanger = changer;
        changer = _changer;
        dispatchChangerUpdate(prevChanger, changer);
        return true;
    }

    // ERC20 standard method overrides with some extra functionality

    // send coins
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));

        // transferring to the contract address destroys tokens
        if (_to == address(this)) {
            balanceOf[_to] -= _value;
            totalSupply -= _value;
        }

        if (events == 0x0)
            return;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.tokenTransfer(msg.sender, _to, _value);
        return true;
    }

    // an account/contract attempts to get the coins
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));

        // transferring to the contract address destroys tokens
        if (_to == address(this)) {
            balanceOf[_to] -= _value;
            totalSupply -= _value;
        }

        if (events == 0x0)
            return;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.tokenTransfer(_from, _to, _value);
        return true;
    }

    // allow another account/contract to spend some tokens on your behalf
    function approve(address _spender, uint256 _value) public returns (bool success) {
        assert(super.approve(_spender, _value));
        if (events == 0x0)
            return true;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.tokenApproval(msg.sender, _spender, _value);
        return true;
    }

    // utility

    function dispatchChangerUpdate(address _prevChanger, address _newChanger) private {
        ChangerUpdate(_prevChanger, _newChanger);
        if (events == 0x0)
            return;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.tokenChangerUpdate(_prevChanger, _newChanger);
    }

    function dispatchTransfer(address _from, address _to, uint256 _value) private {
        Transfer(_from, _to, _value);
        if (events == 0x0)
            return;

        BancorEventsInterface eventsContract = BancorEventsInterface(events);
        eventsContract.tokenTransfer(_from, _to, _value);
    }

    // fallback
    function() {
        assert(false);
    }
}