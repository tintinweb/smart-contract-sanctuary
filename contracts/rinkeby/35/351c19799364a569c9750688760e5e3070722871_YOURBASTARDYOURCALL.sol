/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.8.4;

interface BASTARDCONTRACT {
  function ownerOf(uint id) external view returns (address); 
}

/* 
YOUR BASTARD, YOUR CALL!!!

AS YOU KNOW, IF YOU ARE HOLDER OF A BASTARD (AKA BGAN, OR BGANPUNK), YOU CAN DO ANYTHING YOU WANT WITH IT.
THIS OFFICIAL SMART CONTRACT EXTENDS IT ONE STEP FURTHER, NOW YOU CAN WRITE YOUR OWN LICENSE FOR YOUR BASTARD!!!
YOU CAN WRITE WHO CAN DO WHAT WITH IT, GRANT ACCESS TO PEOPLE, OR MAKE IT PUBLIC DOMAIN.
FOR EXAMPLE YOU CAN SAY:
THIS THIS THIS PEOPLE OR EVERYONE CAN USE THIS BASTARD AS PFP
THIS THIS THIS PEOPLE CAN OPEN A MERCH SHOP FOR THIS BASTARD
ETC. ETC. THERE ARE MANY POSSIBILITIES
IF YOU DON'T CARE ABOUT LICENSE AT ALL, YOU CAN WRITE SOMETHING LIKE "THIS BASTARD HAS A CRUSH ON BASTARD #9030" LOL
IF YOU TRANSFER/SELL YOUR BASTARD TO SOMEONE ELSE, NEW OWNER HAS ALL RIGHTS TO EDIT/REWRITE THE TEXT HOW THEY WISH
LET’S SEE HOW THIS MODEL WILL WORK!
GO BASTARDS! WITH LUV FROM BERK



https://bastardganpunks.club 
*/


contract YOURBASTARDYOURCALL {

    address public constant V1ADDRESS = 0x9126B817CCca682BeaA9f4EaE734948EE1166Af1;
    // address public constant V2ADDRESS = 0x31385d3520bCED94f77AaE104b406994D8F2168C;
    address public constant V2ADDRESS = 0x7727Ba48CEc517175C42cbC6c65Bb538a6180A4F;
    
    mapping (uint256 => string) V1BASTARDLICENSES;
    mapping (uint256 => string) V2BASTARDLICENSES;
    
    event LicenseChanged(address _from, uint8 _gen, uint256 _tokenId);
    event LicenseRemoved(address _from, uint8 _gen, uint256 _tokenId);
  
    
    function setLicenseForBASTARDStorage(uint8 _version, uint _id, string memory _text) external {
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
    
    
    function removeLicenseForBastard(uint8 _version, uint _id) external {
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


/* hey. i'm caner aka memorycollect0r. 
i actually made a ultra mega hyper intergalactic epic masterpiece license contract, but berk trimmed all cool extra features saying they cost so much gas. F U BERK. 
thx for using. see ya. 
contact: [email protected] - twitter.com/memorycollect0r */