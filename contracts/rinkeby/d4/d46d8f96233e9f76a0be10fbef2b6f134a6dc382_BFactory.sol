// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.4;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./BPool.sol";

contract BFactory {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    event LOG_ADMIN(
        address indexed caller,
        address indexed admin
    );

    mapping(address=>bool) private _isBPool;

    address private _admin;

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        _;
    }

    constructor() {
        _admin = msg.sender;
    }

    function getAdmin()
        external view
        returns (address)
    {
        return _admin;
    }

    function isBPool(address b)
        external view returns (bool)
    {
        return _isBPool[b];
    }

    function newBPool()
        external onlyAdmin
        returns (BPool)
    {
        BPool bpool = new BPool();
        _isBPool[address(bpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(bpool));
        bpool.setController(msg.sender);
        return bpool;
    }

    function setAdmin(address admin)
        external onlyAdmin
    {
        _admin = admin;
        emit LOG_ADMIN(msg.sender, admin);
    }

    function collect(BPool pool)
        external onlyAdmin
    {
        uint collected = IERC20(pool).balanceOf(address(this));
        bool xfer = pool.transfer(_admin, collected);
        require(xfer, "ERR_ERC20_FAILED");
    }
}