// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Context.sol";
import "./IBEP20.sol";

interface IWhitelist {
    function isWhitelisted(address investor) external view returns (bool);
}

contract GedditSeedSale is Context, Ownable {
    IWhitelist public _whitelist;
    IBEP20 public _gedditToken;

    struct lockedTokens {
        uint256 amount;
        uint256 timestampToUnlock;
    }

    modifier onlyWhitelisted(address investor) {
        require(_isWhitelisted(investor));
        _;
    }

    mapping(address => lockedTokens[]) private _lockedTokens;

    constructor(IWhitelist whitelist, IBEP20 gedditToken) {
        _whitelist = whitelist;
        _gedditToken = gedditToken;
    }

    function _isWhitelisted(address a) internal view returns (bool) {
        return IWhitelist(_whitelist).isWhitelisted(a);
    }

    function getLockedTokens(address account) public view returns (lockedTokens[] memory) {
        return _lockedTokens[account];
    }

    receive() external payable {
        _lock(_msgSender(), _msgValue());
    }
   
    function _lock(address account, uint256 investingAmount) private onlyWhitelisted(account) returns (bool) {
        
        require(investingAmount > 0, "No funds to lock");
        
        uint256 tokenToTransfer = 2*investingAmount;
        
        _gedditToken.transferFrom(_gedditToken.getOwner(), address(this), tokenToTransfer);
        
        payable(_gedditToken.getOwner()).transfer(investingAmount);
        
        uint256 lastLockTime = block.timestamp;
        
        for (uint i = 0; i <= 3 ; i++) {
            lastLockTime += 4380 hours;
            lockedTokens memory a;
            a.amount = tokenToTransfer / 4;
            a.timestampToUnlock = lastLockTime;
            _lockedTokens[account].push(a);
        }
        
        return true;
    }

    function unlock(address account) external returns (bool) {
        require( account != address(0), "Address should be non zero" );
       
        uint i = 0;
        uint256 tokensToTransfer = 0;
        uint arrayLength = 0;
        
        unchecked { 
            arrayLength = _lockedTokens[account].length - 1;
        }
        
        for (i; i <= arrayLength ; i++) {
            if( _lockedTokens[account][i].amount > 0 && block.timestamp >= _lockedTokens[account][i].timestampToUnlock) {
                tokensToTransfer += _lockedTokens[account][i].amount;
                delete _lockedTokens[account][i];
           }
        }
        
        require( tokensToTransfer > 0 , "No Available funds to unlock" );
        _gedditToken.transfer(account, tokensToTransfer);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
    * @dev Returns the name of the token.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

   
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
pragma solidity 0.8.7;

import "./Context.sol";

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

