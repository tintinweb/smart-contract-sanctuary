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

import "./thewall.sol";


contract TheWallCryptaur is Ownable, IERC721Receiver
{
    using SafeMath for uint256;
    using Address for address;

    string public standard='Token 0.1';
    string public name='TheWallCryptaur';
    string public symbol='CTWC';
    uint8  public decimals=0;
    
    event Transfer(address indexed sender, address indexed receiver, uint256 amount, bytes data);
    event Transfer(address indexed sender, address indexed receiver, uint256 amount);
    event BordersChanged(int256 lowBorder, int256 highBorder);

    mapping(address => uint256) public balanceOf;
    uint256 public  totalSupply;
    int256  public  lowBorder;
    int256  public  highBorder;
    TheWall private _thewall;

    constructor(address payable thewall) Ownable()
    {
        _thewall = TheWall(thewall);
        setBorders(480, 500);
        mint(_msgSender(), 1000000);
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) public view override returns (bytes4)
    {
        require(_msgSender() == address(_thewall), "TheWallCryptaur: can receive TheWall Global tokens only");
        return this.onERC721Received.selector;
    }

    function setBorders(int256 l, int256 h) onlyOwner public
    {
        require(l > 0, "TheWallCryptaur: Borders must be positive");
        require(h >= l, "TheWallCryptaur: High border must be higher or equal than low border");
        lowBorder = l;
        highBorder = h;
        emit BordersChanged(l, h);
    }

    function isInBorders(int256 v) view public returns (bool)
    {
        int256 av = v;
        if (av < 0)
        {
            av = -v;
        }
        return av >= lowBorder || av <= highBorder;
    }

    function create(int256 x, int256 y, uint256 clusterId, address payable referrerCandidate, uint256 nonce, bytes memory content) public returns (uint256)
    {
        require(isInBorders(x) && isInBorders(y), "TheWallCryptaur: Area must be in borders");
        _burn(_msgSender(), 1);
        uint256 areaId = _thewall.create(x, y, clusterId, referrerCandidate, nonce, content);
        _thewall.safeTransferFrom(address(this), _msgSender(), areaId);
        return areaId;
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
        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[receiver] = balanceOf[receiver].add(amount);
        
        if (receiver.isContract())
        {
            ERC223ReceivingContract r = ERC223ReceivingContract(receiver);
            r.tokenFallback(sender, amount, data);
        }
        emit Transfer(sender, receiver, amount, data);
        emit Transfer(sender, receiver, amount);
    }

    function mint(address account, uint256 amount) onlyOwner public
    {
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(address(0), account, amount, empty);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal
    {
        balanceOf[account] = balanceOf[account].sub(amount, "TheWallCryptaur: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(account, address(0), amount, empty);
        emit Transfer(account, address(0), amount);
    }
    
    function finishMe() onlyOwner public
    {
        selfdestruct(payable(_msgSender()));
    }
}