//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IFirstDibsMarketSettings.sol';

contract FirstDibsMarketSettings is Ownable, IFirstDibsMarketSettings {
    uint16 public override globalTimeBuffer = 15 * 60; // default global auction time buffer (if bid is made in last 15 min, extend auction another 15 min)
    uint64 public override globalAuctionDuration = 24 * 60 * 60; // default global auction duration (24 hours)
    uint8 public override globalMarketCommission = 5; // default commission for auction admin (1stDibs)
    uint8 public override globalCreatorRoyaltyRate = 5; // default royalties to creators
    uint8 public override globalMinimumBidIncrement = 10; // 10% min bid increment
    address public override commissionAddress; // address of the auction admin (1stDibs)

    constructor(address _commissionAddress) public {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );

        commissionAddress = _commissionAddress; // receiver address for auction admin (globalMarketplaceCommission gets sent here)
    }

    modifier nonZero(uint256 value) {
        require(value > 0, 'Value must be greater than zero');
        _;
    }

    /**
     * @dev setter for global auction admin
     * @param _commissionAddress address of the global auction admin (1stDibs wallet)
     */
    function setCommissionAddress(address _commissionAddress) external onlyOwner {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );
        commissionAddress = _commissionAddress;
    }

    /**
     * @dev setter for global time buffer
     * @param timeBuffer new time buffer in seconds
     */
    function setGlobalTimeBuffer(uint16 timeBuffer) external onlyOwner nonZero(timeBuffer) {
        globalTimeBuffer = timeBuffer;
    }

    /**
     * @dev setter for global auction duration
     * @param auctionDuration new auction duration in seconds
     */
    function setGlobalAuctionDuration(uint32 auctionDuration)
        external
        onlyOwner
        nonZero(auctionDuration)
    {
        globalAuctionDuration = auctionDuration;
    }

    /**
     * @dev setter for global market commission rate
     * @param marketCommission new market commission rate
     */
    function setGlobalMarketCommission(uint8 marketCommission) external onlyOwner {
        require(marketCommission >= 3, 'Market commission cannot be lower than 3%');
        globalMarketCommission = marketCommission;
    }

    /**5
     * @dev setter for global creator royalty rate
     * @param royaltyRate new creator royalty rate
     */
    function setGlobalCreatorRoyaltyRate(uint8 royaltyRate) external onlyOwner {
        require(royaltyRate >= 2, 'Creator royalty cannot be lower than 2%');
        globalCreatorRoyaltyRate = royaltyRate;
    }

    /**
     * @dev setter for global minimum bid increment
     * @param bidIncrement new minimum bid increment
     */
    function setGlobalMinimumBidIncrement(uint8 bidIncrement)
        external
        onlyOwner
        nonZero(bidIncrement)
    {
        globalMinimumBidIncrement = bidIncrement;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

interface IFirstDibsMarketSettings {
    function globalTimeBuffer() external view returns (uint16);

    function globalAuctionDuration() external view returns (uint64);

    function globalMarketCommission() external view returns (uint8);

    function globalCreatorRoyaltyRate() external view returns (uint8);

    function globalMinimumBidIncrement() external view returns (uint8);

    function commissionAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1348
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}