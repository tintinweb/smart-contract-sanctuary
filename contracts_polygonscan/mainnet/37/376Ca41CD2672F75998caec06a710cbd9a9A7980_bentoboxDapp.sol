pragma solidity ^0.6.12;

//import statements go here
import "./interfaces/IBentoBoxV1.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract bentoboxDapp {
    using SafeMath for uint256;

    address public constant BENTOBOX_MASTER_CONTRACT_ADDRESS = 0x0319000133d3AdA02600f0875d2cf03D442C3367;

    address public constant USDC_ADDRESS = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    
    address public constant WMATIC_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant SUSHI_ADDRESS = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address public constant WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant WBTC_ADDRESS = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

    address public constant MATIC_USD_ORACLE = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant BTC_USD_ORACLE = 0xc907E116054Ad103354f2D350FD2514433D57F6f;
    address public constant ETH_USD_ORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
    address public constant SUSHI_USD_ORACLE = 0x49B0c695039243BBfEb8EcD054EB70061fd54aa0;

    address[] public USDCToWMATICPath = [USDC_ADDRESS, WMATIC_ADDRESS];
    address[] public USDCToSUSHIPath = [USDC_ADDRESS, SUSHI_ADDRESS];
    address[] public USDCToWETHPath = [USDC_ADDRESS, WETH_ADDRESS];
    address[] public USDCToWBTCPath = [USDC_ADDRESS, WBTC_ADDRESS];

    address[] public WMATICToUSDCPath = [WMATIC_ADDRESS, USDC_ADDRESS];
    address[] public SUSHIToUSDCPath = [SUSHI_ADDRESS, USDC_ADDRESS];
    address[] public WETHToUSDCPath = [WETH_ADDRESS, USDC_ADDRESS];
    address[] public WBTCToUSDCPath = [WBTC_ADDRESS, USDC_ADDRESS];

    address public constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    
    uint256 public totalNumberOfShares;
    mapping(address => uint256) public userNumberOfShares; 

    IBentoBoxV1 public BentoMasterContract = IBentoBoxV1(BENTOBOX_MASTER_CONTRACT_ADDRESS);
    IUniswapV2Router02 public sushiSwapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER);
    //more variables here
    // constructor() autoBalancer public {
    //     // BentoMasterContract = IBentoBoxV1(BENTOBOX_MASTER_CONTRACT_ADDRESS);
    //     // BentoMasterContract.registerProtocol();
    // } 

    function registerProtocol () public {
        BentoMasterContract.registerProtocol();
    }
    
    /**
     * Returns the latest price
     */
    function getLatestPrice(address _oracle_address) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_oracle_address).latestRoundData();
        return price;
    }

    function updateSharesOnWithdrawal(address user) public { //make this ownable - only contract itself can update this?
        require (userNumberOfShares[user] > 0, "Error - This user has no shares");
        totalNumberOfShares -= userNumberOfShares[user];
        userNumberOfShares[user] = 0;
    }

    function getUserShares(address user) public view returns (uint256 userShares) {
        return userNumberOfShares[user];
    }

    function approve_spending (address token_address, address spender_address, uint256 amount_to_approve) public {
            IERC20(token_address).approve(spender_address, amount_to_approve);
    }
    
     receive() external payable {
    }

    function depositToBento (uint256 amount_, address token_address, address address_from, address address_to) public  {
            IERC20 token_ = IERC20(token_address);

            BentoMasterContract.deposit(
            token_, //IERC20 token_ what is this? USDC contract address? no, I think it's the instantiation of an ERC20...
            address_from, //from - this would be from the dapp
            address_to, //to - this would be to bentobox?
            amount_, //10USDC?
            0 //leave blank I think...
            );
    }

    function depositUserFunds (uint256 amount_, address token_address, address address_from, address address_to) public  {
        IERC20 token_ = IERC20(token_address);

        BentoMasterContract.deposit(
        token_, //IERC20 token_ what is this? USDC contract address? no, I think it's the instantiation of an ERC20...
        address_from, //from - this would be from the dapp
        address_to, //to - this would be to bentobox?
        amount_, //10USDC?
        0 //leave blank I think...
        );

        withdraw(amount_, token_address, address(this), address(this));

        approve_spending(USDC_ADDRESS, SUSHISWAP_ROUTER, amount_);

        uint256 WMATIC_balanceInUSD = getUSDBentoTokenBalanceOf(WMATIC_ADDRESS, MATIC_USD_ORACLE, 18);
        uint256 SUSHI_balanceInUSD = getUSDBentoTokenBalanceOf(SUSHI_ADDRESS, SUSHI_USD_ORACLE, 18);
        uint256 WETH_balanceInUSD = getUSDBentoTokenBalanceOf(WETH_ADDRESS, ETH_USD_ORACLE, 18);
        uint256 WBTC_balanceInUSD = getUSDBentoTokenBalanceOf(WBTC_ADDRESS, BTC_USD_ORACLE, 8);

        uint256 Total_in_USD = WMATIC_balanceInUSD.add(SUSHI_balanceInUSD).add(WETH_balanceInUSD).add(WBTC_balanceInUSD);
        
        if (Total_in_USD > 0) {
            swapProportionately(WMATIC_balanceInUSD, SUSHI_balanceInUSD, WETH_balanceInUSD, WBTC_balanceInUSD, Total_in_USD, amount_);
        } else {
            swapIntoFourEqualParts(amount_);
        }
        
        depositAllFourTokensBackToBento();

        if (Total_in_USD > 0) {
            updateSharesOnDeposit(address_from, Total_in_USD, amount_);
        } else {
            setSharesFirstTime(address_from);
        }
    }
    function getUSDBentoTokenBalanceOf(address token_address, address oracle_address, uint256 token_decimals) public view returns (uint256) {
        // uint256 token_decimals = ERC20(token_address).decimals();
        return BentoTokenBalanceOf(token_address, address(this))
        .mul(uint256(getLatestPrice(oracle_address)))
        .div(10**(token_decimals+2));
    }



    function swapProportionately(uint256 WMATIC_amount, uint256 SUSHI_amount, uint256 WETH_amount, uint256 WBTC_amount, uint256 totalUSDAmount, uint256 depositAmount) public {
        uint256 WMATIC_share = WMATIC_amount.div(totalUSDAmount).mul(depositAmount); 
        uint256 SUSHI_share = SUSHI_amount.div(totalUSDAmount).mul(depositAmount);
        uint256 WETH_share = WETH_amount.div(totalUSDAmount).mul(depositAmount);
        uint256 WBTC_share = WBTC_amount.div(totalUSDAmount).mul(depositAmount);

        swap(WMATIC_share, uint256(0), USDCToWMATICPath, address(this), uint256(-1));
        swap(SUSHI_share, uint256(0), USDCToSUSHIPath, address(this), uint256(-1));
        swap(WETH_share, uint256(0), USDCToWETHPath, address(this), uint256(-1));
        swap(WBTC_share, uint256(0), USDCToWBTCPath, address(this), uint256(-1));
    }

    function swapIntoFourEqualParts(uint256 amount) public {
        swap(amount.div(4), uint256(0), USDCToWMATICPath, address(this), uint256(-1));
        swap(amount.div(4), uint256(0), USDCToSUSHIPath, address(this), uint256(-1));
        swap(amount.div(4), uint256(0), USDCToWETHPath, address(this), uint256(-1));
        swap(amount.div(4), uint256(0), USDCToWBTCPath, address(this), uint256(-1));
    }

    function depositAllFourTokensBackToBento() public {
        approve_spending(WMATIC_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS, 9999999999999999999999999);
        depositTokenBalanceToBento(WMATIC_ADDRESS, address(this), address(this));
        approve_spending(SUSHI_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS, 9999999999999999999999999);
        depositTokenBalanceToBento(SUSHI_ADDRESS, address(this), address(this));
        approve_spending(WETH_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS, 9999999999999999999999999);
        depositTokenBalanceToBento(WETH_ADDRESS, address(this), address(this));
        approve_spending(WBTC_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS, 9999999999999999999999999);
        depositTokenBalanceToBento(WBTC_ADDRESS, address(this), address(this));
    }

    function setSharesFirstTime(address user) public {
        userNumberOfShares[user] = 100000000;
        totalNumberOfShares = userNumberOfShares[user];
    }

    function updateSharesOnDeposit(address user, uint256 total_in_USD, uint256 deposit_amount) public { //make this ownable - only contract itself can update this?
        uint256 newSharesForUser = deposit_amount.div(total_in_USD).mul(totalNumberOfShares);
        totalNumberOfShares = totalNumberOfShares.add(newSharesForUser);
        if (userNumberOfShares[user] > 0) {
            userNumberOfShares[user] = userNumberOfShares[user].add(newSharesForUser);
        } else {
            userNumberOfShares[user] = newSharesForUser;
        }
    }

    function depositTokenBalanceToBento (address token_address, address address_from, address address_to) public  {
        IERC20 token_ = IERC20(token_address);
        uint256 tokenBalance = token_.balanceOf(address_from);
        
        BentoMasterContract.deposit(
        token_, //IERC20 token_ the instantiation of an ERC20...
        address_from, //from - this would be from the dapp or the user
        address_to, //to - this would be to bentobox
        tokenBalance, //10USDC?
        0 //leave blank I think...
        );
    }
    function withdrawUserFunds(address user) public {
        //do I need an approval here?

        uint256 WMATIC_amount = userNumberOfShares[user].div(totalNumberOfShares).mul(BentoTokenBalanceOf(WMATIC_ADDRESS, address(this)));
        uint256 SUSHI_amount = userNumberOfShares[user].div(totalNumberOfShares).mul(BentoTokenBalanceOf(SUSHI_ADDRESS, address(this)));
        uint256 WETH_amount = userNumberOfShares[user].div(totalNumberOfShares).mul(BentoTokenBalanceOf(WETH_ADDRESS, address(this)));
        uint256 WBTC_amount = userNumberOfShares[user].div(totalNumberOfShares).mul(BentoTokenBalanceOf(WBTC_ADDRESS, address(this)));

        withdrawAllFourTokensFromBento(WMATIC_amount, SUSHI_amount, WETH_amount, WBTC_amount);

        approveSpendingWholeBalance(WMATIC_ADDRESS, SUSHISWAP_ROUTER);
        approveSpendingWholeBalance(SUSHI_ADDRESS, SUSHISWAP_ROUTER);
        approveSpendingWholeBalance(WETH_ADDRESS, SUSHISWAP_ROUTER);
        approveSpendingWholeBalance(WBTC_ADDRESS, SUSHISWAP_ROUTER);

        swapWholeBalanceBackToUSDC(WMATIC_ADDRESS);
        swapWholeBalanceBackToUSDC(SUSHI_ADDRESS);
        swapWholeBalanceBackToUSDC(WETH_ADDRESS);
        swapWholeBalanceBackToUSDC(WBTC_ADDRESS);

        approveSpendingWholeBalance(USDC_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS);
        
        depositTokenBalanceToBento(USDC_ADDRESS, address(this), address(this));

        uint256 USDC_amount = BentoTokenBalanceOf(USDC_ADDRESS, address(this));
        withdraw(USDC_amount, USDC_ADDRESS, address(this), user);

        updateSharesOnWithdrawal(user);
    }

    function withdrawAllFourTokensFromBento(uint256 _WMATIC_amount, uint256 _SUSHI_amount, uint256 _WETH_amount, uint256 _WBTC_amount) public {
        withdraw(_WMATIC_amount, WMATIC_ADDRESS, address(this), address(this));
        withdraw(_SUSHI_amount, SUSHI_ADDRESS, address(this), address(this));
        withdraw(_WETH_amount, WETH_ADDRESS, address(this), address(this));
        withdraw(_WBTC_amount, WBTC_ADDRESS, address(this), address(this));
    }

    function withdraw(uint256 amount_, address token_address, address address_from, address address_to) public  {
        IERC20 token_ = IERC20(token_address); //is this right?

        BentoMasterContract.withdraw(
        token_, 
        address_from, //address from - the bentobox master contract address??
        address_to, //address to - the address of the dapp itself
        amount_, //leave blank?
        0 //uint256 share
    );
    }

    function approveSpendingWholeBalance(address _token, address _spender) public {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        approve_spending(_token, _spender, tokenBalance);
    }

    function swapWholeBalanceBackToUSDC(address _token) public {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = USDC_ADDRESS;
        swap(tokenBalance, uint256(0), path, address(this), uint256(-1));
    }
    
    function withdraw_matic(uint256 amount_) public {
        msg.sender.transfer(amount_);
    }
    
    function transfer(address token_address, uint256 _share, address address_from, address address_to) public  {
        IERC20 _token = IERC20(token_address);
    // do I call this on bentomastercontract? I think so. But then it's the app making the call.
    BentoMasterContract.transfer(
        _token, //IERC20 token
        address_from, //address from - a specified user address
        address_to, //address to - the dapp itself receives the funds
        _share //uint256 share
        );
    }

    function BentoTokenBalanceOf(address token_address, address user_address) public view returns (uint256 token_balance) {
        IERC20 _token = IERC20(token_address);
        token_balance = BentoMasterContract.balanceOf(_token, user_address);
        return token_balance;
    }
    
    function swap(uint256 _amountIn, uint256 _amountOutMin, address[] memory _path, address _acct, uint256 _deadline) public {
        
       sushiSwapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _acct,
            _deadline);
        }
    }

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.add(elastic.to128());
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.sub(elastic.to128());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./IERC20.sol";

