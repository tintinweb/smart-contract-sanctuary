//SourceUnit: EasyThreeLine.sol

pragma solidity 0.5.10;




contract EasyThreeLine {

    struct User {
        uint id;
        address adrUser;
        address referrer;
        uint partnersCount;
        uint partnersAllCount;

    }

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;



    uint public constant LINE_PRICE = 400 trx;
    address payable public owner;




    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event SentTrxDividends(address indexed from, address indexed receiver);


    constructor() public {


        owner = msg.sender;

        User memory user = User({
            id: 1,
            adrUser: owner,
            referrer: owner,
            partnersCount: uint(0),
            partnersAllCount: uint(0)
        });

        users[owner] = user;
        idToAddress[1] = owner;

    }

    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }


    function withdrawLostTrxFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        owner.transfer(address(this).balance);
    }


    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }




    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");

        if (!isUserExists(referrerAddress)) {
            referrerAddress = owner;
        }

        if (!isUserExists(referrerAddress)) {
            referrerAddress = owner;
        }

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        require(msg.value == LINE_PRICE, "invalid registration cost");


        User memory user = User({
            id: lastUserId,
            adrUser: userAddress,
            referrer: referrerAddress,
            partnersCount: 0,
            partnersAllCount: uint(0)
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        lastUserId++;

        users[referrerAddress].partnersCount++;
        users[referrerAddress].partnersAllCount++;


        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);

        return withdrawForPartners(referrerAddress, userAddress);
    }


    function withdrawForPartners(address referrerAddress, address userAddress) private {

        sendTrxDividends(referrerAddress, userAddress);

        address refAdr2 = users[referrerAddress].referrer;
        users[refAdr2].partnersAllCount++;
        sendTrxDividends(refAdr2, userAddress);

        address refAdr3 = users[refAdr2].referrer;
        users[refAdr3].partnersAllCount++;
        sendTrxDividends(refAdr3, userAddress);


    }



    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }



    function sendTrxDividends(address _userAddress, address _from) private {


        uint valueSumm = 100 trx;

        address(uint160(_userAddress)).transfer(valueSumm);
        emit SentTrxDividends(_from, _userAddress);

    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}