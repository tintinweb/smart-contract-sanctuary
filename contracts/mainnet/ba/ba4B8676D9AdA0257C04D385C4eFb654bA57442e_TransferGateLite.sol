// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A transfer gate (GatedERC20) for use with RootKit tokens

It:
    Allows customization of tax and burn rates
    Allows transfer to/from approved Uniswap pools
    Disallows transfer to/from non-approved Uniswap pools
    Allows transfer to/from anywhere else
    Allows for free transfers if permission granted
    Allows for unrestricted transfers if permission granted
*/

import "./Owned.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./EliteToken.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./ITransferGateLite.sol";

contract TransferGateLite is TokensRecoverable, ITransferGateLite //a.k.a. KETH/Elite Transfer Door
{   
    using Address for address;
    using SafeMath for uint256;
    
    mapping (address => bool) public participantControllers;
    mapping (address => bool) public freeParticipant;
    uint16 burnRate;   

    function setParticipantController(address participantController, bool allow) public ownerOnly()
    {
        participantControllers[participantController] = allow;
    }

    function setFreeParticipant(address participant, bool free) public
    {
        require (msg.sender == owner || participantControllers[msg.sender], "Not an Owner or Free Participant");
        freeParticipant[participant] = free;
    }

    function setBurnRate(uint16 _burnRate) public // 10000 = 100%
    {
        require (msg.sender == owner || participantControllers[msg.sender], "Not an Owner or Free Participant");
        require (_burnRate <= 10000, "> 100%");
       
        burnRate = _burnRate;
    }
  
    function handleTransfer(address, address from, address to, uint256 amount) public virtual override returns (uint256 burn)
    {       
        if (freeParticipant[from] || freeParticipant[to]) 
        { 
            return (0); 
        }
        // "amount" will never be > totalSupply so these multiplications will never overflow
        burn = amount * burnRate / 10000;
    }
}