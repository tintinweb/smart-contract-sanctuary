/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

/// SPDX-License-Identifier: MIT
/*
▄▄█    ▄   ██   █▄▄▄▄ ▄█ 
██     █  █ █  █  ▄▀ ██ 
██ ██   █ █▄▄█ █▀▀▌  ██ 
▐█ █ █  █ █  █ █  █  ▐█ 
 ▐ █  █ █    █   █    ▐ 
   █   ██   █   ▀   
           ▀          */
/// 🦊🌾 Special thanks to Keno / Boring / Gonpachi / Karbon for review and continued inspiration.
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// @notice A library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math).
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

/// @notice Interface for depositing into and withdrawing from Aave lending pool.
interface IAaveBridge {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function deposit( 
        address asset, 
        uint256 amount, 
        address onBehalfOf, 
        uint16 referralCode
    ) external;

    function withdraw( 
        address token, 
        uint256 amount, 
        address destination
    ) external;
}

/// @notice Interface for depositing into and withdrawing from BentoBox vault.
interface IBentoBridge {
    function balanceOf(IERC20, address) external view returns (uint256);
    
    function registerProtocol() external;

    function deposit( 
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

/// @notice Interface for depositing into and withdrawing from Compound finance protocol.
interface ICompoundBridge {
    function underlying() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
}

/// @notice Interface for Dai Stablecoin (DAI) `permit()` primitive.
interface IDaiPermit {
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
}

/// @notice Interface for depositing and withdrawing assets from KASHI.
interface IKashi {
    function asset() external returns (IERC20);
    
    function addAsset(
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);
    
    function removeAsset(address to, uint256 fraction) external returns (uint256 share);
}

/// @notice Interface for depositing into and withdrawing from SushiBar.
interface ISushiBarBridge { 
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
}

/// @notice Interface for SushiSwap.
interface ISushiSwap {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
/// License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
/// License-Identifier: MIT

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
/// License-Identifier: MIT

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
    /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results) {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

/// @notice Extends `BoringBatchable` with DAI `permit()`.
contract BoringBatchableWithDai is BaseBoringBatchable {
    IDaiPermit constant dai = IDaiPermit(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI token contract
    
    /// @notice Call wrapper that performs `ERC20.permit` on `dai` using EIP 2612 primitive.
    /// Lookup `IDaiPermit.permit`.
    function permitDai(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        dai.permit(holder, spender, nonce, expiry, allowed, v, r, s);
    }
    
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

/// @notice Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
library Babylonian {
    function sqrt(uint y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/// @notice Interface for SushiSwap liquidity zaps based on awesomeness from zapper.fi (0xcff6eF0B9916682B37D80c19cFF8949bc1886bC2).
interface ISushiLiquidityZap {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function burn(address to) external returns (uint amount0, uint amount1);
       
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @notice SushiSwap liquidity zaps based on awesomeness from zapper.fi (0xcff6eF0B9916682B37D80c19cFF8949bc1886bC2).
contract Sushiswap_ZapIn_General_V3 {
    using SafeMath for uint256;
    using BoringERC20 for IERC20;
    
    address constant sushiSwapFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; // SushiSwap factory contract
    ISushiLiquidityZap constant sushiSwapRouter = ISushiLiquidityZap(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiSwap router contract
    address constant ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant pairCodeHash = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303; // SushiSwap pair code hash

    event ZapIn(address sender, address pool, uint256 tokensRec);

    /**
     @notice This function is used to invest in given SushiSwap pair through ETH/ERC20 Tokens.
     @param to Address to receive LP tokens.
     @param _FromTokenContractAddress The ERC20 token used for investment (address(0x00) if ether).
     @param _pairAddress The SushiSwap pair address.
     @param _amount The amount of fromToken to invest.
     @param _minPoolTokens Reverts if less tokens received than this.
     @param _swapTarget Excecution target for the first swap.
     @param swapData Dex quote data.
     @return Amount of LP bought.
     */
    function zapIn(
        address to,
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData
    ) external payable returns (uint256) {
        uint256 toInvest = _pullTokens(
            _FromTokenContractAddress,
            _amount
        );
        uint256 LPBought = _performZapIn(
            _FromTokenContractAddress,
            _pairAddress,
            toInvest,
            _swapTarget,
            swapData
        );
        require(LPBought >= _minPoolTokens, 'ERR: High Slippage');
        emit ZapIn(to, _pairAddress, LPBought);
        IERC20(_pairAddress).safeTransfer(to, LPBought);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress) internal pure returns (address token0, address token1)
    {
        ISushiLiquidityZap sushiPair = ISushiLiquidityZap(_pairAddress);
        token0 = sushiPair.token0();
        token1 = sushiPair.token1();
    }

    function _pullTokens(address token, uint256 amount) internal returns (uint256 value) {
        if (token == address(0)) {
            require(msg.value > 0, 'No eth sent');
            return msg.value;
        }
        require(amount > 0, 'Invalid token amount');
        require(msg.value == 0, 'Eth sent with token');
        // transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (
            address _ToSushipoolToken0,
            address _ToSushipoolToken1
        ) = _getPairTokens(_pairAddress);
        if (
            _FromTokenContractAddress != _ToSushipoolToken0 &&
            _FromTokenContractAddress != _ToSushipoolToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }
        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) = _swapIntermediate(
            intermediateToken,
            _ToSushipoolToken0,
            _ToSushipoolToken1,
            intermediateAmt
        );
        return
            _sushiDeposit(
                _ToSushipoolToken0,
                _ToSushipoolToken1,
                token0Bought,
                token1Bought
            );
    }

    function _sushiDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        IERC20(_ToUnipoolToken0).approve(address(sushiSwapRouter), 0);
        IERC20(_ToUnipoolToken1).approve(address(sushiSwapRouter), 0);
        IERC20(_ToUnipoolToken0).approve(
            address(sushiSwapRouter),
            token0Bought
        );
        IERC20(_ToUnipoolToken1).approve(
            address(sushiSwapRouter),
            token1Bought
        );
        (uint256 amountA, uint256 amountB, uint256 LP) = sushiSwapRouter
            .addLiquidity(
            _ToUnipoolToken0,
            _ToUnipoolToken1,
            token0Bought,
            token1Bought,
            1,
            1,
            address(this),
            deadline
        );
            // returning residue in token0, if any
            if (token0Bought.sub(amountA) > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought.sub(amountA)
                );
            }
            // returning residue in token1, if any
            if (token1Bought.sub(amountB) > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought.sub(amountB)
                );
            }
        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            IERC20 fromToken = IERC20(_fromTokenAddress);
            fromToken.approve(address(_swapTarget), 0);
            fromToken.approve(address(_swapTarget), _amount);
        }
        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));
        (bool success, ) = _swapTarget.call{value: valueToSend}(swapCallData);
        require(success, 'Error Swapping Tokens 1');
        uint256 finalBalance0 = token0.balanceOf(address(this)).sub(
            initialBalance0
        );
        uint256 finalBalance1 = token1.balanceOf(address(this)).sub(
            initialBalance1
        );
        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }
        require(amountBought > 0, 'Swapped to Invalid Intermediate');
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToSushipoolToken0,
        address _ToSushipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        (address token0, address token1) = _ToSushipoolToken0 < _ToSushipoolToken1 ? (_ToSushipoolToken0, _ToSushipoolToken1) : (_ToSushipoolToken1, _ToSushipoolToken0);
        ISushiSwap pair =
            ISushiSwap(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", sushiSwapFactory, keccak256(abi.encodePacked(token0, token1)), pairCodeHash))
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToSushipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            // if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _toContractAddress,
                _ToSushipoolToken1,
                amountToSwap
            );
            token0Bought = _amount.sub(amountToSwap);
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            // if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _toContractAddress,
                _ToSushipoolToken0,
                amountToSwap
            );
            token1Bought = _amount.sub(amountToSwap);
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn) internal pure returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    /**
     @notice This function is used to swap ERC20 <> ERC20.
     @param _FromTokenContractAddress The token address to swap from.
     @param _ToTokenContractAddress The token address to swap to. 
     @param tokens2Trade The amount of tokens to swap.
     @return tokenBought The quantity of tokens bought.
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }
        IERC20(_FromTokenContractAddress).approve(
            address(sushiSwapRouter),
            0
        );
        IERC20(_FromTokenContractAddress).approve(
            address(sushiSwapRouter),
            tokens2Trade
        );
        (address token0, address token1) = _FromTokenContractAddress < _ToTokenContractAddress ? (_FromTokenContractAddress, _ToTokenContractAddress) : (_ToTokenContractAddress, _FromTokenContractAddress);
        address pair =
            address(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", sushiSwapFactory, keccak256(abi.encodePacked(token0, token1)), pairCodeHash))
                )
            );
        require(pair != address(0), 'No Swap Available');
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;
        tokenBought = sushiSwapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];
        require(tokenBought > 0, 'Error Swapping Tokens 2');
    }
    
    function zapOut(
        address pair,
        address to,
        uint256 amount
    ) external returns (uint256 amount0, uint256 amount1) {
        IERC20(pair).safeTransferFrom(msg.sender, pair, amount); // pull `amount` to `pair`
        (amount0, amount1) = ISushiLiquidityZap(pair).burn(to); // trigger burn to redeem liquidity for `to`
    }
    
    function zapOutBalance(
        address pair,
        address to
    ) external returns (uint256 amount0, uint256 amount1) {
        IERC20(pair).safeTransfer(pair, IERC20(pair).balanceOf(address(this))); // transfer local balance to `pair`
        (amount0, amount1) = ISushiLiquidityZap(pair).burn(to); // trigger burn to redeem liquidity for `to`
    }
}

/// @notice Interface for SUSHI MasterChef v2.
interface IMasterChefV2 {
    function lpToken(uint256 pid) external view returns (IERC20);
    function deposit(uint256 pid, uint256 amount, address to) external;
}

/// @notice Interface for ETH wrapper contract (v9).
interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

/// @notice Contract that batches SUSHI staking and DeFi strategies - V1 'iroirona'.
contract InariV1 is BoringBatchableWithDai, Sushiswap_ZapIn_General_V3 {
    using SafeMath for uint256;
    using BoringERC20 for IERC20;
    
    address governance = msg.sender; // governance role to initialize `masterChefv2`
    IERC20 constant sushiToken = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); // SUSHI token contract
    address constant sushiBar = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272; // xSUSHI staking contract for SUSHI
    IMasterChefV2 masterChefv2; // SUSHI MasterChef v2 contract
    ISushiSwap constant sushiSwapSushiETHPair = ISushiSwap(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0); // SUSHI/ETH pair on SushiSwap
    IAaveBridge constant aave = IAaveBridge(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9); // AAVE lending pool contract for xSUSHI staking into aXSUSHI
    IERC20 constant aaveSushiToken = IERC20(0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a); // aXSUSHI staking contract for xSUSHI
    IBentoBridge constant bento = IBentoBridge(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966); // BENTO vault contract
    address constant crSushiToken = 0x338286C0BC081891A4Bda39C7667ae150bf5D206; // crSUSHI staking contract for SUSHI
    address constant crXSushiToken = 0x228619CCa194Fbe3Ebeb2f835eC1eA5080DaFbb2; // crXSUSHI staking contract for xSUSHI
    address constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // ETH wrapper contract (v9)
    
    /// @notice Initialize this Inari contract.
    constructor() public {
        bento.registerProtocol(); // register this contract with BENTO
    }

    /// @notice Helper function to approve this contract to spend tokens and enable strategies.
    function bridgeToken(IERC20[] calldata token, address[] calldata to) external {
        for (uint256 i = 0; i < token.length; i++) {
            token[i].approve(to[i], type(uint256).max); // max approve `to` spender to pull `token` from this contract
        }
    }

    /// @notice Admin function to set `masterChefv2` and burn `governance` role.
    function setMasterChefv2(IMasterChefV2 _masterChefv2) external {
        require(msg.sender == governance, '!governance');
        masterChefv2 = _masterChefv2;
        governance = address(0); // burn role
    }
    
    /**********
    ETH HELPERS 
    **********/
    receive() external payable {}
    
    function withdrawETHBalance(address to) external payable {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, '!ethCallable');
    }
    
    /***********
    WETH HELPERS 
    ***********/
    function depositBalanceToWETH(address to) external payable {
        IWETH(wETH).deposit{value: address(this).balance}();
        if (to != address(this)) IERC20(wETH).safeTransfer(to, IERC20(wETH).balanceOf(address(this)));
    }
    
    function withdrawBalanceFromWETH(address to) external {
        IWETH(wETH).withdraw(IERC20(wETH).balanceOf(address(this)));
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, '!ethCallable');
    }
    
    /**********
    TKN HELPERS 
    **********/
    function depositToken(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount); 
    }
    
    function withdrawTokenBalance(IERC20 token, address to) external {
        token.safeTransfer(to, token.balanceOf(address(this))); 
    }

    /************
    SUSHI HELPERS 
    ************/
    /// @notice Stake SUSHI local balance into xSushi for benefit of `to` by call to `sushiBar`.
    function stakeSushiBalance(address to) external {
        ISushiBarBridge(sushiBar).enter(sushiToken.balanceOf(address(this))); // stake local SUSHI into `sushiBar` xSUSHI
        IERC20(sushiBar).safeTransfer(to, IERC20(sushiBar).balanceOf(address(this))); // transfer resulting xSUSHI to `to`
    }
    
    /***********
    CHEF HELPERS 
    ***********/
    function balanceToMasterChefv2(IERC20 lpToken, uint256 pid, address to) external {
        masterChefv2.deposit(pid, lpToken.balanceOf(address(this)), to);
    }
    
    /************
    KASHI HELPERS 
    ************/
    function assetBalanceToKashi(IKashi kashiPair, address to, bool skim) external returns (uint256 fraction) {
        fraction = kashiPair.addAsset(to, skim, bento.balanceOf(kashiPair.asset(), address(this)));
    }
    
    function assetBalanceFromKashi(address kashiPair, address to) external returns (uint256 share) {
        share = IKashi(kashiPair).removeAsset(to, IERC20(kashiPair).balanceOf(address(this)));
    }
