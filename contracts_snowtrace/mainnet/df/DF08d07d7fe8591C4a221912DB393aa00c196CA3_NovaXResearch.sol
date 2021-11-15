/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract NovaXResearch {
    address private owner;

    constructor() {
        owner = msg.sender;
       
    }

    
    function makeResearch(uint researchId, uint planetNo) payable public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        uint256 rLevel  = planet.getParam1(planetNo, "r-level"); 
        require(rLevel >= 1, "Need to build research center on your planet.");

        require(isResearchDone(researchId, planetNo) == false);

        Loot loot = Loot(0x9ab7f0203cb23f7a6a33eD7AFA518B4a34e5E7C7);
        uint256[] memory tokenList = loot.tokensOfOwner(msg.sender);
        bool researchFound = false;
        uint tokenIdFound = 0;
        for(uint i = 0; i < tokenList.length; i++){
            uint tokenId = tokenList[i];
            if (loot.typeOfItem(tokenId) == researchId){
                tokenIdFound = tokenId;
                researchFound = true;
            }
            
        }
        require(researchFound, "Don't have necessary loot for this research.");
        
        //check min levels
        uint256 sLevel  = planet.getParam1(planetNo, "s-level"); 
        uint256 mLevel  = planet.getParam1(planetNo, "m-level"); 
        uint256 cLevel  = planet.getParam1(planetNo, "c-level"); 
        
        //0: Heavy fighter
        //1: battleship
        //2: cruiser
        //3: destroyer
        //4: space dog
        //5: heavy space soldier
        //6: plasma powered soldier
        //7: bomber
        //8: alien leader
        //9: samurai
        //10: doom warrior
        if(researchId == 0) {
            require((sLevel >= 4) && (mLevel >= 4) && (cLevel >= 4), "you don't have the min level required buildings");
        }
        else if(researchId == 1) {
            require((sLevel >= 5) && (mLevel >= 5) && (cLevel >= 5), "you don't have the min level required buildings");
        }
        else if(researchId == 2) {
            require((sLevel >= 8) && (mLevel >= 8) && (cLevel >= 8), "you don't have the min level required buildings");
        }
        else if(researchId == 3) {
            require((sLevel >= 10) && (mLevel >= 10) && (cLevel >= 10), "you don't have the min level required buildings");
        }
        else if(researchId == 4) {
            require((sLevel >= 5) && (mLevel >= 5) && (cLevel >= 5), "you don't have the min level required buildings");
        }
        else if(researchId == 5) {
            require((sLevel >= 6) && (mLevel >= 6) && (cLevel >= 6), "you don't have the min level required buildings");
        }
        else if(researchId == 6) {
            require((sLevel >= 7) && (mLevel >= 7) && (cLevel >= 7), "you don't have the min level required buildings");
        }
        else if(researchId == 7) {
            require((sLevel >= 8) && (mLevel >= 8) && (cLevel >= 8), "you don't have the min level required buildings");
        }
        else if(researchId == 8) {
            require((sLevel >= 12) && (mLevel >= 12) && (cLevel >= 12), "you don't have the min level required buildings");
        }
        else if(researchId == 9) {
            require((sLevel >= 12) && (mLevel >= 12) && (cLevel >= 12), "you don't have the min level required buildings");
        }
        else if(researchId == 10) {
            require((sLevel >= 15) && (mLevel >= 15) && (cLevel >= 15), "you don't have the min level required buildings");
        }

        loot.burnItem(tokenIdFound);
        makeResearchDone(researchId, planetNo) ;
    }
    
    function isResearchDone(uint researchId, uint planetNo) view public  returns (bool) {
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        string memory researchKey = string(abi.encodePacked("r-",  uintToString(researchId)));
        uint256 r  = planet.getParam1(planetNo, researchKey); 
        return (r == 1);
    }
    
    function makeResearchDone(uint researchId, uint planetNo)  private{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        string memory researchKey = string(abi.encodePacked("r-",  uintToString(researchId)));
        uint256 r  = planet.getParam1(planetNo, researchKey); 
        require (r != 1);
        
        
        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address metadataSetterAddress = novax.getParam3("metadataSetter");
        MetadataSetter setter = MetadataSetter(metadataSetterAddress);
        setter.setParam1(planetNo, researchKey, 1);

    }
    
    function listOfResearchesDone(uint planetNo) view public  returns(uint[] memory ) {
        uint count = 0;
        for(uint i = 0; i <= 10; i++){
            if(isResearchDone(i, planetNo)){
                count += 1;
            }
        }
        uint[] memory researchIdList = new uint[](count);
        uint index2 = 0;
        for(uint i = 0; i <= 10; i++){
            if(isResearchDone(i, planetNo)){
               researchIdList[index2] = i;
               index2 ++;
            }
        }
        
        return researchIdList;
    }
   
    
    
    //setters
    function setOwner(address user) onlyOwner public{
        owner = user;
    }
    
    function getOwner() public view returns (address)  {
        return owner;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
   
    function withdraw(uint amount) onlyOwner public returns(bool) {
        require(amount <= address(this).balance);
        payable(owner).transfer(amount);
        return true;

    }
    
    
    function uintToString(uint v) private view returns (string memory str) {
        if(v == 0){ return "0";  }
        if(v == 1){ return "1";  }
        if(v == 2){ return "2";  }
        if(v == 3){ return "3";  }
        if(v == 4){ return "4";  }
        if(v == 5){ return "5";  }
        if(v == 6){ return "6";  }
        if(v == 7){ return "7";  }
        if(v == 8){ return "8";  }
        if(v == 9){ return "9";  }
        if(v == 10){ return "10";  }
        if(v == 11){ return "11";  }
        if(v == 12){ return "12";  }
        if(v == 13){ return "13";  }
        if(v == 14){ return "14";  }
        if(v == 15){ return "15";  }
        if(v == 16){ return "16";  }
        return "0";
    }
   
}


contract Novax {
   
    function getParam3(string memory key) public view returns (address)  {}
   
}

contract Loot {
    function burnItem(uint256 tokenId) payable public {}
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function typeOfItem(uint _itemNo) view public returns(uint) {} 
    function ownerOf(uint256 tokenId) public view  returns (address) {}
}

contract Planet {
        function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
    function getParam1(uint planetId, string memory key) public view returns (uint256)  { }
   
    function getParam2(uint planetId, string memory key) public view returns (string memory)  {  }
}


contract MetadataSetter {
   function setParam1(uint planetNo, string memory key, uint256 value)  public{  }
   function setParam2(uint planetNo, string memory key, string memory value)  public{}
}