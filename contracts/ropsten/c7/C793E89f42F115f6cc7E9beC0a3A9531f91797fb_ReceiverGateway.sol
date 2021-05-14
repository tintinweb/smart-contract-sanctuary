// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
import "./Ownable.sol";

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from,address to,uint256 value ) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract ReceiverGateway is Ownable {
    event ReceiveEvent(address sendAddr, uint256 amount);
    event ExtractEvent(address ownerAddr,address token20Addr, uint256 amount);

    receive() external payable {
        emit ReceiveEvent(msg.sender, msg.value);
    }

    function extractToken(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
        emit ExtractEvent(owner(),address(0), amount);
    }

    function extractToken20(address token20Addr,uint256 amount) public onlyOwner {
        require(token20Addr!=address(0));
        require(ERC20(token20Addr).transfer(owner(), amount),"Token20 extract failed");
        emit ExtractEvent(owner(),token20Addr, amount);
    }

    
}