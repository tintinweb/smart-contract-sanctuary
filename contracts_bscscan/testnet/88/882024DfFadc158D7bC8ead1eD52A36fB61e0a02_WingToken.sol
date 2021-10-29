// SPDX-License-Identifier: NONE
pragma solidity ^0.8.4;

import "./interfaces/IERC20.sol";
import "./utilities/Ownable.sol";

contract WingToken is IERC20, Ownable {
    uint256   public override totalSupply;
    uint8     public override decimals     = 18;
    string    public override symbol       = "WING";
    string    public override name         = "WingDapp Token";

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    function getOwner() external override view returns (address) { return owner; }

    function balanceOf(address _account) external override view returns (uint256) {
        return _balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external override view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        require(_allowances[_sender][msg.sender] >= _amount, 'ERC20: Insufficient allowance for transfer');
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, _allowances[_sender][msg.sender] - _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] - _subtractedValue);
        return true;
    }

    function mint(uint256 _amount) public onlyOwner returns (bool) {
        _mint(msg.sender, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: Cannot transfer from the zero address");
        require(_recipient != address(0), "ERC20: Cannot transfer to the zero address");

        _balances[_sender] = _balances[_sender] - _amount;
        _balances[_recipient] = _balances[_recipient] + _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "ERC20: Cannot mint to the zero address");

        totalSupply = totalSupply + _amount;
        _balances[_account] = _balances[_account] + _amount;
        emit Transfer(address(0), _account, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: Cannot approve from the zero address");
        require(_spender != address(0), "ERC20: Cannot approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: Caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}