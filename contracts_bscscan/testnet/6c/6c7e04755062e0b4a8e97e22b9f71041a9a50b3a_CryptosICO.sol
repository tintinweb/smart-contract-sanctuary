/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

//SPDX-License-Identifier: UNLICENSED
    
         pragma solidity 0.8.4;
    
  

 contract CryptosICO {
      address [] private arr; 
              address public admin;
        address payable public deposit;
       uint public w;
       uint public h;
       uint public v;
       uint public j;
       uint public k;
       uint public r;
        uint public hardCap = 400 ether;
        uint public raisedAmount; // this value will be in wei
       uint public x;
       uint public y;
        uint public maxInvestment = 5 ether;
        uint public minInvestment = 0.1 ether;
        
        enum State { running, halted} // ICO states 
        State public icoState;
        
        constructor(address payable _deposit){
            deposit = _deposit; 
            admin = msg.sender; 
            
        }
     
        
        modifier onlyAdmin(){
            require(msg.sender == admin);
            _;
        }
        
        
        // emergency stop
        function halt() public onlyAdmin{
            icoState = State.halted;
        }
        
        function Tokenprice (uint _w) public onlyAdmin{
          w=_w;  
        }
        function investsharebnb (uint _h) public onlyAdmin{
          h=_h;  
        }
        function refsharebnb (uint _j) public onlyAdmin{
          j=_j;  
        }
        function investsharetok (uint _v) public onlyAdmin{
          v=_v;  
        }
        function refsharetok (uint _k) public onlyAdmin{
          k=_k;  
        }
        
        function resume() public onlyAdmin{
            icoState = State.running;
        }
        
        
        function changeDepositAddress(address payable newDeposit) public onlyAdmin{
            deposit = newDeposit;
        }
        
        
        function getCurrentState() public view returns(State){
            if(icoState == State.halted){
                return State.halted;
            }else return State.running;
        }
     
     
        
       event Buy(address investor, uint value, uint tokens);
        
        
        // function called when sending eth to the contract
        function  buy(address payable com) payable public returns(bool){ 
             uint i;
    
  for(i = 0; i < arr.length; i++)
  {
    if(arr[i] == com)
    {
        x=(x+h)/100;
        y=(y+j)/100;
       
    }
  
    
  if(i >= arr.length)
 { x=(x+100)/100;
  y=0;
          } }   
            
            uint tokens = msg.value;
           
            // adding tokens to the inverstor's balance from the founder's balance
                       deposit.transfer(msg.value*x); // transfering the value sent to the ICO to the deposit address
                        com.transfer(msg.value*y);
            emit Buy (msg.sender, msg.value, tokens);
            
             arr.push(msg.sender);
            return true;
  
        }
       
       
              
        }