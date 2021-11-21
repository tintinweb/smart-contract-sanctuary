// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './ISeafortuneRef.sol';

contract SeafortuneBuy is Ownable{
  
  IERC20 token;

  ISeafortuneRef referrer;

  uint256 private _coefficient = 10000;

  uint public minimum = 100 * (10 ** 18); // SFOR

  fallback () external payable {
    
    deposit(address(0x0));
        
  }
    
  receive() external payable {
        
    deposit(address(0x0));
        
  }

  function Setup(address token_addr, address ref_addr) public returns(address){

    token = IERC20(token_addr);

    referrer = ISeafortuneRef(ref_addr);

    return token_addr;
  }

  function deposit(address _referrer) public payable {
    
    uint _sold = msg.value * _coefficient;
        
    require(_sold >= minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');

    require(token.balanceOf(address(this)) >= msg.value, 'INSUFFICIENT CONTRACT BALANCE');

    if(!referrer.hasReferrer(msg.sender) && _referrer != msg.sender){
      referrer.addReferrer(msg.sender, _referrer);
      referrer.addBuyIncome(_referrer, _sold);
    }    
    //require(safeTransfer(address(token), msg.sender, _sold), 'TRANSFER FAILED' ); 
    token.transfer(msg.sender, _sold);  
  }

  // Helpers
  function safeTransfer(address _token, address to, uint value) internal returns (bool){
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function setCoefficient(uint256 coefficient) external onlyOwner returns(bool) {
    _coefficient = coefficient;
    return true;
  }

  function getCoefficient() external view returns(uint256) {
    return _coefficient;
  }

  function withdrawToken(uint256 _amount) external onlyOwner returns(bool){    
    require(token.transfer(owner(), _amount), 'TRANSFER FAILED');
    return true;
  }
  
  function withdrawBnb() external onlyOwner returns(bool){
    if(address(this).balance >= 0){
      payable(owner()).transfer(address(this).balance);
    }
    return true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ISeafortuneRef {

  function addReferrer(address _account, address _referrer) external returns(bool);

  function addBuyIncome(address _account, uint256 _amount) external returns(bool);

  function addRefIncome(address _account, uint256 _amount) external returns(bool);

  function getBuyIncome(address _account) external view returns(uint256);

  function getRefIncome(address _account) external view returns(uint256);

  function getReferrer(address _account) external view returns(address);

  function claimBuyIncome() external payable returns(bool);

  function claimRefIncome() external payable returns(bool);

  function hasReferrer(address _account) external view returns(bool);

  function totalReferrer() external view returns(uint256);

  
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