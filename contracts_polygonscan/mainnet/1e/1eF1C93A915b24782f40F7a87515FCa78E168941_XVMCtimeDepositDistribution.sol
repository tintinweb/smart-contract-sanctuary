/**
 *Submitted for verification at polygonscan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// File: @openzeppelin/contracts/utils/Context.sol

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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


interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address tokenOwner)  external returns (uint balance);
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IacPool {
  function giftDeposit(uint256 _amount, address _toAddress, uint256 _minToServeInSecs) external;
}

contract XVMCtimeDepositDistribution is Ownable{
    constructor(
        IERC20 _token
    ) {
        // Infinite approve
        IERC20(_token).approve(address(0xD00a313cAAe665c4a828C80fF2fAb3C879f7B08B), type(uint256).max); //vaults
        IERC20(_token).approve(address(0xa999A93221042e4Ecc1D002E0935C4a6c67FD242), type(uint256).max);
        IERC20(_token).approve(address(0x0E6f5D3e65c0D3982275EE2238eb7452EBf8F31D), type(uint256).max);
        IERC20(_token).approve(address(0x0e4f23dE638bd6032ab0146B02f82F5Da0c407aF), type(uint256).max);
        IERC20(_token).approve(address(0xEa76E32F7626B3A1bdA8C2AB2C70A85A8fdebaAB), type(uint256).max);
        IERC20(_token).approve(address(0xD582d1DF416F421288aa4E8E5813661E1d5b3D5f), type(uint256).max);
    }

   function depositIntoPool(address _poolAddress, address[] calldata _to, uint256[] calldata _values, uint256[] calldata _mandatoryTime) external onlyOwner  
   {
      require(_to.length == _values.length && _to.length == _mandatoryTime.length);
      for (uint256 i = 0; i < _to.length; i++) {
          IacPool(_poolAddress).giftDeposit(_values[i], _to[i], _mandatoryTime[i]);
    }
  }

  function withdrawTokens(IERC20 _token) external onlyOwner {
      _token.transfer(payable(msg.sender), _token.balanceOf(address(this)));
  }
}