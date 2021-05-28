/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// im yuri

contract Likelion_21 {
    
    address owner = 0x82ed50b75368ed1043A0dfdE7d7aDF4CD66Ad61b;
    address payable owner_pay = payable(owner);
   
    
   //E
    uint count1;
    modifier countAll {
        require(count1 < 5);
        _;
    }
    
    //F
    event Alarm(uint counts);
    uint count2;
    modifier count2Get {
        _;
        if(count2 >= 100) {
            emit Alarm(count2);
        }
    }
    
    // A
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // B,C
    function getMoney() payable public returns(uint, uint) {
        return (address(this).balance, address(msg.sender).balance);
        count2++;
    }
    
    // D
    function sendMoney(address payable recipient, uint amount) payable onlyOwner public {
        recipient.transfer(amount);
    }
    
    //E
    function getAll() payable onlyOwner countAll public {
        owner_pay.transfer(address(this).balance);
        count1++;
    }
}