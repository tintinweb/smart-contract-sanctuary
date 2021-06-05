/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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


contract LakhoToken is IERC20 {
    
    string private _symbol;
    string private  _name;
    uint8 private _decimals;
    uint private _totalSupply;
    mapping(address => uint) private userBalance;
    mapping(address => mapping(address => uint)) private allowances;
    
    
    constructor(address creator) {
        _symbol = "LT";
        _name = "LakhoToken";
        _decimals = 1;
        _totalSupply = 10**2;
        userBalance[creator] = _totalSupply;
        emit Transfer(address(0), creator, _totalSupply);
        
    }
    
    function name() external view returns (string memory) {
        return _name;   
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
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