/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0
// @MRFCiki

pragma solidity ^0.8.0;


interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

interface IPancakeswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract EcekEcekTaiKoceng {

    address owner = address(0x9D6aCbaDdD6EB12968Cf38A20922491C88059fe3); //your address
    // address router = address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
    constructor() {}
    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdrawETH() public payable {
        require(msg.sender == owner);
        uint256 etherBalance = address(this).balance;
        payable(owner).transfer(etherBalance);
    }


    function retrieveERC20(address _token, uint _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function ApproveERC20(address _token, address router) external onlyOwner {
        IERC20(_token).approve(router, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }
    function swapExactETHForTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external payable onlyOwner {
        IPancakeswapV2Router02(router).swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            deadline
        );
    }
    
    
    function swapExactTokensForETH(
        address router,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external onlyOwner {

        uint amountIn = IERC20(path[0]).balanceOf(address(this));
        //IERC20(path[0]).approve(address(router), amountIn);
        IPancakeswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
     }


    function getRegoTaikoceng(address router, address tokenAddress, address bnbaddress) public view returns (uint) {
    	uint amountIn = getAmountIn(tokenAddress);
        address[] memory _path = new address[](2);
        _path[0] = tokenAddress;
        _path[1] = bnbaddress;
        uint[] memory _amts = IPancakeswapV2Router02(router).getAmountsOut(amountIn, _path);
        return _amts[1];
    }

    
    function getAmountIn(address tokenAddress) public view returns (uint) {
    	uint decimals = IERC20(tokenAddress).decimals();
    	uint amountIn = (10 ** decimals);
    	return amountIn;
    }

    function getDecimals(address tokenAddress) public view returns (uint) {
    	uint decimals = IERC20(tokenAddress).decimals();
    	return decimals;
    }
    
}