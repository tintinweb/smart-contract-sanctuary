// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPools is Ownable {

  address private AAVE_LENDING_POOL;

  uint256 private COMP_CTOKEN_COUNT;
  TokenPair[] private COMP_TOKEN_LST;
  mapping(address => uint256) private IS_SUPPORTED_COMP_TOKEN;

  event AAVE_LendingPool_Update(address indexed lendingPool);
  event COMP_CToken_Add(address indexed token, address indexed cToken);
  event COMP_CToken_Remove(address indexed token, address indexed cToken);

  struct TokenPair {
    address token;
    address cToken;
  }

  function setAaveConfig(address _lendingPool) external onlyOwner {
    AAVE_LENDING_POOL = _lendingPool;

    emit AAVE_LendingPool_Update(_lendingPool);
  }

  function addCompToken(address _token, address _cToken) external onlyOwner {
    require(IS_SUPPORTED_COMP_TOKEN[_token] == 0, "supported token");

    COMP_TOKEN_LST.push(TokenPair(_token, _cToken));
    IS_SUPPORTED_COMP_TOKEN[_token] = ++COMP_CTOKEN_COUNT;

    emit COMP_CToken_Add(_token, _cToken);
  }

  function removeCompToken(address _token) external onlyOwner {
    require(IS_SUPPORTED_COMP_TOKEN[_token] != 0, "unsupported token");

    uint256 _ind = IS_SUPPORTED_COMP_TOKEN[_token] - 1;
    address _cToken = COMP_TOKEN_LST[_ind].cToken;
    COMP_TOKEN_LST[_ind] = COMP_TOKEN_LST[COMP_TOKEN_LST.length - 1];
    COMP_TOKEN_LST.pop();
    COMP_CTOKEN_COUNT--;
    IS_SUPPORTED_COMP_TOKEN[_token] = 0;

    emit COMP_CToken_Remove(_token, _cToken);
  }

  function deposit(address _token, uint256 _value, uint8 _mode) external returns(bool) {
    if (_mode == 0) {
      /// Aave deposit
      (bool success, ) = AAVE_LENDING_POOL.delegatecall(abi.encodeWithSignature("deposit(address,uint256,address,uint16)", _token, _value, msg.sender, 0));
      return success;
    } else {
      /// Compound deposit
      (bool success, ) = _getCToken(_token).delegatecall(abi.encodeWithSignature("mint(uint256)", _value));
      return success;
    }
  }

  function withdraw(address _token, uint256 _value, uint8 _mode) external returns(bool) {
    if (_mode == 0) {
      /// Aave withdraw
      (bool success, ) = AAVE_LENDING_POOL.delegatecall(abi.encodeWithSignature("withdraw(address,uint256,address", _token, _value, msg.sender));
      return success;
    } else {
      /// Compound withdraw
      (bool success, ) = _getCToken(_token).delegatecall(abi.encodeWithSignature("repayBorrow(uint256)", _value));
      return success;
    }
  }

  function _getCToken(address _token) internal view returns(address) {
    require(IS_SUPPORTED_COMP_TOKEN[_token] != 0, "unsupported token");

    uint256 _ind = IS_SUPPORTED_COMP_TOKEN[_token] - 1;
    return COMP_TOKEN_LST[_ind].cToken;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

