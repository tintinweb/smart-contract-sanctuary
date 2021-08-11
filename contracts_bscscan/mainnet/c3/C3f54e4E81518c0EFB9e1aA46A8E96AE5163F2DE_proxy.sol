/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

pragma solidity ^0.8.6;
interface Bundle {
    function getCurrentTokens() external view returns (address[] memory tokens);
    function joinPool(uint256 poolAmountOut, uint[] calldata maxAmountsIn) external;
    function totalSupply() external view returns(uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract proxy {
    address bundle;
    address dai;
    address usdc;
    address busd;
    address usdt;
    uint256[] amounts;
    constructor(address _bundle, address _busd, address _usdt, address _usdc, address _dai) public {
        bundle = _bundle;
        busd = _busd;
        dai = _dai;
        usdt = _usdt;
        usdc = _usdc;
    }

    function mint(uint256 amountOut) public {
        IERC20(busd).approve(bundle, IERC20(busd).balanceOf(address(this)));
        IERC20(dai).approve(bundle, IERC20(dai).balanceOf(address(this)));
        IERC20(usdc).approve(bundle, IERC20(usdc).balanceOf(address(this)));
        IERC20(usdt).approve(bundle, IERC20(usdt).balanceOf(address(this)));
        amounts = [IERC20(usdt).balanceOf(address(this)),IERC20(usdc).balanceOf(address(this)),IERC20(dai).balanceOf(address(this)),IERC20(busd).balanceOf(address(this))];
        Bundle(bundle).joinPool(amountOut, amounts);
        IERC20(bundle).transfer(msg.sender, IERC20(bundle).balanceOf(address(this)));
    }
}