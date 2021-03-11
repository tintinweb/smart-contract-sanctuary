// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";

contract JuiceOracleWrapper is Ownable{
    
    using SafeMath for uint;
    address public tellerContractAddress=0xFe41Cb708CD98C5B20423433309E55b53F79134a;
    address public joosContractAddress=0x2ec063289d162Ea3bddc56Ce8b57201feD32B628;
    struct TellorInfo{
        uint256 id;
        uint256 tellorPSR;
    }
    uint256 tellorId=1;
    mapping(string=>address) typeOneMapping;  // chainlink
    string[] typeOneArray;
    mapping(string=> TellorInfo) typeTwomapping; // tellor
    string[] typeTwoArray;
    bool isExtraAdded=false;
    mapping(string=>uint256) public staticPricesMapping;
    
    function updateTellerContractAddress(address newAddress) public onlyOwner{
        tellerContractAddress = newAddress;
    }
    
    function updateJOOSContractAddress(address _joosContractAddress) public onlyOwner{
        joosContractAddress = _joosContractAddress;
    }
     function updateIsExtraAdded(bool _isExtraAdded) external onlyOwner{
        isExtraAdded = _isExtraAdded;
    }
    function updateStaticPricesMapping(string memory currencySymbol, uint256 amount) external onlyOwner{
        staticPricesMapping[currencySymbol] = amount;
    }
    function addTypeOneMapping(string memory currencySymbol, address chainlinkAddress) public onlyOwner{
        typeOneMapping[currencySymbol]=chainlinkAddress;
        if(!checkAddressIfExists(typeOneArray,currencySymbol)){
            typeOneArray.push(currencySymbol);
        }
    }
    
    function addTypeTwoMapping(string memory currencySymbol, uint256 tellorPSR) public onlyOwner{
        TellorInfo memory tInfo= TellorInfo({
            id:tellorId,
            tellorPSR:tellorPSR
        });
        typeTwomapping[currencySymbol]=tInfo;
        tellorId++;
        if(!checkAddressIfExists(typeTwoArray,currencySymbol)){
            typeTwoArray.push(currencySymbol);
        }
    }
    
    function getPrice(string memory currencySymbol,
        uint256 oracleType) public view returns (uint256){
        //oracletype 1 - chainlink and  for teller
        if(oracleType == 1){
        require(typeOneMapping[currencySymbol]!=address(0), "please enter valid currency");
            OracleInterface oObj = OracleInterface(typeOneMapping[currencySymbol]);
            if(isExtraAdded){
                return(staticPricesMapping[currencySymbol]);
            }else{
                return uint256(oObj.latestAnswer());
            }
        }else if(oracleType==2){
            require(typeTwomapping[currencySymbol].id!=0, "please enter valid currency");
            tellorInterface tObj = tellorInterface(tellerContractAddress);
            uint256 actualFiatPrice;
            bool statusTellor;
            (actualFiatPrice,statusTellor) = tObj.getLastNewValueById(typeTwomapping[currencySymbol].tellorPSR);
            if(isExtraAdded){
                return(staticPricesMapping[currencySymbol]);
            }else{
                return uint256(actualFiatPrice);
            }
        }else{
            JOOSoracleWrapper jObj = JOOSoracleWrapper(joosContractAddress);
            (uint128 joosFiatPrice,)=jObj.getValue(currencySymbol);
            return uint256(uint256(joosFiatPrice).mul(100));
        }
    }
    
    function getTypeOneArray() external view returns(string[] memory){
        return typeOneArray;
    }
    
    function getTypeTwoArray() external view returns(string[] memory){
        return typeTwoArray;
    }
    function checkAddressIfExists(string[] memory arr, string memory currencySymbol) internal pure returns(bool){
        for(uint256 i=0;i<arr.length;i++){
            if((keccak256(abi.encodePacked(arr[i]))) == (keccak256(abi.encodePacked(currencySymbol)))){
                return true;
            }
        }
        return false;
    }
}

interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

interface JOOSoracleWrapper{
    function getValue(string memory key) external view returns (uint128, uint128);
}

interface tellorInterface{
     function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}