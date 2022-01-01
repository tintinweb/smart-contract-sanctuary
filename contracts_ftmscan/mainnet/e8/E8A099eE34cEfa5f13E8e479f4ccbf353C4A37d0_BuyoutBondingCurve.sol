/**
 *Submitted for verification at FtmScan.com on 2021-12-31
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/interfaces/IOwnable.sol

pragma solidity ^0.8.9;
interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external; 
}

// File: contracts/interfaces/INftCollectionSale.sol

pragma solidity 0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) NftLaunchpad 16/12/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface INftCollectionSale is IOwnable {
    /**
        @dev Amount of tokens to be able to be minted.
        @return uint256     Total supply.
     */
    function totalSupply() external returns(uint256);
    /**
        @dev Amount of tokens minted.
        @return uint256     Total minted.
     */
    function totalMinted() external returns(uint256);
    /**
        @dev Allows users to know the URI + whether it has been revealed or not.
        @dev If !revealed, return "".
        @return URI         URI of the metadata.
        @return revealed    Whether URI has been revealed.
     */
    function tokenURI() external returns(string calldata URI, bool revealed);
    /**
        @dev Mint an `tokenId` to the `to` address.
        @param to       Receiver of the NFT.
        @param tokenId  Token being minted.
     */
    function mint(address to, uint256 tokenId) external;
}

// File: contracts/interfaces/ISaleModel.sol

pragma solidity ^0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) ISaleModel 29/12/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface ISaleModel is IOwnable {

    function initData(bytes calldata payload) external;
    
}

// File: contracts/interfaces/ISaleFactory.sol

pragma solidity ^0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) ISaleFactory 28/12/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface ISaleFactory {

    event Initiated();
    event SaleDeployed();
    event NewSaleModel();
    event NewCommissioner();
    event NewCommissionPerc();

    /**
        @notice Gets WETH address.
     */
    function WETH() external returns(IERC20);

    /**
        @notice Gets fee receiver address.
     */
    function COMMISSIONER() external returns(address);

    /**
        @notice Gets commission amount that is used in calculations (i.e, 500 = 0.05).
     */
    function COMMISSION_PERC() external returns(uint256);

    /**
        @notice Deploy a new model to be used.
        @param model    Address of the new sale model contract.
     */
    function deployModel(ISaleModel model) external;

    /**
        @notice Deploy a sale model w/ payload initialisation.
        @param collection       NFT collection being sold.
        @param model            Sale model being used to conduct sale.
        @param payload          Init params data of the sale model.
        @return result          Address of cloned sale contract.
        @return initialised     Whether contract was initialised w/ the `payload` data.
     */
    function createSale(
        INftCollectionSale collection, 
        uint16 model, 
        bytes calldata payload
    ) external returns (address result, bool initialised);

    /**
        @notice Deploy a sale model w/o payload initialisation.
        @param collection       NFT collection being sold.
        @param model            Sale model being used to conduct sale.
        @return result          Address of cloned sale contract.
        @return initialised     Whether contract was initialised (always false).
     */
    function createSale(
        INftCollectionSale collection, 
        uint16 model
    ) external returns (address result, bool initialised);
}

// File: contracts/interfaces/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable is IOwnable {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/SaleModels/BuyoutBondingCurve.sol

pragma solidity ^0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) BuyoutBondingCurve 27/12/2021 | SPDX-License-Identifier: MIT
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

