pragma solidity ^0.5.0;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol" ;

contract WIKI is Ownable {
    using SafeMath for uint256;

    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // TransferBurn
    mapping(address => bool)  private pancakePairAddress;
    uint256 private tradeFeeTotal;

    uint256 public holdTotalCount;
    mapping(uint256 => address) private holdAddress;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TradeFee(address indexed _fromAddress, uint256 _fee);
    event PancakePairAddress(address indexed _sender, address indexed _pancakePairAddress,bool _value);
    event HoldTotalCount(address indexed _sender, uint256 _holdTotalCount, address _holdAddress);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "WIKI";
        _symbol = "WIKI";
        _decimals = 18;
        _totalSupply = 31000000000000000000000000;// 31000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply;
    }

    // ================= Special transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");

        if(pancakePairAddressOf(_recipient)){
            require(_amount.add(_amount.mul(15).div(100)) <= balances[_sender],"ERC20: transfer amount exceeds balance");

            balances[_sender] -= _amount.add(_amount.mul(15).div(100));// sell ==>  user 115%
            balances[_recipient] += _amount;// pancakePair 100%
            emit Transfer(_sender, _recipient, _amount);

            balances[address(0)] += _amount.mul(5).div(100);
            emit Transfer(_sender,address(0),_amount.mul(5).div(100));

            _toHoldList(_sender,_amount.mul(10).div(100));

            tradeFeeTotal += _amount.mul(15).div(100);
            emit TradeFee(_sender, _amount.mul(15).div(100));// add trade fee log
        }else{
            balances[_sender] -= _amount;
            balances[_recipient] += _amount;
            emit Transfer(_sender, _recipient, _amount);
        }
    }

    function _toHoldList(address _sender, uint256 _holdAmount) internal {
        for(uint256 i = 1;i<= holdTotalCount; i++){
            balances[holdAddress[i]] += _holdAmount.div(holdTotalCount);
            emit Transfer(_sender, holdAddress[i], _holdAmount.div(holdTotalCount));
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

    function addHoldAddress(address _holdAddress) public onlyOwner returns (bool) {
        require(holdTotalCount < 21, "-> holdTotalCount: The maximum number of additions has been reached.");
        holdTotalCount += 1;
        holdAddress[holdTotalCount] = _holdAddress;
        emit HoldTotalCount(msg.sender, holdTotalCount, _holdAddress);
        return true;
    }

    function addPancakePairAddress(address _pancakePairAddress,bool _value) public onlyOwner returns (bool) {
        pancakePairAddress[_pancakePairAddress] = _value;
        emit PancakePairAddress(msg.sender, _pancakePairAddress, _value);
        return true;
    }

    function pancakePairAddressOf(address _pancakePairAddress) public view returns (bool) {
        return pancakePairAddress[_pancakePairAddress];
    }

    function getTradeFeeTotal() public view returns (uint256) {
        return tradeFeeTotal;
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