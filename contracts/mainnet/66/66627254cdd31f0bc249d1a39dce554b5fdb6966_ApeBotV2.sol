/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity = 0.8.4;
pragma experimental ABIEncoderV2;

// Leak alpha for fun and profit with https://twitter.com/mevalphaleak

contract DyDxFlashLoanHelper {
    function marketIdFromTokenAddress(address tokenAddress) internal pure returns (uint256 resultId) {
        assembly {
            switch tokenAddress
            case 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 {
                resultId := 0
            }
            case 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 {
                resultId := 2
            }
            case 0x6B175474E89094C44Da98b954EedeAC495271d0F {
                resultId := 3
            }
            default {
                revert(0, 0)
            }
        }
    }
    function wrapWithDyDx(address requiredToken, uint256 requiredBalance, bool requiredApprove, bytes calldata data) public {
        Types.ActionArgs[] memory operations = new Types.ActionArgs[](3);
        operations[0] = Types.ActionArgs({
            actionType: Types.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: requiredBalance
            }),
            primaryMarketId: marketIdFromTokenAddress(requiredToken),
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        operations[1] = Types.ActionArgs({
            actionType: Types.ActionType.Call,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: data
        });
        operations[2] = Types.ActionArgs({
            actionType: Types.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: requiredBalance + (requiredToken == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ? 1 : 2)
            }),
            primaryMarketId: marketIdFromTokenAddress(requiredToken),
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Types.AccountInfo[] memory accountInfos = new Types.AccountInfo[](1);
        accountInfos[0] = Types.AccountInfo({
            owner: address(this),
            number: 1
        });
        if (requiredApprove) {
          // Approval might be already set or can be set inside of callback function
          IERC20Token(requiredToken).approve(
            0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e,
            0xffffffffffffffffffffffffffffffff // Max uint112
          );
        }
        ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e).operate(accountInfos, operations);
    }
}

contract IAlphaLeakConstants {
    address internal constant TOKEN_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant TOKEN_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant TOKEN_DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant TOKEN_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant TOKEN_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address internal constant PROXY_DYDX  = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address internal constant ORACLE_USDC = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
    address internal constant ORACLE_DAI  = 0x773616E4d11A78F511299002da57A0a94577F1f4;

    uint256 internal constant FLAG_FLASH_DYDY_WETH     = 0x1;
    uint256 internal constant FLAG_FLASH_DYDY_USDC     = 0x2;
    uint256 internal constant FLAG_FLASH_DYDY_DAI      = 0x4;
    uint256 internal constant FLAG_EXIT_WETH           = 0x8;

    uint256 internal constant FLAG_WETH_ACCOUNTING     = 0x10;
    uint256 internal constant FLAG_USDC_ACCOUNTING     = 0x20;
    uint256 internal constant FLAG_DAI_ACCOUNTING      = 0x40;

    uint256 internal constant FLAG_RETURN_WETH         = 0x1000;
    uint256 internal constant FLAG_RETURN_USDC         = 0x2000;
    uint256 internal constant FLAG_RETURN_DAI          = 0x4000;
    uint256 internal constant FLAG_RETURN_CUSTOM       = 0x8000;
    uint256 internal constant FLAG_RETURN_CUSTOM_SHIFT = 0x100000000000000000000;

    uint256 internal constant WRAP_FLAG_TRANSFORM_ETH_TO_WETH_AFTER_APE = 0x1;
    uint256 internal constant WRAP_FLAG_TRANSFORM_WETH_TO_ETH_AFTER_APE = 0x2;
    uint256 internal constant WRAP_FLAG_PAY_COINBASE                    = 0x4;
    uint256 internal constant WRAP_FLAG_PAY_COINBASE_BIT_SHIFT          = 0x100000000000000000000000000000000;
}

// All funds left on this contract will be immediately lost to snipers
// This contract is completely permision-less and allows anyone to execute any arbitrary logic
// Overall goal is to make a contract which allows to execute all types of nested flash loans

