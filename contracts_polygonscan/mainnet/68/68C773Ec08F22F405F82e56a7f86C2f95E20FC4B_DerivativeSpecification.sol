// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol";
import "./IDerivativeSpecification.sol";

contract DerivativeSpecification is IDerivativeSpecification {
    function isDerivativeSpecification() external pure override returns (bool) {
        return true;
    }

    string internal symbol_;

    bytes32[] internal oracleSymbols_;
    bytes32[] internal oracleIteratorSymbols_;
    bytes32 internal collateralTokenSymbol_;
    bytes32 internal collateralSplitSymbol_;

    uint256 internal livePeriod_;

    uint256 internal primaryNominalValue_;
    uint256 internal complementNominalValue_;

    uint256 internal authorFee_;

    string internal name_;
    string private baseURI_;
    address internal author_;

    function name() external view virtual override returns (string memory) {
        return name_;
    }

    function baseURI() external view virtual override returns (string memory) {
        return baseURI_;
    }

    function symbol() external view virtual override returns (string memory) {
        return symbol_;
    }

    function oracleSymbols()
        external
        view
        virtual
        override
        returns (bytes32[] memory)
    {
        return oracleSymbols_;
    }

    function oracleIteratorSymbols()
        external
        view
        virtual
        override
        returns (bytes32[] memory)
    {
        return oracleIteratorSymbols_;
    }

    function collateralTokenSymbol()
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return collateralTokenSymbol_;
    }

    function collateralSplitSymbol()
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return collateralSplitSymbol_;
    }

    function livePeriod() external view virtual override returns (uint256) {
        return livePeriod_;
    }

    function primaryNominalValue()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return primaryNominalValue_;
    }

    function complementNominalValue()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return complementNominalValue_;
    }

    function authorFee() external view virtual override returns (uint256) {
        return authorFee_;
    }

    function author() external view virtual override returns (address) {
        return author_;
    }

    constructor(
        address _author,
        string memory _name,
        string memory _symbol,
        bytes32[] memory _oracleSymbols,
        bytes32[] memory _oracleIteratorSymbols,
        bytes32 _collateralTokenSymbol,
        bytes32 _collateralSplitSymbol,
        uint256 _livePeriod,
        uint256 _primaryNominalValue,
        uint256 _complementNominalValue,
        uint256 _authorFee,
        string memory _baseURI
    ) public {
        author_ = _author;
        name_ = _name;
        symbol_ = _symbol;
        oracleSymbols_ = _oracleSymbols;
        oracleIteratorSymbols_ = _oracleIteratorSymbols;
        collateralTokenSymbol_ = _collateralTokenSymbol;
        collateralSplitSymbol_ = _collateralSplitSymbol;
        livePeriod_ = _livePeriod;
        primaryNominalValue_ = _primaryNominalValue;
        complementNominalValue_ = _complementNominalValue;
        authorFee_ = _authorFee;
        baseURI_ = _baseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
    /// @notice Proof of a derivative specification
    /// @dev Verifies that contract is a derivative specification
    /// @return true if contract is a derivative specification
    function isDerivativeSpecification() external pure returns (bool);

    /// @notice Set of oracles that are relied upon to measure changes in the state of the world
    /// between the start and the end of the Live period
    /// @dev Should be resolved through OracleRegistry contract
    /// @return oracle symbols
    function oracleSymbols() external view returns (bytes32[] memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    /// finds the value closest to a given timestamp
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbols
    function oracleIteratorSymbols() external view returns (bytes32[] memory);

    /// @notice Type of collateral that users submit to mint the derivative
    /// @dev Should be resolved through CollateralTokenRegistry contract
    /// @return collateral token symbol
    function collateralTokenSymbol() external view returns (bytes32);

    /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
    /// and the initial collateral split to the final collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split symbol
    function collateralSplitSymbol() external view returns (bytes32);

    /// @notice Lifecycle parameter that define the length of the derivative's Live period.
    /// @dev Set in seconds
    /// @return live period value
    function livePeriod() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of primary asset
    /// @dev Units of collateral theoretically swappable for 1 unit of primary asset
    /// @return primary nominal value
    function primaryNominalValue() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of complement asset
    /// @dev Units of collateral theoretically swappable for 1 unit of complement asset
    /// @return complement nominal value
    function complementNominalValue() external view returns (uint256);

    /// @notice Minting fee rate due to the author of the derivative specification.
    /// @dev Percentage fee multiplied by 10 ^ 12
    /// @return author fee
    function authorFee() external view returns (uint256);

    /// @notice Symbol of the derivative
    /// @dev Should be resolved through DerivativeSpecificationRegistry contract
    /// @return derivative specification symbol
    function symbol() external view returns (string memory);

    /// @notice Return optional long name of the derivative
    /// @dev Isn't used directly in the protocol
    /// @return long name
    function name() external view returns (string memory);

    /// @notice Optional URI to the derivative specs
    /// @dev Isn't used directly in the protocol
    /// @return URI to the derivative specs
    function baseURI() external view returns (string memory);

    /// @notice Derivative spec author
    /// @dev Used to set and receive author's fee
    /// @return address of the author
    function author() external view returns (address);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}