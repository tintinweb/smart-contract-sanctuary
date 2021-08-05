/**
 *Submitted for verification at Etherscan.io on 2020-12-24
*/

// SmartWay Ticket
// https://dappticket.com
//
/// SPDX-License-Identifier: MIT
pragma solidity =0.7.2;

contract Ticket {
    uint256 public uid = 1;

    uint8 public constant MAX_LEVEL = 12; // Maximum number of levels

    uint256 public constant LEFT_PRICE = 0.025 ether; // Starting price

    enum Site {X3, X4}

    struct X3 {
        uint8 status; // 0: nonactivated; 1: open; 2: open and blocked;
        uint256 reinvestCount;
        address[] points;
        address ref;
    }

    struct X4 {
        uint8 status; // 0: nonactivated; 1: open; 2: open and blocked;
        uint256 reinvestCount;
        address[] firstPoints;
        address[] leftPoints;
        address[] rightPoints;
        address ref;
    }

    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        mapping(uint8 => X3) x3Site;
        mapping(uint8 => X4) x4Site;
    }

    enum Relation {
        Direct, // 0 Match to management account
        Partner, // 1 Normally matched
        Slide, // 2
        Gift // The junior partner surpasses his superior
    }

    event NewUser(
        address indexed _user,
        address indexed _referrer,
        uint8 level
    );

    event Transfer(
        Site indexed _matrix,
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        uint8 _level,
        bool blocked,
        uint256 _skip
    );

    event IndexUser(
        Site indexed _matrix,
        address indexed _user,
        address indexed _referrer,
        address _partner,
        uint8 _level,
        uint256 _skip,
        Relation _relation,
        uint8 _buyAgain,
        uint8 _pointLevel,
        uint256 _reinvestNumber,
        bool _active
    );
    address public owner;
    mapping(uint8 => uint256) public levelPrice;
    mapping(address => User) public users;
    mapping(uint256 => address) public userIDToAddress;

    constructor(address _ownerAddress) {
        owner = _ownerAddress;
        levelPrice[1] = LEFT_PRICE;
        for (uint8 i = 2; i <= MAX_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        createUser(_ownerAddress, address(0x0), MAX_LEVEL);
    }

    receive() external payable {
        if (msg.data.length == 0) {
            register(msg.sender, owner);
            return;
        }
        register(msg.sender, bytesToAddress(msg.data));
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function register(address ref) external payable returns (bool) {
        return register(msg.sender, ref);
    }

    function register(address userAddress, address ref) private returns (bool) {
        require(msg.value == LEFT_PRICE * 2, "Wrong registration cost.");
        require(!isUserExists(userAddress), "User exists.");
        require(isUserExists(ref), "Referrer not exists.");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Cannot be a contract");
        createUser(userAddress, ref, 1);
        // X3
        x3Transfer(userAddress, ref, 1, LEFT_PRICE);
        // X4
        x4Transfer(userAddress, ref, 1, LEFT_PRICE);
        return true;
    }

    function createUser(
        address userAddress,
        address ref,
        uint8 level
    ) private returns (uint256 userID) {
        require(level <= MAX_LEVEL, "Level exceeds maximum limit.");
        userIDToAddress[uid] = userAddress;
        User storage user = users[userAddress];
        user.id = uid;
        user.referrer = ref;
        for (uint8 i = 1; i <= level; i++) {
            user.x3Site[i].status = 1;
            user.x4Site[i].status = 1;
        }
        if (ref != address(0x0)) {
            users[ref].partnersCount++;
        }
        userID = uid;
        uid++;
        emit NewUser(userAddress, ref, level);
    }

    function buyX3Level(uint8 level) public payable {
        buyNewLevel(Site.X3, level);
    }

    function buyX4Level(uint8 level) public payable {
        buyNewLevel(Site.X4, level);
    }

    function buyNewLevel(Site matrix, uint8 level) private {
        uint256 amount = levelPrice[level];
        require(level > 1 && level <= MAX_LEVEL, "Invalid level.");
        require(msg.value == amount, "Invalid price.");
        require(
            isUserExists(msg.sender),
            "User does not exist, please register first."
        );
        if (matrix == Site.X3) {
            require(
                users[msg.sender].x3Site[level].status == 0,
                "The current X3 level has been activated."
            );
            require(
                users[msg.sender].x3Site[level - 1].status > 0,
                "Can not leapfrog upgrade."
            );
            x3Transfer(msg.sender, users[msg.sender].referrer, level, amount);
            users[msg.sender].x3Site[level].status = 1;
            users[msg.sender].x3Site[level - 1].status = 1;
        } else {
            require(
                users[msg.sender].x4Site[level].status == 0,
                "The current X4 level has been activated."
            );
            require(
                users[msg.sender].x4Site[level - 1].status > 0,
                "Can not leapfrog upgrade."
            );
            x4Transfer(msg.sender, users[msg.sender].referrer, level, amount);
            users[msg.sender].x4Site[level].status = 1;
            users[msg.sender].x4Site[level - 1].status = 1;
        }
    }

    // x3Transfer
    function x3Transfer(
        address userAddress,
        address ref,
        uint8 level,
        uint256 amount
    ) private {
        (address receiver, uint256 skip) = updateX3(userAddress, ref, level, 0);
        transfer(Site.X3, level, userAddress, receiver, skip, amount);
    }

    function transfer(
        Site matrix,
        uint8 level,
        address from,
        address receiver,
        uint256 skip,
        uint256 amount
    ) private {
        if (matrix == Site.X3) {
            while (true) {
                X3 memory x3 = users[receiver].x3Site[level];
                if (x3.status == 2) {
                    // blocked
                    emit Transfer(
                        matrix,
                        from,
                        receiver,
                        amount,
                        level,
                        true,
                        skip
                    );
                    receiver = x3.ref;
                } else {
                    break;
                }
            }
        } else {
            while (true) {
                X4 memory x4 = users[receiver].x4Site[level];
                if (x4.status == 2) {
                    // blocked
                    emit Transfer(
                        matrix,
                        from,
                        receiver,
                        amount,
                        level,
                        true,
                        skip
                    );
                    receiver = x4.ref;
                } else {
                    break;
                }
            }
        }
        emit Transfer(matrix, from, receiver, amount, level, false, skip);
        address(uint160(receiver)).transfer(amount);
    }

    // x3 update
    // @userAddress Register or upgrade user address
    // @return The address to receive funds
    function updateX3(
        address userAddress,
        address referrer,
        uint8 level,
        uint256 skip
    ) private returns (address, uint256) {
        address ref = findX3ActiveReferrer(referrer, level);
        User storage user = users[userAddress];
        X3 storage x3 = users[ref].x3Site[level];
        Relation relation = Relation.Direct;
        if (ref != referrer) {
            relation = Relation.Gift;
        }
        if (user.x3Site[level].ref != ref) {
            user.x3Site[level].ref = ref;
        }
        if (x3.points.length < 2) {
            x3.points.push(userAddress);
            emit IndexUser(
                Site.X3,
                userAddress,
                ref,
                address(0x0),
                level,
                skip,
                relation,
                0,
                1,
                x3.reinvestCount,
                x3.status == 1
            );
            return (ref, skip);
        }
        x3.points = new address[](0);
        x3.reinvestCount++;
        if (ref == owner) {
            emit IndexUser(
                Site.X3,
                userAddress,
                ref,
                address(0x0),
                level,
                skip,
                relation,
                1,
                1,
                x3.reinvestCount - 1,
                true
            );
            return (ref, skip);
        }
        if (
            level < MAX_LEVEL &&
            users[ref].x3Site[level + 1].status == 0 &&
            x3.status == 1
        ) {
            x3.status = 2;
            emit IndexUser(
                Site.X3,
                userAddress,
                ref,
                address(0x0),
                level,
                skip,
                relation,
                2,
                1,
                x3.reinvestCount - 1,
                false
            );
        } else {
            emit IndexUser(
                Site.X3,
                userAddress,
                ref,
                address(0x0),
                level,
                skip,
                relation,
                1,
                1,
                x3.reinvestCount - 1,
                x3.status == 1
            );
        }
        // Buy agin
        return updateX3(ref, users[ref].referrer, level, skip + 1);
    }

    function x4Transfer(
        address userAddress,
        address ref,
        uint8 level,
        uint256 amount
    ) private {
        (address receiver, uint256 skip) = updateX4(userAddress, ref, level, 0);
        transfer(Site.X4, level, userAddress, receiver, skip, amount);
    }

    // x4 update
    // @userAddress Register or upgrade user address
    // @return The address to receive funds
    function updateX4(
        address userAddress,
        address referrer,
        uint8 level,
        uint256 skip
    ) private returns (address, uint256) {
        address ref = findX4ActiveReferrer(referrer, level);
        X4 storage x4 = users[ref].x4Site[level];
        Relation relation = Relation.Direct;
        if (ref != referrer) {
            relation = Relation.Gift;
        }
        address partner = address(0x0);
        if (x4.firstPoints.length < 2) {
            partner = ref;
            x4.firstPoints.push(userAddress);
            users[userAddress].x4Site[level].ref = ref;
            emit IndexUser(
                Site.X4,
                userAddress,
                ref,
                address(0x0),
                level,
                skip,
                relation,
                0,
                1,
                x4.reinvestCount,
                x4.status == 1
            );
            if (ref == owner) {
                return (owner, skip);
            }
            // isSlide = false
            return
                updateX4Second(userAddress, x4.ref, level, ref, relation, skip);
        } else {
            // isSlide = true
            return
                updateX4Second(
                    userAddress,
                    ref,
                    level,
                    address(0x0),
                    relation,
                    skip
                );
        }
    }

    // Update the second level points
    function updateX4Second(
        address userAddress,
        address ref,
        uint8 level,
        address partner,
        Relation relation,
        uint256 skip
    ) private returns (address receiver, uint256) {
        X4 storage x4 = users[ref].x4Site[level];
        // Update the first level point
        bool isSlide = partner == address(0x0);
        address slideTo;
        if (isSlide) {
            if (x4.leftPoints.length <= x4.rightPoints.length) {
                // left
                slideTo = x4.firstPoints[0];
            } else {
                // right
                slideTo = x4.firstPoints[1];
            }
            X4 storage slideX4 = users[slideTo].x4Site[level];
            slideX4.firstPoints.push(userAddress);
            users[userAddress].x4Site[level].ref = slideTo;
            emit IndexUser(
                Site.X4,
                userAddress,
                slideTo,
                partner,
                level,
                skip,
                Relation.Slide,
                0,
                1,
                slideX4.reinvestCount,
                slideX4.status == 1
            );
        } else {
            slideTo = partner;
        }
        if (x4.rightPoints.length + x4.leftPoints.length >= 3) {
            // Determine whether the loop can continue
            x4.leftPoints = new address[](0);
            x4.rightPoints = new address[](0);
            x4.firstPoints = new address[](0);
            x4.ref = address(0x0);
            x4.reinvestCount++;
            if (
                level < MAX_LEVEL &&
                users[ref].x4Site[level + 1].status == 0 &&
                x4.status == 1
            ) {
                x4.status = 2;
                emit IndexUser(
                    Site.X4,
                    userAddress,
                    ref,
                    slideTo,
                    level,
                    skip,
                    relation,
                    2,
                    2,
                    x4.reinvestCount - 1,
                    false
                );
            } else {
                emit IndexUser(
                    Site.X4,
                    userAddress,
                    ref,
                    slideTo,
                    level,
                    skip,
                    relation,
                    1,
                    2,
                    x4.reinvestCount - 1,
                    x4.status == 1
                );
            }
            if (ref == owner) {
                return (owner, skip);
            }
            // Buy again
            return updateX4(ref, users[ref].referrer, level, skip + 1);
        }
        // Enough points
        if (slideTo == x4.firstPoints[0]) {
            x4.leftPoints.push(userAddress);
        } else {
            x4.rightPoints.push(userAddress);
        }
        if (isSlide) {
            emit IndexUser(
                Site.X4,
                userAddress,
                ref,
                slideTo,
                level,
                skip,
                relation,
                0,
                2,
                x4.reinvestCount,
                x4.status == 1
            );
        } else {
            emit IndexUser(
                Site.X4,
                userAddress,
                ref,
                slideTo,
                level,
                skip,
                Relation.Partner,
                0,
                2,
                x4.reinvestCount,
                x4.status == 1
            );
        }
        return (ref, skip);
    }

    function findX3ActiveReferrer(address addr, uint8 level)
        public
        view
        returns (address)
    {
        while (true) {
            if (users[addr].x3Site[level].status > 0) {
                return addr;
            }
            addr = users[addr].referrer;
        }
        return addr;
    }

    function findX4ActiveReferrer(address addr, uint8 level)
        public
        view
        returns (address)
    {
        while (true) {
            if (users[addr].x4Site[level].status > 0) {
                return addr;
            }
            addr = users[addr].referrer;
        }
        return addr;
    }

    // Get x3 information
    // @param addr user address
    // @param level level level
    function userX3Site(address addr, uint8 level)
        public
        view
        returns (
            uint8 status,
            uint256 reinvestCount,
            address[] memory points,
            address ref
        )
    {
        X3 memory x3 = users[addr].x3Site[level];
        status = x3.status;
        reinvestCount = x3.reinvestCount;
        points = x3.points;
        ref = x3.ref;
    }

    // Get x3 information
    // @param addr user address
    // @param level level level
    function userX4Site(address addr, uint8 level)
        public
        view
        returns (
            uint8 status,
            uint256 reinvestCount,
            address[] memory firstPoints,
            address[] memory leftPoints,
            address[] memory rightPoints,
            address ref
        )
    {
        X4 memory x4 = users[addr].x4Site[level];
        status = x4.status;
        reinvestCount = x4.reinvestCount;
        firstPoints = x4.firstPoints;
        leftPoints = x4.leftPoints;
        rightPoints = x4.rightPoints;
        ref = x4.ref;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
}