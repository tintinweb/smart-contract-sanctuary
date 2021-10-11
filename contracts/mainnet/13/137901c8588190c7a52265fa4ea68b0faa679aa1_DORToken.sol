// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./WhitelistAdminRole.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract DORToken is ERC721Enumerable, ReentrancyGuard, Pausable, WhitelistAdminRole {
    using SafeMath for uint256;

    enum TokenType {
        NONE,
        SILVER, // 1. Mix & Match Silver Grade Daughter
        GOLD, // 2. Mix & Match Gold Grade Daughter
        RAINBOW, // 3. Mix & Match Rainbow Grade Daughter
        EBIBLE, // 4. Daughter E-bible
        RANDOM, // 5. NONE
        M3D, // 6. 3D Mother NFT
        AIRDROPS, // 7. Limited Daughter NFT
        SPARK, // 8. SPARK Token NFT
        DAUGHTER, // 9. daughters
        ALIEN, // 10. daughters of alien
        RARE, // 11. rare daughters
        MOTHER // 12. the mother
    }

    uint256 public salePrice = 0.05 ether;
    string private _baseTokenURI;
    mapping(uint256 => uint256) typeMapping;

    // params
    uint256 public SILVER_CLAIM_DAUGHTER_MIN_NUM = 5;
    uint256 public GOLD_CLAIM_DAUGHTER_MIN_NUM = 10;
    uint256 public RAINBOW_CLAIM_DAUGHTER_MIN_NUM = 20;

    // claim flags
    mapping(uint256 => bool) claimFlags; // claim flags for silver/gold/rainbow
    mapping(uint256 => bool) claim3DFlags; // claim flags for m3d
    mapping(uint256 => bool) claimEbibleFlags; // claim flags for ebible
    mapping(address => bool) claimAirdropsFlags; // claim flags for airdrops type
    mapping(address => bool) claimSparkFlags; // claim flags for spark type

    mapping(address => bool) whitelistAirdrops; // whitelist for AIRDROPS type
    mapping(address => bool) whitelistSpark; // whitelist for SPARK type

    ////////////////////////////////////////////////////
    // nft index
    ////////////////////////////////////////////////////
    // daughter index
    uint256 nextDaughterIndex = 1;
    uint256 daughterIndexMin = 1;
    uint256 daughterIndexMax = 999;
    // alien index
    uint256 nextAlienIndex = daughterIndexMax + 1;
    uint256 alienIndexMin = daughterIndexMax + 1;
    uint256 alienIndexMax = daughterIndexMax + 44;
    // silver index
    uint256 nextSilverIndex = alienIndexMax + 1;
    uint256 silverIndexMin = alienIndexMax + 1;
    uint256 silverIndexMax = alienIndexMax + 300;
    // gold index
    uint256 nextGoldIndex = silverIndexMax + 1;
    uint256 goldIndexMin = silverIndexMax + 1;
    uint256 goldIndexMax = silverIndexMax + 150;
    // rainbow index
    uint256 nextRainbowIndex = goldIndexMax + 1;
    uint256 rainbowIndexMin = goldIndexMax + 1;
    uint256 rainbowIndexMax = goldIndexMax + 50;
    // rare index
    uint256 nextRareIndex = rainbowIndexMax + 1;
    uint256 rareIndexMin = rainbowIndexMax + 1;
    uint256 rareIndexMax = rainbowIndexMax + 450;
    // ebible index
    uint256 nextEbibleIndex = rareIndexMax + 1;
    uint256 ebibleIndexMin = rareIndexMax + 1;
    uint256 ebibleIndexMax = rareIndexMax + 500;
    // mother index
    uint256 nextMotherIndex = ebibleIndexMax + 1;
    uint256 motherIndexMin = ebibleIndexMax + 1;
    uint256 motherIndexMax = ebibleIndexMax + 30;
    // m3d index
    uint256 nextM3dIndex = motherIndexMax + 1;
    uint256 m3dIndexMin = motherIndexMax + 1;
    uint256 m3dIndexMax = motherIndexMax + 30;
    // airdrop index
    uint256 nextAirdropsIndex = m3dIndexMax + 1;
    uint256 airdropsIndexMin = m3dIndexMax + 1;
    uint256 airdropsIndexMax = m3dIndexMax + 300;
    // spark index
    uint256 nextSparkIndex = airdropsIndexMax + 1;
    uint256 sparkIndexMin = airdropsIndexMax + 1;
    uint256 sparkIndexMax = airdropsIndexMax + 500;
    ////////////////////////////////////////////////////
    // nft index
    ////////////////////////////////////////////////////

    bool whitelistEnabled = true;  // whitelist switch, for pre-sale
    mapping(address => bool) whitelist; // whitelist for mint
    mapping (address => uint256) public whitelistMintCounts; // limit for pre-sale
    uint256 public whitelistMintMaxCount = 2;

    bool public sgrClaimEnabled; // silver/gold/rainbow switch
    bool public ebibleClaimEnabled; // ebible claim switch
    bool public m3dClaimEnabled;  // m3d claim switch

    /////////////////////////////////////////////////////
    // params
    function setWhitelistMintMaxCount(uint256 value) public onlyWhitelistAdmin {
        whitelistMintMaxCount = value;
    }

    function setSGREnabled(bool flag) public onlyWhitelistAdmin {
        sgrClaimEnabled = flag;
    }

    function setEbileEnabled(bool flag) public onlyWhitelistAdmin {
        ebibleClaimEnabled = flag;
    }

    function set3DEnabled(bool flag) public onlyWhitelistAdmin {
        m3dClaimEnabled = flag;
    }

    function setWhitelistEnabled(bool flag) public onlyWhitelistAdmin {
        whitelistEnabled = flag;
    }

    function setSalePrice(uint256 value) public onlyWhitelistAdmin {
        salePrice = value;
    }

    function setSilverClaimDaughterMinNum(uint256 value) public onlyWhitelistAdmin {
        SILVER_CLAIM_DAUGHTER_MIN_NUM = value;
    }

    function setGoldClaimDaughterMinNum(uint256 value) public onlyWhitelistAdmin {
        GOLD_CLAIM_DAUGHTER_MIN_NUM = value;
    }

    function setRainbowClaimDaughterMinNum(uint256 value) public onlyWhitelistAdmin {
        RAINBOW_CLAIM_DAUGHTER_MIN_NUM = value;
    }
    /////////////////////////////////////////////////////


    constructor() ERC721("Daughters of Rainbow", "DOR") {
        // _baseTokenURI = "ipfs://QmaWSLDeJ3Urn47RX3fNEKcU4Tg7TXHpLy1t4t8z466AUP/";
        // metadata: ipfs://QmaWSLDeJ3Urn47RX3fNEKcU4Tg7TXHpLy1t4t8z466AUP/<tokenId>.json
    }

    function getNextDaughterId() internal returns (uint256 id) {
        id = nextDaughterIndex;
        nextDaughterIndex = nextDaughterIndex.add(1);
    }

    function getNextAlienId() internal returns (uint256 id) {
        id = nextAlienIndex;
        nextAlienIndex = nextAlienIndex.add(1);
    }

    function getNextSilverId() internal returns (uint256 id) {
        id = nextSilverIndex;
        nextSilverIndex = nextSilverIndex.add(1);
    }

    function getNextGoldId() internal returns (uint256 id) {
        id = nextGoldIndex;
        nextGoldIndex = nextGoldIndex.add(1);
    }

    function getNextRainbowId() internal returns (uint256 id) {
        id = nextRainbowIndex;
        nextRainbowIndex = nextRainbowIndex.add(1);
    }

    function getNextRareId() internal returns (uint256 id) {
        id = nextRareIndex;
        nextRareIndex = nextRareIndex.add(1);
    }

    function getNextEbibleId() internal returns (uint256 id) {
        id = nextEbibleIndex;
        nextEbibleIndex = nextEbibleIndex.add(1);
    }

    function getNextMotherId() internal returns (uint256 id) {
        id = nextMotherIndex;
        nextMotherIndex = nextMotherIndex.add(1);
    }

    function getNextM3dId() internal returns (uint256 id) {
        id = nextM3dIndex;
        nextM3dIndex = nextM3dIndex.add(1);
    }

    function getNextAirdropsId() internal returns (uint256 id) {
        id = nextAirdropsIndex;
        nextAirdropsIndex = nextAirdropsIndex.add(1);
    }

    function getNextSparkId() internal returns (uint256 id) {
        id = nextSparkIndex;
        nextSparkIndex = nextSparkIndex.add(1);
    }

    //////////////////////////////////////////////////////////////
    // NFT type and count functions
    function daughterLeftover() public view returns (uint256) {
        if (nextDaughterIndex > daughterIndexMax) {
            return 0;
        }
        return daughterIndexMax.sub(nextDaughterIndex).add(1);
    }

    function getDaughterCount() public view returns (uint256) {
        return daughterCurrentCount();
    }

    function daughterCurrentCount() public view returns (uint256) {
        return nextDaughterIndex.sub(daughterIndexMin);
    }

    function alienLeftover() public view returns (uint256) {
        if (nextAlienIndex > alienIndexMax) {
            return 0;
        }
        return alienIndexMax.sub(nextAlienIndex).add(1);
    }

    function alienCurrentCount() public view returns (uint256) {
        return nextAlienIndex.sub(alienIndexMin);
    }

    function silverLeftover() public view returns (uint256) {
        if (nextSilverIndex > silverIndexMax) {
            return 0;
        }
        return silverIndexMax.sub(nextSilverIndex).add(1);
    }

    function silverCurrentCount() public view returns (uint256) {
        return nextSilverIndex.sub(silverIndexMin);
    }

    function goldLeftover() public view returns (uint256) {
        if (nextGoldIndex > goldIndexMax) {
            return 0;
        }
        return goldIndexMax.sub(nextGoldIndex).add(1);
    }

    function goldCurrentCount() public view returns (uint256) {
        return nextGoldIndex.sub(goldIndexMin);
    }

    function rainbowLeftover() public view returns (uint256) {
        if (nextRainbowIndex > rainbowIndexMax) {
            return 0;
        }
        return rainbowIndexMax.sub(nextRainbowIndex).add(1);
    }

    function rainbowCurrentCount() public view returns (uint256) {
        return nextRainbowIndex.sub(rainbowIndexMin);
    }

    function rareLeftover() public view returns (uint256) {
        if (nextRareIndex > rareIndexMax) {
            return 0;
        }
        return rareIndexMax.sub(nextRareIndex).add(1);
    }

    function rareCurrentCount() public view returns (uint256) {
        return nextRareIndex.sub(rareIndexMin);
    }

    function ebibleLeftover() public view returns (uint256) {
        if (nextEbibleIndex > ebibleIndexMax) {
            return 0;
        }
        return ebibleIndexMax.sub(nextEbibleIndex).add(1);
    }

    function ebibleCurrentCount() public view returns (uint256) {
        return nextEbibleIndex.sub(ebibleIndexMin);
    }

    function motherLeftover() public view returns (uint256) {
        if (nextMotherIndex > motherIndexMax) {
            return 0;
        }
        return motherIndexMax.sub(nextMotherIndex).add(1);
    }

    function motherCurrentCount() public view returns (uint256) {
        return nextMotherIndex.sub(motherIndexMin);
    }

    function m3dLeftover() public view returns (uint256) {
        if (nextM3dIndex > m3dIndexMax) {
            return 0;
        }
        return m3dIndexMax.sub(nextM3dIndex).add(1);
    }

    function m3dCurrentCount() public view returns (uint256) {
        return nextM3dIndex.sub(m3dIndexMin);
    }

    function airdropsLeftover() public view returns (uint256) {
        if (nextAirdropsIndex > airdropsIndexMax) {
            return 0;
        }
        return airdropsIndexMax.sub(nextAirdropsIndex).add(1);
    }

    function airdropsCurrentCount() public view returns (uint256) {
        return nextAirdropsIndex.sub(airdropsIndexMin);
    }

    function sparkLeftover() public view returns (uint256) {
        if (nextSparkIndex > sparkIndexMax) {
            return 0;
        }
        return sparkIndexMax.sub(nextSparkIndex).add(1);
    }

    function sparkCurrentCount() public view returns (uint256) {
        return nextSparkIndex.sub(sparkIndexMin);
    }
    //////////////////////////////////////////////////////////////


    //////////////////////////////////////////////////////////////
    // claim flags
    function setClaimFlag(uint256 tokenId, bool flag) internal {
        claimFlags[tokenId] = flag;
    }

    function setClaim3DFlag(uint256 tokenId, bool flag) internal {
        claim3DFlags[tokenId] = flag;
    }

    function setClaimEbibleFlag(uint256 tokenId, bool flag) internal {
        claimEbibleFlags[tokenId] = flag;
    }

    function setClaimAirdropsFlag(address account, bool flag) internal {
        claimAirdropsFlags[account] = flag;
    }

    function setClaimSparkFlag(address account, bool flag) internal {
        claimSparkFlags[account] = flag;
    }

    function getClaimFlag(uint256 tokenId) public view returns (bool) {
        return claimFlags[tokenId];
    }

    function getClaim3DFlag(uint256 tokenId) public view returns (bool) {
        return claim3DFlags[tokenId];
    }

    function getClaimEbibleFlag(uint256 tokenId) public view returns (bool) {
        return claimEbibleFlags[tokenId];
    }

    function getClaimAirdropsFlag(address account) public view returns (bool) {
        return claimAirdropsFlags[account];
    }

    function getClaimSparkFlag(address account) public view returns (bool) {
        return claimSparkFlags[account];
    }
    //////////////////////////////////////////////////////////////

    function addWhitelist(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function isWhitelist(address account) public view returns (bool) {
        return whitelist[account];
    }

    function addWhitelistAirdrops(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistAirdrops[accounts[i]] = true;
        }
    }

    function isWhitelistAirdrops(address account) public view returns (bool) {
        return whitelistAirdrops[account];
    }

    function addWhitelistSpark(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistSpark[accounts[i]] = true;
        }
    }

    function isWhitelistSpark(address account) public view returns (bool) {
        return whitelistSpark[account];
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseTokenURI) external onlyWhitelistAdmin {
        _baseTokenURI = baseTokenURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!(owner|approved)");
        _burn(tokenId);
    }

    function getType(uint256 tokenId) public view returns (uint256) {
        return typeMapping[tokenId];
    }

    function getTokenTypes(uint256[] memory tokenIds) public view returns (uint256[] memory types) {
        types = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            types[i] = getType(tokenIds[i]);
        }
    }

    function setTokenType(uint256 tokenId, uint256 tp) public onlyWhitelistAdmin {
        setType(tokenId, tp);
    }

    function setType(uint256 tokenId, uint256 tp) internal {
        typeMapping[tokenId] = tp;
    }

    function _mintDaughter(address account, uint256 num) internal {
        require(nextDaughterIndex.add(num) <= daughterIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextDaughterId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.DAUGHTER));
        }
    }

    function _mintAlien(address account, uint256 num) internal {
        require(nextAlienIndex.add(num) <= alienIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextAlienId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.ALIEN));
        }
    }

    function claimSGR(uint256 tp) public {
        require(sgrClaimEnabled, "not start");

        address account = _msgSender();
        // check silver/gold/rainbow
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(account);
        uint256 daughterCount;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                daughterCount = daughterCount.add(1);
            }
        }

        uint256 cnt;
        if (tp == uint256(TokenType.RAINBOW)) {
            cnt = RAINBOW_CLAIM_DAUGHTER_MIN_NUM;
            require(rainbowLeftover() > 0, "no rainbow leftover");
        } else if (tp == uint256(TokenType.GOLD)) {
            cnt = GOLD_CLAIM_DAUGHTER_MIN_NUM;
            require(goldLeftover() > 0, "no gold leftover");
        } else if (tp == uint256(TokenType.SILVER)) {
            cnt = SILVER_CLAIM_DAUGHTER_MIN_NUM;
            require(silverLeftover() > 0, "no silver leftover");
        } else {
            require(false, "type error");
        }
        require(daughterCount >= cnt, "can't claim SGR");
        // set claim flag
        for (uint256 i = 0; i < tokenTypes.length && cnt > 0; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                setClaimFlag(tokenIds[i], true);
                cnt = cnt.sub(1);
            }
        }

        // mint
        if (tp == uint256(TokenType.RAINBOW)) {
            _mintRainbow(account, 1);
        } else if (tp == uint256(TokenType.GOLD)) {
            _mintGold(account, 1);
        } else if (tp == uint256(TokenType.SILVER)) {
            _mintSilver(account, 1);
        }
    }

    function _mintSilver(address account, uint256 num) internal {
        require(nextSilverIndex.add(num) <= silverIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextSilverId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.SILVER));
        }
    }

    function _mintGold(address account, uint256 num) internal {
        require(nextGoldIndex.add(num) <= goldIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextGoldId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.GOLD));
        }
    }

    function _mintRainbow(address account, uint256 num) internal {
        require(nextRainbowIndex.add(num) <= rainbowIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextRainbowId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.RAINBOW));
        }
    }

    function _mintRare(address account, uint256 num) internal {
        require(nextRareIndex.add(num) <= rareIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextRareId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.RARE));
        }
    }

    function _mintEbible(address account, uint256 num) internal {
        require(nextEbibleIndex.add(num) <= ebibleIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextEbibleId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.EBIBLE));
        }
    }

    function _mintMother(address account, uint256 num) internal {
        require(nextMotherIndex.add(num) <= motherIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextMotherId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.MOTHER));
        }
    }

    function _mintM3d(address account, uint256 num) internal {
        require(nextM3dIndex.add(num) <= m3dIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextM3dId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.M3D));
        }
    }

    function _mintAirdrops(address account, uint256 num) internal {
        require(nextAirdropsIndex.add(num) <= airdropsIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextAirdropsId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.AIRDROPS));
        }
    }

    function _mintSpark(address account, uint256 num) internal {
        require(nextSparkIndex.add(num) <= sparkIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextSparkId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.SPARK));
        }
    }

    // presale for daughter
    function mint(uint256 num) public payable nonReentrant WhenNotPaused {
        if (whitelistEnabled) { // check whitelist
            require(isWhitelist(_msgSender()), "not in whitelist");
            require(whitelistMintCounts[_msgSender()].add(num) <= whitelistMintMaxCount, "whitelist mint num limited");
            whitelistMintCounts[_msgSender()] =  whitelistMintCounts[_msgSender()].add(num);
        }
        // validate
        require(msg.value >= salePrice.mul(num), "payment invalid");
        // mint daughter
        _mintDaughter(_msgSender(), num);
    }

    // returns (uint256[] tokenIds, uint256[] tokenTypes)
    function getTokens(address owner) public view returns (uint256[] memory, uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory tokenTypes = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            tokenIds[i] = id;
            tokenTypes[i] = getType(id);
        }
        return (tokenIds, tokenTypes);
    }

    function canClaimSGR(address owner) public view returns (bool silver, bool gold, bool rainbow) {
        if (!sgrClaimEnabled) { // not enabled
            return (false, false, false);
        }

        // check silver/gold/rainbow
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(owner);
        uint256 daughterCount;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                daughterCount = daughterCount.add(1);
            }
        }

        if (daughterCount >= RAINBOW_CLAIM_DAUGHTER_MIN_NUM && rainbowLeftover() > 0) {
            rainbow = true;
        } else if (daughterCount >= GOLD_CLAIM_DAUGHTER_MIN_NUM && goldLeftover() > 0) {
            gold = true;
        } else if (daughterCount >= SILVER_CLAIM_DAUGHTER_MIN_NUM && silverLeftover() > 0) {
            silver = true;
        }
    }

    function canClaim(address account) public view
        returns
        (bool silver, bool gold, bool rainbow, bool ebible, bool random, bool m3d, bool airdrops, bool spark) {
        // check silver/gold/rainbow
        (silver, gold, rainbow) = canClaimSGR(account);

        // check ebible
        ebible = canClaimEbible(account);

        // check random silver/gold/rainbow
        random = false;

        // check m3d
        m3d = canClaim3D(account);

        // check airdrops
        airdrops = canClaimAirdrops(account);

        // check spark
        spark = canClaimSpark(account);
    }

    function canClaim3D(address account) public view returns (bool) {
        if (!m3dClaimEnabled) {
            return false;
        }

        // mint over
        if (m3dLeftover() == 0) {
            return false;
        }

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(account);
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaim3DFlag(tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    function canClaimEbible(address account) public view returns (bool) {
        if (!ebibleClaimEnabled) { // not enabled
            return false;
        }

        // mint over
        if (ebibleLeftover() == 0) {
            return false;
        }

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(account);
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.RARE) && !getClaimEbibleFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        if (cnt >= 3) {
            return true;
        }
        return false;
    }

    function claim3D() public {
        require(m3dClaimEnabled, "not start");

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        bool can;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaim3DFlag(tokenIds[i])) {
                can = true;
                break;
            }
        }
        require(can, "can't claim 3D mother");

        // set claim flag
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaim3DFlag(tokenIds[i])) {
                setClaim3DFlag(tokenIds[i], true);
                break;
            }
        }

        // mint
        _mintM3d(_msgSender(), 1);
    }

    function canClaimAirdrops(address account) public view returns (bool) {
        if (isWhitelistAirdrops(account) && !getClaimAirdropsFlag(account) && airdropsLeftover() > 0) {
            return true;
        }
        return false;
    }

    function claimAirdrops() public {
        address account = _msgSender();
        require(canClaimAirdrops(account), "can't claim airdrops");

        // set claim flags
        setClaimAirdropsFlag(account, true);

        // mint
        _mintAirdrops(account, 1);
    }

    function canClaimSpark(address account) public view returns (bool) {
        if (isWhitelistSpark(account) && !getClaimSparkFlag(account) && sparkLeftover() > 0) {
            return true;
        }
        return false;
    }

    function claimSpark() public {
        address account = _msgSender();
        require(canClaimSpark(account), "can't claim spark");

        // set claim flags
        setClaimSparkFlag(account, true);

        // mint
        _mintSpark(account, 1);
    }

    function claim(uint256 tp) public {
        if (tp == uint256(TokenType.SILVER) || tp == uint256(TokenType.GOLD) || tp == uint256(TokenType.RAINBOW)) {
            claimSGR(tp);
        } else if (tp == uint256(TokenType.EBIBLE)) {
            claimEbible();
        } else if (tp == uint256(TokenType.M3D)) {
            claim3D();
        } else if (tp == uint256(TokenType.AIRDROPS)) {
            claimAirdrops();
        } else if (tp == uint256(TokenType.SPARK)) {
            claimSpark();
        }
    }

    function claimEbible() public {
        require(ebibleClaimEnabled, "not start");

        // check and set claim flag
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.RARE) && !getClaimEbibleFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        require(cnt >= 3, "can claim ebile");

        // set claim flag
        uint256 c = 3;
        for (uint256 i = 0; i < tokenTypes.length && c > 0; i++) {
            if (tokenTypes[i] == uint256(TokenType.RARE) && !getClaimEbibleFlag(tokenIds[i])) {
                setClaimEbibleFlag(tokenIds[i], true);
                c = c.sub(1);
            }
        }

        // mint
        _mintEbible(_msgSender(), 1);
    }

    ////////////////////////////////////////////////////
    // admin operation
    ////////////////////////////////////////////////////

    function adminMintDaughter(address account, uint256 num) public onlyWhitelistAdmin {
        _mintDaughter(account, num);
    }

    // admin mint alien
    function adminMintAlien(address account, uint256 num) public onlyWhitelistAdmin {
        _mintAlien(account, num);
    }

    // admin mint alien
    function adminMintRare(address account, uint256 num) public onlyWhitelistAdmin {
        _mintRare(account, num);
    }

    // admin mint mother
    function adminMintMother(address account, uint256 num) public onlyWhitelistAdmin {
        _mintMother(account, num);
    }

    // admin mint airdrops
    function adminMintAirdrops(address account, uint256 num) public onlyWhitelistAdmin {
        _mintAirdrops(account, num);
    }

    // admin mint spark
    function adminMintSpark(address account, uint256 num) public onlyWhitelistAdmin {
        _mintSpark(account, num);
    }

    function adminMint(address account, uint256 tp, uint256 num) public onlyWhitelistAdmin {
        if (tp == uint256(TokenType.DAUGHTER)) {
            _mintDaughter(account, num);
        } else if (tp == uint256(TokenType.ALIEN)) {
            _mintAlien(account, num);
        } else if (tp == uint256(TokenType.SILVER)) {
            _mintSilver(account, num);
        } else if (tp == uint256(TokenType.GOLD)) {
            _mintGold(account, num);
        } else if (tp == uint256(TokenType.RAINBOW)) {
            _mintRainbow(account, num);
        } else if (tp == uint256(TokenType.RARE)) {
            _mintRare(account, num);
        } else if (tp == uint256(TokenType.EBIBLE)) {
            _mintEbible(account, num);
        } else if (tp == uint256(TokenType.MOTHER)) {
            _mintMother(account, num);
        } else if (tp == uint256(TokenType.M3D)) {
            _mintM3d(account, num);
        } else if (tp == uint256(TokenType.AIRDROPS)) {
            _mintAirdrops(account, num);
        } else if (tp == uint256(TokenType.SPARK)) {
            _mintSpark(account, num);
        }
    }

    function adminMintx(address account, uint256 tp, uint256 tokenId) public onlyWhitelistAdmin {
        // mint and set token type
        _safeMint(account, tokenId);
        setType(tokenId, tp);
    }

    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    ////////////////////////////////////////////////////
}