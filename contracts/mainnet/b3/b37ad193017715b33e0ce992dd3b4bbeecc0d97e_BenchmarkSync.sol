/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************/
/*       SyncDEX starts here              */
/******************************************/

abstract contract SyncDEX 

{
    function sync() external virtual;
}


/******************************************/
/*       GulpDEX starts here              */
/******************************************/

abstract contract GulpDEX 

{
    function gulp(address token) external virtual;
}

/******************************************/
/*       BenchmarkSync starts here       */
/******************************************/

contract BenchmarkSync {

    address public constant benchmark = 0x67c597624B17b16fb77959217360B7cD18284253;
    
    address owner1;
    address owner2;
    address owner3;
    address owner4;
    address owner5;
    
    SyncDEX[] public SyncPools;
    GulpDEX[] public GulpPools;

    modifier isOwner() 
    {
        require (msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3 || msg.sender == owner4 || msg.sender == owner5);
        _;
    }
    
    /**
     * @dev Sync liquidity pools. 
     */
    function syncPools() public {
        uint256 syncArrayLength = SyncPools.length;
        for (uint256 i = 0; i < syncArrayLength; i++) 
        {
            if (address(SyncPools[i]) != address(0)) {
                SyncPools[i].sync();
            }           
        }

        uint256 gulpArrayLength = GulpPools.length;
        for (uint256 i = 0; i < gulpArrayLength; i++) 
        {
            if (address(GulpPools[i]) != address(0)) {
                GulpPools[i].gulp(benchmark);
            }           
        }
    }
    
    /**
     * @dev Add a new Liquidity Pool. 
     * @param _lpPool Address of Liquidity Pool.
     */
    function addSyncPool (address _lpPool) public isOwner {
        SyncPools.push(SyncDEX(_lpPool));
    }

    /**
     * @dev Add a new Liquidity Pool. 
     * @param _lpPool Address of Liquidity Pool.
     */
    function addGulpPool (address _lpPool) public isOwner {
        GulpPools.push(GulpDEX(_lpPool));
    }

    /**
     * @dev Remove a Liquidity Pool. 
     * @param _index Index of Liquidity Pool.
     */
    function removeSyncPool (uint256 _index) public isOwner {
        delete SyncPools[_index];
    }

    /**
     * @dev Remove a Liquidity Pool. 
     * @param _index Index of Liquidity Pool.
     */
    function removeGulpPool (uint256 _index) public isOwner {
        delete GulpPools[_index];
    }
}