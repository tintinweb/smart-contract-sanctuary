/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}

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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Strings for uint256;

    AggregatorV3Interface internal priceFeed;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping tokenId to month
    mapping (uint256 => uint8) private _tokenMonths;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // How many NFTs have been issued for each period;
    mapping (uint8 => uint16) public madePerPeriod;


    // unix time stamps in seconds for each month for the next 50 months
    // startTimes[49] means that you are predicting no flippening in the next 4 years
    // GMT Time
    uint32[] public startTimes = [1619827200, 1622505600, 1625097600, 1627776000, 1630454400, 1633046400,
    1635724800, 1638320400, 1640998800, 1643677200, 1646096400, 1648771200, 1651363200, 1654041600, 1656633600, 1659312000,
    1661990400, 1664582400, 1667260800, 1669856400, 1672534800, 1675213200, 1677632400, 1680307200, 1682899200, 1685577600,
    1688169600, 1690848000, 1693526400, 1696118400, 1698796800, 1701392400, 1704070800, 1706749200, 1709254800, 1711929600,
    1714521600, 1717200000, 1719792000, 1722470400, 1725148800, 1727740800, 1730419200, 1733014800, 1735693200, 1738371600,
    1740790800, 1743465600, 1746057600, 1748736000];


	// prices[x] represents the price of the xth token purchased that month in wei
    uint64[] public prices = [10000000000000000
    , 12500000000000000
    , 15000000000000000
    , 17500000000000000
    , 20000000000000000
    , 25000000000000000
    , 30000000000000000
    , 35000000000000000
    , 40000000000000000
    , 47500000000000000
    , 55000000000000000
    , 62500000000000000
    , 70000000000000000
    , 80000000000000000
    , 90000000000000000
    , 100000000000000000
    , 110000000000000000
    , 122500000000000000
    , 135000000000000000
    , 147500000000000000
    , 160000000000000000
    , 175000000000000000
    , 190000000000000000
    , 205000000000000000
    , 220000000000000000
    , 237500000000000000
    , 255000000000000000
    , 272500000000000000
    , 290000000000000000
    , 310000000000000000
    , 310000000000000000
    ];

   
    uint256 public numTokens = 0;

    // Which NFTs have already claimed their prize
    mapping (uint256 => bool) idsClaimed;

    // How Many NFTs have successfully claimed their prizes
    uint8 tokenClaimCount;

    address payable contractOwner;

    // The unix timestamp of when the flippening has occured
    // and the contract has been called, or 0.
    uint64 public flippeningTime = 0;

    // Amount [in wei] currently payable to winners
    uint256 public payoutBalance = 0;

    // Amount to be paid to devs and artists
    uint256 public artistBalance = 0;

	// Address of gitcoin's multisig wallet
	// gitcoin balance can only be sent to this address.
    address payable gitcoinMatchingMultiSig =  payable (0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6);

    // Amount [in wei] currently payable to gitcoin matching funds
    uint256 public gitcoinBalance = 0;
    
    // historical amount [in wei] already paid to gitcoin matching funds
    uint256 public gitcoinHistorical = 0;

    //price where ETH market cap flips Btc
    // This is how many wei can be bought for 1 btc
    int256 flippeningRatio = 6179713906000000000;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () {
        _name = "FlippeningNFT";
        _symbol = "FLIP";

        // https://data.chain.link/btc-eth
		// Mainnet chainlink address
		// https://etherscan.io/address/0xdeb288F737066589598e9214E782fa5A8eD689e8
        priceFeed = AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8);
        contractOwner = payable(msg.sender);
    }


    function getLatestPrice() public view returns (int) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function monthOf(uint256 tokenId) public view returns (uint8) {
        return _tokenMonths[tokenId];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "https://www.ethflippening.com/uri/";
    }

    function createNFT(uint8 period) public payable {

        // Calculate the price and make sure they have sent enough
        require(msg.value >= prices[madePerPeriod[period]], 'You need to send at least the current price');

        // Make sure that the maximum number of tokens have not already been created for that period.
        require(madePerPeriod[period] < 31, 'Max tokens for that period already minted');

        // Tokens can no longer be minted after the flippening has been recorded
        require(flippeningTime == 0, 'Tokens must be created before flippening is recorded');
        
        // Only 50 periods are available
        require(period < 50, 'Only 50 months are available');

        // Create the token
        _mint(msg.sender, numTokens);

        // Update token month
        _tokenMonths[numTokens] = period;

        // Increment
        numTokens ++;

        // Update number per period
        madePerPeriod[period] ++;

        // Handle money sent
        payoutBalance = payoutBalance + msg.value * 45 / 100;
        gitcoinBalance = gitcoinBalance + msg.value * 6 / 100;
        artistBalance = artistBalance + msg.value * 49 / 100;
    }


    // This function is called when someone claims a prize
    // but can also be called by anyone to record the event
    // without claiming.
    function recordFlippening() public {
        int256 ratio = getLatestPrice();
     
       

        require(flippeningTime == 0, 'Flippening has already been recorded');

        // Check if the flippening has happened via the ratio
        // if so, record the current time
        if (ratio <= flippeningRatio) {
            flippeningTime = uint64(block.timestamp);
        }

        // Record the current time if we have already passed the end
        // and no flippening has occured
        if (flippeningTime == 0 && ratio > flippeningRatio && uint32(block.timestamp) > uint32(startTimes[49]) ) {
            flippeningTime = uint64(block.timestamp);
        }
    }


    function tokenClaimed(uint256 tokenId) public view returns(bool)  {
        return idsClaimed[tokenId];
    }

    function claimPrize(uint256 tokenId) public {

        require(msg.sender == ownerOf(tokenId), 'Only the token owner may claim');

        require(idsClaimed[tokenId] == false, 'This token has already claimed the prize');

        // Check if flippening has occured
        // If so, set timestamp
        if (flippeningTime == 0) {
            recordFlippening();
        }

        // Make sure the token is in the correct period
        // Either flippening time is greater than start time of the month you picked and less than the month you picked + 1
        // Or, you have picked the last month and the flippening time is greater than this

        require ((flippeningTime > startTimes[_tokenMonths[tokenId]] && flippeningTime < startTimes[_tokenMonths[tokenId] + 1]) ||
            (flippeningTime > startTimes[49] && _tokenMonths[tokenId] == 49), "You have not won");

        idsClaimed[tokenId] = true;

        // Transfer prize amount to token owner
        uint256 weiToSend = payoutBalance / (madePerPeriod[_tokenMonths[tokenId]] - tokenClaimCount);
        tokenClaimCount++;
        payoutBalance = payoutBalance - weiToSend;
    
        address payable winner = payable(msg.sender);
        (bool success, ) = winner.call{value: weiToSend}("");
        require(success, "Transfer failed.");
       
    }


    // Anyone can call this function to send gitcoin's share to their multisig wallet
    // This can be called with any balance, and the caller will be responsible for the
    // gas fee

    function donateToGitcoin() public {
        if (gitcoinBalance > 0) {
            uint256 toSend = gitcoinBalance;
            gitcoinHistorical += gitcoinBalance;
            gitcoinBalance = 0;
            (bool success, ) = gitcoinMatchingMultiSig.call{value: toSend}("");
            require(success, "Transfer failed.");
        }

    }

    // If called by an owner, withdraw the approriate amount
    function withdraw() public {
        require(payable(msg.sender) == contractOwner, 'Only the owner may call this function');
        uint256 toSend = artistBalance;
        artistBalance = 0;
        (bool success, ) = contractOwner.call{value: toSend}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    ///**
    // * @dev See {IERC721-safeTransferFrom}.k

    /**
     * @dev See {IERC721-safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);

    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
}