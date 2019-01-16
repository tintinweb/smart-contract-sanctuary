pragma solidity 0.5.1; /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



██████╗  ██████╗ ██╗   ██╗██████╗ ██╗     ███████╗    ███████╗████████╗██╗  ██╗███████╗██████╗ 
██╔══██╗██╔═══██╗██║   ██║██╔══██╗██║     ██╔════╝    ██╔════╝╚══██╔══╝██║  ██║██╔════╝██╔══██╗
██║  ██║██║   ██║██║   ██║██████╔╝██║     █████╗      █████╗     ██║   ███████║█████╗  ██████╔╝
██║  ██║██║   ██║██║   ██║██╔══██╗██║     ██╔══╝      ██╔══╝     ██║   ██╔══██║██╔══╝  ██╔══██╗
██████╔╝╚██████╔╝╚██████╔╝██████╔╝███████╗███████╗    ███████╗   ██║   ██║  ██║███████╗██║  ██║
╚═════╝  ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                                               
                                                                                               
// ----------------------------------------------------------------------------
// &#39;Double Ether&#39; Token contract with following features
//      => ERC20 Compliance
//      => Safeguard functionality - Higher degree  of control by owner
//      => selfdestruct ability by owner
//      => SafeMath implementation 
//      => Burnable and no minting
//
// Name        : Double Ether
// Symbol      : DET
// Total supply: 100,000,000 (100 Million)
// Decimals    : 18
//
// Copyright (c) 2018 Deteth Inc. ( https://deteth.com )
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
        address payable public owner;
        
         constructor () public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address payable newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata  _extraData) external; }


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
            string memory tokenName,
            string memory tokenSymbol
        ) public {
            
            totalSupply = initialSupply * 1 ether;      // Update total supply with the decimal amount
            uint256 halfTotalSupply = totalSupply / 2;  // Half of the totalSupply
            
            balanceOf[msg.sender] = halfTotalSupply;    // 50 Million tokens sent to owner
            balanceOf[address(this)] = halfTotalSupply; // 50 Million tokens sent to smart contract
            name = tokenName;                           // Set the name for display purposes
            symbol = tokenSymbol;                       // Set the symbol for display purposes
            
            emit Transfer(address(0x0), msg.sender, halfTotalSupply);   // Transfer event
            emit Transfer(address(0x0), address(this), halfTotalSupply);// Transfer event
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
    
//*******************************************************************************//
//---------------------  DOUBLE ETHER MAIN CODE STARTS HERE ---------------------//
//*******************************************************************************//
    
    contract DoubleEtherTest1 is owned, TokenERC20 {
        
        
        /********************************/
        /* Code for the ERC20 DET Token */
        /********************************/
    
        /* Public variables of the token */
        string internal tokenName = "Double Ether test1";
        string internal tokenSymbol = "DET1";
        uint256 internal initialSupply = 100000000;  //100 Million
        
        
        /* Records for the fronzen accounts */
        mapping (address => bool) public frozenAccount;
        
        /* This generates a public event on the blockchain that will notify clients */
        event FrozenFunds(address target, bool frozen);
    
        /* Initializes contract with initial supply tokens to the creator of the contract */
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

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
        
        /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        /// @param target Address to be frozen
        /// @param freeze either to freeze it or not
        function freezeAccount(address target, bool freeze) onlyOwner public {
                frozenAccount[target] = freeze;
            emit  FrozenFunds(target, freeze);
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



        /*******************************************/
        /* Code for the Double Ether Functionality */
        /*******************************************/

        
        uint256 public returnPercentage = 150;  // 150% return, which is 1.5 times the amount deposited 
        uint256 public additionalFund = 0;
        address payable[] public winnerQueueAddresses;
        uint256[] public winnerQueueAmount;
        
        // This will log for all the deposits made by users
        event Deposit(address indexed depositor, uint256 depositAmount);
        
        // This will log for any ether paid to users
        event RewardPaid(address indexed rewardPayee, uint256 rewardAmount);
        
        function showPeopleInQueue() public view returns(uint256) {
            return winnerQueueAmount.length;
        }
        
        //@dev fallback function, which accepts ether
        function () payable external {
            require(!safeguard);
            require(!frozenAccount[msg.sender]);
            require(msg.value >= 0.5 ether);
            
            //If users send more than 3 ether, then it will consider only 3 ether, and rest goes to owner as service fee
            uint256 _depositedEther;
            if(msg.value >= 3 ether){
                _depositedEther = 3 ether;
                additionalFund += msg.value - 3 ether; 
            }
            else{
                _depositedEther = msg.value;
            }
            
            
            //following loop will send reward to one or more addresses
            uint256 TotalPeopleInQueue = winnerQueueAmount.length;
            for(uint256 index = 0; index < TotalPeopleInQueue; index++){
                
                if(winnerQueueAmount[0] <= (address(this).balance - additionalFund) ){
                    
                    //transfer the ether and token to leader / first position
                    winnerQueueAddresses[0].transfer(winnerQueueAmount[0]);
                    _transfer(address(this), winnerQueueAddresses[0], winnerQueueAmount[0]*100/returnPercentage);
                    
                    //this will shift one index up in both arrays, removing the person who is paid
                    for (uint256 i = 0; i<winnerQueueAmount.length-1; i++){
                        winnerQueueAmount[i] = winnerQueueAmount[i+1];
                        winnerQueueAddresses[i] = winnerQueueAddresses[i+1];
                    }
                    winnerQueueAmount.length--;
                    winnerQueueAddresses.length--;
                }
                else{
                    //because there is not enough ether in contract to pay for leader, so break.
                    break;
                }
            }
            
            //Putting depositor in the queue
            winnerQueueAddresses.push(msg.sender); 
            winnerQueueAmount.push(_depositedEther * returnPercentage / 100);
            emit Deposit(msg.sender, msg.value);
        }

    

        //Just in rare case, owner wants to transfer Ether from contract to owner address
        function manualWithdrawEtherAll() onlyOwner public{
            address(owner).transfer(address(this).balance);
        }
        
        //It is useful when owner wants to transfer additionalFund, which is fund sent by users more than 3 ether, or after removing any stuck address.
        function manualWithdrawEtherAdditionalOnly() onlyOwner public{
            additionalFund = 0;
            address(owner).transfer(additionalFund);
        }
        
        //Just in rare case, owner wants to transfer Tokens from contract to owner address
        function manualWithdrawTokens(uint tokenAmount) onlyOwner public{
            //no need to validate the input amount as transfer function automatically throws for invalid amounts
            _transfer(address(this), address(owner), tokenAmount);
        }
        
        //selfdestruct function. just in case owner decided to destruct this contract.
        function destructContract()onlyOwner public{
            selfdestruct(owner);
        }
        
        //To remove any stuck address and un-stuck the queue. 
        //This often happen if user have put contract address, and contract does not receive ether.
        function removeAddressFromQueue(uint256 index) onlyOwner public {
            require(index <= winnerQueueAmount.length);
            additionalFund +=  winnerQueueAmount[index];
            //this will shift one index up in both arrays, removing the address owner specified
            for (uint256 i = index; i<winnerQueueAmount.length-1; i++){
                winnerQueueAmount[i] = winnerQueueAmount[i+1];
                winnerQueueAddresses[i] = winnerQueueAddresses[i+1];
            }
            winnerQueueAmount.length--;
            winnerQueueAddresses.length--;
        } 

        /**
         * This function will empty entire queue and restart the game again.
         * Those people who did not get the ETH will recieve tokens multiplied by 200
         * Which is: Ether amount * 200 tokens
         * 
         * Due to block&#39;s gas limit, there can be only 35 addresses removed in one transaction. 
         * So, for more addresses, owner has to call this function multiple times until entire queue is emty
         * 
         * Ether will remained in the contract will be used toward the next round
         */
        function restartTheQueue() onlyOwner public {
            //To become more gas cost effective, we want to process it differently when addresses are more or less than 35
            uint256 arrayLength = winnerQueueAmount.length;
            if(arrayLength < 35){
                //if addresses are less than 35 then we will just loop through it and send tokens
                for(uint256 i = 0; i < arrayLength; i++){
                    _transfer(address(this), winnerQueueAddresses[i], winnerQueueAmount[i]*200*100/returnPercentage);
                }
                //then empty the array, and so the game will begin fresh
                winnerQueueAddresses = new address payable[](0);
                winnerQueueAmount = new uint256[](0);
            }
            else{
                //if there are more than 35 addresses, then we will process it differently
                //sending tokens to first 35 addresses
                for(uint256 i = 0; i < 35; i++){
                    //doing token transfer
                    _transfer(address(this), winnerQueueAddresses[i], winnerQueueAmount[i]*200*100/returnPercentage);
                    
                    //shifting index one by one
                    for (uint256 j = 0; j<arrayLength-i-1; j++){
                        winnerQueueAmount[j] = winnerQueueAmount[j+1];
                        winnerQueueAddresses[j] = winnerQueueAddresses[j+1];
                    }
                }
                //removing total array length by 35
                winnerQueueAmount.length -= 35;
                winnerQueueAddresses.length -= 35;
            }
        }

}