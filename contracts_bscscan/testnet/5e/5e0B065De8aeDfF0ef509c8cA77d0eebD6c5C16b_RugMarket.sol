// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./access/Ownable.sol";
import "./token/BEP20/IBEP20.sol";
import "./libraries/Percentages.sol";

struct Listing {
    address token;
    address owner;
    uint256 quantity;
    uint256 price;
    bool taxedToken;
    SaleState state;
}

enum SaleState {
    OPEN,
    SOLD,
    CANCELLED
}

contract RugMarket is Ownable {
    using Percentages for uint256;

    IBEP20              public  zombie;         // The zombie token
    uint                public  taxRate;        // The sales taxes rate for burning ZMBE
    Listing[]           public  listings;       // The market listings
    
    // The tokens that are whitelisted to be traded
    mapping (address => bool) public tokenWhitelist;

    // Burn address
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;

    // Events for notifying about things
    event ListingAdded(uint id, address indexed owner, address indexed token, uint256 quantity, uint256 price);
    event ListingCancelled(uint id);
    event ListingSold(uint id, address indexed buyer, address indexed token, uint256 paid);

    // Constructor for constructing things
    constructor (address _zombie, uint _taxRate) {
        zombie = IBEP20(_zombie);
        taxRate = _taxRate;
    }

    // Function to set the tax rate
    function setTaxRate(uint _taxRate) public onlyOwner() {
        taxRate = _taxRate;
    }

    // Function to change whitelist state for an address
    function setWhitelist(address _token, bool _allowed) public onlyOwner() {
        tokenWhitelist[_token] = _allowed;
    }

    // Function to get the total number of listings
    function totalListings() public view returns (uint) {
        return listings.length;
    }

    // Function to add a listing
    function add(address _token, uint256 _quantity, uint256 _price) public returns (uint) {
        require(tokenWhitelist[_token], 'RugMarket: Token must be whitelisted in order to list');
        IBEP20 token = IBEP20(_token);
        require(token.balanceOf(msg.sender) >= _quantity, 'RugMarket: Insufficent token balance');

        uint256 contractBalanceStart = token.balanceOf(address(this));        
        require(token.transferFrom(msg.sender, address(this), _quantity));        
        uint256 transferredTokens = token.balanceOf(address(this)) - contractBalanceStart;

        require(transferredTokens > 0, 'RugMarket: No tokens were transferred');
        bool taxed = contractBalanceStart != transferredTokens;

        listings.push(Listing({
            token: _token,
            owner: msg.sender,
            quantity: transferredTokens,
            price: _price,
            taxedToken: taxed,
            state: SaleState.OPEN
        }));

        uint id = listings.length - 1;

        emit ListingAdded(id, msg.sender, _token, transferredTokens, _price);
        return id;
    }

    // Function to cancel a listing
    function cancel(uint _id) public {
        require(listings[_id].state == SaleState.OPEN, 'RugMarket: This listing is not open');
        require(listings[_id].owner == msg.sender, 'RugMarket: You do not own this listing');

        IBEP20 token = IBEP20(listings[_id].token);
        require(token.transfer(msg.sender, listings[_id].quantity));

        listings[_id].state = SaleState.CANCELLED;
        emit ListingCancelled(_id);
    }

    // Function to buy a listing
    function buy(uint _id) public {
        require(listings[_id].state == SaleState.OPEN, 'RugMarket: This listing is not open');
        require(zombie.balanceOf(msg.sender) >= listings[_id].price, 'RugMarket: Insufficient ZMBE balance');

        uint256 tax = listings[_id].price.calcPortionFromBasisPoints(taxRate);
        uint256 remaining = listings[_id].price - tax;
        
        IBEP20 token = IBEP20(listings[_id].token);
        require(token.transfer(msg.sender, listings[_id].quantity));
        require(zombie.transferFrom(msg.sender, burnAddr, tax));
        require(zombie.transferFrom(msg.sender, listings[_id].owner, remaining));

        listings[_id].state = SaleState.SOLD;
        emit ListingSold(_id, msg.sender, listings[_id].token, listings[_id].price);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.4;

library Percentages {
    // Get value of a percent of a number
    function calcPortionFromBasisPoints(uint _amount, uint _basisPoints) public pure returns(uint) {
        if(_basisPoints == 0 || _amount == 0) {
            return 0;
        } else {
            uint _portion = _amount * _basisPoints / 10000;
            return _portion;
        }
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor()  {
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