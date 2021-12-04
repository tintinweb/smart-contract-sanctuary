/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient {
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external;
}

//Actual token contract
contract ARTNANO{
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed owner, address indexed spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        symbol = "ARNO";
        name = "ART-NANO";
        decimals = 18;
        totalSupply = 50000000000000000000000000;
        balanceOf[0x8817f003777293D25FADC1e4F320c395BDacE828] = totalSupply;
        emit Transfer(address(0), 0x8817f003777293D25FADC1e4F320c395BDacE828, totalSupply); // Set the symbol for display purposes
    }

   function totalSupply() public constant returns (uint256) {
        return totalSupply  - balanceOf[address(0)];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function transfer(address from, address to, uint256 value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[from] >= value);
        // Check for overflows
        require(balanceOf[to] + value >= balanceOf[to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[from] + balanceOf[to];
        // Subtract from the sender
        balanceOf[from] -= value;
        // Add the same to the recipient
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `value` tokens to `to` from your account
     *
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transfer(address to, uint256 value) public returns (bool success) {
        transfer(msg.sender, to, value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `value` tokens to `to` on behalf of `from`
     *
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);     // Check allowance
        allowance[from][msg.sender] -= value;
        transfer(from, to, value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `spender` to spend no more than `value` tokens on your behalf
     *
     * @param spender The address authorized to spend
     * @param value the max amount they can spend
     */
    function approve(address spender, uint256 value) public
        returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `spender` to spend no more than `value` tokens on your behalf, and then ping the contract about it
     *
     * @param spender The address authorized to spend
     * @param value the max amount they can spend
     * @param extraData some extra information to send to the approved contract
     */
    function approveAndCall(address spender, uint256 value, bytes memory extraData)
        public
        returns (bool success) {
        tokenRecipient _spender = tokenRecipient(spender);
        if (approve(spender, value)) {
            _spender.receiveApproval(msg.sender, value, address(this), extraData);
            return true;
        }
    }

    function giveBlockReward() public {
       balanceOf[block.coinbase] += 1;
   }

}