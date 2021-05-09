/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/** A reference implementation of EIP-2135
 *
 * For simplicity, this reference implementation creates a super simple `issueTicket` function without
 * restriction on who can issue new tickets and under what condition a ticket can be issued.
 */
contract Ticket /* is ERC2135, ERC721, ERC173, ERC165 */ {

  address public issuer;

  mapping(uint256 => uint256) private ticketStates; /* 0 = unissued, 1 = issued, unconsumed, 2 = consumed); */
  mapping(uint256 => address) private ticketHolders;
  
  constructor() {
    issuer = msg.sender;
  }
  
  /** ERC 2135 */
  event OnConsumption(uint256 _tockenId, address _consumer);
  
  /** ERC 721 */
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
 
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    require(_from == msg.sender, "The sender must be the source of transfer.");
    require(_from == ticketHolders[_tokenId], "The sender must hold the ticket.");
    require(1 == ticketStates[_tokenId], "The ticket must be issued but not consumed.");
    ticketHolders[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
    return;
  }

  /**
   * ERC 2135
   */
  function issue(uint256 _ticketId, address _receiver) public returns (bool success) {
    require (msg.sender == issuer, "Only ticket issuer can issue ticket.");
    require (ticketStates[_ticketId] == 0, "The ticket address has been issued and not consumed yet, it cannot be issued again."); // ticket needs to be not issued yet;
    ticketStates[_ticketId] = 1;
    ticketHolders[_ticketId] = _receiver;
    return true;
  }

  /**
   * ERC 2135
   */
  function consume(uint256 _ticketId, address _consumer) public returns (bool success) {
    require (_consumer == msg.sender, "Consumer must be the sender themselves in this contract.");
    require (ticketHolders[_ticketId] == msg.sender, "Only the current ticket holder can request to consume a ticket");
    require (ticketStates[_ticketId] == 1, "The ticket needs to be issued but not consumed yet.");
    ticketStates[_ticketId] = 2;
    emit OnConsumption(_ticketId, msg.sender);
    return true;
  }

  /**
   * ERC 2135
   */
  function isConsumable(uint256 _ticketId) public view returns (bool consumable) {
    return ticketStates[_ticketId] == 1;
  }
  
  
}