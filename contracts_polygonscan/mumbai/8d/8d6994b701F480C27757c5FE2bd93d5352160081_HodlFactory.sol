/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

pragma solidity ^0.7.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/**
 * @title Spawn
 * @author 0age
 * @notice This contract provides creation code that is used by Spawner in order
 * to initialize and deploy eip-1167 minimal proxies for a given logic contract.
 * SPDX-License-Identifier: MIT
 */
contract Spawn {
  constructor(address logicContract, bytes memory initializationCalldata) payable {
    // delegatecall into the logic contract to perform initialization.
    (bool ok, ) = logicContract.delegatecall(initializationCalldata);
    if (!ok) {
      // pass along failure message from delegatecall and revert.
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // place eip-1167 runtime code in memory.
    bytes memory runtimeCode = abi.encodePacked(
      bytes10(0x363d3d373d3d3d363d73),
      logicContract,
      bytes15(0x5af43d82803e903d91602b57fd5bf3)
    );

    // return eip-1167 code to write it to spawned contract runtime.
    assembly {
      return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
    }
  }
}
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IHodlERC20 {
  function init(
    address _token,
    uint256 _penalty,
    uint256 _lockWindow,
    uint256 _expiry,
    uint256 _fee,
    uint256 _n,
    address _feeRecipient,
    string memory _name,
    string memory _symbol,
    address _bonusToken
  ) external;
}

/**
 * @title HodlSpawner
 * @notice This contract spawns and initializes eip-1167 minimal proxies that
 * point to existing logic contracts.
 * @notice This contract was modified from Spawner.sol
 * https://github.com/0age/Spawner/blob/master/contracts/Spawner.sol to fit into our factory
 */
contract HodlSpawner {
  // fixed salt value because we will only deploy an Hodl pool with the same init value once
  bytes32 private constant SALT = bytes32(0);

  /**
   * @notice internal function for spawning an eip-1167 minimal proxy using `CREATE2`
   * @param logicContract address of the logic contract
   * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
   * from the spawned contract to the logic contract during contract creation
   * @return spawnedContract the address of the newly-spawned contract
   */
  function _spawn(address logicContract, bytes memory initializationCalldata) internal returns (address) {
    // place the creation code and constructor args of the contract to spawn in memory
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

    // spawn the contract using `CREATE2`
    return Create2.deploy(0, SALT, initCode);
  }

  /**
   * @notice internal view function for finding the address of the standard
   * eip-1167 minimal proxy created using `CREATE2` with a given logic contract
   * and initialization calldata payload
   * @param logicContract address of the logic contract
   * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
   * from the spawned contract to the logic contract during contract creation
   * @return target address of the next spawned minimal proxy contract with the
   * given parameters.
   */
  function _computeAddress(address logicContract, bytes memory initializationCalldata)
    internal
    view
    returns (address target)
  {
    // place the creation code and constructor args of the contract to spawn in memory
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );
    // get target address using the constructed initialization code
    bytes32 initCodeHash = keccak256(initCode);

    target = Create2.computeAddress(SALT, initCodeHash);
  }
}

/**
 * @title A factory to create hToken
 * @notice Create new hToken and keep track of all hToken addresses
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for the logic contract
 */
