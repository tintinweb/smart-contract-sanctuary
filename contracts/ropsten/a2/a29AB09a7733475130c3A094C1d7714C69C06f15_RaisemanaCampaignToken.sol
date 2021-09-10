/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.4.25;

/**

 /$$$$$$$            /$$                                                                
| $$__  $$          |__/                                                                
| $$  \ $$  /$$$$$$  /$$  /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$  /$$$$$$$   /$$$$$$ 
| $$$$$$$/ |____  $$| $$ /$$_____/ /$$__  $$| $$_  $$_  $$ |____  $$| $$__  $$ |____  $$
| $$__  $$  /$$$$$$$| $$|  $$$$$$ | $$$$$$$$| $$ \ $$ \ $$  /$$$$$$$| $$  \ $$  /$$$$$$$
| $$  \ $$ /$$__  $$| $$ \____  $$| $$_____/| $$ | $$ | $$ /$$__  $$| $$  | $$ /$$__  $$
| $$  | $$|  $$$$$$$| $$ /$$$$$$$/|  $$$$$$$| $$ | $$ | $$|  $$$$$$$| $$  | $$|  $$$$$$$
|__/  |__/ \_______/|__/|_______/  \_______/|__/ |__/ |__/ \_______/|__/  |__/ \_______/

        Campaign: ---||---- 
        by ---||---
        v1.0                                                                                                                                                                                                                                                                    
 */

contract Owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "RAISEMANA: Only the contract owner is allowed to called requested function");
        _;
    }
}

contract Erc20Token is Owned {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public onlyOwner returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public onlyOwner returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract RaisemanaCampaignToken is Erc20Token {
    string public name;
    string public symbol;
    uint8 public constant decimals = 0;

    uint _totalSupply;
    mapping(address => uint) _balanceOf;
    mapping(address => mapping(address => uint)) _allowance;

    constructor(string tokenName, string tokenSymbol, uint maximumTotalSupply) public {
        name = tokenName;
        symbol = tokenSymbol;
        _totalSupply = maximumTotalSupply;
        _balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balanceOf[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowance[tokenOwner][spender];
    }

    function transfer(address to, uint value) public onlyOwner returns (bool success){
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public onlyOwner returns (bool success) {
        require(_allowance[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");
        _allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        require(spender == owner, "RAISEMANA: The only one autorized entity to have allowence for transfer tokens is Raisemana (owner))");
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function endOfTheCampaignContract(address tokenOwner) public onlyOwner returns (bool success) {
        require(tokenOwner != owner, "RAISEMANA: Cannot end campaign contract for the owner)");
        uint balance = _balanceOf[tokenOwner];
        _transfer(tokenOwner, msg.sender, balance);
        return true;
    }

    function _transfer(address from, address to, uint value) internal {
        require(to != 0x0, "ERC20: transfer to the zero address");
        require(_balanceOf[from] >= value, "ERC20: transfer amount exceeds balance");
        require(_balanceOf[to] + value >= _balanceOf[to], "ERC20: transfer amount exceeds balance");

        uint previousBalance = _balanceOf[from] + _balanceOf[to];
        _balanceOf[from] -= value;
        _balanceOf[to] += value;

        emit Transfer(from, to, value);
        assert(_balanceOf[from] + _balanceOf[to] == previousBalance);
    }
}