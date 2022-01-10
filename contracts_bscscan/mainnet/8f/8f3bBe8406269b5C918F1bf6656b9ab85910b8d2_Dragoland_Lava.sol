// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";

contract Dragoland_Lava is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct FeePair {
        uint256 fee;
        address receiver;
    }

    bool public saleEnabled_;
    uint256 public price;
    address public collateral;

    mapping(uint256 => FeePair) public feeMap;

    function initialize() public initializer {
        __ERC20_init("Dragoland_Lava", "Dragoland_Lava");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        setup();
    }

    function setup() public onlyOwner {
        saleEnabled_ = true;
        price = 250;
        //$DRAGO Token - The Native Token To Dragoland.io
        collateral = address(0x3D87f8923c3a16c5AB5D460ffA548418b58d9Fd8);
        _mint(msg.sender, 1 * 10**decimals());

        //A-Play2Earn Rewards Ecosystem
        feeMap[1].receiver = 0x3D87f8923c3a16c5AB5D460ffA548418b58d9Fd8; //To Rewards Ecosystem Contract
        feeMap[1].fee = 50;
        //B-Liquidity Pool - Sustainability 
        feeMap[2].receiver = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00; //Temporary Address For Deployment
        feeMap[2].fee = 40;
        //C-Developer & Team Funding 
        feeMap[3].receiver = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00; //DevelopersWallet
        feeMap[3].fee = 3;
        //D-Marketing Funding
        feeMap[4].receiver = 0xCD45fAd7f03067d3d03Ea4fbfC73fE1C09D25d57; //MarketingWallet
        feeMap[4].fee = 6;
        //E-Spare In Case Of Future Need
        feeMap[5].receiver = 0x8d96E9678d2Fae750f4e0c50a82160359e31EF00; //Doesn't Apply
        feeMap[5].fee = 0;
        //F-Burn Address
        feeMap[6].receiver = address(0xdEaD); //Burned
        feeMap[6].fee = 1;
    }

    function getImplementation() public virtual returns (address) {
        return super._getImplementation();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }



    function saleEnabled(bool status) public onlyOwner {
        saleEnabled_ = status;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setCollateral(address collateralAddress) public onlyOwner {
        collateral = collateralAddress;
    }

    function getCollateral() public view returns (address) {
        return collateral;
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

    function Buy(address buyer, uint256 amount) public {
        uint256 totalBuy = amount.mul(price);
        IERC20 collateralToken = IERC20(collateral);
        uint256 senderBalance = collateralToken.balanceOf(buyer);
        uint256 allowance = collateralToken.allowance(buyer, address(this));

        require(saleEnabled_, "Sales disabled");
        require(senderBalance >= totalBuy, "Insuficient collateral");
        require(allowance >= totalBuy, "Insuficient collateral allowance");

        collateralToken.transferFrom(
            buyer,
            feeMap[1].receiver,
            (totalBuy.mul(feeMap[1].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[2].receiver,
            (totalBuy.mul(feeMap[2].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[3].receiver,
            (totalBuy.mul(feeMap[3].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[4].receiver,
            (totalBuy.mul(feeMap[4].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[5].receiver,
            (totalBuy.mul(feeMap[5].fee)).div(100)
        );
        collateralToken.transferFrom(
            buyer,
            feeMap[6].receiver,
            (totalBuy.mul(feeMap[6].fee)).div(100)
        );

        _mint(buyer, amount);
    }
}