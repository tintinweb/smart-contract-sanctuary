/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract AdsContract {
    struct ad {
        string title;
        string description;
        string redirect_url;
    }

    ad[] ads;

    //Dynamic fee
    uint256 _creationFeeETH = 10000000000000000; //wei

    event AdUpdated(ad newAd, address advertiser, uint256 newFee);
    event FeesHasBeenWithdrawed(uint256 balance, address receiver);
   
    function updateAd(ad memory newAd) public payable {
        require(msg.value == _creationFeeETH, "ETH sent are not enough to update the number.");
        ads.push(newAd);
        _creationFeeETH = _creationFeeETH * 125 /100;
        emit AdUpdated(newAd, msg.sender, _creationFeeETH);
    }

    function getAd() public view returns (ad memory) {
        require(ads.length != 0, "There are no ads");
        return ads[ads.length - 1];
    }
    
    function getFee() public view returns (uint256) {
        return _creationFeeETH;
    }
    
    //TODO: aggiungere una funzione per il withdraw dei soldi che può essere chiamata solo dall'owner dello smart contract
    function withdrawFees() public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit FeesHasBeenWithdrawed(balance, msg.sender);
    }
    
    //TODO: cambiare owner dello smart contract
}