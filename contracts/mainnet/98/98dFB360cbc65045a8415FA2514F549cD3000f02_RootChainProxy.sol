pragma solidity ^0.5.2;
import {Ownable} from "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ProxyStorage is Ownable {
    address internal proxyTo;
}

pragma solidity ^0.5.2;

contract ChainIdMixin {
  bytes constant public networkId = "199";
  uint256 constant public CHAINID = 199;
}

pragma solidity ^0.5.2;

import {Governable} from "./governance/Governable.sol";
import {IWithdrawManager} from "../root/withdrawManager/IWithdrawManager.sol";


contract Registry is Governable {
    // @todo hardcode constants
    bytes32 private constant WETH_TOKEN = keccak256("wethToken");
    bytes32 private constant DEPOSIT_MANAGER = keccak256("depositManager");
    bytes32 private constant STAKE_MANAGER = keccak256("stakeManager");
    bytes32 private constant VALIDATOR_SHARE = keccak256("validatorShare");
    bytes32 private constant WITHDRAW_MANAGER = keccak256("withdrawManager");
    bytes32 private constant CHILD_CHAIN = keccak256("childChain");
    bytes32 private constant STATE_SENDER = keccak256("stateSender");
    bytes32 private constant SLASHING_MANAGER = keccak256("slashingManager");

    address public erc20Predicate;
    address public erc721Predicate;

    mapping(bytes32 => address) public contractMap;
    mapping(address => address) public rootToChildToken;
    mapping(address => address) public childToRootToken;
    mapping(address => bool) public proofValidatorContracts;
    mapping(address => bool) public isERC721;

    enum Type {Invalid, ERC20, ERC721, Custom}
    struct Predicate {
        Type _type;
    }
    mapping(address => Predicate) public predicates;

    event TokenMapped(address indexed rootToken, address indexed childToken);
    event ProofValidatorAdded(address indexed validator, address indexed from);
    event ProofValidatorRemoved(address indexed validator, address indexed from);
    event PredicateAdded(address indexed predicate, address indexed from);
    event PredicateRemoved(address indexed predicate, address indexed from);
    event ContractMapUpdated(bytes32 indexed key, address indexed previousContract, address indexed newContract);

    constructor(address _governance) public Governable(_governance) {}

    function updateContractMap(bytes32 _key, address _address) external onlyGovernance {
        emit ContractMapUpdated(_key, contractMap[_key], _address);
        contractMap[_key] = _address;
    }

    /**
     * @dev Map root token to child token
     * @param _rootToken Token address on the root chain
     * @param _childToken Token address on the child chain
     * @param _isERC721 Is the token being mapped ERC721
     */
    function mapToken(
        address _rootToken,
        address _childToken,
        bool _isERC721
    ) external onlyGovernance {
        require(_rootToken != address(0x0) && _childToken != address(0x0), "INVALID_TOKEN_ADDRESS");
        rootToChildToken[_rootToken] = _childToken;
        childToRootToken[_childToken] = _rootToken;
        isERC721[_rootToken] = _isERC721;
        IWithdrawManager(contractMap[WITHDRAW_MANAGER]).createExitQueue(_rootToken);
        emit TokenMapped(_rootToken, _childToken);
    }

    function addErc20Predicate(address predicate) public onlyGovernance {
        require(predicate != address(0x0), "Can not add null address as predicate");
        erc20Predicate = predicate;
        addPredicate(predicate, Type.ERC20);
    }

    function addErc721Predicate(address predicate) public onlyGovernance {
        erc721Predicate = predicate;
        addPredicate(predicate, Type.ERC721);
    }

    function addPredicate(address predicate, Type _type) public onlyGovernance {
        require(predicates[predicate]._type == Type.Invalid, "Predicate already added");
        predicates[predicate]._type = _type;
        emit PredicateAdded(predicate, msg.sender);
    }

    function removePredicate(address predicate) public onlyGovernance {
        require(predicates[predicate]._type != Type.Invalid, "Predicate does not exist");
        delete predicates[predicate];
        emit PredicateRemoved(predicate, msg.sender);
    }

    function getValidatorShareAddress() public view returns (address) {
        return contractMap[VALIDATOR_SHARE];
    }

    function getWethTokenAddress() public view returns (address) {
        return contractMap[WETH_TOKEN];
    }

    function getDepositManagerAddress() public view returns (address) {
        return contractMap[DEPOSIT_MANAGER];
    }

    function getStakeManagerAddress() public view returns (address) {
        return contractMap[STAKE_MANAGER];
    }

    function getSlashingManagerAddress() public view returns (address) {
        return contractMap[SLASHING_MANAGER];
    }

    function getWithdrawManagerAddress() public view returns (address) {
        return contractMap[WITHDRAW_MANAGER];
    }

    function getChildChainAndStateSender() public view returns (address, address) {
        return (contractMap[CHILD_CHAIN], contractMap[STATE_SENDER]);
    }

    function isTokenMapped(address _token) public view returns (bool) {
        return rootToChildToken[_token] != address(0x0);
    }

    function isTokenMappedAndIsErc721(address _token) public view returns (bool) {
        require(isTokenMapped(_token), "TOKEN_NOT_MAPPED");
        return isERC721[_token];
    }

    function isTokenMappedAndGetPredicate(address _token) public view returns (address) {
        if (isTokenMappedAndIsErc721(_token)) {
            return erc721Predicate;
        }
        return erc20Predicate;
    }

    function isChildTokenErc721(address childToken) public view returns (bool) {
        address rootToken = childToRootToken[childToken];
        require(rootToken != address(0x0), "Child token is not mapped");
        return isERC721[rootToken];
    }
}

