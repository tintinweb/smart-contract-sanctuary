//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IFirstDibsMarketSettings.sol';

contract FirstDibsMarketSettings is Ownable, IFirstDibsMarketSettings {
    // default buyer's premium (price paid by buyer above winning bid)
    uint32 public override globalBuyerPremium = 0;

    // default commission for auction admin (1stDibs)
    uint32 public override globalMarketCommission = 5;

    // default royalties to creators
    uint32 public override globalCreatorRoyaltyRate = 5;

    // 10% min bid increment
    uint32 public override globalMinimumBidIncrement = 10;

    // default global auction time buffer (if bid is made in last 15 min,
    // extend auction another 15 min)
    uint32 public override globalTimeBuffer = 15 * 60;

    // default global auction duration (24 hours)
    uint32 public override globalAuctionDuration = 24 * 60 * 60;

    // address of the auction admin (1stDibs)
    address public override commissionAddress;

    constructor(address _commissionAddress) public {
        require(
            _commissionAddress != address(0),
            'Cannot have null address for _commissionAddress'
        );

        commissionAddress = _commissionAddress; // receiver address for auction admin (globalMarketplaceCommission gets sent here)
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, 'Value must be greater than zero');
        _;
    }

    /**
     * @dev Modifier used to ensure passed value is <= 100. Handy to validate percent values.
     * @param _value uint256 to validate
     */
    modifier lte100(uint256 _value) {
        require(_value <= 100, 'Value must be <= 100');
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
     * @param _timeBuffer new time buffer in seconds
     */
    function setGlobalTimeBuffer(uint32 _timeBuffer) external onlyOwner nonZero(_timeBuffer) {
        globalTimeBuffer = _timeBuffer;
    }

    /**
     * @dev setter for global auction duration
     * @param _auctionDuration new auction duration in seconds
     */
    function setGlobalAuctionDuration(uint32 _auctionDuration)
        external
        onlyOwner
        nonZero(_auctionDuration)
    {
        globalAuctionDuration = _auctionDuration;
    }

    /**
     * @dev setter for global buyer premium
     * @param _buyerPremium new buyer premium percent
     */
    function setGlobalBuyerPremium(uint32 _buyerPremium) external onlyOwner {
        globalBuyerPremium = _buyerPremium;
    }

    /**
     * @dev setter for global market commission rate
     * @param _marketCommission new market commission rate
     */
    function setGlobalMarketCommission(uint32 _marketCommission)
        external
        onlyOwner
        lte100(_marketCommission)
    {
        require(_marketCommission >= 3, 'Market commission cannot be lower than 3%');
        globalMarketCommission = _marketCommission;
    }

    /**5
     * @dev setter for global creator royalty rate
     * @param _royaltyRate new creator royalty rate
     */
    function setGlobalCreatorRoyaltyRate(uint32 _royaltyRate)
        external
        onlyOwner
        lte100(_royaltyRate)
    {
        require(_royaltyRate >= 2, 'Creator royalty cannot be lower than 2%');
        globalCreatorRoyaltyRate = _royaltyRate;
    }

    /**
     * @dev setter for global minimum bid increment
     * @param _bidIncrement new minimum bid increment
     */
    function setGlobalMinimumBidIncrement(uint32 _bidIncrement)
        external
        onlyOwner
        nonZero(_bidIncrement)
    {
        globalMinimumBidIncrement = _bidIncrement;
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
pragma solidity 0.6.12;

interface IFirstDibsMarketSettings {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalCreatorRoyaltyRate() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

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

