pragma solidity ^0.8.0;

import "./interface/IBounty.sol";
import "./interface/IBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bounty is IBounty, Ownable {

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    uint256 lastPayout;
    uint256 rewardCounter;
    address token;

    mapping (uint256 => mapping(address => uint256)) public quickDrawsPerAccount;
    uint256 highestQuickdrawCount;
    address highestQuickDrawAddress;

    constructor(address _token) {
        token = _token;
        lastPayout = block.timestamp;
    }

    //to recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

    function getTitle() external pure override returns(string memory) {
        return "Fastest Hands In The West";
    }

    function getDescription() external pure override returns(string memory) {
        return "Wanted dead or alive, the user who wins the most quickdraws per week will receive the entire reward pool";
    }

    function logBuy(address user, uint256 amount) external override onlyToken {

    }

    function logSell(address user, uint256 amount) external override onlyToken {

    }

    function logQuickDrawWin(address user, uint256 winnings, uint256 bid) external override onlyToken {

        uint256 count = quickDrawsPerAccount[rewardCounter][user] + 1;
        quickDrawsPerAccount[rewardCounter][user] = count;

        if (count > highestQuickdrawCount) {
            highestQuickdrawCount = count;
            highestQuickDrawAddress = user;
            emit NewWinner(user);
        }

        if (block.timestamp - lastPayout > 1 weeks) {

            emit BountyPayout(user, address(this).balance);
            payable(highestQuickDrawAddress).transfer(address(this).balance);
            highestQuickdrawCount = 0;

            lastPayout = block.timestamp;
            rewardCounter++;

        }

    }

    function recoverBEP20(address _token, uint256 amount) external override onlyOwner {
        IBEP20(_token).transfer(owner(), amount);
    }

}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IBounty {

    event NewWinner(address indexed winner);
    event BountyPayout(address indexed winner, uint256 bnbAmount);

    function getTitle() external pure returns(string memory);

    function getDescription() external pure returns(string memory);

    function logBuy(address user, uint256 amount) external;

    function logSell(address user, uint256 amount) external;

    function logQuickDrawWin(address user, uint256 winnings, uint256 bid) external;

    function recoverBEP20(address _token, uint256 amount) external;

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

