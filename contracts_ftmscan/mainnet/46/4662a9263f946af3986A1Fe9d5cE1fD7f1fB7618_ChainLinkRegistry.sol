/**
 *Submitted for verification at FtmScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface ChainlinkOracle is IERC20 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function lastRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint256);
    function latestTimestamp() external view returns (uint256);
    function version() external view returns (uint256);
}

contract ChainLinkRegistry is Ownable {
    mapping(address => address) public feeds;

    function addFeed(address token, address feed) public onlyOwner {
        require(IERC20(token).decimals() != 0, "token does not appear to be a valid ERC20");
        require(ChainlinkOracle(feed).version() != 0, "feed does not appear to be a chainlink feed");
        feeds[token] = feed;
    }

    function decimals(address token) public view returns (uint8) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).decimals();
    }

    function description(address token) public view returns (string memory) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).description();
    }

    function lastRoundData(address token) public view returns (uint80, int256, uint256, uint256, uint80) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).lastRoundData();
    }

    function latestAnswer(address token) public view returns (int256) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).latestAnswer();
    }

    function latestRound(address token) public view returns (uint256) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).latestRound();
    }

    function latestTimestamp(address token) public view returns (uint256) {
        require(feeds[token] != address(0), "feed does not exist for token");
        return ChainlinkOracle(feeds[token]).latestTimestamp();
    }

    function removeFeed(address token) public onlyOwner {
        require(IERC20(token).decimals() != 0, "token does not appear to be a valid ERC20");
        delete feeds[token];
    }
}