pragma solidity ^0.4.20;

/// @title kryptono exchange AirDropContract for KNOW token
/// @author Trong Cau Ta <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f682849998919597839e959b8385b6919b979f9ad895999b">[email&#160;protected]</a>>
/// For more information, please visit kryptono.exchange

/// @title ERC20
contract ERC20 {
    uint public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract AirDropContract {

    event AirDropped(address addr, uint amount);
    address public owner = 0x00a107483c8a16a58871182a48d4ba1fbbb6a64c71;

    function drop(
        address tokenAddress,
        address[] recipients,
        uint256[] amounts) public {
        require(msg.sender == owner);
        require(tokenAddress != 0x0);
        require(amounts.length == recipients.length);

        ERC20 token = ERC20(tokenAddress);

        uint balance = token.balanceOf(msg.sender);
        uint allowance = token.allowance(msg.sender, address(this));
        uint available = balance > allowance ? allowance : balance;

        for (uint i = 0; i < recipients.length; i++) {
            require(available >= amounts[i]);
            if (isQualitifiedAddress(
                recipients[i]
            )) {
                available -= amounts[i];
                require(token.transferFrom(msg.sender, recipients[i], amounts[i]));

                AirDropped(recipients[i], amounts[i]);
            }
        }
    }

    function isQualitifiedAddress(address addr)
        public
        view
        returns (bool result)
    {
        result = addr != 0x0 && addr != msg.sender && !isContract(addr);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function () payable public {
        revert();
    }
    
    // withdraw any ERC20 token in this contract to owner
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}