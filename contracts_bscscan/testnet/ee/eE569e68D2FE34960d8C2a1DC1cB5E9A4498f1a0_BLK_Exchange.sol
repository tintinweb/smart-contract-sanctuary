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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function burn(address addr_,uint amount_) external returns (bool);

    function mint(address addr_, uint amount_) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BLK_Exchange is Ownable {
    IERC20 public USDB;
    mapping(address =>mapping(address => uint))public record;
    mapping(address =>bool)public coinList;
    uint public limit = 10000 ether;
    uint public total;

    event SwapForCoin(address indexed sender_, address indexed coin_,uint amount_);
    event SwapForUsdb(address indexed sender_, address indexed coin_,uint amount_);

    function swapForUsdb(uint amount_,address coin_) public {
        require(coinList[coin_],'wrong coin');
        require(total + amount_ <= limit, 'over limit');
        USDB.mint(msg.sender, amount_);
        IERC20(coin_).transferFrom(msg.sender, address(this), amount_);
        record[msg.sender][coin_] += amount_;
        total += amount_;
        emit SwapForUsdb(msg.sender, coin_,amount_);
    }

    function swapForCoin(uint amount_,address coin_) public {
        require(coinList[coin_],'wrong coin');
        require(amount_ <= record[msg.sender][coin_], 'out limit');
        IERC20(coin_).transfer(msg.sender, amount_);
        USDB.burn(msg.sender,amount_);
        record[msg.sender][coin_] -= amount_;
        total -= amount_;
        emit SwapForCoin(msg.sender, coin_,amount_);
    }

    function setLimit(uint com_) public onlyOwner {
        limit = com_;
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }
    function setToken(address UB_) public onlyOwner {
        USDB = IERC20(UB_);
    }

    function addToken(address addr_)public onlyOwner{
        coinList[addr_] = true;
    }

    function deleteToken(address addr_)public onlyOwner{
        coinList[addr_] = false;
    }
}