interface IBatchFlashBorrower {
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./BoringRebase.sol";
import './IBatchFlashBorrower.sol';
import './IFlashBorrower.sol';
import './IStrategy.sol';

interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function balanceOf(IERC20, address) external view returns (uint256);
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);
    function batchFlashLoan(IBatchFlashBorrower borrower, address[] calldata receivers, IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
    function claimOwnership() external;
    function deploy(address masterContract, bytes calldata data, bool useCreate2) external payable;
    function deposit(IERC20 token_, address from, address to, uint256 amount, uint256 share) external payable returns (uint256 amountOut, uint256 shareOut);
    function flashLoan(IFlashBorrower borrower, address receiver, IERC20 token, uint256 amount, bytes calldata data) external;
    function harvest(IERC20 token, bool balance, uint256 maxChangeAmount) external;
    function masterContractApproved(address, address) external view returns (bool);
    function masterContractOf(address) external view returns (address);
    function nonces(address) external view returns (uint256);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function pendingStrategy(IERC20) external view returns (IStrategy);
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function registerProtocol() external;
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function setStrategy(IERC20 token, IStrategy newStrategy) external;
    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;
    function strategy(IERC20) external view returns (IStrategy);
    function strategyData(IERC20) external view returns (uint64 strategyStartDate, uint64 targetPercentage, uint128 balance);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(IERC20 token, uint256 amount, bool roundUp) external view returns (uint256 share);
    function totals(IERC20) external view returns (Rebase memory totals_);
    function transfer(IERC20 token, address from, address to, uint256 share) external;
    function transferMultiple(IERC20 token, address from, address[] calldata tos, uint256[] calldata shares) external;
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function whitelistMasterContract(address masterContract, bool approved) external;
    function whitelistedMasterContracts(address) external view returns (bool);
    function withdraw(IERC20 token_, address from, address to, uint256 amount, uint256 share) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./IERC20.sol";

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStrategy {
    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256 amount) external;

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    // The actualAmount should be very close to the amount. The difference should NOT be used to report a loss. That's what harvest is for.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

pragma solidity ^0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.6.12;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}