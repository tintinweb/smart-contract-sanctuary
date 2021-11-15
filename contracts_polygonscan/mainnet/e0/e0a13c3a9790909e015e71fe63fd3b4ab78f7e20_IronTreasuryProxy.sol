pragma solidity 0.8.4;

contract IronTreasuryProxy {
    function hasPool(address _pool) external pure returns (bool) {
        return _pool == 0x09cA5d827712dD7b2570FD534305B663Ae788C17;
    }
}

