// SPDX-License-Identifier: AGPL-3.0-only

/*
*  \_\_     _/_/
*      \___/
*     ~(0 0)~
* ____/(._.)
*       /
* ___  /
*    ||
*    ||
* 
*/

pragma solidity 0.8.9;
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ISpriteRouter {
    function getSprite(uint8 partId, uint8 typeId, uint8 spriteId) external view returns (string memory);
}

contract DearDeer is ERC721Enumerable {

    mapping(uint => bool) DNAMinted;
    mapping(uint => uint) DeerDNA;

    uint public MINT_PRICE = 0.05 ether;
    uint public MAX_SUPPLY = 5000;

    uint public MAX_MINT_PER_WALLET = 5;
    uint public MAX_MINT_PER_TX = 5;

    uint PRNG_ENT = 27;

    bool public MINT_IS_ON;
    bool public MINT_IS_PUBLIC;
    bool public REVEALED;

    bytes32 merkleRoot;

    address public owner;
    address public dao;

    uint16[][46] WEIGHTS;

    string[] GENDER           = ["Male", "Female"];
    string[] FUR              = ["Beastie", "Brown", "Elfie", "Frosty", "Ghost", "Golden", "Grey", "Pink", "Dr. Quantum"];
    string[] HAIR_COLOR       = ["Black", "Blonde", "Brown", "Bubblegum", "Night", "Purple", "Red", "Shameless", "Sh\xC5\x8Dsa", "Swampy", "White"];
    string[] HAIR_STYLE       = ["Average Dystopian Choice", "Elizabeth Theorem", "My Beloved", "Nuke 'Em", "Ouch", "Simply Free", "Spiky Originality", "Straight Grace", "Straight Grace With Curl", "The Princess", "Two Hot Buns", "Wine Consequence"];
    string[] FRECKLES         = ["Yes", "No"];
    string[] EYES             = ["Beyond Your Glasses", "Donate Me", "Hasta la Vista Baby", "I'm Tired", "Jazz", "Lively", "Lookers", "Midnight Movie", "Mildly Lovable", "Nuke Protectors", "Our Mutual Friend", "Pass the Boof", "Rectangular", "Red Menace", "Seduction", "Tired of Being Beautiful", "Unforgettable Moment"];
    string[] BROWS            = ["A Little Nervous", "Are They Drawn", "Be Gentle", "Be Harsh", "Big One", "Just Looking", "Seriously"];
    string[] BEARD            = ["A Brick of Hair", "Czar", "Hobo", "No Match", "Stasis", "Time Traveler", "None"];
    string[] MOUTH            = ["A Bit Happy", "Big Smile", "Confused", "Doomer", "Froggy", "No Mercy", "Not Too Pathetic", "Sheep Ancestors", "Smug", "Stunned", "Subscribe to My OnlyDeers", "Sweet Tooth"];
    string[] EARS             = ["Floppers", "I'm All Ears", "Little Cutie", "Mildly Cuter"];
    string[] EARRINGS         = ["Cheap Diamonds", "Praise ETH", "Thunderstorm", "Triple Pierce", "None"];
    string[] NOSE             = ["Bridged", "Cute-N-Small", "Flat Pierced", "Northern Hint", "Nosey", "Santa's Helper", "Second Heart", "Silver for Deers"];
    string[] ANTLERS          = ["Brave One", "Devil Within", "Hard Fought", "Lovable", "Pointers", "Shroom Blue", "Shroom Noisy", "Shroom Red", "Sigma", "Spy Among Us"];
    string[] ANTLER_ACCESSORY = ["4 Star Hotel", "That'll Do", "Desperate", "Afterparty", "Antennas", "Occasional Forager", "Plastic World", "None"];
    string[] CLOTHES          = ["A Link", "Apples", "Cheapest Choice", "Deers in Black", "Easy to Stain", "Favourite Servant", "Fountain Lover", "Heavy Suit", "I Live For This Shit", "Junkie", "Nuke Pack", "Ode to the Carpet", "Opened Up", "Smells Like Teen Spirit", "Spider Silk", "Surprise!", "Teufort Classic", "Too Tight for Space", "Upper Gift", "What Sweet Dreams Are Made Of", "Worker", "Young Producer", "Naked"];  // He-he naked
    string[] BACKGROUND       = ["Blue", "Dark Blue", "Green", "Lime", "Pink", "Red", "Violet", "Yellow"];

    string SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" id="deer">';
    string SVG_FOOTER = '<style>#deer {image-rendering: pixelated; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';
    string SVG_IMAGE_TAG = '<image width="100%" height="100%" href="data:image/png;base64,';

    string description = 'Dear Deer is a collection of hardcore onchain pixel art PFPs. Each deer is generated at the time of mint. No IPFS, no API, both metadata and graphics are stored on Ethereum forever.';

    ISpriteRouter spriteRouter;

    constructor() ERC721("Dear Deer", "DEER") {
        owner = msg.sender;

        WEIGHTS[0] = [5000, 5000];                                                          // gender
        WEIGHTS[1] = [300, 2500, 400, 400, 300, 1500, 3000, 1500, 100];                     // fur_m
        WEIGHTS[2] = [300, 3000, 400, 400, 300, 1500, 2500, 1500, 100];                     // fur_f
        WEIGHTS[3] = [1200, 3000, 3000, 100, 500, 500, 500, 500, 100, 500, 100];            // hair_color_m
        WEIGHTS[4] = [1100, 3000, 2000, 400, 800, 800, 800, 500, 200, 200, 200];            // hair_color_f
        WEIGHTS[5] = [2000, 0, 0, 1000, 2000, 2300, 2700, 0, 0, 0, 0, 0];                   // hair_style_m
        WEIGHTS[6] = [1200, 1300, 1300, 0, 200, 0, 800, 1100, 800, 1100, 1100, 1100];       // hair_style_f
        WEIGHTS[7] = [1000, 9000];                                                          // freckles_m
        WEIGHTS[8] = [5000, 5000];                                                          // freckles_f
        
        // eyes_m
        WEIGHTS[9] = [900, 0, 10, 1100, 300, 1800, 1000, 100, 0, 1000, 1000, 500, 1890, 200, 0, 200, 0];
        // eyes_f
        WEIGHTS[10] = [1200, 1000, 0, 100, 200, 1000, 1200, 100, 1500, 100, 700, 100, 100, 100, 1400, 700, 500];

        WEIGHTS[11] = [1000, 1000, 1000, 2000, 2000, 1500, 1500];                           // brows_m
        WEIGHTS[12] = [1500, 1000, 2000, 1000, 1000, 1500, 2000];                           // brows_f
        WEIGHTS[13] = [1000, 500, 700, 400, 1400, 1000, 5000];                              // beard_m
        WEIGHTS[14] = [0, 0, 0, 0, 0, 0, 10000];                                            // beard_f
        WEIGHTS[15] = [2000, 0, 1300, 0, 0, 0, 6700];                                       // beard_confused
        WEIGHTS[16] = [2000, 0, 1300, 0, 0, 0, 6700];                                       // beard_doomer
        WEIGHTS[17] = [2000, 0, 1300, 0, 0, 0, 6700];                                       // beard_froggy
        WEIGHTS[18] = [1100, 500, 900, 100, 0, 1000, 6400];                                 // beard_not_too_pathetic
        WEIGHTS[19] = [1100, 200, 800, 0, 0, 1000, 6900];                                   // beard_smug
        WEIGHTS[20] = [1200, 200, 1200, 400, 0, 100, 6900];                                 // beard_sweet_tooth
        WEIGHTS[21] = [1200, 1000, 900, 800, 1000, 1000, 700, 600, 700, 1500, 100, 500];    // mouth_m
        WEIGHTS[22] = [1000, 1500, 800, 300, 600, 200, 1000, 800, 900, 1200, 500, 1200];    // mouth_f
        WEIGHTS[23] = [3000, 3000, 2000, 2000];                                             // ears_m
        WEIGHTS[24] = [2000, 2000, 3000, 3000];                                             // ears_f
        WEIGHTS[25] = [0, 10, 0, 900, 9090];                                                // earrings_m
        WEIGHTS[26] = [1300, 200, 1100, 1400, 6000];                                        // earrings_f
        WEIGHTS[27] = [500, 2000, 500, 1000, 4000, 500, 1000, 500];                         // nose_m
        WEIGHTS[28] = [500, 2000, 500, 1000, 4000, 500, 1000, 500];                         // nose_f
        WEIGHTS[29] = [0, 2300, 600, 800, 4000, 600, 1100, 600];                            // nose_bridged
        WEIGHTS[30] = [2500, 1100, 2000, 800, 2100, 75, 50, 150, 1025, 200];                // antlers_m
        WEIGHTS[31] = [2250, 1050, 1650, 2000, 1650, 75, 50, 150, 925, 200];                // antlers_f
        WEIGHTS[32] = [400, 1000, 0, 0, 0, 0, 0, 8600];                                     // antler_accessory_brave_one_m
        WEIGHTS[33] = [300, 500, 0, 0, 0, 0, 0, 9200];                                      // antler_accessory_brave_one_f
        WEIGHTS[34] = [0, 0, 500, 0, 0, 0, 0, 9500];                                        // antler_accessory_hard_fought_m
        WEIGHTS[35] = [0, 0, 100, 0, 0, 0, 0, 9900];                                        // antler_accessory_hard_fought_f
        WEIGHTS[36] = [0, 0, 0, 200, 200, 0, 0, 9600];                                      // antler_accessory_lovable_m
        WEIGHTS[37] = [0, 0, 0, 400, 400, 0, 0, 9200];                                      // antler_accessory_lovable_f
        WEIGHTS[38] = [0, 0, 0, 0, 0, 300, 100, 9600];                                      // antler_accessory_pointers_m
        WEIGHTS[39] = [0, 0, 0, 0, 0, 500, 100, 9400];                                      // antler_accessory_pointers_f

        // clothes_m
        WEIGHTS[40] = [700, 0, 1600, 400, 400, 0, 300, 100, 500, 800, 100, 100, 1100, 300, 0, 0, 200, 0, 0, 100, 1400, 1000, 900];
        // clothes_f
        WEIGHTS[41] = [700, 400, 1400, 400, 400, 200, 0, 0, 500, 800, 0, 0, 700, 300, 300, 300, 200, 200, 400, 100, 1400, 1100, 200];

        WEIGHTS[42] = [1250, 1250, 1250, 1250, 1250, 1250, 1250, 1250];                     // background
        WEIGHTS[43] = [1700, 1700, 1700, 1700, 0, 0, 1500, 1700];                           // background_bubblegum
        WEIGHTS[44] = [1450, 1500, 1450, 1400, 1400, 1400, 1400, 0];                        // background_blonde
        WEIGHTS[45] = [1450, 0, 1450, 1400, 1400, 1450, 1450, 1400];                        // background_white

        devMint();
    }


    // MINT FUNCTIONS

    function whiteListMint(uint deer_num, bytes32[] calldata merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not whitelisted");

        require(MINT_IS_ON, "Mint is off");
        require(deer_num <= MAX_MINT_PER_TX, "Mint per tx cap");
        require(balanceOf(msg.sender) + deer_num <= MAX_MINT_PER_WALLET, "Mint per wallet cap");
        require(totalSupply() + deer_num <= MAX_SUPPLY, "Supply cap");
        require(MINT_PRICE * deer_num <= msg.value, "Not enough ETH");
        require(!isContract(msg.sender));

        for (uint i = 0; i < deer_num; i++) {
            mintDeer();
        }
    }

    function mint(uint deer_num) external payable {
        require(MINT_IS_ON, "Mint is off");
        require(MINT_IS_PUBLIC, "Public mint not started");
        require(deer_num <= MAX_MINT_PER_TX, "Mint per tx cap");
        require(balanceOf(msg.sender) + deer_num <= MAX_MINT_PER_WALLET, "Mint per wallet cap");
        require(totalSupply() + deer_num <= MAX_SUPPLY, "Supply cap");
        require(MINT_PRICE * deer_num <= msg.value, "Not enough ETH");
        require(!isContract(msg.sender));

        for (uint i = 0; i < deer_num; i++) {
            mintDeer();
        }
    }

    function devMint() internal {
        for (uint i = 0; i < 100; i++) {
            mintDeer();
        }
    }

    function mintDeer() internal {
        uint tokenId = totalSupply();
        uint DNA = generateDNA(tokenId);
        DeerDNA[tokenId] = DNA;
        DNAMinted[DNA] = true;

        _mint(msg.sender, tokenId);
    }

    function generateDNA(uint tokenId) internal returns (uint) {
        PRNG_ENT++; 
        uint DNA = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tokenId, PRNG_ENT)));
        if (DNAMinted[DNA]) return generateDNA(tokenId);
        return DNA;
    }


    // VIEW FUNCTIONS

    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!REVEALED) {
            return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"description": "',
                                description,
                                '",',
                                '"image": "ipfs://bafybeifywnwas6zc3nim6eil76kkdgvfpctkr6ngy7sjiogj7losr4kdya/"}'   // the only use of IPFS is this temp placeholder gif before reveal
                            )
                        )
                    )
                )
            );
        }

        uint8[16] memory deer = getDeer(tokenId);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Dear Deer #',
                            uintToString(tokenId),
                            '",',
                            '"description": "',
                            description,
                            '",',
                            '"image": "',
                            renderImage(deer),
                            '",',
                            formatTraits(deer),
                            '}'
                        )
                    )
                )
            )
        );
    }

    function getDeer(uint tokenId) public view returns (uint8[16] memory) {
        uint16[16] memory genes = sequenceDNA(DeerDNA[tokenId]);
        uint8[16] memory deer;

        // 0 gender
        // 1 fur
        // 2 hair_color
        // 3 hair_style
        // 4 freckles
        // 5 eyes
        // 6 brows
        // 7 beard
        // 8 mouth
        // 9 ears
        // 10 earrings
        // 11 nose
        // 12 antlers
        // 13 antler_accessory
        // 14 clothes
        // 15 background

        deer[0] = wrand(genes[0], 0);

        if (deer[0] == 0) {

            deer[1] = wrand(genes[1], 1);
            deer[2] = wrand(genes[2], 3);
            deer[3] = wrand(genes[3], 5);
            deer[4] = wrand(genes[4], 7);
            deer[5] = wrand(genes[5], 9);
            deer[6] = wrand(genes[6], 11);

            deer[8] = wrand(genes[8], 21);
            if (deer[8] == 2) {
                deer[7] = wrand(genes[7], 15);
            } else if (deer[8] == 3) {
                deer[7] = wrand(genes[7], 16);
            } else if (deer[8] == 4) {
                deer[7] = wrand(genes[7], 17);
            } else if (deer[8] == 6) {
                deer[7] = wrand(genes[7], 18);
            } else if (deer[8] == 8) {
                deer[7] = wrand(genes[7], 19);
            } else if (deer[8] == 11) {
                deer[7] = wrand(genes[7], 20);
            } else {
                deer[7] = wrand(genes[7], 13);
            }

            deer[9] = wrand(genes[9], 23);
            deer[10] = wrand(genes[10], 25);

            if (deer[5] == 0 || deer[5] == 4 || deer[5] == 7 || deer[5] == 9 || deer[5] == 10 || deer[5] == 13) {
                deer[11] = wrand(genes[11], 29);
            } else {
                deer[11] = wrand(genes[11], 27);
            }

            deer[12] = wrand(genes[12], 30);

            if (deer[12] == 0) {
                deer[13] = wrand(genes[13], 32);
            } else if (deer[12] == 2) {
                deer[13] = wrand(genes[13], 34);
            } else if (deer[12] == 3) {
                deer[13] = wrand(genes[13], 36);
            } else if (deer[12] == 4) {
                deer[13] = wrand(genes[13], 38);
            } else {
                deer[13] = 7;
            }

            deer[14] = wrand(genes[14], 40);

        } else {
            deer[1] = wrand(genes[1], 2);
            deer[2] = wrand(genes[2], 4);
            deer[3] = wrand(genes[3], 6);
            deer[4] = wrand(genes[4], 8);
            deer[5] = wrand(genes[5], 10);
            deer[6] = wrand(genes[6], 12);
            deer[7] = wrand(genes[7], 14);
            deer[8] = wrand(genes[8], 22);
            deer[9] = wrand(genes[9], 24);
            deer[10] = wrand(genes[10], 26);
            
            if (deer[5] == 0 || deer[5] == 4 || deer[5] == 7 || deer[5] == 9 || deer[5] == 10 || deer[5] == 13) {
                deer[11] = wrand(genes[11], 29);
            } else {
                deer[11] = wrand(genes[11], 28);
            }

            deer[12] = wrand(genes[12], 31);

            if (deer[12] == 0) {
                deer[13] = wrand(genes[13], 33);
            } else if (deer[12] == 2) {
                deer[13] = wrand(genes[13], 35);
            } else if (deer[12] == 3) {
                deer[13] = wrand(genes[13], 37);
            } else if (deer[12] == 4) {
                deer[13] = wrand(genes[13], 39);
            } else {
                deer[13] = 7;
            }

            deer[14] = wrand(genes[14], 41);
        }

        if (deer[2] == 3) {
            deer[15] = wrand(genes[15], 43);
        } else if (deer[2] == 1) {
            deer[15] = wrand(genes[15], 44);
        } else if (deer[2] == 10) {
            deer[15] = wrand(genes[15], 45);
        } else {
            deer[15] = wrand(genes[15], 42);
        }

        return deer;

        // Oh, deer, head hurts. But it works.
    }
    
    function sequenceDNA(uint DNA) internal pure returns (uint16[16] memory) {
        uint16[16] memory genes;
        for (uint8 i = 0; i < 16; i++) {
            genes[i] = uint16(DNA % 10000);
            DNA /= 10000;
        }
        return genes;
    }

    function wrand(uint16 gene, uint8 weightsListIndex) internal view returns (uint8 trait_index) {
        for (uint8 i = 0; i < WEIGHTS[weightsListIndex].length; i++) {
            uint16 current = WEIGHTS[weightsListIndex][i];
            if (gene < current) {
                return i;
            }
            gene -= current;
        }
        revert();
    }

    function renderImage(uint8[16] memory deer) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            SVG_HEADER,
                            composeSprites(deer),
                            SVG_FOOTER
                        )
                    )
                )
            )
        );
    }

    function composeSprites(uint8[16] memory deer) internal view returns (string memory) {

        string memory comp1 = string(abi.encodePacked(
            renderSprite(spriteRouter.getSprite(0, 0, deer[15])),                                   // background
            renderSprite(spriteRouter.getSprite(1, deer[0], deer[1])),                              // body
            renderSprite(spriteRouter.getSprite(3, deer[1], deer[6])),                              // brows
            deer[4] == 0 ? renderSprite(spriteRouter.getSprite(2, 0, 0)) : ''                       // freckles
        ));

        string memory comp2 = '';
        if (deer[3] == 0 || deer[3] == 9 || deer[3] == 11) {                                        // if over ear hair style
            comp2 = string(abi.encodePacked(                                                           
                renderSprite(spriteRouter.getSprite(5, deer[1], deer[9])),                          // ears
                deer[10] != 4 ? renderSprite(spriteRouter.getSprite(6, deer[9], deer[10])) : '',    // earrings
                renderSprite(spriteRouter.getSprite(7, 0, deer[5])),                                // eyes
                renderSprite(spriteRouter.getSprite(4, deer[2], deer[3]))                           // hair
            ));
        } else {                                                                                    // if regular hair style
            comp2 = string(abi.encodePacked(
                renderSprite(spriteRouter.getSprite(4, deer[2], deer[3])),                          // hair
                renderSprite(spriteRouter.getSprite(5, deer[1], deer[9])),                          // ears
                deer[10] != 4 ? renderSprite(spriteRouter.getSprite(6, deer[9], deer[10])) : '',    // earrings
                renderSprite(spriteRouter.getSprite(7, 0, deer[5]))                                 // eyes
            ));
        }

        bool overmouth;
        if ((deer[7] == 1 || deer[7] == 5) && (deer[8] != 5)) {
            overmouth = true;
        }

        string memory comp3 = string(abi.encodePacked(
            deer[14] != 22 ? renderSprite(spriteRouter.getSprite(8, deer[0], deer[14])) : '',       // clothes
            deer[7] != 6 ? renderSprite(spriteRouter.getSprite(9, deer[2], deer[7])) : '',          // beard
            renderSprite(spriteRouter.getSprite(10, 0, deer[8])),                                   // mouth
            overmouth ? renderSprite(spriteRouter.getSprite(9, deer[2], 5)) : ''                    // check over mouth beard style
        ));

        string memory comp4 = string(abi.encodePacked(
            renderSprite(spriteRouter.getSprite(11, deer[1], deer[11])),                            // nose
            renderSprite(spriteRouter.getSprite(12, 0, deer[12])),                                  // antlers
            deer[13] != 7 ? renderSprite(spriteRouter.getSprite(13, 0, deer[13])) : ''              // antler_accessory
        ));

        return string(abi.encodePacked(comp1, comp2, comp3, comp4));
    }

    function renderSprite(string memory sprite) internal view returns (string memory) {
        return string(abi.encodePacked(
            SVG_IMAGE_TAG,
            sprite,
            '"/>'
        ));
    }

    function formatTraits(uint8[16] memory deer) internal view returns (string memory) {
        string memory part1 = string(abi.encodePacked(
            '"attributes": [',
            '{"trait_type": "Gender", "value": "',           GENDER[deer[0]], '"},',
            '{"trait_type": "Fur", "value": "',              FUR[deer[1]], '"},',
            '{"trait_type": "Hair Color", "value": "',       HAIR_COLOR[deer[2]], '"},',
            '{"trait_type": "Hair Style", "value": "',       HAIR_STYLE[deer[3]], '"},',
            '{"trait_type": "Freckles", "value": "',         FRECKLES[deer[4]], '"},'
        ));
        string memory part2 = string(abi.encodePacked(
            '{"trait_type": "Eyes", "value": "',             EYES[deer[5]], '"},',
            '{"trait_type": "Brows", "value": "',            BROWS[deer[6]], '"},'
            '{"trait_type": "Beard", "value": "',            BEARD[deer[7]], '"},',
            '{"trait_type": "Mouth", "value": "',            MOUTH[deer[8]], '"},',
            '{"trait_type": "Ears", "value": "',             EARS[deer[9]], '"},',
            '{"trait_type": "Earrings", "value": "',         EARRINGS[deer[10]], '"},'
        ));
        string memory part3 = string(abi.encodePacked(
            '{"trait_type": "Nose", "value": "',             NOSE[deer[11]], '"},',
            '{"trait_type": "Antlers", "value": "',          ANTLERS[deer[12]], '"},',
            '{"trait_type": "Antler Accessory", "value": "', ANTLER_ACCESSORY[deer[13]], '"},',
            '{"trait_type": "Clothes", "value": "',          CLOTHES[deer[14]], '"},',
            '{"trait_type": "Background", "value": "',       BACKGROUND[deer[15]], '"}]'
        ));
        return string(abi.encodePacked(part1, part2, part3));
    }


    // OWNER STUFF

    function reveal() external onlyOwner {
        REVEALED = true;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setDAO(address dao_) external onlyOwner {
        dao = dao_;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Can't be zero address");
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner lmao");
        _;
    }


    // DAO STUFF

    function setMerkleRoot(bytes32 root) external onlyOwnerOrDAO {
        merkleRoot = root;
    }

    function turnMintOn() external onlyOwnerOrDAO {
        MINT_IS_ON = true;
    }

    function turnMintOff() external onlyOwnerOrDAO {
        MINT_IS_ON = false;
    }

    function setMintPublic() external onlyOwnerOrDAO {
        MINT_IS_PUBLIC = true;
    }

    function setMintWhitelisted() external onlyOwnerOrDAO {
        MINT_IS_PUBLIC = false;
    }

    function setPrice(uint price) external onlyOwnerOrDAO {
        MINT_PRICE = price;
    }

    function setMaxSupply(uint max_supply) external onlyOwnerOrDAO {
        MAX_SUPPLY = max_supply;
    }

    function setMaxMintPerTx(uint maxMintPerTx) external onlyOwnerOrDAO {
        MAX_MINT_PER_TX = maxMintPerTx;
    }

    function setMaxMintPerWallet(uint maxMintPerWallet) external onlyOwnerOrDAO {
        MAX_MINT_PER_WALLET = maxMintPerWallet;
    }

    function setSpriteRouter(address ISpriteRouterAddress) external onlyOwnerOrDAO {
        spriteRouter = ISpriteRouter(ISpriteRouterAddress);
    }

    function setDescription(string calldata description_) external onlyOwnerOrDAO {
        description = description_;
    }

    function setSVGHeader(string calldata SVGHeader) external onlyOwnerOrDAO {
        SVG_HEADER = SVGHeader;
    }

    function setSVGFooter(string calldata SVGFooter) external onlyOwnerOrDAO {
        SVG_FOOTER = SVGFooter;
    }

    function setSVGImageTag(string calldata imageTag) external onlyOwnerOrDAO {
        SVG_IMAGE_TAG = imageTag;
    }

    function withdrawDAO() external onlyOwnerOrDAO {
        payable(dao).transfer(address(this).balance);
    }

    modifier onlyOwnerOrDAO {
        require(msg.sender == owner || msg.sender == dao, "only owner or dao");
        _;
    }


    // HELPER FUNCTIONS

    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function uintToString(uint256 num) internal pure returns (string memory) {
        if (num == 0) {
            return "0";
        }
        uint256 temp = num;
        uint256 len;
        while (temp != 0) {
            len++;
            temp /= 10;
        }
        bytes memory strBuffer = new bytes(len);
        while (num != 0) {
            len -= 1;
            strBuffer[len] = bytes1(uint8(48 + uint256(num % 10)));
            num /= 10;
        }
        return string(strBuffer);
    }

}


/*
*     \_\_     _/_/
*         \___/
*        ~(0 0)~
*         (._.)\_________
*             \          \~
*              \  _____(  )
*               ||      ||
*               ||      ||
*
* HELLO DEER, NICE TO SEE YOU HERE :)
*/

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}