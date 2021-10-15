// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./ERC31337.sol";
import "./IERC20.sol";

contract EliteToken is ERC31337
{
    using Address for address;
    using SafeMath for uint256;
    
    mapping (address => bool) public freeParticipantControllers;
    mapping (address => bool) public freeParticipants; 

    mapping (address => bool) public burnRateControllers;
    uint16 burnRate;   

    constructor (IERC20 _wrappedToken) ERC31337(_wrappedToken, "eliteHNW", "eHNW")
    {
    }    

    function setFreeParticipantController(address freeParticipantController, bool allow) public ownerOnly()
    {
        freeParticipantControllers[freeParticipantController] = allow;
    }

    function setFreeParticipant(address participant, bool free) public
    {
        require (msg.sender == owner || freeParticipantControllers[msg.sender], "Not an owner or free participant controller");
        freeParticipants[participant] = free;
    }

    function setBurnRateController(address burnRateController, bool allow) public ownerOnly()
    {
        burnRateControllers[burnRateController] = allow;
    }

    function setBurnRate(uint16 _burnRate) public // 10000 = 100%
    {
        require (msg.sender == owner || burnRateControllers[msg.sender], "Not an owner or burn rate controller");
        require (_burnRate <= 10000, "But rate must be less or equal to 100%");
       
        burnRate = _burnRate;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "EliteToken: transfer from the zero address");
        require(recipient != address(0), "EliteToken: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 remaining = amount;

        if (!freeParticipants[sender] && !freeParticipants[recipient] && burnRate > 0)
        {
            uint256 burn = amount * burnRate / 10000;
            amount = remaining = remaining.sub(burn, "Burn too much");
            _burn(sender, burn);
        }
        
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "EliteToken: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        
        emit Transfer(sender, recipient, remaining);
    }
}