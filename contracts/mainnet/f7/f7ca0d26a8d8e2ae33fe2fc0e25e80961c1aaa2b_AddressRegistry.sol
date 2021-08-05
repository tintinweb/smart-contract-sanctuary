// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { Ownable } from "./Ownable.sol";
import { IAddressRegistry } from "./IAddressRegistry.sol";
import { AddressStorage } from "./AddressStorage.sol";

contract AddressRegistry is IAddressRegistry, Ownable, AddressStorage {
    event AvalancheUpdated(address indexed newAddress);
    event LGEUpdated(address indexed newAddress);
    event LodgeUpdated(address indexed newAddress);
    event LoyaltyUpdated(address indexed newAddress);
    event FrostUpdated(address indexed newAddress);
    event FrostPoolUpdated(address indexed newAddress);
    event SlopesUpdated(address indexed newAddress);
    event SnowPatrolUpdated(address indexed newAddress);
    event TreasuryUpdated(address indexed newAddress);
    event UniswapRouterUpdated(address indexed newAddress);
    event VaultUpdated(address indexed newAddress);
    event WethUpdated(address indexed newAddress);

    bytes32 private constant AVALANCHE_KEY = "AVALANCHE";
    bytes32 private constant LGE_KEY = "LGE";
    bytes32 private constant LODGE_KEY = "LODGE";
    bytes32 private constant LOYALTY_KEY = "LOYALTY";
    bytes32 private constant FROST_KEY = "FROST";
    bytes32 private constant FROST_POOL_KEY = "FROST_POOL";
    bytes32 private constant SLOPES_KEY = "SLOPES";
    bytes32 private constant SNOW_PATROL_KEY = "SNOW_PATROL";
    bytes32 private constant TREASURY_KEY = "TREASURY";
    bytes32 private constant UNISWAP_ROUTER_KEY = "UNISWAP_ROUTER";
    bytes32 private constant WETH_KEY = "WETH";
    bytes32 private constant VAULT_KEY = "VAULT";

    function getAvalanche() public override view returns (address) {
        return getAddress(AVALANCHE_KEY);
    }

    function setAvalanche(address _address) public override onlyOwner {
        _setAddress(AVALANCHE_KEY, _address);
        emit AvalancheUpdated(_address);
    }

    function getLGE() public override view returns (address) {
        return getAddress(LGE_KEY);
    }

    function setLGE(address _address) public override onlyOwner {
        _setAddress(LGE_KEY, _address);
        emit LGEUpdated(_address);
    }

    function getLodge() public override view returns (address) {
        return getAddress(LODGE_KEY);
    }

    function setLodge(address _address) public override onlyOwner {
        _setAddress(LODGE_KEY, _address);
        emit LodgeUpdated(_address);
    }

    function getLoyalty() public override view returns (address) {
        return getAddress(LOYALTY_KEY);
    }

    function setLoyalty(address _address) public override onlyOwner {
        _setAddress(LOYALTY_KEY, _address);
        emit LoyaltyUpdated(_address);
    }

    function getFrost() public override view returns (address) {
        return getAddress(FROST_KEY);
    }

    function setFrost(address _address) public override onlyOwner {
        _setAddress(FROST_KEY, _address);
        emit FrostUpdated(_address);
    }

    function getFrostPool() public override view returns (address) {
        return getAddress(FROST_POOL_KEY);
    }

    function setFrostPool(address _address) public override onlyOwner {
        _setAddress(FROST_POOL_KEY, _address);
        emit FrostPoolUpdated(_address);
    }

    function getSlopes() public override view returns (address) {
        return getAddress(SLOPES_KEY);
    }

    function setSlopes(address _address) public override onlyOwner {
        _setAddress(SLOPES_KEY, _address);
        emit SlopesUpdated(_address);
    }

    function getSnowPatrol() public override view returns (address) {
        return getAddress(SNOW_PATROL_KEY);
    }

    function setSnowPatrol(address _address) public override onlyOwner {
        _setAddress(SNOW_PATROL_KEY, _address);
        emit SnowPatrolUpdated(_address);
    }

    function getTreasury() public override view returns (address payable) {
        address payable _address = address(uint160(getAddress(TREASURY_KEY)));
        return _address;
    }

    function setTreasury(address _address) public override onlyOwner {
        _setAddress(TREASURY_KEY, _address);
        emit TreasuryUpdated(_address);
    }

    function getUniswapRouter() public override view returns (address) {
        return getAddress(UNISWAP_ROUTER_KEY);
    }

    function setUniswapRouter(address _address) public override onlyOwner {
        _setAddress(UNISWAP_ROUTER_KEY, _address);
        emit UniswapRouterUpdated(_address);
    }

    function getVault() public override view returns (address) {
        return getAddress(VAULT_KEY);
    }

    function setVault(address _address) public override onlyOwner {
        _setAddress(VAULT_KEY, _address);
        emit VaultUpdated(_address);
    }

    function getWeth() public override view returns (address) {
        return getAddress(WETH_KEY);
    }

    function setWeth(address _address) public override onlyOwner {
        _setAddress(WETH_KEY, _address);
        emit WethUpdated(_address);
    }
}