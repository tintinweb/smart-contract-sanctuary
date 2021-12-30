// SPDX-License-Identifier: MIT
// NovaLabs

pragma solidity ^0.8.4;

import './interfaces/IERC20.sol';
import './interfaces/IERC721Metadata.sol';
import './interfaces/IERC721.sol';

import "./abstracts/Context.sol";
import "./abstracts/Democratic.sol";

contract Market is Context, Democratic {

    uint32 public totalAuctions;

    mapping(address => bool) public ERC721Address;

    function authorizeAddresses(address newaddress) external demokratia() {
        ERC721Address[newaddress] = true;
    }

    struct nftInfo {
        uint256 auctionId;
        address nftContract;
        uint256 tokenId;
        string tokenURI;
    }

    struct auctionNFT {
        uint auctionId;
        address owner;
        uint minPrice;
        uint endAuction;
        address buyer;
        uint sellingPrice;
        bool sold;
    }

    struct auctionInfo{
        uint auctionId;
        uint lastBidNumber;
        address lastbuyer;
        uint lastbid;
    }

    struct buyerInfo{
        uint totalBids;
        uint amountBet;
        bool winner;
    }

    event AuctionCreated (
        uint indexed AuctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 minPrice,
        uint endAuction
    );

    event BidCreated (
        uint indexed AuctionId,
        uint bidNumber,
        address lastbuyer,
        uint lastbid
    );

    event Withdraw (
        uint indexed AuctionId,
        address participant,
        uint amount
    );

    event NFTClaimed (
        uint indexed AuctionId,
        address winner
    );

    mapping(uint => nftInfo) public NFTtoInfo;

    mapping(uint => auctionInfo) public AuctiontoInfo;
    mapping(uint => auctionNFT) public AuctiontoNFT;

    mapping(address => mapping(uint => bool)) public ExistingAuctions;
    mapping(address => mapping(address => mapping(uint => buyerInfo))) public BuyerAuction;

    uint public maxPrice;
    
    function setMaxPrice(uint newMax) external demokratia(){
        require(newMax >= 1000, 'Maximum is too low');
        maxPrice = newMax;
    }

    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _endAuction
    ) external returns(uint) {

        totalAuctions += 1;
        require(!ExistingAuctions[_nftContract][_tokenId], 'Auction already exist');
        require(_endAuction > block.timestamp + 3600, 'You need to set at least one hour auction time');
        
        IERC721 nftFactory = IERC721(_nftContract);
        IERC721Metadata nftFactoryMeta = IERC721Metadata(_nftContract);

        require(_msgSender() == nftFactory.ownerOf(_tokenId), 'Caller must be owner of NFT');
        require(nftFactory.isApprovedForAll(_msgSender(), address(this)), 'Caller must Approve operator');
        require(_minPrice  > 0, "Price must be at least 1 $LENNY");
        require(_minPrice <= maxPrice, "Price must be the less than maxPrice");

        uint256 _auctionId = totalAuctions;
        string memory _uri = nftFactoryMeta.tokenURI(_tokenId);
        
        NFTtoInfo[_auctionId] = nftInfo (
            _auctionId,
            _nftContract,
            _tokenId,
            _uri
        );

        AuctiontoNFT[_auctionId] =  auctionNFT (
            _auctionId,
            _msgSender(),
            _minPrice,
            _endAuction,
            address(0),
            0,
            false
        );

        nftFactory.transferFrom(_msgSender(), address(this), _tokenId);
        
        ExistingAuctions[_nftContract][_tokenId] = true;

        AuctiontoInfo[_auctionId] = auctionInfo (
            _auctionId,
            0,
            address(0),
            0
        );
        
        emit AuctionCreated(
            _auctionId,
            _nftContract,
            _tokenId,
            _msgSender(),
            _minPrice,
            _endAuction
        );

        return _auctionId;
    }

    function createAuctionERC721(
        address _owner,
        address _nftContract,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _endAuction
    ) external returns(uint) {

        require(ERC721Address[_msgSender()], 'Only authorize Smart Contract can call');

        totalAuctions += 1;
        require(!ExistingAuctions[_nftContract][_tokenId], 'Auction already exist');
        require(_endAuction > block.timestamp + 3600, 'You need to set at least one hour auction time');
        
        IERC721Metadata nftFactory = IERC721Metadata(_nftContract);
        
        require(_minPrice  > 0, "Price must be at least 1 $LENNY");
        require(_minPrice <= maxPrice, "Price must be the less than maxPrice");

        uint256 _auctionId = totalAuctions;
        string memory _uri = nftFactory.tokenURI(_tokenId);
        
        NFTtoInfo[_auctionId] = nftInfo (
            _auctionId,
            _nftContract,
            _tokenId,
            _uri
        );

        AuctiontoNFT[_auctionId] =  auctionNFT (
            _auctionId,
            _owner,
            _minPrice,
            _endAuction,
            address(0),
            0,
            false
        );
        
        ExistingAuctions[_nftContract][_tokenId] = true;

        AuctiontoInfo[_auctionId] = auctionInfo (
            _auctionId,
            0,
            address(0),
            0
        );
        
        emit AuctionCreated(
            _auctionId,
            _nftContract,
            _tokenId,
            _msgSender(),
            _minPrice,
            _endAuction
        );

        return _auctionId;
    }


    function updateAuction (uint _auctionId, uint _minPrice, uint _endAuction) external {
        auctionNFT storage auction = AuctiontoNFT[_auctionId];
        require(auction.auctionId == _auctionId, 'Auction have to exist');
        require(auction.owner == _msgSender(), 'update has to be made by the owner');
        require(auction.endAuction <= block.timestamp, 'Auction have to be done');

        auction.minPrice = _minPrice;
        auction.endAuction = _endAuction;
        
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];

        emit AuctionCreated(
            _auctionId,
            infoNFT.nftContract,
            infoNFT.tokenId,
            _msgSender(),
            _minPrice,
            _endAuction
        );
    }

    function bid(uint _auctionId, uint _bidPrice) external {
        auctionNFT storage auction = AuctiontoNFT[_auctionId];
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];

        require(auction.auctionId == _auctionId, 'Auction have to exist');
        require(auction.endAuction >= block.timestamp, 'Auction have to be active');

        auctionInfo storage info = AuctiontoInfo[_auctionId];
        require(_bidPrice > info.lastbid && _bidPrice >= auction.minPrice, 'Bid has to be higher than last Price');

        IERC20 lenny = IERC20(tokenAdd);
        uint newBet = _bidPrice * 10 ** lenny.decimals();
        require(lenny.balanceOf(_msgSender())>= newBet, 'No enought Token');

        buyerInfo storage buyer = BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId];
        require(!buyer.winner, 'You are already Winner');
        
        uint newbid = buyer.totalBids + 1;
        uint amountToAdd = newBet - buyer.amountBet * 10 ** lenny.decimals();

        lenny.transferFrom(_msgSender(), address(this), amountToAdd);

        if( info.lastbuyer!=address(0) ){
            BuyerAuction[info.lastbuyer][infoNFT.nftContract][infoNFT.tokenId].winner = false;
        }

        BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId] = buyerInfo (
            newbid,
            _bidPrice,
            true
        );

        uint newBidNumber = info.lastBidNumber + 1;
        
        AuctiontoInfo[_auctionId] = auctionInfo (
            _auctionId,
            newBidNumber,
            _msgSender(),
            _bidPrice
        );

        emit BidCreated(
            _auctionId,
            newBidNumber,
            _msgSender(),
            _bidPrice
        );
    }

    function withdrawBet (uint _auctionId) external {
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];
        buyerInfo storage buyer = BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId];
        require(!buyer.winner, 'Winner can not call withdrawnBet');
        require(buyer.amountBet != 0, 'Only participant can call');

        IERC20 lenny = IERC20(tokenAdd);
        uint decimalAmount = buyer.amountBet * 10 ** lenny.decimals();
        lenny.transfer(_msgSender(), decimalAmount);

        BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId] = buyerInfo (
            0,
            0,
            false
        );

        emit Withdraw(_auctionId, _msgSender(), decimalAmount);
    }


    function claimNFT (uint _auctionId) external {
        auctionNFT storage auction = AuctiontoNFT[_auctionId];
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];

        require(block.timestamp >= auction.endAuction, 'Selling period must have ended');
        require(!auction.sold, 'NFT already claimed');

        buyerInfo storage buyer = BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId];
        require(buyer.winner, 'Only winner can call this function');
        
        IERC20 lenny = IERC20(tokenAdd);
        uint decimalAmount = buyer.amountBet * 10 ** lenny.decimals();

        lenny.transfer(auction.owner, decimalAmount);

        IERC721 nftFactory = IERC721(infoNFT.nftContract);        
        nftFactory.safeTransferFrom(address(this), _msgSender() , infoNFT.tokenId);

        AuctiontoNFT[_auctionId].buyer = _msgSender();
        AuctiontoNFT[_auctionId].sellingPrice = buyer.amountBet;
        AuctiontoNFT[_auctionId].sold = true;

        emit NFTClaimed (_auctionId, _msgSender());
    }

    function getAllNFT() external view returns (nftInfo[] memory){

        nftInfo[] memory listInfo  = new nftInfo[](totalAuctions);
        
        for (uint i = 1; i <= totalAuctions; i++) {
            nftInfo storage info = NFTtoInfo[i];
            uint index = i - 1;
            listInfo[index] = info;
        }

        return listInfo;
    }

    
    address public tokenAdd;
    
    function addTokenAddress (address newAddress) external demokratia() {
        tokenAdd = newAddress;
    }

    constructor(uint _maxPrice, address _doscAddress) Democratic(_doscAddress) {
        maxPrice = _maxPrice;
    }

}

