/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract FlashBotRunner {

    uint256 private constant OP_OPTIONAL = 0x1;
    uint256 private constant OP_CHECK_RESULT = 0x2;
    uint256 private constant OP_STATIC_CALL = 0x4;
    uint256 private constant OP_DELEGATE_CALL = 0x8;

    struct Operation {
        address payable callTarget;
        bytes callData;
        uint256 callValue;
        uint256 gas;
        bytes32 returnHash;
        uint256 flags;
    }

    mapping(address => bool) public isOperator;

    modifier onlyOperatorOrSelf() {
        require(msg.sender == address(this) || isOperator[msg.sender], 'ONLY_OPERATOR_OR_SELF');
        _;
    }

    constructor(address[] memory operators) {
        for (uint256 i = 0; i < operators.length; ++i) {
            isOperator[operators[i]] = true;
        }
    }

    function toggleOperator(address operator, bool isAllowed)
        external
        onlyOperatorOrSelf
    {
        isOperator[operator] = isAllowed;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
        external
        pure
        returns (bytes4)
    {
        return 0x150b7a02;
    }

    receive() external payable {}

    function execute(Operation[] memory ops)
        public
        payable
        onlyOperatorOrSelf
    {
        for (uint256 i = 0; i < ops.length; ++i) {
            Operation memory op = ops[i];
            uint256 callGas = op.gas == 0 ? gasleft() - 2300 : op.gas;
            bool success;
            bytes memory resultData;
            if (op.flags & OP_DELEGATE_CALL == OP_DELEGATE_CALL) {
                (success, resultData) = op.callTarget
                    .delegatecall{gas: callGas}(op.callData);
            } else if (op.flags & OP_STATIC_CALL == OP_STATIC_CALL) {
                (success, resultData) = op.callTarget
                    .staticcall{gas: callGas}(op.callData);
            } else {
                (success, resultData) = op.callTarget
                    .call{value: op.callValue, gas: callGas}(op.callData);
            }
            if (op.flags & OP_OPTIONAL != OP_OPTIONAL) {
                if (!success) {
                    if (resultData.length == 0) {
                        revert('CALL_FAILED');
                    }
                    assembly {
                        revert(add(resultData, 32), mload(resultData))
                    }
                }
            }
            if (op.flags & OP_CHECK_RESULT == OP_CHECK_RESULT) {
                require(op.returnHash == keccak256(resultData), 'UNEXPECTED_CALL_RESULT');
            }
        }
    }
}