// Second version of apeBot which is better gas optimised and performs internal call during flash-loan callbacks
// Introduced support of apeBank(0x00000000454a11ca3a574738c0aab442b62d5d45) with smallApeCallback/largeApeCallback
contract ApeBotV2 is DyDxFlashLoanHelper, IAlphaLeakConstants {
    string  public constant name = "https://twitter.com/mevalphaleak";

    fallback() external payable {}

    function smallApeCallback(bytes calldata data) external payable {
        // Added to support apeBank(0x00000000454a11ca3a574738c0aab442b62d5d45) flash loans natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
    }
    function largeApeCallback(
        address sender,
        uint wethToReturn,
        uint wbtcToReturn,
        uint daiToReturn,
        uint usdcToReturn,
        uint usdtToReturn,
        bytes calldata data
    ) external payable {
        // Added to support apeBank(0x00000000454a11ca3a574738c0aab442b62d5d45) flash loans natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
        
        // Since largeApeCallback function was used, bot operator is too lazy to return funds using generalised logic
        uint256 selfBalance = address(this).balance;
        if (selfBalance > 1) {
            payable(msg.sender).transfer(
                selfBalance == msg.value ? selfBalance : selfBalance - 1
            );
        }
        if (wethToReturn > 0) {
            uint256 tokenBalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
            if (tokenBalance > 1) {
                IERC20Token(TOKEN_WETH).transfer(
                    msg.sender,
                    tokenBalance == wethToReturn ? tokenBalance : tokenBalance - 1
                );
            }
        }
        if (wbtcToReturn > 0) {
            uint256 tokenBalance = IERC20Token(TOKEN_WBTC).balanceOf(address(this));
            if (tokenBalance > 1) {
                IERC20Token(TOKEN_WBTC).transfer(
                    msg.sender,
                    tokenBalance == wbtcToReturn ? tokenBalance : tokenBalance - 1
                );
            }
        }
        if (daiToReturn > 0) {
            uint256 tokenBalance = IERC20Token(TOKEN_DAI).balanceOf(address(this));
            if (tokenBalance > 1) {
                IERC20Token(TOKEN_DAI).transfer(
                    msg.sender,
                    tokenBalance == daiToReturn ? tokenBalance : tokenBalance - 1
                );
            }
        }
        if (usdcToReturn > 0) {
            uint256 tokenBalance = IERC20Token(TOKEN_USDC).balanceOf(address(this));
            if (tokenBalance > 1) {
                IERC20Token(TOKEN_USDC).transfer(
                    msg.sender,
                    tokenBalance == usdcToReturn ? tokenBalance : tokenBalance - 1
                );
            }
        }
        if (usdtToReturn > 0) {
            uint256 tokenBalance = IERC20Token(TOKEN_USDT).balanceOf(address(this));
            if (tokenBalance > 1) {
                IERC20Token(TOKEN_USDT).transfer(
                    msg.sender,
                    tokenBalance == usdtToReturn ? tokenBalance : tokenBalance - 1
                );
            }
        }
    }

    function callFunction(
        address,
        Types.AccountInfo memory,
        bytes calldata data
    ) external {
        // Added to support DyDx flash loans natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
    }
    function executeOperation(
        address,
        uint256,
        uint256,
        bytes calldata _params
    ) external {
        // Added to support AAVE v1 flash loans natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(_params,(uint256[])));
    }
    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        address,
        bytes calldata params
    )
        external
        returns (bool)
    {
        // Added to support AAVE v2 flash loans natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(params,(uint256[])));
        return true;
    }

    function uniswapV2Call(
        address,
        uint,
        uint,
        bytes calldata data
    ) external {
        // Added to support uniswap v2 flash swaps natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
    }
    function uniswapV3FlashCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external {
        // Added to support uniswap v3 flash loans natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
    }
    function uniswapV3MintCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external {
        // Added to support uniswap v3 flash mints natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
    }
    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external {
        // Added to support uniswap v3 flash swaps natively
        // Security checks aren't necessary since I'm an ape
        apeWrap(abi.decode(data,(uint256[])));
    }


    // Function signature 0x00000000
    // Was main entry point for v1 bot: https://etherscan.io/address/0x666f80a198412bcb987c430831b57ad61facb666#code
    // Still keeping to make backend migration to the newer version easier for me
    function wfjizxua(
        uint256 actionFlags,
        uint256[] calldata actionData
    ) public payable returns(int256 ethProfitDelta) {
        int256[4] memory balanceDeltas;
        balanceDeltas[0] = int256(address(this).balance - msg.value);
        if ((actionFlags & (FLAG_WETH_ACCOUNTING | FLAG_USDC_ACCOUNTING | FLAG_DAI_ACCOUNTING)) > 0) {
            // In general ACCOUNTING flags should be used only during simulation and not production to avoid wasting gas on oracle calls
            if ((actionFlags & FLAG_WETH_ACCOUNTING) > 0) {
                balanceDeltas[1] = int256(IERC20Token(TOKEN_WETH).balanceOf(address(this)));
            }
            if ((actionFlags & FLAG_USDC_ACCOUNTING) > 0) {
                balanceDeltas[2] = int256(IERC20Token(TOKEN_USDC).balanceOf(address(this)));
            }
            if ((actionFlags & FLAG_DAI_ACCOUNTING) > 0) {
                balanceDeltas[3] = int256(IERC20Token(TOKEN_DAI).balanceOf(address(this)));
            }
        }

        if ((actionFlags & (FLAG_FLASH_DYDY_WETH | FLAG_FLASH_DYDY_USDC | FLAG_FLASH_DYDY_DAI)) > 0) {
            // This simple logic only supports single token flashloans
            // For multiple tokens or multiple providers you should use general purpose logic using 'ape' function
            if ((actionFlags & FLAG_FLASH_DYDY_WETH) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_WETH).balanceOf(PROXY_DYDX);
                this.wrapWithDyDx(
                    TOKEN_WETH,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_WETH).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encode(actionData)
                );
            } else if ((actionFlags & FLAG_FLASH_DYDY_USDC) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_USDC).balanceOf(PROXY_DYDX);
                this.wrapWithDyDx(
                    TOKEN_USDC,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_USDC).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encode(actionData)
                );
            } else if ((actionFlags & FLAG_FLASH_DYDY_DAI) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_DAI).balanceOf(PROXY_DYDX);
                this.wrapWithDyDx(
                    TOKEN_DAI,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_DAI).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encode(actionData)
                );
            }
        } else {
            apeWrap(actionData);
        }

        if ((actionFlags & FLAG_EXIT_WETH) > 0) {
            uint wethbalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
            if (wethbalance > 1) WETH9(TOKEN_WETH).withdraw(wethbalance - 1);
        }

        ethProfitDelta = int256(address(this).balance) - balanceDeltas[0];
        if ((actionFlags & (FLAG_WETH_ACCOUNTING | FLAG_USDC_ACCOUNTING | FLAG_DAI_ACCOUNTING)) > 0) {
            if ((actionFlags & FLAG_WETH_ACCOUNTING) > 0) {
                ethProfitDelta += int256(IERC20Token(TOKEN_WETH).balanceOf(address(this))) - balanceDeltas[1];
            }
            if ((actionFlags & FLAG_USDC_ACCOUNTING) > 0) {
                ethProfitDelta += (int256(IERC20Token(TOKEN_USDC).balanceOf(address(this))) - balanceDeltas[2]) * IChainlinkAggregator(ORACLE_USDC).latestAnswer() / (1 ether);
            }
            if ((actionFlags & FLAG_DAI_ACCOUNTING) > 0) {
                ethProfitDelta += (int256(IERC20Token(TOKEN_DAI).balanceOf(address(this))) - balanceDeltas[3]) * IChainlinkAggregator(ORACLE_DAI).latestAnswer() / (1 ether);
            }
        }


        uint selfBalance = address(this).balance;
        if (selfBalance > 1) payable(msg.sender).transfer(selfBalance - 1);
        if ((actionFlags & (FLAG_RETURN_WETH | FLAG_RETURN_USDC | FLAG_RETURN_DAI | FLAG_RETURN_CUSTOM)) > 0) {
            // Majority of simple atomic arbs should just need ETH
            if ((actionFlags & FLAG_RETURN_WETH) > 0) {
                uint tokenBalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(TOKEN_WETH).transfer(msg.sender, tokenBalance - 1);
            }
            if ((actionFlags & FLAG_RETURN_USDC) > 0) {
                uint tokenBalance = IERC20Token(TOKEN_USDC).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(TOKEN_USDC).transfer(msg.sender, tokenBalance - 1);
            }
            if ((actionFlags & FLAG_RETURN_DAI) > 0) {
                uint tokenBalance = IERC20Token(TOKEN_DAI).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(TOKEN_DAI).transfer(msg.sender, tokenBalance - 1);
            }
            if ((actionFlags & FLAG_RETURN_CUSTOM) > 0) {
                address tokenAddr = address(uint160(actionFlags / FLAG_RETURN_CUSTOM_SHIFT));
                uint tokenBalance = IERC20Token(tokenAddr).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(tokenAddr).transfer(msg.sender, tokenBalance - 1);
            }
        }
    }
    
    // Function signature 0x0000000f
    // public payable version of apeWrap
    function eldddhzr(
        uint256[] calldata actionData
    ) public payable {
        apeWrap(actionData);
    }

    function apeWrap(uint256[] memory actionData) internal {
        ape(actionData);
        
        if ((actionData[0] & (WRAP_FLAG_TRANSFORM_ETH_TO_WETH_AFTER_APE | WRAP_FLAG_TRANSFORM_WETH_TO_ETH_AFTER_APE | WRAP_FLAG_PAY_COINBASE)) > 0) {
            uint256 wrapFlags = actionData[0];
            if ((wrapFlags & WRAP_FLAG_TRANSFORM_WETH_TO_ETH_AFTER_APE) > 0) {
                uint wethbalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
                if (wethbalance > 1) WETH9(TOKEN_WETH).withdraw(wethbalance - 1);
                if ((wrapFlags & WRAP_FLAG_PAY_COINBASE) > 0) {
                    block.coinbase.transfer(wrapFlags / WRAP_FLAG_PAY_COINBASE_BIT_SHIFT);
                }
            } else {
                uint selfBalance = address(this).balance;
                if ((wrapFlags & WRAP_FLAG_PAY_COINBASE) > 0) {
                    uint amountToPay = wrapFlags / WRAP_FLAG_PAY_COINBASE_BIT_SHIFT;
                    if (selfBalance < amountToPay) {
                        WETH9(TOKEN_WETH).withdraw(amountToPay - selfBalance);
                        selfBalance = 0;
                    } else {
                        selfBalance -= amountToPay;
                    }
                    block.coinbase.transfer(amountToPay);
                }
                if (((wrapFlags & WRAP_FLAG_TRANSFORM_ETH_TO_WETH_AFTER_APE) > 0) && selfBalance > 1) {
                    WETH9(TOKEN_WETH).deposit{value: selfBalance - 1}();
                }
            }
        }
    }

    function ape(uint256[] memory data) internal {
        // data[0] was used for wrapFlags inside apeWrap function
        uint callId = 1;
        for (; callId < data.length;) {
            assembly {
                let callInfo := mload(add(data, mul(add(callId, 1), 0x20)))
                let callLength := and(div(callInfo, 0x1000000000000000000000000000000000000000000000000000000), 0xffff)
                let p := mload(0x40)   // Find empty storage location using "free memory pointer"
                // Place signature at begining of empty storage, hacky logic to compute shift here
                let callSignDataShiftResult := mul(and(callInfo, 0xffffffff0000000000000000000000000000000000000000000000), 0x10000000000)
                switch callSignDataShiftResult
                case 0 {
                    callLength := mul(callLength, 0x20)
                    callSignDataShiftResult := add(data, mul(0x20, add(callId, 3)))
                    for { let i := 0 } lt(i, callLength) { i := add(i, 0x20) } {
                        mstore(add(p, i), mload(add(callSignDataShiftResult, i)))
                    }
                }
                default {
                    mstore(p, callSignDataShiftResult)
                    callLength := add(mul(callLength, 0x20), 4)
                    callSignDataShiftResult := add(data, sub(mul(0x20, add(callId, 3)), 4))
                    for { let i := 4 } lt(i, callLength) { i := add(i, 0x20) } {
                        mstore(add(p, i), mload(add(callSignDataShiftResult, i)))
                    }
                }

                mstore(0x40, add(p, add(callLength, 0x20)))
                // new free pointer position after the output values of the called function.

                let callContract := and(callInfo, 0xffffffffffffffffffffffffffffffffffffffff)
                // Re-use callSignDataShiftResult as success
                switch and(callInfo, 0xf000000000000000000000000000000000000000000000000000000000000000)
                case 0x1000000000000000000000000000000000000000000000000000000000000000 {
                    callSignDataShiftResult := delegatecall(
                                    and(div(callInfo, 0x10000000000000000000000000000000000000000), 0xffffff), // allowed gas to use
                                    callContract, // contract to execute
                                    p,    // Inputs are at location p
                                    callLength, //Inputs size
                                    p,    //Store output over input
                                    0x20) //Output is 32 bytes long
                }
                default {
                    callSignDataShiftResult := call(
                                    and(div(callInfo, 0x10000000000000000000000000000000000000000), 0xffffff), // allowed gas to use
                                    callContract, // contract to execute
                                    mload(add(data, mul(add(callId, 2), 0x20))), // wei value amount
                                    p,    // Inputs are at location p
                                    callLength, //Inputs size
                                    p,    //Store output over input
                                    0x20) //Output is 32 bytes long
                }

                callSignDataShiftResult := and(div(callInfo, 0x10000000000000000000000000000000000000000000000000000000000), 0xff)
                if gt(callSignDataShiftResult, 0) {
                    // We're copying call result as input to some futher call
                    mstore(add(data, mul(callSignDataShiftResult, 0x20)), mload(p))
                }
                callId := add(callId, add(and(div(callInfo, 0x1000000000000000000000000000000000000000000000000000000), 0xffff), 2))
                mstore(0x40, p) // Set storage pointer to empty space
            }
        }
    }
}

library Types {
    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}

interface ISoloMargin {
    function operate(Types.AccountInfo[] memory accounts, Types.ActionArgs[] memory actions) external;
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
}
interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}
interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
interface IGasToken {
    function free(uint256 value) external returns (uint256);
}
interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}