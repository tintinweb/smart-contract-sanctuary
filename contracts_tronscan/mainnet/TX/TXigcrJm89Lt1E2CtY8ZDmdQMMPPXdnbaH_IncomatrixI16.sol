//SourceUnit: i16incomatrix.sol

pragma solidity >=0.4.23 <0.6.0;

contract IncomatrixI16 {
     using SafeMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint256 => bool) activeX12Levels;
        mapping(uint256 => X12) x12Matrix;
    }
    
    struct X12 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        address[] thirdLevelReferrals;
        address[] fourthLevelReferrals;
        bool blocked;
        uint8 reinvestCount;
    }

    uint8 public constant LAST_LEVEL = 16;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    address public mainContractAddress;
     bool public openPublicRegistration;
    
    mapping(uint256 => uint) public levelPrice;
    
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint256 level,uint8 reinvestCount);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint256 level);
    event NewUserPlace(address indexed user, address indexed referrer,address indexed currentReferrer, uint8  matrix, uint256 level, uint8 depth,uint8 reinvestcount);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint256 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint256 level);
    event EarningsMatrix(address indexed user,uint256 amount,uint8 matrix,uint256 level);
    
    constructor(address ownerAddress,address oldaddress) public {
         levelPrice[1] = 50 trx;
        levelPrice[2] = 100 trx;
        levelPrice[3] = 150 trx;
        levelPrice[4] = 200 trx;
        levelPrice[5] = 250 trx;
        levelPrice[6] = 300 trx;
        levelPrice[7] = 400 trx;
        levelPrice[8] = 500 trx;
        levelPrice[9] = 1000 trx;
        levelPrice[10] = 1500 trx;
        levelPrice[11] = 2000 trx;
        levelPrice[12] = 3000 trx;
        levelPrice[13] = 6000 trx;
        levelPrice[14] = 9000 trx;
        levelPrice[15] = 12000 trx;
        levelPrice[16] = 15000 trx;
        
        owner = ownerAddress;
        mainContractAddress=oldaddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            
            users[ownerAddress].activeX12Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
   
    
    function buyNewLevel(uint256 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
            owner.transfer(msg.value);
          
       
    }    
    
    
    
    function buyFirstLevel() public payable{
         
        buylevel1(msg.sender);
    }
    
    function buylevel1(address userAddress) internal {
        
        require(msg.value == 50 trx, "buy cost 50 trx");
        require(!isUserExists(userAddress), "user exists");
        
       owner.transfer(msg.value);
       
    }
    
    
    function usersActiveX12Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX12Levels[level];
    }

   
    
    function usersX12Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,address[] memory, bool) {
        return (users[userAddress].x12Matrix[level].currentReferrer,
                users[userAddress].x12Matrix[level].firstLevelReferrals,
                users[userAddress].x12Matrix[level].secondLevelReferrals,
                users[userAddress].x12Matrix[level].thirdLevelReferrals,
                users[userAddress].x12Matrix[level].blocked);
    }
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

   

    function sendTRXDividends(address userAddress,  uint256 level) private {
        address ref1=users[users[userAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer;
        address ref2=users[ref1].x12Matrix[level].currentReferrer;
        address ref3=users[ref2].x12Matrix[level].currentReferrer;
       if(ref1!=address(0)){
            if (address(uint160(ref1)).send(levelPrice[level].mul(20).div(100))) {
               emit EarningsMatrix(ref1,levelPrice[level].mul(20).div(100),3,level);
            }
            else
            {
                 return address(uint160(ref1)).transfer(address(this).balance);
            }
            
       }
       else
       {
            if (address(uint160(owner)).send(levelPrice[level].mul(20).div(100))) {
               emit EarningsMatrix(owner,levelPrice[level].mul(20).div(100),3,level);
            }
       }
       if(ref2!=address(0)){
            if (address(uint160(ref2)).send(levelPrice[level].mul(30).div(100))) {
                emit EarningsMatrix(ref2,levelPrice[level].mul(30).div(100),3,level);
            }
            else
            {
                 return address(uint160(ref2)).transfer(address(this).balance);
            }
       }
       else
       {
            if (address(uint160(owner)).send(levelPrice[level].mul(30).div(100))) {
                emit EarningsMatrix(owner,levelPrice[level].mul(30).div(100),3,level);
            }
       }
       if(ref3!=address(0) && users[ref3].x12Matrix[level].fourthLevelReferrals.length<=14){
            if (address(uint160(ref3)).send(levelPrice[level].mul(50).div(100))) {
                emit EarningsMatrix(ref3,levelPrice[level].mul(50).div(100),3,level);
            }
            else
            {
                 return address(uint160(ref3)).transfer(address(this).balance);
            }
       }
       else
       {
           if(ref3==address(0)){
           if (address(uint160(owner)).send(levelPrice[level].mul(50).div(100))) {
                emit EarningsMatrix(owner,levelPrice[level].mul(50).div(100),3,level);
            }
           }
       }
            
       
        
        // if (isExtraDividends) {
        //     emit SentExtraEthDividends(_from, receiver, matrix, level);
        // }
    }
    
  
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    /*  12X */
    function updateX12Referrer(address userAddress, address referrerAddress, uint256 level) private {
        require(users[referrerAddress].activeX12Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x12Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress,referrerAddress, 3, level,1, users[referrerAddress].x12Matrix[level].reinvestCount);
            
            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
               
               return sendTRXDividends(userAddress, level);
            }
            
            address ref = users[referrerAddress].x12Matrix[level].currentReferrer;            
            users[ref].x12Matrix[level].secondLevelReferrals.push(userAddress); 
            emit NewUserPlace(userAddress, referrerAddress,ref, 3, level,2, users[ref].x12Matrix[level].reinvestCount);
            
            address ref1 = users[ref].x12Matrix[level].currentReferrer;            
            users[ref1].x12Matrix[level].thirdLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress,ref1, 3, level,3, users[ref1].x12Matrix[level].reinvestCount);
            
             address ref2 = users[ref1].x12Matrix[level].currentReferrer;            
            users[ref2].x12Matrix[level].fourthLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress,ref2, 3, level,4, users[ref2].x12Matrix[level].reinvestCount);
            
            return updateX12ReferrerSecondLevel(userAddress, ref2, level);
        }
         if (users[referrerAddress].x12Matrix[level].secondLevelReferrals.length < 4) {
        users[referrerAddress].x12Matrix[level].secondLevelReferrals.push(userAddress);
        address secondref = users[referrerAddress].x12Matrix[level].currentReferrer; 
        address thirdref=users[secondref].x12Matrix[level].currentReferrer;
        if(secondref==address(0))
        secondref=owner;
        if(thirdref==address(0))
        thirdref=owner;
       
        
        if (users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length < 
            2) {
            updateX12(userAddress, referrerAddress, level, false);
        } else {
            updateX12(userAddress, referrerAddress, level, true);
        }
        
        updateX12ReferrerSecondLevel(userAddress, thirdref, level);
        }
        
        
        else  if (users[referrerAddress].x12Matrix[level].thirdLevelReferrals.length < 8) {
        users[referrerAddress].x12Matrix[level].thirdLevelReferrals.push(userAddress);

      if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 0);
            
        } else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 1);
            
        }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[2]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 2);
           
        }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[3]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 3);
            
        }
        
        updateX12ReferrerSecondLevel(userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, level);
        }
        
         else  if (users[referrerAddress].x12Matrix[level].fourthLevelReferrals.length < 16) {
        users[referrerAddress].x12Matrix[level].fourthLevelReferrals.push(userAddress);

      if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 0);
            
        } else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 1);
            
        }else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[2]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 2);
            
        }else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[3]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 3);
            
        }
        else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[4]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 4);
            
        } else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[5]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 5);
            
        }else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[6]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 6);
            
        }else if (users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[7]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12FromThird(userAddress, referrerAddress, level, 7);
            
        }
        
          
        
        updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    function updateX12(address userAddress, address referrerAddress, uint256 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdLevelReferrals.push(userAddress);
            users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].fourthLevelReferrals.push(userAddress);
            
            
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], 3, level, 1,users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], referrerAddress, 3, level, 2,users[referrerAddress].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], users[referrerAddress].x12Matrix[level].currentReferrer, 3, level, 3,users[referrerAddress].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer, 3, level, 4,users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount);
           
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[0];
           
        } else {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdLevelReferrals.push(userAddress);
            users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].fourthLevelReferrals.push(userAddress);
            
           emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], 3, level, 1,users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], referrerAddress, 3, level, 2,users[referrerAddress].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], users[referrerAddress].x12Matrix[level].currentReferrer, 3, level, 3,users[referrerAddress].x12Matrix[level].reinvestCount);
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer, 3, level, 4,users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount);
           
            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX12Fromsecond(address userAddress, address referrerAddress, uint256 level,uint pos) private {
            users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.push(userAddress);
             users[users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].secondLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].fourthLevelReferrals.push(userAddress);
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos],users[referrerAddress].x12Matrix[level].currentReferrer, 3, level,4,users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].reinvestCount); //third position
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos],referrerAddress, 3, level,3,users[referrerAddress].x12Matrix[level].reinvestCount); //third position
            
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer, 3, level,2,users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].reinvestCount);

             emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], 3, level, 1,users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].reinvestCount); //first position
           //set current level
            
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos];
           
       
    }
    
    
     function updateX12FromThird(address userAddress, address referrerAddress, uint256 level,uint pos) private {
            users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.push(userAddress);
             users[users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].secondLevelReferrals.push(userAddress);
             address fourthupline=users[users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer;
            users[fourthupline].x12Matrix[level].thirdLevelReferrals.push(userAddress);
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos],referrerAddress, 3, level,4,users[referrerAddress].x12Matrix[level].reinvestCount); //third position
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos],fourthupline, 3, level,3,users[fourthupline].x12Matrix[level].reinvestCount); //third position
            
            emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos], users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos]].x12Matrix[level].currentReferrer, 3, level,2,users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos]].x12Matrix[level].reinvestCount);

             emit NewUserPlace(userAddress,users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos], users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos], 3, level, 1,users[users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos]].x12Matrix[level].reinvestCount); //first position
           //set current level
            
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].thirdLevelReferrals[pos];
           
       
    }
    
    
    function updateX12ReferrerSecondLevel(address userAddress, address referrerAddress, uint256 level) private {
        if(referrerAddress==address(0)){
            
            return sendTRXDividends(userAddress, level);
        }
        if (users[referrerAddress].x12Matrix[level].fourthLevelReferrals.length < 16) {
           
           return sendTRXDividends(userAddress, level);
        }
        if (users[referrerAddress].x12Matrix[level].fourthLevelReferrals.length == 16) {
           
            sendTRXDividends(userAddress, level);
        }
        
        users[referrerAddress].x12Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].thirdLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].fourthLevelReferrals = new address[](0);
        
       
        if (!users[referrerAddress].activeX12Levels[level.add(1)] && level != LAST_LEVEL) {
            users[referrerAddress].x12Matrix[level].blocked = true;
        }

        users[referrerAddress].x12Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX12Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level,users[referrerAddress].x12Matrix[level].reinvestCount);
            
                
            updateX12Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 3, level,users[referrerAddress].x12Matrix[level].reinvestCount);
            
            sendTRXDividends(userAddress, level);
        }
    }
    
     function findFreeX12Referrer(address userAddress, uint256 level) public view returns(address) {
        while (true) {
            if(users[userAddress].referrer==address(0)){
                return owner;
            }
            if (users[users[userAddress].referrer].activeX12Levels[level]) {
                
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    
    
     function getrefferal(address userAddress) public view returns(address)
    {
       return IncomeMatrixContract(mainContractAddress).getrefferaladdress(userAddress);
    }
    
     
   
}




 interface IncomeMatrixContract
{
    function getrefferaladdress(address)external view returns(address);
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}