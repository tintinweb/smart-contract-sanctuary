pragma solidity ^0.4.24;

contract todoRename{

    uint _totalSupply = 10000000;
    uint public tokenCirculation;
    uint public decimals = 2;
    string name = &#39;TACoin&#39;;
    string symbol = &#39;TAC&#39;;
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) private _allowance;
    address public manager;

    constructor() public{
        manager = msg.sender;
        balances[manager] = 5000;
    }

    modifier onlyManager(){
        require(msg.sender ==manager);
        _;
    }
    function totalSupply() public constant returns (uint){
        return _totalSupply;
    }

    function balanceOf(address _tokenOwner) public constant returns (uint balance){
        return balances[_tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining){
        remaining = _allowance[tokenOwner][spender];
        return remaining;
    }

    function transfer(address _to, uint _tokens) public returns (bool success){
        success = false;
        require(balances[msg.sender]>= _tokens);
        balances[msg.sender] -= _tokens;
        balances[_to] += _tokens;
        success = true;
        emit Transfer(msg.sender, _to, _tokens);
        return success;

    }

    function approve(address _spender, uint _tokens) public returns (bool success){
        success = false;
        require(balances[msg.sender]>= _tokens);
        _allowance[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return success;
    }

    function transferFrom(address _from, address _to, uint _tokens) public returns (bool success){
        success = false;
        require(_allowance[_from][msg.sender] >= _tokens);
        balances[_from] -= _tokens;
        balances[_to] += _tokens;
        success = true;
        emit Transfer(_from, _to, _tokens);
        return success;

    }

    function mint(address _to, uint _tokens) public onlyManager returns(bool success){
        success = false;
        require((tokenCirculation+_tokens) <= _totalSupply);
        balances[_to] += _tokens;
        emit Transfer(this, _to, _tokens);
        success = true;
        return success;
    }

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}