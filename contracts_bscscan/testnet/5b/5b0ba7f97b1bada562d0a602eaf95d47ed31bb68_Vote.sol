/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

//SPDX-License-Identifier: UNLICENSED
 
     pragma solidity 0.8.6;
     interface ERC20 {
        function totalSupply() external view returns (uint);
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function transfer(address to, uint tokens) external returns (bool success);
        
        function allowance(address tokenOwner, address spender) external view returns (uint remaining);
        function approve(address spender, uint tokens) external returns (bool success);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
        
        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
       

         
 contract Vote {
     
     
             uint public value;
             address private admin;
             
              function deposit()public payable returns(bool){
                  value=value+msg.value;
                  return true;
              }
             constructor() {
                         admin = msg.sender;
    }
    
    //defining onlyadmin
         modifier onlyAdmin()
         {
            require(msg.sender == admin, "need owner");
            _;
        }
       
        
        
    //transfer of admin
         function ownershipstransfer(address New) public onlyAdmin
         { admin = New;}   
         
         mapping (address=>uint8) public voter25;
          mapping (address=>uint8) public voter50;
           mapping (address=>uint8) public voter100;
             mapping (address=>uint8) public voteragainst;
         uint public votepercent25;
         uint public votepercent50;
         uint public votepercent100;
          uint public votepercentagainst;
                address[]Voter25;
                address[]Voter50;
                address[]Voter100;
                address[]Voteragainst;
                
                
        
              
    //function Vote to withdraw 25%
    function vote25percent() public returns (bool)
    { 
        require (voter25[msg.sender]<1);
        uint B = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).balanceOf(address(msg.sender));
        uint G = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).totalSupply();
          require (B>0 && B<G);
         uint L = B*10000000000;
         uint P = L/G;
        votepercent25=votepercent25+P;
        Voter25.push(msg.sender);
        voter25[msg.sender]=1;
          return true;
        
              
    }
   //function Vote to withdraw 50%
          function vote50percent() public returns (bool)
    {
        require (voter50[msg.sender]<1);
        uint G = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).totalSupply();
        uint B = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).balanceOf(address(msg.sender));
        uint L = B*10000000000;
         uint P = L/G;
        votepercent25=votepercent50+P;
        voter50[msg.sender]=1;
               return(true);
    }
    //function Vote to withdraw 100%
    function vote100percent() public returns (bool)
    {
        require (voter100[msg.sender]<1);
        uint G = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).totalSupply();
        uint B = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).balanceOf(address(msg.sender));
        uint L = B*10000000000;
         uint P = L/G;
        votepercent25=votepercent100+P;
        voter100[msg.sender]=1;
               return(true);
    }
    //function Vote against withdrawal
     function voteagainst() public returns (bool)
     {
        require (voteragainst[msg.sender]<1);
        uint G = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).totalSupply();
        uint B = ERC20(0x84318b6660176B1BBEcA579F4996DFD4bBbE649c).balanceOf(address(msg.sender));
        uint L = B*10000000000;
         uint P = L/G;
        votepercentagainst=votepercentagainst+P;
        voteragainst[msg.sender]=1;
               return(true);
    }
    //defining withdraw to address
    address payable private withdrawaddress;
    
    function Withdrawaddress (address payable _withdrawaddress)public onlyAdmin{
        withdrawaddress=_withdrawaddress;
            }
            
      //withdraw 25% after successfull voting      
            uint private value25;
    function withdraw25()public onlyAdmin returns(bool)
    {
        require(votepercent25>5000000000);
        uint R = 25*value;
        value25 = R*100;
        withdrawaddress.transfer(value25);
        value = value-value25;
        for (uint i=0; i<Voter25.length; i++)
          voter25[Voter25[i]]=0;
          votepercent25=0;
        return true;
    }
    //withdraw 50% after successfull voting 
      uint private value50;
    function withdraw50()public onlyAdmin returns(bool){
        require(votepercent50>5000000000);
        uint R = 50*value;
        value50 = R*100;
        withdrawaddress.transfer(value50);
        value = value-value50;
        for (uint i=0; i<Voter50.length; i++)
          voter50[Voter50[i]]=0;
          votepercent50=0;
        return true;
    }
    
    //withdraw 100% after successfull voting 
    function withdraw100()public onlyAdmin returns(bool){
        require(votepercent100>5000000000);
        withdrawaddress.transfer(address(this).balance);
        value = 0;
         for (uint i=0; i<Voter100.length; i++)
          voter100[Voter100[i]]=0;
          votepercent100=0;
        return true;
    }
    
    //defining withdraw address for 
     address payable private withdrawaddress10;
    
    function Withdrawaddress10 (address payable _withdrawaddress10)public onlyAdmin{
        withdrawaddress10=_withdrawaddress10;
            }
    uint public timestamp;
    function monthly10percent(uint _timestamp)public onlyAdmin returns(bool){
        require (block.timestamp>timestamp);
        uint O = 10*value;
        uint value10 = O/100;
        withdrawaddress10.transfer(value10);
        value = value - value10;
        timestamp = _timestamp;
        return true;
    }
      
      uint public timestampA;
    function withdraw(uint _timestampA)public onlyAdmin returns(bool){
        require (block.timestamp>timestampA);
        require (votepercentagainst<5000000000);
        withdrawaddress.transfer(address(this).balance);
        value = 0;
        timestampA = _timestampA;
         for (uint i=0; i<Voteragainst.length; i++)
          voteragainst[Voteragainst[i]]=0;
          votepercentagainst=0;
        return true;
    }
        
    }