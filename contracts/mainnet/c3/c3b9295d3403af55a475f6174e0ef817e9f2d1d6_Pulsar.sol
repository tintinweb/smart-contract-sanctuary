/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/**
 Pulsars are rotating neutron stars observed to have pulses of radiation at very regular intervals that typically range from milliseconds to seconds. 
 Pulsars have very strong magnetic fields which funnel jets of particles out along the two magnetic poles. 
 These accelerated particles produce very powerful beams of light. Often, the magnetic field is not aligned with the spin axis, so those beams of particles and light are swept around as the star rotates. 
 When the beam crosses our line-of-sight, we see a pulse – in other words, we see pulsars turn on and off as the beam sweeps over Earth.
 
 */
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

contract Pulsar {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    
    uint256 public totalSupply = 10 * 10**11 * 10**18;
    string public name = "Pulsar";
    string public symbol = hex"50554C534152f09f8c9f";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        return true;
        
    }
}