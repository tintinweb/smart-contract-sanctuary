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


contract KeralaDonationContract is Ownable {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    uint public amountRaised;
    bool donationClosed = false;

    mapping (address => uint256) public balanceOf;
    /* To track donated amount of a user */
    mapping (address => uint256) public balance;
    event FundTransfer(address backer, uint amount, bool isContribution);
    event Transfer(address indexed from, address indexed to, uint256 value);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = &#39;Kerala Flood Donation Token&#39;;
        symbol = &#39;KFDT&#39;;
        decimals = 0;
        totalSupply = 1000000;

        balanceOf[owner] = totalSupply;
        amountRaised = 0;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] == 0);
        require(_value == 1);

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
        _transfer(msg.sender, _to, _value);
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

    /* check user&#39;s donated amount */
    function checkMyDonation() public view returns(uint) {
      return balance[msg.sender];
    }

    /* check if user is a backer */
    function isBacker() public view returns(bool) {
      if (balanceOf[msg.sender] > 0) {
        return true;
      }
      return false;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!donationClosed);
        uint amount = msg.value;
        amountRaised += amount;
        balance[msg.sender] += amount;
        transfer(msg.sender, 1);
        owner.transfer(msg.value);
    }
}