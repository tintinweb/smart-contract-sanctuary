//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Base64.sol";

contract Monster is ERC721Enumerable {
    address payable public owner;
    
    struct ability_score {//属性值
        uint32 attributes;//属性
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

    constructor() ERC721("Monster Manifested", "MMS"){
        owner = payable(msg.sender);
    }

    event monstered(address indexed owner, uint monster);
    //水平
    event Leveled(address indexed leveler, uint next_monster, uint32 attributes, uint32 attack, uint32 defense, uint32 constitution, uint32 vitality, uint32 speed, string colour, uint32 dodge, uint32 life, uint32 growing_up, uint32 five_elements);
  
    
    function mintMonster(uint id) private{
        if (id == 1) {
            monster1_count ++;
        }else if (id == 2) {
            monster2_count ++;
        }
        next_monster ++;
        uint _next_monster = next_monster;
        class[_next_monster] = id;
        uint rand = uint(keccak256(abi.encodePacked(_next_monster)));        
        ability_score storage _attr = ability_scores[_next_monster];//属性值
        //_attr.attributes = 10;//属性
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
        emit Leveled(msg.sender, _next_monster, _attr.attributes,_attr.attack, _attr.defense, _attr.constitution, _attr.vitality,_attr.speed, _attr.colour, _attr.dodge, _attr.life, _attr.growing_up, _attr.five_elements);
        emit monstered(msg.sender, _next_monster);
    }
    

    function claim(uint id) public payable{
        require(msg.value == 1e18, "1BNB IS REQUIRED");
        require(id >= 1 && id <= 2, "Classes ID invalid");
        require(next_monster >= 0 && next_monster < 20000, "Token ID invalid");
        require(monster1_count >= 0 && monster1_count < 10000, "Token ID invalid");
        require(monster2_count >= 0 && monster2_count < 10000, "Token ID invalid");
        mintMonster(id);
    }
    
    /**
     * 获取召唤师角色相关信息
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
        if (id == 1) {
            return "Gluttonous";
        } else if (id == 2) {
            return "NineTailedFox";
        }
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