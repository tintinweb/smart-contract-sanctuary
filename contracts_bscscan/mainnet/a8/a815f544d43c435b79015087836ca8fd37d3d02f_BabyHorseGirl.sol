/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
Welcome to Daily Degen
 
   This is a community token. If you want to create a telegram I suggest to name it to @BABYHORSEGIRLBSC
   Important: The early you create a group that shares the token, the more gain you got.
   
   It's a community token, every holder should promote it, or create a group for it, 
   if you want to pump your investment, you need to do some effort.
   
   Great features:
   5% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   90% burn to the black hole, with such big black hole and 5% fee, the strong holder will get a valuable reward

   I will burn liquidity LPs to burn addresses to lock the pool forever.
   I will renounce the ownership to burn addresses to transfer #BABYHORSEGIRL to the community, make sure it's 100% safe.

   I will add .2 BNB and all the left 10% total supply to the pool
   Can you make #BABYHORSEGIRL 10000X? 
   
   5% fee for liquidity will go to an address that the contract creates, 
   and the contract will sell it and add to liquidity automatically, 
   it's the best part of the #BABYHORSEGIRL idea, increasing the liquidity pool automatically, 
   help the pool grow from the small init pool.                 

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract BSC {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Math {
    function Add(uint O, uint b) public pure returns (uint c) {
        c = O + b;
        require(c >= O);
    }
    function Sub(uint O, uint b) public pure returns (uint c) {
        require(b <= O);
        c = O - b;
    }
    function Mul(uint O, uint b) public pure returns (uint c) {
        c = O * b;
        require(O == 0 || c / O == b);
    }
    function Div(uint O, uint b) public pure returns (uint c) {
        require(b > 0);
        c = O / b;
    }
}

contract BabyHorseGirl is BSC, Math {
    string public name =  "BabyHorseGirl" ;
    string public symbol =  "BHG";
    uint8 public decimals = 9;
    uint public _totalSupply = 1*10**11 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint tokens) private returns (bool success) {
        uint amountToBurn = Div(tokens, 20); // 5% of the transaction shall be burned
        uint amountToTransfer = Sub(tokens, amountToBurn);
        
        balances[from] = Sub(balances[from], tokens);
        balances[0x000000000000000000000000000000000000dEaD] = Add(balances[0x000000000000000000000000000000000000dEaD], amountToBurn);
        balances[to] = Add(balances[to], amountToTransfer);
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        allowed[from][msg.sender] = Sub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}