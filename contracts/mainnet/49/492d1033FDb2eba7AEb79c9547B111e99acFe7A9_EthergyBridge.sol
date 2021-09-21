/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);
}

interface IXDaiBridge {
    function relayTokens(address _receiver, uint256 _amount) external;
}

interface IOmniBridge {
    function relayTokens(address token, address _receiver, uint256 _value) external;
}

interface IWETH9 {
    
    function deposit() external payable;
}

contract EthergyBridge{
    
    address public xdaiBridge = 0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016;
    address public omniBridge = 0x88ad09518695c6c3712AC10a214bE5109a655671;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public dao; // target address on xDai net - should be minion address
    
    event BridgeXDai(address target, uint amount);
    event BridgeWETH(address target, uint amount);
    event WrapETH(uint amount);
    
    constructor(address _dao) public
    {
        dao = _dao;
    }

    function bridgeXDai() external {
        uint256 balance = IERC20(dai).balanceOf(address(this));
        require(balance > 0, "No sufficent DAI on the smart contract");
        IERC20(dai).approve(xdaiBridge, balance);
        IXDaiBridge(xdaiBridge).relayTokens(dao, balance);
        
        emit BridgeXDai(dao, balance);
    }
    
    function bridgeWETH() external {
        uint256 balance = IERC20(weth).balanceOf(address(this));
        require(balance > 0, "No sufficent WETH on the smart contract");
        IERC20(weth).approve(omniBridge, balance);
        IOmniBridge(omniBridge).relayTokens(weth, dao, balance);
        
        emit BridgeWETH(dao, balance);
    }
    
    function wrapEth() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No sufficent ETH on the smart contract");
        IWETH9(weth).deposit{value: balance}();
        
        emit WrapETH(balance);
    }
}