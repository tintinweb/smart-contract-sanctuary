/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/TrustedCaller.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

contract TrustedCaller {
    address public trustedCaller;

    constructor(address _trustedCaller) {
        trustedCaller = _trustedCaller;
    }

    modifier onlyTrustedCaller(address _caller) {
        require(_caller == trustedCaller, "CALLER_IS_FORBIDDEN");
        _;
    }
}

// File: contracts/interfaces/IFinance.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

interface IFinance {
    function newImmediatePayment(
        address _token,
        address _receiver,
        uint256 _amount,
        string memory _reference
    ) external;
}

// File: contracts/libraries/EVMScriptCreator.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

library EVMScriptCreator {
    bytes4 private constant SPEC_ID = hex"00000001";

    function createEVMScript(
        address _to,
        bytes4 _methodId,
        bytes memory _evmScriptCallData
    ) internal pure returns (bytes memory _commands) {
        return
            abi.encodePacked(
                SPEC_ID,
                _to,
                uint32(_evmScriptCallData.length) + 4,
                _methodId,
                _evmScriptCallData
            );
    }

    function createEVMScript(
        address _to,
        bytes4 _methodId,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        for (uint256 i = 0; i < _evmScriptCallData.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to,
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodId,
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }
}

// File: contracts/interfaces/IEVMScriptFactory.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity 0.8.4;

interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}

// File: contracts/EVMScriptFactories/TopUpLegoProgram.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>


pragma solidity 0.8.4;





contract TopUpLegoProgram is TrustedCaller, IEVMScriptFactory {
    IFinance public finance;
    address public legoProgram;

    constructor(
        address _trustedCaller,
        IFinance _finance,
        address _legoProgram
    ) TrustedCaller(_trustedCaller) {
        finance = _finance;
        legoProgram = _legoProgram;
    }

    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        (address[] memory rewardTokens, uint256[] memory amounts) =
            _decodeEVMScriptCallData(_evmScriptCallData);
        _validateMotionData(rewardTokens, amounts);

        bytes[] memory paymentsCallData = new bytes[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; ++i) {
            paymentsCallData[i] = abi.encode(
                rewardTokens[i],
                legoProgram,
                amounts[i],
                "Lego Program Transfer"
            );
        }

        return
            EVMScriptCreator.createEVMScript(
                address(finance),
                finance.newImmediatePayment.selector,
                paymentsCallData
            );
    }

    function _validateMotionData(address[] memory _rewardTokens, uint256[] memory _amounts)
        private
        pure
    {
        require(_rewardTokens.length == _amounts.length, "LENGTH_MISMATCH");
        require(_rewardTokens.length > 0, "EMPTY_DATA");
        for (uint256 i = 0; i < _rewardTokens.length; ++i) {
            require(_amounts[i] > 0, "ZERO_AMOUNT");
        }
    }

    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address[] memory rewardPrograms, uint256[] memory amounts)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        internal
        pure
        returns (address[] memory rewardPrograms, uint256[] memory amounts)
    {
        return abi.decode(_evmScriptCallData, (address[], uint256[]));
    }
}