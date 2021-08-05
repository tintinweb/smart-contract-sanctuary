/**
 *Submitted for verification at Etherscan.io on 2020-11-13
*/

pragma solidity 0.7.1;

contract SimpleERC20Token {
    string public constant name = "inMatch token";
    string public constant symbol = "INM";
    uint8 public constant decimals = 3;
    uint256 public totalSupply = 0;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = 200000000000;  // 200m tokens
        totalSupply = 200000000000;  // 200m tokens
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= _allowances[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}