pragma solidity ^0.8.9;

import './SafeMath.sol';
import './ERC20Interface.sol';
import './ApproveAndCallFallBack.sol';

contract BustaCoin is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint256 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        symbol = "BST";
        name = "Busta Coin";
        decimals = 8;
        //you have to add 8 additional 0 for the decimals since I picked 8 decimals
        _totalSupply = 100000000000000;

        //my ropsten testnet metamask address
        balances[0x014Da1D627E6ceB555975F09D26B048644382Ac6] = _totalSupply;
        emit Transfer(address(0), 0x014Da1D627E6ceB555975F09D26B048644382Ac6, _totalSupply);
    }


    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
 
    fallback() external payable {
        revert();
    }
}