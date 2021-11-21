//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;
import "./routers/BaseAggregator.sol";

/// @title Rainbow swap aggregator contract
contract RainbowRouter is BaseAggregator {
    address public owner;

    constructor() {
        owner = msg.sender;
        status = 1;
    }

    /// @dev modifier that ensures only the owner is allowed to call a specific method
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner address of the new owner
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        owner = newOwner;
    }

    /// @dev method to withdraw ERC20 tokens (from the fees)
    /// @param token address of the token to withdraw
    /// @param to address that's receiving the tokens
    /// @param amount amount of tokens to withdraw
    function withdrawTokenFees(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev method to withdraw ETH (from the fees)
    /// @param to address that's receiving the ETH
    /// @param amount amount of ETH to withdraw
    function withdrawEthFees(address to, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(to, amount);
    }

    /// @dev method to approve other ERC20s
    // This is useful so we can manually preapprove top pairs
    // making future swaps consume less gas
    /// @param token address of the token to approve
    /// @param spender address that will be approved to spend the tokens
    /// @param amount allowance amount
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeApprove(token, spender, amount);
    }

    receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";

/// @title Rainbow base aggregator contract
contract BaseAggregator {
    /// @dev Used to prevent re-entrancy
    uint256 internal status;

    /// @dev modifier that prevents reentrancy attacks on specific methods
    modifier nonReentrant() {
        // On the first call to nonReentrant, status will be 1
        require(status != 2, "NON_REENTRANT");

        // Any calls to nonReentrant after this point will fail
        status = 2;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        status = 1;
    }

    /** INTERNAL **/

    /// @dev internal method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    function _fillQuoteTokenToEth(
        address sellTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints
    ) internal {
        // 1 - Get the initial eth amount
        uint256 initialEthAmount = address(this).balance - msg.value;

        // 2 - Move the tokens to this contract
        TransferHelper.safeTransferFrom(
            sellTokenAddress,
            msg.sender,
            address(this),
            sellAmount
        );

        // 3 - Approve the aggregator's contract to swap the tokens
        if (
            IERC20(sellTokenAddress).allowance(address(this), swapTarget) <
            sellAmount
        ) {
            TransferHelper.safeApprove(
                sellTokenAddress,
                swapTarget,
                type(uint256).max
            );
        }

        // 4 - Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        // 5 - Substract the fees and send the rest to the user
        // Fees will be held in this contract
        uint256 finalEthAmount = address(this).balance;
        uint256 ethDiff = finalEthAmount - initialEthAmount;

        if (feePercentageBasisPoints > 0) {
            uint256 fees = (ethDiff * feePercentageBasisPoints) / 10000;
            uint256 amountMinusFees = ethDiff - fees;
            TransferHelper.safeTransferETH(msg.sender, amountMinusFees);
            // when there's no fee, 1inch sends the fund directly to the user
            // we check to prevent sending 0 ETH in that case
        } else if (ethDiff > 0) {
            TransferHelper.safeTransferETH(msg.sender, ethDiff);
        }
    }

    /// @dev internal method that executes ERC20 to ERC20 token swaps with the ability to take a fee from the input
    function _fillQuoteTokenToToken(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount
    ) internal {
        // 1 - Get the initial balance of the output token
        uint256 boughtAmount = IERC20(buyTokenAddress).balanceOf(address(this));

        // 2 - Move the tokens to this contract (which includes our fees)
        TransferHelper.safeTransferFrom(
            sellTokenAddress,
            msg.sender,
            address(this),
            sellAmount
        );

        // 3 - Approve the aggregator's contract to swap the tokens if needed
        if (
            IERC20(sellTokenAddress).allowance(address(this), swapTarget) <
            sellAmount - feeAmount
        ) {
            TransferHelper.safeApprove(
                sellTokenAddress,
                swapTarget,
                type(uint256).max
            );
        }

        // 4 - Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        // the swapCallData is passing sellAmount - feeAmount as the input
        // so we can keep the fees in this contract
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "SWAP_CALL_FAILED");

        // 5 - Send tokens to the user
        boughtAmount =
            IERC20(buyTokenAddress).balanceOf(address(this)) -
            boughtAmount;
        TransferHelper.safeTransfer(buyTokenAddress, msg.sender, boughtAmount);
    }

    /** EXTERNAL **/

    /// @param buyTokenAddress the address of token that the user should receive
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param feeAmount the amount of ETH that we will take as a fee
    function fillQuoteEthToToken(
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 feeAmount
    ) public payable nonReentrant {
        // 1 - Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees
        // minus our fees, which are kept in this contract
        (bool success, ) = swapTarget.call{value: msg.value - feeAmount}(
            swapCallData
        );
        require(success, "SWAP_CALL_FAILED");

        // 2 - Send the received tokens back to the user
        TransferHelper.safeTransfer(
            buyTokenAddress,
            msg.sender,
            IERC20(buyTokenAddress).balanceOf(address(this))
        );
    }

    /// @param sellTokenAddress the address of token that the user is selling
    /// @param buyTokenAddress the address of token that the user should receive
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feeAmount the amount of the tokens to sell that we will take as a fee
    function fillQuoteTokenToToken(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount
    ) public payable nonReentrant {
        _fillQuoteTokenToToken(
            sellTokenAddress,
            buyTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feeAmount
        );
    }

    /// @dev method that executes ERC20 to ERC20 token swaps with the ability to take a fee from the input
    // and accepts a signature to use permit, so the user doesn't have to make an previous approval transaction
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param buyTokenAddress the address of token that the user should receive
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feeAmount the amount of the tokens to sell that we will take as a fee
    /// @param permitSignature struct containing the value, nonce, deadline, v, r and s values of the permit signature
    function fillQuoteTokenToTokenWithPermit(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount,
        TransferHelper.Permit calldata permitSignature
    ) public payable nonReentrant {
        // 1 - Apply permit
        TransferHelper.permit(
            permitSignature,
            sellTokenAddress,
            msg.sender,
            address(this)
        );

        //2 - Call fillQuoteTokenToToken
        _fillQuoteTokenToToken(
            sellTokenAddress,
            buyTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feeAmount
        );
    }

    /// @dev method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feePercentageBasisPoints the amount of ETH that we will take as a fee in 10000 basis points
    function fillQuoteTokenToEth(
        address sellTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints
    ) public payable nonReentrant {
        _fillQuoteTokenToEth(
            sellTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feePercentageBasisPoints
        );
    }

    /// @dev method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    // and accepts a signature to use permit, so the user doesn't have to make an previous approval transaction
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param swapTarget the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feePercentageBasisPoints the amount of ETH that we will take as a fee in 10000 basis points
    /// @param permitSignature struct containing the amount, nonce, deadline, v, r and s values of the permit signature
    function fillQuoteTokenToEthWithPermit(
        address sellTokenAddress,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints,
        TransferHelper.Permit calldata permitSignature
    ) public payable nonReentrant {
        // 1 - Apply permit
        TransferHelper.permit(
            permitSignature,
            sellTokenAddress,
            msg.sender,
            address(this)
        );

        // 2 - call fillQuoteTokenToEth
        _fillQuoteTokenToEth(
            sellTokenAddress,
            swapTarget,
            swapCallData,
            sellAmount,
            feePercentageBasisPoints
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;
import "../interfaces/IERC2612.sol";
import "../interfaces/IDAI.sol";

/// @title TransferHelper
/// @dev Helper methods for interacting with ERC20 tokens and sending ETH
library TransferHelper {
    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    struct Permit {
        uint256 value;
        uint256 nonce;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev Approval method with revert in case of failure
    /// @param token address of the token to approve
    /// @param to address to approve
    /// @param value amount to approve
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "APPROVE_FAILED"
        );
    }

    /// @dev Transfer method with revert in case of failure
    /// @param token address of the token to transfer
    /// @param to address to receive the tokens
    /// @param value amount to transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    /// @dev TransferFrom method with revert in case of failure
    /// @param token address of the token to transfer
    /// @param from address to move the tokens from
    /// @param to address to receive the tokens
    /// @param value amount to transfer
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    /// @dev transfer eth method with revert in case of failure
    /// @param to address that will receive ETH
    /// @param value amount of ETH to transfer
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /// @dev permit method helper that will handle both known implementations
    // DAI vs ERC2612 tokens
    /// @param permitSignature bytes containing the encoded permit signature
    /// @param tokenAddress address of the token that will be permitted
    /// @param holder address that holds the tokens to be permitted
    /// @param spender address that will be permitted to spend the tokens
    function permit(
        Permit memory permitSignature,
        address tokenAddress,
        address holder,
        address spender
    ) internal {
        if (tokenAddress == DAI_ADDRESS) {
            IDAI(tokenAddress).permit(
                holder,
                spender,
                permitSignature.nonce,
                permitSignature.deadline,
                true,
                permitSignature.v,
                permitSignature.r,
                permitSignature.s
            );
        } else {
            IERC2612(tokenAddress).permit(
                holder,
                spender,
                permitSignature.value,
                permitSignature.deadline,
                permitSignature.v,
                permitSignature.r,
                permitSignature.s
            );
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;

import "./IERC20.sol";

interface IERC2612 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function _nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;

import "./IERC20.sol";

interface IDAI is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function version() external view returns (string memory);
}