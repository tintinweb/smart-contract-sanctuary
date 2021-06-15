/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

//SPDX-License-Identifier: AFL-1.1
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract MaximoSC {

    struct DataTx {
        string data;
        string txhash;
    }

    mapping(string => DataTx[]) assets;
    mapping(string => DataTx[]) workOrders;
    
    mapping(string => mapping(uint => uint)) assetsIndexes;
    mapping(string => mapping(uint => uint)) workOrdersIndexes;

    modifier doesElementExist(bool isElementAnAsset, string memory assetNum, uint timestamp, bool mustExist) {
        
        uint index;
        DataTx memory element;
        
        
        if(isElementAnAsset){
            index = assetsIndexes[assetNum][timestamp];
        }
        else{
            index = workOrdersIndexes[assetNum][timestamp];
        }
        
        
        if(mustExist) {
            
            require(index != 0);
            
            if(isElementAnAsset)
                element = assets[assetNum][index - 1];
            else
                element = workOrders[assetNum][index - 1];
            
            bytes32 realHash = keccak256(abi.encodePacked(element.txhash));
            bytes32 voidHash = keccak256(abi.encodePacked(""));
            
            require(realHash == voidHash);
        }
        else
            require(index == 0);
            
        _;
    }

    function getAsset(string memory assetnum) public view returns (DataTx[] memory) {
        DataTx[] memory res = assets[assetnum];
        return res;
    }

    function getWorkOrder(string memory assetnum) public view returns (DataTx[] memory) {
        DataTx[] memory res = workOrders[assetnum];
        return res;
    }

    function addAsset(string memory assetNum, uint timestamp, string memory assetData) public doesElementExist(true, assetNum, timestamp, false) {
        DataTx memory asset;
        asset.data = assetData;
        assets[assetNum].push(asset);
        
        assetsIndexes[assetNum][timestamp] = assets[assetNum].length;
        
    }

    function addWorkOrder(string memory assetNum, uint timestamp, string memory woData) public doesElementExist(false, assetNum, timestamp, false) {
        DataTx memory wo;
        wo.data = woData;
        workOrders[assetNum].push(wo);
        
        workOrdersIndexes[assetNum][timestamp] = workOrders[assetNum].length;
        
    }

    function setAssetTxHash(string memory assetNum, uint timestamp, string memory txhash) public doesElementExist(true, assetNum, timestamp, true) {
        uint index = assetsIndexes[assetNum][timestamp] - 1;
        assets[assetNum][index].txhash = txhash;
    }

    function setWOTxHash(string memory assetNum, uint timestamp, string memory txhash) public doesElementExist(false, assetNum, timestamp, true) {
        uint index = workOrdersIndexes[assetNum][timestamp] - 1;
        workOrders[assetNum][index].txhash = txhash;
    }
}