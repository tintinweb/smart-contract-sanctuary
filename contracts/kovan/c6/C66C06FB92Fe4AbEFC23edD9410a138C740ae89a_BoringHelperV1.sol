/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Copyright (c) 2021 BoringCrypto
// Twitter: @Boring_Crypto

// Version 22-Mar-2021 

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function owner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function bonusEndBlock() external view returns (uint256);

    function devaddr() external view returns (address);

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function startBlock() external view returns (uint256);

    function sushi() external view returns (address);

    function sushiPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 nr)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);

    function pendingSushi(uint256 nr, address who) external view returns (uint256);
}

interface ITopDog {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function bonusEndBlock() external view returns (uint256);

    function devaddr() external view returns (address);

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function startBlock() external view returns (uint256);

    function bone() external view returns (address);

    function bonePerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 nr)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);

    function pendingBone(uint256 nr, address who) external view returns (uint256);
}

interface IPair is IERC20 {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

interface IFactory {
    function allPairsLength() external view returns (uint256);

    function allPairs(uint256 i) external view returns (IPair);

    function getPair(IERC20 token0, IERC20 token1) external view returns (IPair);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);
}

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
}

contract Ownable {
    address public immutable owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

library BoringERC20 {
    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    function symbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success ? returnDataToString(data) : "???";
    }

    function name(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success ? returnDataToString(data) : "???";
    }

    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function DOMAIN_SEPARATOR(IERC20 token) internal view returns (bytes32) {
        (bool success, bytes memory data) = address(token).staticcall{gas: 10000}(abi.encodeWithSelector(0x3644e515));
        return success && data.length == 32 ? abi.decode(data, (bytes32)) : bytes32(0);
    }

    function nonces(IERC20 token, address owner) internal view returns (uint256) {
        (bool success, bytes memory data) = address(token).staticcall{gas: 5000}(abi.encodeWithSelector(0x7ecebe00, owner));
        return success && data.length == 32 ? abi.decode(data, (uint256)) : uint256(-1); // Use max uint256 to signal failure to retrieve nonce (probably not supported)
    }
}

library BoringPair {
    function factory(IPair pair) internal view returns (IFactory) {
        (bool success, bytes memory data) = address(pair).staticcall(abi.encodeWithSelector(0xc45a0155));
        return success && data.length == 32 ? abi.decode(data, (IFactory)) : IFactory(0);
    }
}

interface IStrategy {
    function skim(uint256 amount) external;

    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    function exit(uint256 balance) external returns (int256 amountAdded);
}

interface IBentoBox {
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

    function claimOwnership() external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (uint128 elastic, uint128 base);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

struct Rebase {
    uint128 elastic;
    uint128 base;
}

struct AccrueInfo {
    uint64 interestPerSecond;
    uint64 lastAccrued;
    uint128 feesEarnedFraction;
}

interface IOracle {
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    function symbol(bytes calldata data) external view returns (string memory);

    function name(bytes calldata data) external view returns (string memory);
}

interface IKashiPair {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo() external view returns (AccrueInfo memory info);

    function addAsset(
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (IERC20);

    function balanceOf(address) external view returns (uint256);

    function bentoBox() external view returns (IBentoBox);

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function claimOwnership() external;

    function collateral() external view returns (IERC20);

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        IERC20 collateral_,
        IERC20 asset_,
        address oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        address swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(address to, uint256 fraction) external returns (uint256 share);

    function removeCollateral(address to, uint256 share) external;

    function repay(
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(address swapper, bool enable) external;

    function swappers(address) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (Rebase memory total);

    function totalBorrow() external view returns (Rebase memory total);

    function totalCollateralShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function withdrawFees() external;
}

contract BoringHelperV1 is Ownable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for IPair;
    using BoringPair for IPair;

    IMasterChef public chef; // IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address public maker; // ISushiMaker(0xE11fc0B43ab98Eb91e9836129d1ee7c3Bc95df50);
    IERC20 public sushi; // ISushiToken(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IERC20 public WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IFactory public sushiFactory; // IFactory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IFactory public uniV2Factory; // IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IERC20 public bar; // 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    IBentoBox public bentoBox; // 0xB5891167796722331b7ea7824F036b3Bdcb4531C
    ITopDog public topDog; // ITopDog()
    address public treasureFinder; // ISushiMaker(0xE11fc0B43ab98Eb91e9836129d1ee7c3Bc95df50);
    IERC20 public bone; // ISushiToken(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);



    constructor(
        ITopDog topDog_
    ) public {
        topDog = topDog_;
    }

    function setContracts(
        ITopDog topDog_
    ) public onlyOwner {
        topDog = topDog_;
    }

    struct Factory {
        IFactory factory;
        uint256 allPairsLength;
    }

    struct Balance {
        IERC20 token;
        uint256 balance;
        uint256 bentoBalance;
    }

    struct BalanceFull {
        IERC20 token;
        uint256 totalSupply;
        uint256 balance;
        uint256 bentoBalance;
        uint256 bentoAllowance;
        uint256 nonce;
        uint128 bentoAmount;
        uint128 bentoShare;
        uint256 rate;
    }

    struct TokenInfo {
        IERC20 token;
        uint256 decimals;
        string name;
        string symbol;
        bytes32 DOMAIN_SEPARATOR;
    }


    struct PairBase {
        IPair token;
        IERC20 token0;
        IERC20 token1;
        uint256 totalSupply;
    }



    struct PairPoll {
        IPair token;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        uint256 balance;
    }


    struct PoolsInfo {
        uint256 totalAllocPoint;
        uint256 poolLength;
    }

    struct PoolInfo {
        uint256 pid;
        IPair lpToken;
        uint256 allocPoint;
        bool isPair;
        IFactory factory;
        IERC20 token0;
        IERC20 token1;
        string name;
        string symbol;
        uint8 decimals;
    }


    struct PoolFound {
        uint256 pid;
        uint256 balance;
    }
    

    struct UserPoolInfo {
        uint256 pid;
        uint256 balance; // Balance of pool tokens
        uint256 totalSupply; // Token staked lp tokens
        uint256 lpBalance; // Balance of lp tokens not staked
        uint256 lpTotalSupply; // TotalSupply of lp tokens
        uint256 lpAllowance; // LP tokens approved for masterchef
        uint256 reserve0;
        uint256 reserve1;
        uint256 rewardDebt;
        uint256 pending; // Pending SUSHI
    }

    function pollPools(address who, uint256[] calldata pids) public view returns (UserPoolInfo[] memory) {
        UserPoolInfo[] memory pools = new UserPoolInfo[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            (uint256 amount, ) = topDog.userInfo(pids[i], who);
            pools[i].balance = amount;
            pools[i].pending = topDog.pendingBone(pids[i], who);

            (address lpToken, , , ) = topDog.poolInfo(pids[i]);
            pools[i].pid = pids[i];
            IPair uniV2 = IPair(lpToken);
            IFactory factory = uniV2.factory();
            if (factory != IFactory(0)) {
                pools[i].totalSupply = uniV2.balanceOf(address(topDog));
                pools[i].lpAllowance = uniV2.allowance(who, address(topDog));
                pools[i].lpBalance = uniV2.balanceOf(who);
                pools[i].lpTotalSupply = uniV2.totalSupply();

                (uint112 reserve0, uint112 reserve1, ) = uniV2.getReserves();
                pools[i].reserve0 = reserve0;
                pools[i].reserve1 = reserve1;
            }
        }
        return pools;
    }
}