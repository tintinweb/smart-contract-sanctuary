pragma solidity >=0.4.22 <0.8.0;

import "./ISmartRightsCertify.sol";

contract SmartRightsCertify is ISmartRightsCertify {

    address owner;
    mapping(bytes32 => address) userCertifications;
    mapping(address => bool) whitelist;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true, "NotInWhitelist");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner");
        _;
    }

    function certifyHash(address _owner, bytes32 _hash) external onlyOwner {
        require(userCertifications[_hash] == address(0), "DuplicateData");
        userCertifications[_hash] = _owner;
    }

    function certifyHash(bytes32 _hash) external onlyWhitelist {
        require(userCertifications[_hash] == address(0), "DuplicateData");
        userCertifications[_hash] = msg.sender;
    }

    function getHashOwner(bytes32 _hash) external view returns(address) {
        return userCertifications[_hash];
    }

    function addToWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }
}