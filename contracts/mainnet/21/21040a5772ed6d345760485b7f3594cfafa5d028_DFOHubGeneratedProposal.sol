/* Description:
 * Transfering totally 10,000,000 BUIDL to specified addresses
 */
pragma solidity ^0.7.1;

contract DFOHubGeneratedProposal {

    function callOneTime(address proposal) public {
        IMVDProxy proxy = IMVDProxy(msg.sender);
        proxy.transfer(0xB0220a5A294F69ba3EDEd32D7f16B2EbECB4DbfE, 10000000000000000000000000, 0xD6F0Bb2A45110f819e908a915237D652Ac7c5AA8);
    }
}

interface IMVDProxy {
    function transfer(address receiver, uint256 value, address token) external;
    function transfer721(address receiver, uint256 tokenId, bytes calldata data, bool safe, address token) external;
}