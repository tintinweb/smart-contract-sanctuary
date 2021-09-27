/**
 *Submitted for verification at polygonscan.com on 2021-09-27
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

interface ICafeMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

interface ICafeRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IIronSwap {
    function swap(uint8 fromIndex, uint8 toIndex, uint256 inAmount, uint256 minOutAmount, uint256 deadline) external returns (uint256);
}


contract CafeSwapStableCompounder {
    address public owner;
    IERC20 public CLP = IERC20(0x815c2D1894Daf25935fa909bE35Ee1Fed67b2B97);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    IERC20 public pBREW = IERC20(0xb5106A3277718eCaD2F20aB6b86Ce0Fee7A21F09);
    IERC20 public WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    ICafeMasterChef public CafeChef = ICafeMasterChef(0xca2DeAc853225f5a4dfC809Ae0B7c6e39104fCe5);
    ICafeRouter public CafeRouter = ICafeRouter(0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc);
    IIronSwap public IronSwap = IIronSwap(0x837503e8A8753ae17fB8C8151B8e6f586defCb57);

    uint constant TWENTY_MINUTES = 1200;
    uint256 public profits;

    address constant public admin = 0xeeee7369a6BcC3Ff891ba6508665184E692f8963;

    constructor() {
        profits = 0;
        owner = msg.sender;
        CLP.approve(address(CafeChef), 2**256 - 1);
        pBREW.approve(address(CafeRouter), 2**256 - 1);
        USDC.approve(address(CafeRouter), 2**256 - 1);
        USDC.approve(address(IronSwap), 2**256 - 1);
        DAI.approve(address(CafeRouter), 2**256 - 1);
        WMATIC.approve(address(CafeRouter), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "CafeSwapCompounder: caller is not the owner");
        _;
    }

    modifier onlyAdmin {
        require(owner == msg.sender || admin == msg.sender, "CafeSwapCompounder: caller is not the owner nor an admin address");
        _;
    }

    function harvest() internal {
        CafeChef.deposit(5,0);
    }

    function depositCLP() public onlyOwner {
        require(CLP.balanceOf(address(this)) > 0, "CafeSwapCompounder: No CLP tokens to deposit");
        CafeChef.deposit(5,CLP.balanceOf(address(this)));
    }

    function emergencyWithdrawCLP() public onlyOwner {
        harvest();
        CafeChef.emergencyWithdraw(5);
        CLP.transfer(owner, CLP.balanceOf(address(this)));
    }

    function harvestToOwner() public onlyOwner {
        harvest();
        pBREW.transfer(owner, pBREW.balanceOf(address(this)));
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function compound() external onlyAdmin() {
        harvest();

        _swapForUSDC();

        uint256 _balanceA = USDC.balanceOf(address(this));
        profits += _balanceA;

        if (_balanceA > 0) {
            _swapHalfUSDCForDAI();
        }

        uint256 aBalance = USDC.balanceOf(address(this));
        uint256 bBalance = DAI.balanceOf(address(this));
        
        if (aBalance > 0 && bBalance > 0) {
            CafeRouter.addLiquidity(
                address(USDC), address(DAI),
                aBalance, bBalance,
                0, 0,
                address(this),
                block.timestamp + TWENTY_MINUTES
            );
        }

        CafeChef.deposit(5, CLP.balanceOf(address(this)));

    }

    function _swapForUSDC() internal {
        address[] memory path = new address[](3);
        path[0] = address(pBREW);
        path[1] = address(WMATIC);
        path[2] = address(USDC);

        CafeRouter.swapExactTokensForTokens(
            (pBREW.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function _swapHalfUSDCForDAI() internal {
        IronSwap.swap(0, 2, (USDC.balanceOf(address(this))/2), 0, block.timestamp + TWENTY_MINUTES);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "CafeSwapCompounder: external call failed");
        return result;
    }

}