contract BuyoutBondingCurve is ISaleModel, Ownable {

    ISaleFactory public constant SALE_FACTORY = ISaleFactory(0x1E6F82370eA4369F2194EAD228a18eF46D9E36c1);
    IERC20 public constant WETH = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    bool public initialised;

    address public commissioner;
    uint256 public commissionPerc;

     struct Info {
        // Whether sale has ended
        bool finalised;
        // Whether contract has given mint access or not
        bool mintAccess;
        // Address that made the sale
        address creator;
        // Token contract to mint ids from
        // Note: Must be able to give permission to this contract to mint
        INftCollectionSale collection;
        // Amount raised from sale
        uint256 raised;
        // Amount not claimed from raised
        uint256 unclaimed;
    }
    Info private _info;

    struct Sale {
        // Last sale price
        uint256 lastPrice;
        // The starting price of the sale
        uint128 startPrice;
        // Timestamp of when sale ends
        uint64 startTime;
        // Timestamp of when sale ends
        uint64 endTime;
        // Each token sold increases `lastPrice` by this amount
        // i.e,     500: (500 / 10,000 = 0.05)
        uint208 multiplier;
        // Total ids to sell/mint
        uint24 totalSupply;
        // Total ids sold
        uint24 totalSold;
    }
    Sale private _sale;

    event Initiated();
    event ClaimedRaised();
    event Buyout();
    event Finalised();

    /// @notice Must be initialised to use function.
    modifier _init() {
        require(initialised, "not initialised");
        _;
    }

    //  External Init
    // ----------------------------------------------------------------------
    
    /**
        @notice Convert data payload into params + init sale.
     */
    function initData(bytes calldata payload) external override {
        (
            INftCollectionSale _collection,
            uint64 _startTime,
            uint64 _endTime,
            uint128 _startPrice,
            uint208 _multiplier,
            uint24 _totalSupply
        ) = abi.decode(
            payload, (
                INftCollectionSale,
                uint64,
                uint64,
                uint128,
                uint208,
                uint24
            )
        );

        init(
            _collection,
            _startTime,
            _endTime,
            _startPrice,
            _multiplier,
            _totalSupply
        );
    }

    /**
        @notice Convert params into data.
     */
    function getInitData(
        INftCollectionSale _collection,
        uint64 _startTime,
        uint64 _endTime,
        uint128 _startPrice,
        uint208 _multiplier,
        uint24 _totalSupply
    ) external pure returns (bytes memory payload) {
        return abi.encode(
            _collection,
            _startTime,
            _endTime,
            _startPrice,
            _multiplier,
            _totalSupply
        );
    }
    

    //  Sale
    // ----------------------------------------------------------------------

    /**
        @notice Initiate the sale contract.
     */
    function init(
        INftCollectionSale _collection,
        uint64 _startTime,
        uint64 _endTime,
        uint128 _startPrice,
        uint208 _multiplier,
        uint24 _totalSupply
    ) public onlyOwner {
        require(!initialised, "already initializsed");
        require(_collection.owner() == address(this), "this address has no mint access");
        require(_startPrice > 0, "cannot multiply 0");
        require(_startTime >= block.timestamp, "start in future");
        require(_endTime > _startTime, "");
        require(_totalSupply > 0, "cannot mint 0");
        
        _info.creator = msg.sender;
        _info.collection = _collection;
        _info.mintAccess = true;

        _sale.startPrice = _startPrice;
        _sale.lastPrice = _startPrice;
        _sale.multiplier = _multiplier;
        
        _sale.startTime = _startTime;
        _sale.endTime = _endTime;

        _sale.totalSupply = _totalSupply;

        commissioner = SALE_FACTORY.COMMISSIONER();
        commissionPerc = SALE_FACTORY.COMMISSION_PERC();

        emit Initiated();
    }   

    /**
        @notice Creator receives unclaimed raised funds.
     */
    function claimRaised() external _init {
        Info memory mInfo = _info;
        require(msg.sender == mInfo.creator, "no access");
        _info.unclaimed = 0;
        WETH.transferFrom(address(this), mInfo.creator, mInfo.unclaimed);
        emit ClaimedRaised();
    }


    //  Participation
    // ----------------------------------------------------------------------

    /**
        @notice Buyout current bundle.
        @param amountOfNfts     Amount of ids to buy.
     */
    function buyout(uint24 amountOfNfts) external _init {
        Info memory mInfo = _info;
        require(!mInfo.finalised, "sale finalised");
        
        Sale memory mSale = _sale;
        uint256 newTotalSold = mSale.totalSold + amountOfNfts;
        require(newTotalSold <= mSale.totalSupply, "excessive amountOfNfts");

        uint256 cost = getCostFor(amountOfNfts);

        // Send payment + update stats
        WETH.transferFrom(msg.sender, address(this), cost);
        _info.raised += cost;
        _info.unclaimed += cost;

        // SSTORE
        mSale.totalSold += amountOfNfts;
        _sale.totalSold += amountOfNfts;

        newTotalSold = mSale.totalSold + amountOfNfts;

        // Finalise if sold out OR current time > endTime
        if (mSale.totalSold == mSale.totalSupply || block.timestamp > mSale.endTime)  {
            // Finalise sale
            _info.collection.transferOwnership(mInfo.creator);
            _info.finalised = true;
            emit Finalised();
        }

        // Mint bought token(s)
        for (uint256 i; i < amountOfNfts; i++) {
            mInfo.collection.mint(msg.sender, i);
        }

        emit Buyout();
    }
    

    //  Views
    // ----------------------------------------------------------------------

    /**
        @notice Calculates the total cost for the amount of nfts being bought.
        @param amountOfNfts     Amount of ids to buy.
     */
    function getCostFor(uint24 amountOfNfts) public view returns (uint256) {
        Sale memory mSale = _sale;

        uint256 adding;
        uint256 cost;

        // Calculate cost
        for (uint256 i; i < amountOfNfts; i++) {
            // Amount being added onto last price.
            // i.e,     ($100 * 500) / 10,000 = $5
            adding = (mSale.lastPrice * mSale.multiplier) / 10000;
            // i.e,     $100 + $5 = $105
            mSale.lastPrice += adding;
            // add token price to cost
            cost += mSale.lastPrice;
        }

        return cost;
    }

    /**
        @notice Returns all stats to do w/ the sale.
     */
    function getSaleStats() external view returns (Info memory info, Sale memory sale) {
        return (_info, _sale);
    }
}