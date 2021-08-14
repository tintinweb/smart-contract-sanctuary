/**
 *Submitted for verification at polygonscan.com on 2021-08-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface IPolyshieldBurner {
    function burnTotals(address account) external view returns (uint256);
}

contract PolyshieldBurnLeaderboard {
    
    address public burnerContract;
    
    mapping(address => bool) public registrations; 
    
    struct Burner {
        address user;
        string userAlias;
        uint256 amount;
    }
    Burner [] burners;

    constructor(address _burnerContract){
        burnerContract = _burnerContract;
    }
    
    function register(string memory _userAlias) public {
        require (registrations[msg.sender]==false, "Already registered!");
        
        Burner memory b = Burner({
            user: msg.sender,
            userAlias: _userAlias,
            amount: 0
            });
        
        burners.push(b);
        registrations[msg.sender]=true;
    }
    
     function getBurners() external view returns (Burner[] memory) {
         
        Burner[] memory list = new Burner[](burners.length);
        
        for (uint i = 0; i < burners.length; i++) {
            list[i] = burners[i];
            list[i].amount = 100;
            list[i].amount = IPolyshieldBurner(burnerContract).burnTotals(list[i].user);
        }

        return list;
    }
}