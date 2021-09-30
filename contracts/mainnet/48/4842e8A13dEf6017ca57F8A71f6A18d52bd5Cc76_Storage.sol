/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity 0.6.11;

contract Storage {

    address owner = msg.sender;
    address latestVersion;
    
    address ZEROADDRESS = 0x0000000000000000000000000000000000000000;
    address DEADADDRESS = 0x000000000000000000000000000000000000dEaD;
    address BURNADDRESS = 0x5D152dd902CC9198B97E5b6Cf5fc23a8e4330180;
    
    mapping(address => mapping(uint => address)) LegacyClaims;
    mapping(address => mapping(uint => address)) Claims;
    address[] BurnAddresses;
    
    constructor() public {
        BurnAddresses.push(DEADADDRESS);
        BurnAddresses.push(BURNADDRESS);
    }
    
    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion, 'Not latest version');
        _;
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner);
        latestVersion = _newVersion;
    }
    
    function getZero() external view returns(address) {
        return ZEROADDRESS;
    }
    
    function getDead() external view returns(address) {
        return DEADADDRESS;
    }
    
    function getBurnAddresses() external view returns (address[] memory){
        return BurnAddresses;
    }
    
    function getLegacyClaims(address nftAddress, uint tokenId) external view returns(address) {
        return LegacyClaims[nftAddress][tokenId];
    }
    
    function getClaims(address nftAddress, uint tokenId) external view returns (address) {
        return Claims[nftAddress][tokenId];
    }
    
    /* ADD Protedted by only current version */
    
    function addToBurnAddresses(address burnAddress) external onlyLatestVersion() {
         BurnAddresses.push(burnAddress);
    }
    
    function addToLegacy(address nftAddress, uint tokenId, address _owner) external onlyLatestVersion() {
        LegacyClaims[nftAddress][tokenId] = _owner;
    }
    
    function removeFromLegacy(address nftAddress, uint tokenId) external onlyLatestVersion() {
        LegacyClaims[nftAddress][tokenId] = ZEROADDRESS;
    }
    
    function addToClaims(address nftAddress, uint tokenId, address _owner) external onlyLatestVersion() {
        Claims[nftAddress][tokenId] = _owner;
    }
}