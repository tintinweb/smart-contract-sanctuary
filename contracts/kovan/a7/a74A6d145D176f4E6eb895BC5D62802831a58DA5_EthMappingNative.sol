/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity 0.5.16;

contract EthMappingNative {
    mapping(address => string) public EthVsNative;
    address[] public EthAddress;
    address public governance;
    constructor() public {
        governance = msg.sender;
    }

    function EthAddressLength() public view returns (uint256){
        return EthAddress.length;
    }

    function changeGovernance(address _gov) external {
        require(governance == msg.sender, "forbidden");
        governance = _gov;
    }

    function saveNativeAddressViaGov(address sender, string calldata nativeAddress) external {
        require(governance == msg.sender, "forbidden");
        _save(sender, nativeAddress);
    }

    function removeNativeAddressViaGov(address sender) external {
        require(governance == msg.sender, "forbidden");
        _remove(sender);
    }

    function saveNativeAddress(string calldata nativeAddress) external {
        _save(msg.sender, nativeAddress);
    }

    function removeNativeAddress() external {
        _remove(msg.sender);
    }

    function _save(address sender, string memory nativeAddress) internal {
        if (bytes(EthVsNative[sender]).length == 0) {
            EthAddress.push(sender);
        }
        EthVsNative[sender] = nativeAddress;
    }

    function _remove(address sender) internal {
        require(bytes(EthVsNative[sender]).length != 0, "!Mapping");
        uint256 _index = 0;
        for (uint256 i = 0; i < EthAddress.length; i++) {
            if (EthAddress[i] == sender) {
                _index = i;
                break;
            }
        }
        require(EthAddress[_index] == sender, "Sender not in list");
        for (uint256 i = _index; i < EthAddress.length - 1; i++) {
            EthAddress[i] = EthAddress[i + 1];
        }
        delete EthAddress[EthAddress.length - 1];
        EthAddress.length --;
        delete EthVsNative[sender];
    }
}