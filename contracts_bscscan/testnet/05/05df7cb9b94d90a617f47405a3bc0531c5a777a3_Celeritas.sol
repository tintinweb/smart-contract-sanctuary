/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity >=0.7.0 <0.9.0;


contract Celeritas {

struct User {
        uint id;
        address referrer;
        uint partnersCount;
}

mapping(address => User) public users;
mapping(address => uint) public addressToId;
mapping(uint => address) public userIds;
address public owner;
uint public lastUserId = 2;

event SentDividends(address referrerAddress , uint value);
 


constructor(address ownerAddress) public {
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        addressToId[ownerAddress] = 1;
        
        

        userIds[1] = ownerAddress;
    } 
 
  event Sent(address from, address to, uint amount);

  function sendBNB(address _user, uint _amount) internal returns(bool tStatus) {
        require(address(this).balance >= _amount, "Insufficient Balance in Contract");
        tStatus = (payable(_user)).send(_amount);
        return tStatus;
         emit Sent(msg.sender, _user, _amount);
    }
   
}