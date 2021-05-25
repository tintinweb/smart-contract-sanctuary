/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

//SPDX-License-Identifier: AFL-1.1
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract MaximoSC {

    struct DataTx {
        string data;
        string txhash;
        int timestamp;
    }

    mapping(string => DataTx[]) assets;
    mapping(string => DataTx[]) work_orders;

    function getAsset(string memory assetnum) public view returns (DataTx[] memory) {
        DataTx[] memory res = assets[assetnum];
        return res;
    }

    function getWorkOrder(string memory assetnum) public view returns (DataTx[] memory) {
        DataTx[] memory res = work_orders[assetnum];
        return res;
    }

    function addAsset(string memory assetnum, int timestamp, string memory assetData) public {
        DataTx memory asset;
        asset.data = assetData;
        asset.timestamp = timestamp;
        assets[assetnum].push(asset);
    }

    function addWorkOrder(string memory assetnum, int timestamp, string memory woData) public {
        DataTx memory wo;
        wo.data = woData;
        wo.timestamp = timestamp;
        work_orders[assetnum].push(wo);
    }

    function setAssetTxHash(string memory assetnum, int timestamp, string memory txhash) public {
        DataTx[] memory _assets = assets[assetnum];

        uint i = 0;
        for(i = 0; i < _assets.length; i++){
            if(_assets[i].timestamp == timestamp){
                assets[assetnum][i].txhash = txhash;
            }
        }
    }

    function setWOTxHash(string memory assetnum, int timestamp, string memory txhash) public {
        DataTx[] memory _work_orders = work_orders[assetnum];

        uint i = 0;
        for(i = 0; i < _work_orders.length; i++){
            if(_work_orders[i].timestamp == timestamp){
                work_orders[assetnum][i].txhash = txhash;
            }
        }
    }
}