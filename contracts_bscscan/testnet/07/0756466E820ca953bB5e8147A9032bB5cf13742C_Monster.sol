//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Base64.sol";

contract Monster is ERC721Enumerable {
    address payable public owner;
    
    struct ability_score {//属性值
        string quality;//属性
        uint32 attack;//攻击
        uint32 defense;//防御
        uint32 constitution;//体力
        uint32 vitality;//活力
        uint32 speed;//速度
        string colour;//颜色
        uint32 dodge;//躲闪
        uint32 life;//寿命
        uint32 growing_up;//成长
        uint32 five_elements;//五行
    }
    
        
    string[11] private colour = [
        "red",
        "orange",
        "yellow",
        "green",
        "blue",
        "purple",
        "white",
        "gray",
        "black",
        "brown",
        "silver"
    ];
    
    
    mapping(uint => ability_score) public ability_scores;//属性值
    mapping(uint => uint) public class;
    uint public next_monster;
    uint public monster1_count;
    uint public monster2_count;
    uint public monster3_count;
    uint public monster4_count;
    uint public monster5_count;
    uint public monster6_count;
    uint public monster7_count;
    uint public monster8_count;
    uint public monster9_count;
    uint public monster10_count;
    uint public monster11_count;


    constructor() ERC721("Monster Manifested", "MMS"){
        owner = payable(msg.sender);
    }

    event monstered(address indexed owner, uint monster);
    //水平
    event Leveled(address indexed leveler, uint next_monster, string quality, uint32 attack, uint32 defense, uint32 constitution, uint32 vitality, uint32 speed, string colour, uint32 dodge, uint32 life, uint32 growing_up, uint32 five_elements);
  
    
    function mintMonster(uint id) private{
        if (id == 1) {
            monster1_count ++;
        }else if (id == 2) {
            monster2_count ++;
        }else if (id == 3) {
            monster3_count ++;
        }else if (id == 4) {
            monster4_count ++;
        }else if (id == 5) {
            monster5_count ++;
        }else if (id == 6) {
            monster6_count ++;
        }else if (id == 7) {
            monster7_count ++;
        }else if (id == 8) {
            monster8_count ++;
        }else if (id == 9) {
            monster9_count ++;
        }else if (id == 10) {
            monster10_count ++;
        }else if (id == 11) {
            monster11_count ++;
        }
        next_monster ++;
        uint _next_monster = next_monster;
        class[_next_monster] = id;
        uint rand = uint(keccak256(abi.encodePacked(_next_monster)));        
        ability_score storage _attr = ability_scores[_next_monster];//属性值
        _attr.quality = "rare";//品质 罕见
        _attr.attack = 10;//攻击
        _attr.defense = 10;//防御
        _attr.constitution = 10;//体力
        _attr.vitality = 10;//活力
        _attr.speed = 10;//速度
        _attr.colour = colour[rand % colour.length];//颜色
        _attr.dodge = 10;//躲闪
        _attr.life = 10;//寿命
        _attr.growing_up = 10;//成长
        _attr.five_elements = 10;//五行
        _safeMint(msg.sender, _next_monster);
        //水平
        emit Leveled(msg.sender, _next_monster, _attr.quality, _attr.attack, _attr.defense, _attr.constitution, _attr.vitality,_attr.speed, _attr.colour, _attr.dodge, _attr.life, _attr.growing_up, _attr.five_elements);
        emit monstered(msg.sender, _next_monster);
    }
    

    function claim(uint id) public payable{
        require(msg.value == 1e18, "1BNB IS REQUIRED");
        require(id >= 1 && id <= 11, "Classes ID invalid");
        //require(next_monster >= 0 && next_monster < 20000, "Token ID invalid");
        require(monster1_count >= 0 && monster1_count < 10000, "Token ID invalid");
        require(monster2_count >= 0 && monster2_count < 10000, "Token ID invalid");
        require(monster3_count >= 0 && monster3_count < 10000, "Token ID invalid");
        require(monster4_count >= 0 && monster4_count < 10000, "Token ID invalid");
        require(monster5_count >= 0 && monster5_count < 10000, "Token ID invalid");
        require(monster6_count >= 0 && monster6_count < 10000, "Token ID invalid");
        require(monster7_count >= 0 && monster7_count < 10000, "Token ID invalid");
        require(monster8_count >= 0 && monster8_count < 10000, "Token ID invalid");
        require(monster9_count >= 0 && monster9_count < 10000, "Token ID invalid");
        require(monster10_count >= 0 && monster10_count < 10000, "Token ID invalid");
        require(monster11_count >= 0 && monster11_count < 10000, "Token ID invalid");
        require(isClasses(id) == false, "Each alien beast can only be summoned once!");
        mintMonster(id);
    }
    
    function isClasses(uint _class) public view returns (bool flag) {
        address msgsender = msg.sender;
        uint _balanceOf = balanceOf(msgsender);
        if (_balanceOf != 0) {
            for (uint i=0; i < _balanceOf ; i++) {
                uint _tokenOf = tokenOfOwnerByIndex(msgsender, i);
                uint _classOf = class[_tokenOf];
                if (_classOf == _class) {
                    flag = true;
                }
            }
        }
    }
    
/*    function isClasses(uint _class) public view returns (bool flag) {
        uint _balanceOf = balanceOf(msg.sender);
        if (_balanceOf != 0) {
            for (uint i=0; i < _balanceOf ; i++) {
                uint _tokenOf = tokenOfOwnerByIndex(msg.sender, i);
                uint _classOf = class[_tokenOf];
                if (_classOf == _class) {
                    flag = true;
                }
            }
        }
    }  */  

    /**
     * 获取宠物角色相关信息
    */
    function monster(uint _monster) external view returns (uint _class) {
        _class = class[_monster];
    }
    
    function withdraw() public {
        require(msg.sender == owner, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    function classes(uint id) public pure returns (string memory description) {
        if (id == 1) {//九尾狐
            return "NineTailedFox"; 
        } else if (id == 2) {//饕餮
            return "Gluttonous Gluttonous";
        } else if (id == 3) {//大熊猫（食铁兽）
            return "Giant Panda (Iron Beast)";
        } else if (id == 4) {//帝江
            return "Di Jiang";
        } else if (id == 5) {//穷奇
            return "Qiong Qi";
        } else if (id == 6) {//鹿蜀
            return "Lu Shu";
        } else if (id == 7) {//鸟身龙首神
            return "Bird body dragon head god";
        } else if (id == 8) {//蛊雕
            return "Gu Diao";
        } else if (id == 9) {//龙身鸟首神
            return "Dragon Body Bird Godhead";
        } else if (id == 10) {//凤皇
            return "Fenghuang";
        } else if (id == 11) {//息壤
            return "Xi Rang";
        }
    }
    
    function classesquality(uint id) public pure returns (string memory description) {
        if (id == 1) {//罕见
            return "rare";  
        } else if (id == 2) {//极品
            return "Need";
        } else if (id == 3) {//普通
            return "ordinary";  
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