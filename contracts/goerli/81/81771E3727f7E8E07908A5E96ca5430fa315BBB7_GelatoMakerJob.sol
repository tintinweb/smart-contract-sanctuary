// SPDX-License-Identifier: UNLICENSED
//solhint-disable compiler-version
pragma solidity 0.8.11;
import {GelatoBytes} from "./gelato/GelatoBytes.sol";

interface ISequencer {
    struct WorkableJob {
        address job;
        bool canWork;
        bytes args;
    }

    function getNextJobs(
        bytes32 network,
        uint256 startIndex,
        uint256 endIndexExcl
    ) external returns (WorkableJob[] memory);

    function numJobs() external view returns (uint256);
}

contract GelatoMakerJob {
    using GelatoBytes for bytes;

    address public immutable pokeMe;

    constructor(address _pokeMe) {
        pokeMe = _pokeMe;
    }

    //solhint-disable code-complexity
    //solhint-disable function-max-lines
    function checker(
        address _sequencer,
        bytes32 _network,
        uint256 _startIndex,
        uint256 _endIndex
    ) external returns (bool, bytes memory) {
        ISequencer sequencer = ISequencer(_sequencer);
        uint256 numJobs = sequencer.numJobs();

        if (numJobs == 0)
            return (false, bytes("GelatoMakerJob: No jobs listed"));
        if (_startIndex >= numJobs) {
            bytes memory msg1 = bytes.concat(
                "GelatoMakerJob: Only jobs available up to index ",
                _toBytes(numJobs - 1)
            );

            bytes memory msg2 = bytes.concat(
                ", inputted startIndex is ",
                _toBytes(_startIndex)
            );
            return (false, bytes.concat(msg1, msg2));
        }

        uint256 endIndex = _endIndex > numJobs ? numJobs : _endIndex;

        ISequencer.WorkableJob[] memory jobs = ISequencer(_sequencer)
            .getNextJobs(_network, _startIndex, endIndex);

        uint256 numWorkable;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) numWorkable++;
        }

        if (numWorkable == 0)
            return (false, bytes("GelatoMakerJob: No workable jobs"));

        ISequencer.WorkableJob[]
            memory workableJobs = new ISequencer.WorkableJob[](numWorkable);

        uint256 wIndex;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) {
                workableJobs[wIndex] = jobs[i];
                wIndex++;
            }
        }

        bytes memory execPayload = abi.encodeWithSelector(
            this.doJobs.selector,
            workableJobs
        );

        return (true, execPayload);
    }

    function doJobs(ISequencer.WorkableJob[] calldata _jobs) external {
        require(msg.sender == pokeMe, "GelatoMakerJob: Only PokeMe");

        for (uint256 i; i < _jobs.length; i++) {
            _doJob(_jobs[i].job, _jobs[i].args);
        }
    }

    function _doJob(address _job, bytes memory _args) internal {
        (bool success, bytes memory returnData) = _job.call(_args);
        if (!success) returnData.revertWithError("GelatoMakerJob: ");
    }

    function _toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
//solhint-disable compiler-version
pragma solidity 0.8.11;

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