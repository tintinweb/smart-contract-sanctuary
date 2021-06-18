/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Token20 is IERC20, Ownable {
    
    string private _symbol;
    string private  _name;
    uint8 private _decimals;
    uint private _totalSupply;
    uint private _currentSupply;
    mapping(address => uint) private userBalance;
    mapping(address => mapping(address => uint)) private allowances;
    
    
    constructor() {
        _symbol = "LC";
        _name = "LakhoCoin";
        _decimals = 2;
        _totalSupply = 100 * (10**_decimals);
        _currentSupply = 0;
        mint(0x4179bc5D284d30e6d0298FCaB7f6Eb9924275afe, 1000);
        mint(0xB8C8Ea3A44291F4645d47C56bFA09F02364C6670, 1000);
    }
    
    
    function mint(address to, uint amount) public onlyOwner {
        require(to != address(0), "ERC20: mint to the zero address");
        require(_currentSupply <= _totalSupply, "ERC20: Total supply already minted!");
        _currentSupply += amount;
        userBalance[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function burn(address from, uint amount) public  {
        require(msg.sender == from || msg.sender == owner(), "ERC20: Can only burn your own tokens");
        require(from != address(0), "ERC20: zero address cannot burn");
        require(userBalance[from] >= amount, "ERC20: Cannot burn more than you own!");
        _currentSupply -= amount;
        userBalance[from] -= amount;
        emit Transfer(from, address(0), amount);
    }
    
    function name() external view returns (string memory) {
        return _name;   
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }
    
    function currentSupply() external view returns (uint256) {
        return _currentSupply;
    }
    
    function balanceOf(address _owner) external override view returns (uint256) {
        return userBalance[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _amount) external override returns (bool) {
        require(userBalance[_from] >= _amount, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _amount, "Insufficient allowance");
        
        userBalance[_from] -= _amount;
        userBalance[_to] += _amount;
        allowances[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function transfer(address _to, uint256 _amount) external override returns (bool) {
        require(userBalance[msg.sender] >= _amount, "Insufficient balance");
        
        userBalance[msg.sender] -= _amount;
        userBalance[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    
    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) external override view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
}