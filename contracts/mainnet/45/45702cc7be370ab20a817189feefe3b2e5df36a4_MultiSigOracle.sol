/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/******************************************/
/*       DEX starts here            */
/******************************************/

abstract contract DEX 

{
    function sync() external virtual;
}

/******************************************/
/*       Benchmark starts here            */
/******************************************/

abstract contract Benchmark 

{
    function rebase(uint256 supplyDelta, bool increaseSupply) external virtual returns (uint256);
    
    function transfer(address to, uint256 value) external virtual returns (bool);
    
    function balanceOf(address who) external virtual view returns (uint256);
}


/******************************************/
/*       multiSigOracle starts here       */
/******************************************/

contract MultiSigOracle {

    address owner1;
    address owner2;
    address owner3;
    address owner4;
    address owner5;

    address public standard;
    uint256 public standardRewards;
    
    Benchmark public bm;
    DEX[] public Pools;

    Transaction public pendingRebasement;
    uint256 internal lastRebasementTime;

    struct Transaction {
        address initiator;
        uint supplyDelta;
        bool increaseSupply;
        bool executed;
    }

    modifier isOwner() 
    {
        require (msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3 || msg.sender == owner4 || msg.sender == owner5);
        _;
    }

    constructor(address _Benchmark, address _Standard)
    {
        owner1 = 0x2c155e07a1Ee62f229c9968B7A903dC69436e3Ec;
        owner2 = 0xdBd39C1b439ba2588Dab47eED41b8456486F4Ba5;
        owner3 = 0x90d33D152A422D63e0Dd1c107b7eD3943C06ABA8;
        owner4 = 0xE12E421D5C4b4D8193bf269BF94DC8dA28798BA9;
        owner5 = 0xD4B33C108659A274D8C35b60e6BfCb179a2a6D4C;
        standard = _Standard;
        bm = Benchmark(_Benchmark);
        
        pendingRebasement.executed = true;
    }

    /**
     * @dev Initiates a rebasement proposal that has to be confirmed by another owner of the contract to be executed. Can't be called while another proposal is pending.
     * @param _supplyDelta Change in totalSupply of the Benchmark token.
     * @param _increaseSupply Whether to increase or decrease the totalSupply of the Benchmark token.
     */
    function initiateRebasement(uint256 _supplyDelta, bool _increaseSupply) public isOwner
    {
        require (pendingRebasement.executed == true, "Pending rebasement.");
        require (lastRebasementTime < (block.timestamp - 64800), "Rebasement has already occured within the past 18 hours.");

        Transaction storage txn = pendingRebasement; 
        txn.initiator = msg.sender;
        txn.supplyDelta = _supplyDelta;
        txn.increaseSupply = _increaseSupply;
        txn.executed = false;
    }

    /**
     * @dev Confirms and executes a pending rebasement proposal. Prohibits further proposals for 18 hours.
     */
    function confirmRebasement() public isOwner
    {
        require (pendingRebasement.initiator != msg.sender, "Initiator can't confirm rebasement.");
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        
        pendingRebasement.executed = true;
        lastRebasementTime = block.timestamp;

        bm.rebase(pendingRebasement.supplyDelta, pendingRebasement.increaseSupply);

        uint256 arrayLength = Pools.length;
        for (uint256 i = 0; i < arrayLength; i++) 
        {
            if (address(Pools[i]) != address(0)) {
                Pools[i].sync();
            }           
        }

        bm.transfer(standard, standardRewards);
    }

    /**
     * @dev Denies a pending rebasement proposal and allows the creation of a new proposal.
     */
    function denyRebasement() public isOwner
    {
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        
        pendingRebasement.executed = true;
    }

    /**
     * @dev Add a new Liquidity Pool. 
     * @param _lpPool Address of Liquidity Pool.
     */
    function addPool (address _lpPool) public isOwner {
        Pools.push(DEX(_lpPool));
    }

    /**
     * @dev Remove a Liquidity Pool. 
     * @param _index Index of Liquidity Pool.
     */
    function removePool (uint256 _index) public isOwner {
        delete Pools[_index];
    }

    /**
     * @dev Change Standard staking rewards. 
     * @param _standardRewards New amount of rewards.
     */
    function setStandardRewards (uint256 _standardRewards) public isOwner {
        standardRewards = _standardRewards;
    }

    /**
     * @dev Remove all MARK deposited on this contract. 
     */
    function withdrawMark () public {
        require (msg.sender == 0x2c155e07a1Ee62f229c9968B7A903dC69436e3Ec || msg.sender == 0xdBd39C1b439ba2588Dab47eED41b8456486F4Ba5, "Only Masterchief can withdraw.");
        bm.transfer(msg.sender, bm.balanceOf(address(this)));
    }
}