// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
/* 
interface FinanContract{
    function deposit (address _depositer,uint _amount,uint _cycle) external returns (uint);
    function withdraw (address _withdrawer,uint _amount) external returns (uint);
    function send (address _receive,uint _amount) external returns (uint);
} */
contract Kbkc is Ownable{
    string public  name;
    string public  symbol;
    uint public  decimals = 18;
    uint256 public totalSupply=10000000000;
    /* FinanContract finanPlay; */
    /* address private finan; */

    mapping (address => uint256) public balanceOf;  //
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint256 value);

    constructor (uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        totalSupply = initialSupply * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        /* finan = finanAddress; */
        /* finanPlay = FinanContract(finanAddress); */
    }
    /* function setFinan(address _finan) external onlyOwner {
        finan = _finan;
    } */
    /* function send(address _to,uint _value) external onlyOwner returns (bool)  {
        _transfer(finan,_to,_value);
        finanPlay.send(_to,_value);
        return true;
    }
    function withdraw(address _to,uint _value) external onlyOwner returns (bool)  {
        _transfer(finan,_to,_value);
        finanPlay.withdraw(_to,_value);
        return true;
    }
    function deposit(uint _value,uint _cycle) external returns (bool)  {
        _transfer(msg.sender,finan,_value);
        finanPlay.deposit(msg.sender,_value,_cycle);
        return true;
    } */
    function totalSupply() external view returns (uint) {
        return totalSupply;
    }
    function balanceOf(address _owner) external view returns (uint) {
        return balanceOf[_owner];
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
    }
}