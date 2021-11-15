//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "./util/IERC20.sol";
import "./util/Counters.sol";
import "./util/SafeMath.sol";
import "./interface/IAniftyERC1155.sol";

contract AniftySale is ERC1155Holder {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _saleIds;
    Counters.Counter private _primarySaleIds;

    struct PrimarySale {
        address lister;
        address payable artist;
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 creationTimestamp;
        uint256 endTimestamp;
    }

    // Only artists can list in primary sales
    struct ArtistInfo {
        bool hasDiscount;
        bool isArtist;
    }

    struct Sale {
        address payable seller;
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 creationTimestamp;
        uint256 endTimestamp;
    }

    // Artist royalties for regular sales
    struct ArtistRoyalties {
        uint256 royalty;
        address payable wallet;
    }

    uint256 constant PRECISION = 10000;
    uint256 public minimumListPrice;
    // Discount to give to artist e.g 250 for 2.5% (primary sale)
    uint256 public discount;
    // Comission fee used to calculate amount to give to use e.g 500 for 5%
    uint256 public commissionFee;
    // Address that collects the commissions
    address payable public commissionWallet;
    // Admin account that grants owner roles
    address public admin;
    IAniftyERC1155 public Anifty;

    bool public secondaryMarketEnabled;

    // address => is owner
    mapping(address => bool) public owners;
    // saleId => Sale struct
    mapping(uint256 => Sale) public sales;
    // saleId => Sale struct
    mapping(uint256 => PrimarySale) public primarySales;

    // Artist info (primary sale)
    mapping(address => ArtistInfo) public artistInfo;
    // Artist royalties, tokenId => ArtistRoyalties
    mapping(uint256 => ArtistRoyalties) public artistRoyalties;

    // The mapping of supported ERC20 token addresses for sales
    mapping(address => bool) public supportedTokens;

    event MintListSale(
        uint256 creationId,
        uint256 saleId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 creationTimestamp,
        address payable artist
    );

    event MintListSaleBatch(
        uint256[] creationIds,
        uint256[] saleIds,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] prices,
        uint256 creationTimestamp,
        address payable[] artists
    );

    event ListSale(
        uint256 saleId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 creationTimestamp,
        address seller,
        bool isPrimary
    );
    event CancelSale(
        uint256 saleId,
        uint256 endTimestamp,
        address seller,
        bool isPrimary
    );
    event UpdateSale(uint256 saleId, uint256 price, bool isPrimary);
    event BuySale(
        uint256 saleId,
        uint256 tokenId,
        uint256 amount,
        uint256 paymentAmount,
        uint256 buyTimestamp,
        address buyer,
        bool completed,
        bool isPrimary
    );

    constructor(
        address[] memory _supportedTokens,
        address _anifty,
        address _admin,
        address _commissionWallet,
        uint256 _commissionFee,
        uint256 _discount,
        uint256 _minimumListPrice
    ) public {
        commissionWallet = payable(_commissionWallet);
        commissionFee = _commissionFee;
        discount = _discount;
        Anifty = IAniftyERC1155(_anifty);
        admin = _admin;
        minimumListPrice = _minimumListPrice;
        // address(0) indicates ETH
        for (uint8 i = 0; i < _supportedTokens.length; i++) {
            supportedTokens[_supportedTokens[i]] = true;
        }
    }

    /********************** MODIFIERS ********************************/

    function onlyWhitelisted(address _artist) private view {
        require(
            admin == msg.sender ||
                owners[msg.sender] ||
                (artistInfo[msg.sender].isArtist && _artist == msg.sender),
            "!whitelisted"
        );
    }

    function onlyArtistOrAuthority(address _artist) private view {
        require(
            _artist == msg.sender || admin == msg.sender || owners[msg.sender],
            "!AritistOrAuth"
        );
    }

    function onlyAdminOrOwner() private view {
        require(admin == msg.sender || owners[msg.sender], "!admin/!owner");
    }

    function editSaleModifier(uint256 _saleId) private view {
        require(sales[_saleId].seller == msg.sender, "!owner");
        require(sales[_saleId].endTimestamp == 0, "!sale");
    }

    function onlySecondaryMarketEnabled() private view {
        require(secondaryMarketEnabled, "!secondaryMarketEnabled");
    }

    /********************** VIEWS ********************************/

    function getSalesInfo(uint256[] memory _saleIds)
        external
        view
        returns (Sale[] memory)
    {
        Sale[] memory saleData = new Sale[](_saleIds.length);

        for (uint256 i = 0; i < _saleIds.length; i++) {
            saleData[i] = Sale(
                sales[_saleIds[i]].seller,
                sales[_saleIds[i]].token,
                sales[_saleIds[i]].tokenId,
                sales[_saleIds[i]].amount,
                sales[_saleIds[i]].price,
                sales[_saleIds[i]].creationTimestamp,
                sales[_saleIds[i]].endTimestamp
            );
        }

        return (saleData);
    }

    function getPrimarySalesInfo(uint256[] memory _saleIds)
        external
        view
        returns (PrimarySale[] memory)
    {
        PrimarySale[] memory saleData = new PrimarySale[](_saleIds.length);

        for (uint256 i = 0; i < _saleIds.length; i++) {
            saleData[i] = PrimarySale(
                primarySales[_saleIds[i]].lister,
                primarySales[_saleIds[i]].artist,
                primarySales[_saleIds[i]].token,
                primarySales[_saleIds[i]].tokenId,
                primarySales[_saleIds[i]].amount,
                primarySales[_saleIds[i]].price,
                primarySales[_saleIds[i]].creationTimestamp,
                primarySales[_saleIds[i]].endTimestamp
            );
        }

        return (saleData);
    }

    /********************** PRIMARY SALE ********************************/
    // List mint and list new NFT
    function mintBatchAndList(
        uint256[] memory _creationIds,
        uint256[] memory _amounts,
        uint256[] memory _prices,
        address[] memory _tokens,
        address payable[] memory _artists,
        string[] memory _names,
        string[] memory _creatorNames,
        string[] memory _descriptions,
        string[] memory _mediaUris
    ) external {
        onlyAdminOrOwner();
        uint256[] memory _tokenIds = Anifty.whitelistMintBatch(
            _amounts,
            _names,
            _creatorNames,
            _descriptions,
            _mediaUris,
            ""
        );
        uint256[] memory primarySaleIds = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Add to sales mapping
            _primarySaleIds.increment();
            primarySaleIds[i] = _primarySaleIds.current();
            primarySales[_primarySaleIds.current()] = PrimarySale({
                lister: msg.sender,
                artist: _artists[i],
                token: _tokens[i],
                tokenId: _tokenIds[i],
                amount: _amounts[i],
                price: _prices[i],
                creationTimestamp: block.timestamp,
                endTimestamp: 0
            });
        }
        emit MintListSaleBatch(
            _creationIds,
            primarySaleIds,
            _tokenIds,
            _amounts,
            _prices,
            block.timestamp,
            _artists
        );
    }

    // List mint and list new NFT
    function mintAndList(
        uint256 _creationId,
        uint256 _amount,
        uint256 _price,
        address _token,
        address payable _artist,
        string memory _name,
        string memory _creatorName,
        string memory _description,
        string memory _mediaUri
    ) external {
        onlyWhitelisted(_artist);
        require(_price >= minimumListPrice, "!minPrice");
        require(_price > 0 && _amount > 0 && supportedTokens[_token], "!param");
        uint256 _tokenId = Anifty.whitelistMint(
            _amount,
            _name,
            _creatorName,
            _description,
            _mediaUri,
            ""
        );
        // Add to sales mapping
        _primarySaleIds.increment();
        primarySales[_primarySaleIds.current()] = PrimarySale({
            lister: msg.sender,
            artist: _artist,
            token: _token,
            tokenId: _tokenId,
            amount: _amount,
            price: _price,
            creationTimestamp: block.timestamp,
            endTimestamp: 0
        });
        emit MintListSale(
            _creationId,
            _primarySaleIds.current(),
            _tokenId,
            _amount,
            _price,
            block.timestamp,
            _artist
        );
    }

    // List new sale of NFT
    function listNewPrimarySale(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _token,
        address payable _artist
    ) external {
        onlyAdminOrOwner();
        require(_price >= minimumListPrice, "!minPrice");
        require(_price > 0 && _amount > 0 && supportedTokens[_token], "!param");
        // Transfer tokens into marketplace contract
        Anifty.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        // Add to sales mapping
        _primarySaleIds.increment();
        primarySales[_primarySaleIds.current()] = PrimarySale({
            lister: msg.sender,
            artist: _artist,
            token: _token,
            tokenId: _tokenId,
            amount: _amount,
            price: _price,
            creationTimestamp: block.timestamp,
            endTimestamp: 0
        });

        emit ListSale(
            _primarySaleIds.current(),
            _tokenId,
            _amount,
            _price,
            block.timestamp,
            _artist,
            true
        );
    }

    // Cancel sale of NFT
    function cancelPrimarySale(uint256 _saleId) external {
        onlyArtistOrAuthority(primarySales[_saleId].artist);
        require(sales[_saleId].endTimestamp == 0, "!sale");
        // Price being set to 0 prevents anyone from purchasing this sale
        primarySales[_saleId].price = 0;
        primarySales[_saleId].endTimestamp = block.timestamp;

        // Transfer tokens into back to lister
        Anifty.safeTransferFrom(
            address(this),
            primarySales[_saleId].lister,
            primarySales[_saleId].tokenId,
            primarySales[_saleId].amount,
            ""
        );
        emit CancelSale(_saleId, block.timestamp, msg.sender, true);
    }

    // Update the price of sale
    function updatePrimarySale(uint256 _saleId, uint256 _price) external {
        onlyArtistOrAuthority(primarySales[_saleId].artist);
        require(primarySales[_saleId].endTimestamp == 0, "!sale");
        primarySales[_saleId].price = _price;
        emit UpdateSale(_saleId, _price, true);
    }

    // Buy NFT
    function buyFromPrimarySale(uint256 _saleId, uint256 _amount)
        external
        payable
    {
        PrimarySale memory primarySale = primarySales[_saleId];
        uint256 paymentAmount = primarySale.price.mul(_amount);
        require(
            primarySale.artist != address(0) && primarySale.endTimestamp == 0,
            "!sale"
        );
        require(_amount > 0 && _amount <= primarySale.amount, "!amount");
        // set endTimestamp if every token has been sold
        if (_amount == primarySale.amount)
            primarySales[_saleId].endTimestamp = block.timestamp;
        primarySales[_saleId].amount = primarySales[_saleId].amount.sub(
            _amount
        );
        // address(0) indicates ETH
        transferTokens(
            primarySale.token,
            primarySale.artist,
            primarySale.tokenId,
            paymentAmount,
            _amount,
            artistInfo[primarySale.artist].hasDiscount
        );
        emit BuySale(
            _saleId,
            primarySale.tokenId,
            _amount,
            msg.value,
            block.timestamp,
            msg.sender,
            primarySales[_saleId].amount == 0,
            true
        );
    }

    /********************** SALE ********************************/

    // List new sale of NFT
    function listNewSale(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _token
    ) external {
        onlySecondaryMarketEnabled();
        require(_price > 0 && _amount > 0 && supportedTokens[_token], "!param");
        // Transfer tokens into marketplace contract
        Anifty.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        // Add to sales mapping
        _saleIds.increment();
        sales[_saleIds.current()] = Sale({
            seller: msg.sender,
            token: _token,
            tokenId: _tokenId,
            amount: _amount,
            price: _price,
            creationTimestamp: block.timestamp,
            endTimestamp: 0
        });

        emit ListSale(
            _saleIds.current(),
            _tokenId,
            _amount,
            _price,
            block.timestamp,
            msg.sender,
            false
        );
    }

    // Cancel sale of NFT
    function cancelSale(uint256 _saleId) external {
        onlySecondaryMarketEnabled();
        editSaleModifier(_saleId);
        sales[_saleId].price = 0;
        sales[_saleId].endTimestamp = block.timestamp;

        // Transfer tokens into back to seller
        Anifty.safeTransferFrom(
            address(this),
            msg.sender,
            sales[_saleId].tokenId,
            sales[_saleId].amount,
            ""
        );
        emit CancelSale(_saleId, block.timestamp, msg.sender, false);
    }

    // Update the price of sale
    function updateSale(uint256 _saleId, uint256 _price) external {
        onlySecondaryMarketEnabled();
        editSaleModifier(_saleId);
        require(_price > 0, "!price");
        sales[_saleId].price = _price;

        emit UpdateSale(_saleId, _price, false);
    }

    // Buy NFT
    function buyFromSale(uint256 _saleId, uint256 _amount) external payable {
        onlySecondaryMarketEnabled();
        Sale memory sale = sales[_saleId];
        uint256 paymentAmount = sale.price.mul(_amount);
        require(sale.seller != address(0) && sale.endTimestamp == 0, "!sale");
        require(_amount <= sale.amount && _amount > 0, "!amount");
        // set endTimestamp if every token has been sold
        if (_amount == sale.amount)
            sales[_saleId].endTimestamp = block.timestamp;
        sales[_saleId].amount = sales[_saleId].amount.sub(_amount);
        // address(0) indicates ETH
        transferTokens(
            sale.token,
            sale.seller,
            sale.tokenId,
            paymentAmount,
            _amount,
            false
        );
        emit BuySale(
            _saleId,
            sale.tokenId,
            _amount,
            msg.value,
            block.timestamp,
            msg.sender,
            sales[_saleId].amount == 0,
            false
        );
    }

    /********************** HELPER ********************************/

    function transferTokens(
        address _token,
        address payable _seller,
        uint256 _tokenId,
        uint256 _paymentAmount,
        uint256 _amount,
        bool _hasDiscount
    ) internal {
        if (_token == address(0)) {
            require(msg.value == _paymentAmount, "!payment");
            //if (msg.value > _paymentAmount)
            //    msg.sender.transfer(msg.value.sub(_paymentAmount));
            // Anifty takes commission for every sale
            uint256 commissionAmount = _paymentAmount.mul(commissionFee).div(
                PRECISION
            );
            if (_hasDiscount) {
                commissionAmount = commissionAmount.sub(
                    _paymentAmount.mul(discount).div(PRECISION)
                );
            }
            // Artists get royalty for every sale
            uint256 royaltyAmount = _paymentAmount
                .mul(artistRoyalties[_tokenId].royalty)
                .div(PRECISION);
            // Transfer seller the price - commission fee
            _seller.transfer(
                _paymentAmount.sub(commissionAmount).sub(royaltyAmount)
            );
            // Transfer commission wallet the commission fee
            commissionWallet.transfer(commissionAmount);
            if (royaltyAmount > 0) {
                artistRoyalties[_tokenId].wallet.transfer(royaltyAmount);
            }
        } else {
            require(msg.value == 0, "!payment");
            IERC20 token = IERC20(_token);
            // Anifty takes commission for every sale
            uint256 commissionAmount = _paymentAmount.mul(commissionFee).div(
                PRECISION
            );
            if (_hasDiscount) {
                commissionAmount = commissionAmount.sub(
                    _paymentAmount.mul(discount).div(PRECISION)
                );
            }
            // Artists get royalty for every sale
            uint256 royaltyAmount = _paymentAmount
                .mul(artistRoyalties[_tokenId].royalty)
                .div(PRECISION);
            // Transfer seller the price - commission fee
            token.transferFrom(
                msg.sender,
                _seller,
                _paymentAmount.sub(commissionAmount).sub(royaltyAmount)
            );
            // Transfer commission wallet the commission fee
            token.transferFrom(msg.sender, commissionWallet, commissionAmount);
            if (royaltyAmount > 0) {
                token.transferFrom(
                    msg.sender,
                    artistRoyalties[_tokenId].wallet,
                    royaltyAmount
                );
            }
        }
        // Give buyer ERC1155
        Anifty.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            ""
        );
    }

    /********************** OWNER/ADMIN ********************************/
    function setCommissionFee(uint256 _commissionFee) external {
        onlyAdminOrOwner();
        commissionFee = _commissionFee;
    }

    function setCommissionWallet(address payable _commissionWallet) external {
        onlyAdminOrOwner();
        commissionWallet = _commissionWallet;
    }

    function setDiscount(uint256 _discount) external {
        onlyAdminOrOwner();
        discount = _discount;
    }

    function setOnlySecondaryMarketEnable(bool _secondaryMarketEnabled)
        external
    {
        onlyAdminOrOwner();
        secondaryMarketEnabled = _secondaryMarketEnabled;
    }

    function setIsArtist(address[] memory _artists, bool _set) external {
        onlyAdminOrOwner();
        for (uint256 i = 0; i < _artists.length; i++) {
            artistInfo[_artists[i]].isArtist = _set;
        }
    }

    function setHasDiscount(address[] memory _artists, bool _set) external {
        onlyAdminOrOwner();
        for (uint256 i = 0; i < _artists.length; i++) {
            artistInfo[_artists[i]].hasDiscount = _set;
        }
    }

    function setArtistRoyalties(
        uint256[] memory _tokenIds,
        uint256[] memory _royalties,
        address payable[] memory _wallets
    ) external {
        onlyAdminOrOwner();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            artistRoyalties[_tokenIds[i]] = ArtistRoyalties(
                _royalties[i],
                _wallets[i]
            );
        }
    }

    function setSupportedTokens(address[] memory _supportedTokens, bool _set)
        external
    {
        onlyAdminOrOwner();
        for (uint8 i = 0; i < _supportedTokens.length; i++) {
            supportedTokens[_supportedTokens[i]] = _set;
        }
    }

    function setMinimumListPrice(uint256 _minimumListPrice) external {
        onlyAdminOrOwner();
        minimumListPrice = _minimumListPrice;
    }

    function setOwners(address[] memory _owners, bool _set) external {
        require(admin == msg.sender, "!admin");
        for (uint8 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = _set;
        }
    }

    function transferAdmin(address _admin) external {
        require(admin == msg.sender, "!admin");
        admin = _admin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IAniftyERC1155 {
    function whitelistMintBatch(
        uint256[] calldata amounts,
        string[] calldata names,
        string[] calldata creatorNames,
        string[] calldata descriptions,
        string[] calldata mediaUris,
        bytes calldata data
    ) external returns (uint256[] memory);

    function whitelistMint(
        uint256 amount,
        string calldata name,
        string calldata creatorName,
        string calldata description,
        string calldata mediaUri,
        bytes calldata data
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

