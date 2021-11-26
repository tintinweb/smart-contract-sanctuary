/**
 *Submitted for verification at FtmScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

// Copyright (c) 2021 theeEnchantress
// Twitter: @0xBuns

// Version 26-Nov-2021

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    function owner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface ISoulSummoner {
    function migrator() external view returns (address);
    function owner() external view returns (address);
    function startTime() external view returns (uint);
    function soul() external view returns (address);
    function soulPerSecond() external view returns (uint);

    function totalAllocPoint() external view returns (uint);
    function poolLength() external view returns (uint);

    function poolInfo(uint nr)
        external
        view
        returns (
            address,
            uint,
            uint,
            uint
        );

    function userInfo(uint nr, address who) external view returns (uint, uint);

    function pendingSoul(uint nr, address who) external view returns (uint);
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
    function totalPairs() external view returns (uint);

    function allPairs(uint i) external view returns (IPair);

    function getPair(IERC20 token0, IERC20 token1) external view returns (IPair);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);
}

library PossessedMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        require((c = a + b) >= b, "PossessedMath: Add Overflow");
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require((c = a - b) <= a, "PossessedMath: Underflow");
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        require(b == 0 || (c = a * b) / b == a, "PossessedMath: Mul Overflow");
    }
}

contract Ownable {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

library PossessedERC20 {
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

    function nonces(IERC20 token, address owner) internal view returns (uint) {
        (bool success, bytes memory data) 
            = address(token).staticcall{gas: 5000}(abi.encodeWithSelector(0x7ecebe00, owner));
        return success && data.length 
            == 32 ? abi.decode(data, (uint)) : type(uint).max; // use max uint to signal failure to retrieve nonce
    }
}

library PossessedPair {
    function factory(IPair pair) internal view returns (IFactory) {
        (bool success, bytes memory data) = address(pair).staticcall(abi.encodeWithSelector(0xc45a0155));
        return success && data.length == 32 ? abi.decode(data, (IFactory)) : IFactory(address(0));
    }
}

interface IStrategy {
    function skim(uint amount) external;

    function harvest(uint balance, address sender) external returns (int256 amountAdded);

    function withdraw(uint amount) external returns (uint actualAmount);

    function exit(uint balance) external returns (int256 amountAdded);
}

interface ISpellBook {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint amount, uint share);
    event LogFlashLoan(
        address indexed borrower, 
        address indexed token, 
        uint amount, 
        uint feeAmount, 
        address indexed receiver
        );
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint amount);
    event LogStrategyInvest(address indexed token, uint amount);
    event LogStrategyLoss(address indexed token, uint amount);
    event LogStrategyProfit(address indexed token, uint amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint amount, uint share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function balanceOf(IERC20, address) external view returns (uint);

    function batch(bytes[] calldata calls, bool revertOnFail) 
        external payable returns (
            bool[] memory successes, bytes[] memory results
        );

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
        uint amount,
        uint share
    ) external payable returns (uint amountOut, uint shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint amount,
        uint deadline,
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
        uint share,
        bool roundUp
    ) external view returns (uint amount);

    function toShare(
        IERC20 token,
        uint amount,
        bool roundUp
    ) external view returns (uint share);

    function totals(IERC20) external view returns (uint128 elastic, uint128 base);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint[] calldata shares
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
        uint amount,
        uint share
    ) external returns (uint amountOut, uint shareOut);
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
    function get(bytes calldata data) external returns (bool success, uint rate);

    function peek(bytes calldata data) external view returns (bool success, uint rate);

    function peekSpot(bytes calldata data) external view returns (uint rate);

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
        uint share
    ) external returns (uint fraction);

    function addCollateral(
        address to,
        bool skim,
        uint share
    ) external;

    function allowance(address, address) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function asset() external view returns (IERC20);

    function balanceOf(address) external view returns (uint);

    function spellBook() external view returns (ISpellBook);

    function borrow(address to, uint amount) external returns (uint part, uint share);

    function claimOwnership() external;

    function collateral() external view returns (IERC20);

    function cook(
        uint8[] calldata actions,
        uint[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint value1, uint value2);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint);

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
        uint[] calldata borrowParts,
        address to,
        address swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(address to, uint fraction) external returns (uint share);

    function removeCollateral(address to, uint share) external;

    function repay(
        address to,
        bool skim,
        uint part
    ) external returns (uint amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(address swapper, bool enable) external;

    function swappers(address) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (Rebase memory total);

    function totalBorrow() external view returns (Rebase memory total);

    function totalCollateralShare() external view returns (uint);

    function totalSupply() external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint rate);

    function userBorrowPart(address) external view returns (uint);

    function userCollateralShare(address) external view returns (uint);

    function withdrawFees() external;
}

contract PossessedHelper is Ownable {
    using PossessedMath for uint;
    using PossessedERC20 for IERC20;
    using PossessedERC20 for IPair;
    using PossessedPair for IPair;

    ISoulSummoner public bruja; // ISoulSummoner(0xce6ccbB1EdAD497B4d53d829DF491aF70065AB5B);
    IERC20 public soul; // ISoulToken(0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07);
    IERC20 public WETH; // 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    IERC20 public WBTC; // 0x321162Cd933E2Be498Cd2267a90534A804051b11;
    IFactory public soulFactory; // IFactory(0x1120e150dA9def6Fe930f4fEDeD18ef57c0CA7eF);
    IFactory public uniV2Factory; // IFactory(0x1120e150dA9def6Fe930f4fEDeD18ef57c0CA7eF);
    IERC20 public enchantment; // 0x6a1a8368D607c7a808F7BbA4F7aEd1D9EbDE147a;
    ISpellBook public spellBook; // 0x400FDECC6eFa3298C17851B8DBd467e530270189;

    constructor(
        ISoulSummoner bruja_,
        IERC20 soul_,
        IERC20 WETH_,
        IERC20 WBTC_,
        IFactory soulFactory_,
        IFactory uniV2Factory_,
        IERC20 enchantment_
    ) {
        bruja = bruja_;
        soul = soul_;
        WETH = WETH_;
        WBTC = WBTC_;
        soulFactory = soulFactory_;
        uniV2Factory = uniV2Factory_;
        enchantment = enchantment_;
    }

    function setContracts(
        ISoulSummoner bruja_,
        IERC20 soul_,
        IERC20 WETH_,
        IERC20 WBTC_,
        IFactory soulFactory_,
        IFactory uniV2Factory_,
        IERC20 enchantment_,
        ISpellBook spellBook_
    ) public onlyOwner {
        bruja = bruja_;
        soul = soul_;
        WETH = WETH_;
        WBTC = WBTC_;
        soulFactory = soulFactory_;
        uniV2Factory = uniV2Factory_;
        enchantment = enchantment_;
        spellBook = spellBook_;
    }

    function getETHRate(IERC20 token) public view returns (uint) {
        if (token == WETH) {
            return 1e18;
        }
        IPair pairUniV2;
        IPair pairSoul;
        if (uniV2Factory != IFactory(address(0))) {
            pairUniV2 = IPair(uniV2Factory.getPair(token, WETH));
        }
        if (soulFactory != IFactory(address(0))) {
            pairSoul = IPair(soulFactory.getPair(token, WETH));
        }
        if (address(pairUniV2) == address(0) && address(pairSoul) == address(0)) {
            return 0;
        }

        uint112 reserve0;
        uint112 reserve1;
        IERC20 token0;
        if (address(pairUniV2) != address(0)) {
            (uint112 reserve0UniV2, uint112 reserve1UniV2, ) = pairUniV2.getReserves();
            reserve0 += reserve0UniV2;
            reserve1 += reserve1UniV2;
            token0 = pairUniV2.token0();
        }

        if (address(pairSoul) != address(0)) {
            (uint112 reserve0Soul, uint112 reserve1Soul, ) = pairSoul.getReserves();
            reserve0 += reserve0Soul;
            reserve1 += reserve1Soul;
            if (token0 == IERC20(address(0))) {
                token0 = pairSoul.token0();
            }
        }

        if (token0 == WETH) {
            return (uint(reserve1) * 1e18) / reserve0;
        } else {
            return (uint(reserve0) * 1e18) / reserve1;
        }
    }

    struct Factory {
        IFactory factory;
        uint totalPairs;
    }

    struct UIInfo {
        uint ethBalance;
        uint soulBalance;
        uint soulEnchantmentBalance;
        uint enchantBalance;
        uint enchantSupply;
        uint soulEnchantmentAllowance;
        Factory[] factories;
        uint ethRate;
        uint soulRate;
        uint btcRate;
        uint pendingSoul;
        uint blockTimeStamp;
        bool[] masterContractApproved;
    }

    function getUIInfo(
        address who,
        IFactory[] calldata factoryAddresses,
        IERC20 currency,
        address[] calldata masterContracts
    ) public view returns (UIInfo memory) {
        UIInfo memory info;
        info.ethBalance = who.balance;

        info.factories = new Factory[](factoryAddresses.length);
        for (uint i = 0; i < factoryAddresses.length; i++) {
            IFactory factory = factoryAddresses[i];
            info.factories[i].factory = factory;
            info.factories[i].totalPairs = factory.totalPairs();
        }

        info.masterContractApproved = new bool[](masterContracts.length);
        for (uint i = 0; i < masterContracts.length; i++) {
            info.masterContractApproved[i] = spellBook.masterContractApproved(masterContracts[i], who);
        }

        if (currency != IERC20(address(0))) {
            info.ethRate = getETHRate(currency);
        }

        if (WBTC != IERC20(address(0))) {
            info.btcRate = getETHRate(WBTC);
        }

        if (soul != IERC20(address(0))) {
            info.soulRate = getETHRate(soul);
            info.soulBalance = soul.balanceOf(who);
            info.soulEnchantmentBalance = soul.balanceOf(address(enchantment));
            info.soulEnchantmentAllowance = soul.allowance(who, address(enchantment));
        }

        if (enchantment != IERC20(address(0))) {
            info.enchantBalance = enchantment.balanceOf(who);
            info.enchantSupply = enchantment.totalSupply();
        }

        if (bruja != ISoulSummoner(address(0))) {
            uint poolLength = bruja.poolLength();
            uint pendingSoul;
            for (uint i = 0; i < poolLength; i++) {
                pendingSoul += bruja.pendingSoul(i, who);
            }
            info.pendingSoul = pendingSoul;
        }
        info.blockTimeStamp = block.timestamp;

        return info;
    }

    struct Balance {
        IERC20 token;
        uint balance;
        uint spellbookBalance;
    }

    struct BalanceFull {
        IERC20 token;
        uint totalSupply;
        uint balance;
        uint spellbookBalance;
        uint spellbookAllowance;
        uint nonce;
        uint128 spellbookAmount;
        uint128 spellbookShare;
        uint rate;
    }

    struct TokenInfo {
        IERC20 token;
        uint decimals;
        string name;
        string symbol;
        bytes32 DOMAIN_SEPARATOR;
    }

    function getTokenInfo(address[] calldata addresses) public view returns (TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            infos[i].token = token;

            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
            infos[i].decimals = token.decimals();
            infos[i].DOMAIN_SEPARATOR = token.DOMAIN_SEPARATOR();
        }

        return infos;
    }

    function findBalances(address who, address[] calldata addresses) public view returns (Balance[] memory) {
        Balance[] memory balances = new Balance[](addresses.length);

        uint len = addresses.length;
        for (uint i = 0; i < len; i++) {
            IERC20 token = IERC20(addresses[i]);
            balances[i].token = token;
            balances[i].balance = token.balanceOf(who);
            balances[i].spellbookBalance = spellBook.balanceOf(token, who);
        }

        return balances;
    }

    function getBalances(address who, IERC20[] calldata addresses) public view returns (BalanceFull[] memory) {
        BalanceFull[] memory balances = new BalanceFull[](addresses.length);

        for (uint i = 0; i < addresses.length; i++) {
            IERC20 token = addresses[i];
            balances[i].totalSupply = token.totalSupply();
            balances[i].token = token;
            balances[i].balance = token.balanceOf(who);
            balances[i].spellbookAllowance = token.allowance(who, address(spellBook));
            balances[i].nonce = token.nonces(who);
            balances[i].spellbookBalance = spellBook.balanceOf(token, who);
            (balances[i].spellbookAmount, balances[i].spellbookShare) = spellBook.totals(token);
            balances[i].rate = getETHRate(token);
        }

        return balances;
    }

    struct PairBase {
        IPair token;
        IERC20 token0;
        IERC20 token1;
        uint totalSupply;
    }

    function getPairs(
        IFactory factory,
        uint fromID,
        uint toID
    ) public view returns (PairBase[] memory) {
        PairBase[] memory pairs = new PairBase[](toID - fromID);

        for (uint id = fromID; id < toID; id++) {
            IPair token = factory.allPairs(id);
            uint i = id - fromID;
            pairs[i].token = token;
            pairs[i].token0 = token.token0();
            pairs[i].token1 = token.token1();
            pairs[i].totalSupply = token.totalSupply();
        }
        return pairs;
    }

    struct PairPoll {
        IPair token;
        uint reserve0;
        uint reserve1;
        uint totalSupply;
        uint balance;
    }

    function pollPairs(address who, IPair[] calldata addresses) public view returns (PairPoll[] memory) {
        PairPoll[] memory pairs = new PairPoll[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            IPair token = addresses[i];
            pairs[i].token = token;
            (uint reserve0, uint reserve1, ) = token.getReserves();
            pairs[i].reserve0 = reserve0;
            pairs[i].reserve1 = reserve1;
            pairs[i].balance = token.balanceOf(who);
            pairs[i].totalSupply = token.totalSupply();
        }
        return pairs;
    }

    struct PoolsInfo {
        uint totalAllocPoint;
        uint poolLength;
    }

    struct PoolInfo {
        uint pid;
        IPair lpToken;
        uint allocPoint;
        bool isPair;
        IFactory factory;
        IERC20 token0;
        IERC20 token1;
        string name;
        string symbol;
        uint8 decimals;
    }

    function getPools(uint[] calldata pids) public view returns (PoolsInfo memory, PoolInfo[] memory) {
        PoolsInfo memory info;
        info.totalAllocPoint = bruja.totalAllocPoint();
        uint poolLength = bruja.poolLength();
        info.poolLength = poolLength;

        PoolInfo[] memory pools = new PoolInfo[](pids.length);

        for (uint i = 0; i < pids.length; i++) {
            pools[i].pid = pids[i];
            (address lpToken, uint allocPoint, , ) = bruja.poolInfo(pids[i]);
            IPair uniV2 = IPair(lpToken);
            pools[i].lpToken = uniV2;
            pools[i].allocPoint = allocPoint;

            pools[i].name = uniV2.name();
            pools[i].symbol = uniV2.symbol();
            pools[i].decimals = uniV2.decimals();

            pools[i].factory = uniV2.factory();
            if (pools[i].factory != IFactory(address(0))) {
                pools[i].isPair = true;
                pools[i].token0 = uniV2.token0();
                pools[i].token1 = uniV2.token1();
            }
        }
        return (info, pools);
    }

    struct PoolFound {
        uint pid;
        uint balance;
    }

    function findPools(address who, uint[] calldata pids) public view returns (PoolFound[] memory) {
        PoolFound[] memory pools = new PoolFound[](pids.length);

        for (uint i = 0; i < pids.length; i++) {
            pools[i].pid = pids[i];
            (pools[i].balance, ) = bruja.userInfo(pids[i], who);
        }

        return pools;
    }

    struct UserPoolInfo {
        uint pid;
        uint balance; // Balance of pool tokens
        uint totalSupply; // Token staked lp tokens
        uint lpBalance; // Balance of lp tokens not staked
        uint lpTotalSupply; // TotalSupply of lp tokens
        uint lpAllowance; // LP tokens approved for soulsummoner
        uint reserve0;
        uint reserve1;
        uint rewardDebt;
        uint pending; // Pending SOUL
    }

    function pollPools(address who, uint[] calldata pids) public view returns (UserPoolInfo[] memory) {
        UserPoolInfo[] memory pools = new UserPoolInfo[](pids.length);

        for (uint i = 0; i < pids.length; i++) {
            (uint amount, ) = bruja.userInfo(pids[i], who);
            pools[i].balance = amount;
            pools[i].pending = bruja.pendingSoul(pids[i], who);

            (address lpToken, , , ) = bruja.poolInfo(pids[i]);
            pools[i].pid = pids[i];
            IPair uniV2 = IPair(lpToken);
            IFactory factory = uniV2.factory();
            if (factory != IFactory(address(0))) {
                pools[i].totalSupply = uniV2.balanceOf(address(bruja));
                pools[i].lpAllowance = uniV2.allowance(who, address(bruja));
                pools[i].lpBalance = uniV2.balanceOf(who);
                pools[i].lpTotalSupply = uniV2.totalSupply();

                (uint112 reserve0, uint112 reserve1, ) = uniV2.getReserves();
                pools[i].reserve0 = reserve0;
                pools[i].reserve1 = reserve1;
            }
        }
        return pools;
    }

    struct KashiPairPoll {
        IERC20 collateral;
        IERC20 asset;
        IOracle oracle;
        bytes oracleData;
        uint totalCollateralShare;
        uint userCollateralShare;
        Rebase totalAsset;
        uint userAssetFraction;
        Rebase totalBorrow;
        uint userBorrowPart;
        uint currentExchangeRate;
        uint spotExchangeRate;
        uint oracleExchangeRate;
        AccrueInfo accrueInfo;
    }

    function pollKashiPairs(address who, IKashiPair[] calldata pairsIn) public view returns (KashiPairPoll[] memory) {
        uint len = pairsIn.length;
        KashiPairPoll[] memory pairs = new KashiPairPoll[](len);

        for (uint i = 0; i < len; i++) {
            IKashiPair pair = pairsIn[i];
            pairs[i].collateral = pair.collateral();
            pairs[i].asset = pair.asset();
            pairs[i].oracle = pair.oracle();
            pairs[i].oracleData = pair.oracleData();
            pairs[i].totalCollateralShare = pair.totalCollateralShare();
            pairs[i].userCollateralShare = pair.userCollateralShare(who);
            pairs[i].totalAsset = pair.totalAsset();
            pairs[i].userAssetFraction = pair.balanceOf(who);
            pairs[i].totalBorrow = pair.totalBorrow();
            pairs[i].userBorrowPart = pair.userBorrowPart(who);

            pairs[i].currentExchangeRate = pair.exchangeRate();
            (, pairs[i].oracleExchangeRate) = pair.oracle().peek(pair.oracleData());
            pairs[i].spotExchangeRate = pair.oracle().peekSpot(pair.oracleData());
            pairs[i].accrueInfo = pair.accrueInfo();
        }

        return pairs;
    }
}