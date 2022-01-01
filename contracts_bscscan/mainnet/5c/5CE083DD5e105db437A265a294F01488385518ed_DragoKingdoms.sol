// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract DragoKingdoms is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    mapping(uint256 => FeePair) public feeMap;

    struct KingdomProps {
        uint256 typeID;
        string kingdomName;
        uint256 rewardRate;
        uint256 slots;
        address collateral;
        uint256 price;
        bool saleEnabled;
        string fullURI;
    }

    mapping(string => KingdomProps) public bProps;
    mapping(uint256 => string) public typeOfKingdomByNFTId;
    mapping(string => address) public collaterals;
    mapping(uint256 => uint256) public craftedAtBlock;
    mapping(address => mapping(string => uint256)) public balancesbyTypeMap;
    bool public applyTaxes;
    event BuyBuilding(address buyer, address feeReceiver, uint256 price, uint256 nftId);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC721_init("Dragoland_Kingdoms", "DragoKingdoms");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setup();
    }

    function setup() public onlyOwner {
        applyTaxes = true;

        collaterals["Drago"] = address(
            0x70D542e94a70081a15a555eCFA1Ba4BFB9217FBb
        );
        collaterals["Dragoland_Ice"] = address(
            0xc072bA75c2F33835B3122a3db4804Bf2350cD20D
        );
        collaterals["Dragoland_Rock"] = address(
            0xe69e58B8e1359a20227BEAdadb586f95920040d7
        );
        collaterals["Dragoland_DragonFlame"] = address(
            0x4D48d91525f4dED93B275782fAF4F2D5C130E29F
        );
        collaterals["Dragoland_LightningBolt"] = address(
            0x43c41D6072833C5B897Ab7e8e273aa2F3EB15a93
        );
        collaterals["Dragoland_Lava"] = address(
            0x8de5bf99Fb4174C7e36108266003E80286b70d5C
        );
        collaterals["Dragoland_Crystals"] = address(
            0xB57a9dc286E52409d4AF347233bf4EE6E7cee653
        );

        //FireKingdom - Settings
        KingdomProps memory fireKingdom;
        fireKingdom.typeID = 1;
        fireKingdom.kingdomName = "FireKingdom";
        fireKingdom.collateral = collaterals["Dragoland_DragonFlame"];
        fireKingdom.price = 90;
        fireKingdom.slots = 3;
        fireKingdom.saleEnabled = true;
        fireKingdom
            .fullURI = "https://dragoland.io/NFT/firekingdom.json";
        bProps["FireKingdom"] = fireKingdom;

        //WaterKingdom - Settings
        KingdomProps memory waterKingdom;
        waterKingdom.typeID = 2;
        waterKingdom.kingdomName = "WaterKingdom";
        waterKingdom.collateral = collaterals["Dragoland_Ice"];
        waterKingdom.price = 160;
        waterKingdom.slots = 3;
        waterKingdom.saleEnabled = true;
        waterKingdom
            .fullURI = "https://dragoland.io/NFT/waterkingdom.json";
        bProps["WaterKingdom"] = waterKingdom;

        //EarthKingdom - Settings
        KingdomProps memory earthKingdom;
        earthKingdom.typeID = 3;
        earthKingdom.kingdomName = "EarthKingdom";
        earthKingdom.collateral = collaterals["Dragoland_Rock"];
        earthKingdom.price = 300;
        earthKingdom.slots = 3;
        earthKingdom.saleEnabled = true;
        waterKingdom
            .fullURI = "https://dragoland.io/NFT/earthkingdom.json";
        bProps["EarthKingdom"] = earthKingdom;

        //EnergyKingdom - Settings
        KingdomProps memory energyKingdom;
        energyKingdom.typeID = 4;
        energyKingdom.kingdomName = "EnergyKingdom";
        energyKingdom.collateral = collaterals["Dragoland_LightningBolt"];
        energyKingdom.price = 350;
        energyKingdom.slots = 3;
        energyKingdom.saleEnabled = true;
        waterKingdom
            .fullURI = "https://dragoland.io/NFT/energykingdom.json";
        bProps["EnergyKingdom"] = energyKingdom;


        //DarknessKingdom - Settings
        KingdomProps memory darknessKingdom;
        darknessKingdom.typeID = 5;
        darknessKingdom.kingdomName = "DarknessKingdom";
        darknessKingdom.collateral = collaterals["Dragoland_Lava"];
        darknessKingdom.price = 400;
        darknessKingdom.slots = 3;
        darknessKingdom.saleEnabled = true;
        waterKingdom
            .fullURI = "https://dragoland.io/NFT/darknesskingdom.json";
        bProps["DarknessKingdom"] = darknessKingdom;


        //LightKingdom - Settings
        KingdomProps memory lightKingdom;
        lightKingdom.typeID = 6;
        lightKingdom.kingdomName = "LightKingdom";
        lightKingdom.collateral = collaterals["Dragoland_Crystals"];
        lightKingdom.price = 999;
        lightKingdom.slots = 3;
        lightKingdom.saleEnabled = true;
        waterKingdom
            .fullURI = "https://dragoland.io/NFT/lightkingdom.json";
        bProps["LightKingdom"] = lightKingdom;


        //1-Play2Earn
        feeMap[1].receiver = 0x70D542e94a70081a15a555eCFA1Ba4BFB9217FBb;
        feeMap[1].fee = 50;
        //2-Liquidity
        feeMap[2].receiver = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00;
        feeMap[2].fee = 47;
        //3-Developers
        feeMap[3].receiver = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00;
        feeMap[3].fee = 0;
        //4-Marketing
        feeMap[4].receiver = 0xCD45fAd7f03067d3d03Ea4fbfC73fE1C09D25d57;
        feeMap[4].fee = 0;
        //5-Spare
        feeMap[5].receiver = 0x70D542e94a70081a15a555eCFA1Ba4BFB9217FBb;
        feeMap[5].fee = 1;
        //6-Burn
        feeMap[6].receiver = address(0xdEaD);
        feeMap[6].fee = 1;

    }

    function setKingdomProps(
        uint256 typeID,
        string memory kingdomName,
        uint256 rewardRate,
        uint256 slots,
        address collateral,
        uint256 price,
        bool isOnSale,
        string memory fullURI
    ) public onlyOwner {
        KingdomProps memory building;
        building.typeID = typeID;
        building.rewardRate = rewardRate;
        building.kingdomName = kingdomName;
        building.collateral = collateral;
        building.price = price;
        building.slots = slots;
        building.saleEnabled = isOnSale;
        building.fullURI = fullURI;
        bProps[kingdomName] = building;
    }

    function transferFrom(address from,address to,uint256 tokenId) public override (ERC721Upgradeable) {
        balancesbyTypeMap[from][typeOfKingdomByNFTId[tokenId]] -= 1;
        balancesbyTypeMap[to][typeOfKingdomByNFTId[tokenId]] += 1;
        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // function Mint(address to, string memory kingdomName) internal {
    //     uint256 currentNFTId = _tokenIdCounter.current();
    //     balancesbyTypeMap[to][kingdomName]++;
    //     craftedAtBlock[currentNFTId] = block.number;
    //     typeOfKingdomByNFTId[currentNFTId] = kingdomName;
    //     _setTokenURI(currentNFTId, bProps[kingdomName].fullURI);
    //     _mint(to, currentNFTId);
    //     _tokenIdCounter.increment();
    // }

    function setBuiltBlock(uint256 blockNumber, uint256 buildingID)
        public
        onlyOwner
    {
        craftedAtBlock[buildingID] = blockNumber;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //Our methods
    function saleEnabled(string memory kingdomName, bool status)
        public
        onlyOwner
    {
        bProps[kingdomName].saleEnabled = status;
    }

    function setPrice(string memory kingdomName, uint256 price_)
        public
        onlyOwner
    {
        bProps[kingdomName].price = price_;
    }

    function setCollateral(
        string memory kingdomName,
        address collateralAddress
    ) public onlyOwner {
        bProps[kingdomName].collateral = collateralAddress;
    }

    function setP2E(address addr, uint256 fee) public onlyOwner {
        feeMap[1].receiver = addr;
        feeMap[1].fee = fee;
    }

    function getP2E() public view virtual returns (address, uint256) {
        return (feeMap[1].receiver, feeMap[1].fee);
    }

    function setLiquidityFee(address addr, uint256 fee) public onlyOwner {
        feeMap[2].receiver = addr;
        feeMap[2].fee = fee;
    }

    function setMarketingFee(address addr, uint256 fee) public onlyOwner {
        feeMap[4].receiver = addr;
        feeMap[4].fee = fee;
    }

    function setDevelopersFee(address addr, uint256 fee) public onlyOwner {
        feeMap[3].receiver = addr;
        feeMap[3].fee = fee;
    }

    function setGameEcosysFee(address addr, uint256 fee) public onlyOwner {
        feeMap[5].receiver = addr;
        feeMap[5].fee = fee;
    }

    function setBurnFee(address addr, uint256 fee) public onlyOwner {
        feeMap[6].receiver = addr;
        feeMap[6].fee = fee;
    }

    function balanceOf(string memory buildingTypeName, address own)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            own != address(0),
            "ERC721: balance query for the zero address"
        );
        uint256 value = balancesbyTypeMap[own][buildingTypeName];
        return value;
    }
    function getTypeIDByNftID(uint256 nftID) public view returns (uint256 typeID) {
        return bProps[typeOfKingdomByNFTId[nftID]].typeID;
    }
    function Buy(string memory kingdomName) public {
        address buyer = address(msg.sender);
        uint256 price = bProps[kingdomName].price;
        IERC20 collateralToken = IERC20(bProps[kingdomName].collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(bProps[kingdomName].saleEnabled, "Sales of are disabled");
        require(senderBalance >= price, "Insuficient collateral");
        require(allowance >= price, "Insuficient collateral allowance");
        
        collateralToken.transferFrom(buyer, feeMap[1].receiver, price); 
        //Mint
        uint256 currentNFTId = _tokenIdCounter.current();
        balancesbyTypeMap[buyer][kingdomName]++;
        craftedAtBlock[currentNFTId] = block.number;
        typeOfKingdomByNFTId[currentNFTId] = kingdomName;
        _mint(buyer, currentNFTId);
        _setTokenURI(currentNFTId, bProps[kingdomName].fullURI);
        emit BuyBuilding(buyer, feeMap[1].receiver, price, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    // if(applyTaxes){
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[1].receiver,
    //         (price.mul(feeMap[1].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[2].receiver,
    //         (price.mul(feeMap[2].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[3].receiver,
    //         (price.mul(feeMap[3].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[4].receiver,
    //         (price.mul(feeMap[4].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[5].receiver,
    //         (price.mul(feeMap[5].fee)).div(100)
    //     );
    //     collateralToken.transferFrom(
    //         buyer,
    //         feeMap[6].receiver,
    //         (price.mul(feeMap[6].fee)).div(100)
    //     );
    //     Mint(buyer, kingdomName);
    // }
    // else
    // {
    }
}