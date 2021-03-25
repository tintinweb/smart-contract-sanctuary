/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▀ ▀▓▌▐▓▓▓▓▓▀▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓ ▓▓▌▝▚▞▜▓ ▀▀ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▄▀▓▌▐▓▌▐▓▄▀▀▀▓▓▓▓▓▓▓▓▓▓▛▀▀▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▛▀▀▀▄▄▄▄▄▄▄▛▀▀▀▓▓▓▛▀▀▀▓▓▓▙▄▄▄▛▀▀▀▓▓▓▛▀▀▀▙▄▄▄▓▓▓▛▀▀▀▄▄▄▄▄▄▄▛▀▀▀▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▀▀▀▜▓▓▓▓▓▓▓▓▓▓▌   ▀▀▀▀▀▀▀▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▓███   ▐███▓▓▓▓▓▓▓▌          ▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▀▀▀▀▀▀▀▓▓▓▓▓▓▓▌   ▓▓▓▛▀▀▀▙▄▄▄▓▓▓▙▄▄▄▛▀▀▀▓▓▓▓▓▓▓▀▀▀▀▀▀▀▀▀▀▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌          ▓▓▓▓▓▓▓▌   ▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓          ▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐▓▓▓  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▓▓▓    ▓▓▓▓▓▓    ▐▓▓▓▓▓▌    ▐▓▓▓      ▐▓▓▓▌    ▐▓▓▓▓▓▌    ▓▓▓▓▓▓▓▌       ▓▓▓    ▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▌   ▓▓▓▓▌  ▓▓▓▓  ▐▌  ▓▓▓▓▌  ▓  ▐▓▓▓▓▌  ▓▓▓  ▐▓▓▓  ▐▓▓▓▓▌  ▓▓▓▓▓▓▓▓  ▐▓  ▐▓▓▓  ▐▓▓▓▌  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▙▄▄▄▓▓▓▓▌  ▓▓▓▓  ▐▌  ▓▓▓▓▌  ▓  ▐▓▓▓▓▓▓▓▓▓▓  ▐▓▓▓  ▐▓▓▓▓▓▓▓▓▓▓▌      ▐▓  ▐▓▓▓  ▐▓▓▓▓▓▓    ▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▓▓▓▓  ▐▌  ▓▓▓▓▌  ▓  ▐▓▓▓▓▓▓▓▓▓▓  ▐▓▓▓  ▐▓▓▓▓▓▓▓▓   ▓▓▓▓  ▐▓  ▐▓▓▓  ▐▓▓▓▓▓▓▓▓▓▓  ▐▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌      ▓▓▓▓▓▓    ▐▓▓▓  ▐▓▓▓▓▓▓▓▓▓▓▓▓▌  ▓  ▐▓▓▓▓▓▓▓▓▓▓▌    ▓▓▓▓  ▐▓▓▓▓▓  ▐▓▓▓    ▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ThePixelPortraits {
    
    using SafeMath for uint256;
    
    enum CommissionStatus { queued, accepted, removed, rejected  }
    
    struct Commission {
        string name;
        uint prevCommission;
        uint nextCommission;
        address payable recipient;
        uint bid;
        CommissionStatus status;
    }

    uint MAX_INT = uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    address payable public admin;
    
    mapping (string => uint) public names;
    mapping (uint => Commission) public commissions;
    
    uint public minBid; // the number of wei required to create a commission
    uint public rejectionCost; // the number of wei that's retained if a commission is rejected
    uint public topCommissionIndex; // the index of the commission currently at the top of the queue
    uint public bottomCommissionIndex; // the index of the commission currently at the bottom of the queue
    uint public newCommissionIndex; // the index of the next commission which should be created in the mapping
    bool public callStarted; // ensures no re-entrancy can occur

    modifier callNotStarted () {
      require(!callStarted);
      callStarted = true;
      _;
      callStarted = false;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin, "not an admin");
        _;
    }
    
    constructor(address payable _admin, uint _minBid, uint _rejectionCost) {
        admin = _admin;
        minBid = _minBid;
        rejectionCost = _rejectionCost;
        newCommissionIndex = 1;
    }
     
    function updateAdmin (address payable _newAdmin)
    public
    callNotStarted
    onlyAdmin
    {
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }
    
    function updateMinBid (uint _newMinBid)
    public
    callNotStarted
    onlyAdmin
    {
        minBid = _newMinBid;
        emit MinBidUpdated(_newMinBid);
    }
    
    function updateRejectionCost (uint _newRejectionCost)
    public
    callNotStarted
    onlyAdmin
    {
        rejectionCost = _newRejectionCost;
        emit RejectionCostUpdated(_newRejectionCost);
    }
    
    function registerNames (string[] memory _names)
    public
    callNotStarted
    onlyAdmin
    {
      require(msg.sender == admin, "not an admin");
        for (uint i = 0; i < _names.length; i++){
            require(validateName(_names[i]), "name not valid"); // ensures the name is valid
            string memory lowerName = toLower(_names[i]);
            require(names[lowerName] == 0, "name not available"); // ensures the name is not taken
            names[lowerName] = MAX_INT;
        }
        emit NamesRegistered(_names);
    }
    
    function commission (string memory _name, uint _commissionToBeat) 
    public
    callNotStarted
    payable
    {
        require(validateName(_name), "name not valid"); // ensures the name is valid
        require(names[toLower(_name)] == 0, "name not available"); // the name cannot be taken when you create your commission
        require(msg.value >= minBid, "bid below minimum"); // must send the proper amount of into the bid
        
        // Next, initialize the new commission
        Commission storage newCommission = commissions[newCommissionIndex];
        newCommission.name = _name;
        newCommission.recipient = payable(msg.sender);
        newCommission.bid = msg.value;
        newCommission.status = CommissionStatus.queued;
        
        // next we handle the checks needed for this bid to skip ahead of an existing commission
        if (_commissionToBeat > 0){
          // if the commission to beat is 0 then this bid is intended for the back of the line
          require(_commissionToBeat < newCommissionIndex, "commission to beat not valid");
          Commission storage commissionToBeat = commissions[_commissionToBeat];
          require(commissionToBeat.bid < newCommission.bid, "bid not greater than following commission");
          require(commissionToBeat.status == CommissionStatus.queued, "bid not in queue");
        }
        
        // finally we add it to the correct position in the queue
        insertToQueue(newCommissionIndex, _commissionToBeat);
        
        emit NewCommission(newCommissionIndex, _name, msg.value, msg.sender);
        
        newCommissionIndex++; // for the subsequent commission to be added into the next slot 
    }
    
    
    function updateCommissionName (uint _commissionIndex, string memory _newName) 
    public
    callNotStarted
    {
        require(_commissionIndex < newCommissionIndex, "commission not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued
        require(names[toLower(selectedCommission.name)] != 0, "original name not taken"); // the requested name must be taken
        require(validateName(_newName), "name not valid"); // ensures the name is valid
        require(names[toLower(_newName)] == 0, "name not available"); // the new name cannot be taken
        
        selectedCommission.name = _newName;

        emit CommissionUpdated(_commissionIndex, _newName);
    }
    
    function rescindCommission (uint _commissionIndex) 
    public
    callNotStarted
    {
        require(_commissionIndex < newCommissionIndex, "commission not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued
        require(names[toLower(selectedCommission.name)] != 0, "original name not taken"); // the requested name must be taken
        
        // first we remove it from the list
        removeFromQueue(_commissionIndex);

        // then we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        selectedCommission.recipient.transfer(selectedCommission.bid);
        
        emit CommissionRescinded(_commissionIndex);
    }
    
    function pushCommissionToBeatCommission (uint _commissionIndex, uint _commissionToBeat)
    public
    payable
    callNotStarted
    {
        require(_commissionIndex < newCommissionIndex, "commission not valid"); // must be a valid previously instantiated commission
        require(_commissionToBeat < newCommissionIndex, "commission to beat not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = commissions[_commissionIndex];
        Commission storage commissionToBeat = commissions[_commissionToBeat];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued
        require(commissionToBeat.status == CommissionStatus.queued, "commission to beat not in queue"); // the commission being beaten must still be queued
        uint newBid = msg.value + selectedCommission.bid;
        require(newBid > commissionToBeat.bid, "new bid not higher than previous"); // the commission must have a higher bid than the old top commission
        
        // first we remove it from the queue
        removeFromQueue(_commissionIndex);

        // then we update the commission's bid
        selectedCommission.bid = newBid;

        // finally we add it to its new place ahead of the one it just beat
        insertToQueue(_commissionIndex, _commissionToBeat);
        
        emit CommissionPushedToFront(_commissionIndex, newBid);
    }
    
    function processCommissions(uint[] memory _commissionIndexes, bool[] memory _rejections)
    public
    onlyAdmin
    callNotStarted
    {
        require(_commissionIndexes.length == _rejections.length, "arrays not the same length");
        for (uint i = 0; i < _commissionIndexes.length; i++){
            require(topCommissionIndex != 0, "the queue may not be empty when processing more commissions"); // the queue my not be empty when processing more commissions 
            Commission storage selectedCommission = commissions[_commissionIndexes[i]];
            
            require(selectedCommission.status == CommissionStatus.queued, "commission not in the queue"); // the queue my not be empty when processing more commissions 
            // first we deal with the status, payments, and name resrvation 
            if (_rejections[i] || names[toLower(selectedCommission.name)] != 0){
                // Thom has decided to reject your commission or it is made for a taken name
                
                selectedCommission.status = CommissionStatus.rejected; // first, we change the status of the commission to rejected
                admin.transfer(rejectionCost); // next we charge our rejection fee
                selectedCommission.recipient.transfer(selectedCommission.bid - rejectionCost); // finally we return the difference back to the recipient
            } else {
                // this means that the name about to be accepted isn't taken yet and will be accepted
                
                selectedCommission.status = CommissionStatus.accepted; // first, we change the status of the commission to accepted
                names[toLower(selectedCommission.name)] = _commissionIndexes[i]; // finally, we reserve the name for this commission
                admin.transfer(selectedCommission.bid); // next we accept the payment for the commission
            }
            // finally, we remove the processed commission from the queue
            removeFromQueue(_commissionIndexes[i]);
            
            emit CommissionProcessed(_commissionIndexes[i], selectedCommission.status);
        }
    }
    
    function removeFromQueue(uint _commissionIndex)
    internal
    {
        Commission storage selectedCommission = commissions[_commissionIndex];
        
        if (_commissionIndex == topCommissionIndex){
          if (_commissionIndex == bottomCommissionIndex){
            // removes the last commission
            topCommissionIndex = 0;
            bottomCommissionIndex = 0;
          } else {
            // removes the current top commission (which has following commissions as well)
            topCommissionIndex = selectedCommission.nextCommission; // change the top to be the 2nd person in the queue
            commissions[topCommissionIndex].prevCommission = 0; // change this new 1st person to have an empty previous
          }
        } else if (_commissionIndex == bottomCommissionIndex) {
            // removes the current bottom commission
            bottomCommissionIndex = selectedCommission.prevCommission; // change the bottom to be the 2nd last person in the queue
            commissions[bottomCommissionIndex].nextCommission = 0; // change this new last person to have an empty next
        } else {
            // removes a commission that's somewhere in the middle
            commissions[selectedCommission.prevCommission].nextCommission = selectedCommission.nextCommission; 
            commissions[selectedCommission.nextCommission].prevCommission = selectedCommission.prevCommission;
        }
        selectedCommission.prevCommission = 0; // the commission is no longer in the queue and has no previous commission
        selectedCommission.nextCommission = 0; // the commission is no longer in the queue and has no next commission

    }
    
    function insertToQueue(uint _insertedCommissionIndex, uint _nextCommissionIndex)
    internal
    {
      Commission storage insertedCommission = commissions[_insertedCommissionIndex];
      Commission storage nextCommission = commissions[_nextCommissionIndex];
      
      if (_nextCommissionIndex == 0){
        // this new commission is being inserted at the back of the line
        if (bottomCommissionIndex == 0){
          // there are currently 0 commissions in the queue
          topCommissionIndex = _insertedCommissionIndex;
          bottomCommissionIndex = _insertedCommissionIndex;
        } else {
          // there's at least 1 commission 
          
          Commission storage prevCommission = commissions[bottomCommissionIndex];
          require(prevCommission.bid >= insertedCommission.bid, "bid larger than the one it follows"); // the previous commisions bid must be greater than the one being inserted
          prevCommission.nextCommission = _insertedCommissionIndex; // the old bottom commission now precedes the one being inserted
          insertedCommission.prevCommission = bottomCommissionIndex; // the new commission now follows the old bottom
          bottomCommissionIndex = _insertedCommissionIndex; // the bottom now points to the new commission
        }    
      } else if (_nextCommissionIndex == topCommissionIndex){
        // this new commission is being inserted at the front of the line
        
        insertedCommission.nextCommission = _nextCommissionIndex; // the new commission now precedes the one being beaten
        nextCommission.prevCommission = _insertedCommissionIndex; // the one being beaten now points to the inserted one
        topCommissionIndex = _insertedCommissionIndex; // the top pointer now points to the inserted one
      } else {
        // the new commission is being inserted in the middle of the queue
        
        // first we must make sure that this insertion keeps the queue sorted by bid price (otherwise it should be added in the correct spot in line)
        Commission storage prevCommission = commissions[nextCommission.prevCommission]; // this is the commission which originally preceded the commission we're inserting before
        require(prevCommission.bid >= insertedCommission.bid, "bid larger than the one it follows"); // the previous commisions bid must be greater than the one being inserted
        
        // now we finally insert it
        insertedCommission.prevCommission = nextCommission.prevCommission; // the commission preceding the new one is the old previous commission
        insertedCommission.nextCommission = _nextCommissionIndex; // the commission following the selected one is the one being beaten
        prevCommission.nextCommission = _insertedCommissionIndex; // the commission following the old previous is the newly inserted one
        nextCommission.prevCommission = _insertedCommissionIndex; // the commission being beaten now follows the one being inserted
        // now they no longer point at each other and instead point to the one in the middle
      }
    }
    
    // Credit to Hashmasks for the following functions
    function validateName (string memory str)
    public 
    pure 
    returns (bool)
    {
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }
    
    function toLower (string memory str)
    public 
    pure 
    returns (string memory)
    {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    event AdminUpdated(address _newAdmin);
    event MinBidUpdated(uint _newMinBid);
    event RejectionCostUpdated(uint _newRejectionCost);
    event NamesRegistered(string[] _names);
    event NewCommission(uint _commissionIndex, string _name, uint _bid, address _recipient);
    event CommissionUpdated(uint _commissionIndex, string _newName);
    event CommissionRescinded(uint _commissionIndex);
    event CommissionPushedToFront(uint _commissionIndex, uint _newBid);
    event CommissionProcessed(uint _commissionIndex, CommissionStatus _status);
}