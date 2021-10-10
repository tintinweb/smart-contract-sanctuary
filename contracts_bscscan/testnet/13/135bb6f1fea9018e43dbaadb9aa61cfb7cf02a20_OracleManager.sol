/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-02
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



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


// File contracts/core/ChainLinkLikeOracle.sol

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;

contract ChainLinkLikeOracle is Ownable {
    address public sAsset;
    int256 public answer;
    uint8 public decimals;
    uint256 public updatedAt;

    constructor(address _sAsset, uint8 _decimals) {
        sAsset = _sAsset;
        decimals = _decimals;
    }

    event UpdateOracle(int256 price, uint256 timestamp);

    function updateOracle(int256 price, uint256 timestamp) public onlyOwner {
        require(timestamp > updatedAt, "Old timestamp");

        answer = price;
        updatedAt = timestamp;

        emit UpdateOracle(price, timestamp);
    }

    function latestRoundData()
        public
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (0, answer, updatedAt, updatedAt, 0);
    }
}


// File contracts/core/OracleManager.sol


pragma solidity 0.8.6;


contract OracleManager is Ownable {
    struct OracleEntry {
        ChainLinkLikeOracle sourceOracle;
        uint32 minimumCollateralRatio;
    }

    // sAsset address to oracle
    mapping(address => OracleEntry) public oracle;

    event CreateOracle(
        address indexed sAsset,
        address sourceOracle,
        uint32 indexed minimumCollateralRatio
    );

    function createOracle(
        address sAsset,
        address sourceOracle,
        uint32 minimumCollateralRatio
    ) public onlyOwner {
        require(
            minimumCollateralRatio >= 100,
            "Collateral requirement too low"
        );

        oracle[sAsset].minimumCollateralRatio = minimumCollateralRatio;

        ChainLinkLikeOracle chainLinkOracle = ChainLinkLikeOracle(sourceOracle);
        require(chainLinkOracle.decimals() <= 18, 'Wrong deceimals');
        oracle[sAsset].sourceOracle = chainLinkOracle;

        emit CreateOracle(sAsset, sourceOracle, minimumCollateralRatio);
    }

    event UpdateMinimumCollateral(
        address indexed sAsset,
        uint32 indexed minimumCollateralRatio
    );

    function updateMinimumCollateral(
        address sAsset,
        uint32 minimumCollateralRatio
    ) public onlyOwner {
        require(
            minimumCollateralRatio >= 100,
            "Collateral requirement too low"
        );

        oracle[sAsset].minimumCollateralRatio = minimumCollateralRatio;
        emit UpdateMinimumCollateral(sAsset, minimumCollateralRatio);
    }

    function getOraclePrice(address sAsset) public view returns (uint256) {
        uint decimalsToAdjust = 18 - oracle[sAsset].sourceOracle.decimals();
        (, int256 answer, , , ) = oracle[sAsset].sourceOracle.latestRoundData();
        return uint(answer) * 10**decimalsToAdjust;
    }

    function getOracleTimestamp(address sAsset)
        public
        view
        returns (uint256)
    {
        (, , uint256 startedAt, , ) =
            oracle[sAsset].sourceOracle.latestRoundData();

            return startedAt;
    }

    function getOracleMinimumCollateral(address sAsset)
        public
        view
        returns (uint32)
    {
        return oracle[sAsset].minimumCollateralRatio;
    }
}