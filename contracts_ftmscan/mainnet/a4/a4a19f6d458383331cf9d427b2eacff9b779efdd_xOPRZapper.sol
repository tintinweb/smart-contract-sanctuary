/**
 *Submitted for verification at FtmScan.com on 2022-01-13
*/

pragma solidity 0.6.12;

//SPDX-License-Identifier: Unlisence 

interface IxOPR {
  function enter(uint256 _amount) external;
  function OPRforxOPR(uint256 _oprAmount) external view returns (uint256);
}

interface IGenericRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IGenericRouter02 is IGenericRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWrappedFantom {
  // deposit wraps received FTM tokens as wFTM in 1:1 ratio by minting
  // the received amount of FTMs in wFTM on the sender's address.
  function deposit() external payable returns (uint256);
}

contract xOPRZapper {
  address private constant wFTMa = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  IWrappedFantom private constant wFTMc = IWrappedFantom(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
  IERC20 private constant wFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

  address private constant xOPR = 0x9E7f8D1E52630d46e8749C8f81e91D4e934f3589;
  IxOPR private constant xOPR_INTERFACE = IxOPR(xOPR);
  IERC20 private constant xOPR_IERC20 = IERC20(xOPR);

  address private constant MULTISIG_TREASURY = 0x87f385d152944689f92Ed523e9e5E9Bd58Ea62ef;

  address private constant OPR_ADDRESS = 0x16dbD24713C1E6209142BCFEED8C170D83f84924;
  IERC20 private constant OPR_TOKEN = IERC20(OPR_ADDRESS);

  address private constant SPIRIT_ROUTER = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;
  IGenericRouter02 private constant SPIRIT_INTERFACE = IGenericRouter02(SPIRIT_ROUTER);

  function zapIn() public payable {
    uint256 input = msg.value;
    uint256 fee = input/100.000; //1% fee on all deposits.
    uint256 leftover = input-fee;
    address toSend = msg.sender;

    // paying the fee, wrapped into wFTM, and sent to our multisig address //
    wFTMc.deposit{value: fee}();
    wFTM.transfer(MULTISIG_TREASURY, wFTM.balanceOf(address(this)));

    // swapping on spiritswap for OPR //
    address[] memory _oprPath;
    _oprPath = new address[](2);
    _oprPath[0] = wFTMa;
    _oprPath[1] = OPR_ADDRESS;
    IGenericRouter02(SPIRIT_ROUTER).swapExactETHForTokens{value: leftover}(0, _oprPath, address(this), block.timestamp);
    // depositing for xOPR //
    if (OPR_TOKEN.allowance(address(this),xOPR) < 115792089237316195423570985008687907853269984665640564039457584007913129639935) {
      OPR_TOKEN.approve(xOPR,115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }
    xOPR_INTERFACE.enter(OPR_TOKEN.balanceOf(address(this)));
    // sending xOPR to sendee //
    xOPR_IERC20.transfer(toSend,xOPR_IERC20.balanceOf(address(this)));
  }
}