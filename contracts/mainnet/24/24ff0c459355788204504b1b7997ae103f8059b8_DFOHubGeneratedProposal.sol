/* Description:
 * Clearing authorizedtomint_0x35f3b5babdfe0be01c8acdaf806e400828108525 value
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

    function callOneTime(address proposal) public {
        IStateHolder holder = IStateHolder(IMVDProxy(msg.sender).getStateHolderAddress());
        holder.clear("authorizedtomint_0x35f3b5babdfe0be01c8acdaf806e400828108525");
    }
}

interface IMVDProxy {
    function getStateHolderAddress() external view returns(address);
}

interface IStateHolder {
    function clear(string calldata varName) external returns(bytes memory oldVal);
    function setAddress(string calldata varName, address val) external returns (address);
    function setBool(string calldata varName, bool val) external returns(bool);
    function setBytes(string calldata varName, bytes calldata val) external returns(bytes memory);
    function setString(string calldata varName, string calldata val) external returns(string memory);
    function setUint256(string calldata varName, uint256 val) external returns(uint256);
}