/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.4.21;

 

/**
    HRC20Token Standard Token implementation
*/
contract HRC20 {

    string public name = 'TPD Token'; // Change it to your Token Name.
    string public symbol = 'TPD'; // Change it to your Token Symbol. Max 4 letters!
    
    string public standard = 'Token 0.1'; // Do not change this one.

    uint8 public decimals = 6; // It's recommended to set decimals to 8.
    
    uint256 public totalSupply = 100000000; // Change it to the Total Supply of your Token.
    address public owner=msg.sender;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function HRC20() public {
        totalSupply =  totalSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount

        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function _burn(address account, uint256 value) internal {
        require(account  != 0x0);
        totalSupply -=value; 
        balanceOf[account] -=value;
 
        emit Transfer(account,  0x0, value);
    }
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        _burn(msg.sender, _value);
    }
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function mintToken(address target, uint256 mintedAmount)  public {
 
        require(owner == msg.sender);   
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }


    // disable pay HTMLCOIN to this contract
    function () public payable {
        revert();
    }
}