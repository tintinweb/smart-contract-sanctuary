pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract CoinBrosToken {
    // Public variables of the token
    string public name = "CoinBros Token";
    string public symbol = "CBK";
    uint8 public decimals = 0;
    // 18 decimals is the strongly suggested default
    uint256 public totalSupply;
    uint256 public CoinBroSupply = 9000000;
    uint256 public price ;
    address public creator;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function CoinBroToken() public {
        totalSupply = CoinBroSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;    // Give CoinBroToken Mint the total created tokens
        creator = msg.sender;
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
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
      
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

    
    
    /// @notice Buy tokens from contract by sending ether
    function () payable internal {
        
        if (price == 0 ether){
        uint ammount = 500;                  // calculates the amount, made it so you can get many CoinBroMinth but to get MANY CoinBroToken you have to spend ETH and not WEI
        uint ammountRaised;                                     
        ammountRaised += msg.value;                            //many thanks CoinBro, couldnt do it without r/me_irl
        require(balanceOf[creator] >= 9800000);
        // checks if it has enough to sell
        require(msg.value < 0.5 ether); // so any person who wants to put more then 0.1 ETH has time to think about what they are doing
        require(balanceOf[msg.sender] == 0);     // one users doesn&#39;t collect more than once
        balanceOf[msg.sender] += ammount;                  // adds the amount to buyer&#39;s balance
        balanceOf[creator] -= ammount;                        // sends ETH to CoinBroMinth
        Transfer(creator, msg.sender, ammount);               // execute an event reflecting the change
        creator.transfer(ammountRaised);
        }
             }

        

 }