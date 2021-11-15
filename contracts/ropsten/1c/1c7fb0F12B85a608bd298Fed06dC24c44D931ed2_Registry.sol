/// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/**
 * @title Registry
 * @dev This contract is used for setting, getting, and verifying contract addresses.
 */

contract Registry {
    
    /***************
    GLOBAL CONSTANTS
    ***************/
    address public tournament;
    address public tournamentFactory;
    address public tribeToken;

    /********
    FUNCTIONS
    ********/

    function setTournamentAddress(address _addr) external {
        require(tournament == address(0), "Address must not be set");
        tournament = _addr;
    }

    function setTournamentFactoryAddress(address _addr) external {
        require(tournamentFactory == address(0), "Address must not be set");
        tournamentFactory = _addr;
    }

    function setTribeTokenAddress(address _addr) external {
        require(tribeToken == address(0), "Address must not be set");
        tribeToken = _addr;
    }

}

