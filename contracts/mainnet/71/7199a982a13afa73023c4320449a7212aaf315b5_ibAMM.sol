/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface erc20 {
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface cy20 {
    function redeemUnderlying(uint) external returns (uint);
    function mint(uint) external returns (uint);
    function borrow(uint) external returns (uint);
    function repayBorrow(uint) external returns (uint);
}

interface registry {
    function cy(address) external view returns (address);
    function price(address) external view returns (uint);
}

contract ibAMM {
    
    registry constant ff = registry(0x5C08bC10F45468F18CbDC65454Cbd1dd2cB1Ac65);
    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    cy20 constant cyDAI = cy20(0x8e595470Ed749b85C6F7669de83EAe304C2ec68F);
    uint constant fee = 995;
    uint constant base = 1000;
    
    constructor() {
        erc20(dai).approve(address(cyDAI), type(uint).max);
    }
    
    function quote_sell(address from, uint amount) external view returns (uint) {
        return ff.price(from) * (amount * fee / base) / 1e18;
    }
    
    function quote_buy(address to, uint amount) external view returns (uint) {
        return (amount * fee / base) * 1e18 / ff.price(to);
    }
    
    function buy(address to, uint amount, uint minOut) external returns (bool) {
        uint _out = (amount * fee / base) * 1e18 / ff.price(to);
        require(_out >= minOut);
        _safeTransferFrom(dai, msg.sender, address(this), amount);
        require(cyDAI.mint(amount) == 0, "ib: supply failed");
        require(cy20(ff.cy(to)).borrow(_out) == 0, 'ib: borrow failed');
        _safeTransfer(to, msg.sender, _out);
        return true;
    }
    
    function sell(address from, uint amount, uint minOut) external returns (bool) {
        uint _out = ff.price(from) * (amount * fee / base) / 1e18;
        require(_out >= minOut);
        _safeTransferFrom(from, msg.sender, address(this), amount);
        require(cyDAI.redeemUnderlying(_out) == 0, "ib: supply failed");
        require(cy20(ff.cy(from)).repayBorrow(amount) == 0, 'ib: repay failed');
        _safeTransfer(dai, msg.sender, _out);
        return true;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}