/**
 *Submitted for verification at FtmScan.com on 2022-01-01
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
// (c) INftCollectionSale 01/01/2022 
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface INftCollectionSale is IOwnable {
    /**
        @dev Amount of tokens to be able to be minted.
        @return uint256     Total supply.
     */
    function totalSupply() external view returns(uint256);
    /**
        @dev Amount of tokens minted.
        @return uint256     Total minted.
     */
    function totalMinted() external view returns(uint256);
    /**
        @dev Returns the base Uniform Resource Identifier (URI) for the collection.
     */
    function baseURI() external view returns(string calldata);
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
    
    event Initiated(INftCollectionSale indexed collection, uint64 indexed startTime, uint64 indexed endTime);
    event Finalised();
    event ClaimedRaised(uint256 indexed amount);
    
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

    event Initiated(ISaleModel[] indexed saleModels);
    event SaleDeployed(ISaleModel indexed saleModel, address indexed creator, bool indexed initialised);
    event ModelAdded(ISaleModel indexed saleModel);
    event ModelRemoved(uint256 indexed index);
    event NewCommissioner(address indexed commissioner);
    event NewCommissionPerc(uint256 indexed commissionPerc);

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
}

// File: contracts/SaleFactory.sol

pragma solidity ^0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) SaleFactory 29/12/2021 | SPDX-License-Identifier: MIT
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

contract SaleFactory is ISaleFactory, Ownable {

    IERC20 public constant WETH = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public override COMMISSIONER;
    uint256 public override COMMISSION_PERC;

    bool public initialised;

    ISaleModel[] public models;

    /**
        @notice Must be initialised to use function.
     */ 
    modifier onlyInit() {
        require(initialised, "not initialised");
        _;
    }


    //  Views
    // ----------------------------------------------------------------------

    /**
        @notice Returns the total models available for use.
     */
    function modelsLength() external view returns(uint256) {
        return models.length;
    }


    //  Admin
    // ----------------------------------------------------------------------

    /**
        @notice Deploys all initial models to be used.
        @param _models          Addresses of the initial sale model contracts.
        @param _commissioner    Fee receiver (i.e, DAO).
        @param _commissionPerc  Fee % of total raised sent to fee receiver.
     */
    function initFactory(ISaleModel[] memory _models, address _commissioner, uint256 _commissionPerc) external onlyOwner {
        require(!initialised, "already initialised");
        for (uint256 i; i < models.length; i++) models.push(_models[i]);
        COMMISSIONER = _commissioner;
        COMMISSION_PERC = _commissionPerc;
        initialised = true;
        emit Initiated(_models);
    }

    /**
        @notice Deploy a new model to be used.
        @param model    Address of the new sale model contract.
     */
    function deployModel(ISaleModel model) external override onlyInit onlyOwner {
        models.push(model);
        emit ModelAdded(model);
    }

    /**
        @notice Removes sale model from being available to use. 
        @param index    Element to remove
     */
    function removeModel(uint256 index) external onlyInit onlyOwner {
        require(index < models.length);
        models[index] = models[models.length-1];
        models.pop();
        emit ModelRemoved(index);
    }

    /**
        @notice Assigns new commissioner to receive commissioned funds.
     */
    function newCommissioner(address _commissioner) external onlyOwner {
        COMMISSIONER = _commissioner;
        emit NewCommissioner(_commissioner);
    }

    /**
        @notice Assigns new commission percentage to all new deployed sale contracts.
     */
    function newCommissionPerc(uint256 _commissionPerc) external onlyOwner {
        COMMISSION_PERC = _commissionPerc;
        emit NewCommissionPerc(_commissionPerc);
    }


    //  Sale
    // ----------------------------------------------------------------------

    function createSale(
        INftCollectionSale collection, 
        uint16 model, 
        bytes calldata payload
    ) external override onlyInit returns (address result, bool payloadInit) {
        require(models.length > model, "model not found");
        require(collection.owner() == address(this), "no mint access");

        address cloning = address(models[model]);
        bytes20 targetBytes = bytes20(cloning);

        address cloneContract;
        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            cloneContract := create(0, clone, 0x37)
        }

        // Transfer collection ownership to allow minting
        collection.transferOwnership(cloneContract);

        bool init;

        if (payload.length > 0) {
            // Call `initData` of clonedContract w/ `data`
            (init, ) = cloneContract.call(abi.encodeWithSignature("initData(bytes calldata payload)", payload));
            require(init, "payload initialisation error");
        }

        // Transfer sale contract ownership to caller
        ISaleModel(cloneContract).transferOwnership(msg.sender);

        emit SaleDeployed(ISaleModel(cloneContract), msg.sender, init);

        return (cloneContract, init);
    }
}