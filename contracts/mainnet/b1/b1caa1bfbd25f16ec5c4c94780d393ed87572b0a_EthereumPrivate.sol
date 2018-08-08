pragma solidity ^0.4.16;

contract EthereumPrivate{
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    string public name = "EthereumPrivate";
    string public symbol = "PETH";
    uint256 public max_supply = 18000000000000;
    uint256 public unspent_supply = 0;
    uint256 public spendable_supply = 0;
    uint256 public circulating_supply = 0;
    uint256 public decimals = 6;
    uint256 public reward = 50000000;
    uint256 public timeOfLastHalving = now;
    uint public timeOfLastIncrease = now;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function howCoin() public {
      timeOfLastHalving = now;
    }

    function updateSupply() internal returns (uint256) {

      if (now - timeOfLastHalving >= 2100000 minutes) {
        reward /= 2;
        timeOfLastHalving = now;
      }

      if (now - timeOfLastIncrease >= 150 seconds) {
        uint256 increaseAmount = ((now - timeOfLastIncrease) / 150 seconds) * reward;
        spendable_supply += increaseAmount;
        unspent_supply += increaseAmount;
        timeOfLastIncrease = now;
      }

      circulating_supply = spendable_supply - unspent_supply;

      return circulating_supply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient

        updateSupply();

        /* Notify anyone listening that the transfer took place */
        Transfer(msg.sender, _to, _value);

    }
    /* Mint new coins by sending ether */
    function mint() public payable {
        require(balanceOf[msg.sender] + _value >= balanceOf[msg.sender]); // Check for overflows
        uint256 _value = msg.value / 100000000;

        updateSupply();

        require(unspent_supply - _value <= unspent_supply);
        unspent_supply -= _value; // Remove from unspent supply
        balanceOf[msg.sender] += _value; // Add the same to the recipient

        updateSupply();

        /* Notify anyone listening that the minting took place */
        Mint(msg.sender, _value);

    }

    function withdraw(uint256 amountToWithdraw) public returns (bool) {

        // Balance given in HOW

        require(balanceOf[msg.sender] >= amountToWithdraw);
        require(balanceOf[msg.sender] - amountToWithdraw <= balanceOf[msg.sender]);

        // Balance checked in HOW, then converted into Wei
        balanceOf[msg.sender] -= amountToWithdraw;

        // Added back to supply in HOW
        unspent_supply += amountToWithdraw;
        // Converted into Wei
        amountToWithdraw *= 100000000;

        // Transfered in Wei
        msg.sender.transfer(amountToWithdraw);

        updateSupply();

        return true;
    }
}