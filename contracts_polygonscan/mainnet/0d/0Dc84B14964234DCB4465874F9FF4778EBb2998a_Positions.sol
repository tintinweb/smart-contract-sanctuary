/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/interface/IERC20Extented.sol

pragma solidity ^0.8.0;

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}


// File contracts/interface/IAssetToken.sol

pragma solidity ^0.8.0;

interface IAssetToken is IERC20Extented {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function owner() external view;
}


// File contracts/interface/IPositions.sol

pragma solidity ^0.8.2;

struct Position {
    uint256 id;
    address owner;
    // collateral asset token.
    IERC20Extented cAssetToken;
    uint256 cAssetAmount;
    // nAsset token.
    IAssetToken assetToken;
    uint256 assetAmount;
    // if is it short position
    bool isShort;
    bool assigned;
}

interface IPositions {
    function openPosition(
        address owner,
        IERC20Extented cAssetToken,
        uint256 cAssetAmount,
        IAssetToken assetToken,
        uint256 assetAmount,
        bool isShort
    ) external returns (uint256 positionId);

    function updatePosition(Position memory position_) external;

    function removePosition(uint256 positionId) external;

    function getPosition(uint256 positionId)
        external
        view
        returns (Position memory);

    function getNextPositionId() external view returns (uint256);

    function getPositions(
        address ownerAddr,
        uint256 startAt,
        uint256 limit
    ) external view returns (Position[] memory);
}


// File contracts/Positions.sol

pragma solidity ^0.8.2;



contract Positions is IPositions, Ownable {
    using Counters for Counters.Counter;

    // positionId => Position
    mapping(uint256 => Position) private _positionsMap;

    // user address => position[]
    mapping(address => uint256[]) private _positionIdsFromUser;

    Counters.Counter private _positionIdCounter;

    /// @notice Triggered when open a new position.
    /// @param positionId The index of this position.
    event OpenPosition(uint256 positionId);

    /// @notice Triggered when a position be closed.
    /// @param positionId The index of this position.
    event ClosePosition(uint256 positionId);

    constructor() {
        // Start at 1.
        _positionIdCounter.increment();
    }

    /// @notice Create a new position.
    /// @dev Only owner. The owner may always be Mint contract.
    /// @param owner Specify a user who will own the new position.
    /// @param cAssetToken The contract address of collateral token.
    /// @param cAssetAmount The amount of collateral token.
    /// @param assetToken The contract address of nAsset token.
    /// @param assetAmount The amount of nAsset token.
    /// @param isShort Is it a short position.
    /// @return positionId The index of the new position.
    function openPosition(
        address owner,
        IERC20Extented cAssetToken,
        uint256 cAssetAmount,
        IAssetToken assetToken,
        uint256 assetAmount,
        bool isShort
    ) external override onlyOwner returns (uint256 positionId) {
        positionId = _positionIdCounter.current();
        _positionIdCounter.increment();
        _positionsMap[positionId] = Position(
            positionId,
            owner,
            cAssetToken,
            cAssetAmount,
            assetToken,
            assetAmount,
            isShort,
            true
        );
        _positionIdsFromUser[owner].push(positionId);
        emit OpenPosition(positionId);
    }

    /// @notice Update the position.
    /// @dev Only owner. The owner may always be Mint contract.
    /// @param position_ The position which is going to be update.
    function updatePosition(Position memory position_)
        external
        override
        onlyOwner
    {
        _positionsMap[position_.id] = position_;
    }

    /// @notice Delete the position.
    /// @dev Only owner. The owner may always be Mint contract.
    /// @param positionId Position's index.
    function removePosition(uint256 positionId) external override onlyOwner {
        delete _positionsMap[positionId];
        emit ClosePosition(positionId);
    }

    /// @notice Get position by id
    /// @param positionId position id
    /// @return position
    function getPosition(uint256 positionId)
        external
        view
        override
        returns (Position memory)
    {
        return _positionsMap[positionId];
    }

    /// @notice get the next id
    /// @return current positionId + 1
    function getNextPositionId() external view override returns (uint256) {
        return _positionIdCounter.current();
    }

    /// @notice get positions under the owner
    /// @param ownerAddr owner address
    /// @param startAt it's a position id, returning positions will greater than it.
    /// @param limit how many positions do you want
    /// @return Position[]
    function getPositions(
        address ownerAddr,
        uint256 startAt,
        uint256 limit
    ) external view override returns (Position[] memory) {
        uint256[] memory arr = _positionIdsFromUser[ownerAddr];
        Position[] memory positions = new Position[](min(limit, arr.length));
        uint256 index = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] < startAt) {
                continue;
            }
            if (index >= limit) {
                break;
            }
            Position memory position = _positionsMap[arr[i]];
            if (position.assigned) {
                positions[index] = position;
                index += 1;
            }
        }

        return positions;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}