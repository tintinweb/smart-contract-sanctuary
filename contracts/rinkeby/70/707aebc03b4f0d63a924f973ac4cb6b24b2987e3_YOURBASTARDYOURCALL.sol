/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.8.4;

/* 
YOUR BASTARD, YOUR CALL!!!

AS YOU KNOW, IF YOU ARE HOLDER OF A BASTARD (AKA BGAN, OR BGANPUNK), YOU CAN DO ANYTHING YOU WANT WITH IT.
THIS OFFICIAL SMART CONTRACT EXTENDS IT ONE STEP FURTHER, NOW YOU CAN WRITE YOUR OWN LICENSE FOR YOUR BASTARD!!!

YOU CAN EITHER STORE WHOLE TEXT ON-CHAIN OR POINT TO AN URL (WEBSITE, SERVER, IPFS, ARWEAVE ETC)

I WILL GIVE YOU EXAMPLES ON HOW YOU CAN USE THIS DATA FOR YOUR BASTARD:

YOU CAN WRITE WHICH PERSON/DAO/WHATEVER YOU GIVE PERMISSION TO USE IT FOR SPECIFIC USE CASES
CLAIM THAT THIS BASTARD IS PUBLIC DOMAIN
OR CAN SAY HI TO YOUR FRIENDS & BELOVED ONES
OR USE HERE AS A CANVAS FOR YOUR TEXTS
OR A MEDIUM FOR YOUR CONCEPTUAL PIECE
OR A TEXT SCORE FOR A PERFORMANCE
OR FILL IT WITH YOUR JUNK
OR ASCII COPYPASTA
OR POEM
OR YOUR FAVOURITE BASTARDOUS FOOD RECEIPT
OR BASTARD LORE / ORIGIN STORY YOU MADE UP
OR MORSE CODE
OR AN ULTRA MEGA META SHIT
OR A RIDDLE
OR YOUR NUDES
OR A LOVE LETTER
OR A MATH EQUATION THAT WILL CHANGE EVERYTHING FOREVER
OR YOUR ENCRYPTED MESSAGE THAT NO ONE WILL TRY TO CRACK
ROAST YOUR BASTARD OR FLATTER
CLAIM YOUR BASTARD AS YOUR COUNTRY FLAG
PERFORM A RITUAL
IF YOU WANNA LOCK THE TEXT FOREVER, YOU GOTTA FAREWELL WITH YOUR BASTARD AND TRANSFER THEM TO A WALLET THAT NOBODY OWNS.
IN SHORT
DO WHATEVER YOU SEE FIT
IT IS ACTUALLY A PLAYGROUND. YOU ARE PART OF A SOCIAL EXPERIMENT.

LESGOOOOOOOOOOOOOOOOOOOO 1 2 3 4

BE COOL WITH PEOPLE REMIXING YOUR BASTARD, SUPPORT CREATIVITY

NEW OWNER SHOULD NOT ASK FOR RETROSPECTIVE CLAIM OR BAN. NEW RULES DEAL WITH THINGS FROM THE MOMENT LICENCE IS UPDATED.

DO NOT BE A DOUCH PLS. BE A NICE BASTARD

EXPLORE YOUR ARTISTRY!

V I B E

LISTEN TO PLUNDERPHONICS BY JOHN OSWALD

https://bastardganpunks.club 
https://discord.gg/bganpunks

https://berkozdemir.com
https://twitter.com/berkozdemir


hey. i'm caner aka memorycollect0r. 
i actually made an ultra mega hyper intergalactic epic masterpiece license contract, but berk trimmed all cool extra features saying the functions cost so much gas. F U BERK. 
thx for using. see ya. 
contact: [email protected] - twitter.com/memorycollect0r

*/

interface BASTARDCONTRACT {
  function ownerOf(uint id) external view returns (address); 
}

contract YOURBASTARDYOURCALL {

    address public constant V1ADDRESS = 0x9126B817CCca682BeaA9f4EaE734948EE1166Af1;
    // address public constant V2ADDRESS = 0x31385d3520bCED94f77AaE104b406994D8F2168C;
    address public constant V2ADDRESS = 0xD673B725dfaD7e1cb5956595b5d74034E5bf8B32;
    
    mapping (uint256 => string) V1BASTARDLICENSES;
    mapping (uint256 => string) V2BASTARDLICENSES;
    
    event LicenseChanged(address _from, uint8 _gen, uint256 _tokenId);
    event LicenseRemoved(address _from, uint8 _gen, uint256 _tokenId);
  
    
    
    /* EXAMPLE
    
    (2, 4444, "THIS BASTARD IS AMAZING") - BGANPUNKV1, ID 4444
    
    (1,10001, "https://gateway.pinata.cloud/ipfs/QmccPaKWuFcQGyXy778S2NfeUuVWyaVorrBnewXKwG2Kg4") - BGANPUNKV2, ID 10001, IPFS link
    
    */
    
    
    function setLicenseForBASTARD(uint8 _version, uint _id, string memory _text) external {
            require(ownerOf(_version, _id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
            
            if(_version == 1){
               
                V1BASTARDLICENSES[_id] = _text;
                emit LicenseChanged(msg.sender, _version, _id );

               
            }
        
            else if(_version == 2){
                
                V2BASTARDLICENSES[_id] = _text;
                emit LicenseChanged(msg.sender, _version, _id );                
            }
            
                
            else {
                revert("DAFUQ IS THIS");
            }
        
        
    }
    
    
    function removeLicenseForBastardStorage(uint8 _version, uint _id) external {
        require(ownerOf(_version, _id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
        
        if(_version == 1){
            delete V1BASTARDLICENSES[_id];
        } else if(_version == 2){
            delete V2BASTARDLICENSES[_id];
        } else {
            revert("NOPE");
        }
        
        emit LicenseRemoved(msg.sender, _version, _id);
    }
    
    
    function removeLicenseForBastardNoStorage(uint8 _version, uint _id) external {
        require(ownerOf(_version, _id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
        
        if(_version == 1){
            V1BASTARDLICENSES[_id] = "";
        } else if(_version == 2){
            V2BASTARDLICENSES[_id] = "";
        } else {
            revert("NOPE");
        }
        
        emit LicenseRemoved(msg.sender, _version, _id);
    }
    
    
    function showLicenseForBASTARD(uint8 _version,uint _id) external view returns(string memory) {
        
        if(_version == 1){
            return V1BASTARDLICENSES[_id];
        }
        
        if(_version == 2){
            return V2BASTARDLICENSES[_id];
        }
        revert("INVALID PARAMS BRO");
    }
    
    function ownerOf(uint8 _version, uint _id) public view returns(address) {
        if(_version == 1){
            return BASTARDCONTRACT(V1ADDRESS).ownerOf(_id);
        }
        
        if(_version == 2){
            return BASTARDCONTRACT(V2ADDRESS).ownerOf(_id);
        }
        return address(0);
    }
}