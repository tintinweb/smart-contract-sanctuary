/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

/**
 *Submitted for verification at FtmScan.com on 2021-08-22
*/

/**
 * SyfinVerified
 * 
 * This is a smart contract used for Verified Profiles on the SYF NFT Market
 * 
 * https://t.me/fantomsyfin - https://sy.finance - https://app.sy.finance - https://nft.sy.finance
 * 
 * https://twitter.com/syfinance
*/

pragma solidity ^0.8.0;

contract SyfinVerified {
    mapping (address => bool) private verifies;
    
    address[] public updates;

    event SetVerified(address indexed hashAddress, bool verified);
    
    address public owner;

    constructor ()  {
       owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setVerified(address addy, bool verified) public onlyOwner {
        
        updates.push(addy);
        
        verifies[addy] = verified;

        emit SetVerified(addy, verified);
    }

    function getVerified(address hashAddress) public view returns (bool) {
        return verifies[hashAddress];
    }
    
    function UpdateCount() public view returns (uint) {
        return updates.length;
    }
}