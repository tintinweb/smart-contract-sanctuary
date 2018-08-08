pragma solidity ^0.4.18;


contract TopIvy {

  /*** CONSTANTS ***/
  string public constant NAME = "TopIvy";
  uint256 public constant voteCost = 0.001 ether;
  
  // You can use this string to verify the indices correspond to the school order below
  string public constant schoolOrdering = "BrownColumbiaCornellDartmouthHarvardPennPrincetonYale";

  /*** STORAGE ***/
  address public ceoAddress;
  uint256[8] public voteCounts = [1,1,1,1,1,1,1,1];

  // Sorted alphabetically:
  // 0: Brown
  // 1: Columbia
  // 2: Cornell
  // 3: Dartmouth
  // 4: Harvard
  // 5: Penn
  // 6: Princeton
  // 7: Yale

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /*** CONSTRUCTOR ***/
  function TopIvy() public {
    ceoAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/
  /// @dev Transfer contract balance
  /// @param _to The address to receive the payout
  function payout(address _to) public onlyCEO{
    _payout(_to);
  }

  /// @dev Buys votes for an option, each vote costs voteCost.
  /// @param _id Which side gets the vote
  function buyVotes(uint8 _id) public payable {
      // Ensure at least one vote can be purchased
      require(msg.value >= voteCost);
      // Ensure vote is only for listed Ivys
      require(_id >= 0 && _id <= 7);
      // Calculate number of votes
      uint256 votes = msg.value / voteCost;
      voteCounts[_id] += votes;
      // Don&#39;t bother sending remainder back because it is <0.001 eth
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }
  
  // @dev Returns the list of vote counts
  function getVotes() public view returns(uint256[8]) {
      return voteCounts;
  }

  /*** PRIVATE FUNCTIONS ***/
  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }
}