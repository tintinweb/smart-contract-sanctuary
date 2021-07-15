pragma solidity ^0.5.0;

contract LandRegistry {
    struct Task {
        uint256 id;
        string content;
        bool completed;
    }
    struct user {
        address userid;
        string uname;
        uint256 ucontact;
        string uemail;
        uint256 upostalCode;
        string city;
        bool exist;
    }
    struct landDetails {
        address payable id;
        string ipfsHash;
        string laddress;
        uint256 lamount;
        uint256 key;
        string isGovtApproved;
        string isAvailable;
        address requester;
        reqStatus requestStatus;
    }

    address[] userarr;
    uint256[] assets;
    address owner;
    enum reqStatus {Default, Pending, Rejected, Approved}

    constructor() public {
        owner = msg.sender;
    }

    struct profiles {
        uint256[] assetList;
    }

    mapping(address => profiles) profile;

    mapping(address => user) public users;
    mapping(uint256 => landDetails) public land;

    function addUser(
        address uid,
        string memory _uname,
        uint256 _ucontact,
        string memory _uemail,
        uint256 _ucode,
        string memory _ucity
    ) public returns (bool) {
        users[uid] = user(
            uid,
            _uname,
            _ucontact,
            _uemail,
            _ucode,
            _ucity,
            true
        );
        userarr.push(uid);
        return true;
    }

    function getUser(address uid)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            string memory,
            uint256,
            string memory,
            bool
        )
    {
        if (users[uid].exist)
            return (
                users[uid].userid,
                users[uid].uname,
                users[uid].ucontact,
                users[uid].uemail,
                users[uid].upostalCode,
                users[uid].city,
                users[uid].exist
            );
    }

    function Registration(
        address payable _id,
        string memory _ipfsHash,
        string memory _laddress,
        uint256 _lamount,
        uint256 _key,
        string memory status,
        string memory _isAvailable
    ) public returns (bool) {
        land[_key] = landDetails(
            _id,
            _ipfsHash,
            _laddress,
            _lamount,
            _key,
            status,
            _isAvailable,
            0x0000000000000000000000000000000000000000,
            reqStatus.Default
        );
        profile[_id].assetList.push(_key);
        assets.push(_key);
        return true;
    }

    function computeId(string memory _laddress, string memory _lamount)
        public
        view
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(_laddress, _lamount))) %
            10000000000000;
    }

    function viewAssets() public view returns (uint256[] memory) {
        return (profile[msg.sender].assetList);
    }

    function Assets() public view returns (uint256[] memory) {
        return assets;
    }

    function landInfoOwner(uint256 id)
        public
        view
        returns (
            address payable,
            string memory,
            uint256,
            string memory,
            string memory,
            address,
            reqStatus
        )
    {
        return (
            land[id].id,
            land[id].ipfsHash,
            land[id].lamount,
            land[id].isGovtApproved,
            land[id].isAvailable,
            land[id].requester,
            land[id].requestStatus
        );
    }

    function govtStatus(
        uint256 _id,
        string memory status,
        string memory _isAvailable
    ) public returns (bool) {
        land[_id].isGovtApproved = status;
        land[_id].isAvailable = _isAvailable;
        return true;
    }

    function makeAvailable(uint256 property) public {
        require(land[property].id == msg.sender);
        land[property].isAvailable = "Available";
    }

    function requstToLandOwner(uint256 id) public {
        land[id].requester = msg.sender;
        land[id].isAvailable = "Pending";
        land[id].requestStatus = reqStatus.Pending;
    }

    function processRequest(uint256 property, reqStatus status) public {
        require(land[property].id == msg.sender);
        land[property].requestStatus = status;
        land[property].isAvailable = "Approved";
        if (status == reqStatus.Rejected) {
            land[property].requester = address(0);
            land[property].requestStatus = reqStatus.Default;
            land[property].isAvailable = "Available";
        }
    }

    function buyProperty(uint256 property) public payable {
        require(land[property].requestStatus == reqStatus.Approved);
        require(msg.value == (land[property].lamount * 1000000000000000000));
        land[property].id.transfer(
            land[property].lamount * 1000000000000000000
        );
        removeOwnership(land[property].id, property);
        land[property].id = msg.sender;
        land[property].isGovtApproved = "Not Approved";
        land[property].isAvailable = "Not yet approved by the govt.";
        land[property].requester = address(0);
        land[property].requestStatus = reqStatus.Default;
        profile[msg.sender].assetList.push(property);
    }

    function removeOwnership(address previousOwner, uint256 id) private {
        uint256 index = findId(id, previousOwner);
        profile[previousOwner].assetList[index] = profile[previousOwner]
            .assetList[profile[previousOwner].assetList.length - 1];
        delete profile[previousOwner].assetList[profile[previousOwner]
            .assetList
            .length - 1];
        profile[previousOwner].assetList.length--;
    }

    function findId(uint256 id, address user) public view returns (uint256) {
        uint256 i;
        for (i = 0; i < profile[user].assetList.length; i++) {
            if (profile[user].assetList[i] == id) return i;
        }
        return i;
    }
}