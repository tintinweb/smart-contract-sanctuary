/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface ERC20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8 );
    function totalSupply() external view returns (uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
contract ERC20 is ERC20Interface{
    string public _name;
    string public _symbol;
    uint8 public _decimals;  // 18 是建议的默认值
    uint256 public _totalSupply;
    mapping (address => uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol){
	_totalSupply = initialSupply * 10 ** uint256(_decimals); 
	_balanceOf[msg.sender] = _totalSupply;               
	_name = tokenName;                                   
	_symbol = tokenSymbol;                               
    }
    function name() external view  override returns (string memory){
        return _name;
    }
    function symbol() external view virtual override returns (string memory){
        return _symbol;
    }
    function decimals() external view virtual override returns (uint8 ){
        return _decimals;
    }
    function totalSupply() external view virtual override returns (uint256 ){
        return _totalSupply;
    }
    function balanceOf(address _owner) external  view virtual override returns (uint256 balance){
        balance = _balanceOf[_owner];
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal virtual {
        require(_to != address(0));
        require(_balanceOf[_from] >= _value);
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        uint  qian=_balanceOf[_from]+_balanceOf[_to];
        _balanceOf[_from]-=_value;
        _balanceOf[_to]+=_value;
        emit Transfer(_from, _to, _value);
        assert(_balanceOf[_from] + _balanceOf[_to] == qian);
    }
    function transfer(address _to, uint256 _value) external virtual override returns(bool success){//不确定b
        _transfer(msg.sender, _to, _value);
        success=true;
    }
    function transferFrom(address _from, address _to, uint256 _value) external virtual override returns (bool success){
        require(_balanceOf[_from]>=_value);//拿不准
        require(_allowance[_from][_to] >= _value);
        _allowance[_from][_to] -= _value;
        _transfer(_from, _to, _value);
        success = true;
    }
    function approve(address _spender, uint256 _value) external virtual override returns (bool success){
        require(msg.sender != address(0));
        require(_spender != address(0)); 
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }
    function allowance(address _owner, address _spender) external view virtual override returns (uint256 remaining){
        return _allowance[_owner][_spender];
    }
    function burn(uint256 _value) public returns (bool success) {
	require(_balanceOf[msg.sender] >= _value);   // Check if the sender has enough
	_balanceOf[msg.sender] -= _value;            // Subtract from the sender
	_totalSupply -= _value;                      // Updates totalSupply
	emit Burn(msg.sender, _value);
	return true;
}
}