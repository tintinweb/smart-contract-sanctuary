/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-19
*/

// contracts/AssetManager.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct Stake {
    address payable stakeOwner;
}

struct Asset {
    bool ListedForSale;
    address payable Owner;
    string Name;
    uint FixedPrice;
    uint StakesAvailable;
    uint StakesReserved;
    Stake[] Stakes;
}

contract AssetManager {

    uint assetCount = 0;
    mapping(uint => Asset) public assets;

    event AssetPurchase(uint AssetId, address PreviousOwner, address NewOwner, uint PurchasePrice);
    event DelistAsset(uint AssetId);
    event ListAsset(uint AssetId);
    event PriceAdjusted(uint AssetId, uint PreviousPrice, uint NewPrice);
    event Registered(uint AssetId, address Owner, string Name, uint FixedPrice, uint StakesAvailable);
    event StakePurchase(uint AssetId, address Stakeholder, uint StakePrice);

    function AdjustFixedPrice(uint assetId, uint newPrice) external {
        Asset storage a = assets[assetId];
        require(a.Owner == msg.sender, "Only the Asset owner can de-list this asset");
        uint oldPrice = a.FixedPrice;
        a.FixedPrice = newPrice;

        emit PriceAdjusted(assetId, oldPrice, newPrice);
    }

    function Delist(uint assetId) external {
        Asset storage a = assets[assetId];
        require(a.Owner == msg.sender, "Only the Asset owner can de-list this asset");
        a.ListedForSale = false;

        emit DelistAsset(assetId);
    }

    function GetStakeHolders(uint assetId) external view returns (Stake[] memory) {
        Asset memory a = assets[assetId];
        return a.Stakes;
    }

    function GetStakePrice(uint assetId) public view returns (uint) {
        Asset memory a = assets[assetId];
        return a.FixedPrice / a.StakesAvailable;
    }

    function List(uint assetId) external {
        Asset storage a = assets[assetId];
        require(a.Owner == msg.sender, "Only the Asset owner can list this asset");
        a.ListedForSale = true;

        emit ListAsset(assetId);
    }

    function PurchaseAsset(uint assetId) external payable {
        Asset storage a = assets[assetId];
        require(a.ListedForSale, "This asset is not listed for sale");
        require(msg.value >= a.FixedPrice, "Transaction value does not match the asset price");
        uint stakePrice = GetStakePrice(assetId);
        for (uint i = 0; i < a.StakesReserved; i++) {
            //pay stakeholders
            a.Stakes[i].stakeOwner.transfer(stakePrice);
        }

        if (a.StakesAvailable > a.StakesReserved) {
            //pay balance to owner
            uint stakesRemaining = a.StakesAvailable - a.StakesReserved;
            a.Owner.transfer(uint(stakesRemaining) * stakePrice);
        }
        address previousOwner = a.Owner;
        a.Owner = payable(msg.sender);
        a.StakesReserved = 0;
        delete a.Stakes;

        emit AssetPurchase(assetId, previousOwner, msg.sender, a.FixedPrice);
    }

    function PurchaseStake(uint assetId) external payable {
        Asset storage a = assets[assetId];
        require(a.StakesReserved < a.StakesAvailable, "No more stakes available to purchase");
        uint stakePrice = GetStakePrice(assetId);
        require (msg.value >= stakePrice, "Transaction value does not match the stake price");
        a.Owner.transfer(msg.value);
        a.Stakes[a.StakesReserved].stakeOwner = payable(msg.sender); 
        a.StakesReserved++;

        emit StakePurchase(assetId, msg.sender, stakePrice);
    }

    function Register(string memory name, uint fixedPrice, uint stakesAvailable) external {
        bytes memory byteString = bytes(name);
        require(byteString.length > 0, "Asset must have a valid name");
        require(stakesAvailable > 0, "Asset must have at least 1 stake");
        Asset storage a = assets[assetCount++];
        a.ListedForSale = false;  
        a.Owner = payable(msg.sender);
        a.Name = name;
        a.FixedPrice = fixedPrice;
        a.StakesReserved = 0;
        a.StakesAvailable = stakesAvailable;

        emit Registered(assetCount, msg.sender, name, fixedPrice, stakesAvailable);
    }
}