/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./PropToken.sol";

/// @title Properties
contract Properties is PropToken {
    uint256 private _commonEquity;
    uint256 private _preferredEquity;
    uint256 private _mezzanine;
    uint256 private _juniorDebt;
    uint256 private _seniorDebt;

    uint16 private _royaltyPercentage;

    modifier onlyPropManagerOrSpecialWallet {
        require(PropTokenHelpers(getDataAddress()).canEditProperty(_msgSender(), address(this)) || _msgSender() == PropTokenHelpers(getDataAddress()).getSpecialWallet(), "Properties: You need to be property manager!");
        _;
    }

    event CapitalStackChange(address indexed property, uint256 tokenizationAmount, uint256 commonEquity, uint256 preferredEquity, uint256 mezzanine,
        uint256 juniorDebt, uint256 seniorDebt);

    constructor(address owner, address propertyRegistry) public PropToken("BlocksquarePropertyToken", "BSPT") {
        transferOwnership(owner);
        _propertyRegistry = propertyRegistry;
    }

    /// @notice change royalty percentage
    /// @param royaltyPercentage Percent for royalties (5% is entered as 500)
    function addRoyaltyPercentage(uint16 royaltyPercentage) public onlyPropManagerOrSpecialWallet {
        require(_royaltyPercentage == 0, "Properties: Royalty percentage already set!");
        require(_royaltyPercentage <= 10000, "Properties: Royalty percentage must be less or equal to 10000");
        _royaltyPercentage = royaltyPercentage;
    }

    /// @notice change capital stack information
    /// @param cap Max amount of tokens that can be minted
    /// @param commonEquity Common equity amount
    /// @param preferredEquity Preferred equity amount
    /// @param mezzanine Mezzanine amount
    /// @param juniorDebt Junior debt amount
    /// @param seniorDebt Senior debt amount
    function changeCapitalStack(uint256 cap, uint256 commonEquity, uint256 preferredEquity, uint256 mezzanine,
        uint256 juniorDebt, uint256 seniorDebt) public onlyPropManagerOrSpecialWallet {
        require(cap.add(commonEquity).add(preferredEquity).add(mezzanine).add(juniorDebt).add(seniorDebt) == 100000 * 1 ether,
            "Properties: The sum of the capital stack needs to be same as maximum supply of BSPT");
        require(cap >= totalSupply(), "Properties: Cap needs to be bigger or equal to total supply");
        _cap = cap;
        _commonEquity = commonEquity;
        _preferredEquity = preferredEquity;
        _mezzanine = mezzanine;
        _juniorDebt = juniorDebt;
        _seniorDebt = seniorDebt;
        emit CapitalStackChange(address(this), cap, commonEquity, preferredEquity, mezzanine, juniorDebt, seniorDebt);
    }

    /// @notice can only be called by property registry
    function changeTokenNameAndSymbol(string memory name, string memory symbol) external {
        require(msg.sender == _propertyRegistry, "Properties: Transaction must come from registry!");
        _name = name;
        _symbol = symbol;
    }

    /// @notice see property registry contract
    function getProperty(uint64 index) public view returns (string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart) {
        return PropTokenHelpers(_propertyRegistry).getPropertyInfo(address(this), index);
    }

    /// @notice see property registry contract
    function getBasicInfo() public view returns (string memory streetLocation, string memory geoLocation, uint256 propertyValuation, uint256 tokenValuation, string memory propertyValuationCurrency) {
        return PropTokenHelpers(_propertyRegistry).getBasicInfo(address(this));
    }

    /// @notice see property registry contract
    function getIPFSHash() public view returns (string memory) {
        return PropTokenHelpers(_propertyRegistry).getIPFS(address(this));
    }

    /// @notice retrieves current capital stack information
    function getCapitalStack() public view returns (uint256 tokenization, uint256 commonEquity, uint256 preferredEquity,
        uint256 mezzanine, uint256 juniorDebt, uint256 seniorDebt) {
        return (_cap,
        _commonEquity,
        _preferredEquity,
        _mezzanine,
        _juniorDebt,
        _seniorDebt);
    }

    /// @notice retrieves current royalty percent
    function getRoyaltyPercentage() public view returns (uint16) {
        return _royaltyPercentage;
    }

    /// @dev fallback function to prevent any ether to be sent to this contract
    receive() external payable {
        revert();
    }
}