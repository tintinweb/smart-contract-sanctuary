/**
 *Submitted for verification at Etherscan.io on 2020-09-06
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function owner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISushiSwapPoolNames {
    function logos(uint256) external view returns(string memory);
    function names(uint256) external view returns(string memory);
    function setPoolInfo(uint256 pid, string memory logo, string memory name) external;
}

interface ISushiToken is IERC20{
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

interface IUniswapFactory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapPair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Underflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Mul Overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Div by 0");
        uint256 c = a / b;

        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

struct BaseInfo {
    uint256 BONUS_MULTIPLIER;
    uint256 bonusEndBlock;
    address devaddr;
    address migrator;
    address owner;
    uint256 startBlock;
    address sushi;
    uint256 sushiPerBlock;
    uint256 totalAllocPoint;
    
    uint256 sushiTotalSupply;
    address sushiOwner;
}

struct PoolInfo {
    string logo;
    string name;
    IUniswapPair lpToken;           // Address of LP token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
    uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
    uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    IERC20 token0;
    IERC20 token1;
    string token0name;
    string token1name;
    string token0symbol;
    string token1symbol;
    uint256 token0decimals;
    uint256 token1decimals;
}

struct UserInfo {
    uint256 block;
    uint256 timestamp;
    uint256 eth_rate;
    uint256 sushiBalance;
    address delegates;
    uint256 currentVotes;
    uint256 nonces;
}

struct UserPoolInfo {
    uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
    uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    uint256 balance; // Balance of pool tokens
    uint256 totalSupply; // Token staked lp tokens
    uint256 uniBalance; // Balance of uniswap lp tokens not staked
    uint256 uniTotalSupply; // TotalSupply of uniswap lp tokens
    uint256 uniAllowance; // UniSwap LP tokens approved for masterchef
    uint256 reserve0;
    uint256 reserve1;
    uint256 token0rate;
    uint256 token1rate;
    uint256 rewardDebt;
    uint256 pending; // Pending SUSHI
}

contract SushiSwapBaseInfo is Ownable {
    // Mainnet
    ISushiSwapPoolNames names = ISushiSwapPoolNames(0xb373a5def62A907696C0bBd22Dc512e2Fc8cfC7E);
    IMasterChef masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    
    // Ropsten
    //ISushiSwapPoolNames names = ISushiSwapPoolNames(0x7685f4c573cE27C94F6aF70B330C29b9c41B8290);
    //IMasterChef masterChef = IMasterChef(0xFF281cEF43111A83f09C656734Fa03E6375d432A);
    
    function setContracts(address names_, address masterChef_) public onlyOwner {
        names = ISushiSwapPoolNames(names_);
        masterChef = IMasterChef(masterChef_);
    }

    function getInfo() public view returns(BaseInfo memory, PoolInfo[] memory) {
        BaseInfo memory info;
        info.BONUS_MULTIPLIER = masterChef.BONUS_MULTIPLIER();
        info.bonusEndBlock = masterChef.bonusEndBlock();
        info.devaddr = masterChef.devaddr();
        info.migrator = masterChef.migrator();
        info.owner = masterChef.owner();
        info.startBlock = masterChef.startBlock();
        info.sushi = masterChef.sushi();
        info.sushiPerBlock = masterChef.sushiPerBlock();
        info.totalAllocPoint = masterChef.totalAllocPoint();
        
        info.sushiTotalSupply = IERC20(info.sushi).totalSupply();
        info.sushiOwner = IERC20(info.sushi).owner();

        uint256 poolLength = masterChef.poolLength();
        PoolInfo[] memory pools = new PoolInfo[](poolLength);
        for (uint256 i = 0; i < poolLength; i++) {
            (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(i);
            IUniswapPair uniV2 = IUniswapPair(lpToken);
            pools[i].lpToken = uniV2;
            pools[i].allocPoint = allocPoint;
            pools[i].lastRewardBlock = lastRewardBlock;
            pools[i].accSushiPerShare = accSushiPerShare;
            
            IERC20 token0 = IERC20(uniV2.token0());
            pools[i].token0 = token0;
            IERC20 token1 = IERC20(uniV2.token1());
            pools[i].token1 = token1;
            
            pools[i].token0name = token0.name();
            pools[i].token0symbol = token0.symbol();
            pools[i].token0decimals = token0.decimals();
            
            pools[i].token1name = token1.name();
            pools[i].token1symbol = token1.symbol();
            pools[i].token1decimals = token1.decimals();
            
            pools[i].logo = names.logos(i);
            pools[i].name = names.names(i);
        }
        return (info, pools);
    }
}

contract SushiSwapUserInfo is Ownable
{
    using SafeMath for uint256;

    // Ropsten
    IUniswapFactory uniFactory = IUniswapFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IMasterChef masterChef = IMasterChef(0xFF281cEF43111A83f09C656734Fa03E6375d432A);
    ISushiToken sushi = ISushiToken(0x81DB9C598b3ebbdC92426422fc0A1d06E77195ec);
    address WETH = 0x078A84ee7991699DD198B7b95055AEd0C782A6eE;

    function setContracts(address uniFactory_, address masterChef_, address sushi_, address WETH_) public onlyOwner {
        uniFactory = IUniswapFactory(uniFactory_);
        masterChef = IMasterChef(masterChef_);
        sushi = ISushiToken(sushi_);
        WETH = WETH_;
    }

    function getETHRate(address token) public view returns(uint256) {
        uint256 eth_rate = 1e18;
        if (token != WETH)
        {
            IUniswapPair pair = IUniswapPair(uniFactory.getPair(token, WETH));
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            if (pair.token0() == WETH) {
                eth_rate = uint256(reserve1).mul(1e18).div(reserve0);
            } else {
                eth_rate = uint256(reserve0).mul(1e18).div(reserve1);
            }
        }
        return eth_rate;
    }
    
    function _getUserInfo(address who, address currency) private view returns(UserInfo memory) {
        UserInfo memory user;
        
        user.block = block.number;
        user.timestamp = block.timestamp;
        user.sushiBalance = sushi.balanceOf(who);
        user.delegates = sushi.delegates(who);
        user.currentVotes = sushi.getCurrentVotes(who);
        user.nonces = sushi.nonces(who);
        user.eth_rate = getETHRate(currency);
        
        return user;
    }
    
    function getUserInfo(address who, address currency) public view returns(UserInfo memory, UserPoolInfo[] memory) {
        uint256 poolLength = masterChef.poolLength();
        UserPoolInfo[] memory pools = new UserPoolInfo[](poolLength);

        for (uint256 i = 0; i < poolLength; i++) {
            (uint256 amount, uint256 rewardDebt) = masterChef.userInfo(i, who);
            pools[i].balance = amount;
            pools[i].rewardDebt = rewardDebt;
            pools[i].pending = masterChef.pendingSushi(i, who);

            (address lpToken, , uint256 lastRewardBlock, uint256 accSushiPerShare) = masterChef.poolInfo(i);
            IUniswapPair uniV2 = IUniswapPair(lpToken);
            pools[i].totalSupply = uniV2.balanceOf(address(masterChef));
            pools[i].uniAllowance = uniV2.allowance(who, address(masterChef));
            pools[i].lastRewardBlock = lastRewardBlock;
            pools[i].accSushiPerShare = accSushiPerShare;
            pools[i].uniBalance = uniV2.balanceOf(who);
            pools[i].uniTotalSupply = uniV2.totalSupply();
            pools[i].token0rate = getETHRate(uniV2.token0());
            pools[i].token1rate = getETHRate(uniV2.token1());
            
            (uint112 reserve0, uint112 reserve1,) = uniV2.getReserves();
            pools[i].reserve0 = reserve0;
            pools[i].reserve1 = reserve1;
        }
        return (_getUserInfo(who, currency), pools);
    }
    
    function getMyInfoInUSDT() public view returns(UserInfo memory, UserPoolInfo[] memory) {
        return getUserInfo(msg.sender, 0x292c703A980fbFce4708864Ae6E8C40584DAF323);
    }
}