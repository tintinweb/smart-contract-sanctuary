/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: apache 2.0
/*
Copyright 2020 Sigmoid Foundation <[email protected]>
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;
contract SigmoidLoan {
    struct AUCTION {
        uint256 auctionType; // 0 erc20 1 erc20Loan 2nft;
        // If auction clossed =false, if ongoing =true
        bool auctionStatus;

        // seller address
        address seller;

        address buyer;

        // starting price
        uint256 startingPrice;

        // min price
        uint256 endingPrice;

        // Auction started at
        uint256 auctionTimestamp;

        // Auction duration
        uint256 auctionDuration;
        
        uint256 interestRate;

        uint256 loanDuration;
        
        string assetsName;

        uint256 assetsAmount;
    }
    AUCTION[] public auctionList;
    AUCTION[] public myLoan;
    AUCTION[] public completionOrder;


    function createLoan(uint256 _auctionType, address _seller,uint256 _startingPrice,uint256 _endingPrice,uint256 _auctionDuration,uint256 _interestRate,uint256 _loanDuration,string memory _assetsName,uint256 _assetsAmount) public {
        AUCTION memory _auction;
        _auction.auctionType = _auctionType;
        _auction.seller = _seller;
        _auction.startingPrice = _startingPrice;
        _auction.endingPrice = _endingPrice;
        _auction.auctionDuration = _auctionDuration;
        _auction.interestRate = _interestRate;
        _auction.loanDuration = _loanDuration;
        _auction.assetsName = _assetsName;
        _auction.assetsAmount   = _assetsAmount;
        _auction.auctionStatus = true;
        _auction.auctionTimestamp = now;
        auctionList.push(_auction);
    }


    struct Trustee{
        string assetsSymbol;
        address seller;
        uint256 amount;
        uint256 id;
    }
    Trustee[] public trusteeList;
    function delegate(string memory _assetsSymbol,address _seller,uint256 _amount) public {
        Trustee memory _trusteeList;
        _trusteeList.seller = _seller;
        _trusteeList.amount = _amount;
        _trusteeList.assetsSymbol = _assetsSymbol;
        _trusteeList.id = now;

        trusteeList.push(_trusteeList);
    }


    function takeOrder(uint256 _auctionTimestamp,address _buyer) public {
        AUCTION memory _OrderSuccess;
        for (uint256 i = 0; i < auctionList.length; i++) {
            if(auctionList[i].auctionTimestamp == _auctionTimestamp){
                require(_buyer != auctionList[i].seller,"Cannot accept the loan order issued by oneself");
                auctionList[i].auctionStatus = false;
                auctionList[i].buyer = _buyer;
                _OrderSuccess = auctionList[i];
            }
        }
        myLoan.push(_OrderSuccess);
    }


    function hanldeRepay(uint256 _auctionTimestamp) public {
        AUCTION memory _completionOrder;
        for (uint256 i = 0; i < auctionList.length; i++) {
            if(auctionList[i].auctionTimestamp == _auctionTimestamp){
                _completionOrder = auctionList[i];
                delete auctionList[i];
            }
        }
        completionOrder.push(_completionOrder);
        if(myLoan.length >=1){
            for (uint256 j = 0; j < myLoan.length; j++) {
                if(myLoan[j].auctionTimestamp == _auctionTimestamp){
                    _completionOrder = myLoan[j];
                    delete myLoan[j]; 
                }
            }
        }
        
        completionOrder.push(_completionOrder);
    }


    function getDEXInfo(uint256 _auctionType) view public returns(AUCTION[] memory ) {
        uint256 len=0;
        for (uint256 i = 0; i < auctionList.length; i++) {
            if(_auctionType == auctionList[i].auctionType){
                // targetAuction[len] = auctionList[i];
                len++;
            }
        }
        // return len;
        AUCTION[] memory targetAuction = new AUCTION[](len);
        uint256 k = 0;
            for (uint256 j = 0; j < auctionList.length; j++) {
                if(_auctionType == auctionList[j].auctionType && auctionList[j].auctionStatus == true){
                   targetAuction[k] = auctionList[j];
                   k++;
                }
        }
        return (targetAuction);
    }

    function getWalletInfo(uint256 _auctionType2) view public returns(AUCTION[] memory) {
        uint256 len2=0;
        for (uint256 i = 0; i < auctionList.length; i++) {
            if( myLoan[i].auctionType == _auctionType2 && myLoan[i].seller == msg.sender && myLoan[i].auctionStatus == false && myLoan[i].buyer != address(0)){
                // targetAuction[len] = auctionList[i];
                len2++;
            }
        }
        // return len;
        AUCTION[] memory walletAuction = new AUCTION[](len2);
        uint256 f = 0;
            for (uint256 j = 0; j < myLoan.length; j++) {
                if(myLoan[j].auctionType == _auctionType2 && myLoan[j].seller == msg.sender){
                   walletAuction[f] = myLoan[j];
                   f++;
                }
        }
        return walletAuction;
    }

}