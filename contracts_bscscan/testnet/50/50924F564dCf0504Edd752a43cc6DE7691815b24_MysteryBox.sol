// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract MysteryBox is Ownable {

    struct MysteryBoxType {
        string name;
        uint256 priceNative;
        uint256 priceTVC;
        uint256 priceNativeDesc;
        uint256 priceTVCDesc;
        uint[] arrayFreqs;
        uint256 stock;
    }
    
    uint256 private mysteryBoxTypeCount;
    mapping (uint256 => MysteryBoxType) private mapMysteryBoxTypes;
    
    mapping (uint256 => uint256[]) private mapArraysFreqs;

    address private roleAdmin;

    modifier onlyAdminOrOwner(){
        require(msg.sender == roleAdmin || msg.sender == owner(), "You don't have permissions");
        _;
    }
    
    function changeAdmin(address _newAdmin) public onlyOwner {
        roleAdmin = _newAdmin;
    }


    function getMysteryBoxCount() external view onlyAdminOrOwner returns(uint256 count_) {
        return mysteryBoxTypeCount;
    }

    constructor() {
        mysteryBoxTypeCount = 1;
        
        mapArraysFreqs[mysteryBoxTypeCount] = [uint(569), uint(769), uint(899), uint(968), uint(998), uint(1000), uint(0)];
        MysteryBoxType memory mysteryBoxType1 = MysteryBoxType(
            "Basic",
            2500 * 1e14,
            3000 * 1e14,
            2375 * 1e14,
            2850 * 1e14,
            mapArraysFreqs[mysteryBoxTypeCount],
            2500
            );
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType1;
        
        mysteryBoxTypeCount++;
        mapArraysFreqs[mysteryBoxTypeCount] = [uint(289), uint(639), uint(819), uint(949), uint(992), uint(1000), uint(0)];
        MysteryBoxType memory mysteryBoxType2 = MysteryBoxType(
            "Common",
            4000 * 1e14,
            5100 * 1e14,
            3800 * 1e14,
            4845 * 1e14,
            mapArraysFreqs[mysteryBoxTypeCount],
            1500
            );
            
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType2;
        
        mysteryBoxTypeCount++;
        mapArraysFreqs[mysteryBoxTypeCount] = [uint(0), uint(99), uint(469), uint(799), uint(949), uint(992), uint(1000)];
        MysteryBoxType memory mysteryBoxType3 = MysteryBoxType(
            "Premium",
            7500 * 1e14,
            8700 * 1e14,
            7125 * 1e14,
            8265 * 1e14,
            mapArraysFreqs[mysteryBoxTypeCount],
            500
            );
        
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType3;
        
    }
    
    function addNewMysteryBoxType(string memory _name, uint256 _priceNative, uint256 _priceTVC, uint256 _priceNativeDesc, uint256 _priceTVCDesc, uint256[] memory _arrayFreqs, uint256 _stock) public onlyOwner {
        mysteryBoxTypeCount++;
        mapArraysFreqs[mysteryBoxTypeCount] = _arrayFreqs;
        MysteryBoxType memory mysteryBoxType = MysteryBoxType(
            _name,
            _priceNative,
            _priceTVC,
            _priceNativeDesc,
            _priceTVCDesc,
            _arrayFreqs,
            _stock
            );
        
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType;
    }
    
    function modifyMysteryBoxType(uint256 _idMystery, string memory _name, uint256 _priceNative, uint256 _priceTVC, uint256 _priceNativeDesc, uint256 _priceTVCDesc, uint256[] memory _arrayFreqs, uint256 _stock) public onlyOwner {
        require(_idMystery <= mysteryBoxTypeCount, "Not exist mystery box.");
        mapArraysFreqs[_idMystery] = _arrayFreqs;
        MysteryBoxType memory mysteryBoxType = MysteryBoxType(
            _name,
            _priceNative,
            _priceTVC,
            _priceNativeDesc,
            _priceTVCDesc,
            _arrayFreqs,
            _stock
            );
        
        mapMysteryBoxTypes[_idMystery] = mysteryBoxType;
    }
    
    function mysteryBoxDetails(uint256 _mysteryBoxId) public view returns (MysteryBoxType memory mysteryBoxDetails_) { 
        require(_mysteryBoxId <= mysteryBoxTypeCount, "Nonexistent token");
        return mapMysteryBoxTypes[_mysteryBoxId];
    }

    function changeMysteryBoxStock(uint256 _numberMysteryBoxType, uint256 _amount) public onlyAdminOrOwner {
        uint256 value = mapMysteryBoxTypes[_numberMysteryBoxType].stock;
        require(value > 0, "Counter: decrement overflow");
        require(value >= _amount, "Not enough stock");
        unchecked {
            mapMysteryBoxTypes[_numberMysteryBoxType].stock -= _amount;
        }
        
    }
}