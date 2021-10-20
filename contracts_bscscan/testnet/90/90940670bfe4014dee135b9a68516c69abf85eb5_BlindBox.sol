// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./WhitelistAdminRole.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";

contract BlindBox is ERC721Enumerable, ReentrancyGuard, Ownable, WhitelistAdminRole {
    using SafeMath for uint256;
    using Strings for uint256;

    enum TokenAttribute {
        NONE,
        GOLD, // 1
        WOOD, // 2
        WATER, // 3
        FIRE, // 4
        SOIL // 5
    }

    enum TokenType {
        NONE,
        BEI, // 1.  bei bei
        JING, // 2. jing jing
        HUAN, // 3. huan huan
        YIING, // 4. ying ying
        NI, // 5.ni ni
        SIMPLE, // 6. simple fuwa
        ENERGY // 7. energy fuwa
    }

    string private _baseTokenURI;
    mapping(uint256 => uint256) typeMapping;
    mapping(uint256 => uint256) attirbuteMapping;
    mapping(uint256 => uint256) energyMapping;

    address public energy;
    address public bee;
    address public usdt;

    uint256 public nextTokenId = 1;

    uint256 seed = 1;

    uint256 public blindBoxPrice = 100 * (10 ** 18); // blind box price, by energy token
    uint256 public beeBurnedForSynthBei = 50 * (10 ** 18); // burned bee when synth new nft
    uint256 public beeBurnedForSynthJing = 100 * (10 ** 18); // burned bee when synth new nft
    uint256 public beeBurnedForSynthHuan = 200 * (10 ** 18); // burned bee when synth new nft
    uint256 public beeBurnedForSynthYing = 300 * (10 ** 18); // burned bee when synth new nft
    uint256 public beeBurnedForSynthNi = 400 * (10 ** 18); // burned bee when synth new nft

    // for synth
    uint256 public beiCountForSynthJing = 3;
    uint256 public jingCountForSynthHuan = 3;
    uint256 public huanCountForSynthYing = 2;
    uint256 public yingCountForSynthNi = 2;

    // fixed wallet, receive tokens
    address public fixedWallet;

    constructor(address _energy, address _bee, address _usdt) ERC721("MetaVerse FUWA", "FUWA") {
        // _baseTokenURI = "ipfs://QmaWSLDeJ3Urn47RX3fNEKcU4Tg7TXHpLy1t4t8z466AUP/";
        // metadata: ipfs://QmaWSLDeJ3Urn47RX3fNEKcU4Tg7TXHpLy1t4t8z466AUP/<tokenType>/<tokenAttribute>.json
        energy = _energy;
        bee = _bee;
        usdt = _usdt;

        fixedWallet = msg.sender;
    }

    function setFixedWallet(address account) public onlyWhitelistAdmin {
        fixedWallet = account;
    }

    function setBlindBoxPrice(uint256 value) public onlyWhitelistAdmin {
        blindBoxPrice = value;
    }

    function setBeeBurnedForSynthBei(uint256 value) public onlyWhitelistAdmin {
        beeBurnedForSynthBei = value;
    }

    function setBeeBurnedForSynthJing(uint256 value) public onlyWhitelistAdmin {
        beeBurnedForSynthJing = value;
    }

    function setBeeBurnedForSynthHuan(uint256 value) public onlyWhitelistAdmin {
        beeBurnedForSynthHuan = value;
    }

    function setBeeBurnedForSynthYing(uint256 value) public onlyWhitelistAdmin {
        beeBurnedForSynthYing = value;
    }

    function setBeeBurnedForSynthNi(uint256 value) public onlyWhitelistAdmin {
        beeBurnedForSynthNi = value;
    }

    function setBeiCountForSynth(uint256 value) public onlyWhitelistAdmin {
        beiCountForSynthJing = value;
    }

    function setJingCountForSynth(uint256 value) public onlyWhitelistAdmin {
        jingCountForSynthHuan = value;
    }

    function setHuanCountForSynth(uint256 value) public onlyWhitelistAdmin {
        huanCountForSynthYing = value;
    }

    function setYingCountForSynth(uint256 value) public onlyWhitelistAdmin {
        yingCountForSynthNi = value;
    }

    function setEnergy(address _energy) public onlyWhitelistAdmin {
        energy = _energy;
    }

    function setBee(address _bee) public onlyWhitelistAdmin {
        bee = _bee;
    }

    function setUSDT(address _usdt) public onlyWhitelistAdmin {
        usdt = _usdt;
    }

    function addWhitelistAdmin(address account) public onlyOwner {
        _addWhitelistAdmin(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseTokenURI) public onlyWhitelistAdmin {
        _baseTokenURI = baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!exists(tokenId)) {
            return "";
        }

        uint256 tokenType = getType(tokenId);
        uint256 attribute = getAttribute(tokenId);
        string memory baseURIx = _baseURI();
        return bytes(baseURIx).length > 0 ? string(abi.encodePacked(baseURIx, tokenType.toString(), "/", attribute.toString(), ".json")) : "";
    }

    function getNextTokenId() internal returns (uint256 id) {
        id = nextTokenId;
        nextTokenId = nextTokenId.add(1);
    }

    function randomAttribute() internal returns (uint256) {
        uint256 balance = IBEP20(energy).balanceOf(address(this));
        uint256 random =  uint256(keccak256(abi.encodePacked(block.timestamp, balance, seed++)));
        return (random % 4) + 1;
    }

    function openBlindBox() public nonReentrant returns (uint256 tokenId, uint256 tokenAttribute) {
        address sender = _msgSender();
        // 1. transfer 100 energy
//        TransferHelper.safeTransferFrom(energy, sender, fixedWallet, blindBoxPrice);

        // 2. open blind box
        // mint
        tokenId = getNextTokenId();
        _safeMint(sender, tokenId);

        // set type and attribute
        tokenAttribute = randomAttribute();
        setType(tokenId, uint256(TokenType.SIMPLE));
        setAttribute(tokenId, tokenAttribute);
    }

    function canSynthBei(address owner) public view returns (bool can) {
        bool gold;
        bool wood;
        bool water;
        bool soil;
        bool fire;

        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            uint256 attribute = getAttribute(id);
            if (attribute == uint256(TokenAttribute.GOLD)) {
                gold = true;
            } else if (attribute == uint256(TokenAttribute.WOOD)) {
                wood = true;
            } else if (attribute == uint256(TokenAttribute.WATER)) {
                water = true;
            } else if (attribute == uint256(TokenAttribute.SOIL)) {
                soil = true;
            } else if (attribute == uint256(TokenAttribute.FIRE)) {
                fire = true;
            }
        }
        return (gold && wood && water && soil && fire);
    }

    function canSynthJing(address owner) public view returns (bool can) {
        uint256 beiCount;

        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            uint256 tp = getType(id);
            if (tp == uint256(TokenType.BEI)) {
                beiCount++;
            }
        }
        return (beiCount >= beiCountForSynthJing);
    }

    function canSynthHuan(address owner) public view returns (bool can) {
        uint256 jingCount;

        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            uint256 tp = getType(id);
            if (tp == uint256(TokenType.JING)) {
                jingCount++;
            }
        }
        return (jingCount >= jingCountForSynthHuan);
    }

    function canSynthYing(address owner) public view returns (bool can) {
        uint256 huanCount;

        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            uint256 tp = getType(id);
            if (tp == uint256(TokenType.HUAN)) {
                huanCount++;
            }
        }
        return (huanCount >= huanCountForSynthYing);
    }

    function canSynthNi(address owner) public view returns (bool can) {
        uint256 yingCount;

        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            uint256 tp = getType(id);
            if (tp == uint256(TokenType.YIING)) {
                yingCount++;
            }
        }
        return (yingCount >= yingCountForSynthNi);
    }

    function synthBei() public returns (uint256 tokenId) {
        address sender = _msgSender();
        bool gold;
        bool wood;
        bool water;
        bool soil;
        bool fire;

        uint256 balance = balanceOf(sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(sender, i);
            uint256 attribute = getAttribute(id);
            if (attribute == uint256(TokenAttribute.GOLD) && !gold) {
                _burn(id);
                gold = true;
            } else if (attribute == uint256(TokenAttribute.WOOD) && !wood) {
                _burn(id);
                wood = true;
            } else if (attribute == uint256(TokenAttribute.WATER) && !water) {
                _burn(id);
                water = true;
            } else if (attribute == uint256(TokenAttribute.SOIL) && !soil) {
                _burn(id);
                soil = true;
            } else if (attribute == uint256(TokenAttribute.FIRE) && !fire) {
                _burn(id);
                fire = true;
            }
        }

        require(gold && wood && water && soil && fire, "synth bei not qualified");

        // transfer bee
        TransferHelper.safeTransferFrom(bee, sender, fixedWallet, beeBurnedForSynthBei);

        // mint bei
        tokenId = getNextTokenId();
        _safeMint(sender, tokenId);
        // set type
        setType(tokenId, uint256(TokenType.BEI));
    }

    function synthJing() public returns (uint256 tokenId) {
        address sender = _msgSender();
        uint256 beiCount = beiCountForSynthJing;
        uint256 balance = balanceOf(sender);
        for (uint256 i = 0; i < balance && beiCount > 0; i++) {
            uint256 id = tokenOfOwnerByIndex(sender, i);
            if (uint256(TokenType.BEI) == getType(id)) {
                _burn(id);
                beiCount--;
            }
        }
        require(beiCount == 0, "synth jing not qualified");

        // transfer bee
        TransferHelper.safeTransferFrom(bee, sender, fixedWallet, beeBurnedForSynthJing);

        // mint bei
        tokenId = getNextTokenId();
        _safeMint(sender, tokenId);
        // set type
        setType(tokenId, uint256(TokenType.JING));
    }

    function synthHuan() public returns (uint256 tokenId) {
        address sender = _msgSender();
        uint256 jingCount = jingCountForSynthHuan;
        uint256 balance = balanceOf(sender);
        for (uint256 i = 0; i < balance && jingCount > 0; i++) {
            uint256 id = tokenOfOwnerByIndex(sender, i);
            if (uint256(TokenType.JING) == getType(id)) {
                _burn(id);
                jingCount--;
            }
        }
        require(jingCount == 0, "synth huan not qualified");

        // transfer bee
        TransferHelper.safeTransferFrom(bee, sender, fixedWallet, beeBurnedForSynthHuan);

        // mint bei
        tokenId = getNextTokenId();
        _safeMint(sender, tokenId);
        // set type
        setType(tokenId, uint256(TokenType.HUAN));
    }

    function synthYing() public returns (uint256 tokenId) {
        address sender = _msgSender();
        uint256 huanCount = huanCountForSynthYing;
        uint256 balance = balanceOf(sender);
        for (uint256 i = 0; i < balance && huanCount > 0; i++) {
            uint256 id = tokenOfOwnerByIndex(sender, i);
            if (uint256(TokenType.HUAN) == getType(id)) {
                _burn(id);
                huanCount--;
            }
        }
        require(huanCount == 0, "synth ying not qualified");

        // transfer bee
        TransferHelper.safeTransferFrom(bee, sender, fixedWallet, beeBurnedForSynthYing);

        // mint bei
        tokenId = getNextTokenId();
        _safeMint(sender, tokenId);
        // set type
        setType(tokenId, uint256(TokenType.YIING));
    }

    function synthNi() public returns (uint256 tokenId) {
        address sender = _msgSender();
        uint256 yingCount = yingCountForSynthNi;
        uint256 balance = balanceOf(sender);
        for (uint256 i = 0; i < balance && yingCount > 0; i++) {
            uint256 id = tokenOfOwnerByIndex(sender, i);
            if (uint256(TokenType.YIING) == getType(id)) {
                _burn(id);
                yingCount--;
            }
        }
        require(yingCount == 0, "synth ni not qualified");

        // transfer bee
        TransferHelper.safeTransferFrom(bee, sender, fixedWallet, beeBurnedForSynthNi);

        // mint bei
        tokenId = getNextTokenId();
        _safeMint(sender, tokenId);
        // set type
        setType(tokenId, uint256(TokenType.NI));
    }

    function canSynth(address owner) public view returns (bool bei, bool jing, bool huan, bool ying, bool ni) {
        bei = canSynthBei(owner);
        jing = canSynthJing(owner);
        huan = canSynthHuan(owner);
        ying = canSynthYing(owner);
        ni = canSynthNi(owner);
    }

    function synth(uint256 tp) public returns (uint256) {
        if (tp == uint256(TokenType.BEI)) {
            return synthBei();
        } else if (tp == uint256(TokenType.JING)) {
            return synthJing();
        } else if (tp == uint256(TokenType.HUAN)) {
            return synthHuan();
        } else if (tp == uint256(TokenType.YIING)) {
            return synthYing();
        } else if (tp == uint256(TokenType.NI)) {
            return synthNi();
        }
        return 0;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function adminMint(address to, uint256 tp) public onlyWhitelistAdmin returns (uint256 tokenId) {
        tokenId = getNextTokenId();
        _safeMint(to, tokenId);
        setType(tokenId, tp);
    }

    function getEnergyFuwa(address owner) public view returns (uint256 tokenId) {
        uint256 balance = balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            if (uint256(TokenType.ENERGY) == getType(id)) {
                tokenId = id;
                break;
            }
        }
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!(owner|approved)");
        _burn(tokenId);
    }

    function getType(uint256 tokenId) public view returns (uint256) {
        return typeMapping[tokenId];
    }

    function getAttribute(uint256 tokenId) public view returns (uint256) {
        return attirbuteMapping[tokenId];
    }

    function getTokenEnergy(uint256 tokenId) public view returns (uint256) {
        return energyMapping[tokenId];
    }

    // returns (uint256[] tokenIds, uint256[] tokenTypes,  uint256[] tokenAttributes, uint256[] tokenEnergies)
    function getTokens(address owner) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory tokenTypes = new uint256[](balance);
        uint256[] memory tokenAttributes = new uint256[](balance);
        uint256[] memory tokenEnergies = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            tokenIds[i] = id;
            tokenTypes[i] = getType(id);
            tokenAttributes[i] = getAttribute(id);
            tokenEnergies[i] = getTokenEnergy(id);
        }
        return (tokenIds, tokenTypes, tokenAttributes, tokenEnergies);
    }

    function setTokenType(uint256 tokenId, uint256 tp) public onlyWhitelistAdmin {
        setType(tokenId, tp);
    }

    function setTokenAttribute(uint256 tokenId, uint256 attr) public onlyWhitelistAdmin {
        setAttribute(tokenId, attr);
    }

    function setType(uint256 tokenId, uint256 tp) internal {
        typeMapping[tokenId] = tp;
    }

    function setAttribute(uint256 tokenId, uint256 attr) internal {
        attirbuteMapping[tokenId] = attr;
    }

    function setTokenEnergy(uint256 tokenId, uint256 value) public onlyWhitelistAdmin {
        energyMapping[tokenId] = value;
    }

    function withdrawBEE(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(bee, owner(), amount);
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(usdt, owner(), amount);
    }

    function withdrawTRX(uint256 amount) public onlyOwner {
        TransferHelper.safeTransferTRX(owner(), amount);
    }
    ////////////////////////////////////////////////////
}