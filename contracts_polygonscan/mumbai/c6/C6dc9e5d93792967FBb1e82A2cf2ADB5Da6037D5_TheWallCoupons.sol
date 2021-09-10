/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "Context.sol";
import "SafeMath.sol";
import "Address.sol";


abstract contract ERC223ReceivingContract
{
    function tokenFallback(address sender, uint amount, bytes memory data) public virtual;
}


contract TheWallCoupons is Context
{
    using SafeMath for uint256;
    using Address for address;

    string public standard='Token 0.1';
    string public name='TheWall';
    string public symbol='TWC';
    uint8 public decimals=0;
    
    event Transfer(address indexed sender, address indexed receiver, uint256 amount, bytes data);

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    address private _thewallusers;

    function setTheWallUsers(address thewallusers) public
    {
        require(thewallusers != address(0), "TheWallCoupons: non-zero address is required");
        require(_thewallusers == address(0), "TheWallCoupons: _thewallusers can be initialized only once");
        _thewallusers = thewallusers;
    }

    modifier onlyTheWallUsers()
    {
        require(_msgSender() == _thewallusers, "TheWallCoupons: can be called from _theWallusers only");
        _;
    }

    function transfer(address receiver, uint256 amount, bytes memory data) public returns(bool)
    {
        _transfer(_msgSender(), receiver, amount, data);
        return true;
    }
    
    function transfer(address receiver, uint256 amount) public returns(bool)
    {
        bytes memory empty = hex"00000000";
         _transfer(_msgSender(), receiver, amount, empty);
         return true;
    }

    function _transfer(address sender, address receiver, uint amount, bytes memory data) internal
    {
        require(receiver != address(0), "TheWallCoupons: Transfer to zero-address is forbidden");

        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[receiver] = balanceOf[receiver].add(amount);
        
        if (receiver.isContract())
        {
            ERC223ReceivingContract r = ERC223ReceivingContract(receiver);
            r.tokenFallback(sender, amount, data);
        }
        emit Transfer(sender, receiver, amount, data);
    }

    function _mint(address account, uint256 amount) onlyTheWallUsers public
    {
        require(account != address(0), "TheWallCoupons: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(address(0), account, amount, empty);
    }

    function _burn(address account, uint256 amount) onlyTheWallUsers public
    {
        require(account != address(0), "TheWallCoupons: burn from the zero address");

        balanceOf[account] = balanceOf[account].sub(amount, "TheWallCoupons: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(account, address(0), amount, empty);
    }
}