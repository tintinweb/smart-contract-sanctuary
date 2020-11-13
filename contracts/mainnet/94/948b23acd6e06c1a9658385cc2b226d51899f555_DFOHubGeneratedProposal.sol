/* Description:
 * DFO Hub - Utilities - Get Metadata Link
 * The metadata located at this link contains all info about the DFO like name, short description, discussion link and many other info.
 */
/* Update:
 * Setting metadata link to ipfs://ipfs/QmaPpa1omFTrD9Erv3Yze8kN9aXDTYBw8yBwbDxU5vTpYw
 */
pragma solidity ^0.7.1;

contract DFOHubGeneratedProposal {

    string private _metadataLink;

    constructor(string memory metadataLink) {
        _metadataLink = metadataLink;
    }

    function getMetadataLink() public view returns(string memory) {
        return _metadataLink;
    }

    function onStart(address newSurvey, address oldSurvey) public {
    }

    function onStop(address newSurvey) public {
    }

    function getValue() public view returns(string memory) {
        return "ipfs://ipfs/QmaPpa1omFTrD9Erv3Yze8kN9aXDTYBw8yBwbDxU5vTpYw";
    }
}