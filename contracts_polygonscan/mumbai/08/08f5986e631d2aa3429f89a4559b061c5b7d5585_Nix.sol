/**
 *Submitted for verification at polygonscan.com on 2021-11-06
*/

pragma solidity ^0.8.7;


// ----------------------------------------------------------------------------
// Nix v0.9.0
//
// https://github.com/bokkypoobah/Nix
//
// Deployed to
//
// 
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
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
    address public newOwner;
    bool initOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Withdrawn(address indexed token, uint tokens, uint tokenId);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function init(address sender) public {
        require(!initOwner, "Already init");
        initOwner = true;
        owner = sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
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
        require(_executing != 1, "NO!");
        _executing = 1;
        _;
        _executing = 2;
    }
}

contract Nix is Owned, ReentrancyGuard, ERC721TokenReceiver, Initializable {
    using Address for address;

    enum OrderType { BuyAny, SellAny, BuyAll, SellAll }

    struct Order {
        address maker;
        address taker;
        uint[] tokenIds;
        uint price;
        OrderType orderType;
        uint64 expiry;
        uint64 tradeCount;
        uint64 tradeMax;
    }
    struct TokenInfo {
        address token;
        bytes32[] ordersIndex;
        mapping(bytes32 => Order) orders;
        uint64 executed;
        uint64 volumeToken;
        uint volumeWeth;
    }
    struct Netting {
        address accounts;
        int amount;
    }
    struct OrderInfo {
        address token;
        uint64 orderIndex;
    }
    struct Trade {
        address taker;
        uint64 blockNumber;
        address[] uniqueAddresses;
        mapping(address => bool) seen;
        mapping(address => int) netting;
        OrderInfo[] orders;
    }

    bytes4 private constant ERC721_INTERFACE = 0x80ac58cd; // https://eips.ethereum.org/EIPS/eip-721
    bytes4 private constant ERC721METADATA_INTERFACE = 0x5b5e139f;
    bytes4 private constant ERC721ENUMERABLE_INTERFACE = 0x780e9d63;

    IERC20Partial public weth;
    IRoyaltyEngineV1Partial public royaltyEngine;

    address[] private tokenInfosIndex;
    mapping(address => TokenInfo) public tokenInfos;
    Trade[] private trades;

    event MakerOrderAdded(address token, bytes32 orderKey, uint orderIndex);
    event TokenInfoAdded(address token, uint tokenInfoIndex);
    event TakerOrderExecuted(bytes32 orderKey, uint orderIndex);
    event ThankYou(uint tip);

    function initialize(IERC20Partial _weth, IRoyaltyEngineV1Partial _royaltyEngine) public initializer {
        init(msg.sender);
        weth = _weth;
        royaltyEngine = _royaltyEngine;
    }

    function onERC721Received(address /*_operator*/, address /*_from*/, uint _tokenId, bytes memory /*_data*/) external override returns(bytes4) {
        emit ThankYou(_tokenId);
        return this.onERC721Received.selector;
    }

    function tokenInfosLength() public view returns (uint) {
        return tokenInfosIndex.length;
    }
    function ordersLength(address token) public view returns (uint) {
        return tokenInfos[token].ordersIndex.length;
    }
    function tradesLength() public view returns (uint) {
        return trades.length;
    }
    function getTokenInfo(uint tokenInfoIndex) external view returns (address token, uint64 _ordersLength, uint64 executed, uint64 volumeToken, uint volumeWeth) {
        token = tokenInfosIndex[tokenInfoIndex];
        TokenInfo storage tokenInfo = tokenInfos[token];
        _ordersLength = uint64(tokenInfo.ordersIndex.length);
        executed = tokenInfo.executed;
        volumeToken = tokenInfo.volumeToken;
        volumeWeth = tokenInfo.volumeWeth;
    }
    function getOrder(address token, uint orderIndex) external view returns (bytes32 orderKey, Order memory order) {
        orderKey = tokenInfos[token].ordersIndex[orderIndex];
        order = tokenInfos[token].orders[orderKey];
    }
    function getTrade(uint tradeIndex) external view returns (address taker, uint64 blockNumber, OrderInfo[] memory orders) {
        Trade storage trade = trades[tradeIndex];
        return (trade.taker, trade.blockNumber, trade.orders);
    }

    function makerAddOrder(
        address taker,
        address token,
        uint[] memory tokenIds,
        uint price,
        OrderType orderType,
        uint64 expiry,
        uint64 tradeMax,
        address integrator
    ) external payable reentrancyGuard {
        // require(expiry == 0 || expiry > block.timestamp, "Invalid expiry");
        if (orderType == OrderType.BuyAll || orderType == OrderType.SellAll) {
            require(tokenIds.length > 0, "No tokenIds specified");
            require(tradeMax == 1, "Only single trade");
        } else {
            require(tradeMax > 0, "Must have at least one trade");
        }

        TokenInfo storage tokenInfo = tokenInfos[token];
        if (tokenInfo.token != token) {
            try IERC721Partial(token).supportsInterface(ERC721_INTERFACE) returns (bool b) {
                require(b, "ERC721");
                tokenInfosIndex.push(token);
                tokenInfo.token = token;
                emit TokenInfoAdded(token, tokenInfosIndex.length - 1);
            } catch {
                revert("Not ERC721");
            }
        }

        bytes32 _orderKey = keccak256(abi.encodePacked(msg.sender, taker, token, tokenIds, orderType, expiry));
        require(tokenInfo.orders[_orderKey].maker == address(0), "Duplicate");

        tokenInfo.ordersIndex.push(_orderKey);
        Order storage order = tokenInfo.orders[_orderKey];
        order.maker = msg.sender;
        order.taker = taker;
        order.tokenIds = tokenIds;
        order.price = price;
        order.orderType = orderType;
        order.expiry = expiry;
        order.tradeMax = tradeMax;
        emit MakerOrderAdded(token, _orderKey, tokenInfo.ordersIndex.length - 1);
        handleTips(integrator);
    }

    // event MakerTokenIdsUpdated(bytes32 orderKey, uint orderIndex);
    // function makerUpdateTokenIds(uint orderIndex, uint[] memory tokenIds, address integrator) external payable reentrancyGuard {
    //     bytes32 orderKey = ordersIndex[orderIndex];
    //     Order storage order = orders[orderKey];
    //     require(msg.sender == order.maker, "Not maker");
    //     order.tokenIds = tokenIds;
    //     emit MakerTokenIdsUpdated(orderKey, orderIndex);
    //     handleTips(integrator);
    // }

    // event MakerOrderUpdated(bytes32 orderKey, uint orderIndex);
    // function makerUpdateOrder(uint orderIndex, uint price, uint64 expiry, int64 tradeMaxAdjustment, address integrator) external payable reentrancyGuard {
    //     bytes32 orderKey = ordersIndex[orderIndex];
    //     Order storage order = orders[orderKey];
    //     require(msg.sender == order.maker, "Not maker");
    //     order.price = price;
    //     order.expiry = expiry;
    //     // TODO: tradeMax must be 1 for BuyAll and SellAll - cannot change this
    //     if (tradeMaxAdjustment < 0) {
    //         uint64 subtract = uint64(-tradeMaxAdjustment);
    //         if (subtract > (order.tradeMax - order.tradeCount)) {
    //             order.tradeMax -= subtract;
    //         } else {
    //             order.tradeMax = order.tradeCount;
    //         }
    //     } else {
    //         order.tradeMax += uint64(tradeMaxAdjustment);
    //     }
    //     emit MakerOrderUpdated(orderKey, orderIndex);
    //     handleTips(integrator);
    // }

    function takerExecuteOrders(address[] memory tokenList, uint[] memory orderIndexes, uint[][] memory tokenIdsList, int totalPrice, address integrator) external payable reentrancyGuard {
        require(tokenList.length > 0);
        require(tokenList.length == orderIndexes.length);
        require(tokenList.length == tokenIdsList.length);

        trades.push();
        Trade storage trade = trades[trades.length - 1];
        trade.taker = msg.sender;
        trade.blockNumber = uint64(block.number);

        for (uint i = 0; i < orderIndexes.length; i++) {
            address token = tokenList[i];
            TokenInfo storage tokenInfo = tokenInfos[token];
            tokenInfo.executed++;
            bytes32 orderKey = tokenInfo.ordersIndex[orderIndexes[i]];
            Order storage order = tokenInfo.orders[orderKey];
            trade.orders.push(OrderInfo(token, uint64(orderIndexes[i])));
            uint[] memory tokenIds = tokenIdsList[i];
            require(tokenIds.length > 0, "TokenIds");
            require(order.taker == address(0) || order.taker == msg.sender, "Not taker");
            require(order.expiry == 0 || order.expiry >= block.timestamp, "Expired");
            require(order.tradeCount < order.tradeMax, "Maxxed");

            address nftFrom;
            address nftTo;
            if (order.orderType == OrderType.BuyAny || order.orderType == OrderType.BuyAll) {
                (nftFrom, nftTo) = (msg.sender, order.maker);
            } else {
                (nftFrom, nftTo) = (order.maker, msg.sender);
            }

            if (order.orderType == OrderType.BuyAny || order.orderType == OrderType.SellAny) {
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
                    IERC721Partial(token).safeTransferFrom(nftFrom, nftTo, tokenIds[j]);
                    tokenInfo.volumeToken++;
                    tokenInfo.volumeWeth += order.price;
                    addNetting(token, tokenIds[j], trade, nftTo, nftFrom, order.price);
                }
            } else { // if (order.orderType == OrderType.BuyAll || order.orderType == OrderType.SellAll) {
                for (uint j = 0; j < order.tokenIds.length; j++) {
                    require(tokenIds[j] == order.tokenIds[j], "TokenIds");
                    IERC721Partial(token).safeTransferFrom(nftFrom, nftTo, order.tokenIds[j]);
                    tokenInfo.volumeToken++;
                }
                tokenInfo.volumeWeth += order.price;
                // NOTE - Using first one
                addNetting(token, order.tokenIds[0], trade, nftTo, nftFrom, order.price);
            }
            order.tradeCount++;
            emit TakerOrderExecuted(orderKey, i);
        }
        require(trade.netting[msg.sender] == totalPrice, "TotalPrice");
        transferNetted(trade);
        handleTips(integrator);
    }

    function addNetting(address token, uint tokenId, Trade storage trade, address wethFrom, address wethTo, uint amount) internal {
        if (!trade.seen[wethFrom]) {
            trade.uniqueAddresses.push(wethFrom);
            trade.seen[wethFrom] = true;
        }
        if (!trade.seen[wethTo]) {
            trade.uniqueAddresses.push(wethTo);
            trade.seen[wethTo] = true;
        }
        trade.netting[wethFrom] -= int(amount);

        (address payable[] memory recipients, uint256[] memory amounts) = royaltyEngine.getRoyaltyView(token, tokenId, amount);
        require(recipients.length == amounts.length);
        for (uint i = 0; i < recipients.length; i++) {
            if (!trade.seen[recipients[i]]) {
                trade.uniqueAddresses.push(recipients[i]);
                trade.seen[recipients[i]] = true;
            }
            trade.netting[recipients[i]] += int(amounts[i]);
            trade.netting[wethTo] -= int(amounts[i]);
        }
        trade.netting[wethTo] += int(amount);
    }
    function transferNetted(Trade storage trade) internal {
        for (uint i = 0; i < trade.uniqueAddresses.length; i++) {
            address account = trade.uniqueAddresses[i];
            delete trade.seen[account];
            if (trade.netting[account] < 0) {
                require(weth.transferFrom(account, address(this), uint(-trade.netting[account])), "-Weth tx");
            }
        }
        for (uint i = 0; i < trade.uniqueAddresses.length; i++) {
            address account = trade.uniqueAddresses[i];
            if (trade.netting[account] > 0) {
                require(weth.transfer(account, uint(trade.netting[account])), "+Weth tx");
            }
            delete trade.netting[account];
        }
        delete trade.uniqueAddresses;
    }
    function handleTips(address integrator) private {
        if (msg.value > 0) {
            uint integratorTip;
            if (integrator != address(0) && integrator != owner) {
                integratorTip = msg.value / 2;
                if (integratorTip > 0) {
                    payable(integrator).transfer(integratorTip);
                }
            }
            emit ThankYou(msg.value);
        }
    }
    receive() external payable {
    }
}

