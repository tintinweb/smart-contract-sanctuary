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
    
    //异兽类型
    mapping(uint => uint) public class;
    
    //下一个异兽
    uint public next_monster;
    
    //异兽minted的数量
    uint public birdbodydragonheadgod_minted;
    uint public dragonbodybirdgodhead_minted;
    uint public phoenix_minted;
    uint public ninetailedfox_minted;
    uint public ironeater_minted;
    uint public gluttonousgluttonous_minted;
    uint public qiongqi_minted;
    
    //异兽组件
    uint8[][11] public birdbodydragonheadgod;
    uint8[][11] public dragonbodybirdgodhead;
    uint8[][11] public phoenix;
    uint8[][11] public ninetailedfox;
    uint8[][11] public ironeater;
    uint8[][11] public gluttonousgluttonous;
    uint8[][11] public qiongqi;
    
    mapping(uint256 => Component) public tokenTraits;
    
    mapping(uint256 => mapping(uint => uint256)) public existingCombinations;

    //异兽关联
    mapping(uint => monster_score) public monster_scores;
    
    event monsterjo(uint summoner, uint monster);
    
    event monstered(address indexed owner, uint monster);
    
    struct monster_score {
        uint summoner;
        uint monster;
    }
    
    struct Component {
        uint8 bkgd;
        uint8 head;
        uint8 neck;
        uint8 body;
        uint8 arm;
        uint8 hand;
        uint8 leg;
        uint8 foot;
        uint8 clothing;
        uint8 tail;
        uint8 attribute;
    }

    constructor() ERC721("Alien Manifested", "AMS"){
        owner = payable(msg.sender);
        //bkgd
        birdbodydragonheadgod[0] = [1, 2, 3];
        dragonbodybirdgodhead[0] = [1, 2, 3];
        phoenix[0] = [1, 2, 3];
        ninetailedfox[0] = [1, 2, 3];
        ironeater[0] = [1, 2, 3];
        gluttonousgluttonous[0] = [1, 2, 3];
        qiongqi[0] = [1, 2, 3];
        //head
        birdbodydragonheadgod[1] = [1, 2, 3];
        dragonbodybirdgodhead[1] = [1, 2, 3];
        phoenix[1] = [1, 2, 3];
        ninetailedfox[1] = [1, 2, 3];
        ironeater[1] = [1, 2, 3];
        gluttonousgluttonous[1] = [1, 2, 3];
        qiongqi[1] = [1, 2, 3];
        //neck
        birdbodydragonheadgod[2] = [1, 2];
        dragonbodybirdgodhead[2] = [1, 2];
        phoenix[2] = [1, 2];
        ninetailedfox[2] = [1, 2];
        ironeater[2] = [1, 2];
        gluttonousgluttonous[2] = [1, 2];
        qiongqi[2] = [1, 2];
        //body
        birdbodydragonheadgod[3] = [1, 2];
        dragonbodybirdgodhead[3] = [1, 2];
        phoenix[3] = [1, 2];
        ninetailedfox[3] = [0];
        ironeater[3] = [1, 2];
        gluttonousgluttonous[3] = [1, 2];
        qiongqi[3] = [1, 2];
        //arm
        birdbodydragonheadgod[4] = [1, 2, 3];
        dragonbodybirdgodhead[4] = [1, 2, 3];
        phoenix[4] = [1, 2];
        ninetailedfox[4] = [0];
        ironeater[4] = [1, 2, 3];
        gluttonousgluttonous[4] = [1, 2, 3];
        qiongqi[4] = [1, 2, 3];
        //hand
        birdbodydragonheadgod[5] = [1, 2, 3];
        dragonbodybirdgodhead[5] = [1, 2, 3];
        phoenix[5] = [0];
        ninetailedfox[5] = [0];
        ironeater[5] = [0];
        gluttonousgluttonous[5] = [0];
        qiongqi[5] = [0];
        //leg
        birdbodydragonheadgod[6] = [1, 2, 3];
        dragonbodybirdgodhead[6] = [1, 2, 3];
        phoenix[6] = [0];
        ninetailedfox[6] = [0];
        ironeater[6] = [0];
        gluttonousgluttonous[6] = [0];
        qiongqi[6] = [0];
        //foot
        birdbodydragonheadgod[7] = [1, 2]; 
        dragonbodybirdgodhead[7] = [1, 2];
        phoenix[7] = [1, 2];
        ninetailedfox[7] = [0];
        ironeater[7] = [1, 2, 3];
        gluttonousgluttonous[7] = [1, 2];
        qiongqi[7] = [1, 2];
        //clothing
        birdbodydragonheadgod[8] = [1, 2, 3];    
        dragonbodybirdgodhead[8] = [1, 2, 3];
        phoenix[8] = [1, 2, 3];
        ninetailedfox[8] = [0];
        ironeater[8] = [1, 2, 3];
        gluttonousgluttonous[8] = [1, 2, 3];
        qiongqi[8] = [1, 2, 3];
        //tail
        birdbodydragonheadgod[9] = [1, 2];  
        dragonbodybirdgodhead[9] = [1, 2];
        phoenix[9] = [1, 2];
        ninetailedfox[9] = [0];
        ironeater[9] = [1, 2];
        gluttonousgluttonous[9] = [1, 2];
        qiongqi[9] = [1, 2];
        //attribute
        birdbodydragonheadgod[10] = [1, 1, 1, 1, 1, 1, 1, 2, 2, 3];   
        dragonbodybirdgodhead[10] = [1, 1, 1, 1, 1, 1, 1, 2, 2, 3];
        phoenix[10] = [1, 1, 1, 1, 1, 1, 1, 2, 2, 3];
        ninetailedfox[10] = [0];
        ironeater[10] = [1, 1, 1, 1, 1, 1, 1, 2, 2, 3];
        gluttonousgluttonous[10] = [1, 1, 1, 1, 1, 1, 1, 2, 2, 3];
        qiongqi[10] = [1, 1, 1, 1, 1, 1, 1, 2, 2, 3];
    }
    
    function mint(uint _monster) public payable{
        require(_monster >= 1 && _monster <= 7, "Classes ID invalid");
        if (_monster == 1) {
            require(msg.value == 5, "5BNB IS REQUIRED");
            require(birdbodydragonheadgod_minted >= 0 && birdbodydragonheadgod_minted < 50, "Token ID invalid");
        }else if (_monster == 2) {
            require(msg.value == 5, "5BNB IS REQUIRED");
            require(dragonbodybirdgodhead_minted >= 0 && dragonbodybirdgodhead_minted < 50, "Token ID invalid");             
        }else if (_monster == 3) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(phoenix_minted >= 0 && phoenix_minted < 1000, "Token ID invalid");            
        }else if (_monster == 4) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(ninetailedfox_minted >= 0 && ninetailedfox_minted < 1000, "Token ID invalid");         
        }else if (_monster == 5) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(ironeater_minted >= 0 && ironeater_minted < 1000, "Token ID invalid");            
        }else if (_monster == 6) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(gluttonousgluttonous_minted >= 0 && gluttonousgluttonous_minted < 1000, "Token ID invalid");           
        }else if (_monster == 7) {
            require(msg.value == 5e17, "0.5BNB IS REQUIRED");
            require(qiongqi_minted >= 0 && qiongqi_minted < 1000, "Token ID invalid");
        }    
        mint_monster(_monster);
    }
   
    
    function mint_monster(uint _monster) private{
        if (_monster == 1) {
            birdbodydragonheadgod_minted ++;
        }else if (_monster == 2) {
            dragonbodybirdgodhead_minted ++;          
        }else if (_monster == 3) {
            phoenix_minted ++;             
        }else if (_monster == 4) {
            ninetailedfox_minted ++;     
        }else if (_monster == 5) {
            ironeater_minted ++;     
        }else if (_monster == 6) {
            gluttonousgluttonous_minted ++;               
        }else if (_monster == 7) {
            qiongqi_minted ++;     
        }  
        next_monster ++;
        uint _next_monster = next_monster;
        class[_next_monster] = _monster;
        uint rand = uint(keccak256(abi.encodePacked(_next_monster)));
        generate(next_monster, rand, _monster);
        _safeMint(msg.sender, _next_monster);
        emit monstered(msg.sender, _next_monster);
    }  

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender;
    }

    //怪物关联
    function monster_join(uint _summoner, uint _monster) external {
        require(_isApprovedOrOwner(_summoner));
        require(ownerOf(_monster) == msg.sender, "ERC721: transfer caller is not owner nor approved");
        monster_scores[_monster] = monster_score(_summoner, _monster);
        emit monsterjo(_summoner, _monster);
    }  
    
    //获取怪物是否关联
    function select_join(uint _monster) public view returns (bool flag) {
        monster_score storage _ms = monster_scores[_monster];
        if(_ms.summoner == 0){
           flag = false;
        }else{
           flag = true;
        }
    } 
    
    function generate(uint256 tokenId, uint256 rand, uint _monster) internal returns (Component memory t) {
        t = selectTraits(rand, _monster);
        if (existingCombinations[structToHash(t)][_monster] == 0) {
          tokenTraits[tokenId] = t;
          existingCombinations[structToHash(t)][_monster] = tokenId;
          return t;
        }
        return generate(tokenId, uint(keccak256(abi.encodePacked(rand))), _monster);
    }
      
    
    function getTokenTraits(uint256 tokenId) external view returns (Component memory) {
        return tokenTraits[tokenId];
    }
 
    function structToHash(Component memory s) internal pure returns (uint256) {
        return uint256(bytes32(
            abi.encodePacked(
              s.bkgd,
              s.head,
              s.neck,
              s.body,
              s.arm,
              s.hand,
              s.leg,
              s.foot,
              s.clothing,
              s.tail,
              s.attribute
            )
        ));
    } 

    function structToHash2(Component memory s) external pure returns (uint256) {
        return uint256(bytes32(
            abi.encodePacked(
              s.bkgd,
              s.head,
              s.neck,
              s.body,
              s.arm,
              s.hand,
              s.leg,
              s.foot,
              s.clothing,
              s.tail,
              s.attribute
            )
        ));
    }    
    
    function selectTraits(uint256 rand, uint _monster) internal view returns (Component memory t) {   
        if (_monster == 1) {
            t.bkgd = birdbodydragonheadgod[0][rand % birdbodydragonheadgod[0].length];
            t.head = birdbodydragonheadgod[1][rand % birdbodydragonheadgod[1].length];
            t.neck = birdbodydragonheadgod[2][rand % birdbodydragonheadgod[2].length];
            t.body = birdbodydragonheadgod[3][rand % birdbodydragonheadgod[3].length];
            t.arm = birdbodydragonheadgod[4][rand % birdbodydragonheadgod[4].length];
            t.hand = birdbodydragonheadgod[5][rand % birdbodydragonheadgod[5].length];
            t.leg = birdbodydragonheadgod[6][rand % birdbodydragonheadgod[6].length];
            t.foot = birdbodydragonheadgod[7][rand % birdbodydragonheadgod[7].length];
            t.clothing = birdbodydragonheadgod[8][rand % birdbodydragonheadgod[8].length];
            t.tail = birdbodydragonheadgod[9][rand % birdbodydragonheadgod[9].length];
            t.attribute = birdbodydragonheadgod[10][rand % birdbodydragonheadgod[10].length];
        }else if (_monster == 2) {
            t.bkgd = dragonbodybirdgodhead[0][rand % dragonbodybirdgodhead[0].length];
            t.head = dragonbodybirdgodhead[1][rand % dragonbodybirdgodhead[1].length];
            t.neck = dragonbodybirdgodhead[2][rand % dragonbodybirdgodhead[2].length];
            t.body = dragonbodybirdgodhead[3][rand % dragonbodybirdgodhead[3].length];
            t.arm = dragonbodybirdgodhead[4][rand % dragonbodybirdgodhead[4].length];
            t.hand = dragonbodybirdgodhead[5][rand % dragonbodybirdgodhead[5].length];
            t.leg = dragonbodybirdgodhead[6][rand % dragonbodybirdgodhead[6].length];
            t.foot = dragonbodybirdgodhead[7][rand % dragonbodybirdgodhead[7].length];
            t.clothing = dragonbodybirdgodhead[8][rand % dragonbodybirdgodhead[8].length];
            t.tail = dragonbodybirdgodhead[9][rand % dragonbodybirdgodhead[9].length];
            t.attribute = dragonbodybirdgodhead[10][rand % dragonbodybirdgodhead[10].length];       
        }else if (_monster == 3) {
            t.bkgd = phoenix[0][rand % phoenix[0].length];
            t.head = phoenix[1][rand % phoenix[1].length];
            t.neck = phoenix[2][rand % phoenix[2].length];
            t.body = phoenix[3][rand % phoenix[3].length];
            t.arm = phoenix[4][rand % phoenix[4].length];
            t.hand = phoenix[5][rand % phoenix[5].length];
            t.leg = phoenix[6][rand % phoenix[6].length];
            t.foot = phoenix[7][rand % phoenix[7].length];
            t.clothing = phoenix[8][rand % phoenix[8].length];
            t.tail = phoenix[9][rand % phoenix[9].length];
            t.attribute = phoenix[10][rand % phoenix[10].length];         
        }else if (_monster == 4) {
            t.bkgd = ninetailedfox[0][rand % ninetailedfox[0].length];
            t.head = ninetailedfox[1][rand % ninetailedfox[1].length];
            t.neck = ninetailedfox[2][rand % ninetailedfox[2].length];
            t.body = ninetailedfox[3][rand % ninetailedfox[3].length];
            t.arm = ninetailedfox[4][rand % ninetailedfox[4].length];
            t.hand = ninetailedfox[5][rand % ninetailedfox[5].length];
            t.leg = ninetailedfox[6][rand % ninetailedfox[6].length];
            t.foot = ninetailedfox[7][rand % ninetailedfox[7].length];
            t.clothing = ninetailedfox[8][rand % ninetailedfox[8].length];
            t.tail = ninetailedfox[9][rand % ninetailedfox[9].length];
            t.attribute = ninetailedfox[10][rand % ninetailedfox[10].length];  
        }else if (_monster == 5) {
            t.bkgd = ironeater[0][rand % ironeater[0].length];
            t.head = ironeater[1][rand % ironeater[1].length];
            t.neck = ironeater[2][rand % ironeater[2].length];
            t.body = ironeater[3][rand % ironeater[3].length];
            t.arm = ironeater[4][rand % ironeater[4].length];
            t.hand = ironeater[5][rand % ironeater[5].length];
            t.leg = ironeater[6][rand % ironeater[6].length];
            t.foot = ironeater[7][rand % ironeater[7].length];
            t.clothing = ironeater[8][rand % ironeater[8].length];
            t.tail = ironeater[9][rand % ironeater[9].length];
            t.attribute = ironeater[10][rand % ironeater[10].length]; 
        }else if (_monster == 6) {
            t.bkgd = gluttonousgluttonous[0][rand % gluttonousgluttonous[0].length];
            t.head = gluttonousgluttonous[1][rand % gluttonousgluttonous[1].length];
            t.neck = gluttonousgluttonous[2][rand % gluttonousgluttonous[2].length];
            t.body = gluttonousgluttonous[3][rand % gluttonousgluttonous[3].length];
            t.arm = gluttonousgluttonous[4][rand % gluttonousgluttonous[4].length];
            t.hand = gluttonousgluttonous[5][rand % gluttonousgluttonous[5].length];
            t.leg = gluttonousgluttonous[6][rand % gluttonousgluttonous[6].length];
            t.foot = gluttonousgluttonous[7][rand % gluttonousgluttonous[7].length];
            t.clothing = gluttonousgluttonous[8][rand % gluttonousgluttonous[8].length];
            t.tail = gluttonousgluttonous[9][rand % gluttonousgluttonous[9].length];
            t.attribute = gluttonousgluttonous[10][rand % gluttonousgluttonous[10].length];         
        }else if (_monster == 7) {
            t.bkgd = qiongqi[0][rand % qiongqi[0].length];
            t.head = qiongqi[1][rand % qiongqi[1].length];
            t.neck = qiongqi[2][rand % qiongqi[2].length];
            t.body = qiongqi[3][rand % qiongqi[3].length];
            t.arm = qiongqi[4][rand % qiongqi[4].length];
            t.hand = qiongqi[5][rand % qiongqi[5].length];
            t.leg = qiongqi[6][rand % qiongqi[6].length];
            t.foot = qiongqi[7][rand % qiongqi[7].length];
            t.clothing = qiongqi[8][rand % qiongqi[8].length];
            t.tail = qiongqi[9][rand % qiongqi[9].length];
            t.attribute = qiongqi[10][rand % qiongqi[10].length];
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
    
    
    function tokenURI(uint256 _monster) public view returns (string memory) {
        string memory output;
        {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("class", " ", toString(class[_monster])));
        
        parts[2] = '</text></svg>';
        
        output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        }
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "monster #', toString(_monster), '", "description": "Rarity is achieved via an active economy, monster must level, gain feats, learn spells, to be able to craft gear. This allows for market driven rarity while allowing an ever growing economy. Feats, spells, and summoner gear is ommitted as part of further expansions.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
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