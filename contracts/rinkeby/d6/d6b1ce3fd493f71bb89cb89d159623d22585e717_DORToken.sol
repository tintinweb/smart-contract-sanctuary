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
        DAUGHTER, // daughters
        ALIEN, // daughters of alien
        RARE, // rare daughters
        MOTHER, // the mother
        SILVER, // mix & match silver grade
        GOLD, // mix & match gold grade
        RAINBOW, // mix & match rainbow grade
        EBIBLE, // daughter ebible
        M3D, // 3D mother
        AIRDROPS // presale airdrops
    }

    uint256 public salePrice = 0.05 ether;
    string private _baseTokenURI;
    mapping(uint256 => uint256) typeMapping;
    mapping(uint256 => bool) claimFlags; // claim flags for silver/gold/rainbow/M3D
    mapping(uint256 => bool) claimEbibleFlags; // claim flags for ebible

    uint256 public silverTotalCount = 50;
    uint256 public goldTotalCount = 50;
    uint256 public rainbowTotalCount = 5;

    uint256 public currentSilverCount;
    uint256 public currentGoldCount;
    uint256 public currentRainbowCount;

    uint256 nextDaughterIndex = 0;
    uint256 maxDaughterIndex = 999;
    uint256 adminMintIndex = 999;

    bool whitelistEnabled = true;  // whitelist switch, for pre-sale
    mapping(address => bool) whitelist; // whitelist for mint

    bool public ebibleEnabled = true; // ebible claim switch
    bool public m3dEnabled = true;  // m3d claim switch

    function setEbileFlag(bool flag) public onlyWhitelistAdmin {
        ebibleEnabled = flag;
    }

    function set3DEnabled(bool flag) public onlyWhitelistAdmin {
        m3dEnabled = flag;
    }

    function setWhitelistEnabled(bool flag) public onlyWhitelistAdmin {
        whitelistEnabled = flag;
    }

    constructor() ERC721("Daughters of Rainbow", "DOR") {
//        _baseTokenURI = "https://daughters-of-rainbow.oss-cn-hangzhou.aliyuncs.com/meta/";
        // https://daughters-of-rainbow-v0.s3.ap-southeast-1.amazonaws.com/meta/
        // metadata: https://daughters-of-rainbow.s3.amazonaws.com/meta/<tokenId>
        // images: https://daughters-of-rainbow.s3.amazonaws.com/thumbs/<tokenId>.png
    }

    function getNextDaughterId() internal returns (uint256) {
        nextDaughterIndex = nextDaughterIndex.add(1);
        return nextDaughterIndex;
    }

    function getNextMintTokenId() internal returns (uint256) {
        adminMintIndex = adminMintIndex.add(1);
        return adminMintIndex;
    }

    function getDaughterCount() public view returns (uint256) {
        return nextDaughterIndex;
    }

    function setSalePrice(uint256 value) public onlyWhitelistAdmin {
        salePrice = value;
    }

    function setClaimFlag(uint256 tokenId, bool flag) internal {
        claimFlags[tokenId] = flag;
    }

    function setClaimEbibleFlag(uint256 tokenId, bool flag) internal {
        claimEbibleFlags[tokenId] = flag;
    }

    function getClaimFlag(uint256 tokenId) public view returns (bool) {
        return claimFlags[tokenId];
    }

    function getClaimEbibleFlag(uint256 tokenId) public view returns (bool) {
        return claimEbibleFlags[tokenId];
    }

    function addWhitelist(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function isWhitelist(address account) public view returns (bool) {
        return whitelist[account];
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

    function setType(uint256 tokenId, uint256 tp) internal {
        typeMapping[tokenId] = tp;
    }

    function _mintDaughter(uint256 num) internal {
        require(nextDaughterIndex.add(num) <= maxDaughterIndex, "token id invalid");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextDaughterId();
            // mint and set token type
            _safeMint(_msgSender(), tokenId);
            setType(tokenId, uint256(TokenType.DAUGHTER));
        }
    }

    // presale for daughter
    function mint(uint256 num) public payable nonReentrant WhenNotPaused {
        if (whitelistEnabled) { // check whitelist
            require(isWhitelist(_msgSender()), "not in whitelist");
        }
        // validate
        require(msg.value >= salePrice.mul(num), "payment invalid");
        // mint daughter
        _mintDaughter(num);
    }

    // admin mint daughter
    function adminMintDaughter(uint256 num) public nonReentrant onlyWhitelistAdmin {
        _mintDaughter(num);
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

    function canClaim(address owner) public view
        returns
        (bool silver, bool gold, bool rainbow, bool random, bool m3d, bool ebible) {
        // check silver/gold/rainbow
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(owner);
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        if (cnt >= 20 && currentRainbowCount < rainbowTotalCount) {
            rainbow = true;
        } else if (cnt >= 10 && currentGoldCount < goldTotalCount) {
            gold = true;
        } else if (cnt >= 5 && currentSilverCount < silverTotalCount) {
            silver = true;
        }

        // random silver/gold/rainbow
        random = canClaimRandom(owner);

        // check m3d
        m3d = canClaim3D(owner);

        // check ebible
        ebible = canClaimEbible(owner);

    }

    function canClaimRandom(address owner) public view returns (bool) {
        return false;
    }

    function canClaim3D(address owner) public view returns (bool) {
        if (!m3dEnabled) {
            return false;
        }

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(owner);
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaimFlag(tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    function canClaimEbible(address owner) public view returns (bool) {
        if (!ebibleEnabled) {
            return false;
        }

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(owner);
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimEbibleFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        if (cnt >= 3) {
            return true;
        }
        return false;
    }

    function claim3D() public {
        require(m3dEnabled, "not start");

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaimFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }
        require(cnt >= 1, "can't claim 3D mother");

        // set claim flag
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaimFlag(tokenIds[i])) {
                setClaimFlag(tokenIds[i], true);
                break;
            }
        }

        // mint
        uint256 tokenId = getNextMintTokenId();
        _safeMint(_msgSender(), tokenId);
        setType(tokenId, uint256(TokenType.M3D));
    }

    function claim(uint256 tp) public {
        // check and set claim flag
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }
        uint256 c;
        if (tp == uint256(TokenType.RAINBOW)) {
            c = 20;
            currentRainbowCount = currentRainbowCount.add(1);
        } else if (tp == uint256(TokenType.GOLD)) {
            c = 10;
            currentGoldCount = currentGoldCount.add(1);
        } else if (tp == uint256(TokenType.SILVER)) {
            c = 5;
            currentSilverCount = currentSilverCount.add(1);
        } else {
            require(false, "type error");
        }
        require(cnt >= c, "can't claim");
        // set claim flag
        for (uint256 i = 0; i < tokenTypes.length && c > 0; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                setClaimFlag(tokenIds[i], true);
                c = c.sub(1);
            }
        }

        // mint
        uint256 tokenId = getNextMintTokenId();
        _safeMint(_msgSender(), tokenId);
        setType(tokenId, tp);
    }

    function claimEbile() public {
        require(ebibleEnabled, "not start");

        // check and set claim flag
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        require(cnt >= 3, "can claim ebile");

        // set claim flag
        uint256 c = 3;
        for (uint256 i = 0; i < tokenTypes.length && c > 0; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                setClaimEbibleFlag(tokenIds[i], true);
                c = c.sub(1);
            }
        }

        // mint
        uint256 tokenId = getNextMintTokenId();
        _safeMint(_msgSender(), tokenId);
        setType(tokenId, uint256(TokenType.EBIBLE));
    }

    function adminMint(uint256 tp, uint256 num) public nonReentrant onlyWhitelistAdmin {
        for (uint256 i = 0; i < num; i++) {
            uint256 tokenId = getNextMintTokenId();
            _safeMint(_msgSender(), tokenId);
            setType(tokenId, tp);
        }
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}