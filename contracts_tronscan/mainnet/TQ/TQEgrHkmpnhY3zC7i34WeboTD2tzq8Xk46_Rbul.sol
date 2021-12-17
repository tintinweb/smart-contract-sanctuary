//SourceUnit: ContractDetail.sol

pragma solidity ^0.5.0;

import "./ITRC.sol";

contract ContractDetail is ITRC {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



//SourceUnit: ITRC.sol

pragma solidity ^0.5.0;

interface ITRC {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: Rbul.sol

pragma solidity ^0.5.0;

import "./TRC.sol";
import "./ContractDetail.sol";

contract Rbul is TRC, ContractDetail {
    constructor (uint256 _totalSupply) public ContractDetail("Rbul", "RUD", 6) {
        _mint(msg.sender, _totalSupply);
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

//SourceUnit: TRC.sol

pragma solidity ^0.5.0;

import "./ITRC.sol";
import "./SafeMath.sol";

contract TRC is ITRC {

    string _m_success = "Txn Success";
    string _m_auth = "Sender not authorized.";

    address private currentOwnerAddress;

    address public firstOwnerAddressFirst = msg.sender;

    uint256 private _totalSupply;

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() public{
        currentOwnerAddress = msg.sender;
    }

    modifier onlyOwner(address _account){
        require(msg.sender == _account, _m_auth);
        _;
    }

    modifier onlyAfter(uint _time) {
      require(now >= _time,"Function called too early.");
      _;
    }

    function changeOwner(address _newOwner) public returns (string memory) {
        if(msg.sender == currentOwnerAddress) {
            currentOwnerAddress = _newOwner;
            return _m_success;
        } else {
            return _m_auth;
        }
    }

    function _connectedAddress() public view returns (address) {
        return msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _currentOwner() public view returns (address) {
        return currentOwnerAddress;
    }

    function _connectedAddressBalance() public view returns (uint256) {
        return _balances[msg.sender];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function burn(address account, uint256 value) public returns (string memory) {
        if(msg.sender == currentOwnerAddress) {
            _burn(account, value);
            return _m_success;
        } else {
            return _m_auth;
        }
    }

    function mint(address account, uint256 value) public returns (string memory) {
        if(msg.sender == currentOwnerAddress) {
            _mint(account, value);
            return _m_success;
        } else {
            return _m_auth;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        if(msg.sender == currentOwnerAddress) {
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
            emit Transfer(address(0), account, amount);
        }
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "Burn from the zero address");

        if(msg.sender == currentOwnerAddress) {
            _totalSupply = _totalSupply.sub(value);
            _balances[account] = _balances[account].sub(value);
            emit Transfer(account, address(0), value);
        }
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        if(msg.sender == currentOwnerAddress) {
            _burn(account, amount);
            _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
        }
    }
}