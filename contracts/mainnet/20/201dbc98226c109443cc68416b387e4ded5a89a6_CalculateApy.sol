pragma solidity 0.5.15;

interface IUniswapRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0);
        z = x / y;
    }
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IYAMIncentivizer {
    function DURATION() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function uni_lp() external view returns (IERC20);
}

interface IUniswap {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract CalculateApy {
    using SafeMath for uint256;
    bool private initialized;

    address public owner;
    address private uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // Stable coin: USDx.
    address private reserveAddress = 0xeb269732ab75A6fD61Ea60b06fE994cD32a83549;
    address private yuanAddress;

    mapping(address => address[]) poolPath;
    uint256 constant BASE = 10 ** 18;
    uint256 constant year_seconds = 3600 * 24 * 365;

    constructor(address _yuanAddress) public {
        initialize(_yuanAddress);
    }

    function initialize(address _yuanAddress) public {
        require(!initialized, "initialize: Already initialized!");
        yuanAddress = _yuanAddress;
        owner = msg.sender;
        initialized = true;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y) / BASE;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).div(y);
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).add(y.sub(1)).div(y);
    }

    function getTokenPrice(address _token) internal view returns (uint256) {
        uint256[] memory res = IUniswapRouter(uniRouter).getAmountsOut(
            BASE,
            poolPath[_token]
        );
        uint256 price = res[res.length - 1];
        return price;
    }

    function setPoolPath(address[] calldata _path) external {
        require(msg.sender == owner, "setPath: Permission denied!");
        poolPath[_path[0]] = _path;
    }

    function setYuanAddress(address _token) external {
        require(msg.sender == owner, "setYuanAddress: Permission denied!");
        yuanAddress = _token;
    }

    function setReserveAddress(address _token) external {
        require(msg.sender == owner, "setReserveAddress: Permission denied!");
        reserveAddress = _token;
    }

    function getUniAddress(address _pool) public view returns (address) {
        IYAMIncentivizer _contract = IYAMIncentivizer(_pool);
        IERC20 uniswapFactory = _contract.uni_lp();
        return address(uniswapFactory);
    }

    function getLpPrice(address _uniPool)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address
        )
    {
        address token0 = IUniswap(_uniPool).token0();
        address token1 = IUniswap(_uniPool).token1();
        uint256 totalValue;
        address token;
        if (token0 == reserveAddress || token1 == reserveAddress) {
            if (token0 == reserveAddress) {
                totalValue = (IERC20(token0)).balanceOf(_uniPool) << 1;
            } else {
                totalValue = (IERC20(token1)).balanceOf(_uniPool) << 1;
            }
        } else {
            if (poolPath[token0].length != 0) {
                token = token0;
            } else if (poolPath[token1].length != 0) {
                token = token1;
            } else {
                return (0, 0, 0, token0, token1);
            }
            uint256 tokenPrice = getTokenPrice(token);
            uint256 _totalSupply = (IERC20(token)).balanceOf(_uniPool) << 1;
            totalValue = rmul(_totalSupply, tokenPrice);
        }
        uint256 lpUniBalance = (IERC20(_uniPool)).totalSupply();
        uint256 lpPrice = rdiv(totalValue, lpUniBalance);
        return (lpPrice, totalValue, lpUniBalance, token0, token1);
    }

    function calcuateApy(address _pool)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IYAMIncentivizer totalIncentive_contract = IYAMIncentivizer(_pool);
        uint256 yuanPrice = getTokenPrice(yuanAddress);
        address uniPool = getUniAddress(_pool);
        (uint256 lpPrice, , , , ) = getLpPrice(uniPool);
        uint256 rewardRate = totalIncentive_contract.rewardRate();
        uint256 lpStakingBalance = (IERC20(uniPool)).balanceOf(_pool);
        if (lpStakingBalance == 0) {
            return (uint256(0), uint256(0), uint256(0));
        }
        uint256 apy = rdiv(
            rmul(rewardRate, yuanPrice),
            rmul(lpStakingBalance, lpPrice)
        );
        return (rmul(apy, year_seconds), rewardRate, yuanPrice);
    }
}