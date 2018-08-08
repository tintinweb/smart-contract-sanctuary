pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;CDS&#39; token contract
//
// Symbol      : CDS
// Name        : Coin Dogs Share
// Total supply: 3000000
// Decimals    : 0
// Website     : www.CoinDogs.co
//
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
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //!!!! before acceptOwnership also transfer tokens from owner to newowner!!!!
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract CoinDogToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;

    uint public TotalSupply;
    uint public AmountToDistribute;

    uint256 public sellPrice;
    uint256 public buyPrice;


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function CoinDogToken() public {
        symbol = "CDS";
        name = "Coin Dogs Share";
        decimals = 0;
        TotalSupply = 3000000;
        setAmountToDistribute(TotalSupply/3);
        buyPrice = 1000000000000000000/400;
        owner = msg.sender;
        balances[this] = TotalSupply;
        emit Transfer(address(0), this, TotalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return TotalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function balanceOfTheContract() public constant returns (uint balance) {
        return balances[this];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        buy();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }





    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function setAmountToDistribute(uint amount) public onlyOwner {
        AmountToDistribute=amount;
    }

    function sendToken(address to, uint amount) public onlyOwner {
        sendToken_internal(to,amount);
    }

    function DistributedSoFar() public constant returns (uint tokens) {
        return TotalSupply-balances[this];
    }
    

    function sendToken_internal(address to, uint amount) internal {

        require(DistributedSoFar()+amount <= AmountToDistribute);

        balances[this] = safeSub(balances[this], amount);
        balances[to] = safeAdd(balances[to], amount);

        emit Transfer(this, to, amount);
    }

    function distributeTokens(address[] addresses, uint[] values) public onlyOwner {
         require(addresses.length==values.length && values.length>0);
         for (uint i = 0; i < addresses.length; i++) {
            sendToken_internal(addresses[i], values[i]);
         }
    }



    function buy() public payable returns (uint amount)  {
        require(buyPrice>0);

        amount = msg.value / buyPrice;                    // calculates the amount

        sendToken_internal(msg.sender, amount);

        return amount;                                    // ends function and returns
    }

    function sell(uint amount) public returns (uint revenue) {
        require(sellPrice>0);

        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[this] = safeAdd(balances[this], amount);


        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }




}