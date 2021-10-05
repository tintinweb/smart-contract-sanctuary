/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// WBTC-renBTC LP Farm - Polygon.Cafeswap.Finance Compounder
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

interface ISushiRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}


contract CafeSwapBTCCompounder {
    address public owner;
    IERC20 public CLP = IERC20(0x4fd19e59A1041e82aCB3Ecc6773EE99913076868);
    IERC20 public renBTC = IERC20(0xDBf31dF14B66535aF65AaC99C32e9eA844e14501);
    IERC20 public WBTC = IERC20(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
    IERC20 public pBREW = IERC20(0xb5106A3277718eCaD2F20aB6b86Ce0Fee7A21F09);
    IERC20 public WETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    ICafeMasterChef public CafeChef = ICafeMasterChef(0xca2DeAc853225f5a4dfC809Ae0B7c6e39104fCe5);
    ICafeRouter public CafeRouter = ICafeRouter(0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc);
    ISushiRouter public SushiRouter = ISushiRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    uint constant TWENTY_MINUTES = 1200;
    uint256 public profits;

    address constant public admin = 0xeeee7369a6BcC3Ff891ba6508665184E692f8963;

    constructor() {
        profits = 0;
        owner = msg.sender;
        CLP.approve(address(CafeChef), 2**256 - 1);
        pBREW.approve(address(CafeRouter), 2**256 - 1);
        WBTC.approve(address(CafeRouter), 2**256 - 1);
        WBTC.approve(address(SushiRouter), 2**256 - 1);
        renBTC.approve(address(CafeRouter), 2**256 - 1);
        WETH.approve(address(CafeRouter), 2**256 - 1);
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
        CafeChef.deposit(16,0);
    }

    function depositCLP() public onlyOwner {
        require(CLP.balanceOf(address(this)) > 0, "CafeSwapCompounder: No CLP tokens to deposit");
        CafeChef.deposit(16,CLP.balanceOf(address(this)));
    }

    function emergencyWithdrawCLP() public onlyOwner {
        harvest();
        CafeChef.emergencyWithdraw(16);
        CLP.transfer(owner, CLP.balanceOf(address(this)));
        pBREW.transfer(owner, pBREW.balanceOf(address(this)));
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

        _swapForWBTC();

        uint256 _balanceA = WBTC.balanceOf(address(this));
        profits += _balanceA;

        if (_balanceA > 0) {
            _swapHalfWBTCforRen();
        }

        uint256 aBalance = WBTC.balanceOf(address(this));
        uint256 bBalance = renBTC.balanceOf(address(this));
        
        if (aBalance > 0 && bBalance > 0) {
            CafeRouter.addLiquidity(
                address(WBTC), address(renBTC),
                aBalance, bBalance,
                0, 0,
                address(this),
                (block.timestamp + TWENTY_MINUTES)
            );
        }

        CafeChef.deposit(16, CLP.balanceOf(address(this)));

    }
    function _swapHalfWBTCforRen() internal {
        address[] memory path = new address[](2);
        path[0] = address(WBTC);
        path[1] = address(renBTC);
        
        SushiRouter.swapExactTokensForTokens(
            (WBTC.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function _swapForWBTC() internal {
        address[] memory path = new address[](3);
        path[0] = address(pBREW);
        path[1] = address(WETH);
        path[2] = address(WBTC);
        
        CafeRouter.swapExactTokensForTokens(
            (pBREW.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "CafeSwapCompounder: external call failed");
        return result;
    }

}