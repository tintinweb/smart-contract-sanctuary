pragma solidity ^0.5.0;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol" ;
import "./SafeERC20.sol";

contract DTU is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // TransferBurn
    mapping(address => bool) private fromWhiteListAddress;
    mapping(address => bool) private toWhiteListAddress;

    address public fundAddress;// 2%
    address public shareAddress;// 3%

    uint256 public tradeFeeTotal;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TradeFee(address indexed _account, address _shareAddress, address _recipient, uint256 _tradeFee);
    event AddressList(address indexed _account, address _shareAddress, address _fundAddress);
    event FromWhiteList(address indexed _account, address _fromWhiteListAddress, bool _value);
    event ToWhiteList(address indexed _account, address _fromWhiteListAddress, bool _value);


    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "Dream Trade Union";
        _symbol = "DTU";
        _decimals = 18;
        _totalSupply = 210000000000000000000000000;// 2.1_00000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply;
        emit Transfer(address(this), _initial_account, _totalSupply);
    }

    // ================= Fee transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");

        if(fromWhiteListAddressOf(_sender)||toWhiteListAddressOf(_recipient)){
            balances[_sender] -= _amount;
            balances[_recipient] += _amount;
            emit Transfer(_sender, _recipient, _amount);
        }else{
            require(_amount.add(_amount.mul(5).div(100)) <= balances[_sender],"ERC20: transfer amount exceeds balance");

            balances[_sender] -= _amount.add(_amount.mul(5).div(100));// sell ==>  user 105%

            balances[_recipient] += _amount;// _recipient 100%
            emit Transfer(_sender, _recipient, _amount);

            balances[shareAddress] += _amount.mul(3).div(100);// shareAddress 3%
            emit Transfer(_sender, shareAddress, _amount.mul(3).div(100));

            balances[fundAddress] += _amount.mul(2).div(100);// fundAddress 2%
            emit Transfer(_sender, fundAddress, _amount.mul(2).div(100));

            tradeFeeTotal += _amount.mul(5).div(100);
            emit TradeFee(_sender, shareAddress, fundAddress, _amount.mul(5).div(100));// add trade fee log
        }
    }

    // ================= White Operation ===============

    function setAddressList(address _shareAddress,address _fundAddress) public onlyOwner returns (bool) {
        fundAddress = _fundAddress;
        shareAddress = _shareAddress;
        emit AddressList(msg.sender, _shareAddress, _fundAddress);
        return true;
    }

    function addFromWhiteListAddress(address _fromWhiteListAddress,bool _value) public onlyOwner returns (bool) {
        fromWhiteListAddress[_fromWhiteListAddress] = _value;
        emit FromWhiteList(msg.sender, _fromWhiteListAddress, _value);
        return true;
    }

    function fromWhiteListAddressOf(address _fromWhiteListAddress) public view returns (bool) {
        return fromWhiteListAddress[_fromWhiteListAddress];
    }

    function addToWhiteListAddress(address _toWhiteListAddress,bool _value) public onlyOwner returns (bool) {
        toWhiteListAddress[_toWhiteListAddress] = _value;
        emit ToWhiteList(msg.sender, _toWhiteListAddress, _value);
        return true;
    }

    function toWhiteListAddressOf(address _toWhiteListAddress) public view returns (bool) {
        return toWhiteListAddress[_toWhiteListAddress];
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