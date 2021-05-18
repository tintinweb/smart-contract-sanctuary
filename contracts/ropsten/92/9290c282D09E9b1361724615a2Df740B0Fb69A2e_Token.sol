/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.8.0;

interface IERC20 {
    
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is IERC20{
	string private _name = "705330558";
	string private  _symbol = "CS188";
	uint8 private _decimals = 18;
	
	uint256 private _totalSupply;

	mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowance;


	// event Transfer(address indexed _from, address indexed _to, uint256 _value);
	// event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor() {
		_totalSupply = 1000000;// * 10 ** uint256(_decimals); 
		_balance[msg.sender] = _totalSupply;
	}


	function name() public view override returns (string memory){
		return _name;
	}

	function symbol() public view override returns (string memory) {
		return _symbol;
	}

	function decimals() public view override returns (uint8){
		return _decimals;
	}

	function totalSupply() public view override returns (uint256){
		return _totalSupply;
	}

	function balanceOf(address _owner) public view override returns (uint256){
		return _balance[_owner];
		
	}

	function transfer(address _to, uint256 _value) public override returns (bool){
		require(_value <= _balance[msg.sender]);
		_balance[msg.sender] = _balance[msg.sender] - _value;
		_balance[_to] =  _balance[_to] + _value;
		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
		require(_value <= _balance[_from]);
		require(_value <= _allowance[_from][msg.sender]);

		_balance[_from] = _balance[_from] - _value;
		_allowance[_from][msg.sender] = _allowance[_from][msg.sender] - _value;
		_balance[_to] = _balance[_to] + _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public override returns (bool){
		_allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view override returns (uint256){
		return _allowance[_owner][_spender];
	} 

}