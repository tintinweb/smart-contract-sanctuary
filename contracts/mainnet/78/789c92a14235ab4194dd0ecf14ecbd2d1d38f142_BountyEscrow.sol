contract BountyEscrow {

  address public admin;

  function BountyEscrow() {
    admin = msg.sender;
  }
  
  event Payout(
    address indexed sender,
    address indexed recipient,
    uint256 indexed sequenceNum,
    uint256 amount,
    bool success
  );

  // transfer deposits funds to recipients
  // Gas used in each `send` will be default stipend, 2300
  function payout(address[] recipients, uint256[] amounts) {
    require(admin == msg.sender);
    require(recipients.length == amounts.length);
    for (uint i = 0; i < recipients.length; i++) {
      Payout(
        msg.sender,
        recipients[i],
        i + 1,
        amounts[i],
        recipients[i].send(amounts[i])
      );
    }
  }
}