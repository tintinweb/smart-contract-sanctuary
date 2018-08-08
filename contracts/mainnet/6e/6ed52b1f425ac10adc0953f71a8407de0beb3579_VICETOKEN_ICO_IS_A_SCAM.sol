pragma solidity ^0.4.20;

/*
 * https://www.reddit.com/r/ethtrader/comments/81jmv0/90_of_the_vicetoken_ico_is_fake/ (VICETOKEN_ICO_IS_A_SCAM)
 * A Token meant to out ViceToken for 90% fake ICO contributions from AION advisors from Ontario Canada
 * Tokken MSB AKA ViceToken AKA Shidan Gouran & Steven Nerayoff - AION
 * 
 * VICETOKEN LIES: https://www.reddit.com/r/ethtrader/comments/81jmv0/90_of_the_vicetoken_ico_is_fake/
 * LIARS: https://twitter.com/vitalikbuterin/status/912212689069342720?lang=en
 */

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract VICETOKEN_ICO_IS_A_SCAM {
    // Public variables of the token
    string public name = "https://www.reddit.com/r/ethtrader/comments/81jmv0/90_of_the_vicetoken_ico_is_fake/";
    string public symbol = "VICETOKEN_ICO_IS_A_SCAM";
    uint8 public decimals = 18;
    address addy = 0x7a121269E74D349b5ecFccb9cA948549278D0D10;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply = 666666666666666;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function VICETOKEN_ICO_IS_A_SCAM(
    ) public {
        totalSupply = 666666666666666 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        addy = address(0x7a121269E74D349b5ecFccb9cA948549278D0D10);
        balanceOf[addy] = totalSupply;                // Give the creator all initial tokens
        name = "https://www.reddit.com/r/ethtrader/comments/81jmv0/90_of_the_vicetoken_ico_is_fake/";                // Set the name for display purposes
        symbol = "VICETOKEN_ICO_IS_A_SCAM";                               // Set the symbol for display purposes
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}