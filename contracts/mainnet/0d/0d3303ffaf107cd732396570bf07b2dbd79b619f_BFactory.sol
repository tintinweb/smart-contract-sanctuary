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

pragma solidity 0.5.12;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./BPool.sol";

contract BFactory is BBronze {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    event LOG_BLABS(
        address indexed caller,
        address indexed blabs
    );

    event LOG_RESERVES_ADDRESS(
        address indexed caller,
        address indexed reservesAddress
    );

    event LOG_ALLOW_NON_ADMIN_POOL(
        address indexed caller,
        bool allow
    );

    mapping(address=>bool) private _isBPool;

    function isBPool(address b)
        external view returns (bool)
    {
        return _isBPool[b];
    }

    function newBPool()
        external
        returns (BPool)
    {
        if (!_allowNonAdminPool) {
            require(msg.sender == _blabs);
        }
        BPool bpool = new BPool();
        _isBPool[address(bpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(bpool));
        bpool.setController(msg.sender);
        return bpool;
    }

    address private _blabs;
    address private _reservesAddress;

    bool private _allowNonAdminPool;

    constructor() public {
        _blabs = msg.sender;
        _reservesAddress = msg.sender;
        _allowNonAdminPool = false;
    }

    function getAllowNonAdminPool()
        external view
        returns (bool)
    {
        return _allowNonAdminPool;
    }

    function setAllowNonAdminPool(bool b)
        external
    {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        emit LOG_ALLOW_NON_ADMIN_POOL(msg.sender, b);
        _allowNonAdminPool = b;
    }

    function getBLabs()
        external view
        returns (address)
    {
        return _blabs;
    }

    function setBLabs(address b)
        external
    {
        require(msg.sender == _blabs);
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function getReservesAddress()
        external view
        returns (address)
    {
        return _reservesAddress;
    }

    function setReservesAddress(address a)
        external
    {
        require(msg.sender == _blabs);
        emit LOG_RESERVES_ADDRESS(msg.sender, a);
        _reservesAddress = a;
    }

    function collect(BPool pool)
        external
    {
        require(msg.sender == _blabs);
        require(_isBPool[address(pool)]);
        uint collected = IERC20(pool).balanceOf(address(this));
        bool xfer = pool.transfer(_blabs, collected);
        require(xfer);
    }

    function collectTokenReserves(BPool pool)
        external
    {
        require(msg.sender == _blabs);
        require(_isBPool[address(pool)]);
        pool.drainTotalReserves(_reservesAddress);
    }
}
