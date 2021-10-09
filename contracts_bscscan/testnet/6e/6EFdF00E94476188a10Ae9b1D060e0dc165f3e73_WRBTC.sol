// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;
interface IWrapped {
    function balanceOf(address) external returns(uint);

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../interface/IWrapped.sol";

contract WRBTC is IWrapped {
    string public name     = "Wrapped RBTC";
    string public symbol   = "WRBTC";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint) override public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    receive () external payable {
        deposit();
    }
    function deposit() override public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) override public {
        require(balanceOf[msg.sender] >= wad, "WRBTC: Balance less than wad");
        balanceOf[msg.sender] -= wad;
        (bool success, ) = msg.sender.call{value:wad, gas:23000}("");
        require(success, "WRBTC: transfer fail");
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() override public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) override public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) override public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        override public
        returns (bool)
    {
        require(balanceOf[src] >= wad, "WRBTC: Balance less than wad");

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "WRBTC: Allowance less than wad");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}