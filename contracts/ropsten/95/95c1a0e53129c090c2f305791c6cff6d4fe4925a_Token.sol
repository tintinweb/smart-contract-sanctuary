/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.8.0;



contract Token {

    // VARIABLES
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    address public _owner;
    string public _name; 
    string public _symbol;
    uint256 public _totalSupply;

    mapping(address=>uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowances;

    // CONSTRUCTOR

    constructor (
        uint256 totalSupply
    ) public {
        _owner = msg.sender;
        _name = '705110900';
        _symbol = 'CS188';
        _totalSupply = totalSupply; // one million
        _balanceOf[msg.sender] = totalSupply; // transfer 100 tokens to spend?
    }

    // VIEWS

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return 18;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balanceOf[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return transferFrom(msg.sender, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = _allowances[_from][msg.sender];
        require(_balanceOf[_from] >= _value && allowance >= _value);
        _balanceOf[_to] += _value;
        _balanceOf[_from] -= _value;
        if (allowance < MAX_UINT256) {
            _allowances[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _value;

        emit Approval(_owner, _spender, _value);
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    // EVENTS

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}