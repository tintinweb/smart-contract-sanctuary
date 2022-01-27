// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./interfaces/IBLXMTreasuryManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ITreasury.sol";

import "./libraries/BLXMLibrary.sol";

contract BLXMTreasuryManager is Ownable, IBLXMTreasuryManager {

    // token A(B) => token B(A) => treasury
    mapping(address => mapping(address => address)) public override getTreasury;
    address[] public override allTreasury;

    function putTreasury(address tokenA, address tokenB, address treasury) external override onlyOwner {
        require(treasury != address(0), 'TREASURY_NOT_FOUND');
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');

        getTreasury[token0][token1] = treasury;
        getTreasury[token1][token0] = treasury; // populate mapping in the reverse direction

        allTreasury.push(treasury);
        emit TreasuryPut(token0, token1, treasury, allTreasury.length);
    }

    function allTreasuryLength() external view override returns (uint) {
        return allTreasury.length;
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasuryManager {

    event TreasuryPut(address indexed tokenA, address indexed tokenB, address indexed treasury, uint length);

    function putTreasury(address tokenA, address tokenB, address treasury) external;
    function getTreasury(address tokenA, address tokenB) external view returns (address treasury);
    function allTreasury(uint) external view returns (address treasury);
    function allTreasuryLength() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface ITreasury {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transfer() external payable;
    function withdraw(address to, uint amountA, uint amountB) external;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "../interfaces/ITreasury.sol";

import "./SafeMath.sol";


library BLXMLibrary {
    using SafeMath for uint;

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_RESERVES');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address treasury, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITreasury(treasury).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function today() internal view returns(uint) {
        return block.timestamp / 1 days;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    uint constant WAD = 10 ** 18;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}