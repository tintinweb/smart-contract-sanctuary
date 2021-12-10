/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;
 
contract Nguvu {
    address owner;
    constructor (uint256 _qty) public {
        owner = msg.sender;
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_   = "NGUVU";
        symbol_ = "N";
        decimals_ = 0;
 
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

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
            require(balances[_from]>= _value, "Insufficient Balance");
            //check if Allwonse is Available
            require(allowed[_from][msg.sender] >= _value,"not enough Allowence");
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;

            emit Transfer(_from, _to, _value);
            return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => mapping (address => uint256)) allowed;
    function approve(address _spender, uint256 _value) public returns(bool success){
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining){
        return allowed[_owner][_spender]; 
    }

    function increaseAllowance(address _spender, uint256 _value) public returns(bool){ 
        allowed[msg.sender][_spender] +=_value; 
        return true;
    }

    function decreseAllowance(address _spender, uint256 _value) public returns(bool){ 
        allowed[msg.sender][_spender]  -= _value; 
        return true;
    }


    modifier OnlyOwner{
        require(msg.sender == owner, "Only owner");
        _;
    }

    function mint(uint256 _qty) public returns(bool){
        //newly minted token to some specify address
        //balances[_to] += _qty;
        //newly minted token to msg.sender
        //balances[msg.sender] += _qty;
        // to contract deployer
        balances[owner] += _qty;
        return true;

    }

    // burn
    function burn(uint256 _qty) public OnlyOwner returns(bool){
        // to check owner balance so owner can not burn more than balance
        require(balances[msg.sender] >= _qty , "Not Enugh token to burn");
        tsupply = _qty;
        balances[owner]= _qty;
        return true;
    }
 
}