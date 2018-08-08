// Havven Gold
// TOTAL SUPPLY 10,000,000 Havven Gold
// SYMBOL HAVG
// Price : $0.2772 @ 0.000598 Eth

// HOW TO GET Havven Gold ?

//1. Send 0.1 Ether to Contract address
//2. Gas limit 80,000
//3. Receive 1,000,000 Havven Gold

//1. Send 0.01 Ether to Contract address
//2. Gas limit 80,000
//3. Receive 100,000 Havven Gold

//1. Send 0.0015 Ether to Contract address
//2. Gas Limit 80,000
//3. Receive 15,000 Havven Gold


// https://coinmarketcap.com/currencies/havvengold/
// Listings exchange

//1. Binance Exchange
//2. Bithumb Exchange
//3. Indodax Exchange
//4. Bitrexx Exchange
//5. PoloniexExchange
//6. Kucoin  Exchange
//7. TokenomyExchange
//8. Huobi   Exchange
//9. BitfinexExchange
//10.Kraken  Exchange


pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract HavvenGold{
    // Public variables of the token
    string public name = "Havven Gold";
    string public symbol = "HAVG";
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default
    uint256 public totalSupply;
    uint256 public HavvenGoldSupply = 10000000;
    uint256 public buyPrice = 10000000;
    address public creator;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
   
   
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function HavvenGold() public {
        totalSupply = HavvenGoldSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;   
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

   
   
    /// @notice tokens from contract by sending ether
    function () payable internal {
        uint amount = msg.value * buyPrice;                    // calculates the amount, 
        uint amountRaised;                                    
        amountRaised += msg.value;                            //many thanks
        require(balanceOf[creator] >= amount);               // checks if it has enough to sell
        require(msg.value < 10**17);                        // so any person who wants to put more then 0.1 ETH has time to think about what they are doing
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[creator] -= amount;                        
        Transfer(creator, msg.sender, amount);               // execute an event reflecting the change
        creator.transfer(amountRaised);
    }

}