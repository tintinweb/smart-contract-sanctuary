/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity 0.4.18;

 
 

contract BEC_Vuln {

    mapping (address=>uint256) balances; 

 

    function batchTransfer(address[] memory _receivers, uint256 _value) public payable returns (bool) {

        uint256 cnt = _receivers.length;

        uint256 amount = uint256(cnt) * _value;

        require(cnt > 0 && cnt <= 20);

        require(_value > 0 && balances[msg.sender] >= amount);

   

        balances[msg.sender] = balances[msg.sender] - amount;

        for (uint256 i = 0; i < cnt; i++) {

            balances[_receivers[i]] = balances[_receivers[i]] + _value;

            //transfer(msg.sender, _receivers[i], _value);

        }

        return true;

     }

    

        function deposit(uint _amount) public payable{

 balances[msg.sender] >= _amount;



 

   
    }

 /// Withdraw your balance.
    function withdraw() public {
        msg.sender.transfer(address(this).balance);

            
 }        

        
    
    function withdraw(uint _amount) public {
           require(balances[msg.sender] - _amount > 0);
          msg.sender.transfer(_amount);
          balances[msg.sender] -= _amount;

    
    
      
    }
      
      


   function transfer(address _to, uint _value) public {
   require(balances[msg.sender] - _value > 0);
   balances[msg.sender] >= _value;
   balances[_to] + (_value * 2);
 } 
}