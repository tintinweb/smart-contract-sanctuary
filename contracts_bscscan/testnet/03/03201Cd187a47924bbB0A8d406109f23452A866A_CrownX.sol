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
        mapping(uint8 => bool) activeX2Levels;
        mapping(uint8 => mapping(uint8 => bool)) activeX3Levels;
        mapping(uint8 => X2) x2Matrix;
        mapping(uint8 => mapping(uint8 => X3)) x3Matrix;
        mapping(uint8 => uint256) holdAmount;
        mapping(uint8 => mapping(uint8 => uint256)) _holdMatrixAmount;
    }

    struct X2 {
        address currentReferrer;
        address[] referrals;
    }

    struct X3 {
        address currentReferrer;
        address[] referrals;
    }

    uint8 public LAST_LEVEL;
    uint8 public LAST_MATRIX;

    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;

    uint256 public lastUserId;

    mapping(uint8 => uint256) public levelPrice;
    mapping(uint8 => mapping(uint8 => uint256)) public matrixPrice;

    address public owner;

    mapping(uint8 => mapping(uint8 => mapping(uint256 => address)))
        public x3vId_number;
    mapping(uint8 => mapping(uint8 => uint256)) public x3CurrentvId;
    mapping(uint8 => mapping(uint8 => uint256)) public x3Index;

    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        uint256 referrerId
    );
    event Upgrade(address indexed user, uint8 matrix, uint8 level);
    event NewUserPlace(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint8 level,
        uint8 place
    );
    event UserIncome(
        address sender,
        address receiver,
        uint256 amount,
        uint8 matrix,
        uint8 level,
        string _for
    );

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

        for (uint8 i = 1; i <= LAST_MATRIX; i++) {
            x3vId_number[i][1][1] = owner;
            x3vId_number[i][2][1] = owner;
            x3Index[i][1] = 1;
            x3Index[i][2] = 1;
            x3CurrentvId[i][1] = 1;
            x3CurrentvId[i][2] = 1;
            users[owner].activeX3Levels[i][1] = true;
            users[owner].activeX3Levels[i][2] = true;
        }

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[owner].activeX2Levels[i] = true;
        }

        userIds[1] = owner;

        emit Registration(owner, address(0), users[owner].id, 0);
        emit Upgrade(owner, 0, 1);
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    //user methods

    function registration(address userAddress, address referrerAddress)
        private
    {
        require(
          msg.value>= 75*1e15,
            "Low Balance"
        );
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
        users[userAddress].activeX2Levels[1] = true;
        userIds[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;

        address freeX2Referrer = findFreeReferrer(referrerAddress, 1);
        users[userAddress].x2Matrix[1].currentReferrer = freeX2Referrer;
        updateX2Referrer(userAddress, freeX2Referrer, 1);

        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id
        );
        emit Upgrade(userAddress, 0, 1);
    }

    function updateX2Referrer(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        if (userAddress == referrerAddress) return;
        require(level <= 7, "not valid level");
        require(
            referrerAddress != address(0) && userAddress != address(0),
            "zero id"
        );
        require(
            users[userAddress].activeX2Levels[level],
            " User Level not activated"
        );

        users[referrerAddress].x2Matrix[level].referrals.push(userAddress);
        if (level == 1) {
            payable(referrerAddress).transfer(levelPrice[1]);
            emit UserIncome(
                userAddress,
                referrerAddress,
                levelPrice[1],
                0,
                1,
                "Level Income"
            );
        } else {
            if (
                users[referrerAddress].activeX2Levels[level] &&
                users[referrerAddress].partnersCount >= 1
            ) {
                payable(referrerAddress).transfer(levelPrice[level].mul(50).div(100)
                );
                emit UserIncome(
                    userAddress,
                    referrerAddress,
                    levelPrice[level].mul(50).div(100),
                    0,
                    level,
                    "Level Income"
                );
            } else {
                //users[referrerAddress].holdAmount[level]+=levelPrice[level].mul(50).div(100);
                address _referrer = referrerAddress;
                for (uint8 k = 1; k <= 30; k++) {
                    if (
                        !users[_referrer].activeX2Levels[level] ||
                        users[_referrer].partnersCount == 0
                    ) {
                        _referrer = users[_referrer].x2Matrix[1].currentReferrer;
                    } else {
                        break;
                    }
                }
                if (
                    !users[_referrer].activeX2Levels[level] ||
                    users[_referrer].partnersCount == 0
                ) {
                    _referrer = owner;
                }
                payable(_referrer).transfer(levelPrice[level].mul(50).div(100));
                
                emit UserIncome(
                    userAddress,
                    _referrer,
                    levelPrice[level].mul(50).div(100),
                    0,
                    level,
                    "Level Income"
                );
            }
        }
        emit NewUserPlace(
            userAddress,
            referrerAddress,
            0,
            level,
            uint8(users[referrerAddress].x2Matrix[level].referrals.length)
        );
    }

    function updateX3Referrer(
        address userAddress,
        address referrerAddress,
        uint8 matrix,
        uint8 level
    ) private {
        require(matrix <= LAST_MATRIX, "not valid matrix");
        if (referrerAddress == userAddress) return;

        uint256 newIndex = x3Index[matrix][level] + 1;
        x3vId_number[matrix][level][newIndex] = userAddress;
        x3Index[matrix][level] = newIndex;

        // sending matrix income to direct upline
        payable(referrerAddress).transfer(matrixPrice[matrix][level]);
        emit UserIncome(
            userAddress,
            referrerAddress,
            matrixPrice[matrix][level],
            matrix,
            level,
            "Global Matrix Income"
        );
        emit NewUserPlace(
            userAddress,
            referrerAddress,
            matrix,
            level,
            uint8(
                users[referrerAddress].x3Matrix[matrix][level].referrals.length
            )
        );

        uint8 member_count = level == 1 ? 3 : 9;
        if (
            users[referrerAddress].x3Matrix[matrix][level].referrals.length <
            member_count
        ) {
            users[referrerAddress].x3Matrix[matrix][level].referrals.push(
                userAddress
            );
            //users[referrerAddress]._holdMatrixAmount[matrix][level]+=matrixPrice[matrix][level];

            if (
                level < 2 &&
                users[referrerAddress]
                    .x3Matrix[matrix][level]
                    .referrals
                    .length ==
                member_count
            ) {
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

    function UpgradeLevel(address _user, uint8 level) external payable {
        require(level <= LAST_LEVEL, "Invalid level");
        require(!users[_user].activeX2Levels[level], "Level already upgraded!");

        users[_user].activeX2Levels[level] = true;


        if (users[_user].holdAmount[level] != 0) {
            payable(_user).transfer(users[_user].holdAmount[level]);
            emit UserIncome(
                address(0),
                _user,
                users[_user].holdAmount[level],
                level,
                0,
                "Holding Income"
            );
            users[_user].holdAmount[level] = 0;
        }

        address referrerAddress = _user;
        for (uint8 i = 1; i <= level; i++) {
            if (referrerAddress != address(0))
                referrerAddress = users[referrerAddress]
                    .x2Matrix[1]
                    .currentReferrer;
            else break;
        }
        if (referrerAddress != address(0))
            updateX2Referrer(_user, referrerAddress, level);
        payable(users[_user].referrer).transfer(levelPrice[level].mul(50).div(100));
        emit Upgrade(_user, 0, level);
        emit UserIncome(
            _user,
            users[_user].referrer,
            levelPrice[level].mul(50).div(100),
            0,
            level,
            "Sponcer Income"
        );
    }

    function UpgradeMatrix(address _user, uint8 matrix) external payable {
        require(
            users[_user].partnersCount >= 2,
            "Please Referrer Atleast Two Member"
        );
        require(matrix <= LAST_MATRIX, "Invalid matrix");
        require(users[_user].activeX2Levels[matrix + 2], "Level not activated");
        require(
            !users[_user].activeX3Levels[matrix][1],
            "Matrix already upgraded!"
        );


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

    function findFreeReferrer(address _user, uint8 level)
        public
        view
        returns (address)
    {
        if (users[_user].x2Matrix[level].referrals.length < 2) return _user;

        address[] memory referrals = new address[](1022);
        referrals[0] = users[_user].x2Matrix[level].referrals[0];
        referrals[1] = users[_user].x2Matrix[level].referrals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 1022; i++) {
            if (users[referrals[i]].x2Matrix[level].referrals.length == 2) {
                if (i < 62) {
                    referrals[(i + 1) * 2] = users[referrals[i]]
                        .x2Matrix[level]
                        .referrals[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]]
                        .x2Matrix[level]
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

    function usersActiveX2Levels(address userAddress, uint8 level)
        public
        view
        returns (bool)
    {
        return users[userAddress].activeX2Levels[level];
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

    function usersX2Matrix(address userAddress, uint8 level)
        public
        view
        returns (address, address[] memory)
    {
        return (
            users[userAddress].x2Matrix[level].currentReferrer,
            users[userAddress].x2Matrix[level].referrals
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