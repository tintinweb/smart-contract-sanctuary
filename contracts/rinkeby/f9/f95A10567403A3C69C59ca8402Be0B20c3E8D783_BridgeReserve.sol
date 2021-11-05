// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IArtBridge.sol";
import "./BridgeContext.sol";

///
///
/// ██████╗ ██████╗ ██╗██████╗  ██████╗ ███████╗
/// ██╔══██╗██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝
/// ██████╔╝██████╔╝██║██║  ██║██║  ███╗█████╗
/// ██╔══██╗██╔══██╗██║██║  ██║██║   ██║██╔══╝
/// ██████╔╝██║  ██║██║██████╔╝╚██████╔╝███████╗
/// ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚══════╝
///
/// ██████╗ ███████╗███████╗███████╗██████╗ ██╗   ██╗███████╗
/// ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝
/// ██████╔╝█████╗  ███████╗█████╗  ██████╔╝██║   ██║█████╗
/// ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝
/// ██║  ██║███████╗███████║███████╗██║  ██║ ╚████╔╝ ███████╗
/// ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
///
///
/// @title Mint reservation and parameter controller
/// @author artbridge.eth
/// @notice BridgeReserve controls all non financial aspects of a project
contract BridgeReserve is BridgeContext {
  IArtBridge public immutable bridge;

  mapping(uint256 => BridgeBeams.ReserveParameters) public projectToParameters;
  mapping(uint256 => mapping(address => bool)) public projectToMinters;
  mapping(uint256 => mapping(address => uint256))
    public projectToUserReservations;
  mapping(uint256 => uint256) public projectToReservations;

  /// @notice allows operations only on projects before mint starts
  /// @param _id target bridge project id
  modifier onlyReservable(uint256 _id) {
    BridgeBeams.ProjectState memory state = bridge.projectState(_id);
    require(state.initialized, "!initialized");
    require(!state.released, "released");
    _;
  }

  constructor(address _bridge) {
    bridge = IArtBridge(_bridge);
  }

  /// @dev proof is supplied by art bridge api
  /// @dev reserve may be over subscribed, allotted on a first come basis
  /// @param _reserved total number of user allocated tokens
  /// @param _id target bridge project id
  /// @param _amount number of reserved tokens to mint
  /// @param _proof reservation merkle proof
  function reserve(
    uint256 _id,
    uint256 _amount,
    uint256 _reserved,
    bytes32[] calldata _proof
  ) external payable onlyReservable(_id) {
    require(
      _amount * bridge.projectToTokenPrice(_id) == msg.value,
      "invalid payment amount"
    );
    require(
      _amount <= _reserved - projectToUserReservations[_id][msg.sender],
      "invalid reserve amount"
    );
    BridgeBeams.ReserveParameters memory params = projectToParameters[_id];
    require(params.reserveRoot != "", "!reserveRoot");
    require(
      _amount <= params.reservedMints - projectToReservations[_id],
      "invalid reserve amount"
    );
    bytes32 node = keccak256(abi.encodePacked(_id, msg.sender, _reserved));
    require(
      MerkleProof.verify(_proof, params.reserveRoot, node),
      "invalid proof"
    );
    bridge.reserve(_id, _amount, msg.sender);
    projectToUserReservations[_id][msg.sender] += _amount;
    projectToReservations[_id] += _amount;
  }

  /// @dev _reserveRoot is required for reserve but is not required to be set initially
  /// @notice set project reserve and mint parameters
  /// @param _id target bridge project id
  /// @param _maxMintPerInvocation maximum allowed number of mints per transaction
  /// @param _reservedMints maximum allowed number of reservice invocations
  function setParameters(
    uint256 _id,
    uint256 _maxMintPerInvocation,
    uint256 _reservedMints,
    bytes32 _reserveRoot
  ) external onlyReservable(_id) onlyOwner {
    require(_id < bridge.nextProjectId(), "invalid _id");
    (, , , , , , uint256 maxSupply, ) = bridge.projects(_id);
    require(_reservedMints <= maxSupply, "invalid reserve amount");
    require(_maxMintPerInvocation > 0, "require positive mint");
    require(_maxMintPerInvocation <= maxSupply, "invalid mint max");
    BridgeBeams.ReserveParameters memory params = BridgeBeams
      .ReserveParameters({
        maxMintPerInvocation: _maxMintPerInvocation,
        reservedMints: _reservedMints,
        reserveRoot: _reserveRoot
      });
    projectToParameters[_id] = params;
  }

  /// @dev projects may support multiple minters
  /// @notice adds a minter as available to mint a given project
  /// @param _id target bridge project id
  /// @param _minter minter address
  function addMinter(uint256 _id, address _minter) external onlyOwner {
    projectToMinters[_id][_minter] = true;
  }

  /// @notice removes a minter as available to mint a given project
  /// @param _id target bridge project id
  /// @param _minter minter address
  function removeMinter(uint256 _id, address _minter) external onlyOwner {
    projectToMinters[_id][_minter] = false;
  }

  /// @notice updates the project maxMintPerInvocation
  /// @param _id target bridge project id
  /// @param _maxMintPerInvocation maximum number of mints per transaction
  function setmaxMintPerInvocation(uint256 _id, uint256 _maxMintPerInvocation)
    external
    onlyReservable(_id)
    onlyOwner
  {
    (, , , , , , uint256 maxSupply, ) = bridge.projects(_id);
    require(_maxMintPerInvocation <= maxSupply, "invalid mint max");
    require(_maxMintPerInvocation > 0, "require positive mint");
    projectToParameters[_id].maxMintPerInvocation = _maxMintPerInvocation;
  }

  /// @notice updates the project reservedMints
  /// @param _id target bridge project id
  /// @param _reservedMints maximum number of reserved mints per project
  function setReservedMints(uint256 _id, uint256 _reservedMints)
    external
    onlyReservable(_id)
    onlyOwner
  {
    (, , , , , , uint256 maxSupply, ) = bridge.projects(_id);
    require(_reservedMints <= maxSupply, "invalid reserve amount");
    projectToParameters[_id].reservedMints = _reservedMints;
  }

  /// @dev utility function to set or update reserve tree root
  /// @notice updates the project reserveRoot
  /// @param _id target bridge project id
  /// @param _reserveRoot project reservation merkle tree root
  function setReserveRoot(uint256 _id, bytes32 _reserveRoot)
    external
    onlyReservable(_id)
    onlyOwner
  {
    projectToParameters[_id].reserveRoot = _reserveRoot;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {BridgeBeams} from "../libraries/BridgeBeams.sol";

interface IArtBridge {
  function mint(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external;

  function reserve(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external;

  function nextProjectId() external view returns (uint256);

  function projects(uint256 _id)
    external
    view
    returns (
      uint256 id,
      string memory name,
      string memory artist,
      string memory description,
      string memory website,
      uint256 supply,
      uint256 maxSupply,
      uint256 startBlock
    );

  function minters(address _minter) external view returns (bool);

  function projectToTokenPrice(uint256 _id) external view returns (uint256);

  function projectState(uint256 _id)
    external
    view
    returns (BridgeBeams.ProjectState memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {BridgeBeams} from "./libraries/BridgeBeams.sol";
import "./Extractable.sol";

contract BridgeContext is Extractable {
  using BridgeBeams for BridgeBeams.Project;
  using BridgeBeams for BridgeBeams.ProjectState;
  using BridgeBeams for BridgeBeams.ReserveParameters;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// BridgeBeams.sol
/// @title BEAMS token helper functions
/// @author artbridge.eth
/// @dev Library assists requirement checks across contracts
library BridgeBeams {
  struct Project {
    uint256 id;
    string name;
    string artist;
    string description;
    string website;
    uint256 supply;
    uint256 maxSupply;
    uint256 startBlock;
  }

  struct ProjectState {
    bool initialized;
    bool mintable;
    bool released;
    uint256 remaining;
  }

  struct ReserveParameters {
    uint256 maxMintPerInvocation;
    uint256 reservedMints;
    bytes32 reserveRoot;
  }

  /// @param _project Target project struct
  /// @return Project state struct derived from given input
  function projectState(Project memory _project)
    external
    view
    returns (BridgeBeams.ProjectState memory)
  {
    return
      ProjectState({
        initialized: isInitialized(_project),
        mintable: isMintable(_project),
        released: isReleased(_project),
        remaining: _project.maxSupply - _project.supply
      });
  }

  /// @param _project Target project struct
  /// @return True if project has required initial parameters, false if not
  function isInitialized(Project memory _project) internal pure returns (bool) {
    if (
      bytes(_project.artist).length == 0 ||
      bytes(_project.description).length == 0
    ) {
      return false;
    }
    return true;
  }

  /// @param _project Target project struct
  /// @return True if project is past mint start block, false if not
  function isReleased(Project memory _project) internal view returns (bool) {
    return _project.startBlock > 0 && _project.startBlock <= block.number;
  }

  /// @param _project Target project struct
  /// @return True if project is available for public mint, false if not
  function isMintable(Project memory _project) internal view returns (bool) {
    if (!isInitialized(_project)) {
      return false;
    }
    return isReleased(_project) && _project.supply < _project.maxSupply;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Extractable is Ownable {
  function withdraw() external payable onlyOwner {
    require(payable(owner()).send(address(this).balance), "!transfer");
  }

  function extract(address _token) external onlyOwner {
    IERC20 token = IERC20(_token);
    token.transfer(owner(), token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}