contract NixHelper {

    Nix public nix;
    IERC20Partial immutable public weth;

    constructor(Nix _nix) {
        nix = _nix;
        weth = _nix.weth();
    }

    function getTokenInfos(uint[] memory tokenInfosIndices) public view returns (address[] memory tokens, uint64[] memory ordersLengthList, uint64[] memory executedList, uint64[] memory volumeTokenList, uint[] memory volumeWethList) {
        uint length = tokenInfosIndices.length;
        tokens = new address[](length);
        ordersLengthList = new uint64[](length);
        executedList = new uint64[](length);
        volumeTokenList = new uint64[](length);
        volumeWethList = new uint[](length);
        for (uint i = 0; i < length; i++) {
            uint tokenInfoIndex = tokenInfosIndices[i];
            if (tokenInfoIndex < nix.tokenInfosLength()) {
                (address token, uint64 ordersLength, uint64 executed, uint64 volumeToken, uint volumeWeth) = nix.getTokenInfo(tokenInfoIndex);
                tokens[i] = token;
                ordersLengthList[i] = ordersLength;
                executedList[i] = executed;
                volumeTokenList[i] = volumeToken;
                volumeWethList[i] = volumeWeth;
            }
        }
    }


    enum OrderStatus { Executable, Expired, Maxxed, MakerNoWeth, MakerNoWethAllowance, MakerNoToken, MakerNotApprovedNix, UnknownError }
    function orderStatus(address token, Nix.Order memory order) public view returns (OrderStatus) {
        if (order.expiry > 0 && order.expiry < block.timestamp) {
            return OrderStatus.Expired;
        }
        if (order.tradeCount >= order.tradeMax) {
            return OrderStatus.Maxxed;
        }
        if (order.orderType == Nix.OrderType.BuyAny || order.orderType == Nix.OrderType.BuyAll) {
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
            if (order.orderType == Nix.OrderType.SellAny) {
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
            } else { // SellAll
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
        bytes32[] memory orderKeys,
        address[] memory makers,
        address[] memory takers,
        uint[][] memory tokenIds,
        uint[] memory prices,
        uint64[5][] memory data
    ) {
        uint length = orderIndices.length;
        orderKeys = new bytes32[](length);
        makers = new address[](length);
        takers = new address[](length);
        tokenIds = new uint[][](length);
        prices = new uint[](length);
        data = new uint64[5][](length);
        uint ordersLength = nix.ordersLength(token);
        for (uint i = 0; i < length; i++) {
            uint orderIndex = orderIndices[i];
            if (orderIndex < ordersLength) {
                (bytes32 orderKey, Nix.Order memory order) = nix.getOrder(token, orderIndex);
                orderKeys[i] = orderKey;
                makers[i] = order.maker;
                takers[i] = order.taker;
                tokenIds[i] = order.tokenIds;
                prices[i] = order.price;
                data[i][0] = uint64(order.orderType);
                data[i][1] = uint64(order.expiry);
                data[i][2] = uint64(order.tradeCount);
                data[i][3] = uint64(order.tradeMax);
                data[i][4] = uint64(orderStatus(token, order));
            }
        }
    }

    function getTrades(uint[] memory tradeIndexes) public view returns (address[] memory takers, uint64[] memory blockNumbers, Nix.OrderInfo[][] memory ordersList) {
        uint length = tradeIndexes.length;
        takers = new address[](length);
        blockNumbers = new uint64[](length);
        ordersList = new Nix.OrderInfo[][](length);
        uint tradesLength = nix.tradesLength();
        for (uint i = 0; i < length; i++) {
            uint tradeIndex = tradeIndexes[i];
            if (tradeIndex < tradesLength) {
                (address taker, uint64 blockNumber, Nix.OrderInfo[] memory orders) = nix.getTrade(tradeIndex);
                takers[i] = taker;
                blockNumbers[i] = blockNumber;
                ordersList[i] = orders;
            }
        }
    }
}