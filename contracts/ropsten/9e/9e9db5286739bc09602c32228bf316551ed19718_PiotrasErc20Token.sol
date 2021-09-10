/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.4.25;

/**

 /$$$$$$$  /$$             /$$                                 
| $$__  $$|__/            | $$                                 
| $$  \ $$ /$$  /$$$$$$  /$$$$$$    /$$$$$$  /$$$$$$   /$$$$$$$
| $$$$$$$/| $$ /$$__  $$|_  $$_/   /$$__  $$|____  $$ /$$_____/
| $$____/ | $$| $$  \ $$  | $$    | $$  \__/ /$$$$$$$|  $$$$$$ 
| $$      | $$| $$  | $$  | $$ /$$| $$      /$$__  $$ \____  $$
| $$      | $$|  $$$$$$/  |  $$$$/| $$     |  $$$$$$$ /$$$$$$$/
|__/      |__/ \______/    \___/  |__/      \_______/|_______/ 
                                                                                                 
Version in which tokens are created only with mint function so the totalSupply is the current existing number of tokens,
on the begining it will be 0 and with every mint it will increase the value, and of course decrease on burnt down.                                                                                                                                                                                  
 */

contract Erc20Token {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PiotrasErc20Token is Erc20Token {
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

    function transfer(address to, uint value) public returns (bool success){
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(_allowance[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");

        _allowance[from][msg.sender] -= value;
        _transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        _allowance[msg.sender][spender] = value;
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