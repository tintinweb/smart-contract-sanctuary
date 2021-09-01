// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICollectiveFactory.sol";
import "./interfaces/ICollective.sol";
import "./interfaces/IPriceOracleAggregator.sol";
import "./interfaces/IStrategy.sol";
import { DataTypes } from "./DataTypes.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title CollectiveFactory
/// @author @ace-contributor
/// @notice factory contract to manage Collective
////////////////////////////////////////////////////////////////////////////////////////////

contract CollectiveFactory is ICollectiveFactory {
    using Clones for address;

    /// @notice owner to manage this collectiveFactory
    address public immutable override owner;

    /// @notice metaData
    DataTypes.ProtocolData public protocolData;

    /// @notice address to collective contract to be cloned
    address public override collectiveImp;

    /// @notice mapping hash to collective
    mapping(bytes32 => address) public collectives;

    /// @notice array of collectives
    address[] public override allCollectives;

    /// @notice aggregator of price oracle for assets
    IPriceOracleAggregator public override priceOralceAggregator;

    /// @notice acceptedTokens can be used
    address[] public override acceptedTokens;

    /// @notice mapping if token is accepted by this protocol
    mapping(address => bool) public override isAcceptedToken;

    /// @notice strategies for token
    mapping(address => IStrategy[]) public tokenStrategies;

    /// @notice return if tokken strategy exists
    mapping(address => mapping(IStrategy => bool)) public override isTokenStrategy;


    /// @notice modifier to allow only the owner to call a function
    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        address _owner,
        address[] memory _acceptedTokens,
        address _priceOralceAggregator,
        uint256 _protocolFee,
        address payable _feeTo,
        address _collectiveImp
    ) {
        require(_owner != address(0), "CLFAC: INVALID_OWNER");
        require(
            _priceOralceAggregator != address(0),
            "CLFAC: INVALID_AGGREGATOR"
        );
        require(
            _protocolFee > 0 && _protocolFee <= 10000,
            "CLFAC: INVALID_FEE"
        );
        require(_feeTo != address(0), "CLFAC: INVALID_FEETO");
        require(_collectiveImp != address(0), "CLFAC: INVALID_COLLECTIVE_ADDR");

        priceOralceAggregator = IPriceOracleAggregator(_priceOralceAggregator);
        owner = _owner;
        collectiveImp = _collectiveImp;
        protocolData = DataTypes.ProtocolData(
            _protocolFee,
            _feeTo,
            10000
        );

        _addAcceptedTokens(_acceptedTokens);
    }

    /// @notice create new collective
    function createCollective(
        bytes32 _name,
        bytes32 _ipfsHash,
        bytes32 _cwUrl,
        address payable _beneficiary,
        address[] memory _acceptedTokens,
        address[] memory _nominations
    ) external override returns (address newCollective) {

        require(_beneficiary != address(0), "CLFAC: INVALID_BENEFICIARY");

        uint256 length = _acceptedTokens.length;
        require(length > 0, "CLFAC: NO_ACCEPTED_TOKEN");

        for (uint256 i = 0; i < length; i++) {
            require(
                isAcceptedToken[_acceptedTokens[i]],
                "CLFAC: NOT_PROTOCOL_ACCEPTED_TOKEN"
            );
            priceOralceAggregator.viewPriceInUSD(_acceptedTokens[i]);
        }

        // calc collective Hash
        bytes32 pHash = keccak256(
            abi.encodePacked(msg.sender, _beneficiary, _name)
        );
        newCollective = collectiveImp.cloneDeterministic(pHash);

        DataTypes.MetaData memory metaData = DataTypes.MetaData(
            _name,
            _ipfsHash,
            _cwUrl,
            _beneficiary,
            msg.sender, // creator
            allCollectives.length + 1,
            address(this), // factory
            pHash
        );

        ICollective(newCollective).initialize(
            metaData,
            _nominations
        );

        collectives[pHash] = newCollective;
        allCollectives.push(newCollective);

        emit CollectiveCreation(pHash, newCollective);
    }

    function getAllCollectives() public view override returns(address[] memory) {
        return allCollectives;
    }

    function getAllAcceptedTokens() public view override returns(address[] memory) {
        return acceptedTokens;
    }

    /// @notice add accepted Tokens
    function _addAcceptedTokens(address[] memory _tokens) internal {
        uint256 length = _tokens.length;

        require(length > 0, "CLFAC: NO_ACCEPTED_TOEKN");

        for (uint256 i = 0; i < length; i++) {
            require(_tokens[i] != address(0), "CLFAC: INVALID_ACCEPTED_TOKEN");

            if (!isAcceptedToken[_tokens[i]]) {
                isAcceptedToken[_tokens[i]] = true;
                acceptedTokens.push(_tokens[i]);
            }
        }
    }

    /// @notice add accepted Tokens
    function addAcceptedTokens(address[] memory _tokens)
        external
        override
        onlyOwner
    {
        _addAcceptedTokens(_tokens);
    }

    function getTokenStrategies(address _token) external view override returns(
        IStrategy[] memory
    ) {
        return tokenStrategies[_token];
    }

    function addTokenStrategy(
        address _token, IStrategy _strategy
    ) external override onlyOwner returns(bool) {
        require(_token != address(0), "CJFAC: INVALID_TOKEN");
        require(address(_strategy) != address(0), "CJFAC: INVALID_STRATEGY");

        require(!isTokenStrategy[_token][_strategy], "CJFAC: STRATEGY_ALREADY_REGISTERED");

        isTokenStrategy[_token][_strategy] = true;
        tokenStrategies[_token].push(_strategy);
        return true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Protocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getProtocolData() external view override returns(
        DataTypes.ProtocolData memory
    ) {
        return protocolData;
    }

    function setFeeTo(address payable _feeTo) external override onlyOwner {
        require(_feeTo != address(0), "CLFAC: INVALID_FEETO");
        protocolData.feeTo = _feeTo;
    }

    function setProtocolFee(uint256 _protocolFee) external override onlyOwner {
        require(
            _protocolFee > 0 && _protocolFee <= protocolData.maxFee,
            "CLFAC: INVALID_PROTOCOL_FEE"
        );
        protocolData.protocolFee = _protocolFee;
    }

    function setCollectiveImpl(address _collectiveImpl) external override onlyOwner {
        require(_collectiveImpl != address(0), "CLFAC: INVALID_COLLECTIVE_IMPL");
        collectiveImp = _collectiveImpl;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStrategy.sol";
import "./IPriceOracleAggregator.sol";
import { DataTypes } from "../DataTypes.sol";

interface ICollectiveFactory {
    event CollectiveCreation(bytes32 collectiveHash, address collective);

    function isTokenStrategy(address _token, IStrategy _strategy) external returns (bool);
    function getTokenStrategies(address _token) external view returns (IStrategy[] memory);
    function addTokenStrategy(address _token, IStrategy _strategy) external returns (bool);

    function owner() external view returns (address);
    function getProtocolData() external view returns (DataTypes.ProtocolData memory);

    function setFeeTo(address payable _feeTo) external;
    function setProtocolFee(uint256 _protocolFee) external;

    function collectiveImp() external view returns (address);
    function setCollectiveImpl(address _collectiveImpl) external;

    function allCollectives(uint) external view returns (address);
    function getAllCollectives() external view returns (address[] memory);

    function acceptedTokens(uint) external view returns (address);
    function getAllAcceptedTokens() external view returns (address[] memory);

    function priceOralceAggregator() external view returns (IPriceOracleAggregator);
    function isAcceptedToken(address _token) external view returns (bool);
    function addAcceptedTokens(address[] memory _tokens) external;

    function createCollective(
        bytes32 _name,
        bytes32 _ipfsHash,
        bytes32 _cwUrl,
        address payable _beneficiary,
        address[] memory _acceptedTokens,
        address[] memory _nominations
    ) external returns (address collective);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStrategy.sol";
import {DataTypes} from "../DataTypes.sol";
import "./IStrategy.sol";

interface ICollective {
    event Deposit(address sender, address token, uint256 amount);
    event Withdraw(address sender, uint256 amount);

    function getDefaultStrategy(address _token)
        external
        view
        returns (IStrategy);

    function getBToken(address _token) external view returns (address);
    function getAcceptedTokens() external view returns(address[] memory);

    function initialize(
        DataTypes.MetaData memory _metaData,
        address[] memory _nominations
    ) external returns (bool);

    function backWithETH() external payable returns (bool);

    function back(address _token, uint256 _value) external returns (bool);

    function redeemBToken(address _token, uint256 _valueToRemove)
        external
        returns (bool);

    function withdraw() external returns (bool);

    function withdrawableQueue(address _token) external view returns (uint256);

    function addAcceptedTokenWithStrategy(address _token, IStrategy _defaultStrategy)
        external
        returns (bool);

    function updateTokenStrategy(address _token, IStrategy _newStrategy)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOracle.sol";

interface IPriceOracleAggregator {
    
    event UpdateOracle(address token, IOracle oracle);

    function getPriceInUSD(address _token) external returns (uint256);
    function updateOracleForAsset(address _asset, IOracle _oracle) external;
    function viewPriceInUSD(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    function token() external view returns (address);

    function balanceOf(address _account) external view returns (uint256);

    function deposit(uint256 _amount) external returns (bool);

    function redeem(address _backer, uint256 _backedAmount)
        external
        returns (bool);

    function withdraw(address _beneficiary, uint256 _totalBackedAmount)
        external
        returns (bool);

    function withdrawAll(address _recipient) external;

    function withdrawableQueue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title DataTypes
/// @author @ace-contributor
////////////////////////////////////////////////////////////////////////////////////////////

library DataTypes {
    struct MetaData {
        bytes32 name;
        bytes32 ipfsHash;
        bytes32 cwUrl;
        address payable beneficiary;
        address creator;
        uint256 id;
        address factory;
        bytes32 hashBytes;
    }

    struct ProtocolData {
        uint256 protocolFee;
        address payable feeTo;
        uint256 maxFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    function getPriceInUSD() external returns (uint256);

    function viewPriceInUSD() external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}