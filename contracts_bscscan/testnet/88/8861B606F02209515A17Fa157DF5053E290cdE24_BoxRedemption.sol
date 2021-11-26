// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ERC1155_CONTRACT {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeMint(address to, string memory partCode) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

interface ERC721_CONTRACT {
    function safeMint(address to, string memory partCode) external;
}

interface RANDOM_CONTRACT {
    function startRandom() external returns (uint256);
}

contract BoxRedemption is Ownable {
    using Strings for string;
    uint8 private constant NFT_TYPE = 0; //Kingdom
    uint8 private constant KINGDOM = 1; //Kingdom
    uint8 private constant TRANING_CAMP = 2; //Training Camp
    uint8 private constant GEAR = 3; //Battle Gear
    uint8 private constant DRO = 4; //Battle DRO
    uint8 private constant SUITE = 5; //Battle Suit
    uint8 private constant BOT = 6; //Battle Bot
    uint8 private constant GEN = 7; //Human GEN
    uint8 private constant WEAP = 8; //WEAP
    uint8 private constant COMBAT_RANKS = 9; //Combat Ranks
    uint8 private constant BLUEPRINT_COMM = 0;
    uint8 private constant BLUEPRINT_RARE = 1;
    uint8 private constant BLUEPRINT_EPIC = 2;
    uint8 private constant GENOMIC_COMMON = 3;
    uint8 private constant GENOMIC_RARE = 4;
    uint8 private constant GENOMIC_EPIC = 5;
    uint8 private constant SPACE_WARRIOR = 6;
    uint8 private constant COMMON = 0;
    uint8 private constant RARE = 1;
    uint8 private constant EPIC = 2;

    // //Testnet
    // address public constant MISTORY_BOX_CONTRACT =
    //     0xfB684dC65DE6C27c63fa7a00B9b9fB70d2125Ea1;
    // address public constant ECIO_NFT_CORE_CONTRACT =
    //     0x7E8eEe5be55A589d5571Be7176172f4DEE7f47aF;
    // address public constant RANDOM_WORKER_CONTRACT =
    //     0x5ABF279B87F84C916d0f34c2dafc949f86ffb887;

      //Main
    address public constant MISTORY_BOX_CONTRACT =
        0x1ddCD5B73afb734b4AE6B1C139858F36311Ed4d3;
    address public constant ECIO_NFT_CORE_CONTRACT =
        0x328Bac8C81A947094f34651e6B0e548EBe35796B;
    address public constant RANDOM_WORKER_CONTRACT =
        0xa17Dc043C68B7714B6D0847ab45F1cE73fc05Bca;

    //Mainnet
    address public constant GAX_CM = 0xaae9f9d4fb8748feba405cE25856DC57C91BbB92;
    address public constant GAX_RARE = 0xc04581BEA69A9C781532A17169C59980F4faC757;
    address public constant GAX_EPIC = 0x9C90ba4C8834e92A771e4Fc0f486F1460e7b7a34;

    //Testnet
    // address public constant GAX_CM = 0x80Bf5dbD599769Eb008a61da6a20a347db35Fd0e;
    // address public constant GAX_RARE =
    //     0x0253Bbd5874f775100BCec873383a2AfdA466273;
    // address public constant GAX_EPIC =
    //     0x36b6eA8bc7E0F4817D3b0212a6797E9b4316eC4C;

    mapping(uint256 => address) ranNumToSender;
    mapping(uint256 => uint256) requestToNFTId;

    //NFTPool
    mapping(uint256 => mapping(uint256 => uint256)) public NFTPool;

    //EPool
    mapping(uint256 => uint256) public EPool;

    //BlueprintFragmentPool
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))))
        public BPPool;

    //GenPool
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
        public GenPool;

    //SpaceWarriorPool
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
        public SWPool;

    event OpenBox(address _by, uint256 _nftId, string partCode);

    constructor() {}

    function initial() public onlyOwner {
        //NFT Type
        // NFTPool[COMMON][0] = 0; //BLUEPRINT_COMM
        // NFTPool[COMMON][1] = 0;
        // NFTPool[COMMON][2] = 0;
        // NFTPool[COMMON][3] = 0;
        // NFTPool[COMMON][4] = 0;
        // NFTPool[COMMON][5] = 0;
        NFTPool[COMMON][6] = 1; //BLUEPRINT_RARE
        NFTPool[COMMON][7] = 1;
        NFTPool[COMMON][8] = 1;
        NFTPool[COMMON][9] = 1;
        for (uint256 i = 10; i <=17; i++) {
             NFTPool[COMMON][i] = 3;
        }
        // NFTPool[COMMON][10] = 3; //GENOMIC_COMMON
        // NFTPool[COMMON][11] = 3;
        // NFTPool[COMMON][12] = 3;
        // NFTPool[COMMON][13] = 3;
        // NFTPool[COMMON][14] = 3;
        // NFTPool[COMMON][15] = 3;
        // NFTPool[COMMON][16] = 3;
        // NFTPool[COMMON][17] = 3;
        NFTPool[COMMON][18] = 6; //SPACE_WARRIOR
        NFTPool[COMMON][19] = 6;

        // NFTPool[RARE][0] = 0;//BLUEPRINT_COMM
        // NFTPool[RARE][1] = 0;
        NFTPool[RARE][2] = 1; //BLUEPRINT_RARE
        NFTPool[RARE][3] = 1;
        NFTPool[RARE][4] = 2; //BLUEPRINT_EPIC
        NFTPool[RARE][5] = 3; //GENOMIC_COMMON
        NFTPool[RARE][6] = 3;
        NFTPool[RARE][7] = 3;
        NFTPool[RARE][8] = 3;
        NFTPool[RARE][9] = 4; //GENOMIC_RARE
        NFTPool[RARE][10] = 4;
        NFTPool[RARE][11] = 4;
        NFTPool[RARE][12] = 4;
        NFTPool[RARE][13] = 4;
        NFTPool[RARE][14] = 4;
        for (uint256 i = 15; i <=19; i++) {
           NFTPool[RARE][i] = 6;
        }
        // NFTPool[RARE][15] = 6; //SPACE_WARRIOR
        // NFTPool[RARE][16] = 6;
        // NFTPool[RARE][17] = 6;
        // NFTPool[RARE][18] = 6;
        // NFTPool[RARE][19] = 6;

        NFTPool[EPIC][0] = 2; //BLUEPRINT_EPIC
        NFTPool[EPIC][1] = 2;
        NFTPool[EPIC][2] = 4; //GENOMIC_RARE
        NFTPool[EPIC][3] = 4;
        NFTPool[EPIC][4] = 5; //GENOMIC_EPIC
        NFTPool[EPIC][5] = 5;
        for (uint256 i = 6; i <=19; i++) {
             NFTPool[EPIC][i] = 6;
        }

        // NFTPool[EPIC][6] = 6; //SPACE_WARRIOR
        // NFTPool[EPIC][7] = 6;
        // NFTPool[EPIC][8] = 6;
        // NFTPool[EPIC][9] = 6;
        // NFTPool[EPIC][10] = 6;
        // NFTPool[EPIC][11] = 6;
        // NFTPool[EPIC][12] = 6;
        // NFTPool[EPIC][13] = 6;
        // NFTPool[EPIC][14] = 6;
        // NFTPool[EPIC][15] = 6;
        // NFTPool[EPIC][16] = 6;
        // NFTPool[EPIC][17] = 6;
        // NFTPool[EPIC][18] = 6;
        // NFTPool[EPIC][19] = 6;

        EPool[0] = GEAR; //Battle Gear
        EPool[1] = DRO; //Battle DRO
        EPool[2] = SUITE; //Battle Suit
        EPool[3] = BOT; //Battle Bot
        EPool[4] = WEAP; //WEAP

        // SWPool[TRANING_CAMP][COMMON][0] = 0;
        SWPool[TRANING_CAMP][COMMON][1] = 1;
        SWPool[TRANING_CAMP][COMMON][2] = 2;
        SWPool[TRANING_CAMP][COMMON][3] = 3;
        SWPool[TRANING_CAMP][COMMON][4] = 4;

        // SWPool[TRANING_CAMP][RARE][0] = 0;
        SWPool[TRANING_CAMP][RARE][1] = 1;
        SWPool[TRANING_CAMP][RARE][2] = 2;
        SWPool[TRANING_CAMP][RARE][3] = 3;
        SWPool[TRANING_CAMP][RARE][4] = 4;

        // SWPool[TRANING_CAMP][EPIC][0] = 0;
        SWPool[TRANING_CAMP][EPIC][1] = 1;
        SWPool[TRANING_CAMP][EPIC][2] = 2;
        SWPool[TRANING_CAMP][EPIC][3] = 3;
        SWPool[TRANING_CAMP][EPIC][4] = 4;
    }

    function initialRandomData() public onlyOwner {
        // --- For Common Box ------
        BPPool[COMMON][COMMON][GEAR][0] = 1;
        BPPool[COMMON][COMMON][GEAR][1] = 2;
        BPPool[COMMON][COMMON][GEAR][2] = 3;
        BPPool[COMMON][COMMON][GEAR][3] = 4;

        BPPool[COMMON][COMMON][DRO][0] = 1;
        BPPool[COMMON][COMMON][DRO][1] = 2;
        BPPool[COMMON][COMMON][DRO][2] = 3;
        BPPool[COMMON][COMMON][DRO][3] = 4;

        // BPPool[COMMON][COMMON][SUITE][0] = 0;
        BPPool[COMMON][COMMON][SUITE][1] = 1;
        BPPool[COMMON][COMMON][SUITE][2] = 2;

        BPPool[COMMON][COMMON][BOT][0] = 1;
        BPPool[COMMON][COMMON][BOT][1] = 2;
        BPPool[COMMON][COMMON][BOT][2] = 3;
        BPPool[COMMON][COMMON][BOT][3] = 4;

        // BPPool[COMMON][COMMON][WEAP][0] = 0;
        BPPool[COMMON][COMMON][WEAP][1] = 1;
        BPPool[COMMON][COMMON][WEAP][2] = 2;
        BPPool[COMMON][COMMON][WEAP][3] = 3;
        //
        BPPool[COMMON][RARE][GEAR][0] = 5;
        BPPool[COMMON][RARE][GEAR][1] = 6;
        BPPool[COMMON][RARE][GEAR][2] = 7;

        BPPool[COMMON][RARE][DRO][0] = 5;
        BPPool[COMMON][RARE][DRO][1] = 6;
        BPPool[COMMON][RARE][DRO][2] = 7;

        BPPool[COMMON][RARE][SUITE][0] = 3;
        BPPool[COMMON][RARE][SUITE][1] = 4;
        BPPool[COMMON][RARE][SUITE][2] = 5;

        BPPool[COMMON][RARE][BOT][0] = 5;
        BPPool[COMMON][RARE][BOT][1] = 6;
        BPPool[COMMON][RARE][BOT][2] = 7;

        BPPool[COMMON][RARE][WEAP][0] = 4;
        BPPool[COMMON][RARE][WEAP][1] = 5;
        BPPool[COMMON][RARE][WEAP][2] = 6;
        BPPool[COMMON][RARE][WEAP][3] = 7;

        // GenPool[COMMON][COMMON][0] = 0;
        GenPool[COMMON][COMMON][1] = 1;
        GenPool[COMMON][COMMON][2] = 2;
        GenPool[COMMON][COMMON][3] = 3;
        GenPool[COMMON][COMMON][4] = 4;
        GenPool[COMMON][COMMON][5] = 5;
        GenPool[COMMON][COMMON][6] = 6;

        // --- For  Rare Box ------
        BPPool[RARE][COMMON][GEAR][0] = 1;
        BPPool[RARE][COMMON][GEAR][1] = 2;
        BPPool[RARE][COMMON][GEAR][2] = 3;
        BPPool[RARE][COMMON][GEAR][3] = 4;

        BPPool[RARE][COMMON][DRO][0] = 1;
        BPPool[RARE][COMMON][DRO][1] = 2;
        BPPool[RARE][COMMON][DRO][2] = 3;
        BPPool[RARE][COMMON][DRO][3] = 4;

        // BPPool[RARE][COMMON][SUITE][0] = 0;
        BPPool[RARE][COMMON][SUITE][1] = 1;
        BPPool[RARE][COMMON][SUITE][2] = 2;

        BPPool[RARE][COMMON][BOT][0] = 1;
        BPPool[RARE][COMMON][BOT][1] = 2;
        BPPool[RARE][COMMON][BOT][2] = 3;
        BPPool[RARE][COMMON][BOT][3] = 4;

        // BPPool[RARE][COMMON][WEAP][0] = 0;
        BPPool[RARE][COMMON][WEAP][1] = 1;
        BPPool[RARE][COMMON][WEAP][2] = 2;
        BPPool[RARE][COMMON][WEAP][3] = 3;
        //
        BPPool[RARE][RARE][GEAR][0] = 5;
        BPPool[RARE][RARE][GEAR][1] = 6;
        BPPool[RARE][RARE][GEAR][2] = 7;

        BPPool[RARE][RARE][DRO][0] = 5;
        BPPool[RARE][RARE][DRO][1] = 6;
        BPPool[RARE][RARE][DRO][2] = 7;

        BPPool[RARE][RARE][SUITE][0] = 3;
        BPPool[RARE][RARE][SUITE][1] = 4;
        BPPool[RARE][RARE][SUITE][2] = 5;

        BPPool[RARE][RARE][BOT][0] = 5;
        BPPool[RARE][RARE][BOT][1] = 6;
        BPPool[RARE][RARE][BOT][2] = 7;

        BPPool[RARE][RARE][WEAP][0] = 4;
        BPPool[RARE][RARE][WEAP][1] = 5;
        BPPool[RARE][RARE][WEAP][2] = 6;
        BPPool[RARE][RARE][WEAP][3] = 7;
        BPPool[RARE][RARE][WEAP][4] = 8;

        //Epic
        BPPool[RARE][EPIC][GEAR][0] = 8;
        BPPool[RARE][EPIC][GEAR][1] = 9;
        BPPool[RARE][EPIC][GEAR][2] = 10;

        BPPool[RARE][EPIC][DRO][0] = 8;
        BPPool[RARE][EPIC][DRO][1] = 9;
        BPPool[RARE][EPIC][DRO][2] = 10;

        BPPool[RARE][EPIC][SUITE][0] = 6;
        BPPool[RARE][EPIC][SUITE][1] = 7;
        BPPool[RARE][EPIC][SUITE][2] = 8;
        BPPool[RARE][EPIC][SUITE][3] = 9;

        BPPool[RARE][EPIC][BOT][0] = 8;
        BPPool[RARE][EPIC][BOT][1] = 9;
        BPPool[RARE][EPIC][BOT][2] = 10;

        BPPool[RARE][EPIC][WEAP][0] = 9;
        BPPool[RARE][EPIC][WEAP][1] = 10;
        BPPool[RARE][EPIC][WEAP][2] = 11;
        BPPool[RARE][EPIC][WEAP][3] = 12;
        BPPool[RARE][EPIC][WEAP][4] = 13;
        BPPool[RARE][EPIC][WEAP][5] = 14;

        // GenPool[RARE][COMMON][0] = 0;
        GenPool[RARE][COMMON][1] = 1;
        GenPool[RARE][COMMON][2] = 2;
        GenPool[RARE][COMMON][3] = 3;
        GenPool[RARE][COMMON][4] = 4;
        GenPool[RARE][COMMON][5] = 5;
        GenPool[RARE][COMMON][6] = 6;

        GenPool[RARE][RARE][0] = 7;
        GenPool[RARE][RARE][1] = 8;
        GenPool[RARE][RARE][2] = 9;
        GenPool[RARE][RARE][3] = 10;
        GenPool[RARE][RARE][4] = 11;
        GenPool[RARE][RARE][5] = 12;

        // --- For Epic Box ------
        BPPool[EPIC][RARE][GEAR][0] = 8;
        BPPool[EPIC][RARE][GEAR][1] = 9;
        BPPool[EPIC][RARE][GEAR][2] = 10;

        BPPool[EPIC][RARE][DRO][0] = 8;
        BPPool[EPIC][RARE][DRO][1] = 9;
        BPPool[EPIC][RARE][DRO][2] = 10;

        BPPool[EPIC][RARE][SUITE][0] = 6;
        BPPool[EPIC][RARE][SUITE][1] = 7;
        BPPool[EPIC][RARE][SUITE][2] = 8;
        BPPool[EPIC][RARE][SUITE][3] = 9;

        BPPool[EPIC][RARE][BOT][0] = 8;
        BPPool[EPIC][RARE][BOT][1] = 9;
        BPPool[EPIC][RARE][BOT][2] = 10;

        BPPool[EPIC][RARE][WEAP][0] = 9;
        BPPool[EPIC][RARE][WEAP][1] = 10;
        BPPool[EPIC][RARE][WEAP][2] = 11;
        BPPool[EPIC][RARE][WEAP][3] = 12;
        BPPool[EPIC][RARE][WEAP][4] = 13;
        BPPool[EPIC][RARE][WEAP][5] = 14;

        //Epic
        BPPool[EPIC][EPIC][GEAR][0] = 8;
        BPPool[EPIC][EPIC][GEAR][1] = 9;
        BPPool[EPIC][EPIC][GEAR][2] = 10;

        BPPool[EPIC][EPIC][DRO][0] = 8;
        BPPool[EPIC][EPIC][DRO][1] = 9;
        BPPool[EPIC][EPIC][DRO][2] = 10;

        BPPool[EPIC][EPIC][SUITE][0] = 6;
        BPPool[EPIC][EPIC][SUITE][1] = 7;
        BPPool[EPIC][EPIC][SUITE][2] = 8;
        BPPool[EPIC][EPIC][SUITE][3] = 9;

        BPPool[EPIC][EPIC][BOT][0] = 8;
        BPPool[EPIC][EPIC][BOT][1] = 9;
        BPPool[EPIC][EPIC][BOT][2] = 10;

        BPPool[EPIC][EPIC][WEAP][0] = 9;
        BPPool[EPIC][EPIC][WEAP][1] = 10;
        BPPool[EPIC][EPIC][WEAP][2] = 11;
        BPPool[EPIC][EPIC][WEAP][3] = 12;
        BPPool[EPIC][EPIC][WEAP][4] = 13;
        BPPool[EPIC][EPIC][WEAP][5] = 14;

        // GenPool[EPIC][COMMON][0] = 0;
        // GenPool[EPIC][COMMON][1] = 1;
        // GenPool[EPIC][COMMON][2] = 2;
        // GenPool[EPIC][COMMON][3] = 3;
        // GenPool[EPIC][COMMON][4] = 4;
        // GenPool[EPIC][COMMON][5] = 5;
        // GenPool[EPIC][COMMON][6] = 6;

        GenPool[EPIC][RARE][0] = 7;
        GenPool[EPIC][RARE][1] = 8;
        GenPool[EPIC][RARE][2] = 9;
        GenPool[EPIC][RARE][3] = 10;
        GenPool[EPIC][RARE][4] = 11;
        GenPool[EPIC][RARE][5] = 12;

        GenPool[EPIC][EPIC][0] = 13;
        GenPool[EPIC][EPIC][1] = 14;
        GenPool[EPIC][EPIC][2] = 15;
        GenPool[EPIC][EPIC][3] = 16;
    }

    function initialSpaceData1() public onlyOwner {
        //BattleGearCampPool
        // SWPool[GEAR][COMMON][0] = 0;
        // SWPool[GEAR][COMMON][1] = 0;
        // SWPool[GEAR][COMMON][2] = 0;
        // SWPool[GEAR][COMMON][3] = 0;
        // SWPool[GEAR][COMMON][4] = 0;
        // SWPool[GEAR][COMMON][5] = 0;
        // SWPool[GEAR][COMMON][6] = 0;
        // SWPool[GEAR][COMMON][7] = 0;
        // SWPool[GEAR][COMMON][8] = 0;
        // SWPool[GEAR][COMMON][9] = 0;
        // SWPool[GEAR][COMMON][10] = 0;
        // SWPool[GEAR][COMMON][11] = 0;
        // SWPool[GEAR][COMMON][12] = 0;
        // SWPool[GEAR][COMMON][13] = 0;
        // SWPool[GEAR][COMMON][14] = 0;
        // SWPool[GEAR][COMMON][15] = 0;
        // SWPool[GEAR][COMMON][16] = 0;
        // SWPool[GEAR][COMMON][17] = 0;
        // SWPool[GEAR][COMMON][18] = 0;
        // SWPool[GEAR][COMMON][19] = 0;
        // SWPool[GEAR][COMMON][20] = 0;
        // SWPool[GEAR][COMMON][21] = 0;
        // SWPool[GEAR][COMMON][22] = 0;
        // SWPool[GEAR][COMMON][23] = 0;
        SWPool[GEAR][COMMON][24] = 1;
        SWPool[GEAR][COMMON][25] = 2;
        SWPool[GEAR][COMMON][26] = 3;
        SWPool[GEAR][COMMON][27] = 4;
        SWPool[GEAR][COMMON][28] = 5;
        SWPool[GEAR][COMMON][29] = 6;

        //DRO
        // SWPool[DRO][COMMON][0] = 0;
        // SWPool[DRO][COMMON][1] = 0;
        // SWPool[DRO][COMMON][2] = 0;
        // SWPool[DRO][COMMON][3] = 0;
        // SWPool[DRO][COMMON][4] = 0;
        // SWPool[DRO][COMMON][5] = 0;
        // SWPool[DRO][COMMON][6] = 0;
        // SWPool[DRO][COMMON][7] = 0;
        // SWPool[DRO][COMMON][8] = 0;
        // SWPool[DRO][COMMON][9] = 0;
        // SWPool[DRO][COMMON][10] = 0;
        // SWPool[DRO][COMMON][11] = 0;
        // SWPool[DRO][COMMON][12] = 0;
        // SWPool[DRO][COMMON][13] = 0;
        // SWPool[DRO][COMMON][14] = 0;
        // SWPool[DRO][COMMON][15] = 0;
        // SWPool[DRO][COMMON][16] = 0;
        // SWPool[DRO][COMMON][17] = 0;
        // SWPool[DRO][COMMON][18] = 0;
        // SWPool[DRO][COMMON][19] = 0;
        // SWPool[DRO][COMMON][20] = 0;
        // SWPool[DRO][COMMON][21] = 0;
        // SWPool[DRO][COMMON][22] = 0;
        // SWPool[DRO][COMMON][23] = 0;
        SWPool[DRO][COMMON][24] = 1;
        SWPool[DRO][COMMON][25] = 2;
        SWPool[DRO][COMMON][26] = 3;
        SWPool[DRO][COMMON][27] = 4;
        SWPool[DRO][COMMON][28] = 5;
        SWPool[DRO][COMMON][29] = 6;

        //SUITE
        // SWPool[SUITE][COMMON][0] = 0;
        // SWPool[SUITE][COMMON][1] = 0;
        // SWPool[SUITE][COMMON][2] = 0;
        // SWPool[SUITE][COMMON][3] = 0;
        // SWPool[SUITE][COMMON][4] = 0;
        SWPool[SUITE][COMMON][5] = 1;
        SWPool[SUITE][COMMON][6] = 1;
        SWPool[SUITE][COMMON][7] = 1;
        SWPool[SUITE][COMMON][8] = 1;
        SWPool[SUITE][COMMON][9] = 1;
        SWPool[SUITE][COMMON][10] = 2;
        SWPool[SUITE][COMMON][11] = 2;
        SWPool[SUITE][COMMON][12] = 2;
        SWPool[SUITE][COMMON][13] = 2;
        SWPool[SUITE][COMMON][14] = 2;
        SWPool[SUITE][COMMON][15] = 3;
        SWPool[SUITE][COMMON][16] = 4;
        SWPool[SUITE][COMMON][17] = 5;

        //BOT
        // SWPool[BOT][COMMON][0] = 0;
        // SWPool[BOT][COMMON][1] = 0;
        // SWPool[BOT][COMMON][2] = 0;
        // SWPool[BOT][COMMON][3] = 0;
        // SWPool[BOT][COMMON][4] = 0;
        // SWPool[BOT][COMMON][5] = 0;
        // SWPool[BOT][COMMON][6] = 0;
        // SWPool[BOT][COMMON][7] = 0;
        // SWPool[BOT][COMMON][8] = 0;
        // SWPool[BOT][COMMON][9] = 0;
        // SWPool[BOT][COMMON][10] = 0;
        // SWPool[BOT][COMMON][11] = 0;
        // SWPool[BOT][COMMON][12] = 0;
        // SWPool[BOT][COMMON][13] = 0;
        // SWPool[BOT][COMMON][14] = 0;
        // SWPool[BOT][COMMON][15] = 0;
        // SWPool[BOT][COMMON][16] = 0;
        // SWPool[BOT][COMMON][17] = 0;
        // SWPool[BOT][COMMON][18] = 0;
        SWPool[BOT][COMMON][19] = 1;
        SWPool[BOT][COMMON][20] = 1;
        SWPool[BOT][COMMON][21] = 2;
        SWPool[BOT][COMMON][22] = 2;
        SWPool[BOT][COMMON][23] = 3;
        SWPool[BOT][COMMON][24] = 3;
        SWPool[BOT][COMMON][25] = 4;
        SWPool[BOT][COMMON][26] = 4;
        SWPool[BOT][COMMON][27] = 5;
        SWPool[BOT][COMMON][28] = 6;
        SWPool[BOT][COMMON][29] = 7;

        //GEN
        // SWPool[GEN][COMMON][0] = 0;
        // SWPool[GEN][COMMON][1] = 0;
        // SWPool[GEN][COMMON][2] = 0;
        // SWPool[GEN][COMMON][3] = 0;
        SWPool[GEN][COMMON][4] = 1;
        SWPool[GEN][COMMON][5] = 1;
        SWPool[GEN][COMMON][6] = 1;
        SWPool[GEN][COMMON][7] = 1;
         for (uint256 i = 8; i <=11; i++) {
           SWPool[GEN][COMMON][i] = 2;
        }
        // SWPool[GEN][COMMON][8] = 2;
        // SWPool[GEN][COMMON][9] = 2;
        // SWPool[GEN][COMMON][10] = 2;
        // SWPool[GEN][COMMON][11] = 2;
        SWPool[GEN][COMMON][12] = 3;
        SWPool[GEN][COMMON][13] = 3;
        SWPool[GEN][COMMON][14] = 3;
        SWPool[GEN][COMMON][15] = 3;
        SWPool[GEN][COMMON][16] = 4;
        SWPool[GEN][COMMON][17] = 4;
        SWPool[GEN][COMMON][18] = 4;
        SWPool[GEN][COMMON][19] = 4;
        SWPool[GEN][COMMON][20] = 5;
        SWPool[GEN][COMMON][21] = 5;
        SWPool[GEN][COMMON][22] = 5;
        SWPool[GEN][COMMON][23] = 5;
        SWPool[GEN][COMMON][24] = 6;
        SWPool[GEN][COMMON][25] = 6;
        SWPool[GEN][COMMON][26] = 6;
        SWPool[GEN][COMMON][27] = 6;

        //WEAP
        // SWPool[WEAP][COMMON][0] = 0;
        // SWPool[WEAP][COMMON][1] = 0;
        // SWPool[WEAP][COMMON][2] = 0;
        // SWPool[WEAP][COMMON][3] = 0;
        // SWPool[WEAP][COMMON][4] = 0;
        // SWPool[WEAP][COMMON][5] = 0;
        for (uint256 i = 6; i <=11; i++) {
             SWPool[WEAP][COMMON][i] = 1;
        }
        // SWPool[WEAP][COMMON][6] = 1;
        // SWPool[WEAP][COMMON][7] = 1;
        // SWPool[WEAP][COMMON][8] = 1;
        // SWPool[WEAP][COMMON][9] = 1;
        // SWPool[WEAP][COMMON][10] = 1;
        // SWPool[WEAP][COMMON][11] = 1;
           for (uint256 i = 12; i <=17; i++) {
            SWPool[WEAP][COMMON][i] = 2;
        }
        // SWPool[WEAP][COMMON][12] = 2;
        // SWPool[WEAP][COMMON][13] = 2;
        // SWPool[WEAP][COMMON][14] = 2;
        // SWPool[WEAP][COMMON][15] = 2;
        // SWPool[WEAP][COMMON][16] = 2;
        // SWPool[WEAP][COMMON][17] = 2;
        for (uint256 i = 18; i <=23; i++) {
            SWPool[WEAP][COMMON][i] = 3;
        }
        // SWPool[WEAP][COMMON][18] = 3;
        // SWPool[WEAP][COMMON][19] = 3;
        // SWPool[WEAP][COMMON][20] = 3;
        // SWPool[WEAP][COMMON][21] = 3;
        // SWPool[WEAP][COMMON][22] = 3;
        // SWPool[WEAP][COMMON][23] = 3;
        SWPool[WEAP][COMMON][24] = 4;
        SWPool[WEAP][COMMON][25] = 5;
        SWPool[WEAP][COMMON][26] = 6;
        SWPool[WEAP][COMMON][27] = 7;
        SWPool[WEAP][COMMON][28] = 8;
    }

    function initialSpaceData2() public onlyOwner {
        // ------- RARE -------
        //BattleGearCampPool
        // SWPool[GEAR][RARE][0] = 0;
        // SWPool[GEAR][RARE][1] = 0;
        // SWPool[GEAR][RARE][2] = 0;
        // SWPool[GEAR][RARE][3] = 0;
        // SWPool[GEAR][RARE][4] = 0;
        // SWPool[GEAR][RARE][5] = 0;
        // SWPool[GEAR][RARE][6] = 0;
        // SWPool[GEAR][RARE][7] = 0;
        // SWPool[GEAR][RARE][8] = 0;
        // SWPool[GEAR][RARE][9] = 0;
        // SWPool[GEAR][RARE][10] = 0;
        // SWPool[GEAR][RARE][11] = 0;
        // SWPool[GEAR][RARE][12] = 0;
        // SWPool[GEAR][RARE][13] = 0;
        // SWPool[GEAR][RARE][14] = 0;
        // SWPool[GEAR][RARE][15] = 0;
        // SWPool[GEAR][RARE][16] = 0;
        // SWPool[GEAR][RARE][17] = 0;
        // SWPool[GEAR][RARE][18] = 0;
        // SWPool[GEAR][RARE][19] = 0;
        SWPool[GEAR][RARE][20] = 1;
        SWPool[GEAR][RARE][21] = 2;
        SWPool[GEAR][RARE][22] = 3;
        SWPool[GEAR][RARE][23] = 4;
        SWPool[GEAR][RARE][24] = 5;
        SWPool[GEAR][RARE][25] = 6;
        SWPool[GEAR][RARE][26] = 7;
        SWPool[GEAR][RARE][27] = 8;
        SWPool[GEAR][RARE][28] = 9;
        SWPool[GEAR][RARE][29] = 10;

        //DRO
        // SWPool[DRO][RARE][0] = 0;
        // SWPool[DRO][RARE][1] = 0;
        // SWPool[DRO][RARE][2] = 0;
        // SWPool[DRO][RARE][3] = 0;
        // SWPool[DRO][RARE][4] = 0;
        // SWPool[DRO][RARE][5] = 0;
        // SWPool[DRO][RARE][6] = 0;
        // SWPool[DRO][RARE][7] = 0;
        // SWPool[DRO][RARE][8] = 0;
        // SWPool[DRO][RARE][9] = 0;
        // SWPool[DRO][RARE][10] = 0;
        // SWPool[DRO][RARE][11] = 0;
        // SWPool[DRO][RARE][12] = 0;
        // SWPool[DRO][RARE][13] = 0;
        // SWPool[DRO][RARE][14] = 0;
        // SWPool[DRO][RARE][15] = 0;
        // SWPool[DRO][RARE][16] = 0;
        // SWPool[DRO][RARE][17] = 0;
        // SWPool[DRO][RARE][18] = 0;
        // SWPool[DRO][RARE][19] = 0;
        SWPool[DRO][RARE][20] = 1;
        SWPool[DRO][RARE][21] = 2;
        SWPool[DRO][RARE][22] = 3;
        SWPool[DRO][RARE][23] = 4;
        SWPool[DRO][RARE][24] = 5;
        SWPool[DRO][RARE][25] = 6;
        SWPool[DRO][RARE][26] = 7;
        SWPool[DRO][RARE][27] = 8;
        SWPool[DRO][RARE][28] = 9;
        SWPool[DRO][RARE][29] = 10;

        //SUITE
        // SWPool[SUITE][RARE][0] = 0;
        // SWPool[SUITE][RARE][1] = 0;
        // SWPool[SUITE][RARE][2] = 0;
        SWPool[SUITE][RARE][3] = 1;
        SWPool[SUITE][RARE][4] = 1;
        SWPool[SUITE][RARE][5] = 1;
        SWPool[SUITE][RARE][6] = 2;
        SWPool[SUITE][RARE][7] = 2;
        SWPool[SUITE][RARE][8] = 2;
        SWPool[SUITE][RARE][9] = 4;
        SWPool[SUITE][RARE][10] = 4;
        SWPool[SUITE][RARE][11] = 5;
        SWPool[SUITE][RARE][12] = 5;
        SWPool[SUITE][RARE][13] = 6;
        SWPool[SUITE][RARE][14] = 7;
        SWPool[SUITE][RARE][15] = 8;
        SWPool[SUITE][RARE][16] = 9;

        //BOT
        // SWPool[BOT][RARE][0] = 0;
        // SWPool[BOT][RARE][1] = 0;
        // SWPool[BOT][RARE][2] = 0;
        // SWPool[BOT][RARE][3] = 0;
        // SWPool[BOT][RARE][4] = 0;
        // SWPool[BOT][RARE][5] = 0;
        // SWPool[BOT][RARE][6] = 0;
        // SWPool[BOT][RARE][7] = 0;
        // SWPool[BOT][RARE][8] = 0;
        // SWPool[BOT][RARE][9] = 0;
        // SWPool[BOT][RARE][10] = 0;
        // SWPool[BOT][RARE][11] = 0;
        // SWPool[BOT][RARE][12] = 0;
        // SWPool[BOT][RARE][13] = 0;
        // SWPool[BOT][RARE][14] = 0;
        // SWPool[BOT][RARE][15] = 0;
        // SWPool[BOT][RARE][16] = 0;
        // SWPool[BOT][RARE][17] = 0;
        SWPool[BOT][RARE][18] = 1;
        SWPool[BOT][RARE][19] = 1;
        SWPool[BOT][RARE][20] = 2;
        SWPool[BOT][RARE][21] = 2;
        SWPool[BOT][RARE][22] = 4;
        SWPool[BOT][RARE][23] = 4;
        SWPool[BOT][RARE][24] = 5;
        SWPool[BOT][RARE][25] = 6;
        SWPool[BOT][RARE][26] = 7;
        SWPool[BOT][RARE][27] = 8;
        SWPool[BOT][RARE][28] = 9;
        SWPool[BOT][RARE][29] = 10;

        //GEN
        // SWPool[GEN][RARE][0] = 0;
        // SWPool[GEN][RARE][1] = 0;
        // SWPool[GEN][RARE][2] = 0;
        SWPool[GEN][RARE][3] = 1;
        SWPool[GEN][RARE][4] = 1;
        SWPool[GEN][RARE][5] = 1;
        SWPool[GEN][RARE][6] = 2;
        SWPool[GEN][RARE][7] = 2;
        SWPool[GEN][RARE][8] = 2;
        SWPool[GEN][RARE][9] = 3;
        SWPool[GEN][RARE][10] = 3;
        SWPool[GEN][RARE][11] = 3;
        SWPool[GEN][RARE][12] = 4;
        SWPool[GEN][RARE][13] = 4;
        SWPool[GEN][RARE][14] = 4;
        SWPool[GEN][RARE][15] = 5;
        SWPool[GEN][RARE][16] = 5;
        SWPool[GEN][RARE][17] = 5;
        SWPool[GEN][RARE][18] = 6;
        SWPool[GEN][RARE][19] = 6;
        SWPool[GEN][RARE][20] = 6;
        SWPool[GEN][RARE][21] = 7;
        SWPool[GEN][RARE][22] = 8;
        SWPool[GEN][RARE][23] = 9;
        SWPool[GEN][RARE][24] = 10;

        //WEAP
        // SWPool[WEAP][RARE][0] = 0;
        // SWPool[WEAP][RARE][1] = 0;
        // SWPool[WEAP][RARE][2] = 0;
        // SWPool[WEAP][RARE][3] = 0;
        // SWPool[WEAP][RARE][4] = 0;
        for (uint256 i = 5; i <=10; i++) {
            SWPool[WEAP][RARE][i] = 1;
        }
        // SWPool[WEAP][RARE][5] = 1;
        // SWPool[WEAP][RARE][6] = 1;
        // SWPool[WEAP][RARE][7] = 1;
        // SWPool[WEAP][RARE][8] = 1;
        // SWPool[WEAP][RARE][9] = 1;
        // SWPool[WEAP][RARE][10] = 1;
        SWPool[WEAP][RARE][11] = 2;
        SWPool[WEAP][RARE][12] = 2;
        SWPool[WEAP][RARE][13] = 2;
        SWPool[WEAP][RARE][14] = 2;
        SWPool[WEAP][RARE][15] = 2;
        SWPool[WEAP][RARE][16] = 2;
        SWPool[WEAP][RARE][17] = 3;
        SWPool[WEAP][RARE][18] = 3;
        SWPool[WEAP][RARE][19] = 3;
        SWPool[WEAP][RARE][20] = 3;
        SWPool[WEAP][RARE][21] = 3;
        SWPool[WEAP][RARE][22] = 3;
        SWPool[WEAP][RARE][23] = 4;
        SWPool[WEAP][RARE][24] = 5;
        SWPool[WEAP][RARE][25] = 6;
        SWPool[WEAP][RARE][26] = 7;
        SWPool[WEAP][RARE][27] = 8;
        SWPool[WEAP][RARE][28] = 9;
        SWPool[WEAP][RARE][29] = 10;
        SWPool[WEAP][RARE][30] = 11;
        SWPool[WEAP][RARE][31] = 12;
        SWPool[WEAP][RARE][32] = 13;
        SWPool[WEAP][RARE][33] = 14;
    }

    function initialSpaceData3() public onlyOwner {
        // ------- EPIC -------

        //BattleGearCampPool
        // SWPool[GEAR][EPIC][0] = 0;
        // SWPool[GEAR][EPIC][1] = 0;
        // SWPool[GEAR][EPIC][2] = 0;
        // SWPool[GEAR][EPIC][3] = 0;
        // SWPool[GEAR][EPIC][4] = 0;
        // SWPool[GEAR][EPIC][5] = 0;
        // SWPool[GEAR][EPIC][6] = 0;
        // SWPool[GEAR][EPIC][7] = 0;
        // SWPool[GEAR][EPIC][8] = 0;
        // SWPool[GEAR][EPIC][9] = 0;
        // SWPool[GEAR][EPIC][10] = 0;
        // SWPool[GEAR][EPIC][11] = 0;
        // SWPool[GEAR][EPIC][12] = 0;
        // SWPool[GEAR][EPIC][13] = 0;
        // SWPool[GEAR][EPIC][14] = 0;
        // SWPool[GEAR][EPIC][15] = 0;
        SWPool[GEAR][EPIC][16] = 1;
        SWPool[GEAR][EPIC][17] = 1;
        SWPool[GEAR][EPIC][18] = 2;
        SWPool[GEAR][EPIC][19] = 2;
        SWPool[GEAR][EPIC][20] = 3;
        SWPool[GEAR][EPIC][21] = 3;
        SWPool[GEAR][EPIC][22] = 4;
        SWPool[GEAR][EPIC][23] = 4;
        SWPool[GEAR][EPIC][24] = 5;
        SWPool[GEAR][EPIC][25] = 6;
        SWPool[GEAR][EPIC][26] = 7;
        SWPool[GEAR][EPIC][27] = 8;
        SWPool[GEAR][EPIC][28] = 9;
        SWPool[GEAR][EPIC][29] = 10;

        //DRO
        // SWPool[DRO][EPIC][0] = 0;
        // SWPool[DRO][EPIC][1] = 0;
        // SWPool[DRO][EPIC][2] = 0;
        // SWPool[DRO][EPIC][3] = 0;
        // SWPool[DRO][EPIC][4] = 0;
        // SWPool[DRO][EPIC][5] = 0;
        // SWPool[DRO][EPIC][6] = 0;
        // SWPool[DRO][EPIC][7] = 0;
        // SWPool[DRO][EPIC][8] = 0;
        // SWPool[DRO][EPIC][9] = 0;
        // SWPool[DRO][EPIC][10] = 0;
        // SWPool[DRO][EPIC][11] = 0;
        // SWPool[DRO][EPIC][12] = 0;
        // SWPool[DRO][EPIC][13] = 0;
        // SWPool[DRO][EPIC][14] = 0;
        // SWPool[DRO][EPIC][15] = 0;
        SWPool[DRO][EPIC][16] = 1;
        SWPool[DRO][EPIC][17] = 1;
        SWPool[DRO][EPIC][18] = 2;
        SWPool[DRO][EPIC][19] = 2;
        SWPool[DRO][EPIC][20] = 3;
        SWPool[DRO][EPIC][21] = 3;
        SWPool[DRO][EPIC][22] = 4;
        SWPool[DRO][EPIC][23] = 4;
        SWPool[DRO][EPIC][24] = 5;
        SWPool[DRO][EPIC][25] = 6;
        SWPool[DRO][EPIC][26] = 7;
        SWPool[DRO][EPIC][27] = 8;
        SWPool[DRO][EPIC][28] = 9;
        SWPool[DRO][EPIC][29] = 10;

        //SUITE
        // SWPool[SUITE][EPIC][0] = 0;
        // SWPool[SUITE][EPIC][1] = 0;
        // SWPool[SUITE][EPIC][2] = 0;
        // SWPool[SUITE][EPIC][3] = 0;
        SWPool[SUITE][EPIC][4] = 1;
        SWPool[SUITE][EPIC][5] = 1;
        SWPool[SUITE][EPIC][6] = 1;
        SWPool[SUITE][EPIC][7] = 1;
        SWPool[SUITE][EPIC][8] = 2;
        SWPool[SUITE][EPIC][9] = 2;
        SWPool[SUITE][EPIC][10] = 2;
        SWPool[SUITE][EPIC][11] = 2;
        SWPool[SUITE][EPIC][12] = 3;
        SWPool[SUITE][EPIC][13] = 4;
        SWPool[SUITE][EPIC][14] = 5;
        SWPool[SUITE][EPIC][15] = 6;
        SWPool[SUITE][EPIC][16] = 7;
        SWPool[SUITE][EPIC][17] = 8;
        SWPool[SUITE][EPIC][18] = 9;

        //BOT
        // SWPool[BOT][EPIC][0] = 0;
        // SWPool[BOT][EPIC][1] = 0;
        // SWPool[BOT][EPIC][2] = 0;
        // SWPool[BOT][EPIC][3] = 0;
        // SWPool[BOT][EPIC][4] = 0;
        // SWPool[BOT][EPIC][5] = 0;
        // SWPool[BOT][EPIC][6] = 0;
        // SWPool[BOT][EPIC][7] = 0;
        // SWPool[BOT][EPIC][8] = 0;
        // SWPool[BOT][EPIC][9] = 0;
        // SWPool[BOT][EPIC][10] = 0;
        // SWPool[BOT][EPIC][11] = 0;
        // SWPool[BOT][EPIC][12] = 0;
        // SWPool[BOT][EPIC][13] = 0;
        // SWPool[BOT][EPIC][14] = 0;
        // SWPool[BOT][EPIC][15] = 0;
        // SWPool[BOT][EPIC][16] = 0;
        // SWPool[BOT][EPIC][17] = 0;
        SWPool[BOT][EPIC][18] = 1;
        SWPool[BOT][EPIC][19] = 1;
        SWPool[BOT][EPIC][20] = 2;
        SWPool[BOT][EPIC][21] = 2;
        SWPool[BOT][EPIC][22] = 4;
        SWPool[BOT][EPIC][23] = 4;
        SWPool[BOT][EPIC][24] = 5;
        SWPool[BOT][EPIC][25] = 6;
        SWPool[BOT][EPIC][26] = 7;
        SWPool[BOT][EPIC][27] = 8;
        SWPool[BOT][EPIC][28] = 9;
        SWPool[BOT][EPIC][29] = 10;

        //GEN
        // SWPool[GEN][EPIC][0] = 0;
        // SWPool[GEN][EPIC][1] = 0;
        // SWPool[GEN][EPIC][2] = 0;
        SWPool[GEN][EPIC][3] = 1;
        SWPool[GEN][EPIC][4] = 1;
        SWPool[GEN][EPIC][5] = 1;
        SWPool[GEN][EPIC][6] = 2;
        SWPool[GEN][EPIC][7] = 2;
        SWPool[GEN][EPIC][8] = 2;
        SWPool[GEN][EPIC][9] = 3;
        SWPool[GEN][EPIC][10] = 3;
        SWPool[GEN][EPIC][11] = 3;
        SWPool[GEN][EPIC][12] = 4;
        SWPool[GEN][EPIC][13] = 4;
        SWPool[GEN][EPIC][14] = 4;
        SWPool[GEN][EPIC][15] = 5;
        SWPool[GEN][EPIC][16] = 5;
        SWPool[GEN][EPIC][17] = 6;
        SWPool[GEN][EPIC][18] = 6;
        SWPool[GEN][EPIC][19] = 7;
        SWPool[GEN][EPIC][20] = 8;
        SWPool[GEN][EPIC][21] = 9;
        SWPool[GEN][EPIC][22] = 10;
        SWPool[GEN][EPIC][23] = 11;
        SWPool[GEN][EPIC][24] = 12;
        SWPool[GEN][EPIC][25] = 13;
        SWPool[GEN][EPIC][26] = 14;
        SWPool[GEN][EPIC][27] = 15;
        SWPool[GEN][EPIC][28] = 16;

        //WEAP
        // SWPool[WEAP][RARE][0] = 0;
        // SWPool[WEAP][RARE][1] = 0;
        // SWPool[WEAP][RARE][2] = 0;
        // SWPool[WEAP][RARE][3] = 0;
        SWPool[WEAP][RARE][4] = 1;
        SWPool[WEAP][RARE][5] = 1;
        SWPool[WEAP][RARE][6] = 1;
        SWPool[WEAP][RARE][7] = 1;
        SWPool[WEAP][RARE][8] = 2;
        SWPool[WEAP][RARE][9] = 2;
        SWPool[WEAP][RARE][10] = 2;
        SWPool[WEAP][RARE][11] = 2;
        SWPool[WEAP][RARE][12] = 3;
        SWPool[WEAP][RARE][13] = 3;
        SWPool[WEAP][RARE][14] = 3;
        SWPool[WEAP][RARE][15] = 3;
        SWPool[WEAP][RARE][16] = 4;
        SWPool[WEAP][RARE][17] = 4;
        SWPool[WEAP][RARE][18] = 5;
        SWPool[WEAP][RARE][19] = 5;
        SWPool[WEAP][RARE][20] = 6;
        SWPool[WEAP][RARE][21] = 6;
        SWPool[WEAP][RARE][22] = 7;
        SWPool[WEAP][RARE][23] = 7;
        SWPool[WEAP][RARE][24] = 8;
        SWPool[WEAP][RARE][25] = 8;
        SWPool[WEAP][RARE][26] = 9;
        SWPool[WEAP][RARE][27] = 10;
        SWPool[WEAP][RARE][28] = 11;
        SWPool[WEAP][RARE][29] = 12;
        SWPool[WEAP][RARE][30] = 13;
        SWPool[WEAP][RARE][31] = 14;
    }

    function openBoxFromGalaxy(uint256 _nftType, uint256 _galaxy_id) public {
        ERC1155_CONTRACT _token;
        if (_nftType == 0) {
            _token = ERC1155_CONTRACT(GAX_CM);
        } else if (_nftType == 1) {
            _token = ERC1155_CONTRACT(GAX_RARE);
        } else if (_nftType == 2) {
            _token = ERC1155_CONTRACT(GAX_EPIC);
        }

        uint256 _balance = _token.balanceOf(msg.sender, _galaxy_id);
        require(_balance >= 1, "Your balance is insufficient.");
        burnAndMint(_token, _nftType, _galaxy_id);
    }

    function burnAndMint(
        ERC1155_CONTRACT _token,
        uint256 _nftType,
        uint256 _id
    ) internal {
        uint256 randomNumber = RANDOM_CONTRACT(RANDOM_WORKER_CONTRACT)
            .startRandom();
        ranNumToSender[randomNumber] = msg.sender;
        requestToNFTId[randomNumber] = _nftType;
        _token.burn(msg.sender, _id, 1);
        string memory partCode = createNFTCode(randomNumber, _nftType);
        mintNFT(randomNumber, partCode);
        emit OpenBox(msg.sender, _nftType, partCode);
    }

    function openBox(uint256 _id) public {
        ERC1155_CONTRACT _token = ERC1155_CONTRACT(MISTORY_BOX_CONTRACT);
        uint256 _balance = _token.balanceOf(msg.sender, _id);
        require(_balance >= 1, "Your balance is insufficient.");
        burnAndMint(_token, _id, _id);
    }

    function mintNFT(uint256 randomNumber, string memory concatedCode) private {
        ERC721_CONTRACT _nftCore = ERC721_CONTRACT(ECIO_NFT_CORE_CONTRACT);
        _nftCore.safeMint(ranNumToSender[randomNumber], concatedCode);
    }

    function createGenomic(
        uint256 _id,
        uint256 _nftTypeCode,
        uint256 _number,
        uint256 _rarity
    ) private view returns (string memory) {
        uint256 genomicType = GenPool[_id][_rarity][_number];
        return
            createPartCode(
                0,
                0, //combatRanksCode
                0, //WEAPCode
                genomicType, //humanGENCode
                0, //battleBotCode
                0, //battleSuiteCode
                0, //battleDROCode
                0, //battleGearCode
                0, //trainingCode
                0, //kingdomCode
                _nftTypeCode
            );
    }

    function createNFTCode(uint256 _ranNum, uint256 _id)
        internal
        view
        returns (string memory)
    {
        uint256 randomNFTType = ranNumWithMod(_ranNum, 1, 20);
        uint256 nftTypeCode = NFTPool[_id][randomNFTType];
        string memory partCode;
        uint256 eRandom = ranNumWithMod(_ranNum, 2, 5);
        uint256 eTypeId = EPool[eRandom];
        if (nftTypeCode == GENOMIC_COMMON) {
            uint256 number = ranNumWithMod(_ranNum, 2, 7);
            partCode = createGenomic(_id, nftTypeCode, number, COMMON);
        } else if (nftTypeCode == GENOMIC_RARE) {
            uint256 number = ranNumWithMod(_ranNum, 2, 6);
            partCode = createGenomic(_id, nftTypeCode, number, RARE);
        } else if (nftTypeCode == GENOMIC_EPIC) {
            uint256 number = ranNumWithMod(_ranNum, 2, 4);
            partCode = createGenomic(_id, nftTypeCode, number, EPIC);
        } else if (nftTypeCode == BLUEPRINT_COMM) {
            uint256 maxRan = maxRanForBluePrintCommon(_id, eTypeId);
            eRandom = ranNumWithMod(_ranNum, 2, maxRan);
            uint256 ePartId = BPPool[_id][COMMON][eTypeId][eRandom];
            partCode = createBlueprintPartCode(nftTypeCode, eTypeId, ePartId);
        } else if (nftTypeCode == BLUEPRINT_RARE) {
            uint256 maxRan = maxRanForBluePrintRare(_id, eTypeId);
            eRandom = ranNumWithMod(_ranNum, 2, maxRan);
            uint256 ePartId = BPPool[_id][RARE][eTypeId][eRandom];
            partCode = createBlueprintPartCode(nftTypeCode, eTypeId, ePartId);
        } else if (nftTypeCode == BLUEPRINT_EPIC) {
            uint256 maxRan = maxRanForBluePrintEpic(_id, eTypeId);
            eRandom = ranNumWithMod(_ranNum, 2, maxRan);
            uint256 ePartId = BPPool[_id][EPIC][eTypeId][eRandom];
            partCode = createBlueprintPartCode(nftTypeCode, eTypeId, ePartId);
        } else if (nftTypeCode == SPACE_WARRIOR) {
            partCode = createSW(_ranNum, _id);
        }

        return partCode;
    }

    function ranNumWithMod(
        uint256 _ranNum,
        uint256 digit,
        uint256 mod
    ) public view virtual returns (uint256) {
        if (digit == 1) {
            return (_ranNum % 100) % mod;
        } else if (digit == 2) {
            return ((_ranNum % 10000) / 100) % mod;
        } else if (digit == 3) {
            return ((_ranNum % 1000000) / 10000) % mod;
        } else if (digit == 4) {
            return ((_ranNum % 100000000) / 1000000) % mod;
        } else if (digit == 5) {
            return ((_ranNum % 10000000000) / 100000000) % mod;
        } else if (digit == 6) {
            return ((_ranNum % 1000000000000) / 10000000000) % mod;
        } else if (digit == 7) {
            return ((_ranNum % 100000000000000) / 1000000000000) % mod;
        } else if (digit == 8) {
            return ((_ranNum % 10000000000000000) / 100000000000000) % mod;
        }

        return 0;
    }

    function extactDigit(uint256 _ranNum) internal pure returns (Digit memory) {
        Digit memory digit;
        digit.digit1 = (_ranNum % 100);
        digit.digit2 = ((_ranNum % 10000) / 100);
        digit.digit3 = ((_ranNum % 1000000) / 10000);
        digit.digit4 = ((_ranNum % 100000000) / 1000000);
        digit.digit5 = ((_ranNum % 10000000000) / 100000000);
        digit.digit6 = ((_ranNum % 1000000000000) / 10000000000);
        digit.digit7 = ((_ranNum % 100000000000000) / 1000000000000);
        digit.digit8 = ((_ranNum % 10000000000000000) / 100000000000000);
        return digit;
    }

    function maxRanForBluePrintCommon(uint256 _id, uint256 eTypeId)
        private
        pure
        returns (uint256)
    {
        uint256 maxRan;
        if (_id == COMMON || _id == RARE) {
            if (eTypeId == SUITE) {
                maxRan = 3;
            } else {
                maxRan = 4;
            }
        } else if (_id == EPIC) {
            if (eTypeId == GEAR || eTypeId == DRO || eTypeId == BOT) {
                maxRan = 3;
            } else if (eTypeId == SUITE) {
                maxRan = 4;
            } else if (eTypeId == WEAP) {
                maxRan = 6;
            }
        }

        return maxRan;
    }

    function maxRanForBluePrintRare(uint256 _id, uint256 eTypeId)
        private
        pure
        returns (uint256)
    {
        uint256 maxRan;
        if (_id == COMMON) {
            if (eTypeId == WEAP) {
                maxRan = 4;
            } else {
                maxRan = 3;
            }
        } else if (_id == RARE) {
            if (eTypeId == WEAP) {
                maxRan = 5;
            } else {
                maxRan = 3;
            }
        } else if (_id == EPIC) {
            if (eTypeId == GEAR || eTypeId == DRO || eTypeId == BOT) {
                maxRan = 3;
            } else if (eTypeId == SUITE) {
                maxRan = 4;
            } else if (eTypeId == WEAP) {
                maxRan = 6;
            }
        }
        return maxRan;
    }

    function maxRanForBluePrintEpic(uint256 _id, uint256 eTypeId)
        private
        pure
        returns (uint256)
    {
        uint256 maxRan;
        if (_id == RARE || _id == EPIC) {
            if (eTypeId == GEAR || eTypeId == DRO || eTypeId == BOT) {
                maxRan = 3;
            } else if (eTypeId == SUITE) {
                maxRan = 4;
            } else if (eTypeId == WEAP) {
                maxRan = 6;
            }
        }
        return maxRan;
    }

    struct Digit {
        uint256 digit1;
        uint256 digit2;
        uint256 digit3;
        uint256 digit4;
        uint256 digit5;
        uint256 digit6;
        uint256 digit7;
        uint256 digit8;
    }

    function createSW(uint256 _random, uint256 _id)
        private
        view
        returns (string memory)
    {
        Digit memory d = extactDigit(_random);
        uint256 training;
        uint256 battleGear;
        uint256 battleDrone;
        uint256 battleSuite;
        uint256 battleBot;
        uint256 humanGEN;
        uint256 WEAPCode;

        training = d.digit2 % 5;
        battleGear = d.digit3 % 30;
        battleDrone = d.digit4 % 30;
        battleBot = d.digit6 % 30;
        if (_id == COMMON) {
            battleSuite = d.digit5 % 18;
            humanGEN = d.digit7 % 28;
            WEAPCode = d.digit8 % 29;
        } else if (_id == RARE) {
            battleSuite = d.digit5 % 17;
            humanGEN = d.digit7 % 25;
            WEAPCode = d.digit8 % 34;
        } else if (_id == EPIC) {
            battleSuite = d.digit5 % 19;
            humanGEN = d.digit7 % 29;
            WEAPCode = d.digit8 % 32;
        } 
        
        string memory concatedCode = convertCodeToStr(6);
        concatedCode = concateCode(concatedCode, 0); //kingdomCode
        concatedCode = concateCode(
            concatedCode,
            SWPool[TRANING_CAMP][_id][training]
        );
        concatedCode = concateCode(concatedCode, SWPool[GEAR][_id][battleGear]);
        concatedCode = concateCode(concatedCode, SWPool[DRO][_id][battleDrone]);
        concatedCode = concateCode(
            concatedCode,
            SWPool[SUITE][_id][battleSuite]
        );
        concatedCode = concateCode(concatedCode, SWPool[BOT][_id][battleBot]);
        concatedCode = concateCode(concatedCode, SWPool[GEN][_id][humanGEN]);
        concatedCode = concateCode(concatedCode, SWPool[WEAP][_id][WEAPCode]);
        concatedCode = concateCode(concatedCode, 0); //Star
        concatedCode = concateCode(concatedCode, 0); //equipmentCode
        concatedCode = concateCode(concatedCode, 0); //Reserved
        concatedCode = concateCode(concatedCode, 0); //Reserved
        return concatedCode;
    }

    function createBlueprintPartCode(
        uint256 nftTypeCode,
        uint256 equipmentTypeId,
        uint256 equipmentPartId
    ) private pure returns (string memory) {
        string memory partCode;

        if (equipmentTypeId == GEAR) {
            //Battle Gear
            partCode = createPartCode(
                equipmentTypeId, //equipmentTypeId
                0, //combatRanksCode
                0, //WEAPCode
                0, //humanGENCode
                0, //battleBotCode
                0, //battleSuiteCode
                0, //battleDROCode
                equipmentPartId, //battleGearCode
                0, //trainingCode
                0, //kingdomCode
                nftTypeCode
            );
        } else if (equipmentTypeId == DRO) {
            //battleDROCode
            partCode = createPartCode(
                equipmentTypeId, //equipmentTypeId
                0, //combatRanksCode
                0, //WEAPCode
                0, //humanGENCode
                0, //battleBotCode
                0, //battleSuiteCode
                equipmentPartId, //battleDROCode
                0, //battleGearCode
                0, //trainingCode
                0, //kingdomCode
                nftTypeCode
            );
        } else if (equipmentTypeId == SUITE) {
            //battleSuiteCode
            partCode = createPartCode(
                equipmentTypeId, //equipmentTypeId
                0, //combatRanksCode
                0, //WEAPCode
                0, //humanGENCode
                0, //battleBotCode
                equipmentPartId, //battleSuiteCode
                0, //battleDROCode
                0, //battleGearCode
                0, //trainingCode
                0, //kingdomCode
                nftTypeCode
            );
        } else if (equipmentTypeId == BOT) {
            //Battle Bot
            partCode = createPartCode(
                equipmentTypeId, //equipmentTypeId
                0, //combatRanksCode
                0, //WEAPCode
                0, //humanGENCode
                equipmentPartId, //battleBotCode
                0, //battleSuiteCode
                0, //battleDROCode
                0, //battleGearCode
                0, //trainingCode
                0, //kingdomCode
                nftTypeCode
            );
        } else if (equipmentTypeId == WEAP) {
            //WEAP
            partCode = createPartCode(
                equipmentTypeId, //equipmentTypeId
                0, //combatRanksCode
                equipmentPartId, //WEAPCode
                0, //humanGENCode
                0, //battleBotCode
                0, //battleSuiteCode
                0, //battleDROCode
                0, //battleGearCode
                0, //trainingCode
                0, //kingdomCode
                nftTypeCode
            );
        }

        return partCode;
    }

    function createPartCode(
        uint256 equipmentCode,
        uint256 starCode,
        uint256 weapCode,
        uint256 humanGENCode,
        uint256 battleBotCode,
        uint256 battleSuiteCode,
        uint256 battleDROCode,
        uint256 battleGearCode,
        uint256 trainingCode,
        uint256 kingdomCode,
        uint256 nftTypeCode
    ) internal pure returns (string memory) {
        string memory code = convertCodeToStr(nftTypeCode);
        code = concateCode(code, kingdomCode);
        code = concateCode(code, trainingCode);
        code = concateCode(code, battleGearCode);
        code = concateCode(code, battleDROCode);
        code = concateCode(code, battleSuiteCode);
        code = concateCode(code, battleBotCode);
        code = concateCode(code, humanGENCode);
        code = concateCode(code, weapCode);
        code = concateCode(code, starCode);
        code = concateCode(code, equipmentCode); //Reserved
        code = concateCode(code, 0); //Reserved
        code = concateCode(code, 0); //Reserved
        return code;
    }

    function concateCode(string memory concatedCode, uint256 digit)
        internal
        pure
        returns (string memory)
    {
        concatedCode = string(
            abi.encodePacked(convertCodeToStr(digit), concatedCode)
        );

        return concatedCode;
    }

    function convertCodeToStr(uint256 code)
        private
        pure
        returns (string memory)
    {
        if (code <= 9) {
            return string(abi.encodePacked("0", Strings.toString(code)));
        }

        return Strings.toString(code);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}