/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.5.4;
// @title Contract to create P2P signatures between parties
contract TrustLinks {
    // Declare a Trust Link structure
    struct TrustLink {
        // Address that signs
        bool trusted;
        uint updated;
    }

    // Store the trust links
    mapping(address => mapping(address => TrustLink)) public trustLinks;

    // Store the reverse link
    mapping(address => address[]) public reverseLookup;


    // Create a trust link
    function addTrustLink(address receiver, bool trusted) public {
        //Add the trust link to the mapping
        trustLinks[receiver][msg.sender] = (TrustLink({
            trusted: trusted,
            updated: block.number
        }));

        // Add to the reverse lookup
        reverseLookup[receiver].push(msg.sender);
    }

    // Allows to check if a trust link is in place between two parties
    function isTrustedLink(address receiver, address sender) public view returns (bool){
        return trustLinks[receiver][sender].trusted;
    }

}