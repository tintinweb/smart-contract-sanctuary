pragma solidity ^0.6.12;
/*
 * SPDX-License-Identifier: MIT
 */


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract Oracled is Owned {
    address[] public oracles;
    uint public maxOracles = 50;

    modifier onlyOracle {
        bool haveAddress = false;

        for (uint i=0; i<oracles.length; i++){
            if (oracles[i] == msg.sender){
                haveAddress = true;
                break;
            }
        }

        require(haveAddress, "Account is not a registered oracle");

        _;
    }

    function regOracle(address _newOracle) public onlyOwner {
        bool emplaced = false;
        for (uint i=0; i<oracles.length; i++){
            if (oracles[i] == 0x0000000000000000000000000000000000000000){
                oracles[i] = _newOracle;
                emplaced = true;
                break;
            }
        }
        if (!emplaced){
            require(oracles.length < maxOracles, "Registering oracle would exceed maximum");

            oracles.push(_newOracle);
        }
    }

    function unregOracle(address _remOracle) public onlyOwner {
        for (uint i=0; i<oracles.length; i++){
            if (oracles[i] == _remOracle){
                delete oracles[i];
                break;
            }
        }
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply, added teleport method
// ----------------------------------------------------------------------------
contract TeleportToken is ERC20Interface, Owned, Oracled {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public threshold;

    mapping(address => uint) balances;
    mapping(uint256 => mapping(address => uint)) public requests;  // number of oracles who have approved this request
    mapping(uint256 => address[]) public approvals;  // addresses of oracles who have approved this request
    mapping(address => mapping(address => uint)) allowed;
    mapping(uint256 => bool) completed;

    event Teleport(address indexed from, string to, uint tokens);
    event Received(address to, uint256 ref, uint tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "TLM";
        name = "Alien Worlds Trilium";
        decimals = 4;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[address(0)] = _totalSupply;
        threshold = 3;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() override public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) override public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) override public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) override public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Moves tokens to the inaccessible account and then sends event for the oracles
    // to monitor and issue on other chain
    // to : EOS address
    // tokens : number of tokens in satoshis
    // ------------------------------------------------------------------------

    function teleport(string memory to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[address(0)] = balances[address(0)].add(tokens);
        emit Teleport(msg.sender, to, tokens);

        return true;
    }


    // ------------------------------------------------------------------------
    // Called by the oracles to move tokens from inaccessible to accessible
    // reference is the txid on the other chain
    // ------------------------------------------------------------------------

    function received(address to, uint256 ref, uint tokens) public onlyOracle returns (bool success) {
        requests[ref][to]++;

        if (requests[ref][to] >= threshold && !completed[ref]){  // 3 confirmations required
            balances[address(0)] = balances[address(0)].sub(tokens);
            balances[to] = balances[to].add(tokens);
            delete requests[ref][to];

            completed[ref] = true;

            emit Received(to, ref, tokens);
            emit Transfer(address(0), to, tokens);
        }

        return true;
    }

    function updateThreshold(uint newThreshold) public onlyOwner returns (bool success) {
        if (newThreshold > 0){
            threshold = newThreshold;

            return true;
        }

        return false;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive () external payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}