/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

pragma solidity ^0.8.7;


// ----------------------------------------------------------------------------
// Nix v0.8.0 testing
//
// https://github.com/bokkypoobah/Nix
//
// Deployed to
//
// 
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021.
// ----------------------------------------------------------------------------
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

interface IERC20Partial {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Partial is IERC165 {
    function ownerOf(uint tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint balance);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable;
}

interface IRoyaltyEngineV1Partial is IERC165 {
    function getRoyaltyView(address tokenAddress, uint tokenId, uint value) external view returns(address payable[] memory recipients, uint[] memory amounts);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes memory _data) external returns(bytes4);
}

contract Owned {
    address public owner;
    bool initOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Withdrawn(address indexed token, uint tokens, uint tokenId);

    modifier onlyOwner {
        require(msg.sender == owner, "NotOwner");
        _;
    }

    function init(address sender) public {
        require(!initOwner, "Already init");
        initOwner = true;
        owner = sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function withdraw(address token, uint tokens, uint tokenId) public onlyOwner {
        if (tokenId == 0) {
            if (token == address(0)) {
                payable(owner).transfer((tokens == 0 ? address(this).balance : tokens));
            } else {
                IERC20Partial(token).transfer(owner, tokens == 0 ? IERC20Partial(token).balanceOf(address(this)) : tokens);
            }
        } else {
            IERC721Partial(token).safeTransferFrom(address(this), owner, tokenId);
        }
        emit Withdrawn(address(token), tokens, tokenId);
    }
}

contract ReentrancyGuard {
    uint private _executing;
    modifier reentrancyGuard() {
        require(_executing != 1, "NO");
        _executing = 1;
        _;
        _executing = 2;
    }
}

/// @author BokkyPooBah, Bok Consulting Pty Ltd
/// @title Decentralised ERC-721 exchange
contract Nix is Owned, ReentrancyGuard, ERC721TokenReceiver, Initializable {
    using Address for address;

    enum BuyOrSell { Buy, Sell }
    enum AnyOrAll { Any, All }

    struct Token {
        address token;
        bytes32[] ordersIndex;
        mapping(bytes32 => Order) orders;
        uint64 executed;
        uint64 volumeToken;
        uint volumeWeth;
    }
    struct Order {
        address maker;
        address taker;
        BuyOrSell buyOrSell;
        AnyOrAll anyOrAll;
        uint[] tokenIds;
        uint price;
        uint64 expiry;
        uint64 tradeCount;
        uint64 tradeMax;
        uint64 royaltyFactor;
    }
    struct Netting {
        address accounts;
        int amount;
    }
    struct ExecutedOrder {
        address token;
        uint64 orderIndex;
    }
    struct Trade {
        address taker;
        uint64 royaltyFactor;
        uint64 blockNumber;
        address[] uniqueAddresses;
        mapping(address => bool) seen;
        mapping(address => int) netting;
        ExecutedOrder[] executedOrders;
    }

    // https://eips.ethereum.org/EIPS/eip-721
    bytes4 private constant ERC721_INTERFACE = 0x80ac58cd;
    bytes4 private constant ERC721METADATA_INTERFACE = 0x5b5e139f;
    bytes4 private constant ERC721ENUMERABLE_INTERFACE = 0x780e9d63;
    uint private constant ROYALTYFACTOR_MAX = 1000;
    uint private MARKETPLACE_FEE;

    IERC20Partial public weth;
    IRoyaltyEngineV1Partial public royaltyEngine;

    address[] private tokensIndex;
    mapping(address => Token) public tokens;
    Trade[] private trades;

    event TokenAdded(address token, uint tokenIndex);
    event OrderAdded(address token, uint orderIndex);
    event OrderDisabled(address token, uint orderIndex);
    // event OrderTokenIdsUpdated(address token, uint orderIndex);
    event OrderUpdated(address token, uint orderIndex);
    event OrderExecuted(address token, uint orderIndex, uint tradeIndex, uint[] tokenIds);
    event ThankYou(uint tip);

    function initialize(IERC20Partial _weth, IRoyaltyEngineV1Partial _royaltyEngine) public initializer {
        init(msg.sender);
        weth = _weth;
        royaltyEngine = _royaltyEngine;
        MARKETPLACE_FEE = 25;
    }

    function setMarketplaceFee(uint fee) public onlyOwner {
        MARKETPLACE_FEE = fee;
    }

    function onERC721Received(address /*_operator*/, address /*_from*/, uint _tokenId, bytes memory /*_data*/) external override returns(bytes4) {
        emit ThankYou(_tokenId);
        return this.onERC721Received.selector;
    }

    function tokensLength() public view returns (uint) {
        return tokensIndex.length;
    }
    function ordersLength(address token) public view returns (uint) {
        return tokens[token].ordersIndex.length;
    }
    function tradesLength() public view returns (uint) {
        return trades.length;
    }
    function getToken(uint tokenIndex) external view returns (address token, uint64 _ordersLength, uint64 executed, uint64 volumeToken, uint volumeWeth) {
        token = tokensIndex[tokenIndex];
        Token storage tokenInfo = tokens[token];
        _ordersLength = uint64(tokenInfo.ordersIndex.length);
        executed = tokenInfo.executed;
        volumeToken = tokenInfo.volumeToken;
        volumeWeth = tokenInfo.volumeWeth;
    }
    function getOrder(address token, uint orderIndex) external view returns (Order memory order) {
        bytes32 orderKey = tokens[token].ordersIndex[orderIndex];
        order = tokens[token].orders[orderKey];
    }
    function getTrade(uint tradeIndex) external view returns (address taker, uint64 royaltyFactor, uint64 blockNumber, ExecutedOrder[] memory executedOrders) {
        Trade storage trade = trades[tradeIndex];
        return (trade.taker, trade.royaltyFactor, trade.blockNumber, trade.executedOrders);
    }

    /// @dev Add order
    /// @param token ERC-721 contract address
    /// @param taker Specific address, or null for any taker
    /// @param tokenIds [] (empty) for any, [tokenId1, tokenId2, ...] for specific tokenIds. Must not be empty for All
    /// @param price Price per NFT for Any. Price for all specified NFTs for All
    /// @param buyOrSell (0) Buy, (1) Sell
    /// @param anyOrAll (0) Any, (1) All
    /// @param expiry Expiry date. 0 = no expiry.
    /// @param tradeMax Must be 0 or 1 for All. Maximum number of NFTs for Any
    /// @param royaltyFactor 0 to ROYALTYFACTOR_MAX, and will be applied as % when the maker sells the NFTs
    /// @param integrator Address of integrator, that will receive a portion of ETH tips
    /// @return orderIndex The new order index
    function addOrder(
        address token,
        address taker,
        BuyOrSell buyOrSell,
        AnyOrAll anyOrAll,
        uint[] memory tokenIds,
        uint price,
        uint expiry,
        uint tradeMax,
        uint royaltyFactor,
        address integrator
    ) external payable reentrancyGuard returns (
        uint64 orderIndex
    ) {
        if (anyOrAll == AnyOrAll.All) {
            require(tokenIds.length > 0, "TokenIds");
            require(tradeMax <= 1, "Parcel");
        }
        require(royaltyFactor <= ROYALTYFACTOR_MAX, "Royalty");

        Token storage tokenInfo = tokens[token];
        if (tokenInfo.token != token) {
            try IERC721Partial(token).supportsInterface(ERC721_INTERFACE) returns (bool b) {
                require(b, "ERC721");
                tokensIndex.push(token);
                tokenInfo.token = token;
                emit TokenAdded(token, tokensIndex.length - 1);
            } catch {
                revert("ERC165");
            }
        }

        bytes32 _orderKey = keccak256(abi.encodePacked(msg.sender, taker, token, tokenIds, price, buyOrSell, anyOrAll, expiry));
        require(tokenInfo.orders[_orderKey].maker == address(0), "Dup");

        tokenInfo.ordersIndex.push(_orderKey);
        Order storage order = tokenInfo.orders[_orderKey];
        order.maker = msg.sender;
        order.taker = taker;
        order.buyOrSell = buyOrSell;
        order.anyOrAll = anyOrAll;
        order.tokenIds = tokenIds;
        order.price = price;
        order.expiry = uint64(expiry);
        order.tradeMax = uint64(tradeMax);
        order.royaltyFactor = uint64(royaltyFactor);
        emit OrderAdded(token, tokenInfo.ordersIndex.length - 1);
        handleTips(integrator);
        return uint64(tokenInfo.ordersIndex.length - 1);
    }

    // Code too large
    /// @dev Disable order
    /// @param token ERC-721 contract address
    /// @param orderIndex Order index
    /// @param integrator Address of integrator, that will receive a portion of ETH tips
    function disableOrder(address token, uint orderIndex, address integrator) external payable reentrancyGuard {
        bytes32 orderKey = tokens[token].ordersIndex[orderIndex];
        Order storage order = tokens[token].orders[orderKey];
        require(msg.sender == order.maker, "NotMaker");
        order.expiry = uint64(block.timestamp - 1);
        emit OrderDisabled(token, orderIndex);
        handleTips(integrator);
    }

    // /// @dev Maker update order tokenIds
    // /// @param token ERC-721 contract address
    // /// @param orderIndex Order index
    // /// @param tokenIds [] (empty) for any, [tokenId1, tokenId2, ...] for specific tokenIds. Must not be empty for All
    // /// @param integrator Address of integrator, that will receive a portion of ETH tips
    // function updateOrderTokenIds(
    //     address token,
    //     uint orderIndex,
    //     uint[] memory tokenIds,
    //     address integrator
    // ) external payable reentrancyGuard {
    //     bytes32 orderKey = tokens[token].ordersIndex[orderIndex];
    //     Order storage order = tokens[token].orders[orderKey];
    //     require(msg.sender == order.maker, "Maker");
    //     order.tokenIds = tokenIds;
    //     emit OrderTokenIdsUpdated(token, orderIndex);
    //     handleTips(integrator);
    // }

    /// @dev Update order
    /// @param token ERC-721 contract address
    /// @param orderIndex Order index
    /// @param taker Specific address, or null for any taker
    /// @param tokenIds [] (empty) for any, [tokenId1, tokenId2, ...] for specific tokenIds. Must not be empty for All
    /// @param price Price per NFT for Any. Price for all specified NFTs for All
    /// @param expiry Expiry date. 0 = no expiry.
    /// @param tradeMaxAdjustment Positive or negative number to adjust tradeMax. tradeMax must result in 0 or 1 for All, or the maximum number of NFTs for Any
    /// @param royaltyFactor 0 to 100, and will be applied as % when the maker sells the NFTs
    /// @param integrator Address of integrator, that will receive a portion of ETH tips
    function updateOrder(
        address token,
        uint orderIndex,
        address taker,
        uint[] memory tokenIds,
        uint price,
        uint expiry,
        int tradeMaxAdjustment,
        uint royaltyFactor,
        address integrator
    ) external payable reentrancyGuard {
        bytes32 orderKey = tokens[token].ordersIndex[orderIndex];
        Order storage order = tokens[token].orders[orderKey];
        require(msg.sender == order.maker, "NotMaker");
        order.taker = taker;
        order.tokenIds = tokenIds;
        order.price = price;
        order.expiry = uint64(expiry);
        if (tradeMaxAdjustment < 0) {
            uint64 subtract = uint64(-int64(tradeMaxAdjustment));
            if (subtract > (order.tradeMax - order.tradeCount)) {
                order.tradeMax -= subtract;
            } else {
                order.tradeMax = order.tradeCount;
            }
        } else {
            order.tradeMax += uint64(int64(tradeMaxAdjustment));
        }
        if (order.anyOrAll == AnyOrAll.All) {
            require(order.tradeMax <= 1, "Parcel");
        }
        order.royaltyFactor = uint64(royaltyFactor);
        emit OrderUpdated(token, orderIndex);
        handleTips(integrator);
    }

    /// @dev Taker execute orders.
    /// @param tokenList List of ERC-721 contract addresses - one address for each order
    /// @param orderIndexes List of order indices - one orderIndex for each order
    /// @param tokenIdsList List of list of tokenIds - one set of tokenIds for each order
    /// @param netAmount Positive (taker receives WETH) or negative (taker pays WETH) for all orders
    /// @param royaltyFactor 0 to ROYALTYFACTOR_MAX, and will be applied as % when the taker sells the NFTs
    /// @param integrator Address of integrator, that will receive a portion of ETH tips
    function executeOrders(
        address[] memory tokenList,
        uint[] memory orderIndexes,
        uint[][] memory tokenIdsList,
        int netAmount,
        uint royaltyFactor,
        address integrator
    ) external payable reentrancyGuard {
        require(tokenList.length > 0 && tokenList.length == orderIndexes.length && tokenList.length == tokenIdsList.length);
        require(royaltyFactor <= ROYALTYFACTOR_MAX, "Royalty");

        trades.push();
        Trade storage trade = trades[trades.length - 1];
        trade.taker = msg.sender;
        trade.royaltyFactor = uint64(royaltyFactor);
        trade.blockNumber = uint64(block.number);

        for (uint i = 0; i < orderIndexes.length; i++) {
            Token storage tokenInfo = tokens[tokenList[i]];
            tokenInfo.executed++;
            bytes32 orderKey = tokenInfo.ordersIndex[orderIndexes[i]];
            Order storage order = tokenInfo.orders[orderKey];
            trade.executedOrders.push(ExecutedOrder(tokenList[i], uint64(orderIndexes[i])));
            uint[] memory tokenIds = tokenIdsList[i];
            require(tokenIds.length > 0, "TokenIds");
            require(order.taker == address(0) || order.taker == msg.sender, "NotTaker");
            require(order.expiry == 0 || order.expiry >= block.timestamp, "Expired");

            (address nftFrom, address nftTo) = (order.buyOrSell == BuyOrSell.Buy) ? (msg.sender, order.maker) : (order.maker, msg.sender);
            if (order.anyOrAll == AnyOrAll.Any) {
                for (uint j = 0; j < tokenIds.length; j++) {
                    bool found = false;
                    if (order.tokenIds.length == 0) {
                        found = true;
                    } else {
                        for (uint k = 0; k < order.tokenIds.length && !found; k++) {
                            if (tokenIds[j] == order.tokenIds[k]) {
                                found = true;
                            }
                        }
                    }
                    require(found, "TokenId");
                    IERC721Partial(tokenInfo.token).safeTransferFrom(nftFrom, nftTo, tokenIds[j]);
                    tokenInfo.volumeToken++;
                    tokenInfo.volumeWeth += order.price;
                    addNetting(tokenInfo, tokenIds[j], trade, order);
                    order.tradeCount++;
                }
            } else {
                require(tokenIds.length == order.tokenIds.length, "TokenIds");
                for (uint j = 0; j < order.tokenIds.length; j++) {
                    require(tokenIds[j] == order.tokenIds[j], "TokenId");
                    IERC721Partial(tokenInfo.token).safeTransferFrom(nftFrom, nftTo, order.tokenIds[j]);
                    tokenInfo.volumeToken++;
                }
                order.tradeCount++;
                tokenInfo.volumeWeth += order.price;
                // NOTE - Royalty information for the FIRST tokenId for All
                addNetting(tokenInfo, order.tokenIds[0], trade, order);
            }
            require(order.tradeCount <= order.tradeMax, "Maxxed");
            emit OrderExecuted(tokenInfo.token, orderIndexes[i], trades.length - 1, tokenIds);
        }

        require(trade.netting[msg.sender] == netAmount, "NetAmount");
        transferNetted(trade);
        handleTips(integrator);
    }

        function addNetting(Token storage tokenInfo, uint tokenId, Trade storage trade, Order memory order) private {
        (address wethTo, address wethFrom) = (order.buyOrSell == BuyOrSell.Buy) ? (msg.sender, order.maker) : (order.maker, msg.sender);
        if (!trade.seen[wethFrom]) {
            trade.uniqueAddresses.push(wethFrom);
            trade.seen[wethFrom] = true;
        }
        if (!trade.seen[wethTo]) {
            trade.uniqueAddresses.push(wethTo);
            trade.seen[wethTo] = true;
        }
        trade.netting[wethFrom] -= int(order.price);
        try royaltyEngine.getRoyaltyView(tokenInfo.token, tokenId, order.price) returns (address payable[] memory recipients, uint256[] memory amounts) {
            require(recipients.length == amounts.length);
            uint royaltyFactor = (order.buyOrSell == BuyOrSell.Buy) ? trade.royaltyFactor : order.royaltyFactor;
            for (uint i = 0; i < recipients.length; i++) {
                if (!trade.seen[recipients[i]]) {
                    trade.uniqueAddresses.push(recipients[i]);
                    trade.seen[recipients[i]] = true;
                }
                uint royalty = amounts[i] * royaltyFactor / 100;
                trade.netting[recipients[i]] += int(royalty);
                trade.netting[wethTo] -= int(royalty);
            }
        } catch {
        }

        // Calculate the marketplace fee and deduct from what user needs to pay
        uint fee = order.price * MARKETPLACE_FEE / 1000;
        if (!trade.seen[owner]) {
            trade.uniqueAddresses.push(owner);
            trade.seen[owner] = true;
        }
        // Take the fee
        trade.netting[owner] += int(fee);
        trade.netting[wethTo] -= int(fee);

        // Add the order price
        trade.netting[wethTo] += int(order.price);
    }

    function transferNetted(Trade storage trade) private {
        for (uint i = 0; i < trade.uniqueAddresses.length; i++) {
            address account = trade.uniqueAddresses[i];
            delete trade.seen[account];
            if (trade.netting[account] < 0) {
                require(weth.transferFrom(account, address(this), uint(-trade.netting[account])), "-Weth");
            }
        }
        for (uint i = 0; i < trade.uniqueAddresses.length; i++) {
            address account = trade.uniqueAddresses[i];
            if (trade.netting[account] > 0) {
                require(weth.transfer(account, uint(trade.netting[account])), "+Weth");
            }
            delete trade.netting[account];
        }
        delete trade.uniqueAddresses;
    }
    function handleTips(address integrator) private {
        if (msg.value > 0) {
            uint integratorTip;
            if (integrator != address(0) && integrator != owner) {
                integratorTip = msg.value * 4 / 5;
                if (integratorTip > 0) {
                    payable(integrator).transfer(integratorTip);
                }
            }
            emit ThankYou(msg.value);
        }
    }
    receive() external payable {
        handleTips(owner);
    }
}

/// @author BokkyPooBah, Bok Consulting Pty Ltd
/// @title Decentralised ERC-721 exchange bulk data retrieval helper
contract NixHelper {

    enum OrderStatus {
        Executable,
        Expired,
        Maxxed,
        MakerNoWeth,
        MakerNoWethAllowance,
        MakerNoToken,
        MakerNotApprovedNix,
        UnknownError
    }

    Nix public nix;
    IERC20Partial immutable public weth;

    constructor(Nix _nix) {
        nix = _nix;
        weth = _nix.weth();
    }

    function getTokens(
        uint[] memory tokensIndices
    ) public view returns (
        address[] memory tokens,
        uint[] memory ordersLengthList,
        uint[] memory executedList,
        uint[] memory volumeTokenList,
        uint[] memory volumeWethList
    ) {
        uint length = tokensIndices.length;
        tokens = new address[](length);
        ordersLengthList = new uint[](length);
        executedList = new uint[](length);
        volumeTokenList = new uint[](length);
        volumeWethList = new uint[](length);
        for (uint i = 0; i < length; i++) {
            uint tokenIndex = tokensIndices[i];
            if (tokenIndex < nix.tokensLength()) {
                (address token, uint64 ordersLength, uint64 executed, uint64 volumeToken, uint volumeWeth) = nix.getToken(tokenIndex);
                tokens[i] = token;
                ordersLengthList[i] = ordersLength;
                executedList[i] = executed;
                volumeTokenList[i] = volumeToken;
                volumeWethList[i] = volumeWeth;
            }
        }
    }

    function orderStatus(address token, Nix.Order memory order) public view returns (OrderStatus) {
        if (order.expiry > 0 && order.expiry < block.timestamp) {
            return OrderStatus.Expired;
        }
        if (order.tradeCount >= order.tradeMax) {
            return OrderStatus.Maxxed;
        }
        if (order.buyOrSell == Nix.BuyOrSell.Buy) {
            uint wethBalance = weth.balanceOf(order.maker);
            if (wethBalance < order.price) {
                return OrderStatus.MakerNoWeth;
            }
            uint wethAllowance = weth.allowance(order.maker, address(nix));
            if (wethAllowance < order.price) {
                return OrderStatus.MakerNoWethAllowance;
            }
        } else {
            try IERC721Partial(token).isApprovedForAll(order.maker, address(nix)) returns (bool b) {
                if (!b) {
                    return OrderStatus.MakerNotApprovedNix;
                }
            } catch {
                return OrderStatus.UnknownError;
            }
            if (order.anyOrAll == Nix.AnyOrAll.Any) {
                if (order.tokenIds.length == 0) {
                    try IERC721Partial(token).balanceOf(order.maker) returns (uint b) {
                        if (b == 0) {
                            return OrderStatus.MakerNoToken;
                        }
                    } catch {
                        return OrderStatus.UnknownError;
                    }
                } else {
                    bool found = false;
                    for (uint j = 0; j < order.tokenIds.length && !found; j++) {
                        try IERC721Partial(token).ownerOf(order.tokenIds[j]) returns (address a) {
                            if (a == order.maker) {
                                found = true;
                            }
                        } catch {
                            return OrderStatus.UnknownError;
                        }
                    }
                    if (!found) {
                        return OrderStatus.MakerNoToken;
                    }
                }
            } else {
                for (uint j = 0; j < order.tokenIds.length; j++) {
                    try IERC721Partial(token).ownerOf(order.tokenIds[j]) returns (address a) {
                        if (a != order.maker) {
                            return OrderStatus.MakerNoToken;
                        }
                    } catch {
                        return OrderStatus.UnknownError;
                    }
                }
            }
        }
        return OrderStatus.Executable;
    }

    function getOrders(
        address token,
        uint[] memory orderIndices
    ) public view returns (
        address[] memory makers,
        address[] memory takers,
        uint[][] memory tokenIds,
        uint[] memory prices,
        uint[7][] memory data
    ) {
        uint length = orderIndices.length;
        makers = new address[](length);
        takers = new address[](length);
        tokenIds = new uint[][](length);
        prices = new uint[](length);
        data = new uint[7][](length);
        uint ordersLength = nix.ordersLength(token);
        for (uint i = 0; i < length; i++) {
            uint orderIndex = orderIndices[i];
            if (orderIndex < ordersLength) {
                Nix.Order memory order = nix.getOrder(token, orderIndex);
                makers[i] = order.maker;
                takers[i] = order.taker;
                tokenIds[i] = order.tokenIds;
                prices[i] = order.price;
                data[i][0] = uint(order.buyOrSell);
                data[i][1] = uint(order.anyOrAll);
                data[i][2] = uint(order.expiry);
                data[i][3] = uint(order.tradeCount);
                data[i][4] = uint(order.tradeMax);
                data[i][5] = uint(order.royaltyFactor);
                data[i][6] = uint(orderStatus(token, order));
            }
        }
    }

    function getTrades(
        uint[] memory tradeIndexes
    ) public view returns (
        address[] memory takers,
        uint[] memory royaltyFactors,
        uint[] memory blockNumbers,
        Nix.ExecutedOrder[][] memory ordersList
    ) {
        uint length = tradeIndexes.length;
        takers = new address[](length);
        royaltyFactors = new uint[](length);
        blockNumbers = new uint[](length);
        ordersList = new Nix.ExecutedOrder[][](length);
        uint tradesLength = nix.tradesLength();
        for (uint i = 0; i < length; i++) {
            uint tradeIndex = tradeIndexes[i];
            if (tradeIndex < tradesLength) {
                (address taker, uint64 royaltyFactor, uint64 blockNumber, Nix.ExecutedOrder[] memory orders) = nix.getTrade(tradeIndex);
                takers[i] = taker;
                royaltyFactors[i] = royaltyFactor;
                blockNumbers[i] = blockNumber;
                ordersList[i] = orders;
            }
        }
    }
}