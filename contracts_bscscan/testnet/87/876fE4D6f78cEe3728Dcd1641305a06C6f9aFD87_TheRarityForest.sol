//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./IRarity.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

//森林
contract TheRarityForest is ERC721 {

    using Counters for Counters.Counter;//计数器
    using Strings for uint256;

    constructor(address _rarityAddr) ERC721("TheRarityForest", "TRF") {//地址
        rarityContract = IRarity(_rarityAddr);
    }

    uint256 private globalSeed;//全球种子
    IRarity public rarityContract;//合约
    mapping(address => mapping(uint256 => Research)) researchs;//研究
    mapping(uint256 => string) items;//项目
    mapping(uint256 => uint256) magic;//魔法
    mapping(uint256 => uint256) level;//等级
    Counters.Counter public _tokenIdCounter;//令牌编号计数器

    string[] sevenDaysItems = [//七日物品
        "Dead King crown", //死去的国王皇冠
        "Black gauntlet",//黑色长手套
        "Haunted ring",//闹鬼的环
        "Ancient book",//古代的书
        "Enchanted book",//魔法书
        "Gold ring",//金戒指
        "Treasure map",//藏宝图
        "Spell book",//魔法师
        "Silver sword",//银剑
        "Ancient Prince Andre's Sword",//古老的安德烈王子之剑
        "Old damaged coin",//损坏的旧硬币
        "Magic necklace",//魔法项链
        "Mechanical hand"//机械手
    ];
    string[] sixDaysItems = [//六天项目
        "Silver sword",//银剑
        "Haunted ring",//闹鬼的环
        "War helmet",//战争的头盔
        "Fire boots",//火的靴子
        "War trophy",//战争的战利品
        "Elf skull",//精灵的头骨
        "Unknown ring",//未知的环
        "Silver ring",//银戒指
        "War book",//战争的书
        "Gold pot",//金罐
        "Demon head",//恶魔的头
        "Unknown key",//未知的关键
        "Cursed book",//被诅咒的书
        "Giant plant seed",//巨大的植物种子
        "Old farmer sickle",//老农夫的镰状
        "War trophy",//战争的战利品
        "Enchanted useless tool"//迷人的无用的工具
    ];
    string[] fiveDaysItems = [//五天项目
        "Dragon egg",//龙蛋
        "Bear claw",//熊爪
        "Silver sword",//银剑
        "Rare ring",//罕见的环
        "Glove with diamonds",//手套与钻石
        "Haunted cloak",//闹鬼的斗篷
        "Dead hero cape",//死去的英雄角
        "Cursed talisman",//被诅咒的护身符
        "Enchanted talisman",//魔法护身符
        "Haunted ring",//闹鬼的环
        "Time crystal",//时间晶体
        "Warrior watch",//战士手表
        "Paladin eye",//圣武士的眼镜
        "Metal horse saddle",//金属马鞍
        "Witcher book",//巫师之书
        "Witch book",//女巫的书
        "Unknown animal eye"//未知的动物的眼镜
    ];
    string[] fourDaysItems = [//四天项目
        "Slain warrior armor",//杀戮战士盔甲
        "Witcher book",//巫师之书
        "Cursed talisman",//被诅咒的护身符
        "Antique ring",//古董戒指
        "Ancient Prince Andre's Sword",//古老的安德烈王子之剑
        "King's son sword",//国王之子剑
        "Old damaged coin",//损坏的旧硬币
        "Thunder hammer",//雷锤
        "Time crystal",//时间晶体
        "Skull fragment",//头骨碎片
        "Hawk eye",//鹰的眼镜
        "Meteorite fragment",//陨石碎片
        "Mutant fisheye",//突变的鱼眼石
        "Wolf necklace",//狼的项链
        "Shadowy rabbit paw",//阴暗的兔爪
        "Paladin eye"//圣武士的眼镜
    ];

    event ResearchStarted(uint256 summonerId, address owner);//研究开始
    event TreasureDiscovered(address owner, uint256 treasureId);//发现宝藏
    event TreasureLevelUp(uint256 treasureId, uint256 summonerId, uint256 newLevel);//宝藏升级

    struct Research {//研究
        uint256 timeInDays;//时间
        uint256 initBlock; //Block when research started 初始化块
        bool discovered;//发现
        uint256 summonerId;//召唤师ID
        address owner;//所有者
    }

    //Gen random
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    //需要经验
    //Return required XP to levelup a treasure
    function xpRequired(uint currentLevel) public pure returns (uint xpToNextLevel) {
        xpToNextLevel = currentLevel * 1000e18;
        for (uint i = 1; i < currentLevel; i++) {
            xpToNextLevel += currentLevel * 1000e18;
        }
    }

    //随机宝物
    //Get random treasure
    function _randomTreasure(Research memory research) internal returns (string memory, uint256, uint256){
        string memory _string = string(abi.encodePacked(research.summonerId, abi.encodePacked(research.owner), abi.encodePacked(research.initBlock), abi.encodePacked(globalSeed)));
        uint256 index = _random(_string);
        globalSeed = index;

        if (research.timeInDays == 7) {//7天
            //(itemName, magic, level)
            return (sevenDaysItems[index % sevenDaysItems.length], index % 11, index % 6);
        }
        if (research.timeInDays == 6) {//6天
            //(itemName, magic, level)
            return (sixDaysItems[index % sixDaysItems.length], index % 11, index % 6);
        }
        if (research.timeInDays == 5) {//5天
            //(itemName, magic, level)
            return (fiveDaysItems[index % fiveDaysItems.length], index % 11, index % 6);
        }
        if (research.timeInDays == 4) {//4天
            //(itemName, magic, level)
            return (fourDaysItems[index % fourDaysItems.length], index % 11, index % 6);
        }
        
    }

    //是召唤者的所有者或被批准者
    //Is owner of summoner or is approved
    function _isApprovedOrOwnerOfSummoner(uint256 summonerId, address _owner) internal view virtual returns (bool) {
        //_owner => expected owner
        address spender = address(this);
        address owner = rarityContract.ownerOf(summonerId);
        return (owner == _owner || rarityContract.getApproved(summonerId) == spender || rarityContract.isApprovedForAll(owner, spender));
    }

    //铸造一个新的 ERC721
    //Mint a new ERC721
    function safeMint(address to) internal returns (uint256){
        uint256 counter = _tokenIdCounter.current();
        _safeMint(to, counter);
        _tokenIdCounter.increment();
        return counter;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("name", " ", items[tokenId]));

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = string(abi.encodePacked("magic", " ", magic[tokenId].toString()));

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = string(abi.encodePacked("level", " ", level[tokenId].toString()));

        parts[6] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "treasure #', tokenId.toString(), '", "description": "Rarity is achieved through good luck and intelligence", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    //研究森林
    //Research for new treasuries
    function startResearch(uint256 summonerId, uint256 timeInDays) public returns (uint256) {
        //timeInDays -> time to research the forest timeInDays -> 研究森林的时间
        require(timeInDays >= 4 && timeInDays <= 7, "not valid");
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your summoner");
        (,,,uint256 summonerLevel) = rarityContract.summoner(summonerId);
        require(summonerLevel >= 2, "not level >= 2");
        require(researchs[msg.sender][summonerId].timeInDays == 0 || researchs[msg.sender][summonerId].discovered == true, "not empty or not discovered yet"); //If empty or already discovered 如果为空或已发现
        researchs[msg.sender][summonerId] = Research(timeInDays, block.timestamp, false, summonerId, msg.sender);
        emit ResearchStarted(summonerId, msg.sender);
        return summonerId;
    }

    //发现宝藏
    //Discover a treasure
    function discover(uint256 summonerId) public returns (uint256){
        Research memory research = researchs[msg.sender][summonerId];
        require(!research.discovered && research.timeInDays > 0, "already discovered or not initialized");
        require(research.initBlock + (research.timeInDays * 1 days) < block.timestamp, "not finish yet");
        //mint erc721 based on pseudo random things
        (string memory _itemName, uint256 _magic, uint256 _level) = _randomTreasure(research);
        uint256 newTokenId = safeMint(msg.sender);
        items[newTokenId] = _itemName;
        magic[newTokenId] = _magic;
        level[newTokenId] = _level;
        research.discovered = true;
        researchs[msg.sender][summonerId] = research;
        emit TreasureDiscovered(msg.sender, newTokenId);
        return newTokenId;
    }

    //升级物品，消耗召唤师 XP（需要批准）
    //Level up an item, spending summoner XP (need approval)
    function levelUp(uint256 summonerId, uint256 tokenId) public {
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your treasure");
        uint256 current = level[tokenId];
        rarityContract.spend_xp(summonerId, xpRequired(current));
        level[tokenId] += 1;
        emit TreasureLevelUp(tokenId, summonerId, current + 1);
    }

    //查看您的宝藏
    //View your treasure
    function treasure(uint tokenId) external view returns (string memory _itemName, uint _magic, uint _level) {
        _itemName = items[tokenId];
        _magic = magic[tokenId];
        _level = level[tokenId];
    }

}