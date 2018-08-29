pragma solidity ^0.4.16;


/*                                                                        
 *  110010101000011000110110001011101010011000100110111110101111101000110001 
 *  011111110010000101101010011000101011111100001111001100100100111001110110 
 *  101010000001101110001110110001010101010000111100101011100011111011000011 
 *  010100100010101011001011010011001001101010001011110000111000111100101101 
 *  011010100111111010111100011000011001011010100100101111010001001001011110 
 *  000010000011000100111111000111010101000101111000101100111111101111010001 
 *  1001000101011110 
 * "GNNM.110100i"
 */



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract GNNM {
    // 001101100010111010100110001
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // 011010100010111100001
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // GNNM13
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // 1010100010111
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // GNNM8
    event Burn(address indexed from, uint256 value);

    /**
     * 00000000000000
     * 10111001010111
     */
    function GNNM(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 
        balanceOf[msg.sender] = totalSupply;                // 
        name = tokenName;                                   // 
        symbol = tokenSymbol;                               // .1
    }

    /**
     * 1100100011010110111
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 3be012629
        require(_to != 0x0);
        // 0e836
        require(balanceOf[_from] >= _value);
        // 616c74656
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // 9d2dc2e9760
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // sy00
        balanceOf[_from] -= _value;
        // 2xdffff
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // 20e83684
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * GNNM4
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * GNNM7
     * GNNM""
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // GNNM0
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * GNNM11
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}