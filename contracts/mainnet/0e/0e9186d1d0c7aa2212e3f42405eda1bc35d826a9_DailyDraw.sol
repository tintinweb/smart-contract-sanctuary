pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;Ethernational&#39; CROWDSALE token contract
//
// Deployed to : 0xD0FDf2ECd4CadE671a7EE1063393eC0eB90816FD
// Symbol      : EIT
// Name        : Ethernational
// Decimals    : 18
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
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
    address public dividendsAccount;

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
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    dividendsContract divC;
    
    function dividendsAcc(address _dividendsAccount) onlyOwner{
        divC = dividendsContract(_dividendsAccount);
        dividendsAccount = _dividendsAccount;
    }
    
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Ethernational is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public bonus1Ends;
    uint public bonus2Ends;
    uint public bonus3Ends;
    uint public endDate;
    uint public ETHinvested;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function Ethernational() public {
        symbol = "EIT";
        name = "Ethernational";
        decimals = 18;
        bonus1Ends = now + 1 weeks;
        bonus2Ends = now + 2 weeks;
        bonus3Ends = now + 4 weeks;
        endDate = now + 8 weeks;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function invested() constant returns (uint){
        return ETHinvested;
    }


    
    





    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        uint perc = ((balances[msg.sender] * 1000)/tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        divC.updatePaid(msg.sender,to,perc);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint perc = ((balances[from] * 1000)/tokens);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        divC.updatePaid(from,to,perc);
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // 500 ELG Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate && msg.value > 1000000000000000);
        uint tokens;
        if (now <= bonus1Ends) {
            tokens = msg.value * 1000;
        } else if (now <= bonus2Ends) {
            tokens = msg.value * 750;
        } else if (now <= bonus3Ends) {
            tokens = msg.value * 625;
        } else {
            tokens = msg.value * 500;
        }
        
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
        ETHinvested = ETHinvested + msg.value;
    }
    
    function buyEIT() public payable {
        require(now >= startDate && now <= endDate && msg.value > 1000000000000000);
        uint tokens;
        if (now <= bonus1Ends) {
            tokens = msg.value * 1000;
        } else if (now <= bonus2Ends) {
            tokens = msg.value * 750;
        } else if (now <= bonus3Ends) {
            tokens = msg.value * 625;
        } else {
            tokens = msg.value * 500;
        }
        
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
        ETHinvested = ETHinvested + msg.value;
    }
    
    
    function bonusInfo() constant returns (uint,uint){
        if (now <= bonus1Ends) {
            return (100, (bonus1Ends - now));
        } else if (now <= bonus2Ends) {
            return (50, (bonus2Ends - now));
        } else if (now <= bonus3Ends) {
            return (25, (bonus3Ends - now));
        } else {
            return (0, 0);
        }
    }
    
    function ICOTimer() constant returns (uint){
        if (now < endDate){
            return (endDate - now);
        }
    }
    



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}








