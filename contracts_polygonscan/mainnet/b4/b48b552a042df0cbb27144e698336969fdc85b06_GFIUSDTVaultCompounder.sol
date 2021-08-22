/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

// SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;
// Contracts needed: GravityMasterchef -> GFISWAP -> GFI LP -> Deposit into GFIMC

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IGFIRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IGFIFarmV2 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function emergencyWithdraw() external;
}

contract GFIUSDTVaultCompounder {
    address public owner;
    IERC20 public GLP = IERC20(0x42286296C3edE3f6a0ec4e687939b017408Cf321);
    IERC20 public GFI = IERC20(0x874e178A2f3f3F9d34db862453Cd756E7eAb0381);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IGFIRouter public GFIRouter = IGFIRouter(0x57dE98135e8287F163c59cA4fF45f1341b680248);
    IGFIFarmV2 public GFIFarm = IGFIFarmV2(0xe3bC11531D78Ce351Db9D2f0eC270B863FaC1C07);
    
    uint constant TWENTY_MINUTES = 1200;

    constructor() {
        owner = msg.sender;
        GLP.approve(address(GFIFarm), 2**256 - 1);
        GFI.approve(address(GFIRouter), 2**256 - 1);
        USDC.approve(address(GFIRouter), 2**256 - 1);
        USDT.approve(address(GFIRouter), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "IronVault: caller is not the owner");
        _;
    }

    function depositGLP() public onlyOwner {
        require(GLP.balanceOf(address(this)) != 0, "GFICompounder: No GLP tokens to stake");
        GFIFarm.deposit(GLP.balanceOf(address(this)));
    }

    function emergencyWithdrawFromGFarm() public onlyOwner {
        GFIFarm.emergencyWithdraw();
        GLP.transfer(owner, GLP.balanceOf(address(this)));
    }

    function claimReward() public onlyOwner {
        GFIFarm.withdraw(0);
    }

    function claimRewardToOwner() public onlyOwner {
        GFIFarm.withdraw(0);
        GFI.transfer(owner, GFI.balanceOf(address(this)));
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function compound() public onlyOwner {
        claimReward();
        swapForUSDC();
        swapForUSDT();

        GFIRouter.addLiquidity(
            address(USDC),
            address(USDT),
            USDC.balanceOf(address(this)),
            USDT.balanceOf(address(this)),
            0,
            0,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );

        GFIFarm.deposit(GLP.balanceOf(address(this)));
    }

    function swapForUSDC() public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(GFI);
        path[1] = address(USDC);

        GFIRouter.swapExactTokensForTokens(
            (GFI.balanceOf(address(this))/2),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function swapForUSDT() public onlyOwner {
        address[] memory path = new address[](3);
        path[0] = address(GFI);
        path[1] = address(USDC);
        path[1] = address(USDT);

        GFIRouter.swapExactTokensForTokens(
            (GFI.balanceOf(address(this))/2),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "IronVault: external call failed");
        return result;
    }
}