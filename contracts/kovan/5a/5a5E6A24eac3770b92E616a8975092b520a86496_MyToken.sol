/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity >=0.7.0 <0.9.0;

contract MyToken{
    string TokenName = "Suise_My_Wife_1";
    string SYM = "Suichan";
    uint TotalSupply = 10000;
    uint8 Decimal = 0;
    address Boss;

    mapping(address => uint)Balance;
    mapping(address => mapping(address => uint))Approved;

    constructor(){
        Balance[msg.sender] = TotalSupply;
        Boss = msg.sender;
    } 

    function callBoss() public view returns(address){
        return Boss;
    }

    // ERC20 functions and events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string memory){ return TokenName; }
    function symbol() public view returns (string memory){ return SYM; }
    function decimals() public view returns (uint8){ return Decimal; }
    function totalSupply() public view returns (uint256){ return TotalSupply; }
    function balanceOf(address _owner) public view returns (uint256 balance){ return Balance[_owner]; }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(Balance[msg.sender] >= _value);
        Balance[msg.sender] -= _value;
        Balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(Approved[_from][msg.sender] >= _value);
        require(Balance[_from] >= _value);
        Approved[_from][msg.sender] -= _value;
        Balance[_from] -= _value;
        Balance[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        Approved[msg.sender][_spender] += _value;
        emit Transfer(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        require(msg.sender == _owner || msg.sender == _spender);
        return Approved[_owner][_spender];
    }
}