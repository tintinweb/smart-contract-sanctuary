/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// 0x6dA4867268c80BFcc1Fe4515A841eCa6299557Fb  // owner
// 0xcf1aecc287027f797b99650b1e020ffa0fb0e248  // busd
pragma solidity 0.5.10;
interface BEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CashCapital {
    
    struct User 
    {
	    uint id;
        address referrer;
        uint partnersCount;   
        uint qualify_reinvest;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        mapping(uint8=>bool) activeX3Levels;
        mapping(uint8=>bool) activeX6Levels;
    }
    
    struct X3 
    {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
     struct X6 
    {
        address currentReferrer;
        address[] referrals;
        address[] secondReferrals;
        bool blocked;
        uint reinvestCount;
        bool isUplineBoardBreak;
    }
    
    
    mapping(address => User) public users;      
    mapping(uint => address) public idToAddress;  

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint => uint) public levelPrice;
    mapping(uint => uint) public blevelPrice;
    BEP20 BUSD;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed _from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed _from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress,BEP20 _BUSD) public {
        levelPrice[1] = 100*1e18;
        levelPrice[2] = 100*1e18;
        levelPrice[3] = 100*1e18;
        
        blevelPrice[1] = 100*1e18;
        blevelPrice[2] = 200*1e18;
        blevelPrice[3] = 300*1e18;
        
        BUSD=_BUSD;
         
        owner = ownerAddress;  
        
        User memory user = User({   
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            qualify_reinvest: uint(0)
        });
        
        users[ownerAddress] = user;   
        idToAddress[1] = ownerAddress; 
        
     
        users[ownerAddress].activeX3Levels[1] = true;
        users[ownerAddress].activeX6Levels[1] = true;
        users[ownerAddress].x6Matrix[1].isUplineBoardBreak = true;
            
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

 

    function withdrawLostTRXFromBalance() public {
        require(msg.sender==owner, "onlyOwner");
        address(uint160(owner)).transfer(address(this).balance);
    }
    
     function withdrawLostTokenFromBalance() public {
        require(msg.sender==owner, "onlyOwner");
        BUSD.transfer(owner,address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    
    function startBoard() external payable {
            require(!users[msg.sender].activeX6Levels[1],"Already Activated");
            require(isUserExists(msg.sender), "user is not exists. Register first.");
            require(BUSD.balanceOf(msg.sender)>=(300*1e18),"Low Balance in wallet");
            require(BUSD.allowance(msg.sender,address(this))>=(300*1e18),"Approve Your Token First");
            BUSD.transferFrom(msg.sender,address(this),300*1e18);
            if(users[msg.sender].x6Matrix[1].reinvestCount==0)
            users[users[msg.sender].referrer].qualify_reinvest=users[users[msg.sender].referrer].qualify_reinvest+1;
            
            
            updateBoard(msg.sender);
    }    
    
    function updateBoard(address _user) private 
    {
            address freeX3Referrer = findBoardReferrer(_user);
            users[_user].activeX6Levels[1] = true;
            users[_user].x6Matrix[1].currentReferrer = freeX3Referrer;
            
            if(freeX3Referrer==owner)
            {
                users[freeX3Referrer].x6Matrix[1].referrals.push(_user);
                emit NewUserPlace(_user, freeX3Referrer, 2, 1, uint8(users[freeX3Referrer].x6Matrix[1].referrals.length));
            }
            else
            {
                address topReferrer=users[freeX3Referrer].x6Matrix[1].currentReferrer;
            
                users[freeX3Referrer].x6Matrix[1].referrals.push(_user);
                users[topReferrer].x6Matrix[1].secondReferrals.push(_user);
            
                uint8 _length=uint8(users[topReferrer].x6Matrix[1].secondReferrals.length);
            
                if(_length<4) 
                {
                    BUSD.transfer(topReferrer,blevelPrice[_length]);  
                }
                if(_length==4)
                {
                    if(topReferrer!=owner)
                    {
                    users[topReferrer].activeX6Levels[1] = false;
                    users[topReferrer].x6Matrix[1].isUplineBoardBreak = false;
                    }
                    users[topReferrer].x6Matrix[1].reinvestCount++;
                    users[users[topReferrer].x6Matrix[1].referrals[0]].x6Matrix[1].isUplineBoardBreak=true;
                    users[users[topReferrer].x6Matrix[1].referrals[1]].x6Matrix[1].isUplineBoardBreak=true;
                    users[topReferrer].x6Matrix[1].referrals = new address[](0);  
                    users[topReferrer].x6Matrix[1].secondReferrals = new address[](0);  
                    if(users[topReferrer].partnersCount>=2 && users[topReferrer].qualify_reinvest>=2 &&  topReferrer!=owner)
                    updateBoard(topReferrer);   
                }
              
                
                emit NewUserPlace(_user, freeX3Referrer, 2, 1, uint8(users[freeX3Referrer].x6Matrix[1].referrals.length));
                emit NewUserPlace(_user, topReferrer, 2, 2, uint8(_length));
    
            }
    }
    
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(BUSD.balanceOf(userAddress)>=(111*1e18),"Low Balance in wallet");
        require(BUSD.allowance(userAddress,address(this))>=(111*1e18),"Approve Your Token First");
        require(users[referrerAddress].partnersCount<10,"Only Ten Direct.");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            qualify_reinvest:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
       
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        BUSD.transferFrom(userAddress,address(this),111*1e18);
        address freeX3Referrer = findFreeX3Referrer(userAddress,1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
      

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }
   
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findBoardReferrer(address userAddress) public view returns(address) {
      while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[1]) {
                address ref;
                if(users[userAddress].referrer==owner)
                  ref=owner;
                else
                {
                    ref=users[userAddress].referrer;
                    while(true)
                    {
                        if(users[ref].x6Matrix[1].isUplineBoardBreak)
                        break;
                        ref=users[ref].x6Matrix[1].currentReferrer;
                    }
                }
               
                if(users[ref].x6Matrix[1].referrals.length==2)
                {
                    address ref1=users[ref].x6Matrix[1].referrals[0];
                    if(users[ref1].x6Matrix[1].referrals.length<2)
                    return ref1;
                    
                    address ref2=users[ref].x6Matrix[1].referrals[1];
                    if(users[ref2].x6Matrix[1].referrals.length<2)
                    return ref2;
                }
                else
                {
                 return ref;   
                }
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    

        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }
    
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked);
    }
    
     function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory,address[] memory, bool,uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].secondReferrals,
                users[userAddress].x6Matrix[level].isUplineBoardBreak,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
      function getUserBoard(address userAddress, uint8 level) public view returns(uint256, uint256[] memory,uint256[] memory, bool) {
       
        userAddress=users[userAddress].x6Matrix[level].currentReferrer;
       
        uint256[] memory firstLevel = new uint256[](users[userAddress].x6Matrix[level].referrals.length);
        uint256[] memory secondLevel = new uint256[](users[userAddress].x6Matrix[level].secondReferrals.length);
        for(uint8 i=0;i<users[userAddress].x6Matrix[level].referrals.length;i++)
        {
          firstLevel[i]=users[users[userAddress].x6Matrix[level].referrals[i]].id;  
        }
        
        for(uint8 j=0;j<users[userAddress].x6Matrix[level].secondReferrals.length;j++)
        {
          secondLevel[j]=users[users[userAddress].x6Matrix[level].secondReferrals[j]].id;  
        }
        
        return (users[userAddress].id,
                firstLevel,
                secondLevel,
                users[userAddress].x6Matrix[level].isUplineBoardBreak);
    }

  
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
        
        
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);
     
        BUSD.transfer(receiver,levelPrice[users[receiver].x3Matrix[level].referrals.length]);
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    
     function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable 
     {
        require(msg.sender==owner,"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) 
        {
            BUSD.transfer(_contributors[i],_balances[i]);
        }
    }
    
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}