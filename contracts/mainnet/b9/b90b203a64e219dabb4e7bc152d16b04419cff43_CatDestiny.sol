pragma solidity ^0.4.22;

contract Destiny {
    function fight(bytes32 cat1, bytes32 cat2, bytes32 entropy) public returns (bytes32 winner);
}

contract CatDestiny is Destiny {
    uint8 private constant type_life = 0;
    uint8 private constant type_attack = 1;
    uint8 private constant type_defense = 2;

    uint8 private constant gen_body = 0;
    uint8 private constant gen_pattern = 4;
    uint8 private constant gen_eye_color = 8;
    uint8 private constant gen_body_color = 16;
    uint8 private constant gen_color = 24;
    uint8 private constant gen_wild = 28;
    uint8 private constant gen_mouth = 32;

    struct Weight {
        uint8 attack;
        uint8 defense;
        uint8 life;
    }

    mapping (uint8 => Weight[32]) private matrix;
    
    function fight(bytes32 cat1, bytes32 cat2, bytes32 seed) public returns (bytes32 winner) {
        int256 life1 = getLife(cat1);
        int256 life2 = getLife(cat2);

        int256 attack1 = getAttack(cat1, seed, 1) * getMult(cat1, seed, 2);
        int256 attack2 = getAttack(cat2, seed, 3) * getMult(cat2, seed, 4);

        int256 defense1 = getDefense(cat1, seed, 5);
        int256 defense2 = getDefense(cat2, seed, 6);
        
        life1 -= (attack2 - (defense1 * 3) / 2);
        life2 -= (attack1 - (defense2 * 3) / 2);
        
        if (life1 < life2) {
            winner = cat2;
        } else if (life2 < life1) {
            winner = cat1;
        } else {
            winner = bytes32(0);
        }
    }
    
    function readValue(bytes32 dna, uint8 att) internal view returns (Weight w) {
        uint8 k = gen(dna, att);
        w = matrix[att][k];
        
        if (w.attack == 0 && w.defense == 0 && w.life == 0) {
            w = Weight({
                attack: uint8(keccak256(k, att)),
                defense: uint8(keccak256(k, att)),
                life: uint8(keccak256(k, att))
            });
        }
    }
    
    function gen(bytes32 dna, uint256 p) private pure returns (uint8) {
        return uint8(bytes1((dna << (248 - (p * 5)))) & 0x1f);
    }
    
    function CatDestinity() public {
        // Load body data
        matrix[0][18] = Weight({attack:233,defense:0,life:240}); //highlander 247
        matrix[0][4] = Weight({attack:211,defense:0,life:205}); //koladiviya 1109
        matrix[0][21] = Weight({attack:188,defense:0,life:190}); //mainecoon 4829
        matrix[0][16] = Weight({attack:170,defense:0,life:206}); //norwegianforest 4990
        matrix[0][27] = Weight({attack:220,defense:0,life:170}); //manx 5991
        matrix[0][23] = Weight({attack:245,defense:0,life:150}); //persian 10662
        matrix[0][7] = Weight({attack:135,defense:0,life:210}); //pixiebob 11551
        matrix[0][0] = Weight({attack:130,defense:0,life:200}); //savannah 12849
        matrix[0][10] = Weight({attack:150,defense:0,life:180}); //chartreux 16624
        matrix[0][5] = Weight({attack:145,defense:0,life:180}); //bobtail 33518
        matrix[0][3] = Weight({attack:145,defense:0,life:180}); //birman 34603
        matrix[0][1] = Weight({attack:130,defense:0,life:150}); //selkirk 39693
        matrix[0][22] = Weight({attack:128,defense:0,life:149}); //laperm 40633
        matrix[0][15] = Weight({attack:135,defense:0,life:110}); //ragdoll 74468
        matrix[0][9] = Weight({attack:130,defense:0,life:110}); //cymric 76012
        matrix[0][14] = Weight({attack:100,defense:0,life:100}); //ragamuffin 85938
        matrix[0][11] = Weight({attack:190,defense:0,life:30}); //himalayan 91315
        matrix[0][13] = Weight({attack:180,defense:0,life:50}); //sphynx 97994
        matrix[0][12] = Weight({attack:90,defense:0,life:120}); //munchkin 98141
        // Load pattern data
        matrix[4][25] = Weight({attack:250,defense:200,life:0}); // razzledazzle 25
        matrix[4][19] = Weight({attack:2,defense:255,life:0}); // highsociety 71
        matrix[4][6] = Weight({attack:200,defense:201,life:0}); // rorschach 78
        matrix[4][18] = Weight({attack:180,defense:190,life:0}); // dippedcone 2414
        matrix[4][17] = Weight({attack:240,defense:100,life:0}); // thunderstruck 2538
        matrix[4][26] = Weight({attack:190,defense:180,life:0}); // hotrod 5061
        matrix[4][5] = Weight({attack:90,defense:255,life:0}); // camo 5417
        matrix[4][2] = Weight({attack:140,defense:141,life:0}); // rascal 9834
        matrix[4][21] = Weight({attack:200,defense:40,life:0}); // henna 12322
        matrix[4][3] = Weight({attack:150,defense:150,life:0}); // ganado 12625
        matrix[4][4] = Weight({attack:230,defense:20,life:0}); // leopard 17016
        matrix[4][11] = Weight({attack:128,defense:150,life:0}); // jaguar 23457
        matrix[4][20] = Weight({attack:120,defense:120,life:0}); // tigerpunk 24011
        matrix[4][1] = Weight({attack:200,defense:23,life:0}); // tiger 30727
        matrix[4][7] = Weight({attack:140,defense:170,life:0}); // spangled 31850
        matrix[4][8] = Weight({attack:150,defense:160,life:0}); // calicool 42080
        matrix[4][10] = Weight({attack:130,defense:140,life:0}); // amur 67930
        matrix[4][12] = Weight({attack:5,defense:100,life:0}); // spock 74454
        matrix[4][9] = Weight({attack:90,defense:99,life:0}); // luckystripe 139732
        // Load eye color data
        matrix[8][7] = Weight({attack:1,defense:0,life:0}); // strawberry 122951
        matrix[8][5] = Weight({attack:20,defense:0,life:0}); // sizzurp 107360
        matrix[8][3] = Weight({attack:24,defense:0,life:0}); // mintgreen 106378
        matrix[8][2] = Weight({attack:40,defense:0,life:0}); // topaz 91993
        matrix[8][1] = Weight({attack:44,defense:0,life:0}); // gold 76929
        matrix[8][6] = Weight({attack:54,defense:0,life:0}); // chestnut 55495
        matrix[8][8] = Weight({attack:60,defense:0,life:0}); // sapphire 34341
        matrix[8][17] = Weight({attack:77,defense:0,life:0}); // limegreen 31774
        matrix[8][0] = Weight({attack:40,defense:0,life:0}); // thundergrey 31120
        matrix[8][11] = Weight({attack:80,defense:0,life:0}); // coralsunrise 29528
        matrix[8][19] = Weight({attack:40,defense:0,life:0}); // bubblegum 17656
        matrix[8][15] = Weight({attack:90,defense:0,life:0}); // cyan 17560
        matrix[8][9] = Weight({attack:100,defense:0,life:0}); // forgetmenot 5796
        matrix[8][14] = Weight({attack:120,defense:0,life:0}); // parakeet 3423
        matrix[8][16] = Weight({attack:80,defense:0,life:0}); // pumpkin 3357
        matrix[8][13] = Weight({attack:231,defense:0,life:0}); // doridnudibranch 2381
        matrix[8][20] = Weight({attack:233,defense:0,life:0}); // twilightsparkle 1554
        matrix[8][24] = Weight({attack:240,defense:0,life:0}); // babypuke 730
        matrix[8][23] = Weight({attack:240,defense:0,life:0}); // eclipse 725
        // Load body color data
        matrix[16][20] = Weight({attack:0,defense:170,life:0}); // lavender 201
        matrix[16][23] = Weight({attack:0,defense:150,life:0}); // verdigris 1832
        matrix[16][19] = Weight({attack:0,defense:122,life:0}); // koala 2247
        matrix[16][13] = Weight({attack:0,defense:150,life:0}); // dragonfruit 2363
        matrix[16][9] = Weight({attack:0,defense:122,life:0}); // cinderella 3186
        matrix[16][8] = Weight({attack:0,defense:99,life:0}); // harbourfog 5688
        matrix[16][14] = Weight({attack:0,defense:12,life:0}); // hintomint 6400
        matrix[16][7] = Weight({attack:0,defense:2,life:0}); // nachocheez 6551
        matrix[16][25] = Weight({attack:0,defense:200,life:0}); // onyx 8225
        matrix[16][18] = Weight({attack:0,defense:55,life:0}); // oldlace 22288
        matrix[16][15] = Weight({attack:0,defense:8,life:0}); // bananacream 36400
        matrix[16][16] = Weight({attack:0,defense:36,life:0}); // cloudwhite 43802
        matrix[16][1] = Weight({attack:0,defense:20,life:0}); // salmon 75223
        matrix[16][4] = Weight({attack:0,defense:20,life:0}); // cottoncandy 78501
        matrix[16][3] = Weight({attack:0,defense:90,life:0}); // orangesoda 79759
        matrix[16][6] = Weight({attack:0,defense:24,life:0}); // aquamarine 82860
        matrix[16][5] = Weight({attack:0,defense:33,life:0}); // mauveover 90339
        matrix[16][0] = Weight({attack:0,defense:20,life:0}); // shadowgrey 91623
        matrix[16][10] = Weight({attack:0,defense:10,life:0}); // greymatter 103658
        // Load color data
        matrix[24][27] = Weight({attack:0,defense:230,life:0}); // mintmacaron 396
        matrix[24][9] = Weight({attack:0,defense:200,life:0}); // shale 787
        matrix[24][17] = Weight({attack:0,defense:190,life:0}); // flamingo 1375
        matrix[24][23] = Weight({attack:0,defense:220,life:0}); // patrickstarfish 1504
        matrix[24][24] = Weight({attack:0,defense:140,life:0}); // seafoam 1927
        matrix[24][13] = Weight({attack:0,defense:160,life:0}); // missmuffett 2647
        matrix[24][22] = Weight({attack:0,defense:177,life:0}); // periwinkle 2896
        matrix[24][15] = Weight({attack:0,defense:201,life:0}); // frosting 7060
        matrix[24][16] = Weight({attack:0,defense:90,life:0}); // daffodil 7438
        matrix[24][14] = Weight({attack:0,defense:122,life:0}); // morningglory 26296
        matrix[24][2] = Weight({attack:0,defense:66,life:0}); // peach 27774
        matrix[24][10] = Weight({attack:0,defense:23,life:0}); // purplehaze 29443
        matrix[24][0] = Weight({attack:0,defense:99,life:0}); // belleblue 30752
        matrix[24][3] = Weight({attack:0,defense:190,life:0}); // icy 34298
        matrix[24][12] = Weight({attack:0,defense:9,life:0}); // azaleablush 34622
        matrix[24][19] = Weight({attack:0,defense:60,life:0}); // bloodred 36960
        matrix[24][1] = Weight({attack:0,defense:30,life:0}); // sandalwood 49768
        matrix[24][7] = Weight({attack:0,defense:10,life:0}); // emeraldgreen 61141
        matrix[24][6] = Weight({attack:0,defense:50,life:0}); // kittencream 186366
        matrix[24][4] = Weight({attack:0,defense:44,life:0}); // granitegrey 197635
        // Load wild data
        matrix[28][17] = Weight({attack:250,defense:200,life:0}); // elk 7036
        matrix[28][19] = Weight({attack:200,defense:250,life:0}); // trioculus 1566
        matrix[28][20] = Weight({attack:240,defense:255,life:0}); // daemonwings 1286
        matrix[28][23] = Weight({attack:245,defense:255,life:0}); // daemonhorns 711
        // Load mouth data
        matrix[32][9] = Weight({attack:10,defense:0,life:0}); // pouty 137345
        matrix[32][14] = Weight({attack:40,defense:0,life:0}); // happygokitty 123608
        matrix[32][15] = Weight({attack:150,defense:0,life:0}); // soserious 105209
        matrix[32][10] = Weight({attack:40,defense:0,life:0}); // saycheese 97689
        matrix[32][8] = Weight({attack:20,defense:0,life:0}); // beard 43754
        matrix[32][3] = Weight({attack:90,defense:0,life:0}); // gerbil 42150
        matrix[32][23] = Weight({attack:110,defense:0,life:0}); // tongue 41916
        matrix[32][0] = Weight({attack:122,defense:0,life:0}); // whixtensions 40268
        matrix[32][11] = Weight({attack:155,defense:0,life:0}); // grim 37027
        matrix[32][2] = Weight({attack:150,defense:0,life:0}); // wuvme 33604
        matrix[32][20] = Weight({attack:194,defense:0,life:0}); // dali 18700
        matrix[32][17] = Weight({attack:209,defense:0,life:0}); // starstruck 4636
        matrix[32][21] = Weight({attack:210,defense:0,life:0}); // grimace 3183
        matrix[32][1] = Weight({attack:99,defense:0,life:0}); // wasntme 3006
        matrix[32][16] = Weight({attack:150,defense:0,life:0}); // cheeky 2688
        matrix[32][24] = Weight({attack:225,defense:0,life:0}); // yokel 2069
        matrix[32][6] = Weight({attack:230,defense:0,life:0}); // belch 1993
        matrix[32][26] = Weight({attack:250,defense:0,life:0}); // neckbeard 1905
        matrix[32][7] = Weight({attack:240,defense:0,life:0}); // rollercoaster 201
        matrix[32][19] = Weight({attack:255,defense:0,life:0}); // ruhroh 62
    }
    
    function urandom(bytes32 seed, uint256 nonce) private returns (bytes32) {
        return keccak256(uint256(seed) + nonce);
    }

    function getLife(bytes32 cat) private returns (int256 life) {
        life = readValue(cat, gen_body).life * 4;
    }
    
    function getDefense(bytes32 cat, bytes32 seed, uint256 nonce) private returns (int256 defense) {
        defense += readValue(cat, gen_pattern).defense;
        defense += readValue(cat, gen_body_color).defense;
        defense += readValue(cat, gen_color).defense;
        defense += readValue(cat, gen_wild).defense;
        defense += uint8(urandom(seed, nonce)) / 2;
    }
    
    function getAttack(bytes32 cat, bytes32 seed, uint256 nonce) private returns (int256 attack) {
        attack += readValue(cat, gen_body).attack;
        attack += readValue(cat, gen_eye_color).attack;
        attack += readValue(cat, gen_pattern).attack;
        attack += readValue(cat, gen_wild).attack;
        attack += readValue(cat, gen_mouth).attack;
        attack += uint8(urandom(seed, nonce)) / 2;
    }
    
    function getMult(bytes32 cat, bytes32 seed, uint256 nonce) internal view returns (int256) {
        return (uint8(urandom(seed, nonce)) == uint8(keccak256(cat))) ? 2 : 1;
    }
}