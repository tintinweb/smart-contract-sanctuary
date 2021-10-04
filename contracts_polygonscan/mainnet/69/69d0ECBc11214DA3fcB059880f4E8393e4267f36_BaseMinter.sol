// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBridgeReserve.sol";
import "./interfaces/IArtBridge.sol";
import "./Extractable.sol";

///
///
/// ██████╗  █████╗ ███████╗███████╗
/// ██╔══██╗██╔══██╗██╔════╝██╔════╝
/// ██████╔╝███████║███████╗█████╗
/// ██╔══██╗██╔══██║╚════██║██╔══╝
/// ██████╔╝██║  ██║███████║███████╗
/// ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
///
/// ███╗   ███╗██╗███╗   ██╗████████╗███████╗██████╗
/// ████╗ ████║██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
/// ██╔████╔██║██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
/// ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
/// ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ███████╗██║  ██║
/// ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
///
/// @title Base Minter
/// @author artbridge.eth
/// @notice Provide project validated minting interface
contract BaseMinter is Extractble {
  IArtBridge public bridge;
  IBridgeReserve public reserve;

  /// @dev financial checks are not enforced, deferred to minter implementation
  /// @notice ensures attempted mint is for a valid project
  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  modifier onlyValidMint(uint256 _id, uint256 _amount) {
    require(_id < bridge.nextProjectId(), "!registered");
    require(reserve.projectToMinters(_id, address(this)), "!minter");
    require(
      _amount <= reserve.projectToParameters(_id).maxMintPerTransaction,
      "exceed mint max"
    );
    _;
  }

  constructor(address _bridge, address _reserve) {
    bridge = IArtBridge(_bridge);
    reserve = IBridgeReserve(_reserve);
  }

  /// @dev extensions of base minter can override mint for custom pricing
  /// @dev base minter provides single price validation
  /// @notice mints the requested amount of project tokens
  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  /// @param _to address to mint tokens to
  function mint(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external payable virtual onlyValidMint(_id, _amount) {
    require(
      _amount * bridge.projectToTokenPrice(_id) == msg.value,
      "invalid payment amount"
    );
    bridge.mint(_id, _amount, _to);
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

pragma solidity >=0.8.0;

import {BridgeBeams} from "../libraries/BridgeBeams.sol";

interface IBridgeReserve {
  function projectToParameters(uint256 _id)
    external
    view
    returns (BridgeBeams.ReserveParameters memory);

  function projectToMinters(uint256 _id, address _minter)
    external
    view
    returns (bool);
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
    returns (BridgeBeams.Project memory);

  function projectToTokenPrice(uint256 _id) external view returns (uint256);

  function projectState(uint256 _id)
    external
    view
    returns (
      bool initialized,
      bool mintable,
      bool released,
      uint256 remaining
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Extractble is Ownable {
  function withdraw() external payable onlyOwner {
    require(payable(owner()).send(address(this).balance), "!transfer");
  }

  function extract(address _token) external onlyOwner {
    IERC20 token = IERC20(_token);
    token.transfer(owner(), token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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

  struct ReserveParameters {
    uint256 maxMintPerTransaction;
    uint256 reservedMints;
    bytes32 reserveRoot;
  }

  /// Project Helper Functions

  function isInitialized(Project memory _project) internal pure returns (bool) {
    if (
      _project.id == 0 ||
      bytes(_project.artist).length == 0 ||
      bytes(_project.description).length == 0 ||
      _project.startBlock == 0
    ) {
      return false;
    }
    return true;
  }

  function isReleased(Project memory _project) internal view returns (bool) {
    return _project.startBlock > 0 && _project.startBlock <= block.number;
  }

  function isMintable(Project memory _project) internal view returns (bool) {
    if (!isInitialized(_project)) {
      return false;
    }
    return isReleased(_project) && _project.supply < _project.maxSupply;
  }
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