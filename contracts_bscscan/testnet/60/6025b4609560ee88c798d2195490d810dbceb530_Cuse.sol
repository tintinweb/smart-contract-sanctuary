pragma solidity ^0.5.0;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol" ;

contract Cuse is Ownable {
    using SafeMath for uint256;

    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // TransferBurn
    mapping(address => bool) private pancakePairAddress;
    address public shareAddress;
    uint256 public tradeFeeTotal;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event PancakePairAddress(address indexed _account, address _pancakePairAddress, bool _value);
    event TradeFee(address indexed _account, address _shareAddress, address _recipient, uint256 _tradeFee);
    event ShareAddress(address indexed _account, address _shareAddress);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "Cosmic journey";
        _symbol = "CUSE";
        _decimals = 18;
        _totalSupply = 1000000000000000000000000000;// 10_00000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply;
        emit Transfer(address(this), _initial_account, _totalSupply);
    }

    // ================= Special transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");

        if(pancakePairAddressOf(_recipient)){
            require(_amount.add(_amount.mul(6).div(100)) <= balances[_sender],"ERC20: transfer amount exceeds balance");

            balances[_sender] -= _amount.add(_amount.mul(6).div(100));// sell ==>  user 106%

            balances[_recipient] += _amount.add(_amount.mul(3).div(100));// pancakePair 103%
            emit Transfer(_sender, _recipient, _amount.add(_amount.mul(3).div(100)));

            balances[shareAddress] += _amount.mul(3).div(100);// shareAddress 3%
            emit Transfer(_sender, shareAddress, _amount.mul(3).div(100));

            tradeFeeTotal += _amount.mul(6).div(100);
            emit TradeFee(_sender, shareAddress, _recipient, _amount.mul(6).div(100));// add trade fee log
        }else{
            balances[_sender] -= _amount;
            balances[_recipient] += _amount;
            emit Transfer(_sender, _recipient, _amount);
        }
    }

    // ================= Pair Operation ===============

    function addPancakePairAddress(address _pancakePairAddress,bool _value) public onlyOwner returns (bool) {
        pancakePairAddress[_pancakePairAddress] = _value;
        emit PancakePairAddress(msg.sender, _pancakePairAddress, _value);
        return true;
    }

    function pancakePairAddressOf(address _pancakePairAddress) public view returns (bool) {
        return pancakePairAddress[_pancakePairAddress];
    }

    function setShareAddress(address _shareAddress) public onlyOwner returns (bool) {
        shareAddress = _shareAddress;
        emit ShareAddress(msg.sender, _shareAddress);
        return true;
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