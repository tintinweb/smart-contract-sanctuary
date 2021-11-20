/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.4.25;


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
  

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


contract GlobalCommunityOne is ERC20Interface, SafeMath {
     struct User{
        uint unloc;
        uint divclass;
    }
    
     struct Userstat {
        
        uint status;
    }
    
    struct Userday {
        uint payday;
    }
    
    
    struct Userdis {
       address dis1;
       address dis2; 
    }
    
    struct Balancestatus{
        uint status;
    }
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public _totalSupply;
        
        
        uint public competitionisopen;
        uint public pricetoken;
        uint public divclass;
      mapping(address => Userstat) public stat;
      mapping(address => Userdis) public dis;
      mapping(address => Userday) public dayuser;
      mapping(address => Balancestatus) public balstat;
      mapping(address => User) public users;
      mapping(address => uint) balances;
      mapping(address => mapping(address => uint)) allowed;
        address public owner;
        address public thistoken;
        address public token1;
      event ownershipTransferred(address indexed previousowner, address indexed newowner);
      
      event token1Transferred(address indexed token1, address indexed newtoken1);
      event paydaytransfered(uint newpaydey);
      event pricetokenTransfer(uint pricetoken, uint newpricetoken);
      event divclassTransfer(uint divclass, uint newdivclass);
      event thistokenTransfer(address thistoken, address newthistoken);
      
    
     constructor() public {
        name = "NewTokens";
        symbol = "NTS";
        decimals = 18;
        _totalSupply = 1700000000000;
        
        divclass = 7;
        pricetoken = 5400;
        
        
        owner = msg.sender;
        thistoken = 0xAD959861c5544641378357deC0404f89d5C1188F;
        token1 = 0xe222d8838DC980A810911B9baab17725bdc0E0CB;
      
      
    }

     function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
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
        uint day = now;
        uint unlocday = users[msg.sender].unloc;
        if(to == thistoken) {
        require (day >= unlocday);
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        GlobalCommunityOne(token1).transfer(msg.sender, tokens);
        } 
        else  {
        require(tokens == 1000000000000000000);
        require(stat[to].status <= 0);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
         
        address sender = to;
        address dis1 = msg.sender;
        address dis2 = dis[dis1].dis1;
        uint status = stat[msg.sender].status + 1;
        
        Userdis memory newDis;
        newDis.dis1 = dis1;
        newDis.dis2 = dis2;
        dis[sender] = newDis;
        
        
        
        Userstat memory newStatus;
        newStatus.status = status;
        stat[sender] = newStatus;
        }
        return true;
    }
    
     function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    
     function transferpricetoken(uint newpricetoken) public onlyOwner {
        emit pricetokenTransfer(pricetoken, newpricetoken);
        pricetoken = newpricetoken;
    }
    
     function divclassTransfereds(uint newdivclass) public onlyOwner {
        emit divclassTransfer(divclass, newdivclass);
        divclass = newdivclass;
    }
     function transferowner(address newowner) public onlyOwner {
        require(newowner != address(0));
        emit ownershipTransferred(owner, newowner);
        owner = newowner;
    }
    
    
    
    
    
     function thistokenTransfereds(address  newthistoken) public onlyOwner {
        require(newthistoken != address(0));
        emit thistokenTransfer(thistoken, newthistoken);
        thistoken = newthistoken;
    }
     function transftoken1(address  newtoken1) public onlyOwner {
        require(newtoken1 != address(0));
        emit token1Transferred(token1, newtoken1);
        token1 = newtoken1;
    }
    
    
    
    
     function () external payable  {
        address workuser = msg.sender;
        address usernewday = msg.sender;
        
        uint start = msg.value * pricetoken;
        
        address onepay = dis[msg.sender].dis1;
        address twopay = dis[msg.sender].dis2;
        uint oneval = start / 10;
        uint twoval = start / 20;
        
        if(msg.value <= 1000000000000000){
            userinvback(workuser);
        }
          
    
        
        balances[msg.sender] = balances[msg.sender] + start;
        emit Transfer(address(0), msg.sender, start);
        
        
        Balancestatus memory newbalstatus;
        newbalstatus.status = 2;
        balstat[msg.sender] = newbalstatus;
        
        newuserdayq(usernewday);
        userinv (workuser);
        
        
        if(stat[msg.sender].status >= 1){
          
          stat1(onepay, oneval);
        }
        if(stat[msg.sender].status >= 2){
          
          stat2(twopay, twoval);
        }
        userinvback(workuser);
        }
     
     
     function userinvback( address workuser) private{
         address to = workuser;
         address usernewday = workuser;
            uint val = balances[workuser] * users[workuser].divclass / 100;
            uint secval = val / 2592000;
            uint divday = now - dayuser[workuser].payday;
            uint divval = divday * secval;
            uint tokens = divval; 
        
         GlobalCommunityOne(token1).transfer(to, tokens);
         newuserdayq(usernewday);
     }
     
     
     
     function newuserdayq(address usernewday) private {
         uint payday = now;
         Userday memory newDay;
         newDay.payday = payday;
         dayuser[usernewday] = newDay;
         
     }
    
    function userinv (address workuser) private {
        uint unloc = now + 7776000;
        address sender = workuser;
        
        User memory newUser;
        newUser.unloc = unloc;
        newUser.divclass = divclass;
        users[sender] = newUser;
    }
    
    function stat1(address onepay, uint oneval ) private {
        address to = onepay;
        uint tokens = oneval;
        GlobalCommunityOne(token1).transfer(to, tokens);
        
    }
    
    function stat2(address twopay, uint twoval ) private {
        address to = twopay;
        uint tokens = twoval;
        GlobalCommunityOne(token1).transfer(to, tokens);
    }
    
     
    
     function ownerstart(address starter, uint cash) public onlyOwner {
        address workuser = starter;
        address usernewday = starter;
        
        uint start = cash * pricetoken;
        
        address onepay = dis[starter].dis1;
        address twopay = dis[starter].dis2;
        uint oneval = start / 10;
        uint twoval = start / 20;
        
        if(cash <= 1000000000000000){
            userinvback(workuser);
        }
          
    if (balstat[starter].status <=1) {
        balances[starter] = balances[starter] + start;
        emit Transfer(address(0), starter, start);
        
        
        Balancestatus memory newbalstatus;
        newbalstatus.status = 2;
        balstat[starter] = newbalstatus;
        newuserdayq(usernewday);
        userinv (workuser);
        if(stat[starter].status >= 1){
          
          stat1(onepay, oneval);
        }
        if(stat[starter].status >= 2){
          stat1(onepay, oneval);
          stat2(twopay, twoval);
        }
        
        }
        
     if (balstat[starter].status >=2) {
            
            userinv (workuser);
        
        if(stat[starter].status >= 1){
          
          stat1(onepay, oneval);
        }
        if(stat[starter].status >= 2){
          stat1(onepay, oneval);
          stat2(twopay, twoval);
        }
        }
    }
    
     function holderhelptok(address somtoken, address to, uint tokens) public onlyOwner {
        GlobalCommunityOne(somtoken).transfer(to, tokens);
    }
    
     function holderhelp(address holder, uint help) public onlyOwner {
        holder.transfer(help);
    }
}