/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity ^0.5.10;

contract distributer{
    
    struct partner {
        address payable addr;
        uint ratio;
        uint payout;
    }

    partner[] public partners;

    modifier onlyPayeeOne() { 
        if (msg.sender == partners[0].addr){
            _;
        }
    }

    constructor() public {
        partners.push(partner(address(0x4D90517Ad43e8B7bd90b55C6e7e4b2292162607b),7840, 0)); //78.4 - onlyPayeeOne
        partners.push(partner(address(0x1102934CD05901fdc9A98265d30DF902Ad7d78E1),1080, 0)); //10.8
        partners.push(partner(address(0xd5f7ce66673F74D1a136D29cCD111000fdEd70B3),990, 0)); //9.9
        partners.push(partner(address(0xDa470AB346A57D403e725138682F3544ba64a9C1),90, 0)); //0.9
    }
    
    function() payable external {}
    
    function calculatePayouts() internal {
        //set payouts to each address
        for (uint i=0; i< partners.length; i++) {
            partners[i].payout += (address(this).balance * partners[i].ratio) / 10000;
        }
    }
    
    function payout() public onlyPayeeOne {
        //This payout is only suitable for a trusted setup and has security consideration where the addresses in partners can be contracts or extended more than 4 addresses.
        calculatePayouts();
        for (uint i=0; i<partners.length; i++) {
            if (partners[i].addr.send(partners[i].payout)) {
                partners[i].payout = 0;
            }
        }
    }
    
}