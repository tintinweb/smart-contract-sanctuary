//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./interfaces/IERC20.sol";
import "./initializer.sol";
import "./ownable.sol";

contract ERC20Upgradable is IERC20, initializer, Ownable{
    uint256 private _totalSupply;

    mapping(address=>uint256) private _balances;
    mapping(address => mapping(address=> uint256)) private _allowances;

    string private name;
    string private symbol;
    uint256 private decimal;

    event Mint(address indexed to, uint256 value);
    
    function getname() external view returns(string memory){
        return name;
    }
    
    function getsymbol() external view returns(string memory){
        return symbol;
    }
    
    function getdecimal() external view returns(uint256){
        return decimal;
    }

    function init(string memory _name, string memory _symbol, uint256 _decimal) external initialized{
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        init_owner(msg.sender);
    }

    function _mint(address to, uint256 value) internal {
        _totalSupply += value;
        _balances[to] += value;
        emit Mint(to, value);
    }

    function mint(address to, uint256 value) external returns (bool) {
        _mint(to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(_balances[from] >= value, "Not enough balance");
        require(to != address(0), "transfer to 0");

        _balances[from] -= value;
        _balances[to] += value;

        emit Transfer(from, to, value);
    }
        
    function _approval(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function transfer(address to, uint256 value) external override returns (bool){
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool){
        _approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool){

    }
    function totalSupply() external view override returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address who) external view override returns (uint256){
        return _balances[who];
    }
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
    }

    fallback() external payable{
        _mint(msg.sender, msg.value * 150);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract initializer{
    bool isinitialized;

    modifier initialized(){
        require(!isinitialized);

        isinitialized = true;
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract Ownable{
    address internal owner;

    event ChangeOnwer(address indexed oldowner, address indexed newowner);

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function init_owner(address _owner) internal {
        require(owner == address(0), "already has owner");
        owner = _owner;
    }

    function setOwner(address newOwner) external onlyOwner{
        address oldowner = owner;
        owner = newOwner;
        emit ChangeOnwer(oldowner, owner);
    }

    function getOwner() external view returns(address){
        return owner;
    }
}

