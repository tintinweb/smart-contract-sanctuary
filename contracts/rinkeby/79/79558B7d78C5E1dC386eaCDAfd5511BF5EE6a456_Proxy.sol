/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity ^0.5.16;

interface GovernorAlphaInterface {
    function castVote(uint proposalId, bool support) external;
}

contract Proxy {
    /// @notice The name of this contract
    string public constant name = "Proxy Voting Service";

    /// @notice The address of the Compound Protocol Governor
    GovernorAlphaInterface public governor_address;

    constructor(address governor_address_) public {
        governor_address = GovernorAlphaInterface(governor_address_);
    }

    function castVote(uint proposalId) public {
        // check here.
        return governor_address.castVote(proposalId, true);
    }



}