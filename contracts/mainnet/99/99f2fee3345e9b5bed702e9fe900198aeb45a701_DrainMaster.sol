pragma solidity <=0.6.8;

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

interface IDrainController {
    function updatePrice() external;
}

contract DrainMaster is ChiGasSaver {
    
    IDrainController constant drainController = IDrainController(0x2e813f2e524dB699d279E631B0F2117856eb902C);

    function drain(uint8[] calldata _pools)
    external
    saveGas(msg.sender) {
        drainController.updatePrice();
        for (uint8 i = 0; i < _pools.length; i++) {
            0xD12d68Fd52b54908547ebC2Cd77Ec6EbbEfd3099.call(
            abi.encodeWithSelector(
                bytes4(
                    keccak256("drain(uint256)")), _pools[i]));
        }
    }
}