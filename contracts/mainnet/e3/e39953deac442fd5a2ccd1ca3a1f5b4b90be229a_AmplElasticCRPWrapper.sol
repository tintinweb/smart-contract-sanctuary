// SPDX-License-Identifier: GNUV3

pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

interface IBPool {
    function gulp(address token) external;
}

interface IAmplElasticCRP {
    function resyncWeight(address token) external;
}

contract AmplElasticCRPWrapper {
    event ErrorReason(bytes reason);

    function safeResync(address crp, address bpool, address token) public {

        try IAmplElasticCRP(crp).resyncWeight(token) {
            // no-op : Resync call success
        }

        catch (bytes memory reason) {
            IBPool(bpool).gulp(token);
            emit ErrorReason(reason);
        }

    }
}