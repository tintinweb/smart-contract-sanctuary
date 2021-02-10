/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function owner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISushiSwapPoolNames {
    function logos(uint256) external view returns(string memory);
    function names(uint256) external view returns(string memory);
    function setPoolInfo(uint256 pid, string memory logo, string memory name) external;
}

interface ISushiToken is IERC20 {
    function delegates(address who) external view returns(address);
    function getCurrentVotes(address who) external view returns(uint256);
    function nonces(address who) external view returns(uint256);
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
    function poolInfo(uint256 nr) external view returns (address, uint256, uint256, uint256);
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingSushi(uint256 nr, address who) external view returns (uint256);
}

interface IPair is IERC20 {
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IFactory {
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256 i) external view returns (IPair);
    function getPair(IERC20 token0, IERC20 token1) external view returns (IPair);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}

library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
}

contract Ownable {
    address public immutable owner;

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

library BoringERC20
{
    function symbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }    

    function name(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private constant ZERO_ADDRESS = address(0);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(ZERO_ADDRESS, msg.sender);
    }

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != ZERO_ADDRESS || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = ZERO_ADDRESS;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = ZERO_ADDRESS;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

contract BoringHelper is BoringOwnable
{
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    IMasterChef public chef; // IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address public maker; // ISushiMaker(0xE11fc0B43ab98Eb91e9836129d1ee7c3Bc95df50);
    ISushiToken public sushi; // ISushiToken(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IERC20 public WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public WBTC; // 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    IFactory public sushiFactory; // IFactory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IFactory public uniV2Factory; // IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IERC20 public bar; // 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    constructor(IMasterChef chef_, address maker_, ISushiToken sushi_, IERC20 WETH_, IERC20 WBTC_, IFactory sushiFactory_, IFactory uniV2Factory_, IERC20 bar_) public {
        setContracts(chef_, maker_, sushi_, WETH_, WBTC_, sushiFactory_, uniV2Factory_, bar_);
    }

    function setContracts(IMasterChef chef_, address maker_, ISushiToken sushi_, IERC20 WETH_, IERC20 WBTC_, IFactory sushiFactory_, IFactory uniV2Factory_, IERC20 bar_) public onlyOwner {
        chef = chef_;
        maker = maker_;
        sushi = sushi_;
        WETH = WETH_;
        WBTC = WBTC_;
        sushiFactory = sushiFactory_;
        uniV2Factory = uniV2Factory_;
        bar = bar_;
    }

    function getETHRate(IERC20 token) public view returns(uint256) {
        if (token == WETH) { return 1e18; }
        IPair pairUniV2 = IPair(uniV2Factory.getPair(token, WETH));
        IPair pairSushi = IPair(sushiFactory.getPair(token, WETH));
        if (address(pairUniV2) == address(0) && address(pairSushi) == address(0)) {
            return 0;
        }
        
        uint112 reserve0; uint112 reserve1;
        if (address(pairUniV2) != address(0)) {
            (uint112 reserve0UniV2, uint112 reserve1UniV2,) = pairUniV2.getReserves();
            reserve0 += reserve0UniV2;
            reserve1 += reserve1UniV2;
        }

        if (address(pairSushi) != address(0)) {
            (uint112 reserve0Sushi, uint112 reserve1Sushi,) = pairSushi.getReserves();
            reserve0 += reserve0Sushi;
            reserve1 += reserve1Sushi;
        }
        
        if (pairUniV2.token0() == WETH) { 
            return uint256(reserve1).mul(1e18) / reserve0; 
        } else { 
            return uint256(reserve0).mul(1e18) / reserve1; 
        }
    }

    struct Factory {
        IFactory factory;
        uint256 allPairsLength;
        address feeTo;
        address feeToSetter;
    }
    
    struct UIInfo {
        uint256 ethBalance;
        uint256 sushiBalance;
        uint256 sushiBarBalance;
        uint256 xsushiBalance;
        uint256 xsushiSupply;
        uint256 sushiBarAllowance;
        Factory[] factories;
        uint256 ethRate;
        uint256 sushiRate;
        uint256 btcRate;
    }

    function getUIInfo(address who, IFactory[] calldata factoryAddresses, IERC20 currency) public view returns(UIInfo memory) {
        UIInfo memory info;
        info.ethBalance = who.balance;

        info.factories = new Factory[](factoryAddresses.length);

        for (uint256 i = 0; i < factoryAddresses.length; i++) {
            IFactory factory = factoryAddresses[i];
            info.factories[i].factory = factory;
            info.factories[i].allPairsLength = factory.allPairsLength();
            info.factories[i].feeTo = factory.feeTo();
            info.factories[i].feeToSetter = factory.feeToSetter();
        }

        info.ethRate = getETHRate(currency);
        info.sushiRate = getETHRate(sushi);
        info.btcRate = getETHRate(WBTC);

        info.sushiBalance = sushi.balanceOf(who);
        info.sushiBarBalance = sushi.balanceOf(address(bar));
        info.xsushiBalance = bar.balanceOf(who);
        info.xsushiSupply = bar.totalSupply();
        info.sushiBarAllowance = sushi.allowance(who, address(bar));

        return info;
    }

    struct Balance {
        IERC20 token;
        uint256 balance;
    }
    
    struct BalanceFull {
        IERC20 token;
        uint256 balance;
        uint256 rate;
    }
    
    struct TokenInfo {
        IERC20 token;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getTokenInfo(address[] calldata addresses) public view returns(TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            infos[i].token = token;
            
            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
            infos[i].decimals = token.decimals();
        }

        return infos;
    }

    function findBalances(address who, address[] calldata addresses) public view returns(Balance[] memory) {
        uint256 balanceCount;

        for (uint256 i = 0; i < addresses.length; i++) {
            if (IERC20(addresses[i]).balanceOf(who) > 0) {
                balanceCount++;
            }
        }

        Balance[] memory balances = new Balance[](balanceCount);

        balanceCount = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            uint256 balance = token.balanceOf(who);
            if (balance > 0) {
                balances[balanceCount].token = token;
                balances[balanceCount].balance = token.balanceOf(who);
                balanceCount++;
            }
        }

        return balances;
    }

    function getBalances(address who, address[] calldata addresses) public view returns(BalanceFull[] memory) {
        BalanceFull[] memory balances = new BalanceFull[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            balances[i].token = token;
            balances[i].balance = IERC20(token).balanceOf(who);
            balances[i].rate = getETHRate(token);
        }

        return balances;
    }

    struct Pair {
        IPair token;
        IERC20 token0;
        IERC20 token1;
    }
    
    function getPairs(IFactory factory, uint256 fromID, uint256 toID) public view returns(Pair[] memory) {
        Pair[] memory pairs = new Pair[](toID - fromID);

        for(uint256 id = fromID; id < toID; id++) {
            IPair token = factory.allPairs(id);
            uint256 i = id - fromID;
            pairs[i].token = token;
            pairs[i].token0 = token.token0();
            pairs[i].token1 = token.token1();
        }
        return pairs;
    }

    function findPairs(address who, IFactory factory, uint256 fromID, uint256 toID) public view returns(Pair[] memory) {
        uint256 pairCount;

        for(uint256 id = fromID; id < toID; id++) {
            IPair token = factory.allPairs(id);
            if (IERC20(token).balanceOf(who) > 0) {
                pairCount++;
            }
        }

        Pair[] memory pairs = new Pair[](pairCount);

        pairCount = 0;
        for(uint256 id = fromID; id < toID; id++) {
            IPair token = factory.allPairs(id);
            uint256 balance = IERC20(token).balanceOf(who);
            if (balance > 0) {
                pairs[pairCount].token = token;
                pairs[pairCount].token0 = IPair(token).token0();
                pairs[pairCount].token1 = IPair(token).token1();
                pairCount++;
            }
        }

        return pairs;
    }

    struct PairPoll {
        IPair token;
        IERC20 token0;
        IERC20 token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        uint256 balance;
    }

    function pollPairs(address who, IPair[] calldata addresses) public view returns(PairPoll[] memory) {
        PairPoll[] memory pairs = new PairPoll[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            IPair token = addresses[i];
            pairs[i].token = token;
            pairs[i].token0 = token.token0();
            pairs[i].token1 = token.token1();
            (uint256 reserve0, uint256 reserve1,) = token.getReserves();
            pairs[i].reserve0 = reserve0;
            pairs[i].reserve1 = reserve1;
            pairs[i].balance = token.balanceOf(who);
            pairs[i].totalSupply = token.totalSupply();
        }
        return pairs;
    }

    struct PoolsInfo {
        uint256 totalAllocPoint;
        uint256 poolLength;
    }

    struct PoolInfo {
        uint256 pid;
        IPair lpToken;           
        uint256 allocPoint;      
        IERC20 token0;
        IERC20 token1;
    }
    
    function getPools(uint256[] calldata pids) public view returns(PoolsInfo memory, PoolInfo[] memory) {
        PoolsInfo memory info;
        info.totalAllocPoint = chef.totalAllocPoint();
        uint256 poolLength = chef.poolLength();
        info.poolLength = poolLength;
        
        PoolInfo[] memory pools = new PoolInfo[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            pools[i].pid = pids[i];
            (address lpToken, uint256 allocPoint,,) = chef.poolInfo(pids[i]);
            IPair uniV2 = IPair(lpToken);
            pools[i].lpToken = uniV2;
            pools[i].allocPoint = allocPoint;

            pools[i].token0 = uniV2.token0();
            pools[i].token1 = uniV2.token1();
        }
        return (info, pools);
    }
    
    function findPools(address who, uint256[] calldata pids) public view returns(PoolInfo[] memory) {
        uint256 count;

        for (uint256 i = 0; i < pids.length; i++) {
            (uint256 balance,) = chef.userInfo(pids[i], who);
            if (balance > 0) {
                count++;
            }
        }

        PoolInfo[] memory pools = new PoolInfo[](count);

        count = 0;
        for (uint256 i = 0; i < pids.length; i++) {
            (uint256 balance,) = chef.userInfo(pids[i], who);
            if (balance > 0) {
                pools[count].pid = pids[i];
                (address lpToken, uint256 allocPoint,,) = chef.poolInfo(pids[i]);
                IPair uniV2 = IPair(lpToken);
                pools[count].lpToken = uniV2;
                pools[count].allocPoint = allocPoint;
    
                pools[count].token0 = uniV2.token0();
                pools[count].token1 = uniV2.token1();
                count++;
            }
        }

        return pools;
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
        uint256 token0rate;
        uint256 token1rate;
        uint256 rewardDebt;
        uint256 pending; // Pending SUSHI
    }    
    
    function pollPools(address who, uint256[] calldata pids) public view returns(UserPoolInfo[] memory) {
        UserPoolInfo[] memory pools = new UserPoolInfo[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            (uint256 amount,) = chef.userInfo(pids[i], who);
            pools[i].balance = amount;
            pools[i].pending = chef.pendingSushi(pids[i], who);

            (address lpToken,,,) = chef.poolInfo(pids[i]);
            pools[i].pid = pids[i];
            IPair uniV2 = IPair(lpToken);
            pools[i].totalSupply = uniV2.balanceOf(address(chef));
            pools[i].lpAllowance = uniV2.allowance(who, address(chef));
            pools[i].lpBalance = uniV2.balanceOf(who);
            pools[i].lpTotalSupply = uniV2.totalSupply();
            pools[i].token0rate = getETHRate(uniV2.token0());
            pools[i].token1rate = getETHRate(uniV2.token1());
            
            (uint112 reserve0, uint112 reserve1,) = uniV2.getReserves();
            pools[i].reserve0 = reserve0;
            pools[i].reserve1 = reserve1;
        }
        return pools;
    }
}