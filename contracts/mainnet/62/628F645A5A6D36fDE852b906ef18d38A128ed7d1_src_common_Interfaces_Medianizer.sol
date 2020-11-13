pragma solidity 0.6.5;


/**
 * @title Medianizer contract
 * @dev From MakerDAO (https://etherscan.io/address/0x729D19f657BD0614b4985Cf1D82531c67569197B#code)
 */
interface Medianizer {
    function read() external view returns (bytes32);
}
