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
    
    address constant owner1 = 0x2c155e07a1Ee62f229c9968B7A903dC69436e3Ec;
    address constant owner2 = 0xdBd39C1b439ba2588Dab47eED41b8456486F4Ba5;
    address constant owner3 = 0x90d33D152A422D63e0Dd1c107b7eD3943C06ABA8;
    address constant owner4 = 0xE12E421D5C4b4D8193bf269BF94DC8dA28798BA9;
    address constant owner5 = 0xD4B33C108659A274D8C35b60e6BfCb179a2a6D4C;
    
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