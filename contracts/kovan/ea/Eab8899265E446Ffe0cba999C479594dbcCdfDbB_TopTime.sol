// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/ITopTime.sol";
import "../payments/ProcessPayments.sol";
import "../security/ReentrancyGuard.sol";
import "../token/interfaces/IBEP721Receiver.sol";
import "../token/interfaces/IBEP721.sol";
import "../dao/interfaces/IDAO.sol";

contract TopTime is
    ITopTime,
    ProcessPayments,
    ReentrancyGuard,
    IBEP721Receiver
{
    address public nftContract;
    address public daoContract;

    // enumerator to represent the sale status.
    enum AuctionStatus {ENDED, LIVE, COMPLETED, FAILED}

    // represents the total auctions created
    uint256 private _auctions;

    struct AuctionInfo {
        uint256 tokenId;
        uint256 askingPrice;
        uint256 currentPrice;
        uint256 start;
        uint256 toptime;
        address creator;
        address winner;
        AuctionStatus status;
    }

    struct BidInfo {
        bytes currency;
        uint256 amount;
        uint256 createdAt;
    }

    mapping(uint256 => AuctionInfo) private _auction;
    mapping(address => mapping(uint256 => BidInfo)) private _bid;

    modifier Approved(uint256 _tokenId) {
        require(
            IBEP721(nftContract).getApproved(_tokenId) == address(this) ||
                IBEP721(nftContract).isApprovedForAll(
                    _msgSender(),
                    address(this)
                ),
            "TopTime Error: token not approved for sale"
        );
        _;
    }

    modifier Elligible() {
        require(
            IDAO(daoContract).isMerchant(_msgSender()),
            "TopTime Error: merchant not approved"
        );
        _;
    }

    event ListItem(
        uint256 tokenId,
        uint256 auctionId,
        address owner,
        uint256 price,
        uint256 toptime
    );
    event Bid(uint256 auctionId, string currency, uint256 amount);
    event Settle(uint256 auctionId);

    /**
     * @dev creates an auction for a specific NFT tokenId.
     *
     * Requirement:
     *
     * `_tokenId` represents the NFT token Id to be solved.
     * `_tokenId` should be approved to be spent by the TopTime SC.
     *
     * `_endsAt` represents the duration of auction from start date represented in seconds.
     * `_price` represents the price in BTC 8-decimal precision.
     *
     * @return bool representing the status of the creation of sale.
     */

    function createAuction(
        uint256 _tokenId,
        uint256 _toptime,
        uint256 _price
    ) public virtual override Approved(_tokenId) Elligible returns (bool) {
        _auctions += 1;
        _auction[_auctions] = AuctionInfo(
            _tokenId,
            _price,
            _price,
            block.timestamp,
            _toptime,
            _msgSender(),
            address(0),
            AuctionStatus.LIVE
        );

        IBEP721(nftContract).safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );
        emit ListItem(_tokenId, _auctions, _msgSender(), _price, _toptime);
        return true;
    }

    /**
     * @dev allows users to bid the auction for a specific NFT.
     *
     * Requirement:
     * `_auctionId` representing the auction the user is bidding.
     * `_currency` the ticker of the token the user is using for payments.
     * `_amount` representing the bid amount in BTC 8-precision.
     */
    function bidAuction(
        uint256 _auctionId,
        string memory _currency,
        uint256 _amount
    ) public virtual override nonReentrant returns (bool) {
        AuctionInfo storage a = _auction[_auctionId];
        BidInfo storage wBid = _bid[a.winner][_auctionId];
        uint256 time = block.timestamp - wBid.createdAt;
        require(time < a.toptime, "TopTime Error: toptime already reached");
        require(
            a.currentPrice < _amount,
            "TopTime Error: bid with a higher value"
        );

        if (a.winner != address(0)) {
            BidInfo storage b = _bid[a.winner][_auctionId];
            settle(string(b.currency), b.amount, a.winner);
        }

        (bool status, uint256 tokens) = payment(_currency, _amount);
        _bid[_msgSender()][_auctionId] = BidInfo(
            bytes(_currency),
            tokens,
            block.timestamp
        );
        a.winner = _msgSender();
        a.currentPrice = _amount;

        emit Bid(_auctionId, _currency, _amount);
        return status;
    }
  
    /**
     * @dev releases the auction token to the highest bidder.
     *
     * `_auctionId` is the identifier of the auction you wisg to settle the tokens.
     *
     * @return bool representing the status of the transaction.
     */
    function releaseAuctionToken(uint256 _auctionId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        AuctionInfo storage a = _auction[_auctionId];
        BidInfo storage wBid = _bid[a.winner][_auctionId];
        uint256 time = block.timestamp - wBid.createdAt;

        require(a.creator == _msgSender(), "TopTime Error: caller not creator");
        require(time >= a.toptime, "TopTime Error: toptime not ended");

        BidInfo storage b = _bid[a.winner][_auctionId];
        bool status = settle(string(b.currency), b.amount, a.creator);

        IBEP721(nftContract).transferFrom(address(this), a.winner, a.tokenId);

        emit Settle(_auctionId);
        return status;
    }

    /**
     * @dev calim the auction token if you're the highest bidder.
     *
     * `_auctionId` is the identifier of the auction you wisg to settle the tokens.
     *
     * @return bool representing the status of the transaction.
     */
    function claimAuctionToken(uint256 _auctionId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        AuctionInfo storage a = _auction[_auctionId];
        BidInfo storage wBid = _bid[a.winner][_auctionId];
        uint256 time = block.timestamp - wBid.createdAt;

        require(a.creator == _msgSender(), "TopTime Error: caller not creator");
        require(time >= a.toptime, "TopTime Error: toptime not ended");

        BidInfo storage b = _bid[a.winner][_auctionId];
        bool status = settle(string(b.currency), b.amount, a.creator);

        IBEP721(nftContract).transferFrom(address(this), a.winner, a.tokenId);

        emit Settle(_auctionId);
        return status;
    }

    /**
     * @dev sets the NFT token smart contract.
     *
     * `_contractAddress` represents the BEP721 contract address.
     * `_contractAddress` cannot be a zero address.
     */
    function setNftContract(address _contractAddress)
        public
        virtual
        returns (bool)
    {
        require(
            _contractAddress != address(0),
            "Auction Error: cannot be zero address"
        );
        nftContract = _contractAddress;
        return true;
    }

    /**
     * @dev sets the DAO smart contract.
     *
     * `_contractAddress` represents the BEP721 contract address.
     * `_contractAddress` cannot be a zero address.
     */
    function setDAOContract(address _contractAddress)
        public
        virtual
        returns (bool)
    {
        require(
            _contractAddress != address(0),
            "Auction Error: cannot be zero address"
        );
        daoContract = _contractAddress;
        return true;
    }

    /**
     * @dev returns the information of every auction with auctionId.
     *
     * `auctionId` represents the Id of the auction you wish to query.
     */
    function auctionInfo(uint256 _auctionId)
        public
        view
        returns (AuctionInfo memory)
    {
        return _auction[_auctionId];
    }

    /**
     * @dev returns the information of every auction with auctionId.
     *
     * `auctionId` represents the Id of the auction you wish to query.
     */
    function bidInfo(address _user, uint256 _auctionId)
        public
        view
        returns (BidInfo memory)
    {
        return _bid[_user][_auctionId];
    }

    /**
     * To make sure TopTime smart contract supports BEP721.
     *
     * @return a bytes4 interface Id for the TopTime SC.
     */
    function onBEP721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure override returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        return 0x150b7a02;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface ITopTime {
    /**
     * @dev creates an top time based auction for a specific NFT tokenId.
     *
     * Requirement:
     *
     * `_tokenId` represents the NFT token Id to be solved.
     * `_tokenId` should be approved to be spent by the Marketplace SC.
     *
     * `_endsAt` represents the duration of auction from start date represented in seconds.
     * `_price` represents the price in BTC 8-decimal precision.
     *
     * @return bool representing the status of the creation of sale.
     */

    function createAuction(
        uint256 _tokenId,
        uint256 _endsAt,
        uint256 _price
    ) external returns (bool);

    /**
     * @dev allows users to bid the auction for a specific NFT.
     * using tokens.
     *
     * Requirement:
     * `_auctionId` representing the auction the user is bidding.
     * `_currency` the ticker of the token the user is using for payments.
     *
     * @return bool representing the status of the bid.
     */
    function bidAuction(uint256 _auctionId, string memory _currency, uint256 _amount) external returns (bool);

    /**
     * @dev releases the auction token to the highest bidder.
     *
     * `_auctionId` is the identifier of the auction you wisg to settle the tokens.
     *
     * @return bool representing the status of the transaction.
     */
    function releaseAuctionToken(uint256 _auctionId) external returns (bool);

    /**
     * @dev calim the auction token if you're the highest bidder.
     *
     * `_auctionId` is the identifier of the auction you wisg to settle the tokens.
     *
     * @return bool representing the status of the transaction.
     */
    function claimAuctionToken(uint256 _auctionId) external returns (bool);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IProcessPayments.sol";
import "./interfaces/IAggregatorV3.sol";
import "../token/interfaces/IBEP20.sol";
import "../utils/Context.sol";
import "../utils/Ownable.sol";

contract ProcessPayments is IProcessPayments, Ownable {
    /**
     * Mapping of bytes string representing token ticker to an oracle address.
     */
    mapping(bytes => address) private _oracles;

    /**
     * Mapping of bytes string representing token ticker to token smart contract.
     */
    mapping(bytes => address) private _contracts;

    /**
     *
     */
    mapping(bytes => uint8) private _isStable;

    /**
     * @dev verifies whether a contract address is configured for a specific ticker.
     */
    modifier Available(string memory _ticker) {
        require(
            _contracts[bytes(_ticker)] != address(0),
            "PoS Error: contract address for ticker not available"
        );
        _;
    }

    /**
     * @dev validates whether the given asset is a stablecoin.
     */
    modifier Stablecoin(string memory _ticker) {
        require(
            _isStable[bytes(_ticker)] == 1,
            "PoS Error: token doesn't represent a stablecoin"
        );
        _;
    }

    /**
     * @dev sets the owners in the Ownable Contract.
     */
    constructor() Ownable() {}

    /**
     * @dev sets the address of the oracle for the token ticker.
     *
     * Requirements:
     * `_oracleAddress` is the chainlink oracle address for price.
     * `_ticker` is the TICKER for the asset. Eg., BTC for Bitcoin.
     */
    function setOracle(address _oracleAddress, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _oracleAddress != address(0),
            "PoS Error: oracle cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_oracles[ticker] == address(0)) {
            _oracles[ticker] = _oracleAddress;
            return true;
        } else {
            revert("PoS Error: oracle address already found");
        }
    }

    /**
     * @dev sets the address of the contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function setContract(address _contractAddress, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _contractAddress != address(0),
            "PoS Error: contract cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_contracts[ticker] == address(0)) {
            _contracts[ticker] = _contractAddress;
            return true;
        } else {
            revert("PoS Error: contract already initialized.");
        }
    }

    /**
     * @dev replace the oracle for an existing ticker.
     *
     * Requirements:
     * `_newOracle` is the chainlink oracle source that's changed.
     * `_ticker` is the TICKER of the asset.
     */
    function replaceOracle(address _newOracle, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _newOracle != address(0),
            "PoS Error: oracle cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_oracles[ticker] != address(0)) {
            _oracles[ticker] = _newOracle;
            return true;
        } else {
            revert("PoS Error: set oracle to replace.");
        }
    }

    /**
     * @dev sets the address of the contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function replaceContract(address _newAddress, string memory _ticker)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(
            _newAddress != address(0),
            "PoS Error: contract cannot be a zero address"
        );
        bytes memory ticker = bytes(_ticker);

        if (_contracts[ticker] != address(0)) {
            _contracts[ticker] = _newAddress;
            return true;
        } else {
            revert("PoS Error: contract not initialized yet.");
        }
    }

    /**
     * @dev marks a specific asset as stablecoin.
     *
     * Requirements:
     * `_ticker` - TICKER of the token that's contract address is already configured.
     *
     * @return bool representing the status of the transaction.
     */
    function markAsStablecoin(string memory _ticker)
        public
        virtual
        override
        Available(_ticker)
        onlyOwner
        returns (bool)
    {
        _isStable[bytes(_ticker)] = 1;
        return true;
    }

    /**
     * @dev process payments with ticker & btc value
     */
    function payment(string memory _ticker, uint256 _btc)
        internal
        virtual
        Available(_ticker)
        returns (bool, uint256)
    {
        if (_isStable[bytes(_ticker)] == 1) {
            return sPayment(_ticker, _btc);
        } else {
            return tPayment(_ticker, _btc);
        }
    }

    /**
     * @dev process payments for stablecoins.
     *
     * Requirements:
     * `_ticker` is the name of the token to be processed.
     * `_btc` is the amount of BTC to be processed in 8-decimals.
     *
     * 1 Stablecoin is considered as 1 USD.
     */
    function sPayment(string memory _ticker, uint256 _btc)
        internal
        virtual
        Available(_ticker)
        Stablecoin(_ticker)
        returns (bool, uint256)
    {
        address spender = _msgSender();
        uint256 amount = sAmount(_ticker, _btc);
        address contractAddress = _contracts[bytes(_ticker)];

        require(
            approval(_ticker, spender) >= amount,
            "PoS Error: insufficient allowance for spender"
        );

        return (
            IBEP20(contractAddress).transferFrom(
                spender,
                address(this),
                amount
            ),
            amount
        );
    }

    /**
     @dev estimates the amount of tokens in eq.btc.
     */
    function sAmount(string memory _ticker, uint256 _btc)
        public
        view
        returns (uint256)
    {
        address contractAddress = _contracts[bytes(_ticker)];
        uint256 decimals = IBEP20(contractAddress).decimals();
        require(decimals <= 18, "Pos Error: asset class not supported");
        // decimals = x
        uint256 price = btcPrice();
        // price - 8 decimal; _btc - 8 decimal;
        uint256 usd = price * _btc * 10**2;

        uint256 amount = usd / 10**(18 - decimals);
        return amount;
    }

    /**
     * @dev process payments for tokens.
     *
     * Requirements:
     * `_ticker` of the token.
     * `_btc` is the amount of BTC to be processed.
     *
     * Price of token is fetched from Chainlink.
     */
    function tPayment(string memory _ticker, uint256 _btc)
        internal
        virtual
        Available(_ticker)
        returns (bool, uint256)
    {
        uint256 amount = tAmount(_ticker, _btc);
        address user = _msgSender();

        require(
            approval(_ticker, user) >= amount,
            "PoS Error: Insufficient Approval"
        );
        address contractAddress = _contracts[bytes(_ticker)];
        return (
            IBEP20(contractAddress).transferFrom(user, address(this), amount),
            amount
        );
    }

    /**
     * @dev resolves the amount of tokens to be paid for the amount of usd.
     *
     * Requirements:
     * `_ticker` represents the token to be accepted for payments.
     * `_btc` represents the value in BTC.
     */
    function tAmount(string memory _ticker, uint256 _btc)
        public
        view
        returns (uint256)
    {
        uint256 price = btcPrice();
        uint256 usd = price * _btc * 10**10;

        uint256 targetPrice = fetchPrice(_ticker);
        uint256 amount = usd / targetPrice;

        address contractAddress = _contracts[bytes(_ticker)];
        uint256 decimal = IBEP20(contractAddress).decimals();

        require(decimal <= 18, "PoS Error: asset class cannot be supported");
        uint256 decimalCorrection = 18 - decimal;

        return amount / 10**decimalCorrection;
    }

    /**
     * @dev used for settle a tokens from the contract
     * to a user.
     *
     * Requirements:
     * `_ticker` of the token.
     * `_value` is the amount of tokens (decimals not handled)
     * `_to` is the address of the user.
     *
     * @return bool representing the status of the transaction.
     */
    function settle(
        string memory _ticker,
        uint256 _value,
        address _to
    ) internal virtual Available(_ticker) returns (bool) {
        address contractAddress = _contracts[bytes(_ticker)];
        return IBEP20(contractAddress).transfer(_to, _value);
    }

    /**
     * @dev checks the approval value of each token.
     *
     * Requirements:
     * `_ticker` is the name of the token to check approval.
     * '_holder` is the address of the account to be processed.
     *
     * @return the approval of any stablecoin in 18-decimal.
     */
    function approval(string memory _ticker, address _holder)
        private
        view
        returns (uint256)
    {
        address contractAddress = _contracts[bytes(_ticker)];
        return IBEP20(contractAddress).allowance(_holder, address(this));
    }

    /**
     * @dev returns the contract address.
     */
    function contractOf(string memory _ticker) public view returns (address) {
        return _contracts[bytes(_ticker)];
    }

    /**
     * @dev returns the latest round price from chainlink oracle.
     *
     * Requirements:
     * `_oracleAddress` the address of the oracle.
     *
     * @return the current latest price from the oracle.
     */
    function fetchPrice(string memory _ticker) public view returns (uint256) {
        address oracleAddress = _oracles[bytes(_ticker)];
        (, int256 price, , , ) = IAggregatorV3(oracleAddress).latestRoundData();
        return uint256(price);
    }

    /**
     * @dev returns the latest BTC-USD price from chainlink oracle.
     *
     * BTC-USD
     * Kovan: 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
     */
    function btcPrice() public view returns (uint256) {
        (, int256 price, , , ) =
            IAggregatorV3(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e)
                .latestRoundData();
        return uint256(price);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title BEP721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from BEP721 asset contracts.
 */
interface IBEP721Receiver {
    /**
     * @dev Whenever an {IBEP721} `tokenId` token is transferred to this contract via {IBEP721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IBEP721.onBEP721Received.selector`.
     */
    function onBEP721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IBEP165.sol";

/**
 * @dev Required interface of an BEP721 compliant contract.
 */
interface IBEP721 is IBEP165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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

//SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface IDAO {
    /**
     * @dev receives the listing for adding new merchants to the marketplace.
     *
     *`hash` is the ipfs hash of the company-info JSON. To reduce gas usuage we're following this approach.
     */
    function createMerchant(
        string memory hash,
        uint256 listingFee,
        uint8 platformTax
    ) external returns (bool);

    /**
     * @dev vote for the approval of merchants.
     *
     * `proposalId` will be the listing Id of the proposal.
     */
    function vote(uint256 proposalId) external returns (bool);

    /**
     * @dev returns if an address is a valid `merchant`
     */
    function isMerchant(address _merchantAddress) external view returns (bool);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * SC for handling payments outside of the marketplace SC.
 *
 * Provides flexibility for handling new payment methods in future.
 * Handles payments now in BNB, ADA, ETH & StableCoins.
 *
 * All prices are handles as 8-decimal irrespective of oracle source.
 */

interface IProcessPayments {
    /**
     * @dev sets the address of the oracle for the token ticker for the first time.
     *
     * Requirements:
     * `_oracleAddress` is the chainlink oracle address for price.
     * `_ticker` is the TICKER for the asset. Eg., BTC for Bitcoin.
     */
    function setOracle(address _oracleAddress, string memory _ticker) external returns (bool);

    /**
     * @dev sets the address of the contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function setContract(address _contractAddress, string memory _ticker) external returns (bool);

    /**
     * @dev replace the address of the oracle for the token ticker.
     *
     * Requirements:
     * `_newOracle` is the chainlink oracle address for price.
     * `_ticker` is the TICKER for the asset. Eg., BTC for Bitcoin.
     */
    function replaceOracle(address _newOracle, string memory _ticker) external returns (bool);

    /**
     * @dev replaces the address of an existing contract for token ticker.
     *
     * Requirements:
     * `_ticker` is the TICKER of the asset.
     * `_contractAddress` is the address of the token smart contract.
     * `_contractAddress` should follow BEP20/ERC20 standards.
     *
     * @return bool representing the status of the transaction.
     */
    function replaceContract(address _newAddress, string memory _ticker) external returns (bool);

    /**
     * @dev marks a specific asset as stablecoin.
     *
     * Requirements:
     * `_ticker` - TICKER of the token that's contract address is already configured.
     *
     * @return bool representing the status of the transaction.
     */
    function markAsStablecoin(string memory _ticker) external returns (bool);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Interface of ZNFT Shares ERC20 Token As in EIP
 */

interface IBEP20 {
    /**
     * @dev returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * @dev provides information about the current execution context.
 *
 * This includes the sender of the transaction & it's data.
 * Useful for meta-transaction as the message sender & gas payer can be different.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev returns the current owner of the SC.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws error if the function is called by account other than owner
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "Ownable: caller not owner");
        _;
    }

    /**
     * @dev Leaves the contract without any owner.
     *
     * It will be impossible to call onlyOwner Functions.
     * NOTE: use with caution.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner(), address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner cannot be zero address"
        );
        address msgSender = _msgSender();

        emit OwnershipTransferred(msgSender, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * @dev implements the IBEP165 interface according
 * to EIP standards.
 *
 * For implementation see {BEP165}
 */

interface IBEP165 {
    /**
     * @dev returns true if this contracts implements the
     * interface defined by `interfaceId`.
     *
     * Must use less than 30,000 GAS.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
        "abi"
      ]
    }
  },
  "libraries": {}
}