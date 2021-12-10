/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
/**
* @title Revenue Manager
* @author Carson Case 
* @dev A contract to manage the revenues of the Roci Platform
 */
contract RevenueManager is PaymentSplitter{
    mapping(address => bool) public investors;

    constructor() PaymentSplitter(){}

    /**
    * @dev adds more investors
    * @param _investors are to be added
     */
    function addInvestors(address[] calldata _investors) external onlyOwner{
        for(uint i = 0; i < _investors.length; i++){
            investors[_investors[i]] = true;
        }
    }

    /**
    * @dev removes investors
    * @param _investors are to be removed
     */
    function removeInvestors(address[] calldata _investors) external onlyOwner{
        for(uint i = 0; i < _investors.length; i++){
            investors[_investors[i]] = false;
        }
    }

    /**
    * @dev  returns the balance available for a caller to request
     */
    function balanceAvailable(address _caller, address _token) external returns(uint){
        if(investors[_caller]){
            return (IERC20(_token).balanceOf(address(this)));
        }
        return 0;
    }

    /**
    * @dev for investors to request funds (for balancing)
     */
    function requestFunds(address _token, uint _amount) external{
        require(investors[msg.sender], "only verified investors may request funds");
        IERC20(_token).transfer(msg.sender, _amount);
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title Payment Splitter
* @author Carson Case 
* @dev A contract to split ERC20 tokens among several addresses and is updateable
 */
abstract contract PaymentSplitter is Ownable{
    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
    // array of Shares to be itterated
    Share[] public shares;
    // total shares to determine how much a share is worth
    uint public totalShares;

    /// @dev empty constructor
    constructor() Ownable(){}

    /**
    * @dev utility function to easily get shares length 
     */
    function getSharesLength() external view returns(uint){
        return(shares.length);
    }

    /**
    * @dev dev function to add more payees and their shares
    * @param _payees is the array of addresses
    * @param _shares is the arrya of share amounts. Must be the same size as Payees
     */
    function addShares(address[] calldata _payees, uint[] calldata _shares) external onlyOwner{
        require(_payees.length == _shares.length);

        for(uint i = 0; i < _payees.length; i++){
            shares.push(Share(_payees[i],_shares[i]));
            totalShares += _shares[i];
        }

    }

    /**
    * @dev Owner function to remove shares by indecies 
    * @param _indecies is the array of indecies to remove from Shares array
     */
    function removeShares(uint[] calldata _indecies) external onlyOwner{
        for(uint i = 0; i < _indecies.length; i++){
            totalShares -= shares[_indecies[i]].share;
            delete shares[_indecies[i]];
        }
    }

    /**
    * @dev function to complete a payment in ERC20 according to the splitter
    * @param _tokenContract address
    * @param _amount to transfer
     */
    function payment(address _tokenContract, uint _amount) public virtual{
        IERC20 token = IERC20(_tokenContract);
        token.transferFrom(msg.sender, address(this), _amount);

        // loop through all shares to send tokens to the shareholders
        for(uint i = 0; i < shares.length; i++){
            Share memory s = shares[i];
            /// NOTE do not do a transfer if sending the this to save gas
            if(s.payee != address(this)){
                token.transferFrom(address(this), s.payee, (_amount * s.share / totalShares));
            }
        }
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