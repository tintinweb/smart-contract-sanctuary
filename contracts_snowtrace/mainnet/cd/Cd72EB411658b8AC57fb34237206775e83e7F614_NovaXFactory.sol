/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract NovaXFactory {
    address private owner;

    constructor() {
        owner = msg.sender;
       
    }

    
    function generateTroop(uint troopId, uint planetNo, address owner) payable onlyNovaxGame public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        uint256 fLevel  = planet.getParam1(planetNo, "f-level"); 
        uint256 aLevel  = planet.getParam1(planetNo, "a-level"); 
        if(troopId >= 0 && troopId <= 4){
            require(fLevel >= 1, "Need to build factory on your planet.");
        }else if(troopId >= 5 && troopId <= 12){
            require(aLevel >= 1, "Need to build academy on your planet.");
        }
        
        //0: Light fighter
        //1: Heavy fighter
        //2: battleship
        //3: cruiser
        //4: destroyer
        //5: space soldier
        //6: space dog
        //7: heavy space soldier
        //8: plasma powered soldier
        //9: bomber
        //10: alien leader
        //11: samurai
        //12: doom warrior
        
        

        //check if research is done.
        if(troopId == 0){
            require(true);
        }
        else if(troopId == 1){
            require(isResearchDone(0, planetNo), "research not done");
        }
        else if(troopId == 2){
            require(isResearchDone(1, planetNo), "research not done");
        }
        else if(troopId == 3){
            require(isResearchDone(2, planetNo), "research not done");
        }
        else if(troopId == 4){
            require(isResearchDone(3, planetNo), "research not done");
        }
        else if(troopId == 5){
            require(true);
        }
        else if(troopId == 6){
            require(isResearchDone(4, planetNo), "research not done");
        }
        else if(troopId == 7){
            require(isResearchDone(5, planetNo), "research not done");
        }
        else if(troopId == 8){
            require(isResearchDone(6, planetNo), "research not done");
        }
        else if(troopId == 9){
            require(isResearchDone(7, planetNo), "research not done");
        }
        else if(troopId == 10){
            require(isResearchDone(8, planetNo), "research not done");
        }
        else if(troopId == 11){
            require(isResearchDone(9, planetNo), "research not done");
        }
        else if(troopId == 12){
            require(isResearchDone(10, planetNo), "research not done");
        }else{
            require(false, "wrong id");
        }
        
        Troop troop = Troop(0x7C347AF74c8DfAf629E4E4D3343d6E6A6ecACe80);
        troop.createItem(owner, troopId);

    }
    
    function totalCostOfTroop( uint troopId) public view returns (uint256[] memory){
        
        uint256[] memory resources = new uint[](3);
        
        require((troopId >= 0) && troopId <= 12, "Wrong troop id");
        if(troopId == 0){
            resources[0] = 4578 ether; resources[1] = 11345 ether; resources[2] = 500 ether;
        }
        else if(troopId == 1){
            resources[0] = 7245 ether; resources[1] = 16820 ether; resources[2] = 800 ether;
        }
        else if(troopId == 2){
            resources[0] = 15456 ether; resources[1] = 33456 ether; resources[2] = 1580 ether;
        }
        else if(troopId == 3){
            resources[0] = 32456 ether; resources[1] = 70123 ether; resources[2] = 3296 ether;
        }
        else if(troopId == 4){
            resources[0] = 72456 ether; resources[1] = 155123 ether; resources[2] = 7060 ether;
        }
        else if(troopId == 5){
            resources[0] = 2800 ether; resources[1] = 6123 ether; resources[2] = 123 ether;
        }
        else if(troopId == 6){
            resources[0] = 3400 ether; resources[1] = 7500 ether; resources[2] = 167 ether;
        }
        else if(troopId == 7){
            resources[0] = 4897 ether; resources[1] = 10784 ether; resources[2] = 327 ether;
        }
        else if(troopId == 8){
            resources[0] = 6784 ether; resources[1] = 14675 ether; resources[2] = 512 ether;
        }
        else if(troopId == 9){
            resources[0] = 8124 ether; resources[1] = 17654 ether; resources[2] = 897 ether;
        }
        else if(troopId == 10){
            resources[0] = 24784 ether; resources[1] = 48312 ether; resources[2] = 2545 ether;
        }
        else if(troopId == 11){
            resources[0] = 26457 ether; resources[1] = 50456 ether; resources[2] = 2845 ether;
        }
        else if(troopId == 12){
            resources[0] = 29456 ether; resources[1] = 55789 ether; resources[2] = 3145 ether;
        }
        return resources;
    }
    
    function resourceAddress(uint rIndex) private view returns (address){
        if (rIndex == 0) {
            return address(0xE6eE049183B474ecf7704da3F6F555a1dCAF240F);
        }else if(rIndex == 1){
            return address(0x4C1057455747e3eE5871D374FdD77A304cE10989);
        }else if(rIndex == 2){
            return address(0x70b4aE8eb7bd572Fc0eb244Cd8021066b3Ce7EE4);
        }
        return address(0);
    }
   
    function hasEnoughResource(address userAddress, address rAddress, uint256 amount) private view returns (bool){
        IERC20 token = IERC20(rAddress);
        return (amount <= token.balanceOf(userAddress));
    }
    
    function isResearchDone(uint researchId, uint planetNo) view public  returns (bool) {
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        string memory researchKey = string(abi.encodePacked("r-",  uintToString(researchId)));
        uint256 r  = planet.getParam1(planetNo, researchKey); 
        return (r == 1);
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
    
    modifier onlyNovaxGame() {

        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address gameAddress = novax.getParam3("game");

        require (gameAddress != address(0));
        require (msg.sender == gameAddress );
        _;
    }
   
}


contract Novax {
   
    function getParam3(string memory key) public view returns (address)  {}
   
}

contract Troop {
      function createItem(address  _to, uint _troopId) payable public returns (uint){}

}

contract Planet {
        function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function createItem(address  _to) payable public returns (uint){}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
    function getParam1(uint planetId, string memory key) public view returns (uint256)  { }
   
    function getParam2(uint planetId, string memory key) public view returns (string memory)  {  }
}


contract MetadataSetter {
   function setParam1(uint planetNo, string memory key, uint256 value)  public{  }
   function setParam2(uint planetNo, string memory key, string memory value)  public{}
}


interface IERC20 {
    function mint(address account, uint256 amount) external payable  returns(bool);
    function burn(address account, uint256 amount) external payable returns(bool);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}