// SPDX-License-Identifier: MIT
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
    
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

import '../interfaces/IDOSC.sol';
import './Context.sol';
/**
 * @dev Provides implementation on the democratic ownership smart contract
 * and allows the child contract that inherites from the Democratic abstact 
 * to interact with the DemocraticOwnership smart contract. The address of 
 * the DemocraticOwnership smart contact address is set within the constructor
 * and can not be change through the lifetime of the child smart contract.
 *
 */

abstract contract Democratic is Context {
    address public immutable doscAdd;
    address public lastAuthorizedAddress;
    uint256 public lastChangingTime;

    constructor(address _doscAdd) {
        doscAdd = _doscAdd;
    }

    function updateSC() external {
        IDOSC dosc = IDOSC(doscAdd);
        lastAuthorizedAddress = dosc.readAuthorizedAddress();
        lastChangingTime = dosc.readEndChangeTime();
    }

    modifier demokratia() {
        require(lastAuthorizedAddress == _msgSender(), "You are not authorized to change");
        require(lastChangingTime >= block.timestamp, "Time for changes expired");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Nova Labs implementation for the Lenny Verse project

pragma solidity ^0.8.0;

/**
 * @dev Provides the interface of democratic ownership smart contract
 * to interact with. The callable functions are readAuthorizedAddress,
 * readEndChangeTime and RegisterCall.
 */

interface IDOSC {
    function readAuthorizedAddress() external view returns (address);
    function readEndChangeTime() external view returns (uint);
    function registerCall(string memory scname, string memory funcname) external;
}