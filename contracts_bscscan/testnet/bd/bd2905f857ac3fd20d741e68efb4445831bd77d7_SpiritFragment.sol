pragma solidity ^0.5.0;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol" ;
import "./SafeERC20.sol";

contract SpiritFragment is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "SpiritFragment";
        _symbol = "SpiritF";
        _decimals = 0;
        _totalSupply = 100000;// 2.1_00000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply;
        emit Transfer(address(this), _initial_account, _totalSupply);
    }

    function mint(address _account, uint256 _amount) public onlyOwner returns (bool) {
       require(_account != address(0), "ERC20: mint to the zero address");

       _totalSupply = _totalSupply.add(_amount);
       balances[_account] = balances[_account].add(_amount);
       emit Transfer(address(this), _account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
       require(_account != address(0), "ERC20: burn from the zero address");

       balances[_account] = balances[_account].sub(_amount, "ERC20: burn amount exceeds balance");
       _totalSupply = _totalSupply.sub(_amount);
       emit Transfer(_account, address(this), _amount);
     }

    // ================= Fee transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");

        balances[_sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
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