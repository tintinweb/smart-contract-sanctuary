pragma solidity ^0.4.16;

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract VixcoreToken2 is Owned {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;   
 
    uint public totalTokenSold; 
    uint public totalWeiReceived;  
    uint public weiBalance;  

    //EVENTS

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    //ETH Withdrawn
    event Withdrawal(address receiver, uint amount);

    //Token is purchased using Selfdrop
    event Selfdrop(address backer, uint weiAmount, uint token);

    //Over softcap set for Selfdrop
    event OverSoftCap(address receiver, uint weiAmount);





    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function VixcoreToken2(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender; 
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

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    } 

    /**
     * Default function when someone&#39;s transferring to this contract 
     * The next 3 functions are the same
     */  
    function () payable public {
        _pay();
    }

    function pay() payable public {  
        _pay();
    }  

    function _pay() internal { 
        uint weiValue = msg.value; 
        uint phase1 = 2500000000000000000000000000;
        uint phase2 = phase1 + 1500000000000000000000000000;
        uint phase3 = phase2 + 1000000000000000000000000000; //phase 3 should be less than supply

        if(totalTokenSold <= phase1){
            _exchange(weiValue, 5000000);
        }else if(totalTokenSold <= phase2){
            _exchange(weiValue, 4000000);
        }else if(totalTokenSold <= phase3){
            _exchange(weiValue, 3500000);
        }else{
            emit OverSoftCap(msg.sender, weiValue);
        } 
    }

    function _exchange(uint weiValue, uint rate) internal {
        uint tokenEquiv = tokenEquivalent(weiValue, rate);  
        _transfer(owner, msg.sender, tokenEquiv); 
        totalWeiReceived += weiValue;
        weiBalance += weiValue;
        totalTokenSold += tokenEquiv;
        emit Selfdrop(msg.sender, weiValue, tokenEquiv); 
    }

    function tokenEquivalent(uint weiValue, uint rate) public returns (uint) {
        return weiValue * rate;
    } 


    /**
     * Withdraw the funds
     *
     * Send the benefeciary some Wei
     * This function will emit the Withdrawal event if send it successful
     * Only owner can call this function 
     */
    function withdraw(uint _amount) onlyOwner public {
        require(_amount > 0);
        require(_amount <= weiBalance);     // Amount withdraw should be less or equal to balance
        if (owner.send(_amount)) {
            weiBalance -= _amount;
            emit Withdrawal(owner, _amount);
        }else{
            throw;
        }
    }


}