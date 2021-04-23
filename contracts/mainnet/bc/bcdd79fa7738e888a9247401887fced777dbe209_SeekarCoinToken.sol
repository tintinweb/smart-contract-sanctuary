/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.24;

//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
//  Symbol          :   SEEK
//  Name            :   SeekarCoin
//  Total Supply    :   1000000
//  Decimals        :   3
//  Author          :   Kordel Kade France
//  Author Account  :   0xDeD6FaE6e3BDB4F86cf692Dc35884B946a7CcE88
//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------

contract SafeMath {

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function buy() payable public returns (uint256 amount);
    function sell(uint256 _amount) public payable returns (uint256 revenue);
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address buyer) public constant returns (uint remaining);
    function transfer(address buyer, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address owner, address buyer, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Sell(uint256 _amount, uint256 revenue, uint256 priceOfOneTokenInWei, address indexed seller, address);
    event Buy(uint256 amount, uint256 priceOfOneTokenInWei, address indexed buyer);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract SeekarCoinToken is ERC20Interface, SafeMath {

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public price;
    uint256 public priceOfOneTokenInWei;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "SEEK";
        name = "SeekarCoin";
        decimals = 3;
        _totalSupply = 1000000000;
        priceOfOneTokenInWei = 1000000000000;
        balances[0xDeD6FaE6e3BDB4F86cf692Dc35884B946a7CcE88] = _totalSupply;
        emit Transfer(address(0), 0xDeD6FaE6e3BDB4F86cf692Dc35884B946a7CcE88, _totalSupply);
        // selfdestruct(0xDeD6FaE6e3BDB4F86cf692Dc35884B946a7CcE88);
    }
    
    function getPrice() public returns(uint256 priceOfOneTokenInWei) {
        uint256 oneCent = 1000000;
        return safeDiv(safeMul(priceOfOneTokenInWei, oneCent), 10000000000000000);
    }
    

    function buy() payable public returns (uint256 amount) {
        uint256 priceOfOneTokenInWei = getPrice();
        amount = msg.value / priceOfOneTokenInWei;
        transfer(msg.sender, amount);
        emit Buy(amount, priceOfOneTokenInWei, msg.sender);
        return amount;
    }
    
    
    //revenue — ether; amount — tokens
    function sell(uint256 _amount) public payable returns (uint256 revenue) {
        uint256 priceOfOneTokenInWei = getPrice();
        revenue = _amount * priceOfOneTokenInWei;
        require(msg.sender.send(revenue));
        transfer(msg.sender, _amount);
        emit Sell(_amount, revenue, priceOfOneTokenInWei, msg.sender, address(this));
        return revenue;
    }
    
    
    // total supply on blockchain
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // account tokenOwner total token balance
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // transfer balance from tokenOwner account to receiving account
    // owner account must have sufficient balance to transfer
    // transfers of 0-value are allowed
    function transfer(address buyer, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[buyer] = safeAdd(balances[buyer], tokens);
        emit Transfer(msg.sender, buyer, tokens);
        return true;
    }

    // token owner can approve spender to initiate a transferFrom()
    // this transfers tokens from token owner account
    function approve(address spender, uint tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // transfer tokens from account to account
    // calling account must already have sufficient tokens approve() - d
    // for spending from the account and the following:
    //  - spending account must have sufficient balance to transfer
    //  - buyer must have sufficient allowance to transfer
    //  - 0 value transfers are allowed
    function transferFrom(address owner, address buyer, uint tokens) public returns (bool success) {
        require(tokens <= balances[owner]);
        require(tokens <= allowed[owner][msg.sender]);

        balances[owner] = safeSub(balances[owner], tokens);
        allowed[owner][msg.sender] = safeSub(allowed[owner][msg.sender], tokens);
        balances[buyer] = safeAdd(balances[buyer], tokens);
        emit Transfer(owner, buyer, tokens);
        return true;
    }

    // returns the amount of tokens approved by the owner
    // that can be transfered from buyer account.
    function allowance(address tokenOwner, address buyer) public constant returns (uint remaining) {
        return allowed[tokenOwner][buyer];
    }


    // token owner can approve for buyer to transferFrom() tokens from token owner account
    // buyer contract function receiveApproval() is then executed
    function approveAndCall(address buyer, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][buyer] = tokens;
        emit Approval(msg.sender, buyer, tokens);
        ApproveAndCallFallBack(buyer).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // accept no ETH
    function () public payable {
        revert();
    }
}