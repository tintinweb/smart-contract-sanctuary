/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity >=0.7.0 < 0.9.0;


contract ManagementSys   {

    struct dataRequester{
        address dataRequester;
        bool isExist;
    }

    struct dataHash{
        string hash;
        mapping(address => dataRequester) dataRequesters;
        bool isExist;
    }

    struct mpa{
        address mpa;
        bool isExist;
    }

    address public dataOwner;
    mpa[] public admins;
    mapping(address => dataRequester) public dataRequesters;
    mapping(string => dataHash) public dataHashes;
    
    event FileAdded(string hash, address uploader);

    event RequesterAdded(string hash, address requester, address uploader);

    error fileAlreadyExists(string hash, address uploader);

    error dataRequesterAlreadyExists(address requester, address uploader);

    error adminAlreadyExists(address admin);

    constructor()   {
        dataOwner = msg.sender;
        mpa memory mainAdmin = mpa(msg.sender, true);
        admins.push(mainAdmin);
    }

    function checkAdmin(address sender) public view returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i].mpa == sender)
                return true;
        }    
        return false;
    }

    function addMPA(address admin) public {
        require(msg.sender == dataOwner);
        require(admins.length <= 3, "Admins should be less than 3");

        for (uint i = 0; i < admins.length; i++) {
            if (admins[i].mpa == admin)
                revert adminAlreadyExists({
                    admin: admin
                });
        }

        mpa memory adminToAdd = mpa(admin, true);
        admins.push(adminToAdd);
    }

    function addFileHash(string memory hash) public {
        require(checkAdmin(msg.sender));

        if (dataHashes[hash].isExist)
            revert fileAlreadyExists({
                hash: hash,
                uploader: dataOwner
            });

        dataHashes[hash].hash = hash;
        dataHashes[hash].isExist = true;

        emit FileAdded(hash, dataOwner);
    }

    function addDataRequesters(address requester) public {
        require(checkAdmin(msg.sender));

        if (dataRequesters[requester].isExist)
            revert dataRequesterAlreadyExists({
                requester: requester,
                uploader: dataOwner
            });

        dataRequesters[requester].dataRequester = requester;
        dataRequesters[requester].isExist = true;
    }

    function requestData(string memory hash) public view returns (bool) {

        if (dataRequesters[msg.sender].isExist 
            && dataHashes[hash].isExist 
            && dataHashes[hash].dataRequesters[msg.sender].isExist) {
            return true;
        }
        return false;
    }

    function setDataRequesterToHash(string memory hash, address requester) public {
        require(checkAdmin(msg.sender));
        require(dataRequesters[requester].isExist, "Requester isn't allowed to request!");
        require(dataHashes[hash].isExist, "Hash doesn't exists!");
        require(!dataHashes[hash].dataRequesters[requester].isExist, "Requester already has permissions!");

        dataHashes[hash].dataRequesters[requester].dataRequester = requester;
        dataHashes[hash].dataRequesters[requester].isExist = true;

        emit RequesterAdded(hash, requester, dataOwner);
    }
}