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
    mapping(address => bool)  private pancakePairAddress;
    address public fcnFarmAddress;
    uint256 private tradeFeeTotal;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TradeFee(address indexed _fromAddress, address indexed _toAddress, uint256 _burnValue);
    event WhiteListAddress(address indexed _sender, address indexed _whiteAddress,string _type,bool _value);
    event FcnFarmAddress(address indexed _sender, address indexed _fcnFarmAddress);
    event PancakePairAddress(address indexed _sender, address indexed _pancakePairAddress,bool _value);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "FCN";
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

        if(pancakePairAddressOf(_recipient)){
            require(_amount.add(_amount.mul(15).div(100)) <= balances[_sender],"ERC20: transfer amount exceeds balance");

            balances[_sender] -= _amount.add(_amount.mul(15).div(100));// sell ==>  user 115%

            balances[_recipient] += _amount;// pancakePair 100%
            emit Transfer(_sender, _recipient, _amount);

            balances[fcnFarmAddress] += _amount.mul(15).div(100);// fcnFarmAddress 15%
            emit Transfer(_sender, fcnFarmAddress, _amount.mul(15).div(100));

            tradeFeeTotal += _amount.mul(15).div(100);
            emit TradeFee(_sender, fcnFarmAddress, _amount.mul(15).div(100));// add trade fee log

        }else if(pancakePairAddressOf(_sender)){
            balances[_sender] -= _amount;// buy ==>  pancakePair 100%

            balances[_recipient] += _amount.mul(90).div(100);// user 90%
            emit Transfer(_sender, _recipient, _amount.mul(90).div(100));

            balances[fcnFarmAddress] += _amount.mul(10).div(100);// fcnFarmAddress 10%
            emit Transfer(_sender, fcnFarmAddress, _amount.mul(10).div(100));

            tradeFeeTotal += _amount.mul(10).div(100);
            emit TradeFee(_sender, fcnFarmAddress, _amount.mul(10).div(100));// add trade fee log

        }else{
            balances[_sender] -= _amount;

            if(fromWhiteListAddressOf(_sender)==true||toWhiteListAddressOf(_recipient)==true){
                // TokenBurn 0%
                balances[_recipient] += _amount;
                emit Transfer(_sender, _recipient, _amount);
            }else{
                // TokenBurn 5% : to 0x00
                balances[_recipient] += _amount.mul(95).div(100);
                emit Transfer(_sender, _recipient, _amount.mul(95).div(100));

                balances[address(0)] += _amount.mul(5).div(100);
                emit Transfer(_sender,_recipient,_amount.mul(5).div(100));
            }
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

    function setFromWhiteListAddress(address _account,bool _value) public onlyOwner returns (bool) {
        fromWhiteListAddress[_account] = _value;
        emit WhiteListAddress(msg.sender,_account,"FromAddress",_value);
        return true;
    }

    function setToWhiteListAddress(address _account,bool _value) public onlyOwner returns (bool) {
        toWhiteListAddress[_account] = _value;
        emit WhiteListAddress(msg.sender,_account,"ToAddress",_value);
        return true;
    }

    function setFcnFarmAddress(address _fcnFarmAddress) public onlyOwner returns (bool) {
        fcnFarmAddress = _fcnFarmAddress;
        emit FcnFarmAddress(msg.sender, _fcnFarmAddress);
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