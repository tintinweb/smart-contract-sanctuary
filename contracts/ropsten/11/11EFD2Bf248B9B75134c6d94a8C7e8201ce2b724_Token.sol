/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.8.0;

/**
* @title Token
* @dev The Token contract follows the ERC20 standard. The name of the token 
* matches my student ID (105364966), and the symbol is the name of this 
* course (CS188).
* This token is being made as a part of a blockchain & distributed algorithms 
* course at UCLA.
*/
contract Token {
    // TODO: define mappings & constants?
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimal;

    mapping (address => uint256) private _balances;

    // allowances[owner][caller]
    mapping (address => mapping (address => uint256)) private _allowances;

    /**
    * @dev Constructor
    */
    constructor() {
        _name = "105364966";
        _symbol = "CS188";
        _decimal = 18;
        _balances[msg.sender] = 100;
        _totalSupply = 100;
    }

    /**
    * @dev Returns the name of the token (my university ID number).
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the token (name of the course).
    */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev 18 was chosen due to it's use among popular tokens.
    */
    function decimals() public view returns (uint8) {
        return _decimal;
    }

    /**
    * @dev returns the number of coins in circulation.
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev returns the balance of the provided owner.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    /**
    * @dev Transfers an amount (_value) of Token to a target (_to) from the 
    * sender's balance.
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // make sure that the sender has enough token to send
        require(_balances[msg.sender] >= _value);
        // decrement from sender's balance/ increment to target's balance
        _balances[msg.sender] = _balances[msg.sender] - _value;
        _balances[_to] = _balances[_to] + _value;
        // trigger transfer event
        emit Transfer(msg.sender, _to, _value);
        // report success
        return true;
    }

    /**
    * @dev transfers _value from _from to _to (up to pre-approved ammount).
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // make sure the _from has high enough balance
        require(_balances[_from] >= _value);
        // make sure sender is allowed to send on _from's behalf
        require(_allowances[_from][msg.sender] >= _value);

        // Decrement _from, increment _to
        _balances[_from] = _balances[_from] - _value;
        _balances[_to] = _balances[_to] + _value;

        // Update allowances
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender] - _value;

        // trigger transfer event
        emit Transfer(_from, _to, _value);
        // report success
        return true;
    }

    /**
    * @dev Give permission for _spender to transfer up to _value from _owner's 
    * account.
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Update allowances
        _allowances[msg.sender][_spender] = _value;

        // Trigger Approval event
        emit Approval(msg.sender, _spender, _value);

        // Report success
        return true;
    }

    /**
    * @dev returns the amount of _owner's balance that _spender may use to transfer.
    */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}