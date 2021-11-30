// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
import {GelatoBytes} from "./gelato/GelatoBytes.sol";

interface IJob {
    function getNextJob(bytes32 operator)
        external
        view
        returns (
            bool canExec,
            address target,
            bytes memory execPayload
        );
}

contract GelatoMakerJob {
    using GelatoBytes for bytes;

    address public immutable pokeMe;

    constructor(address _pokeMe) {
        pokeMe = _pokeMe;
    }

    function doJob(
        address _target,
        bytes memory _execPayload,
        bool _shouldRevert
    ) external {
        require(msg.sender == pokeMe, "GelatoMakerJob: Only PokeMe");

        (bool success, bytes memory returnData) = _target.call(_execPayload);
        if (!success && _shouldRevert)
            returnData.revertWithError("GelatoMakerJob.doJob:");
    }

    function checker(
        bytes32 _network,
        address _job,
        bool _shouldRevert
    ) external view returns (bool canExec, bytes memory pokeMePayload) {
        address target;
        bytes memory execPayload;

        (canExec, target, execPayload) = IJob(_job).getNextJob(_network);

        pokeMePayload = abi.encodeWithSelector(
            this.doJob.selector,
            target,
            execPayload,
            _shouldRevert
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}