/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity 0.6.0;

// ----------------------------------------------------------------------------
// 'Simurg' token contract
//
// Deployed to : 0x813e08aE6df34d19c69A1c52DcBAa5730E973E9E
// Symbol      : SMR
// Name        : Simurg share
// Total supply: 1000000000
// Decimals    : 18
//
// 
//
// (c) by Ahiwe Onyebuchi Valentine.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
abstract contract ERC20 {
            function totalSupply() public virtual returns (uint theTotalSupply);
            function balanceOf(address _owner) public virtual returns (uint balance);
            function transfer(address _to, uint _value) public virtual returns (bool success);
            function transferFrom(address _from, address _to, uint _value) public virtual returns (bool success);
            function approve(address _spender, uint _value) public virtual returns (bool success);
            function allowance(address _owner, address _spender) public virtual returns (uint remaining);
            event Transfer(address indexed _from, address indexed _to, uint _value);
            event Approval(address indexed _owner, address indexed _spender, uint _value);
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

contract SpeadTheGainContract{
    uint public _totalSupply;
    mapping(address => uint) public balances;
    uint public indexedAddressesCounter = 0;
    mapping(address=>bool) ifAdressExisted;
    mapping(uint=>address) ownersAddresses;
    uint requiredAmount = 1 wei;
    
    function spreadTheGain() external payable{
        require(msg.value >= requiredAmount, "Can't send 0 value!");
        for (uint i = 0; i < indexedAddressesCounter; i++){
            payable(ownersAddresses[i]).transfer(address(this).balance*(balances[ownersAddresses[i]]/_totalSupply));
        }
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract simurgShare is ERC20, Owned, SafeMath, SpeadTheGainContract {
    string public symbol;
    string public  name;
    uint8 public decimals;
    
    
    mapping(address => mapping(address => uint)) allowed;
    
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public{
        symbol = "SMR";
        name = "Simurg share";
        decimals = 18;
        _totalSupply =  1000000000000000000000000000;
        ownersAddresses[0] = msg.sender;
        ifAdressExisted[msg.sender] = true;
        indexedAddressesCounter ++;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    
    /*
    My shares special functions
    */
    function showOwners() public view returns(address[] memory){
        address[] memory returnResult = new address[](indexedAddressesCounter);
        for (uint i = 0; i < indexedAddressesCounter; i++){
            returnResult[i] = ownersAddresses[i];
        }
        return returnResult;
    }

    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        if (ifAdressExisted[to] == false){
            ownersAddresses[indexedAddressesCounter] = to;
            ifAdressExisted[to] = true;
            indexedAddressesCounter ++;
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    // function () external payable {
    //     revert();
    // }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}