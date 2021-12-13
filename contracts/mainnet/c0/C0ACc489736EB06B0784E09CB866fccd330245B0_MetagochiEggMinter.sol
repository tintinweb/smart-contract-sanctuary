/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// File contracts/@openzeppelin/contracts/utils/Context.sol



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

// File contracts/@openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


// File contracts/@openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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


// File contracts/final.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

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

interface IMetaGochiEgg {
    function mint(address _to, uint256 _amount) external;
}

contract MetagochiEggMinter is Ownable{
    using SafeMath for uint256;

    modifier onlyClevel() {
        require(msg.sender == walletA || msg.sender == walletB || msg.sender == owner());
    _;
    }

    address walletA;
    address walletB;
    uint256 walletBPercentage = 10;

    IERC20 public founderToken;
    IMetaGochiEgg public founderPack;
    IMetaGochiEgg public normalPack;
    uint256 public minimumFounderAmount = 15000000000000*10**9;  // founder token has 9 decimals!!

    uint256 public mintAmountToPrice = 0.05 ether;

    constructor() {
        walletA = payable(0x352b858FFE3584238870478A53d7cd2339363A3b);
        walletB = payable(0x5FFeB4E72401143BcEC5aDC543EcC5fd388d2A88);
        founderToken = IERC20(0xC1a85Faa09c7f7247899F155439c5488B43E8429);

        founderPack = IMetaGochiEgg(0x7F1cf2796D7C33B8f5AcBB02c7FFfab51F7A3D36);
        normalPack = IMetaGochiEgg(0x90749BcAE7bDeE78fD7b8829aeAc855c32A56376);
    }

    function mint_pack(uint256 _amount) public payable {
        require(msg.value>0 && msg.value == mintAmountToPrice.mul(_amount) , "Invalid value.");
        require(_amount < 50, "Invalid value.");

        bool founder = founderToken.balanceOf(msg.sender)>=minimumFounderAmount;

        if (founder){
            // mint founder
            founderPack.mint(msg.sender, _amount);
        }else{
            // mint normal
            normalPack.mint(msg.sender, _amount);
        }
    }

    // admin and clevel functions
    function setMinimumFounderTokenAmount(uint256 _amount) public onlyOwner {
             minimumFounderAmount = _amount;
    }

    function getMinimumFounderTokenAmount() public view returns(uint256) {
             return minimumFounderAmount;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
             mintAmountToPrice =_price;
    }

    function getMintPrice() public view returns (uint256) {
        return mintAmountToPrice ;
    }

    function withdraw_all() public onlyClevel {
        require (address(this).balance > 0);
        uint256 amountB = SafeMath.div(address(this).balance,100).mul(walletBPercentage);
        uint256 amountA = address(this).balance.sub(amountB);
        payable(walletA).transfer(amountA);
        payable(walletB).transfer(amountB);
    }

    function setWalletA(address _walletA) public {
        require (msg.sender == walletA, "Who are you?");
        require (_walletA != address(0x0), "Invalid wallet");
        walletA = _walletA;
    }

    function setWalletB(address _walletB) public {
        require (msg.sender == walletB, "Who are you?");
        require (_walletB != address(0x0), "Invalid wallet.");
        walletB = _walletB;
    }

    function setWalletBPercentage(uint256 _percentage) public onlyOwner{
        require (_percentage>walletBPercentage && _percentage<=100, "Invalid new slice.");
        walletBPercentage = _percentage;
    }

}


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}