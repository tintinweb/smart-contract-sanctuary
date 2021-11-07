// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract Play is Ownable{
    string public  name = "Migrations_Copy";
    string public  symbol ="MigCopy";
    uint public  decimals = 18;
    string private test;
    uint256 public _totalSupply=10000000000 * 10 ** decimals;

    mapping (address => uint256) public _balanceOf;  //
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint256 value);

    constructor (string memory _test) {
        test = _test;
        _balanceOf[msg.sender] = _totalSupply;
    }
    function setTest(string memory _test) public {
        test = _test;
    }
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address _owner) external view returns (uint) {
        return _balanceOf[_owner];
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(_balanceOf[_from] >= _value);
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        _approve(msg.sender,_spender,_value);
        return true;
    }
    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function burn(uint256 _value) public onlyOwner {
        require(_balanceOf[msg.sender] >= _value);
        _balanceOf[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner {
        require(_balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        _balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        _totalSupply -= _value;
        emit Burn(_from, _value);
    }
}