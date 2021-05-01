/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;
// Leak alpha for run and profit with https://twitter.com/mevalphaleak

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
          // Approval might be already set or can be set inside of 'operations[1]'
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
    address internal constant TOKEN_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant TOKEN_DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address internal constant PROXY_DYDX  = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address internal constant ORACLE_USDC = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
    address internal constant ORACLE_DAI  = 0x773616E4d11A78F511299002da57A0a94577F1f4;

    uint256 internal constant FLAG_TRANSFORM_ETH_TO_WETH_BEFORE_APE = 0x1;
    uint256 internal constant FLAG_TRANSFORM_WETH_TO_ETH_BEFORE_APE = 0x2;
    uint256 internal constant FLAG_TRANSFORM_ETH_TO_WETH_AFTER_APE  = 0x4;
    uint256 internal constant FLAG_TRANSFORM_WETH_TO_ETH_AFTER_APE  = 0x8;

    uint256 internal constant FLAG_FLASH_DYDY_WETH     = 0x10;
    uint256 internal constant FLAG_FLASH_DYDY_USDC     = 0x20;
    uint256 internal constant FLAG_FLASH_DYDY_DAI      = 0x40;

    uint256 internal constant FLAG_WETH_ACCOUNTING     = 0x80;
    uint256 internal constant FLAG_USDC_ACCOUNTING     = 0x100;
    uint256 internal constant FLAG_DAI_ACCOUNTING      = 0x200;


    uint256 internal constant FLAG_EXIT_WETH           = 0x400;
    uint256 internal constant FLAG_PAY_COINBASE_SHARE  = 0x800;
    uint256 internal constant FLAG_PAY_COINBASE_AMOUNT = 0x1000;


    uint256 internal constant FLAG_RETURN_WETH         = 0x2000;
    uint256 internal constant FLAG_RETURN_USDC         = 0x4000;
    uint256 internal constant FLAG_RETURN_DAI          = 0x8000;
}

contract ApeBot is DyDxFlashLoanHelper, IAlphaLeakConstants {
    string  public constant name = "https://twitter.com/mevalphaleak";

    fallback() external payable {}
    function callFunction(
        address,
        Types.AccountInfo memory,
        bytes calldata data
    ) external {
        // Added to support DyDx flash loans natively
        // Security checks aren't necessary since I'm an ape
        address(this).call(data);
    }
    function executeOperation(
        address,
        uint256,
        uint256,
        bytes calldata _params
    ) external {
        // Added to support AAVE v1 flash loans natively
        // Security checks aren't necessary since I'm an ape
        address(this).call(_params);
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
        address(this).call(params);
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
        address(this).call(data);
    }
    function uniswapV3FlashCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external {
        // Added to support uniswap v3 flash loans natively
        // Security checks aren't necessary since I'm an ape
        address(this).call(data);
    }
    function uniswapV3MintCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external {
        // Added to support uniswap v3 flash mints natively
        // Security checks aren't necessary since I'm an ape
        address(this).call(data);
    }
    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external {
        // Added to support uniswap v3 flash swaps natively
        // Security checks aren't necessary since I'm an ape
        address(this).call(data);
    }

    // All funds left on this contract will be imidiately lost to snipers
    // This function is completely permision-less and allows anyone to execute any arbitrary logic
    // Overall goal is to make a contract which allows to execute all types of nested flash loans
    function ape(uint256 actionFlags, uint256[] memory data) public payable {
        // FLAGS are used to simplify some common actions, they aren't necessary
        if ((actionFlags & (FLAG_TRANSFORM_ETH_TO_WETH_BEFORE_APE | FLAG_TRANSFORM_WETH_TO_ETH_BEFORE_APE)) > 0) {
            if ((actionFlags & FLAG_TRANSFORM_ETH_TO_WETH_BEFORE_APE) > 0) {
                uint selfbalance = address(this).balance;
                if (selfbalance > 1) WETH9(TOKEN_WETH).deposit{value: selfbalance - 1}();
            } else {
                uint wethbalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
                if (wethbalance > 1) WETH9(TOKEN_WETH).withdraw(wethbalance - 1);
            }
        }

        uint callId = 0;
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

        // FLAGS are used to simplify some common actions, they aren't necessary
        if ((actionFlags & (FLAG_TRANSFORM_ETH_TO_WETH_AFTER_APE | FLAG_TRANSFORM_WETH_TO_ETH_AFTER_APE)) > 0) {
            if ((actionFlags & FLAG_TRANSFORM_ETH_TO_WETH_AFTER_APE) > 0) {
                uint selfbalance = address(this).balance;
                if (selfbalance > 1) WETH9(TOKEN_WETH).deposit{value: selfbalance - 1}();
            } else {
                uint wethbalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
                if (wethbalance > 1) WETH9(TOKEN_WETH).withdraw(wethbalance - 1);
            }
        }
    }

    // Function signature 0x00000000
    // Should be main entry point for any simple MEV searcher
    // Though you can always use 'ape' function directly with general purpose logic
    function wfjizxua(
        uint256 actionFlags,
        uint256[] calldata actionData
    ) external payable returns(int256 ethProfitDelta) {
        int256[4] memory balanceDeltas;
        balanceDeltas[0] = int256(address(this).balance);
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
                    abi.encodeWithSignature('ape(uint256,uint256[])', actionFlags, actionData)
                );
            } else if ((actionFlags & FLAG_FLASH_DYDY_USDC) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_USDC).balanceOf(PROXY_DYDX);
                this.wrapWithDyDx(
                    TOKEN_USDC,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_USDC).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encodeWithSignature('ape(uint256,uint256[])', actionFlags, actionData)
                );
            } else if ((actionFlags & FLAG_FLASH_DYDY_DAI) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_DAI).balanceOf(PROXY_DYDX);
                this.wrapWithDyDx(
                    TOKEN_DAI,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_DAI).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encodeWithSignature('ape(uint256,uint256[])', actionFlags, actionData)
                );
            }
        } else {
            this.ape(actionFlags, actionData);
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


        if ((actionFlags & FLAG_PAY_COINBASE_AMOUNT) > 0) {
            uint selfbalance = address(this).balance;
            uint amountToPay = actionFlags / 0x100000000000000000000000000000000;
            if (selfbalance < amountToPay) {
                // Attempting to cover the gap via WETH token
                WETH9(TOKEN_WETH).withdraw(amountToPay - selfbalance);
            }
            payable(block.coinbase).transfer(amountToPay);
        } else if ((actionFlags & FLAG_PAY_COINBASE_SHARE) > 0) {
            uint selfbalance = address(this).balance;
            uint amountToPay = (actionFlags / 0x100000000000000000000000000000000) * uint256(ethProfitDelta) / (1 ether);
            if (selfbalance < amountToPay) {
                // Attempting to cover the gap via WETH token
                WETH9(TOKEN_WETH).withdraw(amountToPay - selfbalance);
            }
            payable(block.coinbase).transfer(amountToPay);
        }

        uint selfBalance = address(this).balance;
        if (selfBalance > 1) payable(msg.sender).transfer(selfBalance - 1);
        if ((actionFlags & (FLAG_RETURN_WETH | FLAG_RETURN_USDC | FLAG_RETURN_DAI)) > 0) {
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

contract ISoloMargin {
    function operate(Types.AccountInfo[] memory accounts, Types.ActionArgs[] memory actions) public {}
    function getMarketTokenAddress(uint256 marketId) public view returns (address) {}
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    string public name;
    string public symbol;
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
}

contract WETH9 {
    function deposit() public payable {}
    function withdraw(uint wad) public {}
}

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}