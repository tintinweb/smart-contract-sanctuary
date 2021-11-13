// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import  "./ice.sol";
import "./Ownable.sol";
import "./IAttr.sol";


// light anti forest
// forest anti land
// land anti ocean
// ocean anti flame
// flame anti light
contract CECalc is ICECalc,Ownable {
    
    uint16 CAMP_LAND = 0;
    uint16 CAMP_FOREST = 1;
    uint16 CAMP_FLAME = 2;
    uint16 CAMP_LIGHT = 3;
    uint16 CAMP_OCEAN = 4;
    address public attrAddress;
    IAttr public attrContract;
    
    
    
    constructor(){
        fastSetAntiCamp(CAMP_FOREST,CAMP_LIGHT);
        fastSetAntiCamp(CAMP_LAND,CAMP_FOREST);
        fastSetAntiCamp(CAMP_OCEAN,CAMP_LAND);
        fastSetAntiCamp(CAMP_FLAME,CAMP_OCEAN);
        fastSetAntiCamp(CAMP_LIGHT,CAMP_FLAME);
    }
    
    mapping(uint16=>uint16) public antiCampMap;
    // campA vs campB : CE rate(10000 as 1)
    mapping(uint16=>mapping(uint16=>uint16)) public antiCampRate;
    
    uint16 public defaultAntiRate = 1200; // 1.2 = 1k * 1.2k / 1m, 1 = 1k * 1k/1m;
    uint32 public MAX_RATE_NUM = 1000000; // 1k * 1k
    
    function setAttrAddress(address _addr) public onlyOwner{
        attrAddress = _addr;
        attrContract = IAttr(_addr);
    }
    
    // admin set anti camp relation
    function setAntiCamp(uint16 _campA,uint16 _campB) public onlyOwner {
        antiCampMap[_campA] = _campB;
    }
    
    // admin set anti camp rate
    function setCampRateRelation(uint16 _campA,uint16 _campB,uint16 rate) public onlyOwner {
        antiCampRate[_campA][_campB] = rate;
    }
    
    // admin set anti camp relation
    function fastSetCampRate(uint16 _campA,uint16 _campB,uint16 rate) public onlyOwner {
        antiCampRate[_campB][_campA] = rate;
        // a -> b = x; ==> b --> a = 1/x;
        uint16 reciprocal = uint16((MAX_RATE_NUM / rate));
        antiCampRate[_campA][_campB] = reciprocal;
    }
    
    function fastSetAntiCamp(uint16 _campA,uint16 _campB) public onlyOwner {
        setAntiCamp(_campA,_campB);
        fastSetCampRate(_campA,_campB,defaultAntiRate);
    }
    
    
    // get the anit camp of current camp
    function getAntiCamp(uint16 _campId) public view override returns(uint16) {
        return antiCampMap[_campId];   
    }
    
    // get the ce rate between campA and campB
    function getAntiCampRate(uint16 _campIdA, uint16 _campIdB) public view override returns(uint16) {
        uint16 ret = antiCampRate[_campIdA][_campIdB];   
        if(ret == 0) return 1000;
        return ret;
    }
    
    
    // get ce of the tokenId
    function getCE(address _nftAddr,uint256 _tokenId) public override view returns(uint32) {
        if(_nftAddr == address(0)) {
            // do nothing, for extension
        }
        NftInfo memory info = attrContract.getNftInfoMap(_tokenId);
        uint32 temp1 = uint32((info.atk + info.hp) * info.level);
        uint32 rate = uint32(1000 + 100 * (info.typeId - 1));
        uint32 temp2 = temp1 * rate;
        return uint32( info.ce + temp2 / 1000);
    }
}