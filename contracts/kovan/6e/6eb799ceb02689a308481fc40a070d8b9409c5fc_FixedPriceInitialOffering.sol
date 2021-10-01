/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";


interface FixedPriceInitialOfferingHelpers {
    function mint(address[] memory accounts, uint256[] memory amounts) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address sender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function canEditProperty(address wallet, address property) external view returns (bool);

    function contractBurn(address user, uint256 amount) external returns (bool);

    function cap() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function hasSystemAdminRights(address sender) external view returns (bool);

    function isCPAdminOfProperty(address admin, address property) external view returns (bool);

    function getUserBytesFromWallet(address wallet) external view returns (bytes32);
}

/// @title Fixed Price Initial Offering
contract FixedPriceInitialOffering is Ownable {
    using SafeMath for uint256;

    struct Offering {
        uint256 presaleStart;
        uint256 presaleEnd;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 price;
        uint256 amountCollected;
        uint256 presaleCollected;
        uint256 presaleMaxInvestment;
        uint256 presaleMinInvestment;
        uint256 maxInvestment;
        uint256 minInvestment;
        uint256 softCap;
        address investmentToken;
        address collector;
        address feeCollector;
        uint256 fee;
        bool investmentCollected;
    }

    struct NewOffering {
        uint256 presaleStart;
        uint256 presaleEnd;
        uint256 saleEnd;
        uint256 price;
        uint256 presaleMaxInvestment;
        uint256 presaleMinInvestment;
        uint256 maxInvestment;
        uint256 minInvestment;
        uint256 softCap;
        address investmentToken;
        address collector;
        address feeCollector;
        uint256 fee;
    }

    mapping(address => mapping(address => mapping(uint16 => uint256))) private _userInvestment;
    mapping(address => mapping(bytes32 => mapping(uint16 => uint256))) private _userTotalInvestment;
    mapping(address => mapping(address => mapping(uint16 => uint256))) private _userTokens;
    mapping(address => mapping(address => mapping(uint16 => uint256))) private _userTokensPresale;
    mapping(address => Offering) private _offerings;
    mapping(address => uint16) private _numOfSuccessfulOfferings;

    address private _dataProxy;
    address private _users;

    modifier onlyCPOrAdmin(address admin, address property) {
        require(FixedPriceInitialOfferingHelpers(_dataProxy).canEditProperty(admin, property), "Initial investment: You need to be able to edit property");
        _;
    }

    event Invested(address indexed property, address indexed wallet, address investmentToken, uint256 amountInvested, uint256 amountReceived);
    event InitialOffer(address indexed property, uint256 pricePerToken, uint256 presaleMaxInvestment, uint256 presaleMinInvestment, uint256 maxInvestment, uint256 minInvestment, uint256 softCap, uint256 presaleStart, uint256 presaleEnd, uint256 saleStart, uint256 saleEnd, address investmentCurrency, address collector, address feeCollector, uint256 fee);
    event ClaimInvestment(address indexed property, uint256 amount, uint256 feeAmount);
    event ReturnedInvestment(address indexed proeprty, address wallet, uint256 amount);
    event ReturnedPresaleInvestment(address indexed proeprty, address wallet, uint256 amount);
    event InitialOfferingCanceled(address indexed property);

    constructor(address dataProxy, address users) public {
        _dataProxy = dataProxy;
        _users = users;
    }

    function changeDataProxy(address dataProxy) public onlyOwner {
        _dataProxy = dataProxy;
    }

    function changeUsers(address users) public onlyOwner {
        _users = users;
    }

    /// @notice create or update offering information
    /// @param newOffering Offering information (price and fee support up to 2 decimals for 5% fee enter 500)
    function modifyOfferingInfo(address property, NewOffering memory newOffering) public onlyCPOrAdmin(_msgSender(), property) {
        require(newOffering.softCap.mul(10 ** 9).div(newOffering.price).div(10 ** 7) <= hardCap(property).sub(currentSupply(property)), "InitialInvestment: Soft cap set too high");
        require(newOffering.presaleStart >= block.timestamp, "InitialInvestment: Investment must start in the future");
        require(newOffering.presaleStart <= newOffering.presaleEnd && (newOffering.presaleEnd + 3 days) <= newOffering.saleEnd, "InitialInvestment: Start time must be before end time");
        Offering memory offering = _offerings[property];
        require(offering.presaleStart == 0 || offering.presaleStart > block.timestamp || offering.saleEnd < block.timestamp || offering.investmentCollected, "Initial investment: Offering already set and it started");
        require((offering.amountCollected == 0 && offering.presaleCollected == 0) || offering.investmentCollected, "InitialInvestment: You need to collect investments first");
        offering = Offering(newOffering.presaleStart, newOffering.presaleEnd, newOffering.presaleEnd + 3 days, newOffering.saleEnd, newOffering.price, 0, 0, newOffering.presaleMaxInvestment, newOffering.presaleMinInvestment, newOffering.maxInvestment, newOffering.minInvestment, newOffering.softCap, newOffering.investmentToken, newOffering.collector, newOffering.feeCollector, newOffering.fee, false);
        _offerings[property] = offering;
        emit InitialOffer(property, offering.price, offering.presaleMaxInvestment, offering.presaleMinInvestment, offering.maxInvestment, offering.minInvestment, offering.softCap, offering.presaleStart, offering.presaleEnd, offering.presaleStart + 3 days, offering.saleEnd, offering.investmentToken, offering.collector, offering.feeCollector, offering.fee);
    }

    /// @notice invest ERC-20 token (DAI for example) to receive property token
    /// @param property Property contract address
    /// @param amount Amount of specified token to invest
    function invest(address property, uint256 amount) public {
        Offering memory offering = _offerings[property];
        bytes32 user = FixedPriceInitialOfferingHelpers(_users).getUserBytesFromWallet(_msgSender());
        require(offering.saleStart <= block.timestamp && offering.saleEnd >= block.timestamp, "InitialInvestment: Offering is not active");
        require(amount >= offering.minInvestment, "InitialInvestment: You need to invest more");
        require(_userTotalInvestment[property][user][_numOfSuccessfulOfferings[property]].add(amount) <= offering.maxInvestment, "InitialInvestment: You need to invest less");
        uint256 cap = FixedPriceInitialOfferingHelpers(property).cap();
        uint256 mintAmount = amount.mul(10 ** 9).div(offering.price).div(10 ** 7);
        uint256 currentSupply = FixedPriceInitialOfferingHelpers(property).totalSupply();

        require(currentSupply.add(mintAmount) <= cap, "InitialInvestment: Too many tokens would be minted");
        _offerings[property].amountCollected = offering.amountCollected.add(amount);

        require(FixedPriceInitialOfferingHelpers(offering.investmentToken).transferFrom(_msgSender(), address(this), amount));

        uint256[] memory mAmount = new uint256[](1);
        mAmount[0] = mintAmount;
        address[] memory receiver = new address[](1);
        receiver[0] = _msgSender();
        require(FixedPriceInitialOfferingHelpers(property).mint(receiver, mAmount));
        _userInvestment[property][_msgSender()][_numOfSuccessfulOfferings[property]] = _userInvestment[property][_msgSender()][_numOfSuccessfulOfferings[property]].add(amount);
        _userTokens[property][_msgSender()][_numOfSuccessfulOfferings[property]] = _userTokens[property][_msgSender()][_numOfSuccessfulOfferings[property]].add(mintAmount);
        _userTotalInvestment[property][user][_numOfSuccessfulOfferings[property]] = _userTotalInvestment[property][user][_numOfSuccessfulOfferings[property]].add(amount);
        emit Invested(property, _msgSender(), offering.investmentToken, amount, mintAmount);
    }

    /// @notice collect investment (only if soft cap was reached and the offering closed)
    /// @param property Property contract address
    function collectInvestments(address property) public {
        Offering storage offering = _offerings[property];
        require(offering.softCap <= offering.amountCollected.add(offering.presaleCollected), "InitialInvestment: Soft cap not reached");
        require(offering.saleEnd < block.timestamp || currentSupply(property) == hardCap(property), "InitialInvestment: You need to wait for initial investment to finish");
        uint256 collected = offering.amountCollected;
        offering.amountCollected = 0;
        offering.investmentCollected = true;
        uint256 fee = collected.mul(offering.fee).div(10000);
        collected = collected.sub(fee);
        _numOfSuccessfulOfferings[property] = _numOfSuccessfulOfferings[property] + 1;
        require(FixedPriceInitialOfferingHelpers(_offerings[property].investmentToken).transfer(offering.collector, collected));
        if (fee > 0) {
            require(FixedPriceInitialOfferingHelpers(_offerings[property].investmentToken).transfer(offering.feeCollector, fee));
        }
        emit ClaimInvestment(property, collected, fee);
    }

    /// @notice mint property tokens for presale (done offchain)
    /// @param property Property contract address
    /// @param wallets Array of wallets to which tokens should be minted
    /// @param amounts Array of amounts of how much tokens should be minted
    function mintPresale(address property, address[] memory wallets, uint256[] memory amounts) public {
        require(FixedPriceInitialOfferingHelpers(_dataProxy).isCPAdminOfProperty(_msgSender(), property), "InitialInvestment: You need to be admin");
        Offering storage offering = _offerings[property];
        require(offering.presaleStart <= block.timestamp && block.timestamp <= offering.saleEnd, "InitialInvestment: Can only mint during sale");
        require(FixedPriceInitialOfferingHelpers(property).mint(wallets, amounts));
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            _userTokensPresale[property][wallet][_numOfSuccessfulOfferings[property]] = _userTokensPresale[property][wallet][_numOfSuccessfulOfferings[property]].add(amounts[i]);
            uint256 investment = amounts[i].mul(offering.price).div(100);
            _offerings[property].presaleCollected = offering.presaleCollected.add(investment);
        }
    }

    /// @notice burn presale minted tokens in case soft cap was not reached
    /// @param property Property contract address
    /// @param wallets Array of wallets for which to burn the property tokens
    function returnPresaleInvestment(address property, address[] memory wallets) public onlyCPOrAdmin(msg.sender, property) {
        Offering storage offering = _offerings[property];
        require(offering.saleEnd <= block.timestamp && offering.softCap > offering.amountCollected.add(offering.presaleCollected), "InitialInvestment: Soft cap must not be reached");
        for (uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 userBalance = _userTokensPresale[property][wallet][_numOfSuccessfulOfferings[property]];
            uint256 userInvestment = userBalance.mul(offering.price).div(100);
            _userTokensPresale[property][wallet][_numOfSuccessfulOfferings[property]] = 0;

            require(FixedPriceInitialOfferingHelpers(property).contractBurn(wallet, userBalance));

            _offerings[property].presaleCollected = _offerings[property].presaleCollected.sub(userInvestment);
            emit ReturnedPresaleInvestment(property, wallet, userInvestment);
        }
    }

    function _returnInvestment(address property, address wallet) private {
        bytes32 user = FixedPriceInitialOfferingHelpers(_users).getUserBytesFromWallet(wallet);
        uint256 userBalance = _userTokens[property][wallet][_numOfSuccessfulOfferings[property]];
        uint256 userInvestment = _userInvestment[property][wallet][_numOfSuccessfulOfferings[property]];
        _userInvestment[property][wallet][_numOfSuccessfulOfferings[property]] = 0;
        _userTokens[property][wallet][_numOfSuccessfulOfferings[property]] = 0;
        _userTotalInvestment[property][user][_numOfSuccessfulOfferings[property]] = _userTotalInvestment[property][user][_numOfSuccessfulOfferings[property]].sub(userInvestment);

        require(FixedPriceInitialOfferingHelpers(property).contractBurn(wallet, userBalance));
        require(FixedPriceInitialOfferingHelpers(_offerings[property].investmentToken).transfer(wallet, userInvestment));

        _offerings[property].amountCollected = _offerings[property].amountCollected.sub(userInvestment);
        emit ReturnedInvestment(property, wallet, userInvestment);
    }

    /// @notice return investment in case soft cap was not reached
    /// @param property Property contract address
    /// @param wallets Array of wallets for which to return the investment
    function returnInvestment(address property, address[] memory wallets) public onlyCPOrAdmin(msg.sender, property) {
        Offering storage offering = _offerings[property];
        require(offering.saleEnd <= block.timestamp && offering.softCap > offering.amountCollected.add(offering.presaleCollected), "InitialInvestment: Soft cap must not be reached");
        for (uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            _returnInvestment(property, wallet);
        }
    }


    /// @notice get back investment and burn property token
    /// @param property Property contract address
    function getInvestmentBack(address property) public {
        Offering storage offering = _offerings[property];
        require(offering.saleEnd < block.timestamp && offering.softCap > offering.amountCollected.add(offering.presaleCollected), "InitialInvestment: Soft cap must not be reached");
        _returnInvestment(property, _msgSender());
    }

    /// @notice cancel current initial investment for property
    /// @param property Property contract address
    function cancelOffering(address property) public {
        require(FixedPriceInitialOfferingHelpers(_dataProxy).hasSystemAdminRights(msg.sender), "InitialInvestment: You need to have system admin rights");
        _offerings[property].presaleStart = block.timestamp;
        _offerings[property].presaleEnd = block.timestamp;
        _offerings[property].saleStart = block.timestamp;
        _offerings[property].saleEnd = block.timestamp;
        emit InitialOfferingCanceled(property);
    }

    /// @notice transfer DAI from this contract to another wallet in case something goes wrong
    /// @param property Property contract address
    /// @param wallet Wallet address
    function recoverDAI(address property, address wallet) public {
        require(FixedPriceInitialOfferingHelpers(_dataProxy).hasSystemAdminRights(msg.sender), "InitialInvestment: You need to have system admin rights");
        Offering storage offering = _offerings[property];
        require(offering.saleEnd <= block.timestamp && offering.softCap > offering.amountCollected.add(offering.presaleCollected), "InitialInvestment: Soft cap must not be reached");
        require(FixedPriceInitialOfferingHelpers(_offerings[property].investmentToken).transfer(wallet, offering.amountCollected));
        _offerings[property].amountCollected = 0;
        _offerings[property].presaleCollected = 0;
        _numOfSuccessfulOfferings[property] = _numOfSuccessfulOfferings[property] + 1;
    }

    /// @notice retrieves total supply of property token
    /// @param property Property contract address
    function currentSupply(address property) public view returns (uint256) {
        return FixedPriceInitialOfferingHelpers(property).totalSupply();
    }

    /// @notice retrieves cap of property token
    /// @param property Property contract address
    function hardCap(address property) public view returns (uint256) {
        return FixedPriceInitialOfferingHelpers(property).cap();
    }

    /// @notice retrieves initial offering information for property
    /// @param property Property contract address
    function offeringInfo(address property) public view returns (Offering memory) {
        return _offerings[property];
    }

    /// @notice retrieves current offering token invested in sale (returns zero if investment was collected) for wallet
    /// @param property Property contract address
    /// @param wallet Investor wallet
    function currentInvestmentByWallet(address property, address wallet) public view returns (uint256) {
        return _userInvestment[property][wallet][_numOfSuccessfulOfferings[property]];
    }

    /// @notice retrieves current total offering token invested in sale by user (returns zero if investment was collected)
    /// @param property Property contract address
    /// @param wallet Investor wallet
    function currentInvestmentByUser(address property, address wallet) public view returns (uint256) {
        bytes32 user = FixedPriceInitialOfferingHelpers(_users).getUserBytesFromWallet(wallet);
        return _userTotalInvestment[property][user][_numOfSuccessfulOfferings[property]];
    }

    /// @notice retrieves current offering token invested in presale (returns zero if investment was collected)
    /// @param property Property contract address
    /// @param wallet Investor wallet
    function currentUserPresaleInvestment(address property, address wallet) public view returns (uint256) {
        return _userTokensPresale[property][wallet][_numOfSuccessfulOfferings[property]].mul(_offerings[property].price).div(100);
    }
}