/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

contract OwnerHelper {
    address public owner;
    mapping(address => bool) locked_;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier locked() {
        require(!locked_[msg.sender]);
        _;
    }

    modifier lockedSender(address from) {
        require(!locked_[from]);
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function lock(address who_) public onlyOwner{
        locked_[who_] = true;
    }

    function unlock(address who_) public onlyOwner {
        locked_[who_] = false;
    }


}

interface ERC20Interface {
    event Burn(address indexed _burner, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() view external returns (uint _supply);

    function balanceOf(address _who) external view returns (uint _value);

    function transfer(address _to, uint256 _value) external returns (bool _success);

    function approve(address _spender, uint256 _value) external returns (bool _success);

    function allowance(address _owner, address _spender) external view returns (uint _allowance);

    function decreaseAllowance(address _spender, uint256 _value) external returns(bool _success);

    function increaseAllowance(address _spender, uint256 _value) external returns(bool _success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);

    function burn(uint256 _value) external;

}

contract BProto is OwnerHelper {
    using SafeMath for uint;

    string public _name;
    uint8 public _decimals;
    string public _symbol;

    uint256 private _totalSupply;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) internal allowed;

    uint constant private E18 = 1000000000000000000;

    event Burn(address indexed _burner, uint256 _value);

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor() public {
        _name = "BProto";
        _decimals = 18;
        _symbol = "BPO";
        _totalSupply = 1100000000 * E18;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() view public returns (uint){
        return _totalSupply;
    }

    function balanceOf(address _who) view public returns(uint){
        return _balances[_who];
    }

    function transfer(address _to, uint _value) public locked returns(bool){
        require(_balances[msg.sender] >= _value);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns(bool){
        require(_balances[msg.sender] >= _value);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint){
        return allowed[_owner][_spender];
    }

    function decreaseAllowance(address _spender, uint256 _value) external returns(bool){
        require(_spender != address(0));
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function increaseAllowance(address _spender, uint256 _value) external returns(bool){
        require(_spender != address(0));
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }


    function transferFrom(address _from, address _to, uint _value) public lockedSender(_from) returns(bool){
        require(_to != address(0));
        require(_balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function burn(uint256 _value) public {
        require(_balances[msg.sender] >= _value);

        address burner = msg.sender;
        _balances[burner] = _balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);

        emit Transfer(burner, address(0), _value);
        emit Burn(burner, _value);
    }
}