//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Base64.sol";

interface rarity {
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
}

contract Alien is ERC721Enumerable {
    rarity constant rm = rarity(0xc4B6C3E745313384072Cc0CcaC56ad2a40459855);
    
    address payable public owner;
    
    //下一个异兽
    uint public next_alien;
    
    //异兽minted的数量
    uint public birdbodydragonheadgod_minted;
    uint public dragonbodybirdgodhead_minted;
    uint public phoenix_minted;
    uint public ninetailedfox_minted;
    uint public ironeater_minted;
    uint public gluttonousgluttonous_minted;
    uint public qiongqi_minted;
    
    //异兽组件
    mapping(uint => uint) public dna;
    mapping(uint => uint) public class;
    mapping(uint => uint) public attribute;
    
    mapping(uint256 => mapping(uint => uint256)) public existing_combinations;

    //异兽关联
    mapping(uint => alien_score) public alien_scores;
    
    event alienjo(uint summoner, uint alien);
    
    event aliened(address indexed owner, uint alien);
    
    //dna
    uint dna_digits = 16;
    uint dna_modulus = 10 ** dna_digits;

    struct alien_score {
        uint summoner;
        uint alien;
    }

    uint[10] private attributerandom = [
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        2,
        2,
        3
    ];

    constructor() ERC721("Alien Manifested", "AMS"){
        owner = payable(msg.sender);
    }  

    function generate(uint256 _next_alien, uint256 rand, uint8 _alien) internal {
        uint rand_dna = rand % dna_modulus;
        if (existing_combinations[rand_dna][_alien] == 0) {   
            dna[_next_alien] = rand_dna;
            class[_next_alien] = _alien;
            attribute[_next_alien] = attributerandom[rand % attributerandom.length];
            existing_combinations[_next_alien][rand] = _next_alien;
        }
        generate(_next_alien, rand % dna_modulus, _alien);
    }

    function mint_alien(uint8 _alien) private{
        if (_alien == 1) {
            birdbodydragonheadgod_minted ++;
        }else if (_alien == 2) {
            dragonbodybirdgodhead_minted ++;          
        }else if (_alien == 3) {
            phoenix_minted ++;             
        }else if (_alien == 4) {
            ninetailedfox_minted ++;     
        }else if (_alien == 5) {
            ironeater_minted ++;     
        }else if (_alien == 6) {
            gluttonousgluttonous_minted ++;               
        }else if (_alien == 7) {
            qiongqi_minted ++;     
        }  
        next_alien ++;
        uint _next_alien = next_alien;
        uint rand = uint(keccak256(abi.encodePacked(_next_alien)));   
        generate(_next_alien, rand, _alien);
        _safeMint(msg.sender, _next_alien);
        emit aliened(msg.sender, _next_alien);
    }      
    
    function mint(uint8 _alien) public payable{
        require(_alien >= 1 && _alien <= 7, "Classes ID invalid");
        if (_alien == 1) {
            require(msg.value == 5, "5BNB IS REQUIRED");
            require(birdbodydragonheadgod_minted >= 0 && birdbodydragonheadgod_minted < 50, "Token ID invalid");
        }else if (_alien == 2) {
            require(msg.value == 5, "5BNB IS REQUIRED");
            require(dragonbodybirdgodhead_minted >= 0 && dragonbodybirdgodhead_minted < 50, "Token ID invalid");             
        }else if (_alien == 3) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(phoenix_minted >= 0 && phoenix_minted < 1000, "Token ID invalid");            
        }else if (_alien == 4) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(ninetailedfox_minted >= 0 && ninetailedfox_minted < 1000, "Token ID invalid");         
        }else if (_alien == 5) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(ironeater_minted >= 0 && ironeater_minted < 1000, "Token ID invalid");            
        }else if (_alien == 6) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(gluttonousgluttonous_minted >= 0 && gluttonousgluttonous_minted < 1000, "Token ID invalid");           
        }else if (_alien == 7) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(qiongqi_minted >= 0 && qiongqi_minted < 1000, "Token ID invalid");
        }    
        mint_alien(_alien);
    }

    function aliener(uint _alien) external view returns (uint _class, uint _dna, uint _attribute) {
        _class = class[_alien];
        _dna = dna[_alien];
        _attribute = attribute[_alien];
    }

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender;
    }

    //怪物关联
    function alien_join(uint _summoner, uint _alien) external {
        require(_isApprovedOrOwner(_summoner));
        require(ownerOf(_alien) == msg.sender, "ERC721: transfer caller is not owner nor approved");
        alien_scores[_alien] = alien_score(_summoner, _alien);
        emit alienjo(_summoner, _alien);
    }  
    
    //获取怪物是否关联
    function select_join(uint _alien) public view returns (bool flag) {
        alien_score storage _ms = alien_scores[_alien];
        if(_ms.summoner == 0){
           flag = false;
        }else{
           flag = true;
        }
    } 
 
    function withdraw() public {
        require(msg.sender == owner, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    //类型
    function classes(uint id) public pure returns (string memory description) {
        if (id == 1) {//鸟身龙首神
           return "Bird body dragon head god";
        } else if (id == 2) {//龙身鸟首神
            return "Dragon Body Bird Godhead";
        } else if (id == 3) {//凤凰
            return "Phoenix";
        } else if (id == 4) {//九尾狐
            return "NineTailedFox";
        } else if (id == 5) {//食铁兽(大熊猫)
            return "Giant Panda (Iron Beast)";
        } else if (id == 6) {//饕餮
            return "Gluttonous Gluttonous";
        } else if (id == 7) {//穷奇
            return "Qiong Qi";
        }
    }
    
    
    function tokenURI(uint256 _alien) public view returns (string memory) {
        string memory output;
        {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("class", " ", toString(class[_alien])));
        
        parts[2] = '</text></svg>';
        
        output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        }
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "alien #', toString(_alien), '", "description": "Rarity is achieved via an active economy, alien must level, gain feats, learn spells, to be able to craft gear. This allows for market driven rarity while allowing an ever growing economy. Feats, spells, and summoner gear is ommitted as part of further expansions.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }



    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


}