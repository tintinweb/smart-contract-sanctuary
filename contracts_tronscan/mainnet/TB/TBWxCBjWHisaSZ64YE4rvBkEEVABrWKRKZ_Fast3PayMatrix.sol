//SourceUnit: Fast3PayMatrix.sol


pragma solidity >=0.4.23 <0.6.0;

contract Fast3PayMatrix{
    struct User {
        uint id;
        address referrer;
        bool block;
        uint8 partnercount;
        uint8 level;
        uint8 levelachieve;
        mapping(uint8 => address[]) partners;
        mapping(uint8 => uint[]) D5Matrix;

    }
    
    struct M4User {
        uint8 level; 
        mapping(uint => M4Matrix) M4;
    }
    
    struct M4Matrix {
        uint id;
        address useraddress;
        uint upline;
        uint8 partnercount;
        uint partnerdata;
        uint8 reentry;
    }
    
    uint8[6] private referrallevel = [10,2,2,2,2,2];
    uint16[11] public matrixcount = [0,1,2,4,8,16,32,64,128,256,512];
    
    mapping(address => User) public users;
    mapping(uint8 => M4User) public M4users;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 
    mapping(uint8 => uint[]) public L5Matrix;
    
    //mapping(uint => uint[]) public M4Users;
    //mapping(address => User) public users;
    
    uint public lastUserId = 2;
    
    uint levelPrice = 2500 * 1e6;
   // uint levelPrice = 2500;
    address public owner;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event BuyNew(address indexed user, uint8 indexed level);
    event Payout(address indexed sender,address indexed receiver,uint indexed dividend,uint userid,uint refid,uint8 matrix,uint8 level,uint recid);
    //event payout(address indexed sender,address indexed receiver,uint indexed dividend,uint recid,uint8 matrix,uint8 level,uint8 position);
    
    event Testor21(uint benid,uint topid,uint8 position);
    event Testor22(uint benid,uint topid,uint8 position);
    
    constructor(address ownerAddress) public {
        
        owner = ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnercount : 0,
          //  partners: address(0),
            block: false,
            level : 0,
            levelachieve:0
        });
        
        users[ownerAddress] = user;
        userIds[1] = ownerAddress;
        
        M4Matrix memory m4matrix = M4Matrix({
            id: 1,
            useraddress:owner,
            upline:0,
            partnercount:0,
            partnerdata:0,
            reentry:0
        });
        
        M4User memory m4user = M4User({
            level: 1
        });
        
    
        
        for (uint8 i = 1; i <= 10; i++) {
            users[ownerAddress].D5Matrix[i].push(1);
            L5Matrix[i].push(1);
            //L5Matrix[i].push(1);
            M4users[i] = m4user;
            M4users[i].M4[1]=m4matrix;
         //   M4users[0][M4][i] = m4matrix;
        }
        
        
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
       registration(msg.sender, referrerAddress);
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == levelPrice, "registration cost 2500");
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
            level : 0,
            levelachieve:0
        });
        
       
        users[userAddress] = user;
        users[userAddress].referrer = referrerAddress;
        userIds[lastUserId] = userAddress;
        
        users[referrerAddress].partners[0].push(userAddress);
        users[referrerAddress].partnercount++;
        users[referrerAddress].level++;
        lastUserId++;
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        updateD3Referrer(userAddress,referrerAddress);
    }

    function updateD3Referrer(address userAddress, address referrerAddress) private {
        uint8 level = users[referrerAddress].levelachieve;
        level++;
        if(users[referrerAddress].level == 1){
            emit Payout(userAddress,referrerAddress,levelPrice,users[userAddress].id,users[referrerAddress].id,1,level,1);
        	sendreward(referrerAddress,levelPrice);
        }else if(users[referrerAddress].level == 2){
            emit Payout(userAddress,referrerAddress,0,users[userAddress].id,users[referrerAddress].id,1,level,2);
            if(referrerAddress == owner){
                emit Payout(referrerAddress,owner,levelPrice,users[referrerAddress].id,1,5,level,2);
        	    sendreward(owner,levelPrice);
            }else{
                emit Payout(referrerAddress,users[referrerAddress].referrer,levelPrice,users[referrerAddress].id,users[users[referrerAddress].referrer].id,5,level,2);
        	    sendreward(users[referrerAddress].referrer,levelPrice);
            }
        }else if(users[referrerAddress].level == 3){
            emit Payout(userAddress,referrerAddress,0,users[userAddress].id,users[referrerAddress].id,1,level,3);
            users[referrerAddress].level = 0;
            users[referrerAddress].levelachieve++;
            updateM4Matrix(referrerAddress,1);
        }
        
      }
      
    function setUpperLine5(uint TrefId,uint8 level) internal pure returns(uint){
    	for (uint8 i = 1; i <= level; i++) {
    		if(TrefId == 1){
        		TrefId = 0;
    		}else if(TrefId == 0){
        		TrefId = 0;
    		}else if((1 < TrefId) && (TrefId < 6)){
        		TrefId = 1;
			}else{
				TrefId -= 1;
				if((TrefId % 4) > 0){
				TrefId = uint(TrefId / 4);
				TrefId += 1;
				}else{
				TrefId = uint(TrefId / 4);  
				}
				
			}	
    	}
    	return TrefId;
    }
    
    function upgradeM4Matrix(address userAddress, uint8 level) internal  returns(bool){
        bool flag;
        uint newid = uint(L5Matrix[level].length);
        newid = newid + 1;
        uint topid = setUpperLine5(newid,1);
        M4Matrix memory m4matrix = M4Matrix({
            id: newid,
            useraddress:userAddress,
            upline:topid,
            partnercount:0,
            partnerdata:0,
            reentry:0
        });
        
        L5Matrix[level].push(users[userAddress].id);
        users[userAddress].D5Matrix[level].push(newid);
        M4users[level].M4[newid]=m4matrix;
        M4users[level].M4[topid].partnercount++;
        
        uint8 pos = M4users[level].M4[topid].partnercount;
        
        if(pos == 4){
         flag =  upgradeM4Matrix(M4users[level].M4[topid].useraddress,level+1);
        }
        flag = true;
        return flag;
    }
    
    function updateM4Matrix(address userAddress, uint8 level) private {
    
        uint newid = uint(L5Matrix[level].length);
        bool upgrade;
        newid = newid + 1;
        uint topid = setUpperLine5(newid,1);
        M4Matrix memory m4matrix = M4Matrix({
            id: newid,
            useraddress:userAddress,
            upline:topid,
            partnercount:0,
            partnerdata:0,
            reentry:0
        });
        
        L5Matrix[level].push(users[userAddress].id);
        users[userAddress].D5Matrix[level].push(newid);
        M4users[level].M4[newid]=m4matrix;
        M4users[level].M4[topid].partnercount++;
        
        uint8 pos = M4users[level].M4[topid].partnercount;
        uint8 orgpos = pos;
        uint8 orglvl = level;
        uint orgtopid = topid;
        address benaddress;
        pos -= 1;
            while(pos > 1){
            if(level < 10){
                level++;
                newid = uint(L5Matrix[level].length);
                newid += 1;
                topid = setUpperLine5(newid,1);
                if(topid == 0){
                    topid = 1;
                }
                pos = M4users[level].M4[topid].partnercount;
                }
            }
        
        if(orgpos == 4){
            upgrade =  upgradeM4Matrix(M4users[orglvl].M4[orgtopid].useraddress,orglvl+1);
        }
       
            if((level >= 4) && (M4users[level].M4[topid].partnerdata < 5)){
		        updateM4Matrix(M4users[level].M4[topid].useraddress,1);
		    }else{
		        orglvl = level;
		        M4users[level].M4[topid].partnerdata++;
		        benaddress = M4users[level].M4[topid].useraddress;
                emit Payout(benaddress,benaddress,levelPrice,users[benaddress].id,users[benaddress].id,2,orglvl,topid);
                sendreward(M4users[level].M4[topid].useraddress,levelPrice);
            }
    }
    
    function buyNewLevel(uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == (matrixcount[level] * levelPrice), "invalid price");
        require(level > 3 && level <= 9, "invalid level");
        BuyM4Matrix(msg.sender,level,msg.value);
    }
    
    function BuyM4Matrix(address userAddress, uint8 level,uint reward) private {
    
        uint newid = uint(L5Matrix[level].length);
        bool upgrade;
        newid = newid + 1;
        uint topid = setUpperLine5(newid,1);
        M4Matrix memory m4matrix = M4Matrix({
            id: newid,
            useraddress:userAddress,
            upline:topid,
            partnercount:0,
            partnerdata:0,
            reentry:0
        });
        emit BuyNew(userAddress,level);
        emit Payout(userAddress,userAddress,reward,users[userAddress].id,users[userAddress].id,11,level,topid);
        L5Matrix[level].push(users[userAddress].id);
        users[userAddress].D5Matrix[level].push(newid);
        M4users[level].M4[newid]=m4matrix;
        M4users[level].M4[topid].partnercount++;
        uint8 orglvl = level;
        uint8 orglvl2 = level;
        uint16 maxbenefit = 0;
        uint remain = 0;
        uint8 pos = M4users[level].M4[topid].partnercount;
        uint8 orgpos = pos;
        uint orgtopid = topid;
        uint topid2 = topid;
        address benaddress;
 
        pos-=1;
        
        while(reward > 0){
            //emit Testor21(newid,topid,pos);
            
            maxbenefit = matrixcount[orglvl+ 1];
            benaddress = M4users[orglvl].M4[topid].useraddress;
            if(orglvl < 10){
            if(pos == 0){
               // emit Testor22(newid,remain,uint8(M4users[orglvl].M4[topid].partnerdata));
                M4users[orglvl].M4[topid].partnerdata = M4users[orglvl].M4[topid].partnerdata + (reward / levelPrice);
                topid2 = topid;
                emit Payout(benaddress,benaddress,reward,users[benaddress].id,users[benaddress].id,3,orglvl,topid2);
                sendreward(M4users[orglvl].M4[topid].useraddress,reward);
              reward = 0;
            }else if(pos == 1){
                remain = maxbenefit - M4users[orglvl].M4[topid].partnerdata;
                if(reward >= (remain * levelPrice)){
                    reward -= (remain * levelPrice);
                }else{
                    //remain = reward;
                    reward = 0;
                }
               // emit Testor22(newid,remain,uint8(M4users[orglvl].M4[topid].partnerdata));
                M4users[orglvl].M4[topid].partnerdata = M4users[orglvl].M4[topid].partnerdata + remain;
              //  emit payout(benaddress,benaddress,(remain * levelPrice),4,orglvl,topid);
                sendreward(M4users[orglvl].M4[topid].useraddress,(remain * levelPrice));
                
            }
                orglvl++;
                newid = uint(L5Matrix[orglvl].length);
                newid += 1;
                topid = setUpperLine5(newid,1);
                if(topid == 0){
                    topid = 1;
                }
                pos = M4users[orglvl].M4[topid].partnercount;
                
            }else{
                M4users[orglvl].M4[topid].partnerdata = M4users[orglvl].M4[topid].partnerdata + (reward / levelPrice);
                reward = 0;
                topid2 = topid;
                emit Payout(benaddress,benaddress,(remain * levelPrice),users[benaddress].id,users[benaddress].id,3,orglvl,topid2);
                sendreward(M4users[orglvl].M4[topid].useraddress,(remain * levelPrice));
            }
        }
        
    
        if(orgpos == 4){
        upgrade =  upgradeM4Matrix(M4users[orglvl2].M4[orgtopid].useraddress,orglvl2+1);
        }
      
            
        }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function usersD5Matrix(address userAddress,uint8 level) public view returns(uint, uint[] memory) {
        return (L5Matrix[level].length,users[userAddress].D5Matrix[level]);
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