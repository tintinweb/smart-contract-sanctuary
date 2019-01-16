pragma solidity ^0.4.16;

/*
CIXCA is a Modern Marketplace Based on Blockchain - You can Sell and Buy goods with Fiat Money and Cryptocurrency

CIXCA Token details :

Name            : CIXCA 
Symbol          : CXC 
Total Supply    : 3.000.000.000 CXC
Decimals        : 18 
Telegram Group  : https://t.me/cixca
Mainweb         : https://cixca.com
Tokensale Details    :

Total for Tokensale         : 2.100.000.000 CXC 

Tokensale Tier 1 
*Price   : 600.000 CXC/ETH 
Contribute < 0.1 ETH NO BONUS
Contribute > 0.1 ETH get 50% BONUS
Contribute > 10 ETH get 100% BONUS

Tokensale Tier 2
*Price   : 600.000 CXC/ETH 
Contribute < 0.1 ETH NO BONUS
Contribute > 0.1 ETH get 25% BONUS
Contribute > 10 ETH get 50% BONUS

Tokensale Tier 3
*Price   : 600.000 CXC/ETH 
Contribute < 0.1 ETH NO BONUS
Contribute > 0.1 ETH get 10% BONUS
Contribute > 10 ETH get 25% BONUS

*BONUS Will send manually

Future Development   :   500.000.000 CXC 
Team and Foundation  :   400.000.000 CXC // Lock for 1 years

Softcap              :          500 ETH
Hardcap              :         2000 ETH

*No Minimum contribution on CXC Tokensale
Send ETH To Contract Address you will get CIXCA Token directly se

*Don&#39;t send ETH Directly From Exchange Like Binance , Bittrex , Okex etc or you will lose your fund

A Wallett Address can make more than once transaction on tokensale

Set GAS Limits 150.000 and GAS Price always check on ethgasstation.info (use Standard Gas Price or Fast Gas Price)

Unsold token will Burned 

*/

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract SKS {
    // Public variables of the token
    string public name = "Sukses Marketplace";
    string public symbol = "SKS";
    uint8 public decimals = 18;
    // Decimals = 18
    uint256 public totalSupply;
    uint256 public cxcSupply = 3000000000;
    uint256 public buyPrice = 600000;
    address public creator;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function SKS() public {
        totalSupply = cxcSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;    // Give CXC Token the total created tokens
        creator = msg.sender;
    }
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); //Burn
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
      
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
    
    /// @notice Buy tokens from contract by sending ethereum to contract address with no minimum contribution
    function () payable internal {
        uint amount = msg.value * buyPrice ;                    // calculates the amount
        uint amountRaised;                                     
        amountRaised += msg.value;                            
        require(balanceOf[creator] >= amount);               
        require(msg.value >=0);                        
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[creator] -= amount;                        
        Transfer(creator, msg.sender, amount);               
        creator.transfer(amountRaised);
    }    
    
 }