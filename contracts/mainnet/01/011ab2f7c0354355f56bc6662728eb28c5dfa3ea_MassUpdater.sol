/**
Mass Updater function that fixes a mistake on the Digester
*/

pragma solidity ^0.6.12;

contract MassUpdater {
    /// @notice The name of this contract
    string public constant name = 'Pool Mass Updater';

    /// @notice The address of the Digester, for MassUpdate the Pools.
    DIGESTERInterface public digester;

    constructor(address digester_) public {
        digester = DIGESTERInterface(digester_);
    }

    function massUpdatePools() public {
        uint256 length = digester.poolLength();
        for (uint256 pid = 0; pid < length; ++pid) {
            if (pid != 8) {
                digester.updatePool(pid);
            }
        }
    }
}

interface DIGESTERInterface {
    function updatePool(uint256 _pid) external;

    function poolLength() external view returns (uint256);
}