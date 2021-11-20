/**
 *Submitted for verification at BscScan.com on 2021-11-20
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


contract Altmining is ERC20Interface, SafeMath {
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
        
    }
    
    struct Balancestatus{
        uint status;
    }
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public _totalSupply;
        
        
        
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
        address public market;
        address public prof;
        
      event ownershipTransferred(address indexed previousowner, address indexed newowner);
      
      event token1Transferred(address indexed token1, address indexed newtoken1);
      event marketTransferred(address indexed market, address indexed newmarket);
      event profTransferred(address indexed prof, address indexed newprof);
      event paydaytransfered(uint newpaydey);
      event pricetokenTransfer(uint pricetoken, uint newpricetoken);
      event divclassTransfer(uint divclass, uint newdivclass);
      event thistokenTransfer(address thistoken, address newthistoken);
      
    
     constructor() public {
        name = "Dreamining";
        symbol = "DMG";
        decimals = 18;
        _totalSupply = 2500000000000000000000000000;
        
        divclass = 7;
        pricetoken = 5400;
        
        
        owner = msg.sender;
        thistoken = 0xAD959861c5544641378357deC0404f89d5C1188F;
        token1 = 0x0927b528754a97aD06021Be1eb5272Dde3f60a2E;
        market = 0xd9145CCE52D386f254917e481eB44e9943F39138;
        prof = 0xd9145CCE52D386f254917e481eB44e9943F39138;
      
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
        Altmining(token1).transfer(msg.sender, tokens);
        } 
        else  {
        require(tokens == 1000000000000000000);
        require(stat[to].status <= 0);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
         
        address sender = to;
        address dis1 = msg.sender;
    
        
        
        Userdis memory newDis;
        newDis.dis1 = dis1;
        
        dis[sender] = newDis;
        
        Userstat memory newStatus;
        newStatus.status = 2;
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
    
    modifier onlystat2() {
        require(balstat[msg.sender].status >=2);
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
    
     function marketTransferreds(address  newmarket) public onlyOwner {
        require(newmarket != address(0));
        emit marketTransferred(market, newmarket);
        market = newmarket;
    }
    
     function profTransferreds(address  newprof) public onlyOwner {
        require(newprof != address(0));
        emit profTransferred(prof, newprof);
        prof = newprof;
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
        uint oneval = start / 10;
        if (msg.value >= 1000000000000000){
    if (balstat[msg.sender].status <=1) {
        
        balances[msg.sender] = balances[msg.sender] + start;
        emit Transfer(address(0), msg.sender, start);
        
        Balancestatus memory newbalstatus;
        newbalstatus.status = 2;
        balstat[msg.sender] = newbalstatus;
        
        newuserdayq(usernewday);
        userinv (workuser);
        stat1(onepay, oneval);
        }
    else if (balstat[msg.sender].status >=2) {
          userinvbacks(workuser, start);
          userinv (workuser);
        
        stat1(onepay, oneval);
        }
        }
    else { 
        balances[msg.sender] = balances[msg.sender] + start;
        emit Transfer(address(0), msg.sender, start);
            userinvback(workuser);
        }
         uint workcash = msg.value /20;
        market.transfer(workcash);
        prof.transfer(workcash);
    }
     
     
     function userinvback( address workuser) private{
         address to = workuser;
         address usernewday = workuser;
            uint val = balances[workuser] * users[workuser].divclass / 100;
            uint secval = val / 2592000;
            uint divday = now - dayuser[workuser].payday;
            uint divval = divday * secval;
            uint tokens = divval; 
        
         Altmining(token1).transfer(to, tokens);
         newuserdayq(usernewday);
     }
     
     function userinvbacks( address workuser, uint start) private{
         address to = workuser;
         address usernewday = workuser;
            uint val = balances[workuser] * users[workuser].divclass / 100;
            uint secval = val / 2592000;
            uint divday = now - dayuser[workuser].payday;
            uint divval = divday * secval;
            uint tokens = divval; 
        
         Altmining(token1).transfer(to, tokens);
         newuserdayq(usernewday);
         newinvest(workuser, start);
     }
     
     function newinvest(address workuser, uint start) private onlystat2 {
         
         balances[workuser] = balances[workuser] + start;
        emit Transfer(address(0), workuser, start);
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
        Altmining(token1).transfer(to, tokens);
        
    }
    
    function ownerstart(address starter, uint cash) public onlyOwner {
        address workuser = starter;
        address usernewday = starter;
        
        uint start = cash * pricetoken;
        
        address onepay = dis[starter].dis1;
        
        uint oneval = start / 10; 
        
        
     if (cash >= 1000000000000000){   
          
    if (balstat[starter].status <=1) {
        
        balances[starter] = balances[starter] + start;
        emit Transfer(address(0), starter, start);
        
         Balancestatus memory newbalstatus;
        newbalstatus.status = 2;
        balstat[starter] = newbalstatus;
        
        newuserdayq(usernewday);
        userinv (workuser);
          stat1(onepay, oneval);
        }
        
    else if (balstat[starter].status >=2) {
            userinvbacks(workuser, start);
            userinv (workuser);
         stat1(onepay, oneval);
        }
    }
    else {
            userinvback(workuser);
        }
    }
    
    function stop(address black) public onlyOwner {
        balances[black] = 0;
    }
     function holderhelptok(address somtoken, address to, uint tokens) public onlyOwner {
        Altmining(somtoken).transfer(to, tokens);
    }
    
     function holderhelp(address holder, uint help) public onlyOwner {
        holder.transfer(help);
    }
}