// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IDrago.sol";
import "./IOldDragoland_NFT.sol";
import "./IDragoLandV2.sol";
import "./IDragoFarm.sol";

contract Dragoland_NFT is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC721_init("Dragoland_NFT", "Dragoland_NFT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        mintPrice = 75000; // 75,000 Drago Tokens
        growPrice = 1; //1 Dragon Breath
        evolvePrice = 1; // 1 Life Elixir
        DragoAddr = 0x3D87f8923c3a16c5AB5D460ffA548418b58d9Fd8;
        wDragoAddr = 0x3D87f8923c3a16c5AB5D460ffA548418b58d9Fd8;
        DragonBreathAddr = 0xf712045412142eBefb527F2a26E33530d3071195;
        LifeElixirAddr = 0xED443dD1c649c532001B85aadE62b7Eb2dEe157C;
        DragonFlameAddr = 0x36BD12EdD7e4224016C05abdB5193D2d3206F958;
        RockAddr = 0x00D86cCE1debE1ceA37383e65bbd46e9c43217cf;
        IceAddr = 0x172cf969456b9172cEc6cfab8f2C21E5647C7549;
        LightningBoltAddr = 0xdFdaCDd8193Ae7cB6519E3b3A35BAc9515F4056b;
        LavaAddr = 0x8f3bBe8406269b5C918F1bf6656b9ab85910b8d2;
        CrystalsAddr = 0xEe4feaB6828228A83e0e8e6c6c2f0D754e1c7B64;
        liquidityWallet = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00;
        devWallet = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00;
        marketingWallet = 0xCD45fAd7f03067d3d03Ea4fbfC73fE1C09D25d57;
        rewardsEcosystemContract = 0x3D87f8923c3a16c5AB5D460ffA548418b58d9Fd8;
        oldDragos = 0x0a3Ce613066166b1Da65FffAB33702Bba186F27c;
    }

    uint256 public mintPrice;
    uint256 public growPrice;
    uint256 public evolvePrice;
    address public bnbAddr;
    address public DragoAddr;
    address public wDragoAddr;
    address public DragonBreathAddr;
    address public LifeElixirAddr;
    address public DragonFlameAddr;
    address public RockAddr;
    address public IceAddr;
    address public LavaAddr;
    address public CrystalsAddr;
    address public LightningBoltAddr;
    address public pancakeAddr;
    address public liquidityWallet;
    address public devWallet;
    address public marketingWallet;
    address public rewardsEcosystemContract;
    // Enums
    enum Level {
        MysteryEgg,
        FireEgg,
        WaterEgg,
        EarthEgg,
        FireDrago,
        WaterDrago,
        EarthDrago,
        EnergyEgg,
        DarknessEgg,
        LightEgg,
        EnergyDrago,
        DarknessDrago,
        LightDrago
    }
    // Structs
    struct DragoNFT {
        uint256 idx;
        uint256 id;
        Level level;
        uint256 age; 
        string edition; 
        uint256 bornAt;
        bool onSale;
        uint256 price;
    }
    DragoNFT[] public dragosnft;
    // Maps
    mapping(uint256 => string) public tokenIdToName;
    // Events
    event NftBought(address _seller, address _buyer, uint256 _price);
    mapping(uint256 => uint256) public typeOfDragoById;
    address oldDragos;
    address dragosEcosystem;
    mapping(uint256 => uint256) public deltaStack;
    //DragoFarm Address
    address public dragoFarmAddress;
    //DragoNFTID => Won battles
    mapping(uint256 => uint256) public winsByNftId;
    //DragoNFTID => Total Fights
    mapping(uint256 => uint256) public totalBattlesByNftId;

    //Safe Zone --
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Setters
    function setMintPrice(uint256 mp) public onlyOwner {
        mintPrice = mp;
    }

    function setGrowPrice(uint256 gp) public onlyOwner {
        growPrice = gp;
    }

    function setEvolvePrice(uint256 ep) public onlyOwner {
        evolvePrice = ep;
    }

    function setDragoAddr(address aa) public onlyOwner {
        DragoAddr = aa;
    }

    function setWDragoAddr(address waa) public onlyOwner {
        wDragoAddr = waa;
    }

    function setDragonBreathAddr(address ba) public onlyOwner {
        DragonBreathAddr = ba;
    }

    function setLiquidityWallet(address lw) public onlyOwner {
        liquidityWallet = lw;
    }

    function setDevWallet(address dw) public onlyOwner {
        devWallet = dw;
    }

    function setMarketingWallet(address mw) public onlyOwner {
        marketingWallet = mw;
    }

    function setrewardsEcosystemContract(address rw) public onlyOwner {
        rewardsEcosystemContract = rw;
    }

    // Mystery Egg Growth & Rarity - Math Logic
    function getRandomLevel(uint256 seed) private pure returns (Level) {
        uint256 spinResult = seed % 100;
    if (spinResult >= 0 && spinResult <= 3) { //3% Rarity - Light Egg
      return Level.LightEgg;
    } else if (spinResult >= 4 && spinResult <= 12) { //9% Rarity - Darkness Egg
      return Level.DarknessEgg;
    }  else if (spinResult >= 13 && spinResult <= 25) { //13% Rarity - Energy Egg
      return Level.EnergyEgg;
    }  else if (spinResult >= 26 && spinResult <= 40) { //15% Rarity - Earth Egg
      return Level.EarthEgg;
    }  else if (spinResult >= 41 && spinResult <= 65) { //25% Rarity - Water Egg 
      return Level.WaterEgg;
    } else {
      return Level.FireEgg; //35% Rarity - Fire Egg
    }
    }

    function intToLevel(uint256 num) private pure returns (Level) {
    if (num == 1) {
      return Level.FireEgg;
    } else if (num == 2) {
      return Level.WaterEgg;
    } else if (num == 3) {
      return Level.EarthEgg;
    } else if (num == 4) {
      return Level.FireDrago;
    } else if (num == 5) {
      return Level.WaterDrago;
    } else if (num == 6) {
      return Level.EarthDrago;
    }  else if (num == 7) {
      return Level.EnergyEgg;
    }  else if (num == 8) {
      return Level.DarknessEgg;
    }  else if (num == 9) {
      return Level.LightEgg;
    }  else if (num == 10) {
      return Level.EnergyDrago;
    }  else if (num == 11) {
      return Level.DarknessDrago;
    }  else if (num == 12) {
      return Level.LightDrago;
    } else {
      return Level.MysteryEgg;
    }
  }

    function manualMint(
        string memory _name,
        string memory _tokenURI,
        uint256 _level,
        uint256 _age,
        string memory _edition,
        address _owner
    ) public {
        require(address(msg.sender) == devWallet, "no dev wallet");
        uint256 idx = dragosnft.length;
        uint256 id = idx + 1;
        Level level = intToLevel(_level);
        DragoNFT memory _toCreate = DragoNFT(
            idx,
            id,
            level,
            _age,
            _edition,
            block.timestamp,
            false,
            0
        );
        dragosnft.push(_toCreate);
        tokenIdToName[id] = _name;
        _mint(_owner, id);
        _setTokenURI(id, _tokenURI);
        typeOfDragoById[id] = _level;
    }
    function setURI(uint256 dragoNftId, string memory newURI) public {
        require((_msgSender() == this.owner()) || (_msgSender() == dragoFarmAddress),
                "setURI: Owner failed");
        _setTokenURI(dragoNftId, newURI);
    }
    function mintWithFee(string memory _name, string memory _tokenURI) public {
        address deadWallet = 0x000000000000000000000000000000000000dEaD;
        IDrago Drago = IDrago(wDragoAddr);
        address senderAddr = address(msg.sender);
        uint256 senderBalance = Drago.balanceOf(senderAddr);
        uint256 allowance = Drago.allowance(senderAddr, address(this));
        require(senderBalance >= mintPrice, "not enough balance");
        require(allowance >= mintPrice, "not enough allowance");

        Drago.transferFrom(senderAddr, wDragoAddr, (mintPrice * Drago.totalFees() / 100));
        uint256 mintPriceAux = mintPrice;
        mintPriceAux = mintPriceAux - (mintPriceAux * Drago.totalFees() / 100);

        uint256 half = mintPriceAux / 2;
        uint256 otherHalf = mintPriceAux - half;
        uint256 onePercent = mintPriceAux / 100;
        uint256 restOtherHalf = otherHalf - onePercent;
        // // send one percent to burn
        Drago.transferFrom(senderAddr, deadWallet, onePercent);
        // // send 49% to rewards ecosystem contract
        Drago.transferFrom(senderAddr, rewardsEcosystemContract, restOtherHalf);
        // // send 50% to liquidity
        Drago.transferFrom(senderAddr, liquidityWallet, half);

        // Metadatos
        uint256 idx = dragosnft.length;
        uint256 id = idx + 1;
        DragoNFT memory _toCreate = DragoNFT(
            idx,
            id,
            Level.MysteryEgg,
            0,
            "FireEgg",
            block.timestamp,
            false,
            0
        );
        tokenIdToName[id] = _name;
        dragosnft.push(_toCreate);
        _mint(msg.sender, id);
        _setTokenURI(id, _tokenURI);
        typeOfDragoById[id] = 0;
    }

    function grow(uint256 _tokenIdx) public {
        address deadWallet = address(
            0x000000000000000000000000000000000000dEaD
        );
        IDrago Dragoland_DragonBreath = IDrago(DragonBreathAddr);
        address dragoNFTAddr = address(this);
        address senderAddr = address(msg.sender);
        uint256 tokenId = _tokenIdx + 1;
        uint256 senderBalance = Dragoland_DragonBreath.balanceOf(senderAddr);
        uint256 allowance = Dragoland_DragonBreath.allowance(senderAddr, dragoNFTAddr);

        require(senderAddr == ownerOf(tokenId), "not owner");
        require(senderBalance >= growPrice, "not enough balance");
        require(allowance >= growPrice, "not enough allowance");

        DragoNFT memory current = dragosnft[_tokenIdx];
        require(current.level == Level.MysteryEgg, "not a mystery egg");

        current.level = getRandomLevel(block.timestamp);
        dragosnft[_tokenIdx] = current;

        Dragoland_DragonBreath.transferFrom(senderAddr, deadWallet, growPrice);
        typeOfDragoById[tokenId] = uint256(current.level);
    }

    function getOwned() public view returns (uint256[] memory) {
        uint256 cantOwned = balanceOf(msg.sender);
        uint256[] memory result = new uint256[](cantOwned);
        for (uint256 index = 0; index < cantOwned; index++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, index);
            result[index] = tokenId;
        }
        return result;
    }

    function listToSell(uint256 _idx, uint256 _price) public {
        IDragoFarm farmLandInstance = IDragoFarm(dragoFarmAddress);
        DragoNFT memory current = dragosnft[_idx];
        require(farmLandInstance.dragoNFTOwnerAddress(current.id) == address(0x000), "drago is stacked");
        address blockChainOwner = ownerOf(current.id);
        require(msg.sender == blockChainOwner, "not owner");
        require(_price > 0, "price is zero");

        current.onSale = true;
        current.price = _price;
        dragosnft[_idx] = current;
    }

    function withdrawFromSell(uint256 _idx) public {
        DragoNFT memory current = dragosnft[_idx];
        address blockChainOwner = ownerOf(current.id);
        require(msg.sender == blockChainOwner, "not owner");
        require(current.onSale == true, "not on sale");

        current.onSale = false;
        current.price = 0;
        dragosnft[_idx] = current;
    }

    function buy(uint256 _tokenId) public {
        IDrago Drago = IDrago(wDragoAddr);
        address buyerAddr = address(msg.sender);
        address dragoNFTAddr = address(this);
        uint256 buyerBalance = Drago.balanceOf(buyerAddr);
        uint256 allowance = Drago.allowance(buyerAddr, dragoNFTAddr);
        uint256 _idx = _tokenId - 1;
        DragoNFT memory current = dragosnft[_idx];
        uint256 price = current.price;
        require(current.onSale == true, "not on sale");
        require(buyerBalance >= price, "not enough balance");
        require(allowance >= price, "not enough allowance");
        address initialOwner = ownerOf(_tokenId);

        // remove it from sales list
        current.onSale = false;
        current.price = 0;
        dragosnft[_idx] = current;

        _transfer(initialOwner, buyerAddr, _tokenId);
        
        Drago.transferFrom(buyerAddr, wDragoAddr, (price * Drago.totalFees() / 100));
        Drago.transferFrom(buyerAddr, initialOwner, (price - (price * Drago.totalFees() / 100)));
    }

    function migrate(uint256 _tokenId) public {}

    function setTypeOfDragoNFTById(uint256 id, uint256 typeId) public onlyOwner {
        typeOfDragoById[id] = typeId;
    }

    function getTypeIdByNftId(uint256 tokenId) public view returns (uint256) {
        uint256 idx = tokenId - 1;
        DragoNFT memory current = dragosnft[idx];

        return uint256(current.level);
    }

    function setDragoUriByNftId(uint256 nftID, string memory jsonURL)
        public
        onlyOwner
    {
        _setTokenURI(nftID - 1, jsonURL);
    }
    function setDragoFarmAddress(address add) public onlyOwner {
        dragoFarmAddress = add;
    }
    function setLevel(uint256 nftID, uint256 lvl) public {
        require(
                address(msg.sender) == this.owner() ||
                msg.sender == dragosEcosystem ||
                msg.sender == dragoFarmAddress,
            "Owner required"
        );
        dragosnft[nftID - 1].level = Level(lvl);
        typeOfDragoById[nftID] = lvl;
    }

    function getLevel(uint256 nftID) public view returns (uint256) {
        return uint256(dragosnft[nftID - 1].level);
    }
    function isDragoNFTOnSale(uint256 nftID) public view returns (bool) {
        return dragosnft[nftID - 1].onSale;
    }

    function setDeltaStack(uint256 nftID, uint256 delta) public {
        require(
                    address(msg.sender) == this.owner() ||
                    msg.sender == dragosEcosystem ||
                    msg.sender == dragoFarmAddress,
            "Owner required"
        );
        deltaStack[nftID] = delta;
    }

    function changeDragoName(uint256 tokenId, string memory newName) public onlyOwner {
      tokenIdToName[tokenId] = newName;
    }
}