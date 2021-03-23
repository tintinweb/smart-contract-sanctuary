/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PonderwareTransferOfAuthority {

    // ponderware is destroying the private key controlling the MooncatRescue contract
    // due to the outcome of the vote contract: 0x1916F482BB9F3523a489791Ae3d6e052b362C777

    // This contract, if confirmed, represents a public transfer of the official ponderware address.

    // To ensure confirmation and get ponderware's new address, call the `whereIsPonderware` function

    address immutable oldPonderwareAddress;
    address payable immutable newPonderwareAddress;

    bool confirmedByOld = false;
    bool confirmedByNew = false;
    bool transferVoid = false;

    modifier addressIsAuthorized {
        require((msg.sender == oldPonderwareAddress) || (msg.sender == newPonderwareAddress), "Unauthorized");
        _;
    }

    modifier transferIsNotVoid {
        require(!transferVoid, "Transfer Of Authority Void");
        _;
    }

    modifier transferIsConfirmed {
        require((confirmedByOld && confirmedByNew), "Not Confirmed");
        _;
    }

    constructor(address payable newPonderwareAddress_) {
        oldPonderwareAddress = msg.sender;
        newPonderwareAddress = newPonderwareAddress_;
    }

    receive() external payable {
        newPonderwareAddress.transfer(msg.value);
    }

    function voidTransfer () public transferIsNotVoid addressIsAuthorized {
        require(!confirmedByOld, "Already Confirmed");
        transferVoid = true;
    }

    function confirm () public transferIsNotVoid addressIsAuthorized {
        if (msg.sender == newPonderwareAddress){
            confirmedByNew = true;
        } else {
            require(confirmedByNew, "New Not Confirmed");
            confirmedByOld = true;
        }
    }

    function whereIsPonderware() public view transferIsNotVoid transferIsConfirmed returns (address) {
        return newPonderwareAddress;
    }

}