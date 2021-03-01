/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// 'MJCoin' token contract
// (c) by Mario Brandinu, Santa Cruz España.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
abstract contract MJCInterface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    function buyToken(address payable sellerAddress, uint tokens) virtual payable public  returns (bool success);
    
   /* function getTokenName() virtual view public returns(string memory);
    function getTokenSymbol() virtual view public  returns (string memory);
    function getTokenDecimals() virtual view public  returns (uint8);*/
    
    // function CrowdsToSaleGet() virtual view public returns (address[] memory);
    // function CrowdsToSaleAdd(address artContract) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);
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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract MJCoin is MJCInterface {//, Owned, SafeMath 
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    address payable public  owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event FundTransfer(address seller, uint amount, bool isContribution);
    
    //address[] public CrowdsToSale;
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "MJC";
        name = "MaryJaneCoin";
        decimals = 0;
        _totalSupply = 1000000;
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    function addSupply(uint newTokens) public  returns (bool esito) {
        require(msg.sender == owner,"Solo il propritario puo aggiungere tokens");
        _totalSupply = _totalSupply + newTokens;
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
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
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        //balances[from] = safeSub(balances[from], tokens);
        balances[from] = balances[from] - tokens;
        //questa funzione permetta il ritiro dei token se l'asta non va in successo
        //rettifica momentanea ma poi attivare l'approvazione nel processo
       /* if(allowed[from][msg.sender]>0){
        allowed[from][msg.sender] = //safeSub(allowed[from][msg.sender], tokens);}*/
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
       // balances[to] = safeAdd(balances[to], tokens);
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
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
 /*   function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }*/
    
    function buyToken(address payable sellerAddress, uint tokens) payable public override returns (bool success) {//
        uint256 sellerBalance = balanceOf(sellerAddress);
        require(tokens <= sellerBalance, "Not enough tokens in the Seller reserve");
        balances[sellerAddress] = balances[sellerAddress] - tokens;
        balances[msg.sender] = balances[msg.sender] + tokens;
        emit Transfer(sellerAddress, msg.sender, tokens);
        sellerAddress.transfer(msg.value);
        
        emit Bought(msg.value);
        
        return true;
    }
    

}