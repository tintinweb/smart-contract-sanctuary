/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

contract SUCSESSLIFE {
    using SafeMath for uint256;
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX2Levels;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => X2) x2Matrix;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => uint256) holdAmount;
    }
    
    struct X2 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint256 RefvID;
    }

    uint8 public constant LAST_LEVEL = 7;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address public owner;
    
    IBEP20 private busdToken;
    
    mapping(uint8 => uint) public levelPrice;
    // mapping(uint8 => uint) public blevelPrice;
    // mapping(uint8 => uint) public alevelPrice;
    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    mapping(uint8 => mapping(uint256 => address)) public x2vId_number;
    mapping(uint8 => uint256) public x2CurrentvId;
    mapping(uint8 => uint256) public x2Index;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event UserIncome(address sender ,address receiver,uint256 amount ,string _for);
    event ReEntry(address user,uint8 level);
    
    constructor(address ownerAddress,IBEP20 _busdAddress) public {
        owner = ownerAddress;
        busdToken=_busdAddress;
        
        levelPrice[1] = 10*1e18; 
        levelPrice[2] = 16*1e18;
        levelPrice[3] = 22*1e18;
        levelPrice[4] = 48*1e18;
        levelPrice[5] = 200*1e18;
        levelPrice[6] = 1600*1e18;
        levelPrice[7] = 5000*1e18;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            x3vId_number[i][1]=owner;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
            
            x2vId_number[i][1]=owner;
            x2Index[i]=1;
            x2CurrentvId[i]=1;
        }
        
        users[ownerAddress].activeX2Levels[1] = true;
        userIds[1] = ownerAddress;
    
        emit Registration(ownerAddress, address(0), users[ownerAddress].id, 0);
        emit Upgrade(ownerAddress, users[ownerAddress].referrer, 1, 1);
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
        require(busdToken.balanceOf(userAddress)>=(levelPrice[1]),"Low Balance");
	    require(busdToken.allowance(userAddress,address(this))>=levelPrice[1],"Invalid allowance amount");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "Referrer not exists");
        uint32 size;
        
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeX2Levels[1] = true; 
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        
        busdToken.transferFrom(userAddress ,address(this), levelPrice[1]);
        
        address freeX2Referrer = findFreeXReferrer(userAddress,1);
        users[userAddress].x2Matrix[1].currentReferrer = freeX2Referrer;
        updateX2Referrer(userAddress, freeX2Referrer, 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
	    emit Upgrade(userAddress, users[userAddress].referrer, 1, 1);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    // function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
    //     require(level<=18,"not valid level");
    //     if(referrerAddress==userAddress) return ;
    //     uint256 newIndex=x3Index[level]+1;
    //     x3vId_number[level][newIndex]=userAddress;
    //     x3Index[level]=newIndex;
    //     if(users[referrerAddress].x3Matrix[level].referrals.length < 5) {
    //       users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
    //       users[referrerAddress].holdAmount[level]+=blevelPrice[level];
    //       emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));

    //         if(level<7 && users[referrerAddress].holdAmount[level]>=blevelPrice[level+1]&&users[referrerAddress].x6Matrix[level].referrals.length==5)
    //         {
        
    //                 //ReEntry deduction in holdAmount
    //                 users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-blevelPrice[level];
    //                 users[referrerAddress].x6Matrix[level].referrals = new address[](0);
    //                 users[referrerAddress].x6Matrix[level].reinvestCount+=1;
                    
    //                 //Next Pool Upgradation 
    //                 users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-blevelPrice[level+1];
    //                 x3CurrentvId[level]=x3CurrentvId[level]+1;  
    //                 autoUpgrade(referrerAddress, (level+1)); 
    //                 uint256 _amount= users[referrerAddress].holdAmount[level];
    //                 //Next Level Upgradation 
    //                 autoUpgradeLevel(referrerAddress, (level+1));  
    //                 //bi-noriacal pool user added
    //                 address freeX2Referrer = findFreeX2Referrer(level);
    //                 users[userAddress].x2Matrix[level].currentReferrer = freeX2Referrer;
    //                 updateX2Referrer(referrerAddress, freeX2Referrer, level);
    //                 emit Upgrade(referrerAddress,freeX2Referrer,3,level);
                    
             
    //                  // 20% goes to globalDeduction
    //                 uint256 global_deduct = _amount.mul(20).div(100);
    //                  // 10% goes to direct sponcer
    //                 uint256 direct_sp = _amount.mul(10).div(100);
    //                 if(users[referrerAddress].referrer!=address(0)){
    //                     address(uint160(users[referrerAddress].referrer)).transfer(direct_sp);
    //                     emit UserIncome(referrerAddress,users[referrerAddress].referrer,direct_sp,"Pool Direct Sponcer");
    //                 }
                    
                  
    //                 uint256 all_deduction =direct_sp.add(global_deduct);
    //                 users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-all_deduction;
    //                 //net holding ammount sent to users
    //                 address(uint160(referrerAddress)).transfer(users[referrerAddress].holdAmount[level]);
    //                 emit UserIncome(referrerAddress,referrerAddress,users[referrerAddress].holdAmount[level],"Global Pool");
    //                 users[referrerAddress].holdAmount[level]=0;
    //                 emit ReEntry(referrerAddress,level);
    //              } 
    //         if(level==18 && users[referrerAddress].x6Matrix[level].referrals.length==5)
    //         {
    //             //REEntry  
    //             users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]-blevelPrice[level];
    //             users[referrerAddress].x6Matrix[level].referrals = new address[](0);
    //             users[referrerAddress].x6Matrix[level].reinvestCount+=1;
    //             //Global Pool Income
    //             address(uint160(referrerAddress)).transfer(users[referrerAddress].holdAmount[level]);
    //             emit UserIncome(referrerAddress,referrerAddress,users[referrerAddress].holdAmount[level],"Global Pool");
    //             users[referrerAddress].holdAmount[level]=0;
    //         }
    //     }

        
    // }

    function updateX2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(level<=7,"not valid level");
        if(referrerAddress==userAddress) return ;
        uint256 newIndex=x2Index[level]+1;
        x2vId_number[level][newIndex]=userAddress;
        x2Index[level]=newIndex;
        if(users[referrerAddress].x2Matrix[level].referrals.length < 2) {
          users[referrerAddress].x2Matrix[level].referrals.push(userAddress);
          emit NewUserPlace(userAddress, referrerAddress,1, level, uint8(users[referrerAddress].x2Matrix[level].referrals.length));
        }
        if(users[referrerAddress].x2Matrix[level].referrals.length==2){
          users[referrerAddress].x2Matrix[level].referrals= new address[](0); 
          x2CurrentvId[level]=x2CurrentvId[level]+1; 

        //   emit UserIncome(userAddress,referrerAddress,alevelPrice[level]*2,"Bi-Narical Income");
        }

    }

    function UpgradeLevel(address _user, uint8 level) external payable {
        require(level<=LAST_LEVEL,"Invalid level");
        require(users[_user].activeX2Levels[level]==false,"Level already upgraded!");
        require(busdToken.balanceOf(_user)>=(levelPrice[level]),"Low Balance");
	    require(busdToken.allowance(_user,address(this))==levelPrice[level],"Invalid Upgradation amount");
	    
        users[_user].activeX2Levels[level]=true;
        
        busdToken.transferFrom(_user ,address(this), levelPrice[level]);        
        emit Upgrade(_user, users[_user].referrer, 1, level);
    }
    
    // function autoUpgrade(address _user, uint8 level) private {
    //     users[_user].activeX3Levels[level] = true;
        
    //     address freeX6Referrer = findFreeX6Referrer(level-1);
    //     users[_user].x3Matrix[level-1].currentReferrer = freeX6Referrer;
    //     // updateX6Referrer(_user, freeX6Referrer, level-1);
        
    //     freeX3Referrer = findFreeX3Referrer(level);
    //     users[_user].x3Matrix[level].currentReferrer = freeX3Referrer;
    //     // updateX6Referrer(_user, freeX6Referrer, level);
    //     emit Upgrade(_user, freeX6Referrer, 2, level);
    // }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function findFreeXReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX2Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX3Referrer(uint8 level) public view returns(address){
        uint256 id=x3CurrentvId[level];
        return x3vId_number[level][id];
    }
    
    function findFreeX2Referrer(uint8 level) public view returns(address){
        uint256 id=x2CurrentvId[level];
        return x2vId_number[level][id];
    }
    
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX2Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }
    
    function usersX2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x2Matrix[level].currentReferrer,
                users[userAddress].x2Matrix[level].referrals,
                users[userAddress].x2Matrix[level].blocked,
                users[userAddress].x2Matrix[level].reinvestCount);
    }
    
    function withdraw(uint256 amt,address payable adr) public payable onlyOwner{
        // adr.transfer(amt);
        busdToken.transfer(adr,amt);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}