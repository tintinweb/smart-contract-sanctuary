/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/TrustedCaller.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice A helper contract contains logic to validate that only a trusted caller has access to certain methods.
/// @dev Trusted caller set once on deployment and can't be changed.
contract TrustedCaller {
    string private constant ERROR_TRUSTED_CALLER_IS_ZERO_ADDRESS = "TRUSTED_CALLER_IS_ZERO_ADDRESS";
    string private constant ERROR_CALLER_IS_FORBIDDEN = "CALLER_IS_FORBIDDEN";

    address public immutable trustedCaller;

    constructor(address _trustedCaller) {
        require(_trustedCaller != address(0), ERROR_TRUSTED_CALLER_IS_ZERO_ADDRESS);
        trustedCaller = _trustedCaller;
    }

    modifier onlyTrustedCaller(address _caller) {
        require(_caller == trustedCaller, ERROR_CALLER_IS_FORBIDDEN);
        _;
    }
}

// File: contracts/interfaces/IFinance.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice Interface of method from Aragon's Finance contract to create a new payment
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

pragma solidity ^0.8.4;

/// @author psirex
/// @notice Contains methods for convenient creation
/// of EVMScripts in EVMScript factories contracts
library EVMScriptCreator {
    // Id of default CallsScript Aragon's executor.
    bytes4 private constant SPEC_ID = hex"00000001";

    /// @notice Encodes one method call as EVMScript
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

    /// @notice Encodes multiple calls of the same method on one contract as EVMScript
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

    /// @notice Encodes multiple calls to different methods within the same contract as EVMScript
    function createEVMScript(
        address _to,
        bytes4[] memory _methodIds,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        require(_methodIds.length == _evmScriptCallData.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < _methodIds.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to,
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodIds[i],
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }

    /// @notice Encodes multiple calls to different contracts as EVMScript
    function createEVMScript(
        address[] memory _to,
        bytes4[] memory _methodIds,
        bytes[] memory _evmScriptCallData
    ) internal pure returns (bytes memory _evmScript) {
        require(_to.length == _methodIds.length, "LENGTH_MISMATCH");
        require(_to.length == _evmScriptCallData.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < _to.length; ++i) {
            _evmScript = bytes.concat(
                _evmScript,
                abi.encodePacked(
                    _to[i],
                    uint32(_evmScriptCallData[i].length) + 4,
                    _methodIds[i],
                    _evmScriptCallData[i]
                )
            );
        }
        _evmScript = bytes.concat(SPEC_ID, _evmScript);
    }
}

// File: contracts/interfaces/IEVMScriptFactory.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice Interface which every EVMScript factory used in EasyTrack contract has to implement
interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}

// File: contracts/EVMScriptFactories/TopUpLegoProgram.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;





/// @author psirex
/// @notice Creates EVMScript to top up the address of the LEGO program
contract TopUpLegoProgram is TrustedCaller, IEVMScriptFactory {
    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_LENGTH_MISMATCH = "LENGTH_MISMATCH";
    string private constant ERROR_EMPTY_DATA = "EMPTY_DATA";
    string private constant ERROR_ZERO_AMOUNT = "ZERO_AMOUNT";

    // -------------
    // VARIABLES
    // -------------

    /// @notice Address of Aragon's Finance contract
    IFinance public immutable finance;

    /// @notice Address of LEGO program
    address public immutable legoProgram;

    // -------------
    // CONSTRUCTOR
    // -------------

    constructor(
        address _trustedCaller,
        IFinance _finance,
        address _legoProgram
    ) TrustedCaller(_trustedCaller) {
        finance = _finance;
        legoProgram = _legoProgram;
    }

    // -------------
    // EXTERNAL METHODS
    // -------------

    /// @notice Creates EVMScript to top up the address of the LEGO program
    /// @param _creator Address who creates EVMScript
    /// @param _evmScriptCallData Encoded tuple: (address[] _rewardTokens, uint256[] _amounts) where
    /// _rewardTokens - addresses of ERC20 tokens (zero address for ETH) to transfer
    /// _amounts - corresponding amount of tokens to transfer
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        view
        override
        onlyTrustedCaller(_creator)
        returns (bytes memory)
    {
        (address[] memory rewardTokens, uint256[] memory amounts) =
            _decodeEVMScriptCallData(_evmScriptCallData);
        _validateEVMScriptCallData(rewardTokens, amounts);

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

    /// @notice Decodes call data used by createEVMScript method
    /// @param _evmScriptCallData Encoded tuple: (address[] _rewardTokens, uint256[] _amounts) where
    /// _rewardTokens - addresses of ERC20 tokens (zero address for ETH) to transfer
    /// _amounts - corresponding amount of tokens to transfer
    /// @return _rewardTokens Addresses of ERC20 tokens (zero address for ETH) to transfer
    /// @return _amounts Amounts of tokens to transfer
    function decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        external
        pure
        returns (address[] memory _rewardTokens, uint256[] memory _amounts)
    {
        return _decodeEVMScriptCallData(_evmScriptCallData);
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _validateEVMScriptCallData(address[] memory _rewardTokens, uint256[] memory _amounts)
        private
        pure
    {
        require(_rewardTokens.length == _amounts.length, ERROR_LENGTH_MISMATCH);
        require(_rewardTokens.length > 0, ERROR_EMPTY_DATA);
        for (uint256 i = 0; i < _rewardTokens.length; ++i) {
            require(_amounts[i] > 0, ERROR_ZERO_AMOUNT);
        }
    }

    function _decodeEVMScriptCallData(bytes memory _evmScriptCallData)
        private
        pure
        returns (address[] memory _rewardTokens, uint256[] memory _amounts)
    {
        return abi.decode(_evmScriptCallData, (address[], uint256[]));
    }
}