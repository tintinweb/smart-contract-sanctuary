/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;

contract ERC20Token {

    address owner;
    constructor (string memory _name, string memory _symbol, uint8 _decimal ) public {
        owner = msg.sender;
        name_   = _name;
        symbol_ = _symbol;
        decimals_ = _decimal;
    }

    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    uint256 tsupply ;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value );
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( balances[_from]>= _value, "Insufficient balance with owner");
        // check if allowance is available
        require( allowed[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => mapping (address => uint256)) allowed;
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Function for increase allowance.
    function increaseAllowance(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] += _value;
        return true;
    }

    function decresingAllowance(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] -= _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    modifier onlyOwner {
        require( msg.sender == owner, "Only Owner");
        _;
    }
    // Mint 

    function _mint(uint256 _qty) internal onlyOwner returns (bool) {
        tsupply += _qty;
        // Newly minted token to some specified address .
        //balances[_to] += _qty;
        // newly minted token to msg.sender
        //balances[msg.sender] += _qty;
        // to contract deployer
        balances[owner] += _qty;
        return true;
    }


    // Burn
    
    function _burn(uint256 _qty) internal onlyOwner returns (bool) {
        require(balances[msg.sender] >= _qty, " Not enough tokens to burn");
        tsupply -= _qty;
        balances[owner] -= _qty;
        return true;

    }
}

contract Ixiono is ERC20Token {

    constructor() ERC20Token("Ixiono", "IXI2", 0) public {
        _mint(1002);       
    }
}