/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

/**
   ______                                                        ______                                                            ______                  ______               ____                       
 .~      ~. |`````````, ``..     ..'' |`````````, `````|`````  .~      ~.        .'. .`.       |         |             ..'''' |  .~      ~. `````|`````  .~      ~.  |    ..'' |            |..          | 
|           |'''|'''''      ``.''     |'''''''''       |      |          |     .'   `   `.     |         |          .''       | |                |      |          | |..''     |______      |  ``..      | 
|           |    `.           |       |                |      |          |   .'           `.   |         |       ..'          | |                |      |          | |``..     |            |      ``..  | 
 `.______.' |      `.         |       |                |       `.______.'  .'               `. `._______.' ....''             |  `.______.'      |       `.______.'  |    ``.. |___________ |          ``| 
        
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Matha1 {
    function Adda1(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function Suba1(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function Mula1(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function Diva1(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract CryptoMusicToken is ERC20Interface, Matha1 {
    string public name = "CryptoMusicToken";
    string public symbol = "CMT";
    uint8 public decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10**9;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool success) {
        uint256 amountToBurn = Diva1(tokens, 40); // 5% of the transaction shall be burned
        uint256 amountToTransfer = Suba1(tokens, amountToBurn);
        
        balances[from] = Suba1(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000000] = Adda1(balances[0x0000000000000000000000000000000000000000], amountToBurn);
        balances[to] = Adda1(balances[to], amountToTransfer);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        allowed[from][msg.sender] = Suba1(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}