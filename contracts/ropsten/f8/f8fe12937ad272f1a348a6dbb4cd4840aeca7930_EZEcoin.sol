pragma solidity 0.4.25;
/*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
                                                                   
                                                               
                                                               
EEEEEEEEEEEEEEEEEEEEEE  ZZZZZZZZZZZZZZZZZZZ  EEEEEEEEEEEEEEEEEEEEEE
E::::::::::::::::::::E  Z:::::::::::::::::Z  E::::::::::::::::::::E
E::::::::::::::::::::E  Z:::::::::::::::::Z  E::::::::::::::::::::E
EE::::::EEEEEEEEE::::E  Z:::ZZZZZZZZ:::::Z   EE::::::EEEEEEEEE::::E
  E:::::E       EEEEEE  ZZZZZ     Z:::::Z    E:::::E       EEEEEE
  E:::::E                       Z:::::Z        E:::::E             
  E::::::EEEEEEEEEE            Z:::::Z         E::::::EEEEEEEEEE   
  E:::::::::::::::E           Z:::::Z          E:::::::::::::::E   
  E:::::::::::::::E          Z:::::Z           E:::::::::::::::E   
  E::::::EEEEEEEEEE         Z:::::Z            E::::::EEEEEEEEEE   
  E:::::E                  Z:::::Z             E:::::E             
  E:::::E       EEEEEE  ZZZ:::::Z     ZZZZZ    E:::::E       EEEEEE
EE::::::EEEEEEEE:::::E  Z::::::ZZZZZZZZ:::Z  EE::::::EEEEEEEE:::::E
E::::::::::::::::::::E  Z:::::::::::::::::Z  E::::::::::::::::::::E
E::::::::::::::::::::E  Z:::::::::::::::::Z  E::::::::::::::::::::E
EEEEEEEEEEEEEEEEEEEEEE  ZZZZZZZZZZZZZZZZZZZ  EEEEEEEEEEEEEEEEEEEEEE
                                                               
                                                               
// ----------------------------------------------------------------------------
// &#39;EZE Coin&#39; token contract, having Crowdsale functionality
//
// Contract Owner : 0xef9EcD8a0A2E4b31d80B33E243761f4D93c990a8
// Symbol         : EZE
// Name           : EZE Coin
// Total supply   : 3,000,000   (3 Million)
// Tokens for ICO : 2,000,000   (2 Million)
// Tokens for Team: 1,000,000   (1 Million)
// Decimals       : 18
//
// Copyright &#169; 2018 onwards EzeChain (https://EzeChain.io)
// Contract designed by EtherAuthority (https://EtherAuthority.io)
// ----------------------------------------------------------------------------
*/

    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
      }
    
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
    
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    }
    
    contract owned {
        address public owner;
        
         constructor () public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
    
    contract TokenERC20 {
        /* Public variables of the token */
        using SafeMath for uint256;
        string public name;
        string public symbol;
        uint8 public decimals = 18;      // 18 decimals is the strongly suggested default, avoid changing it
        uint256 public totalSupply;
        uint256 public reservedForICO;
    
        /* This creates an array with all balances */
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
        /* This generates a public event on the blockchain that will notify clients */
        event Transfer(address indexed from, address indexed to, uint256 value);
    
        /* This notifies clients about the amount burnt */
        event Burn(address indexed from, uint256 value);
    
        /**
         * Constrctor function
         *
         * Initializes contract with initial supply tokens to the creator of the contract
         */
        constructor (
            uint256 initialSupply,
            uint256 allocatedForICO,
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1e18);               // Update total supply with the decimal amount
            reservedForICO = allocatedForICO.mul(1e18);          // Tokens reserved For ICO
            balanceOf[this] = reservedForICO;                    // 2 Million Tokens will remain in the contract
            balanceOf[msg.sender]=totalSupply.sub(reservedForICO); // Rest of tokens will be sent to owner
            name = tokenName;                                   // Set the name for display purposes
            symbol = tokenSymbol;                               // Set the symbol for display purposes
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
            require(balanceOf[_to].add(_value) > balanceOf[_to]);
            // Save this for an assertion in the future
            uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
            // Subtract from the sender
            balanceOf[_from] = balanceOf[_from].sub(_value);
            // Add the same to the recipient
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
            // Asserts are used to use static analysis to find bugs in your code. They should never fail
            assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
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
         * Transfer tokens from other address
         *
         * Send `_value` tokens to `_to` in behalf of `_from`
         *
         * @param _from The address of the sender
         * @param _to The address of the recipient
         * @param _value the amount to send
         */
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(_value <= allowance[_from][msg.sender]);     // Check allowance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
        }
    
        /**
         * Set allowance for other address
         *
         * Allows `_spender` to spend no more than `_value` tokens in your behalf
         *
         * @param _spender The address authorized to spend
         * @param _value the max amount they can spend
         */
        function approve(address _spender, uint256 _value) public returns (bool success) {
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
        function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
            totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
           emit Burn(msg.sender, _value);
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
            balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
            totalSupply = totalSupply.sub(_value);                              // Update totalSupply
            emit  Burn(_from, _value);
            return true;
        }
    }
    
    /***************************************************************************/
    /**                   MAIN EZE COIN CONTRACT STARTS HERE                  **/
    /***************************************************************************/
    
    contract EZEcoin is owned, TokenERC20 {
        
        //*************************************************//
        //-------  User whitelisting functionality  -------//
        //*************************************************//
        
        /* Public variables for whitelisting  */
        bool public whitelistingStatus = false;
        mapping (address => bool) public whitelisted;
        
        
        /**
         * Change whitelisting status on or off
         * When whitelisting is true, then crowdsale will only accept investors who are whitelisted.
         */
        function changeWhitelistingStatus() onlyOwner public{
            if (whitelistingStatus == false){
                whitelistingStatus = true;
            }
            else{
                whitelistingStatus = false;    
            }
        }
        
        /**
         * Whitelist any user address - only Owner can do this
         *
         * It will add user address in whitelisted mapping
         */
        function whitelistUser(address userAddress) onlyOwner public{
            require(whitelistingStatus == true);
            require(userAddress != 0x0);
            whitelisted[userAddress] = true;
        }
        
        /**
         * Whitelist Many user address at once - only Owner can do this
         * It will require maximum of 150 addresses to prevent block gas limit max-out and DoS attack
         * It will add user address in whitelisted mapping
         */
        function whitelistManyUsers(address[] userAddresses) onlyOwner public{
            require(whitelistingStatus == true);
            uint256 addressCount = userAddresses.length;
            require(addressCount <= 150);
            for(uint256 i = 0; i < addressCount; i++){
                require(userAddresses[i] != 0x0);
                whitelisted[userAddresses[i]] = true;
            }
        }
        
        
        //**************************************************//
        //------------- Code for the EZE Coin  -------------//
        //**************************************************//
        
        /* Public variables of the token  */
        string internal tokenName = "EZE Coin";
        string internal tokenSymbol = "EZE";
        uint256 internal initialSupply  = 3000000;  // 3 Million   
        uint256 private allocatedForICO = 2000000;  // 2 Million
    
        /* Records for the fronzen accounts  */ 
        mapping (address => bool) public frozenAccount;
    
        /* This generates a public event on the blockchain that will notify clients  */ 
        event FrozenFunds(address target, bool frozen);
    
        /* Initializes contract with initial supply of tokens sent to the creator as well as contract  */
        constructor () TokenERC20(initialSupply, allocatedForICO, tokenName, tokenSymbol) public { }
    
         
        /**
         * Transfer tokens - Internal transfer, only can be called by this contract
         * 
         * This checks if the sender or recipient is not fronzen
         * 
         * This keeps the track of total token holders and adds new holders as well.
         *
         * Send `_value` tokens to `_to` from your account
         *
         * @param _from The address of the sender
         * @param _to The address of the recipient
         * @param _value the amount of tokens to send
         */
        function _transfer(address _from, address _to, uint _value) internal {
            require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
            require (balanceOf[_from] >= _value);               // Check if the sender has enough
            require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
            require(!frozenAccount[_from]);                     // Check if sender is frozen
            require(!frozenAccount[_to]);                       // Check if recipient is frozen
            balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
            balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
            emit Transfer(_from, _to, _value);
        }
    
        /**
         * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
         * 
         * @param target Address to be frozen
         * @param freeze either to freeze it or not
         */
        function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
          emit  FrozenFunds(target, freeze);
        }
    
    
        //**************************************************//
        //------------- Code for the Crowdsale -------------//
        //**************************************************//
        
        /* Public variables for the Crowdsale  */
        /* For timestamp concersion:  https://etherauthority.io/tools/timestamp  */
        uint256 public privateSaleStart = 154232640;        // 21 Nov 1974 02:24:00 - GMT
        uint256 public preSaleStart   = 1554076799;         // 31 Mar 2019 23:59:59 - GMT
        uint256 public mainSaleStart = 1554576799;          // 06 Apr 2019 18:53:19 - GMT
        uint256 public icoEnd  = 1642218072;                // 15 Jan 2022 03:41:12 - GMT
        uint256 public exchangeRate = 5000;                 // 1 ETH = 5000 Tokens
        uint256 public minimumContribution = 1 ether;       // Minimum Contribution in pre sale as well as main sale
        uint256 public maximumContribution = 1000 ether;    // maximum Contribution
        uint256 public tokensSold = 0;                      // How many tokens sold in crowdsale
        
        
        /* Public variables for the bonuses  */
        uint256 public privateSaleBonus = 50;               // Bonus in Private-Sale
        uint256 public preSaleBonus = 30;                   // Bonus in Pre-Sale
        
        uint256 public mainSaleBonusPeriod1End = 1555576799;// Main-sale bonus period 1
        uint256 public mainSaleBonusPeriod2End = 1564576799;// Main-sale bonus period 2
        uint256 public mainSaleBonusPeriod3End = 1574576799;// Main-sale bonus period 3
        
        uint256 public mainSaleBonusPeriod1Percentage = 25; // Main-sale bonus period 1 percentage    
        uint256 public mainSaleBonusPeriod2Percentage = 15; // Main-sale bonus period 2 percentage
        uint256 public mainSaleBonusPeriod3Percentage = 5;  // Main-sale bonus period 3 percentage
                
        
        /**
         * @dev Fallback function, it accepts Ether while ICO is running, other wise reject
         * @dev It calcualtes token amount from exchangeRate and also adds Bonuses if applicable
         * @dev Ether will be forwarded to owner immidiately
         */
        function () payable public {
            
            if(whitelistingStatus == true) { require(whitelisted[msg.sender]); }
            
            require(msg.value >= minimumContribution && msg.value <= maximumContribution, &#39;Ether amount is either less than minimum or higher than maximum limit&#39;);
            require(now >= privateSaleStart && now <= icoEnd, &#39;Either private sale not started or ICO is ended&#39;);
            
            uint256 token = msg.value.mul(exchangeRate);            // token amount = weiamount * price
            uint256 totalTokens = token.add(purchaseBonus(token));  // token + bonus

            tokensSold = tokensSold.add(totalTokens);
            _transfer(this, msg.sender, totalTokens);               // makes the token transfer
            
            forwardEherToOwner();                                   // send ether to owner
            
        }
    
        
        /**
         * Automatocally forwards ether from smart contract to owner address.
         */
        function forwardEherToOwner() internal {
            owner.transfer(msg.value); 
        }
        
        /**
         * @dev Calculates purchase bonus according to the schedule.
         * @dev SafeMath at some place is not used intentionally as overflow is impossible, and that saves gas cost
         * 
         * @param _tokenAmount calculating tokens from amount of tokens 
         * 
         * @return bonus amount in wei
         * 
         */
        function purchaseBonus(uint256 _tokenAmount) public view returns(uint256){

            if(now > privateSaleStart && now < preSaleStart){
                return _tokenAmount.mul(privateSaleBonus).div(100);   //Private-sale bonus
            }
            else if(now > preSaleStart && now < mainSaleStart){
                return _tokenAmount.mul(preSaleBonus).div(100);   //Pre-sale bonus
            }
            else if(now > mainSaleStart && now < icoEnd){
                /* calculating individual bonus periods while main sale is going On */
                if(now > mainSaleStart && now < mainSaleBonusPeriod1End){
                    return _tokenAmount.mul(mainSaleBonusPeriod1Percentage).div(100);   //Main-sale Period 1 bonus
                }
                else if(now > mainSaleBonusPeriod1End && now < mainSaleBonusPeriod2End){
                    return _tokenAmount.mul(mainSaleBonusPeriod2Percentage).div(100);   //Main-sale Period 2 bonus
                }
                else if(now > mainSaleBonusPeriod2End && now < mainSaleBonusPeriod3End){
                    return _tokenAmount.mul(mainSaleBonusPeriod3Percentage).div(100);   //Main-sale Period 3 bonus
                }
                else{
                    return 0;   //No bonus for any period of main sale other than specified periods
                }
            }
            else{
                return 0;       //No bonus when ICO is ended
            }
        }
        
        /**
         * Updating dates of private sale, pre sale, main sale, and ICO end dates
         * The dates must be in timestamp
         * You can get timestamp for any dates at:  https://EtherAuthority.io/tools/timestamp
         * Only condition is that Private sale date must be less than pre sale date, which must be less than main sale date, which must be less than ICO end date
         */
        function updateIcoDates(uint256 privateSaleStartNew, uint256 preSaleStartNew, uint256 mainSaleStartNew, uint256 icoEndNew)onlyOwner public{
            require(privateSaleStartNew < preSaleStartNew && preSaleStartNew  < mainSaleStartNew && mainSaleStartNew < icoEndNew);
            privateSaleStart = privateSaleStartNew;
            preSaleStart = preSaleStartNew;
            mainSaleStart = mainSaleStartNew;
            icoEnd = icoEndNew;
        }
        
        /**
         * Update exchange rate
         * 1 Eth = how many tokens?
         */
        function updateExchangeRate(uint256 exchangeRateNew) onlyOwner public{
            exchangeRate = exchangeRateNew;
        }
        
        /**
         * Update all the bonus parameters
         * You need to enter all the parameters even if you want to update only one or few of those
         */
        function updateBonusParameters(uint256 privateSaleBonusNew, uint256 preSaleBonusNew, uint256 mainSaleBonusPeriod1EndNew, uint256 mainSaleBonusPeriod2EndNew, uint256 mainSaleBonusPeriod3EndNew, uint256 mainSaleBonusPeriod1PercentageNew, uint256 mainSaleBonusPeriod2PercentageNew, uint256 mainSaleBonusPeriod3PercentageNew ) onlyOwner public{
            
            privateSaleBonus = privateSaleBonusNew;    // Bonus in Private-Sale
            preSaleBonus = preSaleBonusNew;            // Bonus in Pre-Sale
            
            mainSaleBonusPeriod1End = mainSaleBonusPeriod1EndNew;  // Main-sale bonus period 1
            mainSaleBonusPeriod2End = mainSaleBonusPeriod2EndNew;  // Main-sale bonus period 2
            mainSaleBonusPeriod3End = mainSaleBonusPeriod3EndNew;  // Main-sale bonus period 3
            
            mainSaleBonusPeriod1Percentage = mainSaleBonusPeriod1PercentageNew; // Main-sale bonus period 1 percentage    
            mainSaleBonusPeriod2Percentage = mainSaleBonusPeriod2PercentageNew; // Main-sale bonus period 2 percentage
            mainSaleBonusPeriod3Percentage = mainSaleBonusPeriod3PercentageNew; // Main-sale bonus period 3 percentage
        
        }
        
        
        /**
         * Function to check wheter ICO is running or not. 
         * 
         * @return bool for whether ICO is running or not
         */
        function icoStatus() public view returns(string){
            if(now < privateSaleStart){
                return "ICO has not started yet";
            }
            else if(now > privateSaleStart && now < preSaleStart){
                return "Private-Sale is going on";
            }
            else if(now > preSaleStart && now < mainSaleStart){
                return "Pre-Sale is going on";
            }
            else if(now > mainSaleStart && now < icoEnd){
                return "Main-Sale is going on";
            }
            else{
                return "ICO is over";
            }
        }
        
        
        /**
         * Just in case, owner wants to transfer Tokens from contract to owner address
         */
        function manualWithdrawToken(uint256 _amount) onlyOwner public {
            uint256 tokenAmount = _amount.mul(1 ether);
            _transfer(this, msg.sender, tokenAmount);
        }
          
        /**
         * Just in case, owner wants to transfer Ether from contract to owner address
         */
        function manualWithdrawEther()onlyOwner public{
            address(owner).transfer(address(this).balance);
        }
        
        /**
         * Stops an ICO
         * It will just set the ICO end date to zero and thus it will stop an ICO
         */
        function stopICO() onlyOwner public{
            icoEnd = 0;
        }
        
        

        
        
    }