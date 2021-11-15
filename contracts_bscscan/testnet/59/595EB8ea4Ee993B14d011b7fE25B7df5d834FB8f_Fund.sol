//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../crawler/oracle/Price.sol";
import "../crawler/oracle/IPFS.sol";
import "../crawler/oracle/Balance.sol";
import "../crawler/Crawler.sol";
import "../crawler/ICrawler.sol";

contract Fund is Crawler, ICrawler {

    using Price for bytes;
    using IPFS for bytes;
    using Balance for bytes;

    bytes __encodedPriceData;
    bytes __encodedIPFS;
    bytes __encodedBalanceInfo;

    bytes32 public recentReqId;

    constructor() {}

    /* Method to query off-chain oracle */

    function queryPriceOracle() onlyOwner public {
        recentReqId = iterateRequestId();
        bytes32[] memory symbols = new bytes32[](2);
        symbols[0] = "btc";
        symbols[1] = "eth";
        crawlerQuery(recentReqId, BridgePriceOracle, abi.encode(symbols)); // eg. provide specific symbol like "btc","eth"
    }

    function queryIPFS(string memory _id) onlyOwner public {
        recentReqId = iterateRequestId();
        crawlerQuery(recentReqId, BridgeIPFS, bytes(_id));
    }

    /* Example getters */

    function getStoredIPFS() external view returns(string memory) {
        return __encodedIPFS.parseIPFS();
    }

    function getStoredPriceInfo() external view returns(Price.PriceInfo memory) {
        return __encodedPriceData.parsePriceInfo();
    }

    function getBalanceInfo() external view returns(Balance.BalanceInfo memory){
        return __encodedBalanceInfo.parseBalanceInfo();
    }

    /**
     * @dev An implementation of the ICrawler callback function which is called after finished external querying. 
     *
     * Requirements:
     *
     * - resolverAddress must be correct
     */
    function crawlerCallback(bytes32 _reqId, bytes32 _type, bytes calldata _calldata) external override onlyResolver {
        // TODO: implement provable signature 
        // TODO: check request id
        require(_reqId != "", "crawlerCallback: invalid request id");

        if (_calldata.length == 0) {
            // TODO: handle an error
        } else {
            if (_type == BridgePriceOracle) {
                __encodedPriceData = _calldata;
            } else if (_type == BridgeIPFS) {
                __encodedIPFS = _calldata;
            } else if (_type == BridgeBalanceUpdated) {
                __encodedBalanceInfo = _calldata;
            } else {
                revert("crawlerCallback: unimplemented callback type");
            }
        }
    }

    /* Utilities */

    function iterateRequestId() internal view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), blockhash(block.number - 1)));
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Price {

    struct Ask {
        string symbol;
    }

    struct Token {
        bytes32 symbol;
        uint256 price;
    }

    struct PriceInfo {
        bytes32 requestId;
        uint256 aggregatedAt;
        uint256 multiplier;
        Token[] tokens;
    }

    /**
     * @dev Returns the list of price data that contains symbol and price (in USD).
     *
     * Requirements:
     *
     * - data cannot be empty
     */
    function parsePriceInfo(bytes memory _data) internal pure returns (PriceInfo memory priceInfo_) {
        require(_data.length > 0, "parsePriceInfo: invalid encoded price data");
        priceInfo_ = abi.decode(_data, (PriceInfo));
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library IPFS {

    /**
     * @dev Returns the IPFS string of IPFS encoded bytes.
     *
     * Requirements:
     *
     * - data cannot be empty
     */
    function parseIPFS(bytes memory _data) internal pure returns(string memory body_) {
        body_ = string(_data);
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Balance {

    struct Token {
        bytes32 symbol;
        uint256 amount;
    }

    struct BalanceInfo {
        uint256 multiplier;
        Token[] tokens;
    }
    
    /**
     * @dev Returns the amount of each token in fund addresses.
     *
     * Requirements:
     *
     * - data cannot be empty
     */
    function parseBalanceInfo(bytes memory _data) internal pure returns (BalanceInfo memory balanceInfo_) {
        require(_data.length > 0, "parseBalanceInfo: invalid encoded balance data");
        balanceInfo_ = abi.decode(_data, (BalanceInfo));
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../resolver/IResolver.sol";

abstract contract Crawler is Ownable {

    bytes32 public constant BridgePriceOracle = "price_oracle";
    bytes32 public constant BridgeRNG = "rng";
    bytes32 public constant BridgeIPFS = "ipfs";
    bytes32 public constant BridgeBalanceUpdated = "balance_updated";
    bytes32 public constant BridgeMessaging = "messaging_bridge";
    bytes32 public constant BridgeExecutor = "executor_bridge";
    bytes32 public constant BridgeLog = "log";

    address public resolver;

    modifier onlyResolver() {
        require(msg.sender == resolver, "onlyResolver: invalid resolver address");
        _;
    }

    function crawlerQuery(bytes32 _reqId, bytes32 _type, bytes memory _calldata) internal {
        require(resolver != address(0), "crawlerQuery: resolver is not set");
        IResolver(resolver).query(_reqId, _type, _calldata);
    }

    /* Getter & Setter */

    function getResolver() public view returns(address) {
        return resolver;
    }

    function setResolver(address _resolver) onlyOwner public {
        resolver = _resolver;
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICrawler {

    function crawlerCallback(bytes32 _reqId, bytes32 _type, bytes calldata _calldata) external;
    
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IResolver {

    function query(bytes32 _reqId, bytes32 _type, bytes memory _calldata) external;
    
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
        return msg.data;
    }
}

