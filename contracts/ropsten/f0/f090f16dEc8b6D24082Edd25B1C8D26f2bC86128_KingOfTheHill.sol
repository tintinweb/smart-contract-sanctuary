// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./KOTH.sol";

contract KingOfTheHill is Ownable, Pausable {
    using SafeMath for uint256;

    bool public _isStrengthPowerUp;
    bool public _isDefensePowerUp;
    bool public _isAgilityPowerUp;
    KOTH private _koth;
    address public _wallet;
    address public _potOwner;
    uint256 public _percentagePotToBuy;
    uint256 public _percentagePotToSeed;
    uint256 public _strengthBonus; // a percentage
    uint256 public _defenseBonus; // a number
    uint256 public _agilityBonus; // a number
    uint256 public _agilityBuyNbBlockMin;
    uint256 private _nbAgility; // a number
    uint256 public _nbBlocksWinning;
    uint256 private _nbBlockBought;
    uint256 public _pot;
    uint256 public _seed;
    address public _weth;

    address public _kothUniPool;

    constructor(
        address owner,
        address wallet_,
        address koth_,
        address weth_
    ) {
        _pause();
        _koth = KOTH(koth_);
        _weth = weth_;
        _wallet = wallet_;
        _percentagePotToBuy = 1; // percentage
        _percentagePotToSeed = 50; // percentage
        _nbBlocksWinning = 100; // number
        _strengthBonus = 10; // percentage
        _defenseBonus = 2; // number
        _agilityBonus = 1; // number
        _kothUniPool = msg.sender; // WARNING Change this to the KOTH uni pool once created
        transferOwnership(owner);
    }

    modifier onlyPotOwner() {
        require(
            _msgSender() == _potOwner,
            "KingOfTheHill: Only pot owner can buy bonus"
        );
        _;
    }

    modifier onlyNotPotOwner() {
        require(
            _msgSender() != _potOwner,
            "KingOfTheHill: sender mut not be the pot owner"
        );
        _;
    }

    modifier onlyRationalPercentage(uint256 percentage) {
        require(
            percentage >= 0 && percentage <= 100,
            "KingOfTheHill: percentage value is irrational"
        );
        _;
    }

    function percentageToAmount(uint256 amount, uint256 percentage)
        public
        pure
        returns (uint256)
    {
        return amount.mul(percentage).div(100);
    }

    function koth() public view returns (address) {
        return address(_koth);
    }

    function setNbBlocksWinning(uint256 nbBlocks) public onlyOwner() {
        require(nbBlocks > 0, "KingOfTheHill: nbBlocks must be greater than 0");
        _nbBlocksWinning = nbBlocks;
    }

    function remainingBlocks() public view returns (uint256) {
        uint256 blockPassed =
            (block.number).sub(_nbBlockBought).add(
                _nbAgility.mul(_agilityBonus)
            );
        if (_potOwner == address(0)) {
            return _nbBlocksWinning;
        } else if (blockPassed > _nbBlocksWinning) {
            return 0;
        } else {
            return _nbBlocksWinning.sub(blockPassed);
        }
    }

    function hasWinner() public view returns (bool) {
        if (_potOwner != address(0) && remainingBlocks() == 0) {
            return true;
        } else {
            return false;
        }
    }

    function setPercentagePotToBuy(uint256 percentage)
        public
        onlyOwner()
        onlyRationalPercentage(percentage)
    {
        _percentagePotToBuy = percentage;
    }

    function setPercentagePotToSeed(uint256 percentage)
        public
        onlyOwner()
        onlyRationalPercentage(percentage)
    {
        _percentagePotToSeed = percentage;
    }

    function setStrengthBonus(uint256 percentage) public onlyOwner() {
        //require("KingOfTheHill: Irration percentage")
        _strengthBonus = percentage;
    }

    function setDefenseBonus(uint256 percentage) public onlyOwner() {
        _defenseBonus = percentage;
    }

    function setAgilityBonus(uint256 nbBlock) public onlyOwner() {
        _agilityBonus = nbBlock;
    }

    function setAgilityBuyNbBlockMin(uint256 nbBlocks) public onlyOwner() {
        _agilityBuyNbBlockMin = nbBlocks;
    }

    function priceOfPot() public view returns (uint256) {
        uint256 price;
        if (!hasWinner()) {
            uint256 defPenality = 1;
            if (_isDefensePowerUp) {
                defPenality = _defenseBonus;
            }
            price = percentageToAmount(
                _pot,
                _percentagePotToBuy.mul(defPenality)
            );
        } else {
            price = percentageToAmount(_seed, _percentagePotToBuy);
        }
        return price;
    }

    function prize() public view returns (uint256) {
        uint256 strBonus = 0;
        if (_isStrengthPowerUp) {
            strBonus = _strengthBonus;
        }
        return _pot.add(percentageToAmount(_pot, strBonus));
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
     * This function returns the price of KOTH in ETH
     */
    function getKOTHPrice() public view returns (uint256) {
        uint256 ethAmount = IERC20(_weth).balanceOf(_kothUniPool);
        uint256 kothAmount = IERC20(_koth).balanceOf(_kothUniPool);
        return kothAmount.div(ethAmount);
    }

    function buyPot() public payable onlyNotPotOwner() whenNotPaused() {
        require(
            msg.value >= priceOfPot(),
            "KingOfTheHill: Not enough ether for buying pot"
        );
        if (hasWinner()) {
            emit Winner(_potOwner, prize());
            payable(_potOwner).transfer(prize());
            _pot = _seed;
            _seed = 0;
        }
        uint256 toSeed = percentageToAmount(msg.value, _percentagePotToSeed);
        uint256 toPot = msg.value.sub(toSeed);
        _pot = _pot.add(toPot);
        _seed = _seed.add(toSeed);
        _nbBlockBought = block.number;
        _isStrengthPowerUp = false;
        _isDefensePowerUp = false;
        _isAgilityPowerUp = false;
        _nbAgility = 0;
        _potOwner = _msgSender();
        emit Bought(_msgSender());
    }

    function buyStrength() public onlyPotOwner() whenNotPaused() {
        require(
            _isStrengthPowerUp == false,
            "KingOfTheHill: Already bought a strength power up"
        );
        uint256 amount = 0;
        amount = percentageToAmount(
            percentageToAmount(priceOfPot(), _strengthBonus),
            30
        );
        amount = amount * getKOTHPrice();

        _koth.operatorBurn(_msgSender(), amount, "", "");
        _isStrengthPowerUp = true;
    }

    function buyDefense() public onlyPotOwner() whenNotPaused() {
        require(
            _isDefensePowerUp == false,
            "KingOfTheHill: Already bought a defense power up"
        );
        uint256 oldPrice = priceOfPot();
        _isDefensePowerUp = true;
        uint256 newPrice = priceOfPot();
        uint256 amount = percentageToAmount(oldPrice - newPrice, 30);
        amount = amount * getKOTHPrice();
        // _koth.transferFrom(msg.sender, address(this), amount);
        // _koth.burn(amount, "0x0");
        _koth.operatorBurn(_msgSender(), amount, "", "");
    }

    function buyAgility(uint256 nbAgility)
        public
        onlyPotOwner()
        whenNotPaused()
    {
        require(
            _isAgilityPowerUp == false,
            "KingOfTheHill: Already bought an agility power up"
        );
        require(nbAgility > 0, "KingOfTheHill: can not buy 0 agility");
        require(
            remainingBlocks() > (_agilityBonus.mul(nbAgility)).add(3),
            "KingOfTheHill: too many agility power-up"
        );
        _koth.operatorBurn(
            _msgSender(),
            _agilityBonus.mul(nbAgility).mul((10**uint256(_koth.decimals()))),
            "",
            ""
        );
        _nbAgility = nbAgility;
        _isAgilityPowerUp = true;
    }

    function pause() public onlyOwner() {
        _pause();
    }

    function unpause() public onlyOwner() {
        _unpause();
    }

    function withdraw(uint256 amount) public onlyOwner() {
        payable(owner()).transfer(amount);
    }

    receive() external payable {
        _pot = _pot.add(msg.value);
    }

    event Winner(address indexed winner, uint256 amount);
    event Bought(address indexed buyer);
}