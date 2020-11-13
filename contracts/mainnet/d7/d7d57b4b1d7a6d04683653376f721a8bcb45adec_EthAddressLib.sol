// Original: https://github.com/aave/aave-protocol/blob/master/contracts/libraries/EthAddressLib.sol

pragma solidity ^0.5.0;

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Represents ETH: https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances#reserves-assets
    }
}