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

import "Address.sol";
import "Ownable.sol";
import "IERC20.sol";
import "thewall.sol";

contract Treasure is Ownable
{
    event TreasureSet(address treasureContract, uint256 treasureAmount);
    event TreasureHidden(bytes32 hash);
    event TreasureFound(int256 [] coords);
    event Rewarded(address indexed user, uint256 indexed tokenId, uint256 amount);

    bytes32     public _hash;
    TheWall     public _thewall;
    TheWallCore public _thewallcore;
    IERC20      public _treasureContract;
    uint256     public _treasuredAmount;
    
    constructor(address payable thewall, address thewallcore, address treasureContract, uint256 treasureAmount)
    {
        _thewall = TheWall(thewall);
        _thewallcore = TheWallCore(thewallcore);
        setTreasure(treasureContract, treasureAmount);
    }
    
    function setTreasure(address treasureContract, uint256 treasureAmount) onlyOwner public
    {
        _treasureContract = IERC20(treasureContract);
        _treasuredAmount = treasureAmount;
        emit TreasureSet(treasureContract, treasureAmount);
    }
    
    function hideTreasure(bytes32 hash) onlyOwner public
    {
        _hash = hash;
        emit TreasureHidden(hash);
    }
    
    function findTreasure(int256 [] memory coords, uint256 salt) onlyOwner public
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(coords)), salt));
        require(hash == _hash, "Treasure: Invalid data");
        emit TreasureFound(coords);
        delete _hash;

        for(uint i = 0; i < coords.length;)
        {
            int256 x = coords[i++];
            int256 y = coords[i++];
            uint256 tokenId = _thewallcore._areaOnTheWall(x, y);
            if (tokenId != 0)
            {
                address user = _thewall.ownerOf(tokenId);
                if (_treasureContract.transfer(user, _treasuredAmount))
                {
                    emit Rewarded(user, tokenId, _treasuredAmount);
                }
            }
        }
    }
    
    function gameOver() onlyOwner public
    {
        uint256 balance = _treasureContract.balanceOf(address(this));
        if (balance > 0)
        {
            _treasureContract.transfer(_msgSender(), balance);
        }
        selfdestruct(payable(_msgSender()));
    }
}