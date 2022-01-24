/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: BUSL-1.1


// File: https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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
}

// File: contracts/clearing.sol


// Contract on rinkeby: 

// UNI on rinkeby: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, USDC on rinkeby: 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b, WETH on rinkeby: 0xc778417e063141139fce010982780140aa0cd5ab, 



pragma solidity ^0.8.11;

interface xchg_interface {
    function getQuoteContracts() external view returns(address[] memory);
    function getWhitelistedBaseContracts() external view returns(address[] memory);
}

contract clearing {

    struct OrderInfo {
        address taker;
        address maker;
        address makerCoinContract;
        address takerCoinContract;
        uint256 totalMakerQty;
        uint256 totalTakerQty;
        uint256 toBeSentByTaker;
        uint256 toBeSentByMaker;
        bytes32 messageHash;
    }

    mapping(address => uint256) public nonces;
    mapping(bytes32 => uint256) public orderFilledTakerQty; // keccak256 mesasge hash => filledTakerQty
    uint256 maker_fee;
    uint256 taker_fee;
    address xchgInterfaceAddress;

    constructor(address _xchgInterfaceAddress /*, uint256 _makerFee, uint256 _takerFee */) {
        // Have an option to change this address as well if you have to change interface address anytime. Maybe, think about it later.
        xchgInterfaceAddress = _xchgInterfaceAddress;
        maker_fee = 750; // Percentage fee = divided by 10k, decimal notation: divided by 1mil
        taker_fee = 750;
    }

    modifier onlyMaker(address maker) {
        require(maker == msg.sender, "ERROR: Order can only be by cancelled by it's maker.");
        _;
    }

    // First making this such that the taker has to take the whole order, will add partial orders later on. 
    // The frontend will convert the wrapped coin balance to the balance of the actual coins and back. We won't be showing the wrapped coin balnace to the user, it will end up confusing them. 
    // The take public order function will ALWAYS, ALWAYS have the exact details which the maker put. If maker is buying, then the side will be buy, and ofc that'll mean that the taker is selling. 

    // Take care of the wrapped coin as well please.

    function takePublicOrder(address maker, address makerCoinContract, address takerCoinContract, uint256 totalMakerQty, uint256 totalTakerQty, uint64 deadline, uint64 nonce, bytes memory signature, uint256 toBeSentByTaker) public {
        OrderInfo memory i = OrderInfo(msg.sender, maker, makerCoinContract, takerCoinContract, totalMakerQty, totalTakerQty, toBeSentByTaker, 0, 0);
        require(nonce == nonces[maker], "ERROR: ORDER_CANCELLED_OR_DOESN'T_EXIST");
        require(deadline >= block.timestamp, "ORDER_EXPIRED");

        bytes32 messageHash = _getMessageHash(i.maker, i.makerCoinContract, i.takerCoinContract, i.totalMakerQty, i.totalTakerQty, deadline, nonce);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

        require(ecrecover(ethSignedMessageHash, v, r, s) == maker, "ERROR: INVALID_SIGNATURE");
        require(orderFilledTakerQty[messageHash] != (2**256)-1, "ERROR: ORDER_ALREADY_EXECUTED");
        require(toBeSentByTaker <= totalTakerQty - orderFilledTakerQty[messageHash], "ERROR: INSUFFICIENT_QUANTITY_AVAILABLE"); // To be sentByTaker amount has been verified

        // Signature is valid + quantity is available. Continue to step 2.
        i.messageHash = messageHash;
        _takePublicOrder(i);
    }

    function _takePublicOrder(OrderInfo memory i) internal {
        // Calculation of fees + checking quotes & bases
        xchg_interface xchg_inter = xchg_interface(xchgInterfaceAddress);

        address[] memory _quoteContracts = xchg_inter.getQuoteContracts();
        address[] memory _baseContracts = xchg_inter.getWhitelistedBaseContracts();

        (address baseContract, address quoteContract) = _checkQuoteAndBaseContracts(i.makerCoinContract, i.takerCoinContract, _quoteContracts, _baseContracts);

        require(baseContract != address(0), "ERROR: Base contract not allowed.");
        require(quoteContract != address(0), "ERROR: Invalid quote contract provided in the order.");

        // For the base contract, check the other condition too for the wrapped coin later. 
        // The person sending the quoteContract will pay the extra fees.

        i.toBeSentByMaker = (i.totalMakerQty * (i.toBeSentByTaker * 1000000000) / i.totalTakerQty) / 1000000000;

        // Signature is valid + quantity is available + no underflow, proceed to execute the order.

        // Calculate fees using quote contract
        if(i.makerCoinContract == quoteContract) {
            // Maker sends the extra fees, from his quote.
            uint256 feeAddition = (i.toBeSentByMaker * maker_fee) /1000000;
            uint256 feeDeduction = (i.toBeSentByMaker * taker_fee) /1000000;
            _executeTx(i, true, feeAddition, feeDeduction);
        } else {
            // Taker contract is the quote, he sends the extra
            uint256 feeAddition = (i.toBeSentByTaker * taker_fee) / 1000000;
            uint256 feeDeduction = (i.toBeSentByTaker * maker_fee) / 1000000;
            _executeTx(i, false, feeAddition, feeDeduction);
        }
    }

    function _executeTx(OrderInfo memory i, bool quoteIsMaker, uint256 feeAddition, uint256 feeDeduction) internal {
        IERC20 _makerCoinContract = IERC20(i.makerCoinContract);
        IERC20 _takerCoinContract = IERC20(i.takerCoinContract);

        if(quoteIsMaker) {
            require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker + feeAddition, "EXECUTION_FAILED: INSUFFICIENT_MAKER_BALANCE (make sure the balance includes the fee)");
            require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker, "EXECUTION_FAILED: INSUFFICIENT_TAKER_BALANCE");
            require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker + feeAddition, "EXECUTION_FAILED: MAKER_APPROVAL_MISSING (make sure the amount approved includes the fees)");
            require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker, "EXECUTION_FAILED: TAKER_APPROVAL_MISSING");

            // First quote coin goes this contract, and then to taker after deducting fees.
            TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, address(this), i.toBeSentByMaker + feeAddition);
            TransferHelper.safeTransfer(i.makerCoinContract, i.taker, i.toBeSentByMaker - feeDeduction);

            TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, i.maker, i.toBeSentByTaker);
        } else /* QuoteIsTaker */ {
            require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "EXECUTION_FAILED: INSUFFICIENT_MAKER_BALANCE");
            require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker + feeAddition, "EXECUTION_FAILED: INSUFFICIENT_TAKER_BALANCE (make sure the balance includes the fee)");
            require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "EXECUTION_FAILED: MAKER_APPROVAL_MISSING");
            require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker + feeAddition, "EXECUTION_FAILED: TAKER_APPROVAL_MISSING (make sure the amount approved includes the fees)");

            // First quote coin goes this contract, and then to taker after deducting fees.
            TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, i.taker, i.toBeSentByMaker);

            TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, address(this), i.toBeSentByTaker + feeAddition);
            TransferHelper.safeTransfer(i.takerCoinContract, i.maker, i.toBeSentByTaker - feeDeduction);
        }

        // Check if the order is now partially filled or fully filled
        uint256 taker_amount_left = i.totalTakerQty - i.toBeSentByTaker - orderFilledTakerQty[i.messageHash];
        
        if(taker_amount_left > 0) {
            // Add it to the partial fills and emit an event of a partial fill
            orderFilledTakerQty[i.messageHash] += i.toBeSentByTaker;
        } else {
            orderFilledTakerQty[i.messageHash] = (2**256)-1;
        }
    }

    function cancelAllOrders() public {
        nonces[msg.sender] += 1;
    }

    // Fix this lol anyone can cancel someone's order
    function cancelOrder(address maker, address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce) public onlyMaker(maker) {
        bytes32 orderId = _getMessageHash(maker, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce);
        orderFilledTakerQty[orderId] = (2**256)-1;
    }

    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getOrderHashToBeSigned(address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce) public view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce));
    }

    function _getMessageHash(address maker, address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(maker, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce));
    }

    function _checkContractAddress(address contractToBeChecked, address[] memory contractsList) internal pure returns(bool) {        
        for(uint256 n = 0; n < contractsList.length; n++) {
            if(contractsList[n] == contractToBeChecked) return true;
        }

        return false;
    }

    function _checkQuoteAndBaseContracts(address makerContract, address takerContract, address[] memory _quoteContracts, address[] memory _baseContracts) internal pure returns(address, address) {
        address _quoteContract = address(0);
        address _baseContract = address(0);
        
        if(_checkContractAddress(makerContract, _quoteContracts) == true) {
            _quoteContract = makerContract;
            if(_checkContractAddress(takerContract, _baseContracts) == true) {
                // All perfect!
                _baseContract = takerContract;
            }
        
        } else if(_checkContractAddress(takerContract, _quoteContracts) == true) {
            _quoteContract = takerContract;
            if(_checkContractAddress(makerContract, _baseContracts) == true) {
                // All perfect!
                _baseContract = makerContract;
            }
        }

        return(_baseContract, _quoteContract);
    }

    // function manageUSDCFees() public onlyFeeManager {

    // }
}