/*
██   ██       ▄   ▄███▄   
█ █  █ █       █  █▀   ▀  
█▄▄█ █▄▄█ █     █ ██▄▄    
█  █ █  █  █    █ █▄   ▄▀ 
   █    █   █  █  ▀███▀   
  █    █     █▐           
 ▀    ▀      ▐         */
    
    /***********
    AAVE HELPERS 
    ***********/
    function balanceToAave(address underlying, address to) external {
        aave.deposit(underlying, IERC20(underlying).balanceOf(address(this)), to, 0); 
    }

    function balanceFromAave(address aToken, address to) external {
        address underlying = IAaveBridge(aToken).UNDERLYING_ASSET_ADDRESS(); // sanity check for `underlying` token
        aave.withdraw(underlying, IERC20(aToken).balanceOf(address(this)), to); 
    }
    
    /**************************
    AAVE -> UNDERLYING -> BENTO 
    **************************/
    /// @notice Migrate AAVE `aToken` underlying `amount` into BENTO for benefit of `to` by batching calls to `aave` and `bento`.
    function aaveToBento(address aToken, address to, uint256 amount) external returns (uint256 amountOut, uint256 shareOut) {
        IERC20(aToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `aToken` `amount` into this contract
        address underlying = IAaveBridge(aToken).UNDERLYING_ASSET_ADDRESS(); // sanity check for `underlying` token
        aave.withdraw(underlying, amount, address(this)); // burn deposited `aToken` from `aave` into `underlying`
        (amountOut, shareOut) = bento.deposit(IERC20(underlying), address(this), to, amount, 0); // stake `underlying` into BENTO for `to`
    }

    /**************************
    BENTO -> UNDERLYING -> AAVE 
    **************************/
    /// @notice Migrate `underlying` `amount` from BENTO into AAVE for benefit of `to` by batching calls to `bento` and `aave`.
    function bentoToAave(IERC20 underlying, address to, uint256 amount) external {
        bento.withdraw(underlying, msg.sender, address(this), amount, 0); // withdraw `amount` of `underlying` from BENTO into this contract
        aave.deposit(address(underlying), amount, to, 0); // stake `underlying` into `aave` for `to`
    }
    
    /*************************
    AAVE -> UNDERLYING -> COMP 
    *************************/
    /// @notice Migrate AAVE `aToken` underlying `amount` into COMP/CREAM `cToken` for benefit of `to` by batching calls to `aave` and `cToken`.
    function aaveToCompound(address aToken, address cToken, address to, uint256 amount) external {
        IERC20(aToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `aToken` `amount` into this contract
        address underlying = IAaveBridge(aToken).UNDERLYING_ASSET_ADDRESS(); // sanity check for `underlying` token
        aave.withdraw(underlying, amount, address(this)); // burn deposited `aToken` from `aave` into `underlying`
        ICompoundBridge(cToken).mint(amount); // stake `underlying` into `cToken`
        IERC20(cToken).safeTransfer(to, IERC20(cToken).balanceOf(address(this))); // transfer resulting `cToken` to `to`
    }
    
    /*************************
    COMP -> UNDERLYING -> AAVE 
    *************************/
    /// @notice Migrate COMP/CREAM `cToken` underlying `amount` into AAVE for benefit of `to` by batching calls to `cToken` and `aave`.
    function compoundToAave(address cToken, address to, uint256 amount) external {
        IERC20(cToken).safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` `cToken` `amount` into this contract
        ICompoundBridge(cToken).redeem(amount); // burn deposited `cToken` into `underlying`
        address underlying = ICompoundBridge(cToken).underlying(); // sanity check for `underlying` token
        aave.deposit(underlying, IERC20(underlying).balanceOf(address(this)), to, 0); // stake resulting `underlying` into `aave` for `to`
    }
    
    /**********************
    SUSHI -> XSUSHI -> AAVE 
    **********************/
    /// @notice Stake SUSHI `amount` into aXSUSHI for benefit of `to` by batching calls to `sushiBar` and `aave`.
    function stakeSushiToAave(address to, uint256 amount) external { // SAAVE
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI into `sushiBar` xSUSHI
        aave.deposit(sushiBar, IERC20(sushiBar).balanceOf(address(this)), to, 0); // stake resulting xSUSHI into `aave` aXSUSHI for `to`
    }
    
    /**********************
    AAVE -> XSUSHI -> SUSHI 
    **********************/
    /// @notice Unstake aXSUSHI `amount` into SUSHI for benefit of `to` by batching calls to `aave` and `sushiBar`.
    function unstakeSushiFromAave(address to, uint256 amount) external {
        aaveSushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(sushiBar, amount, address(this)); // burn deposited aXSUSHI from `aave` into xSUSHI
        ISushiBarBridge(sushiBar).leave(amount); // burn resulting xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
/*
███   ▄███▄      ▄     ▄▄▄▄▀ ████▄ 
█  █  █▀   ▀      █ ▀▀▀ █    █   █ 
█ ▀ ▄ ██▄▄    ██   █    █    █   █ 
█  ▄▀ █▄   ▄▀ █ █  █   █     ▀████ 
███   ▀███▀   █  █ █  ▀            
              █   ██            */ 
    /// @notice Liquidity zap into BENTO.
    function zapToBento(
        address to,
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData
    ) external payable returns (uint256) {
        uint256 toInvest = _pullTokens(
            _FromTokenContractAddress,
            _amount
        );
        uint256 LPBought = _performZapIn(
            _FromTokenContractAddress,
            _pairAddress,
            toInvest,
            _swapTarget,
            swapData
        );
        require(LPBought >= _minPoolTokens, "ERR: High Slippage");
        emit ZapIn(to, _pairAddress, LPBought);
        bento.deposit(IERC20(_pairAddress), address(this), to, LPBought, 0); 
        return LPBought;
    }
    
    /// @notice Liquidity zap from BENTO.
    function zapFromBento(
        address pair,
        address to,
        uint256 amount
    ) external returns (uint256 amount0, uint256 amount1) {
        bento.withdraw(IERC20(pair), msg.sender, pair, amount, 0); // withdraw `amount` to `pair` from BENTO
        (amount0, amount1) = ISushiLiquidityZap(pair).burn(to); // trigger burn to redeem liquidity for `to`
    }
 
    /************
    BENTO HELPERS 
    ************/
    function balanceToBento(IERC20 token, address to) external payable returns (uint256 amountOut, uint256 shareOut) {
        if (address(token) == address(0)) {
            (amountOut, shareOut) = bento.deposit{value: address(this).balance}(IERC20(wETH), address(this), to, address(this).balance, 0); 
        } else {
            (amountOut, shareOut) = bento.deposit(token, address(this), to, token.balanceOf(address(this)), 0); 
        }
    }
    
    function fromBento(IERC20 token, uint256 amount) external returns (uint256 amountOut, uint256 shareOut) {
        (amountOut, shareOut) = bento.withdraw(token, msg.sender, address(this), amount, 0); 
    }
    
    function balanceFromBento(IERC20 token, address to) external returns (uint256 amountOut, uint256 shareOut) {
        (amountOut, shareOut) = bento.withdraw(token, address(this), to, bento.balanceOf(token, address(this)), 0); 
    }

    /***********************
    SUSHI -> XSUSHI -> BENTO 
    ***********************/
    /// @notice Stake SUSHI `amount` into BENTO xSUSHI for benefit of `to` by batching calls to `sushiBar` and `bento`.
    function stakeSushiToBento(address to, uint256 amount) external returns (uint256 amountOut, uint256 shareOut) {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI into `sushiBar` xSUSHI
        (amountOut, shareOut) = bento.deposit(IERC20(sushiBar), address(this), to, IERC20(sushiBar).balanceOf(address(this)), 0); // stake resulting xSUSHI into BENTO for `to`
    }
    
    /***********************
    BENTO -> XSUSHI -> SUSHI 
    ***********************/
    /// @notice Unstake xSUSHI `amount` from BENTO into SUSHI for benefit of `to` by batching calls to `bento` and `sushiBar`.
    function unstakeSushiFromBento(address to, uint256 amount) external {
        bento.withdraw(IERC20(sushiBar), msg.sender, address(this), amount, 0); // withdraw `amount` of xSUSHI from BENTO into this contract
        ISushiBarBridge(sushiBar).leave(amount); // burn withdrawn xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
/*    
▄█▄    █▄▄▄▄ ▄███▄   ██   █▀▄▀█ 
█▀ ▀▄  █  ▄▀ █▀   ▀  █ █  █ █ █ 
█   ▀  █▀▀▌  ██▄▄    █▄▄█ █ ▄ █ 
█▄  ▄▀ █  █  █▄   ▄▀ █  █ █   █ 
▀███▀    █   ▀███▀      █    █  
        ▀              █    ▀  
                      ▀      */
// - COMPOUND - //
    /***********
    COMP HELPERS 
    ***********/
    function balanceToCompound(ICompoundBridge cToken) external {
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        cToken.mint(underlying.balanceOf(address(this)));
    }

    function balanceFromCompound(address cToken) external {
        ICompoundBridge(cToken).redeem(IERC20(cToken).balanceOf(address(this)));
    }
    
    /**************************
    COMP -> UNDERLYING -> BENTO 
    **************************/
    /// @notice Migrate COMP/CREAM `cToken` `cTokenAmount` into underlying and BENTO for benefit of `to` by batching calls to `cToken` and `bento`.
    function compoundToBento(address cToken, address to, uint256 cTokenAmount) external returns (uint256 amountOut, uint256 shareOut) {
        IERC20(cToken).safeTransferFrom(msg.sender, address(this), cTokenAmount); // deposit `msg.sender` `cToken` `cTokenAmount` into this contract
        ICompoundBridge(cToken).redeem(cTokenAmount); // burn deposited `cToken` into `underlying`
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        (amountOut, shareOut) = bento.deposit(underlying, address(this), to, underlying.balanceOf(address(this)), 0); // stake resulting `underlying` into BENTO for `to`
    }
    
    /**************************
    BENTO -> UNDERLYING -> COMP 
    **************************/
    /// @notice Migrate `cToken` `underlyingAmount` from BENTO into COMP/CREAM for benefit of `to` by batching calls to `bento` and `cToken`.
    function bentoToCompound(address cToken, address to, uint256 underlyingAmount) external {
        IERC20 underlying = IERC20(ICompoundBridge(cToken).underlying()); // sanity check for `underlying` token
        bento.withdraw(underlying, msg.sender, address(this), underlyingAmount, 0); // withdraw `underlyingAmount` of `underlying` from BENTO into this contract
        ICompoundBridge(cToken).mint(underlyingAmount); // stake `underlying` into `cToken`
        IERC20(cToken).safeTransfer(to, IERC20(cToken).balanceOf(address(this))); // transfer resulting `cToken` to `to`
    }
    
    /**********************
    SUSHI -> CREAM -> BENTO 
    **********************/
    /// @notice Stake SUSHI `amount` into crSUSHI and BENTO for benefit of `to` by batching calls to `crSushiToken` and `bento`.
    function sushiToCreamToBento(address to, uint256 amount) external returns (uint256 amountOut, uint256 shareOut) {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ICompoundBridge(crSushiToken).mint(amount); // stake deposited SUSHI into crSUSHI
        (amountOut, shareOut) = bento.deposit(IERC20(crSushiToken), address(this), to, IERC20(crSushiToken).balanceOf(address(this)), 0); // stake resulting crSUSHI into BENTO for `to`
    }
    
    /**********************
    BENTO -> CREAM -> SUSHI 
    **********************/
    /// @notice Unstake crSUSHI `cTokenAmount` into SUSHI from BENTO for benefit of `to` by batching calls to `bento` and `crSushiToken`.
    function sushiFromCreamFromBento(address to, uint256 cTokenAmount) external {
        bento.withdraw(IERC20(crSushiToken), msg.sender, address(this), cTokenAmount, 0); // withdraw `cTokenAmount` of `crSushiToken` from BENTO into this contract
        ICompoundBridge(crSushiToken).redeem(cTokenAmount); // burn deposited `crSushiToken` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
    
    /***********************
    SUSHI -> XSUSHI -> CREAM 
    ***********************/
    /// @notice Stake SUSHI `amount` into crXSUSHI for benefit of `to` by batching calls to `sushiBar` and `crXSushiToken`.
    function stakeSushiToCream(address to, uint256 amount) external { // SCREAM
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        ICompoundBridge(crXSushiToken).mint(IERC20(sushiBar).balanceOf(address(this))); // stake resulting xSUSHI into crXSUSHI
        IERC20(crXSushiToken).safeTransfer(to, IERC20(crXSushiToken).balanceOf(address(this))); // transfer resulting crXSUSHI to `to`
    }
    
    /***********************
    CREAM -> XSUSHI -> SUSHI 
    ***********************/
    /// @notice Unstake crXSUSHI `cTokenAmount` into SUSHI for benefit of `to` by batching calls to `crXSushiToken` and `sushiBar`.
    function unstakeSushiFromCream(address to, uint256 cTokenAmount) external {
        IERC20(crXSushiToken).safeTransferFrom(msg.sender, address(this), cTokenAmount); // deposit `msg.sender` `crXSushiToken` `cTokenAmount` into this contract
        ICompoundBridge(crXSushiToken).redeem(cTokenAmount); // burn deposited `crXSushiToken` `cTokenAmount` into xSUSHI
        ISushiBarBridge(sushiBar).leave(IERC20(sushiBar).balanceOf(address(this))); // burn resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
    
    /********************************
    SUSHI -> XSUSHI -> CREAM -> BENTO 
    ********************************/
    /// @notice Stake SUSHI `amount` into crXSUSHI and BENTO for benefit of `to` by batching calls to `sushiBar`, `crXSushiToken` and `bento`.
    function stakeSushiToCreamToBento(address to, uint256 amount) external returns (uint256 amountOut, uint256 shareOut) {
        sushiToken.safeTransferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        ISushiBarBridge(sushiBar).enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        ICompoundBridge(crXSushiToken).mint(IERC20(sushiBar).balanceOf(address(this))); // stake resulting xSUSHI into crXSUSHI
        (amountOut, shareOut) = bento.deposit(IERC20(crXSushiToken), address(this), to, IERC20(crXSushiToken).balanceOf(address(this)), 0); // stake resulting crXSUSHI into BENTO for `to`
    }
    
    /********************************
    BENTO -> CREAM -> XSUSHI -> SUSHI 
    ********************************/
    /// @notice Unstake crXSUSHI `cTokenAmount` into SUSHI from BENTO for benefit of `to` by batching calls to `bento`, `crXSushiToken` and `sushiBar`.
    function unstakeSushiFromCreamFromBento(address to, uint256 cTokenAmount) external {
        bento.withdraw(IERC20(crXSushiToken), msg.sender, address(this), cTokenAmount, 0); // withdraw `cTokenAmount` of `crXSushiToken` from BENTO into this contract
        ICompoundBridge(crXSushiToken).redeem(cTokenAmount); // burn deposited `crXSushiToken` `cTokenAmount` into xSUSHI
        ISushiBarBridge(sushiBar).leave(IERC20(sushiBar).balanceOf(address(this))); // burn resulting xSUSHI from `sushiBar` into SUSHI
        sushiToken.safeTransfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
/*
   ▄▄▄▄▄    ▄ ▄   ██   █ ▄▄      
  █     ▀▄ █   █  █ █  █   █     
▄  ▀▀▀▀▄  █ ▄   █ █▄▄█ █▀▀▀      
 ▀▄▄▄▄▀   █  █  █ █  █ █         
           █ █ █     █  █        
            ▀ ▀     █    ▀       
                   ▀     */
    /// @notice SushiSwap ETH to stake SUSHI into xSUSHI for benefit of `to`. 
    function ethStakeSushi(address to) external payable { // SWAP `N STAKE
        (uint256 reserve0, uint256 reserve1, ) = sushiSwapSushiETHPair.getReserves();
        uint256 amountInWithFee = msg.value.mul(997);
        uint256 amountOut =
            amountInWithFee.mul(reserve0) /
            reserve1.mul(1000).add(amountInWithFee);
        IWETH(wETH).deposit{value: msg.value}();
        IERC20(wETH).safeTransfer(address(sushiSwapSushiETHPair), msg.value);
        sushiSwapSushiETHPair.swap(amountOut, 0, address(this), "");
        ISushiBarBridge(sushiBar).enter(sushiToken.balanceOf(address(this))); // stake resulting SUSHI into `sushiBar` xSUSHI
        IERC20(sushiBar).safeTransfer(to, IERC20(sushiBar).balanceOf(address(this))); // transfer resulting xSUSHI to `to`
    }
    
    /// @notice SushiSwap `fromToken` `amountIn` to `toToken` for benefit of `to`.
    function swap(address fromToken, address toToken, address to, uint256 amountIn) external returns (uint256 amountOut) {
        (address token0, address token1) = fromToken < toToken ? (fromToken, toToken) : (toToken, fromToken);
        ISushiSwap pair =
            ISushiSwap(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", sushiSwapFactory, keccak256(abi.encodePacked(token0, token1)), pairCodeHash))
                )
            );
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amountIn);
        if (toToken > fromToken) {
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, "");
        } else {
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, "");
        }
    }
    
    /// @notice SushiSwap local `fromToken` balance in this contract to `toToken` for benefit of `to`.
    function swapBalance(address fromToken, address toToken, address to) external returns (uint256 amountOut) {
        (address token0, address token1) = fromToken < toToken ? (fromToken, toToken) : (toToken, fromToken);
        ISushiSwap pair =
            ISushiSwap(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", sushiSwapFactory, keccak256(abi.encodePacked(token0, token1)), pairCodeHash))
                )
            );
        uint256 amountIn = IERC20(fromToken).balanceOf(address(this));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (toToken > fromToken) {
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, "");
        } else {
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, "");
        }
    }
}