/**
 *Submitted for verification at Etherscan.io on 2020-05-20
*/

/**
 * 
 * ██████╗ ██╗   ██╗███████╗██╗  ██╗ ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗██╗███╗   ██╗ ██████╗
 * ██╔══██╗██║   ██║██╔════╝██║  ██║██╔════╝██║  ██║██╔══██╗██║████╗  ██║██║████╗  ██║██╔════╝
 * ██████╔╝██║   ██║███████╗███████║██║     ███████║███████║██║██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
 * ██╔══██╗██║   ██║╚════██║██╔══██║██║     ██╔══██║██╔══██║██║██║╚██╗██║██║██║╚██╗██║██║   ██║
 * ██║  ██║╚██████╔╝███████║██║  ██║╚██████╗██║  ██║██║  ██║██║██║ ╚████║██║██║ ╚████║╚██████╔╝
 * ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
 * 
 * 
 * Auto Run Queue 1 Line Concept !
 * URL: https://rushchaining.com/
 **/
pragma solidity 0.6.4;


contract RushChaining {
    address public ownerWallet;

    struct QueueStruct {
        uint256 id;
        address addr;
    }
    mapping(uint256 => QueueStruct) public queue;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 invest;
        uint256 profit;
        address refAddr;
        uint256 referral;
    }
    mapping(address => UserStruct) public users;

    // Fee for ownerWallet in percentage
    uint256 FEE = 3;
    // Rewards for invitation in percentage
    uint256 REWARD = 7;

    mapping(uint256 => address) public addrByID;
    uint256 public currQueue = 0;

    // Event for notification
    event regEvent(
        address indexed _user,
        address indexed _refAddr,
        uint256 currQueue
    );

    constructor() public {
        ownerWallet = msg.sender;

        UserStruct memory userStruct;
        QueueStruct memory queueStruct;
        currQueue++;

        queueStruct = QueueStruct({id: currQueue, addr: msg.sender});

        userStruct = UserStruct({
            isExist: true,
            id: currQueue,
            invest: 0,
            profit: 0,
            refAddr: msg.sender,
            referral: 0
        });

        users[ownerWallet] = userStruct;
        queue[currQueue] = queueStruct;
        addrByID[currQueue] = ownerWallet;
    }

    function regByID(uint256 _referrerID) public payable {
        require(msg.value == 0.1 ether, "Require 0.1 ether");

        require(_referrerID <= currQueue, "Incorrect referrer Id");
        if (_referrerID <= 0) _referrerID = 1;

        UserStruct memory userStruct;
        QueueStruct memory queueStruct;
        currQueue++;

        queueStruct = QueueStruct({id: currQueue, addr: msg.sender});

        if (!users[msg.sender].isExist) {
            userStruct = UserStruct({
                isExist: true,
                id: currQueue,
                invest: msg.value,
                profit: 0,
                refAddr: addrByID[_referrerID],
                referral: 0
            });

            users[msg.sender] = userStruct;
        } else {
            users[msg.sender].invest = users[msg.sender].invest + msg.value;
        }

        queue[currQueue] = queueStruct;
        addrByID[currQueue] = msg.sender;

        users[addrByID[_referrerID]].referral++;

        // Send fee to ownerWallet
        address(uint160(ownerWallet)).transfer((msg.value * FEE) / 100);
        users[ownerWallet].profit =
            users[ownerWallet].profit +
            (msg.value * FEE) /
            100;

        // Pay for referral
        address(uint160(addrByID[_referrerID])).transfer(
            (msg.value * REWARD) / 100
        );
        users[addrByID[_referrerID]].profit =
            users[addrByID[_referrerID]].profit +
            (msg.value * REWARD) /
            100;

        emit regEvent(msg.sender, addrByID[_referrerID], currQueue);

        if (currQueue > 11) {
            address(uint160(addrByID[currQueue - 11])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 11]].profit =
                users[addrByID[currQueue - 11]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 10])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 10]].profit =
                users[addrByID[currQueue - 10]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 9])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 9]].profit =
                users[addrByID[currQueue - 9]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 8])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 8]].profit =
                users[addrByID[currQueue - 8]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 7])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 7]].profit =
                users[addrByID[currQueue - 7]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 6])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 6]].profit =
                users[addrByID[currQueue - 6]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 5])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 5]].profit =
                users[addrByID[currQueue - 5]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 4])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 4]].profit =
                users[addrByID[currQueue - 4]].profit +
                (msg.value * 10) /
                100;

            address(uint160(addrByID[currQueue - 3])).transfer(
                (msg.value * 10) / 100
            );
            users[addrByID[currQueue - 3]].profit =
                users[addrByID[currQueue - 3]].profit +
                (msg.value * 10) /
                100;
        } else {
            address(uint160(ownerWallet)).transfer(
                (msg.value * (100 - FEE - REWARD)) / 100
            );
            users[ownerWallet].profit =
                users[ownerWallet].profit +
                (msg.value * (100 - FEE - REWARD)) /
                100;
        }
    }
}