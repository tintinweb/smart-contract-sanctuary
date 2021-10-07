/**
 *Submitted for verification at arbiscan.io on 2021-10-07
*/

pragma solidity >=0.7.6;

contract AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    // l1 addresses are transformed during l1->l2 calls. see https://developer.offchainlabs.com/docs/l1_l2_messages#address-aliasing for more information.
    function applyL1ToL2Alias(address l1Address) public pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }
}