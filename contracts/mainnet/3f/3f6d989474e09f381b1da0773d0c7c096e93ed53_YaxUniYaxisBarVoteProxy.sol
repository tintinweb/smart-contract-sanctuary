/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

interface IVoteProxy {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _voter) external view returns (uint256);
}

interface IMasterChef {
    function userInfo(uint256, address)
    external
    view
    returns (uint256, uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract YaxUniVoteProxy is IVoteProxy {
    // ETH/YAX token
    IUniswapV2Pair public constant yaxEthUniswapV2Pair = IUniswapV2Pair(
        0x1107B6081231d7F256269aD014bF92E041cb08df
    );
    // YAX token
    IERC20 public constant yax = IERC20(
        0xb1dC9124c395c1e97773ab855d66E879f053A289
    );

    // YaxisChef contract
    IMasterChef public constant chef = IMasterChef(
        0xC330E7e73717cd13fb6bA068Ee871584Cf8A194F
    );

    // Using 9 decimals as we're square rooting the votes
    function decimals() public override virtual pure returns (uint8) {
        return uint8(9);
    }

    function totalSupply() public override virtual view returns (uint256) {
        (uint256 _yaxAmount,,) = yaxEthUniswapV2Pair.getReserves();
        return sqrt(yax.totalSupply()) + sqrt((2 * _yaxAmount * yaxEthUniswapV2Pair.balanceOf(address(chef))) / yaxEthUniswapV2Pair.totalSupply());
    }

    function balanceOf(address _voter) public override virtual view returns (uint256) {
        (uint256 _stakeAmount,) = chef.userInfo(6, _voter);
        (uint256 _yaxAmount,,) = yaxEthUniswapV2Pair.getReserves();
        return sqrt(yax.balanceOf(_voter)) + sqrt((2 * _yaxAmount * _stakeAmount) / yaxEthUniswapV2Pair.totalSupply());
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

interface IYaxisBar is IERC20 {
    function availableBalance()
    external view
    returns (uint);

}

contract YaxUniYaxisBarVoteProxy is YaxUniVoteProxy {

    IYaxisBar public constant yaxisBar = IYaxisBar(
        0xeF31Cb88048416E301Fee1eA13e7664b887BA7e8
    );

    function totalSupply() public override view returns (uint256) {
        return  super.totalSupply() + sqrt(yaxisBar.availableBalance());
    }

    function balanceOf(address _voter) public override view returns (uint256) {
        uint256 _yaxAmount = (yaxisBar.balanceOf(_voter) * yaxisBar.availableBalance()) / yaxisBar.totalSupply() ;
        return super.balanceOf(_voter) + sqrt(_yaxAmount);
    }
}