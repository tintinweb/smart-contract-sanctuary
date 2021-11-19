/**
 *Submitted for verification at Etherscan.io on 2021-11-19
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
    
    erc20 constant eurs = erc20(0xdB25f211AB05b1c97D595516F45794528a807ad8);
    erc20 constant ibeur = erc20(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27);
    
    cy20 constant cy_eurs = cy20(0xA8caeA564811af0e92b1E044f3eDd18Fa9a73E4F);
    cy20 constant ib_eur = cy20(0x00e5c0774A5F065c285068170b20393925C84BF3);
    
    uint constant decimals = 10**(18-2);
    
    bool public breaker = false;
    
    constructor() {
        erc20(eurs).approve(address(cy_eurs), type(uint).max);
        erc20(ibeur).approve(address(ib_eur), type(uint).max);
    }
    
    function buy(uint amount) external returns (bool) {
        _safeTransferFrom(address(eurs), msg.sender, address(this), amount);
        require(cy_eurs.mint(amount) == 0, "ib: supply failed");
        uint _out = amount*decimals;
        require(ib_eur.borrow(_out) == 0, 'ib: borrow failed');
        _safeTransfer(address(ibeur), msg.sender, _out);
        return true;
    }
    
    function sell(uint amount) external returns (bool) {
        uint _out = amount / decimals;
        _safeTransferFrom(address(ibeur), msg.sender, address(this), amount);
        require(cy_eurs.redeemUnderlying(_out) == 0, "ib: supply failed");
        require(ib_eur.repayBorrow(amount) == 0, 'ib: repay failed');
        _safeTransfer(address(eurs), msg.sender, _out);
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