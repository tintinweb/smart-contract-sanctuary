/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity ^0.5.0;

//--------------------------------------
//  CRIPTORO Coin contract
//
// Symbol      : CTRO
// Name        : CRIPTORO COIN
// Total supply: 500000000
// Decimals    : 10
//--------------------------------------

contract ERC20Interface {
    function changeOwnership(address newOwner) public returns(bool success);
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function vestCollaboratorToken(address to, uint256 tokens) public returns (bool success);
    function collaboratorBalance(address addr) public view returns(uint256);
    function unvestCollaboratorToken(address addr) public returns(uint256);
    function claimVestingBenefits(address addr) public returns(bool);
    function burn(uint tokens) public  returns(bool success);
    
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address from, address, uint256 value);
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
        require(b <= a); 
        c = a - b; 
    }

    function safeMul(uint a, uint b) public pure returns (uint c){
    c = a * b; require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract CriptoRo is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private initialSupply;
    uint256 public _totalSupply;
    address public owner;
    uint six_month = 182;
    uint three_month = six_month / 2;
    uint nine_month = six_month + three_month;
    uint twelve_month = 365;
    uint fifteen_month = twelve_month + three_month;
    
    
    struct Incentive {
        uint256 amt;
	uint locktime;
	uint term; //To monitor claimed incentive details.
    }
//-------------------------------------------------------
//term = 1 => Claimed 6 months incentive
//term = 2 => Claimed 9 months incentive
//term = 3 => Claimed 12 months incentive
//term = 4 => Claimed 15 months incentive
//-------------------------------------------------------
    mapping(address => uint) balances;
    mapping(address => Incentive[]) vestStatus;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "CRIPTORO COIN";
        symbol = "CTRO";
        decimals = 10;
        _totalSupply = 500000000 * 10 ** uint256(decimals);
	    initialSupply = _totalSupply;
	    balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
 
    function changeOwnership(address newOwner) public returns(bool success){
          require(owner == msg.sender,'This is not owner');
          require(newOwner != address(0));
          owner = newOwner;
          return true;
        
    }
    function totalSupply() public view returns (uint) {
        return safeSub(_totalSupply, balances[address(0)]);
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
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
   function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
   }
   
   //// Admin sends amount to collaborator address
   function vestCollaboratorToken(address to, uint256 tokens) public returns (bool success){
            require(to != address(0));
            require(msg.sender == owner, "Its not owner");
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            vestStatus[to].push(Incentive(tokens, now, 0));
            emit Transfer(msg.sender, to, tokens);
            return true;
   }
    
    ////check the collaborator total balance
    function collaboratorBalance(address addr) public view returns(uint256) {
       Incentive[] memory balanceArray = vestStatus[addr];
       uint256 bal = 0;
       for(uint i=0; i<balanceArray.length; i++){
            bal = bal + balanceArray[i].amt;
        }
       return bal;
    }
    
    function calculateIncentive(uint256 bal, uint term, uint locktime) private view returns(uint256){
        uint daysPassed =  (  now - locktime) / 60 / 60 / 24;
        uint256 incentive = 0;
        if(daysPassed >= fifteen_month) {
            incentive = (bal * 25 * (4-term) / 100);
        }else if(daysPassed >= twelve_month) {
            incentive = (bal * 25 * (3-term) / 100);
        }else if(daysPassed >= nine_month) {
            incentive = (bal * 25 * (2-term) / 100);
        }else if(daysPassed >= six_month) {
            incentive = (bal * 25 * (1-term) / 100);
        }
        return incentive;
    }
    
    function unvestCollaboratorToken(address addr) public returns(uint256) {
          require(msg.sender == owner, "Its not owner");
         Incentive[] memory balanceArray = vestStatus[addr];
         uint256 bal = 0;
         uint256 incentive = 0;
         uint256 totalBalance = 0;
         for(uint i=0; i<balanceArray.length; i++){
            uint term = balanceArray[i].term;
            bal = bal + balanceArray[i].amt;
            incentive = incentive + calculateIncentive(bal, term, balanceArray[i].locktime);
         }
         totalBalance = safeAdd(bal, incentive);
         balances[owner] = safeSub(balances[owner], incentive);
         balances[addr] = safeAdd(balances[addr], totalBalance);
         delete vestStatus[addr];
         return totalBalance;
     }

     function claimVestingBenefits(address addr) public returns(bool) {
            Incentive[] memory balanceArray = vestStatus[addr];
            uint256 incentive = 0;
            uint256 bal = 0;
            for(uint i=0; i<balanceArray.length; i++){
                uint term = balanceArray[i].term;
                bal = bal + balanceArray[i].amt;
                if(term < 4) {
                    uint tempIncentive = calculateIncentive(bal, term, balanceArray[i].locktime);
                    if(tempIncentive != 0) {
                        balanceArray[i].term = safeAdd(balanceArray[i].term, 1);
                        incentive = incentive + tempIncentive;
                    }
                }
            }
            balances[owner] = safeSub(balances[owner], incentive);
            balances[addr] = safeAdd(balances[addr], incentive);
        
        return true;
     }

    //Owner burns the token exclusive reserveSupply
    function burn(uint tokens) public  returns(bool success){
        require(owner == msg.sender,'This is not owner');
        balances[msg.sender] = safeSub(balances[msg.sender],tokens);
        _totalSupply = safeSub(_totalSupply,tokens);
        emit Burn(msg.sender,address(0), tokens);
        return true;
    }
    
    
   }