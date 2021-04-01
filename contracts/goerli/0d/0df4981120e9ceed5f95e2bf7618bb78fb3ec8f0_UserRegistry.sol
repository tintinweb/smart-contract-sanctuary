/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.8.0;

contract UserRegistry {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // Threshold for verification status
    uint256 public verificationthresh;

    struct User {
        bool exists;
        address userAddress;
        string publicKey;
        string userName;
        string userAvatar;
        mapping(address => bool) verifications;
        uint256 numVerifications;
    }

 event UserAdded(
        address userAddress,
        string userName,
        string userAvatar,
        string publicKey
    );

    event VerificationAdded(
        address _from,
        address _to,
        uint256 _numverifications
    );

    uint numUsers;
    mapping (address => User) users;   
    
     function createUser (
     address userAddress, 
     string memory publicKey,
     string memory userName,
     string memory userAvatar
     ) public returns (bool) {
        require(
            users[msg.sender].numVerifications >= verificationthresh,
            "Only verified users can add new users"
        );
        User storage r = users[userAddress];
        r.userAddress = userAddress;
        r.publicKey = publicKey;
        r.userName = userName;
        r.userAvatar = userAvatar;
        r.exists = true;
        r.numVerifications = 0;
        
        emit UserAdded(
            users[msg.sender].userAddress,
            users[msg.sender].userName,
            users[msg.sender].userAvatar,
            users[msg.sender].publicKey
        );
        
    }

   
    event UserAdded(address userAddress);

    event Error(string _err);

    constructor() public {
        owner = msg.sender;
        verificationthresh = 2;
        User storage r = users[owner];
        r.userAddress = owner;
        r.publicKey = "";
        r.userName = "Root";
        r.userAvatar = "data";
        r.exists = true;
        r.numVerifications = 10;
    }

    function addVerification(address userAddress)
        public
        returns (string memory _feedback)
    {
        // Add a verfier to this user's hash

        // If the verifier isnt verified himself, throw.
        require(
            users[msg.sender].numVerifications >= verificationthresh,
            "verifier has not enough verifications."
        );

        uint256 numval = users[userAddress].numVerifications;
        users[userAddress].verifications[msg.sender] = true;
        users[userAddress].numVerifications = numval + 1;

        emit VerificationAdded(
            msg.sender,
            userAddress,
            users[userAddress].numVerifications
        );
    }

    function giveGodVerification(address payable userAddress)
        public
        onlyOwner
        returns (bool)
    {
        users[userAddress].numVerifications = 10;
        return true;
    }

    function readUser(address userAddress)
        public
        view
        returns (
            string memory userName,
            string memory userAvatar,
            string memory publicKey,
            uint256 numVerifications
        )
    {
        return (
            users[userAddress].userName,
            users[userAddress].userAvatar,
            users[userAddress].publicKey,
            users[userAddress].numVerifications
        );
    }

    function checkVeracity(address payable userAddress)
        public
        view
        returns (uint256 numVerifications)
    {
        return users[userAddress].numVerifications;
    }
}