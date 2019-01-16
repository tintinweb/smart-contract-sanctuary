pragma solidity ^0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


 .----------------.  .----------------.  .----------------.  .----------------.  .-----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |    _______   | || |  _________   | || |   _______    | || |  _________   | || | ____  _____  | |
| |   /  ___  |  | || | |_   ___  |  | || |  |  ___  |   | || | |_   ___  |  | || ||_   \|_   _| | |
| |  |  (__ \_|  | || |   | |_  \_|  | || |  |_/  / /    | || |   | |_  \_|  | || |  |   \ | |   | |
| |   &#39;.___`-.   | || |   |  _|  _   | || |      / /     | || |   |  _|  _   | || |  | |\ \| |   | |
| |  |`\____) |  | || |  _| |___/ |  | || |     / /      | || |  _| |___/ |  | || | _| |_\   |_  | |
| |  |_______.&#39;  | || | |_________|  | || |    /_/       | || | |_________|  | || ||_____|\____| | |
| |              | || |              | || |              | || |              | || |              | |
| &#39;--------------&#39; || &#39;--------------&#39; || &#39;--------------&#39; || &#39;--------------&#39; || &#39;--------------&#39; |
 &#39;----------------&#39;  &#39;----------------&#39;  &#39;----------------&#39;  &#39;----------------&#39;  &#39;----------------&#39; 


// ----------------------------------------------------------------------------
// &#39;se7en&#39; Token contract with following features
//      => In-built ICO functionality
//      => ERC20 Compliance
//      => Higher control of ICO by owner
//      => selfdestruct functionality
//      => SafeMath implementation 
//      => Air-drop
//      => User whitelisting
//      => Minting/burning by owner
//
// Name        : se7en
// Symbol      : S7N
// Total supply: 74,243,687,134
// Reserved coins for ICO: 7,424,368,713
// Decimals    : 18
//
// Copyright (c) 2018 XSe7en Social Media Inc. ( https://se7en.social )
// Contract designed by EtherAuthority ( https://EtherAuthority.io )
// ----------------------------------------------------------------------------
   
*/ 

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
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


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
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
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; }


//***************************************************************//
//------------------ ERC20 Standard Template -------------------//
//***************************************************************//
    
    contract TokenERC20 {
        // Public variables of the token
        using SafeMath for uint256;
        string public name;
        string public symbol;
        uint8 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
        uint256 public totalSupply;
        uint256 public reservedForICO;
        bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    
        // This creates an array with all balances
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
        // This generates a public event on the blockchain that will notify clients
        event Transfer(address indexed from, address indexed to, uint256 value);
    
        // This notifies clients about the amount burnt
        event Burn(address indexed from, uint256 value);
    
        /**
         * Constrctor function
         *
         * Initializes contract with initial supply tokens to the creator of the contract
         */
        constructor (
            uint256 initialSupply,
            uint256 allocatedForICO,
            string memory tokenName,
            string memory tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1 ether);       // Update total supply with the decimal amount
            reservedForICO = allocatedForICO.mul(1 ether);  // Tokens reserved For ICO
            balanceOf[address(this)] = reservedForICO;      // 7,424,368,713 Tokens will remain in the contract
            balanceOf[msg.sender]=totalSupply.sub(reservedForICO); // Rest of tokens will be sent to owner
            name = tokenName;                               // Set the name for display purposes
            symbol = tokenSymbol;                           // Set the symbol for display purposes
        }
    
        /**
         * Internal transfer, only can be called by this contract
         */
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
            // Prevent transfer to 0x0 address. Use burn() instead
            require(_to != address(0x0));
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
            require(!safeguard);
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
        function approve(address _spender, uint256 _value) public
            returns (bool success) {
            require(!safeguard);
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
        function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
            public
            returns (bool success) {
            require(!safeguard);
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, address(this), _extraData);
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
            require(!safeguard);
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
            require(!safeguard);
            require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
            require(_value <= allowance[_from][msg.sender]);    // Check allowance
            balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
            totalSupply = totalSupply.sub(_value);                              // Update totalSupply
            emit  Burn(_from, _value);
            return true;
        }
        
    }
    
//************************************************************************//
//---------------------  SE7EN MAIN CODE STARTS HERE ---------------------//
//************************************************************************//
    
    contract se7en is owned, TokenERC20 {
        
        /*************************************/
        /*  User whitelisting functionality  */
        /*************************************/
        bool public whitelistingStatus = false;
        mapping (address => bool) public whitelisted;
        
        /**
         * Change whitelisting status on or off
         *
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
            require(userAddress != address(0x0));
            whitelisted[userAddress] = true;
        }
        
        /**
         * Whitelist Many user address at once - only Owner can do this
         * It will require maximum of 150 addresses to prevent block gas limit max-out and DoS attack
         * It will add user address in whitelisted mapping
         */
        function whitelistManyUsers(address[] memory userAddresses) onlyOwner public{
            require(whitelistingStatus == true);
            uint256 addressCount = userAddresses.length;
            require(addressCount <= 150);
            for(uint256 i = 0; i < addressCount; i++){
                require(userAddresses[i] != address(0x0));
                whitelisted[userAddresses[i]] = true;
            }
        }
        
        
        
        /********************************/
        /* Code for the ERC20 S7N Token */
        /********************************/
    
        /* Public variables of the token */
        string private tokenName = "se7en";
        string private tokenSymbol = "S7N";
        uint256 private initialSupply = 74243687134;
        uint256 private allocatedForICO = 7424368713;
        
        
        /* Records for the fronzen accounts */
        mapping (address => bool) public frozenAccount;
        
        /* This generates a public event on the blockchain that will notify clients */
        event FrozenFunds(address target, bool frozen);
    
        /* Initializes contract with initial supply tokens to the creator of the contract */
        constructor () TokenERC20(initialSupply, allocatedForICO, tokenName, tokenSymbol) public {}

        /* Internal transfer, only can be called by this contract */
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
            require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
            require (balanceOf[_from] >= _value);               // Check if the sender has enough
            require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
            require(!frozenAccount[_from]);                     // Check if sender is frozen
            require(!frozenAccount[_to]);                       // Check if recipient is frozen
            balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
            balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
            emit Transfer(_from, _to, _value);
        }
        
        /// @notice Create `mintedAmount` tokens and send it to `target`
        /// @param target Address to receive the tokens
        /// @param mintedAmount the amount of tokens it will receive
        function mintToken(address target, uint256 mintedAmount) onlyOwner public {
            balanceOf[target] = balanceOf[target].add(mintedAmount);
            totalSupply = totalSupply.add(mintedAmount);
            emit Transfer(address(0x0), address(this), mintedAmount);
            emit Transfer(address(this), target, mintedAmount);
        }

        /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        /// @param target Address to be frozen
        /// @param freeze either to freeze it or not
        function freezeAccount(address target, bool freeze) onlyOwner public {
                frozenAccount[target] = freeze;
            emit  FrozenFunds(target, freeze);
        }

        /******************************/
        /* Code for the S7N Crowdsale */
        /******************************/
        
        /* TECHNICAL SPECIFICATIONS:
        
        => ICO Phases details   : 
            Pre Sale    - Dec 16 - Dec 31, 2018 (minimum 1 ETH 50% Bonus) 
            ICO Phase 1 - January 1 - 15, 2019 - 20% Bonus (No minimum or maximum contribution)
            ICO Phase 2 - January 16 - 31, 2019 - 10% Bonus (No minimum or maximum contribution)
            ICO Phase 3 - February 1 - 28, 2019 - 5% Bonus (No minimum or maximum contribution)
        => Token Exchange Rate  :  1 ETH = 1298 Tokens (which equivalents to 1 Tokens ≈ 0.00077 ETH)
        => Coins reserved for ICO : 7,424,368,713 
        
        */

        //public variables for the Crowdsale
        //to convert date to timestamp: https://etherauthority.io/tools/timestamp
        uint256 public datePreSale   = 1544943600 ;      // 16 Dec 2018 07:00:00 - GMT
        uint256 public dateIcoPhase1 = 1546326000 ;      // 01 Jan 2019 07:00:00 - GMT
        uint256 public dateIcoPhase2 = 1547622000 ;      // 16 Jan 2019 07:00:00 - GMT
        uint256 public dateIcoPhase3 = 1549004400 ;      // 01 Feb 2019 07:00:00 - GMT
        uint256 public dateIcoEnd    = 1551398399 ;      // 28 Feb 2019 23:59:59 - GMT
        uint256 public exchangeRate  = 1298;             // 1 ETH = 1298 Tokens 
        uint256 public tokensSold    = 0;                // how many tokens sold through crowdsale
        
        //@dev fallback function, only accepts ether if pre-sale or ICO is running or Reject
        function () payable external {
            require(!safeguard);
            require(!frozenAccount[msg.sender]);
            require(datePreSale < now && dateIcoEnd > now);
            if(whitelistingStatus == true) { require(whitelisted[msg.sender]); }
            if(datePreSale < now && dateIcoPhase1 > now){ require(msg.value >= (1 ether)); }
            // calculate token amount to be sent
            uint256 token = msg.value.mul(exchangeRate);                        //weiamount * exchangeRate
            uint256 finalTokens = token.add(calculatePurchaseBonus(token));     //add bonus if available
            tokensSold = tokensSold.add(finalTokens);
            _transfer(address(this), msg.sender, finalTokens);                  //makes the transfers
            forwardEherToOwner();                                               //send Ether to owner
        }

        
        //calculating purchase bonus
        function calculatePurchaseBonus(uint256 token) internal view returns(uint256){
            if(datePreSale < now && now < dateIcoPhase1 ){
                return token.mul(50).div(100);  //50% bonus in pre sale
            }
            else if(dateIcoPhase1 < now && now < dateIcoPhase2 ){
                return token.mul(20).div(100);  //20% bonus in ICO phase 1
            }
            else if(dateIcoPhase2 < now && now < dateIcoPhase3 ){
                return token.mul(10).div(100);  //10% bonus in ICO phase 2
            }
            else if(dateIcoPhase3 < now && now < dateIcoEnd ){
                return token.mul(5).div(100);  //5% bonus in ICO phase 3
            }
            else{
                return 0;                      //NO BONUS
            }
        }

        //Automatocally forwards ether from smart contract to owner address
        function forwardEherToOwner() internal {
            address(owner).transfer(msg.value); 
        }

        //Function to update an ICO parameter.
        //It requires: timestamp of all the dates
        //For date to timestamp conversion: https://etherauthority.io/tools/timestamp
        //Owner need to make sure the contract has enough tokens for ICO. 
        //If not enough, then he needs to transfer some tokens into contract addresss from his wallet
        //If there are no tokens in smart contract address, then ICO will not work.
        //Only thing is required is that all the dates of phases must be in ascending order.
        function updateCrowdsale(uint256 datePreSaleNew, uint256 dateIcoPhase1New, uint256 dateIcoPhase2New, uint256 dateIcoPhase3New, uint256 dateIcoEndNew) onlyOwner public {
            require(datePreSaleNew < dateIcoPhase1New && dateIcoPhase1New < dateIcoPhase2New);
            require(dateIcoPhase2New < dateIcoPhase3New && dateIcoPhase3New < dateIcoEnd);
            datePreSale   = datePreSaleNew;
            dateIcoPhase1 = dateIcoPhase1New;
            dateIcoPhase2 = dateIcoPhase2New;
            dateIcoPhase3 = dateIcoPhase3New;
            dateIcoEnd    = dateIcoEndNew;
        }
        
        //Stops an ICO.
        //It will just set the ICO end date to zero and thus it will stop an ICO
        function stopICO() onlyOwner public{
            dateIcoEnd = 0;
        }
        
        //function to check wheter ICO is running or not. 
        //It will return current state of the crowdsale
        function icoStatus() public view returns(string memory){
            if(datePreSale > now ){
                return "Pre sale has not started yet";
            }
            else if(datePreSale < now && now < dateIcoPhase1){
                return "Pre sale is running";
            }
            else if(dateIcoPhase1 < now && now < dateIcoPhase2){
                return "ICO phase 1 is running";
            }
            else if(dateIcoPhase2 < now && now < dateIcoPhase3){
                return "ICO phase 2 is running";
            }
            else if(dateIcoPhase3 < now && now < dateIcoEnd){
                return "ICO phase 3 is running";
            }
            else{
                return "ICO is not active";
            }
        }
        
        //Function to set ICO Exchange rate. 
        //1 ETH = How many Tokens ?
        function setICOExchangeRate(uint256 newExchangeRate) onlyOwner public {
            exchangeRate=newExchangeRate;
        }
        
        //Just in case, owner wants to transfer Tokens from contract to owner address
        function manualWithdrawToken(uint256 _amount) onlyOwner public {
            uint256 tokenAmount = _amount.mul(1 ether);
            _transfer(address(this), msg.sender, tokenAmount);
        }
          
        //Just in case, owner wants to transfer Ether from contract to owner address
        function manualWithdrawEther()onlyOwner public{
            address(owner).transfer(address(this).balance);
        }
        
        //selfdestruct function. just in case owner decided to destruct this contract.
        function destructContract()onlyOwner public{
            selfdestruct(owner);
        }
        
        /**
         * Change safeguard status on or off
         *
         * When safeguard is true, then all the non-owner functions will stop working.
         * When safeguard is false, then all the functions will resume working back again!
         */
        function changeSafeguardStatus() onlyOwner public{
            if (safeguard == false){
                safeguard = true;
            }
            else{
                safeguard = false;    
            }
        }
        
        
        /********************************/
        /* Code for the Air drop of S7N */
        /********************************/
        
        /**
         * Run an Air-Drop
         *
         * It requires an array of all the addresses and amount of tokens to distribute
         * It will only process first 150 recipients. That limit is fixed to prevent gas limit
         */
        function airdrop(address[] memory recipients,uint tokenAmount) public onlyOwner {
            uint256 addressCount = recipients.length;
            require(addressCount <= 150);
            for(uint i = 0; i < addressCount; i++)
            {
                  //This will loop through all the recipients and send them the specified tokens
                  _transfer(address(this), recipients[i], tokenAmount.mul(1 ether));
            }
        }
}