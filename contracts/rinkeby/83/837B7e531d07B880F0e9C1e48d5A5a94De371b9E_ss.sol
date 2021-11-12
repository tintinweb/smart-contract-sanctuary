// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ss{
    uint currentlength;
    uint maxbidamount;
    struct bidder_amount{
        address bidder;
        uint256 amount;
    }
    
    bidder_amount[] bidders;
     struct Auction {
        uint256 startTime;
        uint256 endTime;
        uint256 extDurationMinutes;
        uint256 minPercentIncrementInBasisPoints;
        bidder_amount[] bidders;
        string []tokenURI;
       
        bool finalized;
    }
    mapping(uint256=>Auction) auctions;
    function sort(bidder_amount[] memory bidders) public returns(bidder_amount[] memory) {
       quickSort(bidders, int(0), int(bidders.length - 1));
       return bidders;
    }
    function quickSort(bidder_amount[] memory bidders, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = bidders[uint(left + (right - left) / 2)].amount;
        while (i <= j) {
            while (bidders[uint(i)].amount < pivot) i++;
            while (pivot < bidders[uint(j)].amount) j--;
            if (i <= j) {
                bidder_amount memory tempory;
                tempory=bidders[uint(i)];
                bidders[uint(i)] = bidders[uint(j)];
                bidders[uint(j)] = tempory;

                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(bidders, left, j);
        if (i < right)
            quickSort(bidders, i, right);
    }
   

   
}