/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

contract SmartOne {
    using SafeMath for uint256;

    address payable private owner; // Smart Contract Owner (Who deploys)
    address payable private adminAddress; // Project manager

    uint256 public PAYMENT_FACTOR = 1000;
    uint256 private constant DIVIDER = 1000;

    uint256 private constant SIGN_UP_AMOUNT = 0.016 ether;
    uint256 private constant ACTIVATE_AMOUNT = 0.016 ether;

    uint256 private constant USERS_PER_POOL = 4;
    uint256 private constant POOL_NUMBER = 5;

    address[4][] public pool = [
        [address(0), address(0), address(0), address(0)],
        [address(0), address(0), address(0), address(0)],
        [address(0), address(0), address(0), address(0)],
        [address(0), address(0), address(0), address(0)],
        [address(0), address(0), address(0), address(0)]
    ];

    uint256[] userPayments = [0.12 ether, 0.24 ether, 0.448 ether, 1.12 ether, 2.24 ether];
    uint256[] adminPayments = [0.12 ether, 0.24 ether, 0.448 ether, 1.12 ether, 2.24 ether];
        
    struct User {
        bool signedUp;
        bool active;
    }

    mapping(address => User) internal users;

    event SignUp(address indexed user, uint256 amount);
    event ActivePool(address indexed user, uint256 amount);
    event UpgradeUser(address indexed user, uint256 amount, uint256 pool);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function isUserSignedUp(address user) internal view returns (bool) {
        return (users[user].signedUp == true);
    }

    function isUserActive(address user) internal view returns (bool) {
        return (users[user].active == true);
    }

    // Main functions
    function joinMe() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isUserSignedUp(msg.sender), "User is already registered");
        require(!isUserActive(msg.sender), "User is already active");
        require(msg.value >= 1e8, "Zero amount");
        require(
            msg.value >= SIGN_UP_AMOUNT.add(ACTIVATE_AMOUNT).mul(PAYMENT_FACTOR).div(DIVIDER),
            "Deposit is below minimum amount"
        );

        User storage user = users[msg.sender];

        if (user.signedUp == false && user.active == false) {
            payable(adminAddress).transfer(SIGN_UP_AMOUNT);

            user.signedUp = true;
            user.active = true;
            addUserPool(msg.sender);

            emit SignUp(msg.sender, SIGN_UP_AMOUNT);
            emit ActivePool(msg.sender, ACTIVATE_AMOUNT);
        }
    }

    function signUp() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isUserSignedUp(msg.sender), "User is already registered");
        require(msg.value >= 1e8, "Zero amount");
        require(
            msg.value >= SIGN_UP_AMOUNT.mul(PAYMENT_FACTOR).div(DIVIDER),
            "Deposit is below minimum amount"
        );

        User storage user = users[msg.sender];

        if (user.signedUp == false) {
            payable(adminAddress).transfer(msg.value);
            user.signedUp = true;
            emit SignUp(msg.sender, msg.value);
        }
    }

    function activatePool() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(isUserSignedUp(msg.sender), "The user must be registered");
        require(!isUserActive(msg.sender), "User is already active");
        require(msg.value >= 1e8, "Zero amount");
        require(
            msg.value >= ACTIVATE_AMOUNT.mul(PAYMENT_FACTOR).div(DIVIDER),
            "Deposit is below minimum amount"
        );

        User storage user = users[msg.sender];

        if (user.active == false) {
            user.active = true;
            addUserPool(msg.sender);
            emit ActivePool(msg.sender, msg.value);
        }
    }

    function systemPayment(uint256 n, address user) internal {
        if (user != address(0)) {
            User storage userData = users[user];
            
            if(n == 4){
                userData.active = false;
            }

            if(address(this).balance > userPayments[n]){
                // User payment
                payable(user).transfer(userPayments[n]);
                emit UpgradeUser(user, userPayments[n], n);
            }

            if(address(this).balance > adminPayments[n]){
                // Admin payment
                payable(adminAddress).transfer(adminPayments[n]);
            }
        }
    }

    function addUserPool(address user) internal {
        address[4][] memory memoryPool = pool;

        // Primer usuario
        address firstUser = address(0);
        uint256 emptySpace = 9;

        // Buscar el ultimo espacio vacio en el pool 1
        for (uint256 j = 0; j < USERS_PER_POOL; j++) {
            if (pool[0][j] == address(0)) {
                emptySpace = j;
                break;
            }
        }

        if (emptySpace != 9) {
            pool[0][emptySpace] = user;
        } else {
            // Desplazar
            for (uint256 n = 0; n < POOL_NUMBER; n++) {
                // Si es el primer pool liberar el ultimo espacio
                if (n == 0) {
                    pool[n][0] = memoryPool[n][1];
                    pool[n][1] = memoryPool[n][2];
                    pool[n][2] = memoryPool[n][3];
                    pool[n][3] = user;
                    user = address(0);
                } else {
                    if (user == address(0) && firstUser == address(0)) break;

                    // Buscar ultimo espacio vacio en el pool
                    uint256 emptySpace2 = 9;

                    for (uint256 k = 0; k < USERS_PER_POOL; k++) {
                        if (pool[n][k] == address(0)) {
                            emptySpace2 = k;
                            break;
                        }
                    }

                    // Si existe un espacio libre usarlo, sino desplazar
                    if (emptySpace2 != 9) {
                        pool[n][emptySpace2] = firstUser;
                        systemPayment(n - 1, firstUser);
                        firstUser = address(0);
                    } else {
                        pool[n][0] = memoryPool[n][1];
                        pool[n][1] = memoryPool[n][2];
                        pool[n][2] = memoryPool[n][3];
                        pool[n][3] = firstUser;
                        systemPayment(n - 1, firstUser);
                        firstUser = address(0);
                    }
                }

                if (memoryPool[n][3] != address(0) || n == 4) {
                    firstUser = memoryPool[n][0];
                } 
                    
            }

            if(firstUser != address(0)){
                systemPayment(4, firstUser);
            }
        }
    }

    function setPaymentFactor(uint256 percent) public onlyOwner returns (uint256){
        PAYMENT_FACTOR = percent;
        return PAYMENT_FACTOR.div(DIVIDER);
    }
   
    
    function setAdmin(address user) public onlyOwner returns(bool){
        adminAddress = payable(user);
        return true;
    } 

    function withDrawFounds(uint256 amount) public onlyOwner {
        if (address(this).balance > amount) 
        {
            payable(adminAddress).transfer(amount);
        }
    }

    function getPaymentFactor() public  view returns (uint256)
    {
        return PAYMENT_FACTOR.div(DIVIDER);
    }

    function getPool() public  view returns (address[4][] memory)
    {
        return pool;
    }

    function getUserData(address _user) public view returns (bool signedUp, bool active)
    {
        User storage user = users[_user];
        return (user.signedUp, user.active);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}