pragma solidity ^0.5.2;

import {IGovernance} from "./IGovernance.sol";

contract Governable {
    IGovernance public governance;

    constructor(address _governance) public {
        governance = IGovernance(_governance);
    }

    modifier onlyGovernance() {
        _assertGovernance();
        _;
    }

    function _assertGovernance() private view {
        require(
            msg.sender == address(governance),
            "Only governance contract is authorized"
        );
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.5.2;

// See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md

interface ERCProxy {
    function proxyType() external pure returns (uint256 proxyTypeId);
    function implementation() external view returns (address codeAddr);
}

pragma solidity ^0.5.2;

import {RootChainStorage} from "./RootChainStorage.sol";
import {Proxy} from "../common/misc/Proxy.sol";
import {Registry} from "../common/Registry.sol";

contract RootChainProxy is Proxy, RootChainStorage {
  constructor(address _proxyTo, address _registry, string memory _heimdallId)
    public
    Proxy(_proxyTo)
  {
    registry = Registry(_registry);
    heimdallId = keccak256(abi.encodePacked(_heimdallId));
  }
}

pragma solidity ^0.5.2;

interface IGovernance {
    function update(address target, bytes calldata data) external;
}

pragma solidity ^0.5.2;

contract DelegateProxyForwarder {
    function delegatedFwd(address _dst, bytes memory _calldata) internal {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := delegatecall(
                sub(gas, 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
    
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

pragma solidity ^0.5.2;

import {ERCProxy} from "./ERCProxy.sol";
import {DelegateProxyForwarder} from "./DelegateProxyForwarder.sol";

contract DelegateProxy is ERCProxy, DelegateProxyForwarder {
    function proxyType() external pure returns (uint256 proxyTypeId) {
        // Upgradeable proxy
        proxyTypeId = 2;
    }

    function implementation() external view returns (address);
}

pragma solidity ^0.5.2;

import {Registry} from "../common/Registry.sol";
import {ProxyStorage} from "../common/misc/ProxyStorage.sol";
import {ChainIdMixin} from "../common/mixin/ChainIdMixin.sol";


contract RootChainHeader {
    event NewHeaderBlock(
        address indexed proposer,
        uint256 indexed headerBlockId,
        uint256 indexed reward,
        uint256 start,
        uint256 end,
        bytes32 root
    );
    // housekeeping event
    event ResetHeaderBlock(address indexed proposer, uint256 indexed headerBlockId);
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }
}


contract RootChainStorage is ProxyStorage, RootChainHeader, ChainIdMixin {
    bytes32 public heimdallId;
    uint8 public constant VOTE_TYPE = 2;

    uint16 internal constant MAX_DEPOSITS = 10000;
    uint256 public _nextHeaderBlock = MAX_DEPOSITS;
    uint256 internal _blockDepositId = 1;
    mapping(uint256 => HeaderBlock) public headerBlocks;
    Registry internal registry;
}

pragma solidity ^0.5.2;
import {DelegateProxy} from "./DelegateProxy.sol";
import {ProxyStorage} from "./ProxyStorage.sol";


contract Proxy is ProxyStorage, DelegateProxy {
    event ProxyUpdated(address indexed _new, address indexed _old);
    event OwnerUpdate(address _prevOwner, address _newOwner);

    constructor(address _proxyTo) public {
        updateImplementation(_proxyTo);
    }

    function() external payable {
        // require(currentContract != 0, "If app code has not been set yet, do not call");
        // Todo: filter out some calls or handle in the end fallback
        delegatedFwd(proxyTo, msg.data);
    }

    function implementation() external view returns (address) {
        return proxyTo;
    }

    function updateImplementation(address _newProxyTo) public onlyOwner {
        require(_newProxyTo != address(0x0), "INVALID_PROXY_ADDRESS");
        require(isContract(_newProxyTo), "DESTINATION_ADDRESS_IS_NOT_A_CONTRACT");
        emit ProxyUpdated(_newProxyTo, proxyTo);
        proxyTo = _newProxyTo;
    }

    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

pragma solidity ^0.5.2;

contract IWithdrawManager {
    function createExitQueue(address token) external;

    function verifyInclusion(
        bytes calldata data,
        uint8 offset,
        bool verifyTxInclusion
    ) external view returns (uint256 age);

    function addExitToQueue(
        address exitor,
        address childToken,
        address rootToken,
        uint256 exitAmountOrTokenId,
        bytes32 txHash,
        bool isRegularExit,
        uint256 priority
    ) external;

    function addInput(
        uint256 exitId,
        uint256 age,
        address utxoOwner,
        address token
    ) external;

    function challengeExit(
        uint256 exitId,
        uint256 inputId,
        bytes calldata challengeData,
        address adjudicatorPredicate
    ) external;
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}