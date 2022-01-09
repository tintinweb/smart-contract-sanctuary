//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IOpenSea {
    function cancelOrder_ (
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external; 
    
    function approveOrder_ (
        address[7] memory addrs,
        uint[9] memory uints,
        uint8 feeMethod,
        uint8 side,
        uint8 saleKind,
        uint8 howToCall,
        bytes calldata,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired
    ) external;
}

interface IERC720 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract OpenSeaBatchCanceller is Ownable {
    // mainnet
    // address public constant OPENSEA = 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b;
    // address public constant RARIBLE = 0x9757F2d2b135150BBeb65308D4a91804107cd8D6;
    // rinkeby
    address public constant OPENSEA = 0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9;
    // address public constant RARIBLE = 0xd4a57a3bD3657D0d46B4C5bAC12b3F156B9B886b;
    
    // cancel order for opensea
    struct OpenSeaCancelOrder {
        address[7] addrs;
        uint[9] uints;
        uint8 feeMethod;
        uint8 side;
        uint8 saleKind;
        uint8 howToCall;
        bytes calldataOrder;
        bytes replacementPattern;
        bytes staticExtradata;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    
    // listing details for opensea
    struct OpenSeaListing {
        address[7] addrs;
        uint[9] uints;
        uint8 feeMethod;
        uint8 side;
        uint8 saleKind;
        uint8 howToCall;
        bytes calldataListing;
        bytes replacementPattern;
        bytes staticExtradata;
        bool orderbookInclusionDesired;
    }

    // can generate OpenSeaListing from this input
    struct ListingInput {
        address tokenAddress;
        uint256 tokenId;
        uint256 priceInWei;
    }
    
    struct ExchangeDetails {
        address exchange;
        bool isActive;
    }
    
    // calldata supplies data for cancel order function relative to exchangeid
    struct CancelInstruction {
        uint256 exchangeId;
        bytes cancelCalldata;
    }
    
    ExchangeDetails[] public exchanges;
    
    constructor() Ownable() {}
    
    function addExchange(address exchange) external onlyOwner {
        exchanges.push(ExchangeDetails(exchange, true));
    }
    
    function updateExchange(uint256 exchangeId, address _exchange, bool _isActive) external onlyOwner {
        exchanges[exchangeId] = ExchangeDetails(_exchange, _isActive);
    }
    
    function getExchangeDetails(uint256 exchangeId) external view returns (address _exchange, bool _isActive) {
        return (exchanges[exchangeId].exchange, exchanges[exchangeId].isActive);
    }
    
    // allows you to bulk cancel orders given exchange exists
    function generalBatchCanceller(CancelInstruction[] memory instructions, bool revertIfFailure) external {
        for (uint i = 0; i < instructions.length; i++) {
            require(exchanges[instructions[i].exchangeId].isActive, "Exchange is not active");
            _generalCancelOrder(instructions[i], revertIfFailure);
        }
    }

    // allows you to batch list order supplying ListingInput
    // generates OpenSeaListing and calls
    // obvious but only for opensesa
    function listOrders(ListingInput[] memory tokenListings, bool revertIfFailure) external {
        OpenSeaListing[] memory listings = new OpenSeaListing[](tokenListings.length);
        
        for (uint i = 0; i < tokenListings.length; i++) {
            address tokenAddress = tokenListings[i].tokenAddress;
            uint256 tokenId = tokenListings[i].tokenId;
            uint256 priceInWei = tokenListings[i].priceInWei;

            IERC720 t = IERC720(tokenAddress);
            require(msg.sender == t.ownerOf(tokenId), "Not the owner");
            require(t.isApprovedForAll(msg.sender, address(this)), "Need to approve Jenie");

            address[7] memory addrs = [OPENSEA, address(this), address(0), address(0x5b3256965e7C3cF26E11FCAf296DfC8807C01073), tokenAddress, address(0), address(0)];
            uint[9] memory uints = [250, 0, 0, 0, priceInWei, 0, block.timestamp, 0, uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))];
            bytes memory transferCalldata = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(0), tokenId);
            bytes memory replacementPattern = bytes(hex"000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000000000000000000000000000");

            OpenSeaListing memory listing = OpenSeaListing(addrs, uints, 1, 1, 0, 0, transferCalldata, replacementPattern, bytes(""), true);
            listings[i] = listing;
        }
        
        batchList(listings, revertIfFailure);
    }

    // batch list orders using OpenSeaListing
    // obvious but only for opensea
    function batchList(OpenSeaListing[] memory listings, bool revertIfFailure) public {
        for (uint i = 0; i < listings.length; i++) {
            _listOrder(listings[i], revertIfFailure);
        }
    }

    // batch cancel opensea orders supply OpenSeaCancelOrder
    function batchCancel(OpenSeaCancelOrder[] memory orders, bool revertIfFailure) external {
        for (uint i = 0; i < orders.length; i++) {
            _cancelOrder(orders[i], revertIfFailure);
        }
    }
    
    function _generalCancelOrder(CancelInstruction memory instruction, bool revertIfFailure) internal {
        (bool success, ) = exchanges[instruction.exchangeId].exchange.call(instruction.cancelCalldata);
        if (!success && revertIfFailure) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
    
    function _listOrder(OpenSeaListing memory listing, bool revertIfFailure) internal {
        bytes memory _data = abi.encodeWithSelector(IOpenSea.approveOrder_.selector, listing.addrs, listing.uints, listing.feeMethod, listing.side, listing.saleKind, listing.howToCall, listing.calldataListing, listing.replacementPattern, listing.staticExtradata);
        (bool success, ) = OPENSEA.call(_data);
        if (!success && revertIfFailure) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _cancelOrder(OpenSeaCancelOrder memory order, bool revertIfFailure) internal {
        require(order.addrs[1] == address(this), "Maker is not Jenie");
        bytes memory _data = abi.encodeWithSelector(IOpenSea.cancelOrder_.selector, order.addrs, order.uints, order.feeMethod, order.side, order.saleKind, order.howToCall, order.calldataOrder, order.replacementPattern, order.staticExtradata, order.v, order.r, order.s);
        (bool success, ) = OPENSEA.call(_data);
        if (!success && revertIfFailure) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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