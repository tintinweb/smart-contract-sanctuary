/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

pragma solidity ^0.8.4;

interface BASTARDCONTRACT {
  function ownerOf(uint id) external view returns (address); 
}

// YOUR BASTARD, YOUR CALL!!!

// AS YOU KNOW, IF YOU ARE HOLDER OF A BASTARD (AKA BGAN, OR BGANPUNK), YOU CAN DO ANYTHING YOU WANT WITH IT.
// THIS OFFICIAL SMART CONTRACT EXTENDS IT ONE STEP FURTHER, NOW YOU CAN WRITE YOUR OWN LICENSE FOR YOUR BASTARD!!!
// YOU CAN WRITE WHO CAN DO WHAT WITH IT, GRANT ACCESS TO PEOPLE, OR MAKE IT PUBLIC DOMAIN.
// FOR EXAMPLE YOU CAN SAY:
// THIS THIS THIS PEOPLE OR EVERYONE CAN USE THIS BASTARD AS PFP
// THIS THIS THIS PEOPLE CAN USE THIS BASTARD FOR THEIR COMMERCIAL WORK
// THIS THIS THIS PEOPLE CAN OPEN A MERCH SHOP WITH THIS BASTARD
// ETC. ETC. THERE ARE MANY POSSIBILITIES
// IF YOU DON'T CARE ABOUT LICENSE AT ALL, YOU CAN WRITE SOMETHING LIKE "THIS BASTARD HAS A CRUSH ON BASTARD #9030" LOL
// OR YOU CAN EXPRESS YOUR LOVE TO YOUR BASTARD
// OR WRITE A BACKSTORY
// THINK OF IT AS A TEXT CANVAS
// IF YOU TRANSFER/SELL YOUR BASTARD TO SOMEONE ELSE, NEW OWNER HAS ALL RIGHTS TO EDIT/REWRITE THE TEXT HOW THEY WISH
// LET’S SEE HOW THIS MODEL WILL WORK!
// GO BASTARDS! BY BERK, WITH <3

// https://bastardganpunks.club


contract YOURBASTARDYOURCALL {
    address public constant V1ADDRESS = 0x9126B817CCca682BeaA9f4EaE734948EE1166Af1;
    address public constant V2ADDRESS = 0xD74B44be7385978f570b375BC01470F5d40e0497;
    // 0x31385d3520bCED94f77AaE104b406994D8F2168C;
    mapping (uint256 => string) V1BASTARDLICENSES;
    mapping (uint256 => string) V2BASTARDLICENSES;
    
    
    event V1LicenseChanged ( uint256 _tokenId, string _text, address _from );
    event V2LicenseChanged ( address indexed _from, uint256 indexed _tokenId, string _text );
    
    function setLicenseForV1BASTARD(uint _id, string memory _text) public {
        
        require( BASTARDCONTRACT(V1ADDRESS).ownerOf(_id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!" );
        
        V1BASTARDLICENSES[_id] = _text;
        
        emit V1LicenseChanged(_id, _text, msg.sender);
        
    }
    
    function showLicenseForV1BASTARD(uint _id) public view returns(string memory) {
        return V1BASTARDLICENSES[_id];
    }
    
    function ownerOf_V1(uint _id) public view returns(address) {
        return BASTARDCONTRACT(V1ADDRESS).ownerOf(_id);
    }
    
    function setLicenseForV2BASTARD(uint _id, string memory _text) public {
        
        require( BASTARDCONTRACT(V2ADDRESS).ownerOf(_id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!" );
        
        V2BASTARDLICENSES[_id] = _text;
        
        emit V2LicenseChanged(msg.sender, _id, _text);
        
    }
    
    function showLicenseForV2BASTARD(uint _id) public view returns(string memory) {
        return V2BASTARDLICENSES[_id];
    }
    
    
    function ownerOf_V2(uint _id) public view returns(address) {
        return BASTARDCONTRACT(V2ADDRESS).ownerOf(_id);
    }
    
    
}