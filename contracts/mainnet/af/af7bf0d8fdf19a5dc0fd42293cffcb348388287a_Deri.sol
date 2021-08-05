/**
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

pragma solidity ^0.6.12;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint _value) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Deri is ERC20Interface, SafeMath {

    string public constant name = "Deriswap V1";
    string public constant symbol = "Deri";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 410000e18;
    
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    constructor() public {
        balances[address(0xE3F67850ad4E181Af82398dEd8172c8CE4b80e59)] = 1000e18;
        balances[address(0x9F53735FC852b70cf0f0fD5A478579370b1ef380)] = 800e18;
        balances[address(0xb77440a40165d125D4f15E43Ba727b08F9eC965C)] = 700e18;
        balances[address(0xA32a9361d8c18AD1CA10F359f3935d746a3caF62)] = 500e18;
        balances[address(0x648543e6bfDd02e147460bCaa4cC43a623342e1d)] = 407000e18;

        emit Transfer(address(0x0), address(0xE3F67850ad4E181Af82398dEd8172c8CE4b80e59), 1000e18);
        emit Transfer(address(0x0), address(0x9F53735FC852b70cf0f0fD5A478579370b1ef380), 800e18);
        emit Transfer(address(0x0), address(0xb77440a40165d125D4f15E43Ba727b08F9eC965C), 700e18);
        emit Transfer(address(0x0), address(0xA32a9361d8c18AD1CA10F359f3935d746a3caF62), 500e18);
        emit Transfer(address(0x0), address(0x648543e6bfDd02e147460bCaa4cC43a623342e1d), 407000e18);
    }
    
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4) ;
        _;
    }
  
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) override returns (bool success){
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(2 * 32) override returns (bool success) {
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint balance) {
            return balances[_owner];
    }

    function approve(address _spender, uint _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override returns (uint remaining) {
        return allowed[_owner][_spender];
    }
  
}