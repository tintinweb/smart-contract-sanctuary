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

import "ReentrancyGuard.sol";
import "thewall.sol";


contract TheWallDaily is Context, IERC721Receiver, ReentrancyGuard
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Address for address;
    using Address for address payable;

    event ContractDeployed(uint256 constLiquidity, uint256 maximumAreasInPool, uint256 rentDurationBlocks);
    event Deposited(address indexed provider, uint256 indexed areaId, int256 x, int256 y, uint256 amountLPT);
    event Withdrawn(uint256 indexed areaId, uint256 withdrawWei);
    event WithdrawnProfit(uint256 indexed areaId, uint256 withdrawWei, uint256 newAmountLPT);
    event Rented(address indexed tenant, uint256 indexed areaId, uint256 blockFinish);

    TheWall     public _thewall;
    TheWallCore public _thewallcore;

    uint256     public _totalSupplyLPT;
    uint256     public _areasInPool;

    struct Area
    {
        uint256 amountLPT;
        address provider;
        address tenant;
        uint256 blockFinish;
    }
    mapping (uint256 => Area) public _pool;
    mapping (address => uint256) public _balanceOf;

    uint256 public constant constLiquidity = 1 ether / 10;
    uint256 public constant maximumAreasInPool = 1000000;
    uint256 public constant rentDurationBlocks = 48 hours / 2;

    constructor(address payable thewall, address thewallcore)
    {
        _thewall = TheWall(thewall);
        _thewallcore = TheWallCore(thewallcore);
        _thewallcore.setNickname("The Wall Daily Protocol V1");
        _thewallcore.setAvatar('\x06\x01\x55\x12\x20\x68\x8d\x76\x62\xb6\x9f\xc9\x1b\x11\x3f\x3b\x3d\xf8\xbf\xf2\xd5\x51\x49\xb6\x0c\x2c\x8b\xe2\xfe\x3c\x5d\x8e\xe2\x34\x93\x87\xdc');
        emit ContractDeployed(constLiquidity, maximumAreasInPool, rentDurationBlocks);
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) public view override returns (bytes4)
    {
        require(_msgSender() == address(_thewall), "TheWallDaily: can receive TheWall Global tokens only");
        return this.onERC721Received.selector;
    }

    function deposit(int256 x, int256 y) public payable
    {
        require(_areasInPool < maximumAreasInPool, "TheWallDaily: No space in pool");
        require(msg.value == constLiquidity, "TheWallDaily: invalid amount deposited");
        uint256 areaId = _thewallcore._areaOnTheWall(x, y);
        require(areaId != 0, "TheWallDaily: Area not found");

        Area memory area;
        area.amountLPT =
            (_areasInPool == 0) ?
                (2**256 - 1) / maximumAreasInPool.mul(constLiquidity) :
                _totalSupplyLPT.mul(constLiquidity).div(address(this).balance.sub(constLiquidity));
        require(area.amountLPT != 0, "TheWallDaily: Precision error");
        area.provider = _msgSender();
        _pool[areaId] = area;
        _areasInPool = _areasInPool.add(1);

        _totalSupplyLPT = _totalSupplyLPT.add(area.amountLPT);
        _balanceOf[area.provider] = _balanceOf[area.provider].add(area.amountLPT);

        _thewall.safeTransferFrom(area.provider, address(this), areaId);
        emit Deposited(area.provider, areaId, x, y, area.amountLPT);
    }

    function tenant(Area memory area) public view returns(address)
    {
        return (area.blockFinish > block.number) ? area.tenant : address(0);
    }

    function withdraw(uint256 areaId) public nonReentrant
    {
        Area storage area = _pool[areaId];
        require(tenant(area) == address(0), "TheWallDaily: Area is busy");
        require(area.provider != address(0), "TheWallDaily: No area found");
        require(area.provider == _msgSender(), "TheWallDaily: No permissions");
        _thewall.safeTransferFrom(address(this), area.provider, areaId);
        uint256 withdrawWei = address(this).balance.mul(area.amountLPT).div(_totalSupplyLPT);
        _areasInPool = _areasInPool.sub(1);
        _totalSupplyLPT = _totalSupplyLPT.sub(area.amountLPT);
        _balanceOf[area.provider] = _balanceOf[area.provider].sub(area.amountLPT);
        payable(area.provider).sendValue(withdrawWei);
        delete _pool[areaId];
        emit Withdrawn(areaId, withdrawWei);
    }

    function withdrawProfit(uint256 areaId) public nonReentrant
    {
        Area storage area = _pool[areaId];
        require(area.provider != address(0), "TheWallDaily: No area found");
        require(area.provider == _msgSender(), "TheWallDaily: No permissions");
        uint256 withdrawWei = address(this).balance * area.amountLPT / _totalSupplyLPT;
        uint256 newAmountLPT = area.amountLPT * constLiquidity / withdrawWei;
        uint256 deltaLPT = area.amountLPT.sub(newAmountLPT);
        _balanceOf[area.provider] = _balanceOf[area.provider].sub(deltaLPT);
        _totalSupplyLPT = _totalSupplyLPT.sub(deltaLPT);
        area.amountLPT = newAmountLPT;
        withdrawWei = withdrawWei.sub(constLiquidity);
        payable(area.provider).sendValue(withdrawWei);
        emit WithdrawnProfit(areaId, withdrawWei, newAmountLPT);
    }

    function setContent(uint256 areaId, bytes memory content) public payable
    {
        require(msg.value == constLiquidity, "TheWallDaily: invalid amount paid");
        Area storage area = _pool[areaId];
        require(area.provider != address(0), "TheWallDaily: No area found");
        address t = tenant(area);
        require(t == address(0) || t == _msgSender(), "TheWallDaily: Area is busy");
        area.tenant = _msgSender();
        area.blockFinish = block.number + rentDurationBlocks;
        _thewall.setContent(areaId, content);
        emit Rented(area.tenant, areaId, area.blockFinish);
    }
}