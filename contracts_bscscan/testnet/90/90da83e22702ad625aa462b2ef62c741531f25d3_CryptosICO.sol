/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

//SPDX-License-Identifier: unidentified
pragma solidity 0.8.4;




 contract CryptosICO {
        address public admin;
        address payable public deposit;
        uint tokenPrice = 0.001 ether;  // 1 ETH = 1000 CRTP, 1 CRPT = 0.001
        uint public hardCap = 300 ether;
        uint public raisedAmount; // this value will be in wei
       
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
     
     
        event Invest(address investor, uint value, uint tokens);
        
        
        // function called when sending eth to the contract
        function invest() payable public returns(bool){ 
            icoState = getCurrentState();
            require(icoState == State.running);
            require(msg.value >= minInvestment && msg.value <= maxInvestment);
            
            raisedAmount += msg.value;
            require(raisedAmount <= hardCap);
            
            uint tokens = msg.value / tokenPrice;
     
            // adding tokens to the inverstor's balance from the founder's balance
                       deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address
            
            emit Invest(msg.sender, msg.value, tokens);
            
            return true;
        }
       
       
       // this function is called automatically when someone sends ETH to the contract's address
       receive () payable external{
            invest();
            
       }
        }