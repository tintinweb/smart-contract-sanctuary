/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: Context

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

// Part: IERC20

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

// Part: Ownable

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

// Part: clientWallet

contract clientWallet is Context, Ownable {


  event ERC20transfered(address indexed token, address indexed client, uint256 amount);
  event ETHtransfered(address clientWallet, uint256 amount);
  event destinationChanged(address oldDestination, address newDestination);

  address public destination;
  address public factory;
  string public clientName;

  constructor() {
    factory = msg.sender;
  }

  receive() external payable {}

  function initialize(string memory _clientName, address _destination) external {
    require(msg.sender == factory, 'Only Factory can initialize');
    destination = _destination;
    clientName = _clientName;
  }

  function changeDestination(address payable _newDestination) public onlyOwner {
    address oldDestination = destination;
    destination = _newDestination;
    emit destinationChanged(oldDestination, _newDestination);
  }

  function transferETH() public onlyOwner returns(bool){
    _transferETH();
    return true;
  }

  function transferERC20(address tokenAddress) public onlyOwner returns(bool){
    uint256 balanceContract = IERC20(tokenAddress).balanceOf(address(this));
    _transferERC2O(tokenAddress, balanceContract);
    emit ERC20transfered(tokenAddress, destination, balanceContract);
    return true;
  }

  function _transferERC2O(address tokenAddress, uint256 _amount) internal {
    IERC20(tokenAddress).transfer(destination, _amount);
  }

  function _transferETH() internal {
    uint256 balanceThisContract = address(this).balance;
    payable(destination).transfer(balanceThisContract);
    emit ETHtransfered(address(this), balanceThisContract);
  }


}

// File: clientWalletFactory.sol

contract clientWalletFactory is Ownable{

  event walletCreated(string indexed _clientName, address _destination, uint256);
  address[] public allClients;


  function createClientWallet(string memory _clientName, address _destination) external onlyOwner returns (address wallet) {
    bytes memory bytecode = type(clientWallet).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(_clientName, _destination));
    assembly {
        wallet := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    clientWallet(payable(wallet)).initialize(_clientName, _destination);
    clientWallet(payable(wallet)).transferOwnership(msg.sender);
    allClients.push(wallet);
    emit walletCreated(_clientName, _destination, allClients.length);
  }
}