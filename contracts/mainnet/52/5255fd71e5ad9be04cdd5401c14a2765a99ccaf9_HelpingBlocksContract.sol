pragma solidity ^0.4.24;


contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract HelpingBlocksContract is Ownable {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    string public description;
    bool public donationClosed = false;

    mapping (address => uint256) public balanceOf;
    /* To track donated amount of a user */
    mapping (address => uint256) public myDonation;
    event Transfer(address indexed from, address indexed to, uint256 value);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = &#39;Helping Blocks Token&#39;;
        symbol = &#39;HBT&#39;;
        decimals = 0;
        totalSupply = 10000000;
        description = "Kerala Flood Relief Fund";
        balanceOf[owner] = totalSupply;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public onlyOwner returns(bool success) {
        _transfer(owner, _to, _value);
        return true;
    }

    /* Stop taking donations */
    function disableDonation() public onlyOwner returns(bool success) {
      donationClosed = true;
      return true;
    }


    /* Start taking donations */
    function enableDonation() public onlyOwner returns(bool success) {
      donationClosed = false;
      return true;
    }

    function setDescription(string str) public onlyOwner returns(bool success) {
      description = str;
      return true;
    }


    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
      require(!donationClosed);
      myDonation[msg.sender] += msg.value;
      if (balanceOf[msg.sender] < 1) {
        _transfer(owner, msg.sender, 1);
      }
    }

    function safeWithdrawal(uint256 _value) payable public onlyOwner {
      owner.transfer(_value);
    }
}