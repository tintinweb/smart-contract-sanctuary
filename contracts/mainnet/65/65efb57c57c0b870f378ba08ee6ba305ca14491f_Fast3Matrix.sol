pragma solidity >=0.4.23 <0.6.0;

contract Fast3Matrix{
    struct User {
        uint id;
        address referrer;
        bool block;
        uint8 partnercount;
        uint8 level;
        uint8 levelallw;
        mapping(uint8 => address[]) partners;
        mapping(uint8 => uint[]) D5No;
       
    }
    
    
    uint8[6] private referrallevel = [
       10,2,2,2,2,2
    ];
    
    uint[] private L5Matrix;
    
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    
    uint public lastUserId = 2;
    uint private benid = 1;
    uint8 private seqid = 0;
    address public owner;
    
    event payout(address indexed sender,address indexed receiver,uint indexed dividend,uint8 matrix,uint8 level,uint8 position);
    event Reentry(address indexed sender,uint senderid,uint8 level,uint8 status);
    event Testor(uint benid,uint8 seqid,uint8 status);

   
    
    constructor(address ownerAddress) public {
        
        owner = ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnercount : 0,
          //  partners: address(0),
            block: false,
            levelallw:1,
            level : 1
        });
        seqid = 1;
        users[ownerAddress] = user;
        userIds[1] = ownerAddress;
        users[ownerAddress].D5No[0].push(1);
        L5Matrix.push(1);
        L5Matrix.push(1);
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,msg.value);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),msg.value);
    }

    function registrationExt(address referrerAddress) external payable {
       registration(msg.sender, referrerAddress,msg.value);
    }
    
    function addtoMatrix(uint newseqid,uint8 status) private{
        uint newid = uint(L5Matrix.length);
        newid = newid + 1;
        users[userIds[newseqid]].level++;
        users[userIds[newseqid]].D5No[0].push(newid);
        L5Matrix.push(newseqid);
        emit Reentry(userIds[newseqid],newid,users[userIds[newseqid]].level,status);
     }
    
    function registration(address userAddress, address referrerAddress,uint buyvalue) private {
        require(msg.value == 0.25 ether, "registration cost 0.25");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnercount :0,
            block: false,
            levelallw:1,
            level : 0
        });
        
        users[userAddress] = user;
        users[userAddress].referrer = referrerAddress;
        userIds[lastUserId] = userAddress;
        
        users[referrerAddress].partners[0].push(userAddress);
        users[referrerAddress].partnercount++;
        users[referrerAddress].levelallw = users[referrerAddress].levelallw + 2;
        addtoMatrix(lastUserId,1);
        lastUserId++;
        levelreward(userAddress,referrerAddress,buyvalue);
        findbenid(userAddress,buyvalue);
    }

    function levelreward(address userAddress,address referrerAddress,uint buyvalue) private{
        uint8 count = 1;
        uint dividend;
        while(count < 7){
            dividend = referrallevel[count-1] * buyvalue / 100;
            if (referrerAddress != owner) {
                emit payout(userAddress,referrerAddress,dividend,2,0,count);
                sendreward(referrerAddress,dividend);
                referrerAddress = users[referrerAddress].referrer;
            }else{
                emit payout(userAddress,owner,dividend,2,0,count);
                sendreward(owner,dividend); 
            }
            count++;
        }
    
    }
    
    function findbenid(address userAddress,uint buyvalue) private {
        uint dividend = 80 * buyvalue / 100;
       address reinvest = userAddress;
        if(seqid == 3){
            //users[userIds[newseqid]].level;
            emit payout(userAddress,userIds[L5Matrix[benid]],0,1,users[userIds[L5Matrix[benid]]].level,seqid);
            addtoMatrix(L5Matrix[benid],2);
            reinvest = userIds[L5Matrix[benid]];
            benid = findqualifier(benid,userAddress);
            seqid = 1;
        }
            emit payout(reinvest,userIds[L5Matrix[benid]],dividend,1,users[userIds[L5Matrix[benid]]].level,seqid);
        sendreward(userIds[L5Matrix[benid]],dividend);
        seqid++;
     }
      
    function findqualifier(uint newseqid,address userAddress) internal returns(uint) {
        uint newbenid = 0;
        while (newbenid == 0) {
            newseqid++;
            if (users[userIds[L5Matrix[newseqid]]].level <= users[userIds[L5Matrix[newseqid]]].levelallw) {
                newbenid = newseqid;
            }else{
                users[userIds[L5Matrix[newseqid]]].block = true;
                emit Reentry(userAddress,newseqid,users[userIds[L5Matrix[newseqid]]].level,3);
            }
        }
        return newseqid;
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function usersD5Matrix(address userAddress) public view returns(uint, uint[] memory) {
        return (L5Matrix.length,users[userAddress].D5No[0]);
    }
    
    function userspartner(address userAddress) public view returns(address[] memory) {
        return (users[userAddress].partners[0]);
    }
    

    function sendreward(address receiver,uint dividend) private {
        
        if (!address(uint160(receiver)).send(dividend)) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}