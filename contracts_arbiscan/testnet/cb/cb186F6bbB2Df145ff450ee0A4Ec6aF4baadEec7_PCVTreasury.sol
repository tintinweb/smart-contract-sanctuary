pragma solidity ^0.8.0;

import "./interfaces/IPCVTreasury.sol";
import "./interfaces/IPCVPolicy.sol";
import "../core/interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";
import "../utils/Ownable.sol";

///@notice PCVTreasury contract manager all PCV(Protocol Controlled Value) assets
///@dev apeXToken for bonding is need to be transferred into this contract before bonding really setup
contract PCVTreasury is IPCVTreasury, Ownable {
    address public immutable override apeXToken;
    mapping(address => bool) public override isLiquidityToken;
    mapping(address => bool) public override isBondPool;

    constructor(address apeXToken_) {
        owner = msg.sender;
        apeXToken = apeXToken_;
    }

    function addLiquidityToken(address lpToken) external override onlyOwner {
        require(lpToken != address(0), "PCVTreasury.addLiquidityToken: ZERO_ADDRESS");
        require(!isLiquidityToken[lpToken], "PCVTreasury.addLiquidityToken: ALREADY_ADDED");
        isLiquidityToken[lpToken] = true;
        emit NewLiquidityToken(lpToken);
    }

    function addBondPool(address pool) external override onlyOwner {
        require(pool != address(0), "PCVTreasury.addBondPool: ZERO_ADDRESS");
        require(!isBondPool[pool], "PCVTreasury.addBondPool: ALREADY_ADDED");
        isBondPool[pool] = true;
        emit NewBondPool(pool);
    }

    function deposit(
        address lpToken,
        uint256 amountIn,
        uint256 payout
    ) external override {
        require(isBondPool[msg.sender], "PCVTreasury.deposit: FORBIDDEN");
        require(isLiquidityToken[lpToken], "PCVTreasury.deposit: NOT_LIQUIDITY_TOKEN");
        require(amountIn > 0, "PCVTreasury.deposit: ZERO_AMOUNT_IN");
        require(payout > 0, "PCVTreasury.deposit: ZERO_PAYOUT");
        uint256 apeXBalance = IERC20(apeXToken).balanceOf(address(this));
        require(payout <= apeXBalance, "PCVTreasury.deposit: NOT_ENOUGH_APEX");
        TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), amountIn);
        TransferHelper.safeTransfer(apeXToken, msg.sender, payout);
        emit Deposit(msg.sender, lpToken, amountIn, payout);
    }

    /// @notice Call this function can withdraw specified lp token to a policy contract
    /// @param lpToken The lp token address want to be withdraw
    /// @param policy The policy contract address to receive the lp token
    /// @param amount Withdraw amount of lp token
    /// @param data Other data want to send to the policy
    function withdraw(
        address lpToken,
        address policy,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner {
        require(isLiquidityToken[lpToken], "PCVTreasury.deposit: NOT_LIQUIDITY_TOKEN");
        require(policy != address(0), "PCVTreasury.deposit: ZERO_ADDRESS");
        require(amount > 0, "PCVTreasury.deposit: ZERO_AMOUNT");
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        require(amount <= balance, "PCVTreasury.deposit: NOT_ENOUGH_BALANCE");
        TransferHelper.safeTransfer(lpToken, policy, amount);
        IPCVPolicy(policy).execute(lpToken, amount, data);
        emit Withdraw(lpToken, policy, amount);
    }

    /// @notice left apeXToken in this contract can be granted out by owner
    /// @param to the address receive the apeXToken
    /// @param amount the amount want to be granted
    function grantApeX(address to, uint256 amount) external override onlyOwner {
        require(to != address(0), "PCVTreasury.grantApeX: ZERO_ADDRESS");
        require(amount > 0, "PCVTreasury.grantApeX: ZERO_AMOUNT");
        uint256 balance = IERC20(apeXToken).balanceOf(address(this));
        require(amount <= balance, "PCVTreasury.grantApeX: NOT_ENOUGH_BALANCE");
        TransferHelper.safeTransfer(apeXToken, to, amount);
        emit ApeXGranted(to, amount);
    }
}

pragma solidity ^0.8.0;

interface IPCVTreasury {
    event NewLiquidityToken(address indexed lpToken);
    event NewBondPool(address indexed pool);
    event Deposit(address indexed pool, address indexed lpToken, uint256 amountIn, uint256 payout);
    event Withdraw(address indexed lpToken, address indexed policy, uint256 amount);
    event ApeXGranted(address indexed to, uint256 amount);

    function apeXToken() external view returns (address);

    function isLiquidityToken(address) external view returns (bool);

    function isBondPool(address) external view returns (bool);

    function addLiquidityToken(address lpToken) external;

    function addBondPool(address pool) external;

    function deposit(
        address lpToken,
        uint256 amountIn,
        uint256 payout
    ) external;

    function withdraw(
        address lpToken,
        address policy,
        uint256 amount,
        bytes calldata data
    ) external;

    function grantApeX(address to, uint256 amount) external;
}

pragma solidity ^0.8.0;

interface IPCVPolicy {
    function execute(address lpToken, uint256 amount, bytes calldata data) external;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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
            "TransferHelper::safeApprove: approve failed"
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
            "TransferHelper::safeTransfer: transfer failed"
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
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}