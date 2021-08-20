/**
 *Submitted for verification at Etherscan.io on 2021-08-20
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

interface IWXDAI {
    function deposit() external payable;
}

contract XDaiWrapper{
    
    // address public wxdai = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address public wxdai = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public minion;
    
    event WrapAndTransfer(uint amount);
    event Received(address, uint);
    
    constructor(address _minion) public
    {
        minion = _minion;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function wrapAndTransfer() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No sufficent XDAI on the smart contract");
        
        IWXDAI(wxdai).deposit{ value: balance }();
        IERC20(wxdai).transfer(minion, balance);
        
        emit WrapAndTransfer(balance);
    }
}