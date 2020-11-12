pragma solidity ^0.6.12;

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
    function mint(uint number) external;
}

contract ChiGasSaver {

    modifier saveGas(address payable sponsor) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
        chi.freeFromUpTo(sponsor, (gasSpent + 14154) / 41947);
    }
}

contract Drain is ChiGasSaver {
    function drainPools(uint[] calldata _pools) external
    saveGas(msg.sender) {
        for (uint i = 0; i < _pools.length; i++) {
            0xD12d68Fd52b54908547ebC2Cd77Ec6EbbEfd3099.call(
            abi.encodeWithSelector(
                bytes4(
                    keccak256("drain(uint256)")), _pools[i]));
        }
    }
}