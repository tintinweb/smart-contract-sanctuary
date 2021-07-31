/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity ^0.4.24;

contract TransferManager {
    function verifyTransfer(address _from, address _to, uint256 _amount) public view returns(bool) {
        if (_from == address(0x89EB60E0f1d88aE71e8c0416c4F72734D6133252)) {
            if (_to == address(0x63A61a31F087295a2b3fbE6F546913Ccbe8127e8)) {
                return true;
            }
            return false;
        }
        return true;
    }
}