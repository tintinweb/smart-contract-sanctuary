contract SimpleSavingsWallet {

  address public owner;

  event Sent(address indexed payee, uint256 amount, uint256 balance);
  event Received(address indexed payer, uint256 amount, uint256 balance);

  modifier onlyOwner {
      require(msg.sender == owner);
      _;
  }
  constructor()
  {
      owner = msg.sender;
  }
  
  /**
   * @dev wallet can receive funds.
   */
  function () public payable {
    Received(msg.sender, msg.value, this.balance);
  }

  /**
   * @dev wallet can send funds
   */
  function sendTo(address payee, uint256 amount) public onlyOwner {
    require(payee != 0 && payee != address(this));
    require(amount > 0);
    payee.transfer(amount);
    emit Sent(payee, amount, this.balance);
  }
}