//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

import "./interface/IPlayer.sol";
import "./interface/ITreasury.sol";

contract Manager {
    struct ManagerAcct {
        address player;
        string username;
        uint256 pctPlayerShare;
        uint256 pctManagerShare;
    }

    mapping(address => ManagerAcct) managers;
    address[] public managerAccts;

    IPlayer playerContract;
    ITreasury treasuryContract;

    constructor(address _playerContract, address _treasuryContract) {
        playerContract = IPlayer(_playerContract);
        treasuryContract = ITreasury(_treasuryContract);
    }

    function setRevShare (uint256 _pctPlayerShare, uint256 _pctManagerShare) external {
        managers[msg.sender].pctPlayerShare = _pctPlayerShare;
        managers[msg.sender].pctManagerShare = _pctManagerShare;
    }

    function getPctShareAll (address _addr) external view returns(uint256, uint256) {
        return (managers[_addr].pctPlayerShare, managers[_addr].pctManagerShare);
    }

    function claimSlpInterfaceTreasury() external {
        uint256 pctPlayerShare = managers[msg.sender].pctPlayerShare;
        uint256 pctManagerShare = managers[msg.sender].pctManagerShare;

        address manager = msg.sender;
        address player = managers[msg.sender].player;

        treasuryContract.remit(player, manager, pctManagerShare, pctPlayerShare);
    }

    function registerManager(
        address _player, 
        string memory _managerUsername,
        uint256 _pctPlayerShare,
        uint256 _pctManagerShare
        ) external
    {
        managers[msg.sender] = ManagerAcct(_player, _managerUsername, _pctPlayerShare, _pctManagerShare);
        managerAccts.push(msg.sender);

        playerContract.registerPlayer(_player, msg.sender);
    }

    function getManagers() external view returns (address[] memory) {
        return managerAccts;
    }

    function getManager(address _addr)
        external
        view
        returns (address,
                string memory,
                uint256,
                uint256
                )
    {
        return (managers[_addr].player,
                managers[_addr].username,
                managers[_addr].pctPlayerShare,
                managers[_addr].pctManagerShare
                );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IPlayer {
    function registerPlayer(address _player, address _manager) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITreasury {
    function calcManagerPlayerShare(uint256 _playerShare) external;
    function remit(address _player, 
                    address _manager, 
                    uint256 pctSharePlayer, 
                    uint256 pctShareManager
                    ) external;
    // function mintSlp(uint256 _amount) external;
    function mintSlp(address _player, uint256 _amount) external;
}