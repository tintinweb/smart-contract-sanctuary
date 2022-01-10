//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBEP20.sol";

contract PrivateSale {
    mapping(address => prop) donor;
   
    uint256 public rfpAmount;
    address public privateSaleAddress;
    uint256 public bnbQuantity;
    address[] public wl;
    uint256 public hardCap;
    uint256 public flagWl = 0;
    struct prop {
        bool exist;
        uint256 bnb;
        bool isclaim;
        uint256 rfp;
    }

    // Payable address can receive Ether
    address payable public owner;
    IBEP20 public token;
    uint256 public start=0;

    // Payable constructor can receive Ether
    constructor(
        IBEP20 bep20,
        address psa,
        uint256 bnbQ,
        uint256 rfpamt
    ) payable {
        privateSaleAddress = psa;
        token = bep20;
        owner = payable(msg.sender);
        bnbQuantity = bnbQ;
        rfpAmount = rfpamt;
    }

    function getBuyerAmount() public view returns (uint256) {
        return donor[msg.sender].bnb;
    }

    function getHardCap() public view returns (uint256) {
        return hardCap;
    }


    function getReceivedAmount() public view returns (uint256) {
        return donor[msg.sender].rfp;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
     function setHardCap(uint256 bnbQ) public  {
         require(msg.sender == owner, "Only Owner");
       bnbQuantity = bnbQ;
  
    }

    function setStart(uint256 on) public  {
         require(msg.sender == owner, "Only Owner");
       start = on;
  
    }

     function getStart() public view returns (uint256) {
        return start;
    }


    function whitelist(address addr) external {
        bool y = false;
        for(uint256 x = 0; x<wl.length;x++){
            if(addr == wl[x]) {y=true;}
        }

        if(y==false){ wl.push(addr);}
       
    }

    

    function enableWhitelist(uint256 flag) external {
         require(msg.sender == owner, "Only Owner");
        flagWl = flag;
    }


    function claimRFP() public {
        if(start == 2){
        if (flagWl == 1) {
            for (uint256 x = 0; x < wl.length; x++) {
                if (msg.sender == wl[x]) {
                   _claimRFP();
                   break;
                }
            }
        }
            
            else if(flagWl == 0){
            _claimRFP();
        }

        }

        else{
            revert("Not Allow");
        }



    }

    function _claimRFP () internal {
         require(donor[msg.sender].rfp == 0, "You have claimed");

                    uint256 rfp = (donor[msg.sender].bnb)* rfpAmount;

                    token.transferFrom(privateSaleAddress, msg.sender, rfp);

                    donor[msg.sender].rfp = rfp;
    }

   
   
    function acceptFund() external payable {

        if (flagWl == 1) {
            for (uint256 x = 0; x < wl.length; x++) {
                if (msg.sender == wl[x]) {
                   _acceptFund();
                   break;
                }
            }
        }
            
            else if(flagWl == 0){
            _acceptFund();
        }


       
    }

    function _acceptFund() internal {
         require(
            (donor[msg.sender].bnb + msg.value) <= 5 ether,
            "greater than 5 bnb maximum."
        );
        require(
            (donor[msg.sender].bnb + msg.value) >= 0.5 ether,
            "Amount less than 0.5 BNB minimum"
        );
        require(hardCap < bnbQuantity, "Filled");

        donor[msg.sender].bnb += msg.value;
            hardCap +=msg.value;
    }

    function withrawFund() public {
        require(msg.sender == owner, "Only Owner");
        uint256 amount = address(this).balance;
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    //Function to transfer Ether from this contract to address from input

    function transfer(address payable _to, uint256 _amount) public {
        // Note that "to" is declared as payable
        require(msg.sender == owner, "Only Owner");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}