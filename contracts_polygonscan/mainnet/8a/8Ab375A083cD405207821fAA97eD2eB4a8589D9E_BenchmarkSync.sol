/**
 *Submitted for verification at polygonscan.com on 2021-11-27
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

    address public constant benchmark = 0xa4Dc6e03dFe83C31325D4BE56cF6B6ecbFe39823;
    address public owner;
    address public newOwner;

    SyncDEX[] public SyncPools;
    GulpDEX[] public GulpPools;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor()
    {
        owner = msg.sender;
    }

    /**
     * @dev Propose a new owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public
    {
        require(msg.sender == owner, "Can only be executed by owner.");
        require(_newOwner != address(0), "0x00 address not allowed.");
        newOwner = _newOwner;
    }

    /**
     * @dev Accept new owner.
     */
    function acceptOwnership() public
    {
        require(msg.sender == newOwner, "Sender not authorized.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
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
    function addSyncPool (address _lpPool) public {
        require(msg.sender == owner, "Can only be executed by owner.");
        SyncPools.push(SyncDEX(_lpPool));
    }

    /**
     * @dev Add a new Liquidity Pool. 
     * @param _lpPool Address of Liquidity Pool.
     */
    function addGulpPool (address _lpPool) public {
        require(msg.sender == owner, "Can only be executed by owner.");
        GulpPools.push(GulpDEX(_lpPool));
    }

    /**
     * @dev Remove a Liquidity Pool. 
     * @param _index Index of Liquidity Pool.
     */
    function removeSyncPool (uint256 _index) public {
        require(msg.sender == owner, "Can only be executed by owner.");
        delete SyncPools[_index];
    }

    /**
     * @dev Remove a Liquidity Pool. 
     * @param _index Index of Liquidity Pool.
     */
    function removeGulpPool (uint256 _index) public {
        require(msg.sender == owner, "Can only be executed by owner.");
        delete GulpPools[_index];
    }
}