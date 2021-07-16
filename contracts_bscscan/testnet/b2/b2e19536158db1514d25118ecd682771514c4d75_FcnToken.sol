/*
    function fromWhiteListAddressOf(address account) public view returns (bool) {
        return _fromWhiteListAddress[account];
    }

    function toWhiteListAddressOf(address account) public view returns (bool) {
        return _toWhiteListAddress[account];
    }

    function _setFromWhiteListAddress(address account,bool value) internal {
        _fromWhiteListAddress[account] = value;
    }

    function _setToWhiteListAddress(address account,bool value) internal {
        _toWhiteListAddress[account] = value;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }



    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(fromWhiteListAddressOf(sender)==true||toWhiteListAddressOf(recipient)==true){
            _totalSupplyBurnFee=0;
        }else{
            if(_totalSupply>30000*10**_tokenDecimals){_totalSupplyBurnFee = 5;}
            else{_totalSupplyBurnFee = 0;}
        }

        if(_totalSupplyBurnFee==0){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }else{
            uint256 burnAmount5 = amount.mul(_totalSupplyBurnFee).div(100).mul(50).div(100);
            uint256 burnAmount3 = amount.mul(_totalSupplyBurnFee).div(100).mul(30).div(100);
            uint256 burnAmount2 = amount.mul(_totalSupplyBurnFee).div(100).mul(20).div(100);

            _balances[sender] = _balances[sender].sub(amount.add(burnAmount5.mul(2)), "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);

            _balances[_liquidityAddress] = _balances[_liquidityAddress].add(burnAmount3);
            _balances[_labsAddress] = _balances[_labsAddress].add(burnAmount2);
            _totalSupply = _totalSupply.sub(burnAmount5);

            _tradeBurn=_tradeBurn.add(burnAmount5);//Statistical destruction

            // tradeBurn add emit
            emit TradeBurn(sender, recipient, burnAmount5);
        }

        emit Transfer(sender, recipient, amount);
    }
*/



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
    uint256 public transferBurnTotal;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TransferBurn(address indexed _fromAddress, address indexed _toAddress, uint256 _fromValue, uint256 _toValue, uint256 _burnValue);

    /*
    mapping(address => bool)  internal _fromWhiteListAddress;
    mapping(address => bool)  internal _toWhiteListAddress; */

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
        balances[_recipient] = balances[_recipient].add(_amount.mul(95).div(100));
        balances[address(0)] = balances[address(0)].add(_amount.mul(5).div(100));

        emit TransferBurn(_sender, _recipient, _amount, _amount.mul(95).div(100), _amount.mul(5).div(100));
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