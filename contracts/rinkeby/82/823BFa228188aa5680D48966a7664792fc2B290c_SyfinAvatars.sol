/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

/**
 *Submitted for verification at FtmScan.com on 2021-08-20
*/

/**
 * SyfinAvatars
 * 
 * This is a smart contract used for simple storage of IPFS hashes on chain to associate with Fantom Addresses for use in SYF NFT Market
 * 
 * This contract can be used for any FTM address!
 * 
 * https://t.me/fantomsyfin - https://sy.finance - https://app.sy.finance - https://nft.sy.finance
 * 
 * https://twitter.com/syfinance
*/

pragma solidity ^0.8.0;

contract SyfinAvatars {
    mapping (address => string) private ipfsHashes;
    mapping (address => string) private mimeTypes;
    mapping (address => string) private names;
    mapping (address => string) private bios;
    
    address[] public updates;

    event SetAvatar(address indexed hashAddress, string hash, string mimetype);

    function setAvatar(string memory hash, string memory mimetype, string memory name, string memory bio) public {
        require(bytes(hash).length == 46);
        require(bytes(mimetype).length > 0);
        
        updates.push(msg.sender);
        
        ipfsHashes[msg.sender] = hash;
        mimeTypes[msg.sender] = mimetype;
        names[msg.sender] = name;
        bios[msg.sender] = bio;
        

        emit SetAvatar(msg.sender, hash, mimetype);
    }

    function getIPFSHash(address hashAddress) public view returns (string memory) {
        return ipfsHashes[hashAddress];
    }
    
    function getMIMEType(address hashAddress) public view returns (string memory) {
        return mimeTypes[hashAddress];
    }
    
    function getName(address hashAddress) public view returns (string memory) {
        return names[hashAddress];
    }
    
    function getBio(address hashAddress) public view returns (string memory) {
        return bios[hashAddress];
    }
    
    function UpdateCount() public view returns (uint) {
        return updates.length;
    }
}