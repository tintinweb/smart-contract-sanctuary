//SourceUnit: itronworld.sol

pragma solidity >=0.4.23 <0.6.0;

contract Itronworld {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }
    struct Divident{
        address dividentAddress;
        uint amount;
    }


    mapping(uint8 => uint) public stepPrice;
    mapping(uint8 => uint) public stagePrice;

    uint public lastUserId = 3;
    address public owner;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    constructor(address ownerAddress, address adminAddress) public {

        stepPrice[1] = 225000000;
        for (uint8 i = 2; i <= 10; i++) {
            stepPrice[i] = stepPrice[i-1] * 2;
        }

        stagePrice[1] = 150000000;
        for (uint8 x = 2; x <= 10; x++) {
            stagePrice[x] = stagePrice[x-1] * 2;
        }

        owner = ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
            });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        userIds[1] = ownerAddress;


        User memory admin = User({
            id: 2,
            referrer: address(0),
            partnersCount: uint(0)
            });
        users[adminAddress] = admin;
        idToAddress[2] = adminAddress;
        userIds[2] = adminAddress;
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 225 trx, "registration cost 225");
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
            partnersCount: 0
            });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;

        if (!address(uint160(owner)).send(msg.value)) {
            return address(uint160(owner)).transfer(address(this).balance);
        }
    }

    function upgradeExt() external payable {
        upgrade(msg.sender);
    }

    function upgrade(address userAddress) private {
        require(isUserExists(userAddress), "user not exists");

        if (!address(uint160(owner)).send(msg.value)) {
            return address(uint160(owner)).transfer(address(this).balance);
        }
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }


}