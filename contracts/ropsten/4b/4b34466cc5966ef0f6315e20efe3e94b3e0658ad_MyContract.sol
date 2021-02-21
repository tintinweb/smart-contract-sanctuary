/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

/* Discussion:
 * //google.com
 */
/* Description:
 * boh
 */
pragma solidity ^0.8.1;

contract MyContract {

    event Menelicche();

    string private _metadataLink;

    constructor(string memory metadataLink) {
        _metadataLink = metadataLink;
    }

    function getMetadataLink() public view returns(string memory) {
        return _metadataLink;
    }

    function onStart(address, address) public {
    }

    function onStop(address) public {
    }

    function menelicche() public {
        emit Menelicche();
    }
}