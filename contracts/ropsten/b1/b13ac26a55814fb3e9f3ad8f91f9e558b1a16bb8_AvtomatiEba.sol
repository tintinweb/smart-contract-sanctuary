/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title AvtomatiEba
 * @dev Lambo ili REKT
 */
contract AvtomatiEba {
    
    mapping(address => string) public degens;
    mapping(address => uint) public balances;
    mapping(address => bool) seen;
    
    uint randNonce = 0;
    uint maxBalance = 0;
    address winner;
    
    function airdrop(string calldata name) public returns (bytes32) { 
        require(!seen[msg.sender]);
        degens[msg.sender] = name;
        balances[msg.sender] = 100;
        return "You were airpropped 100 credits";
    }

    function try_luck(uint bet) public returns(string memory) {
        require(seen[msg.sender] && balances[msg.sender] > bet);
        balances[msg.sender] =  balances[msg.sender] * randMod(bet % 100);
        if (balances[msg.sender] > maxBalance) {
            maxBalance = balances[msg.sender];
            winner = msg.sender;
        }
        return string(abi.encodePacked("Your new balance is ", balances[msg.sender]));
    }
    
    function randMod(uint _modulus) internal returns(uint) 
    {
       randNonce++;  
       return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

    
    function leaderboard() public view returns (string memory) {
        {
            return string(abi.encodePacked(degens[winner], "with ", maxBalance));
        }
    }
}