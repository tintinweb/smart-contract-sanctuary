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
    mapping (uint256 => bool) public supportedStorageProvider;
    
    address public constant V1ADDRESS = 0x9126B817CCca682BeaA9f4EaE734948EE1166Af1;
    // address public constant V2ADDRESS = 0x31385d3520bCED94f77AaE104b406994D8F2168C;
    address public constant V2ADDRESS = 0x7727Ba48CEc517175C42cbC6c65Bb538a6180A4F;
    
    mapping (uint256 => License) V1BASTARDLICENSES;
    mapping (uint256 => License) V2BASTARDLICENSES;
    
    event LicenseChanged(address _from, BastardGen _gen, uint256 _tokenId, License _license);
    event LicenseRemoved(address _from, BastardGen _gen, uint256 _tokenId);
    
    enum BastardGen{
        V1,
        V2
    }
    
    enum LicenseType{
        EXTERNAL_PROVIDER,
        ON_CHAIN_STRING
    }
    
    struct StorageProvider {
        string name;
        string baseURI;
    }
    
    struct License {
        LicenseType licenseType;
        string content;
        StorageProvider provider;
    }
    
    
    
    function setLicenseForBASTARDWStorage(BastardGen _version, uint _id, LicenseType _type, StorageProvider memory _provider,  string memory _text) external {
            require(ownerOf(_version, _id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
            
            License storage V1 = V1BASTARDLICENSES[_id];
            License storage V2 = V2BASTARDLICENSES[_id];
            
            if(_type == LicenseType.EXTERNAL_PROVIDER){
                
                if(_version == BastardGen.V1){
                    V1.licenseType = _type;
                    V1.content = _text;
                    V1.provider.name = _provider.name;
                    V1.provider.baseURI = _provider.baseURI;
                }
            
                if(_version == BastardGen.V2){
                    V2.licenseType = _type;
                    V2.content = _text;
                    V2.provider.name = _provider.name;
                    V2.provider.baseURI = _provider.baseURI;
                }
                
                // require(bytes(_text).length == _provider.hashLength, "SHAKE THAT HASH FOR ME. SERIOUSLY, THIS HASH IS NOT MATCHING THE PROVIDER LENGTH!");
                
            } else if (_type == LicenseType.ON_CHAIN_STRING) {
                
                if(_version == BastardGen.V1){
                    V1.licenseType = _type;
                    V1.content = _text;
                    V1.provider.name = "CHAIN";
                    V1.provider.baseURI = "";
                }
            
                if(_version == BastardGen.V2){
                    V2.licenseType = _type;
                    V2.content = _text;
                    V2.provider.name = "CHAIN";
                    V2.provider.baseURI = "";
                }
                
            } else {
                revert("DAFUQ IS THIS");
            }
        
             if(_version == BastardGen.V1){
                emit LicenseChanged(msg.sender, _version, _id , V1);
            }
        
            if(_version == BastardGen.V2){
                emit LicenseChanged(msg.sender, _version, _id , V2);
            }
        
    }
    
    function setLicenseForBASTARD(BastardGen _version, uint _id, LicenseType _type, StorageProvider memory _provider,  string memory _text) external {
        if(_version == BastardGen.V1){
            require(BASTARDCONTRACT(V1ADDRESS).ownerOf(_id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
        } else if(_version == BastardGen.V2){
            require(BASTARDCONTRACT(V2ADDRESS).ownerOf(_id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
        } else {
            revert('IS THIS A FAKE BASTARD?');
        }
        
        if(_type == LicenseType.EXTERNAL_PROVIDER){
            
            // hash = _text
            
            if(_version == BastardGen.V1){
                V1BASTARDLICENSES[_id].licenseType = _type;
                V1BASTARDLICENSES[_id].content = _text;
                V1BASTARDLICENSES[_id].provider.name = _provider.name;
                V1BASTARDLICENSES[_id].provider.baseURI = _provider.baseURI;
            }
        
            if(_version == BastardGen.V2){
                V2BASTARDLICENSES[_id].licenseType = _type;
                V2BASTARDLICENSES[_id].content = _text;
                V2BASTARDLICENSES[_id].provider.name = _provider.name;
                V2BASTARDLICENSES[_id].provider.baseURI = _provider.baseURI;
            }
            
            
        } else if (_type == LicenseType.ON_CHAIN_STRING) {
            
            if(_version == BastardGen.V1){
                V1BASTARDLICENSES[_id].licenseType = _type;
                V1BASTARDLICENSES[_id].content = _text;
                V1BASTARDLICENSES[_id].provider.name = "CHAIN";
                V1BASTARDLICENSES[_id].provider.baseURI = "";
            }
        
            if(_version == BastardGen.V2){
                V2BASTARDLICENSES[_id].licenseType = _type;
                V2BASTARDLICENSES[_id].content = _text;
                V2BASTARDLICENSES[_id].provider.name = "CHAIN";
                V2BASTARDLICENSES[_id].provider.baseURI = "";
            }
       
        } else {
            revert("DAFUQ IS THIS");
        }
        
        if(_version == BastardGen.V1){
            emit LicenseChanged(msg.sender, _version, _id , V1BASTARDLICENSES[_id]);
        }
        
        if(_version == BastardGen.V2){
            emit LicenseChanged(msg.sender, _version, _id, V2BASTARDLICENSES[_id]);
        }
    }
    
    function removeLicenseForBastard(BastardGen _version, uint _id) external {
        require(ownerOf(_version, _id) == msg.sender, "HEY, YOU CAN NOT CHANGE LICENSE FOR A BASTARD YOU DON'T HOLD!");
        
        if(_version == BastardGen.V1){
            delete V1BASTARDLICENSES[_id];
        } else if(_version == BastardGen.V2){
            delete V2BASTARDLICENSES[_id];
        } else {
            revert("NOPE");
        }
        
        emit LicenseRemoved(msg.sender, _version, _id);
    }
    
    function showLicenseForBASTARD(BastardGen _version,uint _id) external view returns(License memory) {
        
        if(_version == BastardGen.V1){
            return V1BASTARDLICENSES[_id];
        }
        
        if(_version == BastardGen.V2){
            return V2BASTARDLICENSES[_id];
        }
        revert("INVALID PARAMS BRO");
    }
    
    function showLicenseContent(BastardGen _version,uint _id) external view returns(string memory) {
        if(_version == BastardGen.V1){
            License memory license =  V1BASTARDLICENSES[_id];
            if(license.licenseType == LicenseType.EXTERNAL_PROVIDER) {
                return string(abi.encodePacked(license.provider.baseURI, license.content));
            }
            if(license.licenseType == LicenseType.ON_CHAIN_STRING) {
                return string(abi.encodePacked(license.content));
            }
        }
        
        if(_version == BastardGen.V2){
            License memory license =  V2BASTARDLICENSES[_id];
            if(license.licenseType == LicenseType.EXTERNAL_PROVIDER) {
                return string(abi.encodePacked(license.provider.baseURI, license.content));
            }
            if(license.licenseType == LicenseType.ON_CHAIN_STRING) {
                return string(abi.encodePacked(license.content));
            }
        }
        revert("THIS PARAMS ARE BULLSHIT");
    }
    
    function ownerOf(BastardGen _version, uint _id) public view returns(address) {
        if(_version == BastardGen.V1){
            return BASTARDCONTRACT(V1ADDRESS).ownerOf(_id);
        }
        
        if(_version == BastardGen.V2){
            return BASTARDCONTRACT(V2ADDRESS).ownerOf(_id);
        }
        return address(0);
    }
}


/* hey. i'm caner aka memorycollect0r. 
i made this ultra mega hyper intergalactic epic masterpiece license contract. 
thx for using. see ya. 
contact: [email protected] - twitter.com/memorycollect0r */