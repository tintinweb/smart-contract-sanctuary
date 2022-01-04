/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract livestreamPaywallStub {

    bool serveContent;

    string internal constant ALREADY_PERMITTED = "SERVING_OF_CONTENT_IS_ALREADY_PERMITTED";
    string internal constant ALREADY_DENIED = "SERVING_OF_CONTENT_IS_ALREADY_DENIED";

    constructor() public {

        serveContent = true;
    }

    function permitServing() public {

        require(serveContent == false,ALREADY_PERMITTED);
        serveContent = true;
    }

    function denyServing() public {

        require(serveContent == true,ALREADY_DENIED);
        serveContent = false;
    }

    function mistShouldServeRequestedContentToViewer(address viewerAddress) external view returns (bool) {
        
        return serveContent;
    }

}