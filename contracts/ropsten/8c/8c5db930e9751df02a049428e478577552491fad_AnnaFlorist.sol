/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity 0.5.0;

contract AnnaFlorist {

    constructor () public {
        name_ = "ANNA_FLORIST";
        symbol_ = "AFL";
        decimals_ = 0;
        tsupply = 1000;
        // total supply to deployer
        balances[msg.sender] = tsupply;
        admin = msg.sender;
    }
    address admin;
    string name_;
    string symbol_;
    uint8 decimals_;
    uint256 tsupply;
    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory){
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;

    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Owner does not have enough tokens");
        require(allowances[_from][msg.sender]>= _value, "Not enough allowance remaining");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from , _to , _value);
        return true;
    }
    mapping(address => mapping(address => uint256)) allowances;
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowances[msg.sender][_spender] = _value;
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
    // Mint - Adding to total supply.
    modifier onlyAdmin{
        require( msg.sender == admin, "Only admin");
        _;
    }
    function mint(address _account, uint256 _add) public onlyAdmin returns(bool) {
        tsupply += _add;
        // added tokens go to admin (deployer)
        //balances[admin] += _add;
        // added tokens go to  some specific address
        balances[_account] += _add;
        return true;
    }

    //Burn - Reduce total supply
    function burn(uint256 _qty) public onlyAdmin returns(bool) {
        require(balances[admin]>= _qty, "Not enough tokens to burn");
        tsupply -= _qty;
        balances[admin] -= _qty;
        return true;
    }
   
}