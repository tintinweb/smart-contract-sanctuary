pragma solidity ^0.5.0;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol" ;

contract FcnToken is Ownable {
    using SafeMath for uint256;

    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // TransferBurn
    mapping(address => bool)  private fromWhiteListAddress;
    mapping(address => bool)  private toWhiteListAddress;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TokenBurn(address indexed _fromAddress, address indexed _toAddress, uint256 _burnValue);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "FcnToken";
        _symbol = "FCN";
        _decimals = 18;
        _totalSupply = 1000000000000000000000000000000000;// 10000000_00000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply.div(2);
        balances[address(0)] = _totalSupply.div(2);
        emit Transfer(address(this), _initial_account, _totalSupply.div(2));
        emit Transfer(address(this), address(0), _totalSupply.div(2));// Issue 1000 trillion tokens and directly destroy 50% of the black hole

    }

    // ================= Special transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");

        balances[_sender] = balances[_sender].sub(_amount);

        if(fromWhiteListAddressOf(_sender)==true||toWhiteListAddressOf(_recipient)==true){
            // TokenBurn 0%
            balances[_recipient] = balances[_recipient].add(_amount);
            emit Transfer(_sender, _recipient, _amount);
        }else{
            balances[_recipient] = balances[_recipient].add(_amount.mul(95).div(100));
            emit Transfer(_sender, _recipient, _amount);

            // TokenBurn 5%
            balances[address(0)] = balances[address(0)].add(_amount.mul(5).div(100));
            emit TokenBurn(_sender,_recipient,_amount.mul(5).div(100));
        }
    }

    // ================= ERC20 Basic Write ===============

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // ================= White list ===============

    function fromWhiteListAddressOf(address _account) public view returns (bool) {
        return fromWhiteListAddress[_account];
    }

    function toWhiteListAddressOf(address _account) public view returns (bool) {
        return toWhiteListAddress[_account];
    }

    function _setFromWhiteListAddress(address _account,bool _value) public onlyOwner returns (bool) {
        fromWhiteListAddress[_account] = _value;
        return true;
    }

    function _setToWhiteListAddress(address _account,bool _value) public onlyOwner returns (bool) {
        toWhiteListAddress[_account] = _value;
        return true;
    }

    // ================= ERC20 Basic Query ===============

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

}