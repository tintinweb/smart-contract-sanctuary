/**
 *Submitted for verification at BscScan.com on 2021-10-19
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


contract CentinummRef is ERC20Interface, SafeMath {
     struct User{
        address dis1;
        address dis2;
        address dis3;
        address dis4;
        address dis5;
    }
     struct Userstat {
        uint status;
    }
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public _totalSupply;
        uint public price;
        uint public Community;
        uint public competitionisopen;
        uint public pricetoken;
      mapping(address => Userstat) public stat;
      mapping(address => User) public users;
      mapping(address => uint) balances;
      mapping(address => mapping(address => uint)) allowed;
        address public owner;
        address public partner;
        address public partner2;
        address public partner3;
        address public partner4;
        address public token1;
      event ownershipTransferred(address indexed previousowner, address indexed newowner);
      event partnerTransferred(address indexed partner, address indexed newpartner);
      event partnerTransferred2(address indexed partner2, address indexed newpartner2);
      event partnerTransferred3(address indexed partner3, address indexed newpartner3);
      event partnerTransferred4(address indexed partner4, address indexed newpartner4);
      event token1Transferred(address indexed token1, address indexed newtoken1);
      event priceTransfer(uint price, uint newprice);
      event pricetokenTransfer(uint pricetoken, uint newpricetoken);
      event competitionTransfer(uint competitionisopen, uint newcompetition);
      event CommunityTransfer(uint Community, uint newCommunity);
    
     constructor() public {
        name = "CentinummRef";
        symbol = "CTNR";
        decimals = 1;
        _totalSupply = 800000000000000000000000000000;
        price = 4000;
        pricetoken = 10000000000000000;
        owner = msg.sender;
        partner = 0x4e977304F48645044BE1B39F09E7aDdA2e8A8cA9;
        partner2 = 0x18661cd6403c046a8f210389f057dB2665689E45;
        partner3 = 0x9710c43F10568355D7db8f506925ceE2d035077A;
        partner4 = 0xfD28623d06D7C413796eaB0bF293aC95973c7AD2;
        token1 = 0x2026D3938cC163E5D16Ad136a356F7981b52E488;
        
       users[0xC7F73460899c34d4dAabd2AB8F46fEB4cE412D22].dis1 = 0x53e8Ec547D92Aa36fCf0ea75C248061a1114b333;
       users[0x53e8Ec547D92Aa36fCf0ea75C248061a1114b333].dis1 = 0x18661cd6403c046a8f210389f057dB2665689E45;
       users[0x18661cd6403c046a8f210389f057dB2665689E45].dis1 = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
       users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].dis1 = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
       users[0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2].dis1 = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
       users[0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D].dis1 = 0x488aDB5c8210a939051CFff266843A456c1B8C68;
       users[0x488aDB5c8210a939051CFff266843A456c1B8C68].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      
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
        
        if(msg.sender == owner) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        } 
        else  {
        require(tokens >= 10);
        require(stat[to].status <= 0);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens/10);
        emit Transfer(msg.sender, to, tokens);
         User memory newUser;
        address sender = to;
        address dis1 = msg.sender;
        address dis2 = users[dis1].dis1;
        address dis3 = users[dis2].dis1;
        address dis4 = users[dis3].dis1;
        address dis5 = users[dis4].dis1;
        newUser.dis1 = dis1;
        newUser.dis2 = dis2;
        newUser.dis3 = dis3;
        newUser.dis4 = dis4;
        newUser.dis5 = dis5;
        users[sender] = newUser;
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
    
     function transferprice(uint newitsprice) public onlyOwner {
        emit priceTransfer(price, newitsprice);
        price = newitsprice;
    }
    
     function transferpricetoken(uint newpricetoken) public onlyOwner {
        emit pricetokenTransfer(pricetoken, newpricetoken);
        pricetoken = newpricetoken;
    }
    
     function transferowner(address newowner) public onlyOwner {
        require(newowner != address(0));
        emit ownershipTransferred(owner, newowner);
        owner = newowner;
    }
    
     function transPart(address  newpartner) public onlyOwner {
        require(newpartner != address(0));
        emit partnerTransferred(partner, newpartner);
        partner = newpartner;
    }
    
     function transPart2(address  newpartner2) public onlyOwner {
        require(newpartner2 != address(0));
        emit partnerTransferred2(partner2, newpartner2);
        partner2 = newpartner2;
    }
    
     function transPart3(address  newpartner3) public onlyOwner {
        require(newpartner3 != address(0));
        emit partnerTransferred3(partner3, newpartner3);
        partner3 = newpartner3;
    }
    
    function transPart4(address  newpartner4) public onlyOwner {
        require(newpartner4 != address(0));
        emit partnerTransferred4(partner4, newpartner4);
        partner4 = newpartner4;
    }
    
    
     function transftoken1(address  newtoken1) public onlyOwner {
        require(newtoken1 != address(0));
        emit token1Transferred(token1, newtoken1);
        token1 = newtoken1;
    }
    
     function () external payable  {
        require(stat[msg.sender].status >= 1);
        
        address to = msg.sender;
        uint start = msg.value / pricetoken;
        uint tokens = msg.value * price; 
        uint newCommunity = Community + 1;
        emit CommunityTransfer(Community, newCommunity);
        Community = newCommunity;
        payer();
        CentinummRef(token1).transfer(to, tokens);
        if(Community <= 10){
        balances[msg.sender] = (balances[msg.sender] + start) + 10;
        emit Transfer(address(0), msg.sender, start);  
        } else {
        balances[msg.sender] = balances[msg.sender] + start;
        emit Transfer(address(0), msg.sender, start);
        }
    }
    
     function payer() private {
        uint value1 = msg.value * 12 / 100;
        uint value2 = msg.value * 14 / 100;
        uint value3 = msg.value * 15/100;
        uint value4 = msg.value *5 / 100;
        uint value6 = msg.value *10 / 100;
        address dis1 = users[msg.sender].dis1;
        address dis2 = users[msg.sender].dis2;
        address dis3 = users[msg.sender].dis3;
        address dis4 = users[msg.sender].dis4;
        address dis5 = users[msg.sender].dis5;
        partner.transfer(value2);
        partner2.transfer(value1);
        partner3.transfer(value1);
        partner3.transfer(value1);
        dis1.transfer(value3);
        dis2.transfer(value4);
        dis3.transfer(value4);
        dis4.transfer(value6);
        dis5.transfer(value3);
    }
    
     function ownerstart(address starter, uint cash) public onlyOwner {
        balances[starter] = balances[starter] + cash;
        emit Transfer(address(0), starter, cash);
    }
    
     function holderhelptok(address somtoken, address to, uint tokens) public onlyOwner {
        CentinummRef(somtoken).transfer(to, tokens);
    }
    
     function holderhelp(address holder, uint help) public onlyOwner {
        holder.transfer(help);
    }
}