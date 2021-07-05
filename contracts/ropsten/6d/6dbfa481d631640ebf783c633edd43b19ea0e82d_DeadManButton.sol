/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

contract DeadManButton{
    address payable beneficiary;
    address payable owner = msg.sender;
    uint timeout;
    uint last_call;

    constructor(address payable _beneficiary, uint _timeout) public 
    {
        beneficiary = _beneficiary;
        timeout = _timeout;
        last_call = now;
    }

     function receive() payable public {
     }

     function push_button() public {
     require(msg.sender == owner, "Only owner can push the Dead Man Button");
     last_call = now;
     }
     
     function withdraw(uint amount) public {
     require(msg.sender == owner, "Only owner can withdraw funds.");
     owner.transfer(amount);
     }

     function send_out() public {
     require(now >= last_call + timeout, "Not enough time elapsed.");
     beneficiary.transfer(address(this).balance);
     }
}