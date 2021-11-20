// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is Context,IERC20 {
    using SafeMath for uint256;

    uint256 public override totalSupply;
    
    mapping (address => uint256) public activeBalances;
    
    mapping (address => uint256) public frozenBalances; //冻结余额
    mapping (address => uint256) public froTimestamp;
    mapping (address => uint256) public unlocknum;
    
    mapping (address => mapping (address => uint256)) private allowances;

    
    function balanceOf(address _who) public view virtual override returns (uint256) {
         return activeBalances[_who] + frozenBalances[_who];
    }
 
    function transfer(address _to, uint _amount) public virtual override returns (bool) {
        _transfer(_msgSender(), _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        _transfer(_from, _to, _amount);
        _approve(_from, _msgSender(), allowances[_from][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
        _approve(_msgSender(), _spender, allowances[_msgSender()][_spender].add(_value));
        return true;
    }
    
    function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
        _approve(_msgSender(), _spender, allowances[_msgSender()][_spender].sub(_value, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        activeBalances[_from] = activeBalances[_from].sub(_amount, "ERC20: transfer amount exceeds balance");
        activeBalances[_to] = activeBalances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
    
    function _mine(address _who, uint256 _amount) internal {
        require(_who != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.sub(_amount, "ERC20: amount exceeds totalSupply");
        activeBalances[_who] = activeBalances[_who].add(_amount);
        emit Transfer(address(this), _who, _amount);
    }
    
    function _approve(address _owner, address _spender, uint _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "SafeMath: division by zero");
    }
    
    function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

library Address {
    function isContract(address _account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }
}

contract Punk is ERC20 {
    using Address for address;
    using SafeMath for uint256;
  
    string public constant name = "Punk Coin";
    string public constant symbol = "punk";
    
    address public governance;
    address public founder;
    
    mapping (address => bool) public minters;
    
    event Allocate(address indexed _from, address indexed _to, uint256 value);

    constructor () {
        governance = _msgSender();
        founder =  address(0x16e945Ab70a5830F30123fD580D8C5C15d5EE645);  
        
        totalSupply = 850000000 * 1 ether;   // 85% will be ready for players
        frozenBalances[founder] = 100000000 * 1 ether;   //allocate 10% to team and be locked
        froTimestamp[founder] = block.timestamp;
        
        activeBalances[founder] = 50000000 * 1 ether;  //allocate 5% for ecosystem cooperation
    }

    function mine(address _who, uint _amount) public {
        require(_msgSender() == governance, "!governance");
        _mine(_who, _amount);
    }
    
    function allocate(address _who, uint _amount) public {
        require(_msgSender() == governance, "!governance");
        
        frozenBalances[founder] = frozenBalances[founder].sub(_amount, "ERC20: transfer amount exceeds balance");
        frozenBalances[_who] = frozenBalances[_who].add(_amount);
        froTimestamp[_who] = block.timestamp;
        emit Allocate(founder, _who, _amount);
    }
    
    function unlock() public {
        address sender = _msgSender();
        require(frozenBalances[sender] > 0, "no balance!");
        require(block.timestamp > (froTimestamp[sender] + 180 days), "at least 180 days!");
        
        uint256 period;
        uint256 counter;
        uint256 amount = 0;
        
        unlocknum[sender] = unlocknum[sender].add(1);
        counter = unlocknum[sender];
        period = block.timestamp.sub(froTimestamp[sender], "time mistake!");
       
        if (counter == 1) {
            amount = frozenBalances[sender] * 30 / 100;
        }
        
        if (counter == 2) {
            amount = frozenBalances[sender] * 50 / 100;
        }
        
        if (counter == 3) {
            amount = frozenBalances[sender] * 50 / 100;
        }
        
        if (counter == 4) {
            amount = frozenBalances[sender];
        }
        
        froTimestamp[sender] = froTimestamp[sender].add(180 days);
        frozenBalances[sender] = frozenBalances[sender].sub(amount, "ERC20: amount exceeds froBalance");
        activeBalances[sender] = activeBalances[sender].add(amount);

    }
  
    function setGovernance(address _new) public {
        require(msg.sender == governance, "!governance");
        governance = _new;
    }
 
}