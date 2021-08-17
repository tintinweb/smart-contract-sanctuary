// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Math.sol";

import "./IBridgeSwap.sol";
import "./Trustable.sol";

contract Bridge is Trustable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for ERC20;

    struct Order {
        uint id;
        uint8 tokenId;
        address sender;
        bytes32 target;
        uint amount;
        uint feeAmount;
        uint8 decimals;
        uint8 destination;
        address tokenIn;
        bytes32 tokenOut;
    }

    struct Token {
        ERC20 token;
        address feeTarget;
        uint16 defaultFee;
        uint defaultFeeBase;
        uint defaultMinAmount;
        uint defaultMaxAmount;
        uint bonus;
    }

    struct Config {
        uint16 fee;
        uint feeBase;
        uint minAmount;
        uint maxAmount;
        bool directTransferAllowed;
    }

    struct CompleteParams {
        uint orderId;
        uint8 dstFrom;
        uint8 tokenId;
        address payable to;
        uint amount;
        uint decimals;
        ERC20 tokenOut;
        address[] swapPath;
    }

    event OrderCreated(uint indexed id, Order order);
    event OrderCompleted(uint indexed id, uint8 indexed dstFrom);

    uint nextOrderId = 0;
    uint8 tokensLength = 0;
    uint8 nativeTokenId = 255;

    // swap settings
    IBridgeSwap public swapper;
    bool public swapsAllowed = false;
    uint8 public swapDefaultTokenId = 0;

    mapping (uint8 => Token) public tokens;
    mapping (address => uint8) public addresses;
    mapping (uint8 => mapping (uint8 => Config)) public configs;
    mapping (uint => Order) public orders;
    EnumerableSet.UintSet private orderIds;
    mapping (bytes32 => bool) public completed;

    function setToken(
        uint8 tokenId,
        ERC20 token,
        address feeTarget,
        uint16 defaultFee,
        uint defaultFeeBase,
        uint defaultMinAmount,
        uint defaultMaxAmount,
        uint8 inputDecimals,
        uint bonus
    ) external onlyOwner {
        require(defaultFee <= 10000, "invalid fee");
        tokens[tokenId] = Token(
            token,
            feeTarget,
            defaultFee,
            convertAmount(token, defaultFeeBase, inputDecimals),
            convertAmount(token, defaultMinAmount, inputDecimals),
            convertAmount(token, defaultMaxAmount, inputDecimals),
            bonus
        );
        addresses[address(token)] = tokenId;

        if (tokenId + 1 > tokensLength) {
            tokensLength = tokenId + 1;
        }
    }

    function setFeeTarget(uint8 tokenId, address feeTarget) external onlyOwner {
        tokens[tokenId].feeTarget = feeTarget;
    }

    function setDefaultFee(uint8 tokenId, uint16 defaultFee) external onlyOwner {
        require(defaultFee <= 10000, "invalid fee");
        tokens[tokenId].defaultFee = defaultFee;
    }

    function setDefaultFeeBase(uint8 tokenId, uint defaultFeeBase, uint8 inputDecimals) external onlyOwner {
        tokens[tokenId].defaultFeeBase = convertAmount(tokens[tokenId].token, defaultFeeBase, inputDecimals);
    }

    function setDefaultMinAmount(uint8 tokenId, uint defaultMinAmount, uint8 inputDecimals) external onlyOwner {
        tokens[tokenId].defaultMinAmount = convertAmount(tokens[tokenId].token, defaultMinAmount, inputDecimals);
    }

    function setDefaultMaxAmount(uint8 tokenId, uint defaultMaxAmount, uint8 inputDecimals) external onlyOwner {
        tokens[tokenId].defaultMaxAmount = convertAmount(tokens[tokenId].token, defaultMaxAmount, inputDecimals);
    }

    function setBonus(uint8 tokenId, uint bonus) external onlyOwner {
        tokens[tokenId].bonus = bonus;
    }

    function setFee(uint8 tokenId, uint8 destination, uint16 fee) external onlyOwner {
        require(fee <= 10000, "invalid fee");
        configs[tokenId][destination].fee = fee;
    }

    function setFeeBase(uint8 tokenId, uint8 destination, uint feeBase, uint8 inputDecimals) external onlyOwner {
        configs[tokenId][destination].feeBase = convertAmount(tokens[tokenId].token, feeBase, inputDecimals);
    }

    function setMinAmount(uint8 tokenId, uint8 destination, uint minAmount, uint8 inputDecimals) external onlyOwner {
        configs[tokenId][destination].minAmount = convertAmount(tokens[tokenId].token, minAmount, inputDecimals);
    }

    function setMaxAmount(uint8 tokenId, uint8 destination, uint maxAmount, uint8 inputDecimals) external onlyOwner {
        configs[tokenId][destination].maxAmount = convertAmount(tokens[tokenId].token, maxAmount, inputDecimals);
    }

    function setDirectTransferAllowed(uint8 tokenId, uint8 destination, bool directTransferAllowed) external onlyOwner {
        configs[tokenId][destination].directTransferAllowed = directTransferAllowed;
    }

    function setConfig(uint8 tokenId, uint8 destination, Config calldata config) external onlyOwner {
        configs[tokenId][destination] = config;
    }

    function setSwapper(IBridgeSwap newSwapper) external onlyOwner {
        swapper = newSwapper;
    }

    function setSwapSettings(bool allowed, uint8 tokenId) external onlyOwner {
        swapsAllowed = allowed;
        swapDefaultTokenId = tokenId;
    }

    function createWithSwap(
        ERC20 tokenIn,
        uint amount,
        uint8 destination,
        bytes32 target,
        bytes32 tokenOut,
        address[] calldata swapPath
    ) external payable {
        require(swapsAllowed && address(swapper) != address(0), "swaps currently disabled");

        // collect user tokens
        if (address(tokenIn) == address(1)) {
            require (amount == msg.value, "native token amount must be equal amount parameter");
        } else {
            tokenIn.safeTransferFrom(msg.sender, address(this), amount);
        }

        // default transfer token
        uint8 tokenId = swapDefaultTokenId;

        // checking for direct transfer allowed
        uint8 tokenInId = addresses[address(tokenIn)];
        if (tokens[tokenInId].token == tokenIn && configs[tokenInId][destination].directTransferAllowed) {
            tokenId = tokenInId;
        }

        // transfer token
        Token memory tok = tokens[tokenId];

        // swap user tokens if need
        if (tok.token != tokenIn) {
            if (address(tokenIn) == address(1)) {
                amount = swapper.swapFromNative{ value: amount }(tok.token, address(this), swapPath);
            } else {
                tokenIn.approve(address(swapper), amount);
                amount = swapper.swap(tokenIn, amount, tok.token, address(this), swapPath);
            }
        }

        require(checkAmount(tokenId, destination, amount), "amount must be in allowed range");

        uint feeAmount = transferFee(tokenId, destination, amount);

        orders[nextOrderId] = Order(
            nextOrderId,
            tokenId,
            msg.sender,
            target,
            amount - feeAmount,
            feeAmount,
            tokenDecimals(tok.token),
            destination,
            address(tokenIn),
            tokenOut
        );
        orderIds.add(nextOrderId);

        emit OrderCreated(nextOrderId, orders[nextOrderId]);
        nextOrderId++;
    }

    function create(uint8 tokenId, uint amount, uint8 destination, bytes32 target) public payable {
        Token storage tok = tokens[tokenId];
        require(address(tok.token) != address(0), "unknown token");

        require(checkAmount(tokenId, destination, amount), "amount must be in allowed range");

        if (address(tok.token) == address(1)) {
            require (amount == msg.value, "native token amount must be equal amount parameter");
        } else {
            tok.token.safeTransferFrom(msg.sender, address(this), amount);
        }

        uint feeAmount = transferFee(tokenId, destination, amount);

        orders[nextOrderId] = Order(
            nextOrderId,
            tokenId,
            msg.sender,
            target,
            amount - feeAmount,
            feeAmount,
            tokenDecimals(tok.token),
            destination,
            address(0),
            bytes32(0)
        );
        orderIds.add(nextOrderId);

        emit OrderCreated(nextOrderId, orders[nextOrderId]);
        nextOrderId++;
    }

    function closeOrder(uint orderId) external onlyTrusted {
        orderIds.remove(orderId);
    }

    function closeManyOrders(uint[] calldata _orderIds) external onlyTrusted {
        for (uint i = 0; i < _orderIds.length; i++) {
            orderIds.remove(_orderIds[i]);
        }
    }

    function completeOrder(
        uint orderId,
        uint8 dstFrom,
        uint8 tokenId,
        address payable to,
        uint amount,
        uint decimals,
        ERC20 tokenOut,
        address[] calldata swapPath
    ) public onlyTrusted {
        bytes32 orderHash = keccak256(abi.encodePacked(orderId, dstFrom));
        require (completed[orderHash] == false, "already transfered");
        require (!Address.isContract(to), "contract targets not supported");

        Token storage tok = tokens[tokenId];
        require(address(tok.token) != address(0), "unknown token");

        amount = convertAmount(tok.token, amount, decimals);

        if (address(tokenOut) != address(0) && tok.token != tokenOut) {
            tok.token.approve(address(swapper), amount);
            if (address(tokenOut) == address(1)) {
                swapper.swapToNative(tok.token, amount, to, swapPath);
            } else {
                swapper.swap(tok.token, amount, tokenOut, to, swapPath);
            }
        } else if (address(tok.token) == address(1)) {
            to.transfer(amount);
        } else {
            tok.token.safeTransfer(to, amount);
        }

        completed[orderHash] = true;

        uint bonus = Math.min(tok.bonus, address(this).balance);
        if (bonus > 0) {
            to.transfer(bonus);
        }

        emit OrderCompleted(orderId, dstFrom);
    }

    function completeManyOrders(CompleteParams[] calldata params) external onlyTrusted {
        for (uint i = 0; i < params.length; i++) {
            completeOrder(
                params[i].orderId,
                params[i].dstFrom,
                params[i].tokenId,
                params[i].to,
                params[i].amount,
                params[i].decimals,
                params[i].tokenOut,
                params[i].swapPath
            );
        }
    }

    function withdraw(uint8 tokenId, address payable to, uint amount, uint8 inputDecimals) external onlyTrusted {
        Token storage tok = tokens[tokenId];

        if (address(tok.token) == address(1)) {
            to.transfer(convertAmount(tok.token, amount, inputDecimals));
        } else {
            tok.token.safeTransfer(to, convertAmount(tok.token, amount, inputDecimals));
        }
    }

    function withdrawToken(ERC20 token, address payable to, uint amount, uint8 inputDecimals) external onlyTrusted {
        if (address(token) == address(1)) {
            to.transfer(convertAmount(token, amount, inputDecimals));
        } else {
            token.safeTransfer(to, convertAmount(token, amount, inputDecimals));
        }
    }

    function isCompleted(uint orderId, uint8 dstFrom) external view returns (bool) {
        return completed[keccak256(abi.encodePacked(orderId, dstFrom))];
    }

    function listOrders() external view returns (Order[] memory) {
        Order[] memory list = new Order[](orderIds.length());
        for (uint i = 0; i < orderIds.length(); i++) {
            list[i] = orders[orderIds.at(i)];
        }

        return list;
    }

    function listTokensNames() external view returns (string[] memory) {
        string[] memory list = new string[](tokensLength);
        for (uint8 i = 0; i < tokensLength; i++) {
            if (address(tokens[i].token) != address(0)) {
                list[i] = tokens[i].token.symbol();
            }
        }

        return list;
    }

    receive() external payable {}

    function convertAmount(ERC20 token, uint amount, uint fromDecimals) view private returns (uint) {
        return amount * (10 ** tokenDecimals(token)) / (10 ** fromDecimals);
    }

    function tokenDecimals(ERC20 token) private view returns (uint8) {
        if (address(token) == address(1)) {
            return 18;
        } else {
            return token.decimals();
        }
    }

    function checkAmount(uint8 tokenId, uint8 destination, uint amount) private view returns (bool) {
        Token memory tok = tokens[tokenId];
        Config memory config = configs[tokenId][destination];

        uint min = tok.defaultMinAmount;
        uint max = tok.defaultMaxAmount;

        if (config.minAmount > 0) {
            min = config.minAmount;
        }
        if (config.maxAmount > 0) {
            max = config.maxAmount;
        }

        return amount >= min && amount <= max;
    }

    function transferFee(uint8 tokenId, uint8 destination, uint amount) private returns (uint feeAmount) {
        Token memory tok = tokens[tokenId];
        Config memory config = configs[tokenId][destination];

        uint fee = tok.defaultFee;
        uint feeBase = tok.defaultFeeBase;

        if (config.fee > 0) {
            fee = config.fee;
        }
        if (config.feeBase > 0) {
            feeBase = config.feeBase;
        }

        feeAmount = feeBase + amount * fee / 10000;
        if (feeAmount > 0 && tok.feeTarget != address(this)) {
            tok.token.safeTransfer(tok.feeTarget, feeAmount);
        }
    }
}