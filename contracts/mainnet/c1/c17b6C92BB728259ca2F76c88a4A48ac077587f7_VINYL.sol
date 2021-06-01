/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


contract VINYL {

    string  public constant name     = "Vinyl";
    string  public constant symbol   = "VINYL";
    uint8   public constant decimals = 18;
    uint256 public constant totalSupply = 5000000e18;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed src, address indexed dst, uint value);

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function transfer(address dst, uint value) external returns (bool) {
        return transferFrom(msg.sender, dst, value);
    }

    function transferFrom(address src, address dst, uint value)
        public returns (bool)
    {
        require(balanceOf[src] >= value, "VINYL/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= value, "VINYL/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], value);
        }
        balanceOf[src] = sub(balanceOf[src], value);
        balanceOf[dst] = add(balanceOf[dst], value);
        emit Transfer(src, dst, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}