contract HodlFactory is HodlSpawner, Ownable {
  /// @dev mapping from parameters hash to its deployed address
  mapping(bytes32 => address) private _idToAddress;

  /// @dev if the address is a valid hToken deployed by this factory
  mapping(address => bool) private _isValidHToken;

  /// @dev mapping of whitelisted asset to prevent people from creating hodling competition with malicious ERC20.
  mapping(address => bool) public isWhitelistAsset;

  address implementation;

  constructor(address _implementation) {
    require(_implementation != address(0), "INVALID_IMPL");
    implementation = _implementation;
  }

  event AssetWhitelisted(address asset, bool whitelisted);

  /// @notice emitted when the factory creates a new hToken "barrel"
  event HodlCreated(
    address contractAddress,
    address indexed token,
    uint256 indexed penalty,
    uint256 lockWindow,
    uint256 indexed expiry,
    uint256 feePortion,
    uint256 n,
    address feeRecipient,
    address creator,
    address bonusToken
  );

  /**
   * @dev owner only function to whitelist or un-whitelist an asset.
   * the owner should be a governance module
   */
  function whitelistAsset(address _asset, bool _isWhitelist) external onlyOwner {
    isWhitelistAsset[_asset] = _isWhitelist;
    emit AssetWhitelisted(_asset, _isWhitelist);
  }

  /**
   * @notice create new HodlERC20 proxy
   * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
   * @param _token token to hold
   * @param _penalty penalty 1 out of 1000
   * @param _lockWindow duration locked before expiry
   * @param _expiry expiry timestamp
   * @param _fee fee out of every 1000 penalty
   * @param _feeRecipient address that collect fees
   * @param _bonusToken extra reward token (optional, set to zero address if using just the base token)
   * @return newHodl newly deployed contract address
   */
  function createHodlERC20(
    address _token,
    uint256 _penalty,
    uint256 _lockWindow,
    uint256 _expiry,
    uint256 _fee,
    uint256 _n,
    address _feeRecipient,
    address _bonusToken
  ) external returns (address newHodl) {
    bytes32 id = _getHodlId(_token, _penalty, _lockWindow, _expiry, _fee, _n, _feeRecipient, _bonusToken);
    require(_idToAddress[id] == address(0), "CREATED");
    require(isWhitelistAsset[_token], "NOT_WHITELISTED");
    require(_bonusToken == address(0) || isWhitelistAsset[_bonusToken], "NOT_WHITELISTED");
    string memory name;
    string memory symbol;

    {
      // create another scope to avoid stack-too-deep error
      IERC20WithDetail token = IERC20WithDetail(_token);
      string memory tokenName = token.name();
      name = _concat("Hodl", tokenName);

      string memory tokenSymbol = token.symbol();
      symbol = _concat("h", tokenSymbol);
    }

    bytes memory initializationCalldata = abi.encodeWithSelector(
      IHodlERC20(implementation).init.selector,
      _token,
      _penalty,
      _lockWindow,
      _expiry,
      _fee,
      _n,
      _feeRecipient,
      name,
      symbol,
      _bonusToken
    );

    newHodl = _spawn(implementation, initializationCalldata);

    _isValidHToken[newHodl] = true;
    _idToAddress[id] = newHodl;

    emit HodlCreated(newHodl, _token, _penalty, _lockWindow, _expiry, _fee, _n, _feeRecipient, msg.sender, _bonusToken);

    return newHodl;
  }

  /**
   * @notice if no hToken has been created with these parameters, it will return address(0)
   * @param _token token to hold
   * @param _penalty penalty 1 out of 1000
   * @param _lockWindow duration locked before expiry
   * @param _expiry expiry timestamp
   * @param _fee fee out of every 1000 penalty
   * @param _feeRecipient address that collects fees
   * @param _bonusToken extra token for donations
   * @return
   */
  function getCreatedHToken(
    address _token,
    uint256 _penalty,
    uint256 _lockWindow,
    uint256 _expiry,
    uint256 _fee,
    uint256 _n,
    address _feeRecipient,
    address _bonusToken
  ) external view returns (address) {
    bytes32 id = _getHodlId(_token, _penalty, _lockWindow, _expiry, _fee, _n, _feeRecipient, _bonusToken);
    return _idToAddress[id];
  }

  /**
   * @notice get the address at which a new hToken with these parameters would be deployed
   * @dev return the exact address that will be deployed at with _computeAddress
   * @param _token token to hold
   * @param _penalty penalty 1 out of 1000
   * @param _lockWindow duration locked before expiry
   * @param _expiry expiry timestamp
   * @param _fee fee out of every 1000 penalty
   * @param _feeRecipient address that collect fees
   * @param _bonusToken extra token for donations
   * @return
   */
  function getTargetHTokenAddress(
    address _token,
    uint256 _penalty,
    uint256 _lockWindow,
    uint256 _expiry,
    uint256 _fee,
    uint256 _n,
    address _feeRecipient,
    address _bonusToken
  ) external view returns (address) {
    address _implementation = implementation;
    string memory name;
    string memory symbol;

    // create another scope to avoid stack-too-deep error
    {
      IERC20WithDetail token = IERC20WithDetail(_token);
      string memory tokenName = token.name();
      name = _concat("Hodl", tokenName);

      string memory tokenSymbol = token.symbol();
      symbol = _concat("h", tokenSymbol);
    }

    bytes memory initializationCalldata = abi.encodeWithSelector(
      IHodlERC20(_implementation).init.selector,
      _token,
      _penalty,
      _lockWindow,
      _expiry,
      _fee,
      _n,
      _feeRecipient,
      name,
      symbol,
      _bonusToken
    );
    return _computeAddress(_implementation, initializationCalldata);
  }

  /**
   * @dev hash parameters and get a unique hToken id
   * @param _token token to hold
   * @param _penalty penalty 1 out of 1000
   * @param _lockWindow duration locked before expiry
   * @param _expiry expiry timestamp
   * @param _fee fee out of every 1000 penalty
   * @param _feeRecipient address that collect fees
   * @param _bonusToken extra token for donations
   * @return id the unique id of an hToken
   */
  function _getHodlId(
    address _token,
    uint256 _penalty,
    uint256 _lockWindow,
    uint256 _expiry,
    uint256 _fee,
    uint256 _n,
    address _feeRecipient,
    address _bonusToken
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_token, _penalty, _lockWindow, _expiry, _fee, _n, _feeRecipient, _bonusToken));
  }

  function _concat(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }
}

interface IERC20WithDetail is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}