// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";


interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

interface tellorInterface{
     function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}

interface uniswapInterface{
     function getAmountsOut(uint amountIn, address[] memory path)
        external view returns (uint[] memory amounts);
}
interface Token{
    function decimals() external view returns(uint256);
}
contract OracleWrapperInverse is Ownable{
    
    using SafeMath for uint256;
    
    //Mainnet
    address public tellerContractAddress=0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5;
    address public UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public usdtContractAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    struct TellorInfo{
        uint256 id;
        uint256 tellorPSR;
    }
    uint256 tellorId=1;
    mapping(string=>address) public typeOneMapping;  // chainlink
    string[] typeOneArray;
    mapping(string=> TellorInfo) public typeTwomapping; // tellor
    string[] typeTwoArray;
    mapping(string=> address) public typeThreemapping; // uniswap
    string[] typeThreeArray;

    function updateTellerContractAddress(address newAddress) public onlyOwner{
        tellerContractAddress = newAddress;
    }
    
    function addTypeOneMapping(string memory currencySymbol, address chainlinkAddress) external onlyOwner{
        typeOneMapping[currencySymbol]=chainlinkAddress;
        if(!checkAddressIfExists(typeOneArray,currencySymbol)){
            typeOneArray.push(currencySymbol);
        }
    }
    
    function addTypeTwoMapping(string memory currencySymbol, uint256 tellorPSR) external onlyOwner{
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
    
    function addTypeThreeMapping(string memory currencySymbol, address tokenContractAddress) external onlyOwner{
        typeThreemapping[currencySymbol]=tokenContractAddress;
        if(!checkAddressIfExists(typeThreeArray,currencySymbol)){
            typeThreeArray.push(currencySymbol);
        }
    }
    function checkAddressIfExists(string[] memory arr, string memory currencySymbol) internal pure returns(bool){
        for(uint256 i=0;i<arr.length;i++){
            if((keccak256(abi.encodePacked(arr[i]))) == (keccak256(abi.encodePacked(currencySymbol)))){
                return true;
            }
        }
        return false;
    }
    function getPrice(string memory currencySymbol,
        uint256 oracleType) external view returns (uint256){
        //oracletype 1 - chainlink and  for teller --2, uniswap---3
        if(oracleType == 1){
            require(typeOneMapping[currencySymbol]!=address(0), "please enter valid currency");
            OracleInterface oObj = OracleInterface(typeOneMapping[currencySymbol]);
            return uint256(oObj.latestAnswer());
        }
        else if(oracleType ==2){
            require(typeTwomapping[currencySymbol].id!=0, "please enter valid currency");
            tellorInterface tObj = tellorInterface(tellerContractAddress);
            uint256 actualFiatPrice;
            bool statusTellor;
            (actualFiatPrice,statusTellor) = tObj.getLastNewValueById(typeTwomapping[currencySymbol].tellorPSR);
            return uint256(actualFiatPrice);
        }else{
            require(typeThreemapping[currencySymbol]!=address(0), "please enter valid currency");
            uniswapInterface uObj = uniswapInterface(UniswapV2Router02);
            address[] memory path = new address[](2);
            path[0] = typeThreemapping[currencySymbol];
            path[1] = usdtContractAddress;
            uint[] memory values=uObj.getAmountsOut(10**(Token(typeThreemapping[currencySymbol]).decimals()),path);
            uint256 usdtDecimals=Token(usdtContractAddress).decimals();
            if(usdtDecimals==8){
                return uint256(values[1]);
            }else{
                return uint256(values[1].mul(10**(8-usdtDecimals)));
            }
        }
    }
    
    function getTypeOneArray() external view returns(string[] memory){
        return typeOneArray;
    }
    
    function getTypeTwoArray() external view returns(string[] memory){
        return typeTwoArray;
    }
    function getTypeThreeArray() external view returns(string[] memory){
        return typeThreeArray;
    }
    function updateUniswapV2Router02(address _UniswapV2Router02) external onlyOwner{
        UniswapV2Router02=_UniswapV2Router02;
    }
    function updateUSDTContractAddress(address _usdtContractAddress) external onlyOwner{
        usdtContractAddress=_usdtContractAddress;
    }
}