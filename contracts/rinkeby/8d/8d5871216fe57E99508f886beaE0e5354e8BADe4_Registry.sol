//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Registry managed contracts
import "../auctions/IHub.sol";
import "../royalties/IRoyalties.sol";
import "../nft/INft.sol";

contract Registry is Ownable, ReentrancyGuard {
    // -----------------------------------------------------------------------
    // STATE
    // -----------------------------------------------------------------------

    // Storage of current hub instance
    IHub internal hubInstance_;
    // Storage of current royalties instance
    IRoyalties internal royaltiesInstance_;
    // Storage of NFT contract (cannot be changed)
    INft internal nftInstance_;

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _nft) Ownable() {
        require(INft(_nft).isActive(), "REG: Address invalid NFT");
        nftInstance_ = INft(_nft);
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getHub() external view returns (address) {
        return address(hubInstance_);
    }

    function getRoyalties() external view returns (address) {
        return address(royaltiesInstance_);
    }

    function getNft() external view returns (address) {
        return address(nftInstance_);
    }

    function isActive() external view returns (bool) {
        return true;
    }

    // -----------------------------------------------------------------------
    //  ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function updateHub(address _newHub) external onlyOwner nonReentrant {
        IHub newHub = IHub(_newHub);
        require(_newHub != address(0), "REG: cannot set HUB to 0x");
        require(
            address(hubInstance_) != _newHub,
            "REG: Cannot set HUB to existing"
        );
        require(
            newHub.isAuctionHubImplementation(),
            "REG: HUB implementation error"
        );
        require(IHub(_newHub).init(), "REG: HUB could not be init");
        hubInstance_ = IHub(_newHub);
    }

    function updateRoyalties(address _newRoyalties)
        external
        onlyOwner
        nonReentrant
    {
        require(_newRoyalties != address(0), "REG: cannot set ROY to 0x");
        require(
            address(royaltiesInstance_) != _newRoyalties,
            "REG: Cannot set ROY to existing"
        );
        require(IRoyalties(_newRoyalties).init(), "REG: ROY could not be init");
        royaltiesInstance_ = IRoyalties(_newRoyalties);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IHub {
    enum LotStatus {
        NO_LOT,
        LOT_REQUESTED,
        LOT_CREATED,
        AUCTION_ACTIVE,
        AUCTION_RESOLVED,
        AUCTION_RESOLVED_AND_CLAIMED,
        AUCTION_CANCELED
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getLotInformation(uint256 _lotID)
        external
        view
        returns (
            address owner,
            uint256 tokenID,
            uint256 auctionID,
            LotStatus status
        );

    function getAuctionInformation(uint256 _auctionID)
        external
        view
        returns (
            bool active,
            string memory auctionName,
            address auctionContract,
            bool onlyPrimarySales
        );

    function getAuctionID(address _auction) external view returns (uint256);

    function isAuctionActive(uint256 _auctionID) external view returns (bool);

    function getAuctionCount() external view returns (uint256);

    function isAuctionHubImplementation() external view returns (bool);

    function isFirstSale(uint256 _tokenID) external view returns (bool);

    function getFirstSaleSplit()
        external
        view
        returns (uint256 creatorSplit, uint256 systemSplit);

    function getSecondarySaleSplits()
        external
        view
        returns (
            uint256 creatorSplit,
            uint256 sellerSplit,
            uint256 systemSplit
        );

    function getScalingFactor() external view returns (uint256);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function requestAuctionLot(uint256 _auctionType, uint256 _tokenID)
        external
        returns (uint256 lotID);

    // -----------------------------------------------------------------------
    // ONLY AUCTIONS STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function firstSaleCompleted(uint256 _tokenID) external;

    function lotCreated(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionStarted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompleted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompletedAndClaimed(uint256 _auctionID, uint256 _lotID)
        external;

    function cancelLot(uint256 _auctionID, uint256 _lotID) external;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IRoyalties {
    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getBalance(address _user) external view returns (uint256);

    function getCollateral() external view returns (address);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function deposit(address _to, uint256 _amount) external payable;

    function withdraw(uint256 _amount) external payable;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface INft {

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the owner for this token  
     */
    function ownerOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the creator of the token
     */
    function creatorOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _owner The address of the address to check
     * @return  uint256 The number of tokens the user owns
     */
    function balanceOf(address _owner) external view returns(uint256);

    /**
     * @return  uint256 The total number of circulating tokens
     */
    function totalSupply() external view returns(uint256);

    /**
     * @param   _owner Address of the owner
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @return  bool The approved status of the spender against the owner
     */
    function isApprovedSpenderOf(
        address _owner, 
        address _spender, 
        uint256 _tokenID
    )
        external
        view
        returns(bool);

    /**
     * @param   _minter Address of the minter being checked
     * @return  isMinter If the minter has the minter role
     * @return  isActiveMinter If the minter is an active minter 
     */
    function isMinter(
        address _minter
    ) 
        external 
        view 
        returns(
            bool isMinter, 
            bool isActiveMinter
        );

    function isActive() external view returns(bool);

    function isTokenBatch(uint256 _tokenID) external view returns(uint256);

    function getBatchInfo(
        uint256 _batchID
    ) 
        external 
        view
        returns(
            uint256 baseTokenID,
            uint256[] memory tokenIDs,
            bool limitedStock,
            uint256 totalMinted
        );

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @param   _approvalSpender The status of the spenders approval on the 
     *          owner
     * @notice  Will revert if msg.sender is the spender or if the msg.sender
     *          is not the owner of the token.
     */
    function approveSpender(
        address _spender,
        uint256 _tokenID,
        bool _approvalSpender
    )
        external;

    // -----------------------------------------------------------------------
    //  ONLY AUCTIONS (hub or spokes) STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _to Address of receiver 
     * @param   _tokenID Token to transfer
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function transfer(
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function batchTransfer(
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenID ID of token being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    // -----------------------------------------------------------------------
    // ONLY MINTER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenCreator Address of the creator. Address will receive the 
     *          royalties from sales of the NFT
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @notice  Only valid active minters will be able to mint new tokens
     */
    function mint(
        address _tokenCreator, 
        address _mintTo,
        string calldata identifier,      
        string calldata location,
        bytes32 contentHash 
    ) external returns(uint256);

    /**
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @param   _amount Amount of tokens to mint
     * @param   _baseTokenID ID of the token being duplicated
     * @param   _isLimitedStock Bool for if the batch has a pre-set limit
     */
    function batchDuplicateMint(
        address _mintTo,
        uint256 _amount,
        uint256 _baseTokenID,
        bool _isLimitedStock
    )
        external
        returns(uint256[] memory);
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
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}