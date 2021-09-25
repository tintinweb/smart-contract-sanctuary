/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITopUpAction {
    struct RecordKey {
        address payer;
        address account;
        bytes32 protocol;
    }

    struct RecordMeta {
        address account;
        bytes32 protocol;
    }

    event Register(
        address indexed account,
        bytes32 indexed protocol,
        uint256 indexed threshold,
        address payer,
        address depositToken,
        uint256 depositAmount,
        address actionToken,
        uint256 singleTopUpAmount,
        uint256 totalTopUpAmount,
        uint256 maxGasPrice,
        bool repayDebt
    );

    event Deregister(
        address indexed payer,
        address indexed account,
        bytes32 indexed protocol
    );

    event TopUp(
        address indexed account,
        bytes32 indexed protocol,
        address indexed payer,
        address depositToken,
        uint256 consumedDepositAmount,
        address actionToken,
        uint256 topupAmount
    );

    function userPositions(address user)
        external
        view
        returns (RecordMeta[] memory);

    function getSupportedProtocols() external view returns (bytes32[] memory);

    function getActionFee() external view returns (uint256);

    function getFeeHandler() external view returns (address);

    function getPosition(
        address payer,
        address account,
        bytes32 protocol
    )
        external
        view
        returns (
            uint96 threshold,
            address depositToken,
            address actionToken,
            uint128 totalTopUpAmount,
            uint128 singleTopUpAmount,
            uint128 depositTokenBalance,
            uint96 maxGasPrice,
            bool repayDebt
        );

    function isProtocolSupported(bytes32 protocol) external view returns (bool);

    function execute(
        address payer,
        address account,
        address keeper,
        bytes32 protocol
    ) external returns (bool);

    function getHealthFactor(bytes32 protocol, address account)
        external
        view
        returns (uint256);

    function canExecute(RecordKey calldata record) external view returns (bool);

    function batchCanExecute(RecordKey[] calldata records)
        external
        view
        returns (bool[] memory);

    function resetPosition(
        address account,
        bytes32 protocol,
        bool unstake
    ) external returns (bool);

    function executeNewTopUpHandler(bytes32 protocol)
        external
        returns (address);

    function executeActionFee() external returns (uint256);

    function executeFeeHandler() external returns (address);
}

contract KeeperWrapper {
    ITopUpAction public action =
        ITopUpAction(0x901413B15EDE84561b539708773E81566a597B23);

    constructor() {}

    function getExecutables(address[] memory _addresses)
        public
        view
        returns (ITopUpAction.RecordKey[] memory)
    {
        // Temporary
        ITopUpAction.RecordKey memory testKey;
        testKey.payer = 0x901413B15EDE84561b539708773E81566a597B23;
        testKey.account = 0x901413B15EDE84561b539708773E81566a597B23;
        testKey.protocol = "test";

        // Getting all positions
        ITopUpAction.RecordKey[] memory keys;
        for (uint256 i = 0; i < _addresses.length; i++) {
            ITopUpAction.RecordMeta[] memory records = action.userPositions(
                _addresses[i]
            );
            for (uint256 j; j < records.length; j++) {
                ITopUpAction.RecordMeta memory record = records[j];
                ITopUpAction.RecordKey memory key;
                key.payer = _addresses[i];
                key.account = record.account;
                key.protocol = record.protocol;
                keys[keys.length] = key;
            }
        }

        // Finding Executables
        ITopUpAction.RecordKey[] memory executables;
        bool[] memory canExecute = action.batchCanExecute(keys);
        for (uint256 i = 0; i < keys.length; i++) {
            if (canExecute[i]) executables[executables.length] = keys[i];
        }

        // Returning Executables
        return executables;
    }
}