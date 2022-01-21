/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Initializable {

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

   
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract CrownX is Initializable {
    using SafeMath for uint256;

    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        mapping(uint8 => mapping(uint8 => bool)) activeX3Levels;
        mapping(uint8 => mapping(uint8 => X3)) x3Matrix;
        mapping(uint8 => mapping(uint8 => uint256)) _holdMatrixAmount;
    }

    struct X3 {
        address currentReferrer;
        address[] referrals;
        uint256 reentry;
    }

    uint8 public LAST_MATRIX;

    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;

    uint256 public lastUserId;

    mapping(uint8 => uint8) public matrixLevel;
    mapping(uint8 => mapping(uint8 => uint256)) public matrixPrice;

    address public owner;
    uint256 public ownerFee;

    mapping(uint8 => mapping(uint8 => mapping(uint256 => address))) public x3vId_number;
    mapping(uint8 => mapping(uint8 => uint256)) public x3CurrentvId;
    mapping(uint8 => mapping(uint8 => uint256)) public x3Index;

    event Registration(address indexed user,address indexed referrer,uint256 indexed userId,uint256 referrerId);
    event Upgrade(address indexed user, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user,address indexed referrer,uint8 matrix,uint8 level,uint8 place);
    event UserIncome(address sender,address receiver,uint256 amount,uint8 matrix,uint8 level,string _for);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function initialize(address _ownerAddress)
        public
        initializer
    {
        //default value
        LAST_MATRIX = 5;
        lastUserId = 2;
        owner = _ownerAddress;

        matrixLevel[1]=4;
        matrixLevel[2]=3;
        matrixLevel[3]=2;
        matrixLevel[4]=2;
        matrixLevel[5]=1;

        matrixPrice[1][1] = 50 * 1e15; //up to down left-right
        matrixPrice[1][2] = 40 * 1e15; //auto 
        matrixPrice[1][3] = 64 * 1e15;
        matrixPrice[1][4] = 200 * 1e15;

        matrixPrice[2][1] = 1 * 1e18;
        matrixPrice[2][2] = 800 * 1e15;
        matrixPrice[2][3] = 1280 * 1e15;

        matrixPrice[3][1] = 5 * 1e18;
        matrixPrice[3][2] = 4 * 1e18;

        matrixPrice[4][1] = 10 * 1e18;
        matrixPrice[4][2] = 8 * 1e18;

        matrixPrice[5][1] = 20 * 1e18;

        users[owner].id = 1;
        users[owner].referrer = address(0);
        users[owner].partnersCount = uint256(0);
        idToAddress[1] = owner;

        x3vId_number[1][1][1] = owner;
        x3Index[1][1] = 1;
        x3CurrentvId[1][1] = 1;
        users[owner].activeX3Levels[1][1] = true;

        userIds[1] = owner;

        emit Registration(owner, address(0), users[owner].id, 0);
        emit Upgrade(owner, 1, 1);
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    //user methods

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value>= 75*1e15,"Low Balance");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "Referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        idToAddress[lastUserId] = userAddress;
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].partnersCount = 0;
        users[userAddress].activeX3Levels[1][1] = true;
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        address freeX2Referrer = findFreeReferrer(referrerAddress, 1,1);
        users[userAddress].x3Matrix[1][1].currentReferrer = freeX2Referrer;
        updateX2Referrer(userAddress, freeX2Referrer, 1,1);

        emit Registration(userAddress,referrerAddress,users[userAddress].id,users[referrerAddress].id);
        emit Upgrade(userAddress, 1, 1);
    }

    function updateX2Referrer(
        address userAddress,
        address referrerAddress,
        uint8 matrix,
        uint8 level
    ) private {
        if (userAddress == referrerAddress) return;
        require(level <= matrixLevel[matrix], "not valid level");
        require(matrix<=5,"Invalid Matrix");
        require(referrerAddress != address(0) && userAddress != address(0),"zero id");
        require(users[userAddress].activeX3Levels[matrix][level],"User Matrix not activated");

        users[referrerAddress].x3Matrix[matrix][level].referrals.push(userAddress);
        payable(referrerAddress).transfer(matrixPrice[1][1].mul(10).div(100));
        ownerFee+=matrixPrice[1][1]-matrixPrice[1][1].mul(10).div(100);
        users[referrerAddress]._holdMatrixAmount[matrix][level]+=matrixPrice[1][1]-matrixPrice[1][1].mul(20).div(100);
        emit UserIncome(userAddress,referrerAddress,matrixPrice[1][1].mul(10).div(100),1,1,"Referrer Income");
        emit NewUserPlace(userAddress,referrerAddress,matrix,level,uint8(users[referrerAddress].x3Matrix[matrix][level].referrals.length));
        if (users[referrerAddress].x3Matrix[matrix][level].referrals.length==2) {
            if(level+1 <= matrixLevel[matrix]){
                users[referrerAddress]._holdMatrixAmount[matrix][level]-=matrixPrice[matrix][level];
                users[referrerAddress].activeX3Levels[matrix][level+1]=true;
                payable(referrerAddress).transfer(users[referrerAddress]._holdMatrixAmount[matrix][level]);
                emit UserIncome(referrerAddress,referrerAddress,users[referrerAddress]._holdMatrixAmount[matrix][level], matrix, level, "Matrix Income");
                users[referrerAddress]._holdMatrixAmount[matrix][level]=0;
                uint256 newIndex = x3Index[matrix][level+1] + 1;
                x3vId_number[matrix][level+1][newIndex] = referrerAddress;
                x3Index[matrix][level+1] = newIndex;
                address freeX3Refferrer = findFreeX3Referrer(1,2);
                updateX3Referrer(referrerAddress,freeX3Refferrer,1,2);
            } 
        } 
        
        
    }

    function updateX3Referrer(
        address userAddress,
        address referrerAddress,
        uint8 matrix,
        uint8 level
    ) private {
        require(matrix <= 5, "not valid matrix");
        if (referrerAddress == userAddress) return;

        // uint256 newIndex = x3Index[matrix][level] + 1;
        // x3vId_number[matrix][level][newIndex] = userAddress;
        // x3Index[matrix][level] = newIndex;

        if (users[referrerAddress].x3Matrix[matrix][level].referrals.length <level**2) {
            users[referrerAddress].x3Matrix[matrix][level].referrals.push(userAddress);
            users[referrerAddress]._holdMatrixAmount[matrix][level]+=matrixPrice[matrix][level];
            emit NewUserPlace(userAddress,referrerAddress,matrix,level,uint8(users[referrerAddress].x3Matrix[matrix][level].referrals.length));
            if (level < 2 &&users[referrerAddress].x3Matrix[matrix][level].referrals.length ==level**2) {
                //Next Pool Upgradation
                //users[referrerAddress]._holdMatrixAmount[matrix][level]=users[referrerAddress]._holdMatrixAmount[matrix][level]-matrixPrice[matrix][level+1];
                x3CurrentvId[matrix][level] = x3CurrentvId[matrix][level] + 1;
                emit Upgrade(referrerAddress, matrix, level);
                //autoUpgrade(referrerAddress,matrix,level+1);

                //net holding ammount sent to users
                //users[referrerAddress]._holdMatrixAmount[matrix][level]=0;
            }
        }
    }



    function UpgradeMatrix(address _user, uint8 matrix ,uint8 level) external payable {
        require(
            users[_user].partnersCount >= 2,
            "Please Referrer Atleast Two Member"
        );
        require(matrix <= LAST_MATRIX, "Invalid matrix");
        require(users[_user].activeX3Levels[level][matrix + 2], "Level not activated");
        require(!users[_user].activeX3Levels[matrix][1],"Matrix already upgraded!");


        // matrix activate token tranfer in contract
        users[_user].activeX3Levels[matrix][1] = true;
        address freeX3Referrer = findFreeX3Referrer(matrix, 1);

        updateX3Referrer(_user, freeX3Referrer, matrix, 1);
        emit Upgrade(_user, matrix, 1);
    }

    function matrixLevel2Upgrade(address _user, uint8 matrix) external payable {
        require(
            users[_user].activeX3Levels[matrix][1],
            "Upgrade Level One First"
        );
        //require(users[_user].x3Matrix[matrix][1].referrals.length >=3,"Matrix Level One is Incomplete");
    
        uint256 newIndex = x3Index[matrix][2] + 1;
        x3vId_number[matrix][2][newIndex] = _user;
        x3Index[matrix][2] = newIndex;
        users[_user].activeX3Levels[matrix][2] = true;
        address freeX3Referrer = findFreeX3Referrer(matrix, 2);
        users[_user].x3Matrix[matrix][2].currentReferrer = freeX3Referrer;

        //updateX3Referrer(_user, freeX3Referrer,matrix, level);
        if (users[freeX3Referrer].x3Matrix[matrix][2].referrals.length < 9) {
            users[freeX3Referrer].x3Matrix[matrix][2].referrals.push(_user);
            payable(freeX3Referrer).transfer(matrixPrice[matrix][2]);
            emit UserIncome(
                _user,
                freeX3Referrer,
                matrixPrice[matrix][2],
                matrix,
                2,
                "Global Matrix Income"
            );
            emit NewUserPlace(
                _user,
                freeX3Referrer,
                matrix,
                2,
                uint8(
                    users[freeX3Referrer].x3Matrix[matrix][2].referrals.length
                )
            );
        }

        if (users[freeX3Referrer].x3Matrix[matrix][2].referrals.length == 9) {
            x3CurrentvId[matrix][2] = x3CurrentvId[matrix][2] + 1;
            freeX3Referrer = findFreeX3Referrer(matrix, 2);
            users[_user].x3Matrix[matrix][2].currentReferrer = freeX3Referrer;
            users[freeX3Referrer].x3Matrix[matrix][2].referrals.push(_user);
            payable(freeX3Referrer).transfer(matrixPrice[matrix][2]);
            emit UserIncome(
                _user,
                freeX3Referrer,
                matrixPrice[matrix][2],
                matrix,
                2,
                "Global Matrix Income"
            );
            emit NewUserPlace(
                _user,
                freeX3Referrer,
                matrix,
                2,
                uint8(
                    users[freeX3Referrer].x3Matrix[matrix][2].referrals.length
                )
            );
        }
        emit Upgrade(_user, matrix, 2);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findFreeReferrer(address _user, uint8 matrix, uint8 level)
        public
        view
        returns (address)
    {
        if (users[_user].x3Matrix[matrix][level].referrals.length < 2) return _user;

        address[] memory referrals = new address[](1022);
        referrals[0] = users[_user].x3Matrix[matrix][level].referrals[0];
        referrals[1] = users[_user].x3Matrix[matrix][level].referrals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 1022; i++) {
            if (users[referrals[i]].x3Matrix[matrix][level].referrals.length == 2) {
                if (i < 62) {
                    referrals[(i + 1) * 2] = users[referrals[i]]
                        .x3Matrix[matrix][level]
                        .referrals[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]]
                        .x3Matrix[matrix][level]
                        .referrals[1];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, "No Free Referrer");

        return freeReferrer;
    }

    function findFreeX3Referrer(uint8 matrix, uint8 level)
        public
        view
        returns (address)
    {
        uint256 id = x3CurrentvId[matrix][level];
        return x3vId_number[matrix][level][id];
    }

    function usersActiveX3Levels(
        address userAddress,
        uint8 matrix,
        uint8 level
    ) public view returns (bool) {
        return users[userAddress].activeX3Levels[matrix][level];
    }

    function usersHoldAmount(
        address userAddress,
        uint8 matrix,
        uint8 level
    ) public view returns (uint256) {
        return users[userAddress]._holdMatrixAmount[matrix][level];
    }


    function usersX3Matrix(
        address userAddress,
        uint8 matrix,
        uint8 level
    ) public view returns (address, address[] memory) {
        return (
            users[userAddress].x3Matrix[matrix][level].currentReferrer,
            users[userAddress].x3Matrix[matrix][level].referrals
        );
    }


    function withdrawETH(uint256 amt, address payable adr)
        public
        payable
        onlyOwner
    {
        adr.transfer(amt);
    }

}