contract dividendsContract is Owned{
    
    Ethernational dc;
    mapping(address => uint) paid;
    uint public totalSupply;
    uint public totalPaid;
    address public ICOaddress;
    
    function ICOaddress(address _t) onlyOwner{
        dc = Ethernational(_t);
        ICOaddress = _t;
        totalSupply = dc.totalSupply() / 1000000000000;
    }
    
    function() payable{
    }
    
    function collectDividends(address member) public returns (uint result) {
        require (msg.sender == member && dc.endDate() < now);
        uint Ownes = dc.balanceOf(member) / 1000000000000;
        uint payout = (((address(this).balance + totalPaid)/totalSupply)*Ownes) - paid[member];
        member.transfer(payout);
        paid[member] = paid[member] + payout;
        totalPaid = totalPaid + payout;
        return payout;
    }
    
    function thisBalance() constant returns (uint){
        return this.balance;
    }
    
    function updatePaid(address from, address to, uint perc) {
        require (msg.sender == ICOaddress);
        uint val = ((paid[from] * 1000000) / perc) / 1000;
        paid[from] = paid[from] - val;
        paid[to] = paid[to] + val;
    }
    
}







    
contract DailyDraw is Owned{
    

    
    bytes32 public number;
    uint public timeLimit;
    uint public ticketsSold;
    
    struct Ticket {
        address addr;
        uint time;
    }
    
    mapping (uint => Ticket) Tickets;

    function start(bytes32 _var1) public {
        if (timeLimit<1){
            timeLimit = now;
            number = _var1 ;
        }
    }

    function () payable{
        uint value = (msg.value)/10000000000000000;
        require (now<(timeLimit+86400));
            uint i = 0;
            while (i++ < value) {
                uint TicketNumber = ticketsSold + i;
                Tickets[TicketNumber].addr = msg.sender;
                Tickets[TicketNumber].time = now;
            } 
            ticketsSold = ticketsSold + value;
   }

    function Play() payable{
        uint value = msg.value/10000000000000000;
        require (now<(timeLimit+86400));
            uint i = 1;
            while (i++ < value) {
                uint TicketNumber = ticketsSold + i;
                Tickets[TicketNumber].addr = msg.sender;
                Tickets[TicketNumber].time = now;
            } 
            ticketsSold = ticketsSold + value;
   }


    function balances() constant returns(uint, uint time){
       return (ticketsSold, (timeLimit+86400)-now);
   }


    function winner(uint _theNumber, bytes32 newNumber) onlyOwner payable {
        require ((timeLimit+86400)<now && number == keccak256(_theNumber));
                
                uint8 add1 = uint8 (Tickets[ticketsSold/4].addr);
                uint8 add2 = uint8 (Tickets[ticketsSold/3].addr);
       
                uint8 time1 = uint8 (Tickets[ticketsSold/2].time);
                uint8 time2 = uint8 (Tickets[ticketsSold/8].time);
       
                uint winningNumber = uint8 (((add1+add2)-(time1+time2))*_theNumber)%ticketsSold;
                
                address winningTicket = address (Tickets[winningNumber].addr);
                
                uint winnings = uint (address(this).balance / 20) * 19;
                uint fees = uint (address(this).balance-winnings)/2;
                uint dividends = uint (address(this).balance-winnings)-fees;
                
                winningTicket.transfer(winnings);
                
                owner.transfer(fees);
                
                dividendsAccount.transfer(dividends);
                
                delete ticketsSold;
                timeLimit = now;
                number = newNumber;

    }

}







contract WeeklyDraw is Owned{
    

    
    bytes32 public number;
    uint public timeLimit;
    uint public ticketsSold;
    
    struct Ticket {
        address addr;
        uint time;
    }
    
    mapping (uint => Ticket) Tickets;

    function start(bytes32 _var1) public {
        if (timeLimit<1){
            timeLimit = now;
            number = _var1 ;
        }
    }

    function () payable{
        uint value = (msg.value)/100000000000000000;
        require (now<(timeLimit+604800));
            uint i = 0;
            while (i++ < value) {
                uint TicketNumber = ticketsSold + i;
                Tickets[TicketNumber].addr = msg.sender;
                Tickets[TicketNumber].time = now;
            } 
            ticketsSold = ticketsSold + value;
   }

    function Play() payable{
        uint value = msg.value/100000000000000000;
        require (now<(timeLimit+604800));
            uint i = 1;
            while (i++ < value) {
                uint TicketNumber = ticketsSold + i;
                Tickets[TicketNumber].addr = msg.sender;
                Tickets[TicketNumber].time = now;
            } 
            ticketsSold = ticketsSold + value;
   }


    function balances() constant returns(uint, uint time){
       return (ticketsSold, (timeLimit+604800)-now);
   }


    function winner(uint _theNumber, bytes32 newNumber) onlyOwner payable {
        require ((timeLimit+604800)<now && number == keccak256(_theNumber));
                
                uint8 add1 = uint8 (Tickets[ticketsSold/4].addr);
                uint8 add2 = uint8 (Tickets[ticketsSold/3].addr);
       
                uint8 time1 = uint8 (Tickets[ticketsSold/2].time);
                uint8 time2 = uint8 (Tickets[ticketsSold/8].time);
       
                uint winningNumber = uint8 (((add1+add2)-(time1+time2))*_theNumber)%ticketsSold;
                
                address winningTicket = address (Tickets[winningNumber].addr);
                
                uint winnings = uint (address(this).balance / 20) * 19;
                uint fees = uint (address(this).balance-winnings)/2;
                uint dividends = uint (address(this).balance-winnings)-fees;
                
                winningTicket.transfer(winnings);
                
                owner.transfer(fees);
                
                dividendsAccount.transfer(dividends);
                
                delete ticketsSold;
                timeLimit = now;
                number = newNumber;

    }

}