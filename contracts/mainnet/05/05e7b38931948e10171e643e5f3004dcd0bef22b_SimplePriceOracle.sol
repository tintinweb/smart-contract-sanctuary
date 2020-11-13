// File: openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/PriceOracle.sol

pragma solidity 0.5.16;

interface PriceOracle {
    /// @dev Return the wad price of token0/token1, multiplied by 1e18
    /// NOTE: (if you have 1 token0 how much you can sell it for token1)
    function getPrice(address token0, address token1)
        external view
        returns (uint256 price, uint256 lastUpdate);
}

// File: contracts/SimplePriceOracle.sol

pragma solidity 0.5.16;



contract SimplePriceOracle is Ownable, PriceOracle {
    event PriceUpdate(address indexed token0, address indexed token1, uint256 price);

    struct PriceData {
        uint192 price;
        uint64 lastUpdate;
    }

    /// @notice Public price data mapping storage.
    mapping (address => mapping (address => PriceData)) public store;

    /// @dev Set the prices of the token token pairs. Must be called by the owner.
    function setPrices(
        address[] calldata token0s,
        address[] calldata token1s,
        uint256[] calldata prices
    )
        external
        onlyOwner
    {
        uint256 len = token0s.length;
        require(token1s.length == len, "bad token1s length");
        require(prices.length == len, "bad prices length");
        for (uint256 idx = 0; idx < len; idx++) {
            address token0 = token0s[idx];
            address token1 = token1s[idx];
            uint256 price = prices[idx];
            store[token0][token1] = PriceData({
                price: uint192(price),
                lastUpdate: uint64(now)
            });
            emit PriceUpdate(token0, token1, price);
        }
    }

    /// @dev Return the wad price of token0/token1, multiplied by 1e18
    /// NOTE: (if you have 1 token0 how much you can sell it for token1)
    function getPrice(address token0, address token1)
        external view
        returns (uint256 price, uint256 lastUpdate)
    {
        PriceData memory data = store[token0][token1];
        price = uint256(data.price);
        lastUpdate = uint256(data.lastUpdate);
        require(price != 0 && lastUpdate != 0, "bad price data");
        return (price, lastUpdate);
    }
}