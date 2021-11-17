pragma solidity ^0.5.2;


/**
 * @title Fake Medianizer contract
 * @dev From MakerDAO (https://etherscan.io/address/0x729D19f657BD0614b4985Cf1D82531c67569197B#code)
 */
contract FakeMedianizer {
    function read() external view returns (bytes32) {
        return 0x0000000000000000000000000000000000000000000000094adc6a4ded958000;
    }
}