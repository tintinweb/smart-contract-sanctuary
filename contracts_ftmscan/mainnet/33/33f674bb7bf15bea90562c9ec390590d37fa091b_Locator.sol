/**
 *Submitted for verification at FtmScan.com on 2021-12-07
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;


// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)


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


// File @openzeppelin/contracts/access/IOwnable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)


interface IOwnable {
    function owner() external view returns (address);
    
    function pushOwnership(address newOwner) external;
    
    function pullOwnership() external;
    
    function renounceOwnership() external;
    
    function transferOwnership(address newOwner) external;
}


// File @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;
    address private _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
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
     * @dev Sets up a push of the ownership of the contract to the specified
     * address which must subsequently pull the ownership to accept it.
     */
    function pushOwnership(address newOwner) public virtual override onlyOwner {
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner );
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts the push of ownership of the contract. Must be called by
     * the new owner.
     */
    function pullOwnership() public override virtual {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/Locator/Locator.sol

contract Locator is Ownable {
  address public DAO;
  address public RedeemHelper;
  address public Staking;
  address public StakingDistributor;
  address public StakingHelper;
  address public StakingWarmup;
  address public BondCalculator;
  address public BondPriceHelper;
  address public StakedToken;
  address public Token;
  address public Treasury;
  address public WrappedStakedToken;

  enum MANAGING {
    DAO,
    REDEEM_HELPER,
    STAKING,
    STAKING_DISTRIBUTOR,
    STAKING_HELPER,
    STAKING_WARMUP,
    BOND_CALCULATOR,
    BOND_PRICE_HELPER,
    STAKED_TOKEN,
    TOKEN,
    TREASURY,
    WRAPPED_STAKED_TOKEN
  }

  event ChangedAddress(
    MANAGING indexed managing,
    address _oldAddress,
    address _newAddress
  );

  constructor(address _DAO) {
    DAO = _DAO;
    emit ChangedAddress(MANAGING.DAO, owner(), _DAO);
    transferOwnership(_DAO);
  }

  function setAddress(MANAGING _managing, address _address)
    external
    onlyOwner
    returns (bool)
  {
    require(_address != address(0));

    address _old;

    if (_managing == MANAGING.DAO) {
      _old = DAO;
      DAO = _address;
    } else if (_managing == MANAGING.REDEEM_HELPER) {
      _old = RedeemHelper;
      RedeemHelper = _address;
    } else if (_managing == MANAGING.STAKING) {
      _old = Staking;
      Staking = _address;
    } else if (_managing == MANAGING.STAKING_DISTRIBUTOR) {
      _old = StakingDistributor;
      StakingDistributor = _address;
    } else if (_managing == MANAGING.STAKING_HELPER) {
      _old = StakingHelper;
      StakingHelper = _address;
    } else if (_managing == MANAGING.STAKING_WARMUP) {
      _old = StakingWarmup;
      StakingWarmup = _address;
    } else if (_managing == MANAGING.BOND_CALCULATOR) {
      _old = BondCalculator;
      BondCalculator = _address;
    } else if (_managing == MANAGING.BOND_PRICE_HELPER) {
      _old = BondPriceHelper;
      BondPriceHelper = _address;
    } else if (_managing == MANAGING.STAKED_TOKEN) {
      _old = StakedToken;
      StakedToken = _address;
    } else if (_managing == MANAGING.TOKEN) {
      _old = Token;
      Token = _address;
    } else if (_managing == MANAGING.TREASURY) {
      _old = Treasury;
      Treasury = _address;
    } else if (_managing == MANAGING.WRAPPED_STAKED_TOKEN) {
      _old = WrappedStakedToken;
      WrappedStakedToken = _address;
    } else return false;

    emit ChangedAddress(_managing, _old, _address);
    return true;
  }
}