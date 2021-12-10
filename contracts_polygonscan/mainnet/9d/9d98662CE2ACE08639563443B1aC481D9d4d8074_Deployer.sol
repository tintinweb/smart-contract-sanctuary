// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import { Destroyable } from "./common/Destroyable.sol";

contract Deployer is Destroyable {

  mapping(bytes32=>address[]) public deploys;
  mapping(bytes32=>uint256[]) public deploysSalts;
  
  event Deployed(address addr, uint256 salt);

  function deploysByCode(bytes memory code) external view returns(address[] memory){
    bytes32 hash = keccak256(abi.encode(code));
    return deploys[hash];
  }
  function deploysCountByHash(bytes32 hash) external view returns(uint256) {
    return deploys[hash].length;
  }

  function deploysCountByCode(bytes memory code) external view returns(uint256) {
    bytes32 hash = keccak256(abi.encode(code));
    return deploys[hash].length;
  }
  
  function deploysByHash(bytes32 hash) external view returns(address[] memory){
    return deploys[hash];
  }

  function deploysByHashAt(bytes32 hash, uint256 deployIndex) external view returns(address){
    return deploys[hash][deployIndex];
  }

  function deploysByCodeAt(bytes memory code, uint256 deployIndex) external view returns(address){
    bytes32 hash = keccak256(abi.encode(code));
    return deploys[hash][deployIndex];
  }
  
  function saltsByCode(bytes memory code) external view returns(uint256[] memory){
    bytes32 hash = keccak256(abi.encode(code));
    return deploysSalts[hash];
  }

  function saltsByHash(bytes32 hash) external view returns(uint256[] memory){
    return deploysSalts[hash];
  }
  
  function saltsByCodeAt(bytes memory code, uint256 saltIndex) external view returns(uint256){
    bytes32 hash = keccak256(abi.encode(code));
    return deploysSalts[hash][saltIndex];
  }
  
  function saltsByHashAt(bytes32 hash, uint256 saltIndex) external view returns(uint256){
    return deploysSalts[hash][saltIndex];
  }

  function deployOwnable(bytes memory code, uint256 salt, address contractOwner) external onlyOwner returns(address){
    Ownable contractAddress = Ownable(deploy(code, salt));
    contractAddress.transferOwnership(contractOwner);
    return address(contractAddress);
  }
  
  function deploy(bytes memory code, uint256 salt) public onlyOwner returns(address){
    address addr;
    assembly {
    addr := create2(0, add(code, 0x20), mload(code), salt)
        if iszero(extcodesize(addr)) { revert(0,0)  }
    }
    bytes32 hash = keccak256(abi.encode(code));
    deploysSalts[hash].push(salt);
    deploys[hash].push(addr);
    emit Deployed(addr, salt);
    return addr;
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

import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "./Interfaces.sol";

contract Destroyable is Ownable {
  constructor(){
  }
    
  function swipeToken(IERC20 token) public onlyOwner returns(bool) {
    try token.transfer(msg.sender, token.balanceOf(address(this))) {
      return true;
    } catch {
      return false;
    }
  }
  
  function destroy(IERC20[] calldata tokensToSwipe) public onlyOwner {
    for(uint256 i = 0; i < tokensToSwipe.length; i++){
      swipeToken(tokensToSwipe[i]);
    }
    selfdestruct(payable(msg.sender));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

  /**
  * @dev Returns decimals for token
  */
  function decimals() external view returns(uint256);
  /**
  * @dev Returns full name of token
  */
  function name() external view returns(string memory);
  /**
  * @dev Returns symbol of token
  */
  function symbol() external view returns(string memory);
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


interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint256) external;
}