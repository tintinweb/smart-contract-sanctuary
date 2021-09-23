/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Simulator {
    event Harvest(uint256 lpTokens);
    event Invested(
        uint256 indexed vaultId,
        uint256 seniorAmount,
        uint256 juniorAmount
    );
    event Redeemed(
        uint256 indexed vaultId,
        uint256 seniorReceived,
        uint256 juniorReceived
    );
    event CreatedPair(
        uint256 indexed vaultId
    );    
    address private strategist;
    mapping(address => bool) private Owners;
    // Access restriction to registered rollover
    modifier onlyStrategist() {
        require(
        msg.sender == strategist,
        "Invalid caller"
        );
        _;
    }
    modifier onlyOwner() {
        require(
        Owners[msg.sender] == true,
        "Invalid caller"
        );
        _;
    }    
    constructor()
    {
        Owners[msg.sender] = true;
    }
    function harvest(uint256 _minLp) onlyStrategist public returns (uint256)
    {
        uint256 lpAmount = _minLp + 1;
        require(lpAmount >= _minLp, "Exceeds maximum slippage");
        emit Harvest(lpAmount);
        return lpAmount;
    }
    function harvest(address _pool, uint256 _minLp) onlyStrategist public returns (uint256)
    {
        uint256 lpAmount = _minLp + 1;
        _pool;
        require(lpAmount >= _minLp, "Exceeds maximum slippage");
        emit Harvest(lpAmount);
        return lpAmount;
    }
    function invest(uint256 _vaultId, uint256 _seniorMinIn, uint256 _juniorMinIn) onlyStrategist external returns (uint256, uint256)
    {
        emit Invested(_vaultId, _seniorMinIn+1, _juniorMinIn+1);
        return (_seniorMinIn+1, _juniorMinIn+1);
    }
    
    function redeem(uint256 _vaultId, uint256 _seniorMinReceived, uint256 _juniorMinReceived) onlyStrategist external returns (uint256, uint256)
    {
        emit Redeemed(_vaultId, _seniorMinReceived+1, _juniorMinReceived+1);
        return (_seniorMinReceived+1, _juniorMinReceived+1);
    }

    function setStrategist(address _strategist) external onlyOwner{
        strategist = _strategist;
    }
    function setOwner(address _owner) external onlyOwner{
        Owners[_owner] = true;
    }
    function createVault(uint256 vaultId) external {
        emit CreatedPair(vaultId);
    }
}