pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

}

// @title The Contract is Standard Token Design.
//
// @Author: Tim Wars
// @Date: 2018.8.3
// @Seealso: ERC20
//
contract ISCToken {

    // === Event ===
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
	event Owner(address indexed from, address indexed to);

    // === Defined ===
    using SafeMath for uint;

    // --- Owner Section ---
    address public owner;
    bool public frozen = false; //

    // --- ERC20 Token Section ---
    uint8 constant public decimals = 24;
    uint public totalSupply = 100 * 10 ** (8+uint256(decimals));  // ***** 1 * 100 Million
    string constant public name = "ISC Token";
    string constant public symbol = "ISC";

    mapping(address => uint) ownerance; // Owner Balance
    mapping(address => mapping(address => uint)) public allowance; // Allower Balance


    // === Modifier ===
    // --- Functional Section ---
    modifier onlyPayloadSize(uint size) {
      assert(msg.data.length == size + 4);
      _;
    }

    // --- Owner Section ---
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isNotFrozen() {
        require(!frozen);
        _;
    }

    // --- ERC20 Section ---
    modifier hasEnoughBalance(uint _amount) {
        require(ownerance[msg.sender] >= _amount);
        _;
    }

    modifier overflowDetected(address _owner, uint _amount) {
        require(ownerance[_owner] + _amount >= ownerance[_owner]);
        _;
    }

    modifier hasAllowBalance(address _owner, address _allower, uint _amount) {
        require(allowance[_owner][_allower] >= _amount);
        _;
    }

    modifier isNotEmpty(address _addr, uint _value) {
        require(_addr != address(0));
        require(_value != 0);
        _;
    }

    modifier isValidAddress {
        assert(0x0 != msg.sender);
        _;
    }

    // === Constructor ===
    constructor() public {
        owner = msg.sender;
        ownerance[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    // --- ERC20 Token Section ---
    function approve(address _spender, uint _value)
        isNotFrozen
        isValidAddress
        public returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0); // must spend to 0 where pre approve balance.
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
        isNotFrozen
        isValidAddress
        overflowDetected(_to, _value)
        public returns (bool success)
    {
        require(ownerance[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);

        ownerance[_to] = ownerance[_to].add(_value);
        ownerance[_from] = ownerance[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public
        constant returns (uint balance)
    {
        return ownerance[_owner];
    }


    function transfer(address _to, uint _value) public
        isNotFrozen
        isValidAddress
        isNotEmpty(_to, _value)
        hasEnoughBalance(_value)
        overflowDetected(_to, _value)
        onlyPayloadSize(2 * 32)
        returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[_to] = ownerance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // --- Owner Section ---
    function transferOwner(address _newOwner)
        isOwner
        public returns (bool success)
    {
        if (_newOwner != address(0)) {
            owner = _newOwner;
            emit Owner(msg.sender, owner);
        }
        return true;
    }

    function freeze()
        isOwner
        public returns (bool success)
    {
        frozen = true;
        return true;
    }

    function unfreeze()
        isOwner
        public returns (bool success)
    {
        frozen = false;
        return true;
    }

    function burn(uint _value)
        isNotFrozen
        isValidAddress
        hasEnoughBalance(_value)
        public returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[0x0] = ownerance[0x0].add(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

}