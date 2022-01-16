// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

/**
 * @dev Interface of the swap function within Balancer Vault.
 */
interface IVault {

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        uint256 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

}

contract balancer_swap {

    //address of the uniswap v2 router
    address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes private constant userData = "0x";
    bool private constant fromInternalBalance = false;
    bool private constant toInternalBalance = false;

    //define structs from IVault
    IVault.SingleSwap singleSwap;
    IVault.FundManagement funds;
    uint256 limit;
    uint256 deadline;

    //define owner contract
    address payable owner;

    constructor()  {
        owner = payable(msg.sender);
    }

    function balancerSwap(
        bytes32 _poolId,
        uint256 _kind,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _limit) external {

            //Approve tokenIn with defined address
            IERC20(_tokenIn).approve(BALANCER_VAULT, _amountIn);

            singleSwap.poolId = _poolId;
            singleSwap.kind = _kind;
            singleSwap.assetIn = _tokenIn;
            singleSwap.assetOut = _tokenOut;
            singleSwap.amount = _amountIn;
            singleSwap.userData = userData;

            funds.sender = address(this);
            funds.fromInternalBalance = fromInternalBalance;
            funds.recipient = owner;
            funds.toInternalBalance = toInternalBalance;

            limit = _limit;
            // deadline = _deadline;
            deadline = block.timestamp;

            IVault(BALANCER_VAULT).swap(singleSwap, funds, limit, deadline);
        }

}