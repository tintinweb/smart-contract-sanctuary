/**
 *Submitted for verification at polygonscan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ITowerMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

interface IFireBirdRouter {
    function swapExactTokensForTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint8[] calldata dexIds, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address pair, address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

contract TOWERFINANCE_INTERFACE {
    // instances
    address public owner;
    IERC20 public FLP = IERC20(0xD70f14f13ef3590e537bBd225754248965A3593c);
    IERC20 public IVORY = IERC20(0x88a3aCAc5C48F93121d4d7771A068A1FCDE078BC);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public TOWER = IERC20(0x8201532917e55bA29674Ef4E88FFe0b775f1BaE8);
    ITowerMasterChef public MasterChef = ITowerMasterChef(0x4696B1A198407BFb8bB8dd59030Bf30FaC258f1D);
    IFireBirdRouter public Router = IFireBirdRouter(0xb31D1B1eA48cE4Bf10ed697d44B747287E785Ad4);

    uint constant TWENTY_MINUTES = 1200;
    address constant public admin = 0xeeee7369a6BcC3Ff891ba6508665184E692f8963;

    constructor() {
        owner = msg.sender;
        FLP.approve(address(MasterChef), 2**256 - 1);
        USDC.approve(address(Router), 2**256 - 1);
        TOWER.approve(address(Router), 2**256 - 1);
        IVORY.approve(address(Router), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "TOWER: caller is not the owner");
        _;
    }

    modifier onlyAdmin {
        require(owner == msg.sender || admin == msg.sender, "TOWER: caller is not the owner nor an admin address");
        _;
    }

    function deposit() public onlyOwner {
        require(FLP.balanceOf(address(this)) > 0, "TOWER: nothing to deposit");
        MasterChef.deposit(0,FLP.balanceOf(address(this)));
    }

    function harvest() public onlyOwner {
        MasterChef.deposit(0,0);
    }

    function harvestToOwner() public onlyOwner {
        harvest();
        IVORY.transfer(owner, IVORY.balanceOf(address(this)));
    }

    function autosell() external onlyAdmin {
        address[] memory path = new address[](1);
        path[0] = 0x10995233Ef7b3abd1a2706a86FFeA456ebae8796;
        uint8[] memory zero = new uint8[](1);
        zero[0] = 0;

        harvest();

        Router.swapExactTokensForTokens(
            address(IVORY),
            address(USDC),
            IVORY.balanceOf(address(this)),
            0,
            path,
            zero,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );

        USDC.transfer(owner, USDC.balanceOf(address(this)));
    }

    function emergencyWithdraw() public onlyOwner {
        harvestToOwner();
        MasterChef.emergencyWithdraw(0);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "GFICompounder: external call failed");
        return result;
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

}