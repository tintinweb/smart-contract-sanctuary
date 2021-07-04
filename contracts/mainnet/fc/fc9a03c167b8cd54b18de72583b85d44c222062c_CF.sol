/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity ^0.5.10;

interface ISimpleERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function mint(address to, uint amount) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
}

contract CF is ISimpleERC20 {
    string public constant name = "GoldRise";
    string public constant symbol = "GOLDRISE";
    uint8 public constant decimals = 18;
    
    address public minter;
    mapping (address => uint) private _balances;

    event Transfer(address from, address to, uint amount);

    constructor() public {
        minter = msg.sender;
    }
    
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }    

    function mint(address to, uint amount) public {
        require(msg.sender == minter);
        require(amount > 0);
        _balances[to] += amount;
    }

    function transfer(address to, uint amount) public returns (bool) {
        require(amount <= _balances[msg.sender], "Insufficient balance.");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}