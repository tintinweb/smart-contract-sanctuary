// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IFixedPriceSale.sol";
import "../payments/ProcessPayments.sol";
import "../security/ReentrancyGuard.sol";
import "../token/interfaces/IBEP721Receiver.sol";
import "../token/interfaces/IBEP721.sol";
import "../dao/interfaces/IDAO.sol";

/**
 * The Implmenetation of `IMarketplace`
 */

contract FixedPriceSale is
    IFixedPriceSale,
    ProcessPayments,
    ReentrancyGuard,
    IBEP721Receiver
{
    // ZNFT token Contract & DAO Contract
    address public nftContract;
    address public daoContract;

    // enumerator to represent the sale status.
    enum SaleStatus {COMPLETED, ONGOING, FAILED}

    // represents the total sales created.
    uint256 private _sales;

    modifier Approved(uint256 tokenId) {
        require(
            IBEP721(nftContract).getApproved(tokenId) == address(this) ||
                IBEP721(nftContract).isApprovedForAll(
                    _msgSender(),
                    address(this)
                ),
            "Marketplace Error: token not approved for sale"
        );
        _;
    }

    modifier Elligible() {
        require(
            IDAO(daoContract).isMerchant(_msgSender()),
            "Marketplace Error: merchant not approved"
        );
        _;
    }

    struct Sale {
        uint256 tokenId;
        uint256 price;
        address creator;
        SaleStatus status;
    }

    struct Buyer {
        bytes method;
        uint256 amount;
        uint256 boughtAt;
    }

    mapping(uint256 => Sale) private _sale;
    mapping(uint256 => Buyer) private _buyer;

    event CreateSale(
        uint256 saleId,
        uint256 tokenId,
        uint256 price,
        address creator
    );
    event BuySale(uint256 saleId, address buyer);

    /**
     * @dev initializes the ProcessPayments Child SC inside Marketplace
     *
     * Payments in marketplace is handled by process payments SC
     */
    constructor(address _nft, address _dao) {
        nftContract = _nft;
        daoContract = _dao;
    }

    /**
     * @dev creates a sale for a specific NFT tokenId.
     *
     * Requirement:
     *
     * `_tokenId` represents the NFT token Id to be solved.
     * `_tokenId` should be approved to be spent by the Marketplace SC.
     *
     * `_price` represents the price in BTC 8-decimal precision.
     *
     * @return bool representing the status of the creation of sale.
     */

    function createSale(uint256 _tokenId, uint256 _price)
        public
        payable
        virtual
        override
        Approved(_tokenId)
        Elligible
        nonReentrant
        returns (bool)
    {   
        uint256 fee = listingFee();
        require(msg.value == fee, "Marketplace Error: listing fee is not equal");

        _sales += 1;

        _sale[_sales] = Sale(
            _tokenId,
            _price,
            _msgSender(),
            SaleStatus.ONGOING
        );

        IBEP721(nftContract).safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );

        payable(daoContract).transfer(msg.value);
        emit CreateSale(_sales, _tokenId, _price, _msgSender());
        return true;
    }

    function listingFee() public view returns (uint256) {
        return IDAO(daoContract).listingFee(_msgSender());
    }

    /**
     * @dev buy sale with a valid acceptable asset.
     *
     * Requirements:
     *
     * `_saleId` represents the identifier for each sale.
     * `_currency` represents the TICKER of the currency.
     * Eg., BTC for bitcoin.
     * @return bool representing the status of purchase.
     */
    function buySale(uint256 _saleId, string memory _currency)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        Sale storage s = _sale[_saleId];
        require(
            s.status == SaleStatus.ONGOING,
            "Marketplace Error: sale not active"
        );

        s.status = SaleStatus.COMPLETED;
        uint256 platformFee = IDAO(daoContract).platformTax(s.creator);
        uint256 _amount = (s.price * platformFee) / 100;

        (bool status, uint256 tokens) = payment(_currency, _amount);

        uint256 cTokens = (tokens * 100) / (100 - platformFee);
        bool status1 = settle(_currency, cTokens, s.creator);

        _buyer[_saleId] = Buyer(bytes(_currency), tokens, block.timestamp);
        IBEP721(nftContract).transferFrom(
            address(this),
            _msgSender(),
            s.tokenId
        );
        emit BuySale(_saleId, _msgSender());
        return status && status1;
    }

    /**
     * To make sure marketplace smart contract supports BEP721.
     *
     * @return a bytes4 interface Id for the marketplace SC.
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

/**
 * Features of Marketplace.
 */

interface IFixedPriceSale {
 
 /**
  * @dev creates a sale for a specific NFT tokenId.
  * Sale ends when someone pays the asking price and it is not ended by time. Runs indefinitely.
  * 
  * Requirement:
  * 
  * `tokenId` represents the NFT token Id to be solved.
  * `tokenId` should be approved to be spent by the Marketplace SC.
  *
  * `price` represents the price in USD 8-decimal precision.
  * 
  * @return bool representing the status of the creation of sale.
  */
  function createSale(uint256 tokenId, uint256 price) external payable returns (bool);

   /**
     * @dev buy sale with a valid acceptable asset (Tokens Not Stablecoins).
     *
     * Requirements:
     * 
     * `_saleId` represents the identifier for each sale.
     * `_currency` represents the TICKER of the currency. 
     * Eg., BTC for bitcoin.
     */
    function buySale(uint256 _saleId, string memory _currency) external returns (bool);  
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IProcessPayments.sol";
import "./interfaces/IAggregatorV3.sol";
import "../token/interfaces/IBEP20.sol";
import "../utils/Context.sol";
import "../utils/Ownable.sol";

contract ProcessPayments is IProcessPayments, Ownable {
    address public settlement;
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
     * @dev replaces the settlement address.
     */
    function replaceSettlementAddress(address _newAddress)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(
            _newAddress != address(0),
            "PoS Error: settlement address cannot be zero"
        );
        settlement = _newAddress;
        return true;
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
            IBEP20(contractAddress).transferFrom(spender, settlement, amount),
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
            IBEP20(contractAddress).transferFrom(user, settlement, amount),
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
        return IBEP20(contractAddress).transferFrom(_msgSender(), _to, _value);
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
        uint256 _listingFee,
        uint8 _platformTax,
        string memory ethWallet,
        string memory bscWallet,
        string memory btcWallet
    ) external returns (bool);

    /**
     * @dev can change the listing features.
     */
    function updateParams(uint256 _proposalId, uint256 _listingFee, uint8 _platformTax, string memory ethWallet, string memory bscWallet, string memory btcWallet) external returns (bool);

    /**
     * @dev vote for the approval of merchants.
     *
     * `proposalId` will be the listing Id of the proposal.
     */
    function vote(uint256 _proposalId) external returns (bool);

    /**
     * @dev allows ZNFT share holders to create a voting proposal.
     */
    function createDistribution(address[] memory _earners, uint256[] memory _percentages) external returns (bool);
    
    /**
     * @dev allows ZNFT share holders to vote for a distribution.
     */
    function voteDistribution(uint256 _distributionId, bool _support) external returns (bool);

    /**
     * @dev allows the distribution of the rewards
     */
    function distribute(uint256 _distributionId) external returns(bool);

    /**
     * @dev returns if an address is a valid `merchant`
     */
    function isMerchant(address _merchantAddress) external view returns (bool);

     /**
     * @dev returns the listing fee of `_merchantAddress`
     */
    function listingFee(address _merchantAddress) external view returns (uint256);

    /**
     * @dev returns the listing fee of `_merchantAddress`
     */
    function platformTax(address _merchantAddress) external view returns (uint8);
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