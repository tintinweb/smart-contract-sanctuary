/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract AdsContract {
    struct ad {
        string title;
        string descrcription;
        string redirect_url;
    }

    ad[] ads;


    //TODO: rendere la fee dinamica: ogni volta che qualcuno chiama lo store la fee incrementa
    uint256 _creationFeeETH = 10000000000000000; //wei

    //TODO: aggiungere eventi
    
   
    function updateAd(ad memory newAd) public payable {
        require(msg.value == _creationFeeETH, "ETH sent are not enough to update the number.");
        ads.push(newAd);
    }

    function getAd() public view returns (ad memory){
        require(ads.length != 0, "There are no ads");
        return ads[ads.length - 1];
    }
    
    
    //TODO: aggiungere una funzione per il withdraw dei soldi che può essere chiamata solo dall'owner dello smart contract
    
    //TODO: cambiare owner dello smart contract
}