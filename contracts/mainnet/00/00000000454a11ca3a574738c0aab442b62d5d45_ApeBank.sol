/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;
// Leak alpha with https://twitter.com/mevalphaleak

// All existing flash-loan providers have at least one of the following downsides
// - Taking excessive fee for the service
// - Hard to loan multiple assets at once
// - Horribly inefficient in terms of gas:
//  - Emitting pointless events
//  - Creating useless additional transfers
//  - No SLOAD/SSTORE optimisation past EIP-2929

// ApeBank is introduced to make most gas efficient flash-loans available to everyone completely for free
// Combined with native gas refunds without any additional sstore operations

// ApeBank doesnt use safeMath and cuts corners everywhere, it isn't suitable for flash-mintable tokens
// Contract wasnt audited by anyone and there's no benefit for depositing tokens into this contract and no APY
// Anyone with half-working brain should think twice before putting anything into this contract
contract ApeBank {
    string  public   constant name = "https://twitter.com/mevalphaleak";
    address internal constant TOKEN_ETH  = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant TOKEN_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant TOKEN_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant TOKEN_DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant TOKEN_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant TOKEN_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 internal constant TOKEN_WETH_MULTIPLIER = 10 ** 14; // 0.4$ at the time of contract creation
    uint256 internal constant TOKEN_WBTC_MULTIPLIER = 10 ** 3;  // 0.5$ at the time of contract creation
    uint256 internal constant TOKEN_DAI_MULTIPLIER  = 10 ** 18;
    uint256 internal constant TOKEN_USDC_MULTIPLIER = 10 ** 6;
    uint256 internal constant TOKEN_USDT_MULTIPLIER = 10 ** 6;

    uint256 internal constant FLAG_BORROW_ETH  = 0x1;
    uint256 internal constant FLAG_BORROW_WETH = 0x2;
    uint256 internal constant FLAG_BORROW_WBTC = 0x4;
    uint256 internal constant FLAG_BORROW_DAI  = 0x8;
    uint256 internal constant FLAG_BORROW_USDC = 0x10;
    uint256 internal constant FLAG_BORROW_USDT = 0x20;
    uint256 internal constant FLAG_COVER_WETH  = 0x40;

    uint256 internal constant FLAG_BURN_NATIVE = 0x80;
    uint256 internal constant FLAG_BURN_GST2   = 0x100;
    uint256 internal constant FLAG_BURN_CHI    = 0x200;

    uint256 internal constant FLAG_SMALL_CALLBACK = 0x400;
    uint256 internal constant FLAG_LARGE_CALLBACK = 0x800;

    uint256 internal constant FLAG_FREE_GAS_TOKEN               = 0x1000;
    uint256 internal constant FLAG_GAS_TOKEN_BURN_AMOUNT_SHIFT  = 0x1000000000000000000000000000000000000000000000000000000000000;

    Types.BankState public state;
    Types.GasTokenPrices public gasTokenBurnPrices;

    // Total amount of tokens deposited into ApeBank, this value can be lower than balances in 'state'
    mapping (address => uint256) public totalDeposits;
    mapping (address => uint256) public userEthBalances;
    mapping (address => Types.BankState) public userTokenBalances;
    // Our hall of fame which allows to use gas tokens for free
    mapping (address => bool) public bestApeOperators;
    
    // Used to collect excess balances and acquire gas tokens
    address public treasury;
    address public pendingTresury;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event SkimmedBalance(address indexed treasury, address indexed token, uint256 amount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    constructor () {
        treasury = msg.sender;
        pendingTresury = 0x0000000000000000000000000000000000000000;
        emit TreasuryUpdated(pendingTresury, treasury);
    }
    function nominateTreasury(address nomination) external {
        require(msg.sender == treasury);
        pendingTresury = nomination;
    }
    function acceptNomination() external {
        require(msg.sender == pendingTresury);
        emit TreasuryUpdated(treasury, pendingTresury);
        treasury = pendingTresury;
        pendingTresury = 0x0000000000000000000000000000000000000000;
    }
    function updateGasTokenPrices(uint80 priceGST2, uint80 priceCHI, uint80 priceNative) external {
        require(msg.sender == treasury);
        Types.GasTokenPrices memory cachedPrices;
        cachedPrices.priceGST2 = priceGST2;
        cachedPrices.priceCHI = priceCHI;
        cachedPrices.priceNative = priceNative;
        gasTokenBurnPrices = cachedPrices;
    }
    function promoteToFreeGasTokens(address apeOperator) external {
        require(msg.sender == treasury);
        bestApeOperators[apeOperator] = true;
    }
    
    fallback() external payable {}

    // Logic to skim excess balances into treasury to acquire more gas tokens
    function skimExcessBalances(address token) external {
        require(msg.sender == treasury);
        uint256 minBalanceToKeep = totalDeposits[token] + 1;

        Types.BankState memory cachedBankState = state;
        uint256 availableBalance;
        if (token == TOKEN_ETH) {
            availableBalance = address(this).balance;
            require(availableBalance > minBalanceToKeep);
            TransferHelper.safeTransferETH(
                msg.sender,
                availableBalance - minBalanceToKeep
            );
            // ETH balances aren't saved in state
        } else {
            availableBalance = IERC20Token(token).balanceOf(address(this));
            require(availableBalance > minBalanceToKeep);
            TransferHelper.safeTransfer(
                token,
                msg.sender,
                availableBalance - minBalanceToKeep
            );

            if (token == TOKEN_WETH) {
                cachedBankState.wethBalance = uint32(minBalanceToKeep / TOKEN_WETH_MULTIPLIER);
            } else if (token == TOKEN_WBTC) {
                cachedBankState.wbtcBalance = uint32(minBalanceToKeep / TOKEN_WBTC_MULTIPLIER);
            } else if (token == TOKEN_DAI) {
                cachedBankState.daiBalance  = uint32(minBalanceToKeep / TOKEN_DAI_MULTIPLIER );
            } else if (token == TOKEN_USDC) {
                cachedBankState.usdcBalance = uint32(minBalanceToKeep / TOKEN_USDC_MULTIPLIER);
            } else if (token == TOKEN_USDT) {
                cachedBankState.usdtBalance = uint32(minBalanceToKeep / TOKEN_USDT_MULTIPLIER);
            }
        }

        require(cachedBankState.numCalls == state.numCalls);
        cachedBankState.numCalls += 1;
        state = cachedBankState;
        emit SkimmedBalance(msg.sender, token, availableBalance - minBalanceToKeep);
    }

    function deposit(address token, uint256 amount) external payable {
        Types.BankState memory cachedBankState = state;
        if (msg.value > 0) {
            require(token == TOKEN_ETH && msg.value == amount, "Incorrect deposit amount");
            userEthBalances[msg.sender] += msg.value;
        } else {
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                amount
            );            
            if (token == TOKEN_WETH) {
                require(amount % TOKEN_WETH_MULTIPLIER == 0, "Incorrect deposit amount");
                uint256 newBalance = cachedBankState.wethBalance + (amount / TOKEN_WETH_MULTIPLIER);
                require(newBalance < (2 ** 32), "Bank size is excessive");
                cachedBankState.wethBalance = uint32(newBalance);
                userTokenBalances[msg.sender].wethBalance += uint32(amount / TOKEN_WETH_MULTIPLIER);
            } else if (token == TOKEN_WBTC) {
                require(amount % TOKEN_WBTC_MULTIPLIER == 0, "Incorrect deposit amount");
                uint256 newBalance = cachedBankState.wbtcBalance + (amount / TOKEN_WBTC_MULTIPLIER);
                require(newBalance < (2 ** 32), "Bank size is excessive");
                cachedBankState.wbtcBalance = uint32(newBalance);
                userTokenBalances[msg.sender].wbtcBalance += uint32(amount / TOKEN_WBTC_MULTIPLIER);
            } else if (token == TOKEN_DAI) {
                require(amount % TOKEN_DAI_MULTIPLIER == 0, "Incorrect deposit amount");
                uint256 newBalance = cachedBankState.daiBalance + (amount / TOKEN_DAI_MULTIPLIER);
                require(newBalance < (2 ** 32), "Bank size is excessive");
                cachedBankState.daiBalance = uint32(newBalance);
                userTokenBalances[msg.sender].daiBalance += uint32(amount / TOKEN_DAI_MULTIPLIER);
            } else if (token == TOKEN_USDC) {
                require(amount % TOKEN_USDC_MULTIPLIER == 0, "Incorrect deposit amount");
                uint256 newBalance = cachedBankState.usdcBalance + (amount / TOKEN_USDC_MULTIPLIER);
                require(newBalance < (2 ** 32), "Bank size is excessive");
                cachedBankState.usdcBalance = uint32(newBalance);
                userTokenBalances[msg.sender].usdcBalance += uint32(amount / TOKEN_USDC_MULTIPLIER);
            } else {
                require(token == TOKEN_USDT, "Token not supported");
                require(amount % TOKEN_USDT_MULTIPLIER == 0, "Incorrect deposit amount");
                uint256 newBalance = cachedBankState.usdtBalance + (amount / TOKEN_USDT_MULTIPLIER);
                require(newBalance < (2 ** 32), "Bank size is excessive");
                cachedBankState.usdtBalance = uint32(newBalance);
                userTokenBalances[msg.sender].usdtBalance += uint32(amount / TOKEN_USDT_MULTIPLIER);
            }
        }
        totalDeposits[token] += amount;
        
        require(cachedBankState.numCalls == state.numCalls);
        cachedBankState.numCalls += 1;
        state = cachedBankState;
        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        Types.BankState memory cachedBankState = state;
        
        totalDeposits[token] -= amount;
        if (token == TOKEN_ETH) {
            require(userEthBalances[msg.sender] >= amount);
            userEthBalances[msg.sender] -= amount;
            // ETH balances aren't saved into state
            TransferHelper.safeTransferETH(
                msg.sender,
                amount
            );
        } else {
            if (token == TOKEN_WETH) {
                require(amount % TOKEN_WETH_MULTIPLIER == 0, "Incorrect withdraw amount");
                uint256 amountDelta = amount / TOKEN_WETH_MULTIPLIER;
                require(uint256(userTokenBalances[msg.sender].wethBalance) >= amountDelta);
                userTokenBalances[msg.sender].wethBalance -= uint32(amountDelta);
                cachedBankState.wethBalance -= uint32(amountDelta);
            } else if (token == TOKEN_WBTC) {
                require(amount % TOKEN_WBTC_MULTIPLIER == 0, "Incorrect withdraw amount");
                uint256 amountDelta = amount / TOKEN_WBTC_MULTIPLIER;
                require(uint256(userTokenBalances[msg.sender].wbtcBalance) >= amountDelta);
                userTokenBalances[msg.sender].wbtcBalance -= uint32(amountDelta);
                cachedBankState.wbtcBalance -= uint32(amountDelta);
            } else if (token == TOKEN_DAI) {
                require(amount % TOKEN_DAI_MULTIPLIER == 0, "Incorrect withdraw amount");
                uint256 amountDelta = amount / TOKEN_DAI_MULTIPLIER;
                require(uint256(userTokenBalances[msg.sender].daiBalance) >= amountDelta);
                userTokenBalances[msg.sender].daiBalance -= uint32(amountDelta);
                cachedBankState.daiBalance -= uint32(amountDelta);
            } else if (token == TOKEN_USDC) {
                require(amount % TOKEN_USDC_MULTIPLIER == 0, "Incorrect withdraw amount");
                uint256 amountDelta = amount / TOKEN_USDC_MULTIPLIER;
                require(uint256(userTokenBalances[msg.sender].usdcBalance) >= amountDelta);
                userTokenBalances[msg.sender].usdcBalance -= uint32(amountDelta);
                cachedBankState.usdcBalance -= uint32(amountDelta);
            } else {
                require(token == TOKEN_USDT, "Token not supported");
                require(amount % TOKEN_USDT_MULTIPLIER == 0, "Incorrect withdraw amount");
                uint256 amountDelta = amount / TOKEN_USDT_MULTIPLIER;
                require(uint256(userTokenBalances[msg.sender].usdtBalance) >= amountDelta);
                userTokenBalances[msg.sender].usdtBalance -= uint32(amountDelta);
                cachedBankState.usdtBalance -= uint32(amountDelta);
            }
            TransferHelper.safeTransfer(
                token,
                msg.sender,
                amount
            );        
        }
        
        require(cachedBankState.numCalls == state.numCalls);
        cachedBankState.numCalls += 1;
        state = cachedBankState;
        emit Withdrawal(msg.sender, token, amount);
    }
    
    function flashApe(address payable callTo, uint256 flags, bytes calldata params) external payable {
        Types.BankState memory cachedBankState = state;

        if ((flags & FLAG_BORROW_WETH) > 0) {
            TransferHelper.safeTransfer(
                TOKEN_WETH,
                callTo,
                uint256(cachedBankState.wethBalance) * TOKEN_WETH_MULTIPLIER
            );
        }
        if ((flags & (FLAG_BORROW_WBTC | FLAG_BORROW_DAI | FLAG_BORROW_USDC | FLAG_BORROW_USDT)) > 0) {
            if ((flags & FLAG_BORROW_WBTC) > 0) {
                TransferHelper.safeTransfer(
                    TOKEN_WBTC,
                    callTo,
                    uint256(cachedBankState.wbtcBalance) * TOKEN_WBTC_MULTIPLIER
                );
            }
            if ((flags & FLAG_BORROW_DAI) > 0) {
                TransferHelper.safeTransfer(
                    TOKEN_DAI,
                    callTo,
                    uint256(cachedBankState.daiBalance) * TOKEN_DAI_MULTIPLIER
                );
            }
            if ((flags & FLAG_BORROW_USDC) > 0) {
                TransferHelper.safeTransfer(
                    TOKEN_USDC,
                    callTo,
                    uint256(cachedBankState.usdcBalance) * TOKEN_USDC_MULTIPLIER
                );
            }
            if ((flags & FLAG_BORROW_USDT) > 0) {
                TransferHelper.safeTransfer(
                    TOKEN_USDT,
                    callTo,
                    uint256(cachedBankState.usdtBalance) * TOKEN_USDT_MULTIPLIER
                );
            }
        }
        uint256 oldSelfBalance = address(this).balance;

        // For "ease" of integration allowing several different callback options
        if ((flags & (FLAG_SMALL_CALLBACK | FLAG_LARGE_CALLBACK)) > 0) {
            // Native payable callbacks
            if ((flags & FLAG_SMALL_CALLBACK) > 0) {
                IApeBot(callTo).smallApeCallback{value: ((flags & FLAG_BORROW_ETH) > 0) ? oldSelfBalance - 1 : 0}(
                    params
                );
            } else {
                IApeBot(callTo).largeApeCallback{value: ((flags & FLAG_BORROW_ETH) > 0) ? oldSelfBalance - 1 : 0}(
                    msg.sender,
                    (((flags & FLAG_BORROW_WETH) > 0) ? uint256(cachedBankState.wethBalance) * TOKEN_WETH_MULTIPLIER : 0),
                    (((flags & FLAG_BORROW_WBTC) > 0) ? uint256(cachedBankState.wbtcBalance) * TOKEN_WBTC_MULTIPLIER : 0),
                    (((flags & FLAG_BORROW_DAI ) > 0) ? uint256(cachedBankState.daiBalance ) * TOKEN_DAI_MULTIPLIER  : 0),
                    (((flags & FLAG_BORROW_USDC) > 0) ? uint256(cachedBankState.usdcBalance) * TOKEN_USDC_MULTIPLIER : 0),
                    (((flags & FLAG_BORROW_USDT) > 0) ? uint256(cachedBankState.usdtBalance) * TOKEN_USDT_MULTIPLIER : 0),
                    params
                );
            }
        } else {
            // Immitating popular non-payable callback
            if ((flags & FLAG_BORROW_ETH) > 0) {
                TransferHelper.safeTransferETH(
                    callTo,
                    oldSelfBalance - 1
                );
            }
            IApeBot(callTo).callFunction(
                msg.sender,
                Types.AccountInfo({
                    owner: address(msg.sender),
                    number: 1
                }),
                params
            );
        }

        // Verifying that all funds were returned
        // If Ether was sent into this function it shouldn't be counted against original balance
        oldSelfBalance -= msg.value;
        uint256 newSelfBalance = address(this).balance;
        // Performing gas refunds
        if ((flags & (FLAG_BURN_NATIVE | FLAG_BURN_GST2 | FLAG_BURN_CHI)) > 0) {
            // No point in burning more than 256 tokens
            uint32 tokensToBurn = uint32((flags / FLAG_GAS_TOKEN_BURN_AMOUNT_SHIFT) & 0xff);

            Types.GasTokenPrices memory cachedBurnPrices;
            if ((flags & FLAG_FREE_GAS_TOKEN) > 0) {
                // Bot can enter hall of fame and get free gas tokens for life
                require(bestApeOperators[msg.sender]);
            } else {
                // Otherwise price of these gas tokens would have to be deducted
                cachedBurnPrices = gasTokenBurnPrices;
            }

            if (((flags & FLAG_BURN_NATIVE) > 0) && (cachedBankState.totalContractsCreated > cachedBankState.firstContractToDestroy + tokensToBurn)) {
                _destroyContracts(cachedBankState.firstContractToDestroy, cachedBankState.firstContractToDestroy + tokensToBurn);
                cachedBankState.firstContractToDestroy += tokensToBurn;
                require(newSelfBalance > tokensToBurn * cachedBurnPrices.priceNative);
                newSelfBalance -= tokensToBurn * cachedBurnPrices.priceNative;
            } else if ((flags & FLAG_BURN_GST2) > 0) {
                IGasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04).free(tokensToBurn);
                require(newSelfBalance > tokensToBurn * cachedBurnPrices.priceGST2);
                newSelfBalance -= tokensToBurn * cachedBurnPrices.priceGST2;
            } else if ((flags & FLAG_BURN_CHI) > 0) {
                IGasToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c).free(tokensToBurn);
                require(newSelfBalance > tokensToBurn * cachedBurnPrices.priceCHI);
                newSelfBalance -= tokensToBurn * cachedBurnPrices.priceCHI;
            }
        }

        if ((flags & (FLAG_BORROW_WETH | FLAG_COVER_WETH)) > 0) {
            // We can combine ETH and WETH balances in this case
            uint256 wethBalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
            require(wethBalance < (2 ** 32) * TOKEN_WETH_MULTIPLIER && (newSelfBalance + wethBalance > oldSelfBalance + uint256(cachedBankState.wethBalance) * TOKEN_WETH_MULTIPLIER));

            if (wethBalance <= uint256(cachedBankState.wethBalance) * TOKEN_WETH_MULTIPLIER) {
                // User didn't return enough WETH covering via excess ETH
                uint256 deltaToCover = uint256(cachedBankState.wethBalance) * TOKEN_WETH_MULTIPLIER + 1 - wethBalance;
                require(newSelfBalance >= oldSelfBalance + deltaToCover);

                WETH9(TOKEN_WETH).deposit{value: deltaToCover}();
                // newSelfBalance won't be used anywhere below
                // WETH balance stays the same in the newState
            } else if (newSelfBalance < oldSelfBalance) {
                // User didn't return enough ETH covering via excess WETH
                require(wethBalance > uint256(cachedBankState.wethBalance) * TOKEN_WETH_MULTIPLIER + (oldSelfBalance - newSelfBalance));

                WETH9(TOKEN_WETH).withdraw(oldSelfBalance - newSelfBalance);
                // newSelfBalance won't be used anywhere below
                cachedBankState.wethBalance = uint32((wethBalance - (oldSelfBalance - newSelfBalance)) / TOKEN_WETH_MULTIPLIER);
            } else {
                cachedBankState.wethBalance = uint32(wethBalance / TOKEN_WETH_MULTIPLIER);
            }
        } else {
            require(newSelfBalance >= oldSelfBalance);
        }

        if ((flags & (FLAG_BORROW_WBTC | FLAG_BORROW_DAI | FLAG_BORROW_USDC | FLAG_BORROW_USDT)) > 0) {
            if ((flags & FLAG_BORROW_WBTC) > 0) {
                uint256 wbtcBalance = IERC20Token(TOKEN_WBTC).balanceOf(address(this));
                // We use strict comparison here to make sure that token transfers always cost 5k gas and not (20k - 15k)
                require(wbtcBalance < (2 ** 32) * TOKEN_WBTC_MULTIPLIER && wbtcBalance > uint256(cachedBankState.wbtcBalance) * TOKEN_WBTC_MULTIPLIER);
                cachedBankState.wbtcBalance = uint32(wbtcBalance / TOKEN_WBTC_MULTIPLIER);
            }
            if ((flags & FLAG_BORROW_DAI) > 0) {
                uint256 daiBalance = IERC20Token(TOKEN_DAI).balanceOf(address(this));
                // We use strict comparison here to make sure that token transfers always cost 5k gas and not (20k - 15k)
                require(daiBalance < (2 ** 32) * TOKEN_DAI_MULTIPLIER && daiBalance > uint256(cachedBankState.daiBalance) * TOKEN_DAI_MULTIPLIER);
                cachedBankState.daiBalance = uint32(daiBalance / TOKEN_DAI_MULTIPLIER);
            }
            if ((flags & FLAG_BORROW_USDC) > 0) {
                uint256 usdcBalance = IERC20Token(TOKEN_USDC).balanceOf(address(this));
                // We use strict comparison here to make sure that token transfers always cost 5k gas and not (20k - 15k)
                require(usdcBalance < (2 ** 32) * TOKEN_USDC_MULTIPLIER && usdcBalance > uint256(cachedBankState.usdcBalance) * TOKEN_USDC_MULTIPLIER);
                cachedBankState.usdcBalance = uint32(usdcBalance / TOKEN_USDC_MULTIPLIER);
            }
            if ((flags & FLAG_BORROW_USDT) > 0) {
                uint256 usdtBalance = IERC20Token(TOKEN_USDT).balanceOf(address(this));
                // We use strict comparison here to make sure that token transfers always cost 5k gas and not (20k - 15k)
                require(usdtBalance < (2 ** 32) * TOKEN_USDT_MULTIPLIER && usdtBalance > uint256(cachedBankState.usdtBalance) * TOKEN_USDT_MULTIPLIER);
                cachedBankState.usdtBalance = uint32(usdtBalance / TOKEN_USDT_MULTIPLIER);
            }
        }

        require(cachedBankState.numCalls == state.numCalls);
        cachedBankState.numCalls += 1;
        state = cachedBankState;
    }

    // Logic related to native gas refunds, it's very short but brainfuck level ugly
    function generateContracts(uint256 amount) external {
        Types.BankState memory cachedState = state;
        uint256 offset = cachedState.totalContractsCreated;
        assembly {
            mstore(callvalue(), 0x766f454a11ca3a574738c0aab442b62d5d453318585733FF60005260176009f3)
            for {let i := div(amount, 32)} i {i := sub(i, 1)} {
                pop(create2(callvalue(), callvalue(), 32, offset))          pop(create2(callvalue(), callvalue(), 32, add(offset, 1)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 2)))  pop(create2(callvalue(), callvalue(), 32, add(offset, 3)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 4)))  pop(create2(callvalue(), callvalue(), 32, add(offset, 5)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 6)))  pop(create2(callvalue(), callvalue(), 32, add(offset, 7)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 8)))  pop(create2(callvalue(), callvalue(), 32, add(offset, 9)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 10))) pop(create2(callvalue(), callvalue(), 32, add(offset, 11)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 12))) pop(create2(callvalue(), callvalue(), 32, add(offset, 13)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 14))) pop(create2(callvalue(), callvalue(), 32, add(offset, 15)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 16))) pop(create2(callvalue(), callvalue(), 32, add(offset, 17)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 18))) pop(create2(callvalue(), callvalue(), 32, add(offset, 19)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 20))) pop(create2(callvalue(), callvalue(), 32, add(offset, 21)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 22))) pop(create2(callvalue(), callvalue(), 32, add(offset, 23)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 24))) pop(create2(callvalue(), callvalue(), 32, add(offset, 25)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 26))) pop(create2(callvalue(), callvalue(), 32, add(offset, 27)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 28))) pop(create2(callvalue(), callvalue(), 32, add(offset, 29)))
                pop(create2(callvalue(), callvalue(), 32, add(offset, 30))) pop(create2(callvalue(), callvalue(), 32, add(offset, 31)))
                offset := add(offset, 32)
            }

            for {let i := and(amount, 0x1F)} i {i := sub(i, 1)} {
                pop(create2(callvalue(), callvalue(), 32, offset))
                offset := add(offset, 1)
            }
        }

        require(cachedState.numCalls == state.numCalls && offset < 2 ** 32);
        cachedState.totalContractsCreated = uint32(offset);
        cachedState.numCalls += 1;
        state = cachedState;
    }
    function _destroyContracts(uint256 firstSlot, uint256 lastSlot) internal {
        assembly {
            let i := firstSlot

            let data := mload(0x40)
            mstore(data, 0xff00000000454a11ca3a574738c0aab442b62d5d450000000000000000000000)
            mstore(add(data, 53), 0x51b94132314e7e963fa256338c05c5dd9c15d277c686d6750c3bc97835a1ed27)
            let ptr := add(data, 21)
            for { } lt(i, lastSlot) { i := add(i, 1) } {
                mstore(ptr, i)
                pop(call(gas(), keccak256(data, 85), 0, 0, 0, 0, 0))
            }
        }
    }
}

interface IApeBot {
    function smallApeCallback(bytes calldata data) external payable;
    function largeApeCallback(
        address sender,
        uint wethToReturn,
        uint wbtcToReturn,
        uint daiToReturn,
        uint usdcToReturn,
        uint usdtToReturn,
        bytes calldata data
    ) external payable;
    function callFunction(address sender, Types.AccountInfo memory accountInfo, bytes memory data) external;
}

library Types {
    struct BankState {
        uint32 wethBalance;
        uint32 wbtcBalance;
        uint32 daiBalance;
        uint32 usdcBalance;
        uint32 usdtBalance;
        uint32 firstContractToDestroy;
        uint32 totalContractsCreated;
        uint32 numCalls;
    }
    struct GasTokenPrices {
        uint80 priceGST2;
        uint80 priceCHI;
        uint80 priceNative;
    }
    struct AccountInfo {
        address owner;
        uint256 number;
    }
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// Only relevant calls in interfaces below
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