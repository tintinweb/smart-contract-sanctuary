pragma solidity ^0.4.23;

/**

    https://zethr.io https://zethr.io https://zethr.io https://zethr.io https://zethr.io


                          ███████╗███████╗████████╗██╗  ██╗██████╗
                          ╚══███╔╝██╔════╝╚══██╔══╝██║  ██║██╔══██╗
                            ███╔╝ █████╗     ██║   ███████║██████╔╝
                           ███╔╝  ██╔══╝     ██║   ██╔══██║██╔══██╗
                          ███████╗███████╗   ██║   ██║  ██║██║  ██║
                          ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝


.------..------.     .------..------..------.     .------..------..------..------..------.
|B.--. ||E.--. |.-.  |T.--. ||H.--. ||E.--. |.-.  |H.--. ||O.--. ||U.--. ||S.--. ||E.--. |
| :(): || (\/) (( )) | :/\: || :/\: || (\/) (( )) | :/\: || :/\: || (\/) || :/\: || (\/) |
| ()() || :\/: |&#39;-.-.| (__) || (__) || :\/: |&#39;-.-.| (__) || :\/: || :\/: || :\/: || :\/: |
| &#39;--&#39;B|| &#39;--&#39;E| (( )) &#39;--&#39;T|| &#39;--&#39;H|| &#39;--&#39;E| (( )) &#39;--&#39;H|| &#39;--&#39;O|| &#39;--&#39;U|| &#39;--&#39;S|| &#39;--&#39;E|
`------&#39;`------&#39;  &#39;-&#39;`------&#39;`------&#39;`------&#39;  &#39;-&#39;`------&#39;`------&#39;`------&#39;`------&#39;`------&#39;

An interactive, variable-dividend rate contract with an ICO-capped price floor and collectibles.

Bankroll contract, containing tokens purchased from all dividend-card profit and ICO dividends.
Acts as token repository for games on the Zethr platform.


Credits
=======

Analysis:
    blurr
    Randall

Contract Developers:
    Etherguy
    klob
    Norsefire

Front-End Design:
    cryptodude
    oguzhanox
    TropicalRogue

**/

contract ZTHInterface {
    function buyAndSetDivPercentage(address _referredBy, uint8 _divChoice, string providedUnhashedPass) public payable returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address _to, uint _value)     public returns (bool);
    function transferFrom(address _from, address _toAddress, uint _amountOfTokens) public returns (bool);
    function exit() public;
    function sell(uint amountOfTokens) public;
    function withdraw(address _recipient) public;
    function getUserAverageDividendRate(address user) public view returns (uint);
}

// Interface of zethr games 
contract ZethrGameInterface{
    function execute(address from, uint value, uint userDivRate, bytes data) public;
}

contract ERC223Receiving {
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// Interface of master bankroll
contract ZethrBankroll {
    address public stakeAddress;
    mapping (address => bool) public isOwner;
    function changeAllocation(address what, int delta) public;
}

// Library to return the actual tier of an average dividend rate 
library ZethrTierLibrary{
    uint constant internal magnitude = 2**64;

    // Gets the tier (1-7) of the divs sent based off of average dividend rate
    // This is an index used to call into the correct sub-bankroll to withdraw tokens
    function getTier(uint divRate) internal pure returns (uint){
        
        // Divide the average dividned rate by magnitude
        // Remainder doesn&#39;t matter because of the below logic
        uint actualDiv = divRate / magnitude; 
        if (actualDiv >= 30){
            return 7;
        }
        else if (actualDiv >= 25){
            return 6;
        }
        else if (actualDiv >= 20){
            return 5;
        }
        else if (actualDiv >= 15){
            return 4;
        }
        else if (actualDiv >= 10){
            return 3; 
        }
        else if (actualDiv >= 5){
            return 2;
        }
        else if (actualDiv >= 2){
            return 1;
        }
        else{
            // Should be impossible
            revert();
        }
    }
}

contract ZethrTokenBankroll is ERC223Receiving {

    /*=================================
    =          LIST OF OWNERS         =
    =================================*/

    /*
        This list is for reference/identification purposes only, and comprises the eight core Zethr developers.
        For game contracts to be listed, they must be approved by a majority (i.e. currently five) of the owners.
        Contracts can be delisted in an emergency by a single owner.

        0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae // Norsefire
        0x11e52c75998fe2E7928B191bfc5B25937Ca16741 // klob
        0x20C945800de43394F70D789874a4daC9cFA57451 // Etherguy
        0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB // blurr
        0x8537aa2911b193e5B377938A723D805bb0865670 // oguzhanox
        0x9D221b2100CbE5F05a0d2048E2556a6Df6f9a6C3 // Randall
        0x71009e9E4e5e68e77ECc7ef2f2E95cbD98c6E696 // cryptodude
        0xDa83156106c4dba7A26E9bF2Ca91E273350aa551 // TropicalRogue
    */
    
    // Mapping of whitelisted contracts
    mapping(address => bool) public whitelistedContract; 
  
    // Daily allocation mapping is master bankroll
    // mapping(address => uint) public dailyAllocation;
    
    mapping (address => uint) public tokenVolumeInput; // tokens in per game 
    mapping (address => uint) public tokenVolumeOutput; // tokens out per  game 
    mapping (address => uint) public gameTokenAmount; // track tokens per game
    mapping (address => uint) public gameTokenAllocation; // game token allocation 
    
    // "free" tokens in the contract, can be allocated to games
    uint public freeTokens;
    
    // List of all games
    address[] public games; 
    
    // Zethr main contract address
    address Zethr; 
  
    // Zethr interface
    ZTHInterface ZethrContract;  

    // Zethr bankroll address
    address ZethrMainBankroll; 
    
    // Dividend rate of this tokenBankroll
    uint public divRate;

    // "tier" of this tokeknBankroll (1-7)
    uint public tier;
    
    // Magnitude for calculating average div rate
    uint constant internal magnitude = 2**64;
    
    // Requires supplied address to be a whitelisted contract
    // Pulls from master bankroll
    modifier contractIsWhiteListed(address ctr){
        require(whitelistedContract[ctr]);
        _;
    }
    
    // Requires msg.sender to be a dev or the bankroll
    modifier onlyDevOrBankroll(){
        require(msg.sender == ZethrMainBankroll || ZethrBankroll(ZethrMainBankroll).isOwner(msg.sender));
        _;
    }
    
    // Requires msg.sender to be a dev
    modifier onlyDev(){
        require(ZethrBankroll(ZethrMainBankroll).isOwner(msg.sender));
        _;
    }

    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/

    /// @dev Contract constructor sets sub roll divrate 
    constructor (uint ctrDivRate) public {
        // Set the address of Zethr main contract
        Zethr = address(0xD48B633045af65fF636F3c6edd744748351E020D); 
       
        // Instantiate the Zethr contract 
        ZethrContract = ZTHInterface(Zethr);

    	// Set the master bankroll address
        ZethrMainBankroll = address(0x1866abdba62468c33c32eb9cc366923af4b760f9); 
        
        // Dev addresses are pulled from the bankroll
        
        // Set this tokenBankroll&#39;s dividend rate
        divRate = ctrDivRate;

        // Set this token&#39;s dividend tier (1-7)
        tier = ZethrTierLibrary.getTier(divRate * magnitude);
    }

    // Admin / bankroll function to change bankroll address
    function setBankroll(address bankrollAddress) public onlyDevOrBankroll() {
      ZethrMainBankroll =  bankrollAddress;
    }

    // Assembly function 
    // Takes: bytes data as input 
    // Returns: the address we want to call 
    // plus the remaining bytes of data which should be fed to the game
    
    /*
        Layout of the actual bytes data as input: 
        First bytes32: an address you want to call to (the game address)
        (Optional) extra bytes32: remaining data 
        Padding of the address is how we see it in raw tx data: 0x00...address 
        
        Input MUST have bytes which are a multiple of 32 
        Input MUST have at least one bytes32 
        
        Test cases 
            Only address
            0x000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa551
            Address + bytes 
            0x000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa551000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa551
            Address + 2 bytes 
            0x000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa551000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa551000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa551
        
        Error cases: 
            Not a multiple of 32 
            0x000000000000000000000000Da83156106c4dba7A26E9bF2Ca91E273350aa5
            Empty
            0x0 
            
        Note: sanity check is done after the getData call to check if address is a contract 
    */
    function getData(bytes data) public pure returns (address, bytes rem) {
        // edge case: len 0 should revert 
        // case: len 1 should only parse addr and empty bytes 
        // case: len more should forloop over bytes and dump them 
        
        require(data.length == (data.length/32) * 32); // sanity check only bytes32 multiples 
    
        // no address found 
        if (data.length == 0) {
            revert(); // no data 
        }
    
        address out_a;
        bytes memory out_b; // initialzie to empty array 
        
        
        // start the assembly magic 
        if (data.length == 32){
            // ONLY an address, rest is empty data. Fine! 
            assembly {
                // Things to know here: 
                // x := bla sets x to bla 
                // mload loads 32 bytes, the input is the memory slot 
                // vars used here are actually POINTERS not the actual data! 
                // Logic (IMPORTANT)
                // A bytes is laid out in solidity as: 
                // first bytes32: a uint which has the LENGTH of this byte 
                // the length of the byte is the numbers of bytes (so in here its a multiple of 32, aka 0x20!)
                //So if we want to retrieve the actual data at the first slot (hence, the address) we need
                //to add 32 bytes to the actual pointer of data, to skip over the length bytes32 
                //then we load this bytes32 and dump it into out_a 
                out_a := mload(add(data, 0x20)) // load first byte into the address slot 
            }
        }
        else{
            // Logic: remove 32 from the actual data length because we want to remove the game address from the data 
            // (Why do that here not in the game? Because it adds a load of code)
            uint len = data.length - 32;
            assembly {
                out_a := mload(add(data, 0x20)) // load first byte into the address slot, same as above in case of only the address 
                // at the out_b pointer, we store the length we want this bytes to have 
                // yup - thats the number of bytes in data (data.length) minus 32 as defined above 
                mstore(out_b, len)
                // now we will actually fill this bytes 
                // for loop: for(uint i=0; i<len; i++)
                for { let i := 0 } lt(i, div(len, 0x20)) { i := add(i, 0x1) } {
                    // calculate the memory slot we want to dump data in: 
                    // take the out_b pointer 
                    // add 32 * (i+1) to this (could have optimized this)
                    let mem_slot := add(out_b, mul(0x20, add(i,1)))
                    // calculate the load slot where we want to actually read memory from 
                    // this is the same as the memory slot we want to write to, +32 
                    // this makes sense becausae we want to basically move all bytes32 one place back! 
                    let load_slot := add(mem_slot,0x20)
                    // actually dump the loaded memory at load_slot into mem_slot 
                    mstore(mem_slot, mload(load_slot))
                }
            }
        }
        //uint codelen;
        //assembly{
          //  codelen := extcodesize(out_a)
        //}
        // require(codelen > 0); // sanity check we are delegate of a contract 
        return (out_a, out_b);
    }

    // Returns true if supplied address is a contract
		// Does not return true if this contract is deployed during this block
    function isContract(address ctr) internal view returns (bool){
        uint codelen;
        assembly{
            codelen := extcodesize(ctr)
        }
        return (codelen > 0);
    }

  // Token fallback - gets entered when users transfer tokens to this contract 
	function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool) {

			// Can only be called from Zethr
	    require(msg.sender == Zethr); 

			// Get the user&#39;s dividend rate
			// This is a big nasty number
	    uint userDivRate = ZethrContract.getUserAverageDividendRate(_from);

			// Calculate the user&#39;s tier, and make sure it is appropriate for this contract
			// (sanity check)
	    require(ZethrTierLibrary.getTier(userDivRate) == tier); 

	    address target;  
	    bytes memory remaining_data;

	    // Grab the data we want to forward (target is the game address)
	    (target, remaining_data) = getData(_data);

	    // Sanity check to make sure we&#39;re calling a contract
	    require(isContract(target));

	    // Sanity check to make sure this game is actually one which can use the bankroll 
	    require(whitelistedContract[target]);
	    
			// Add tokens the game&#39;s token amount counter (for this contract only)
	    gameTokenAmount[target] = SafeMath.add(gameTokenAmount[target], _amountOfTokens);

			// Add tokens the game&#39;s token volume counter (for this contract only)
	    tokenVolumeInput[target] = SafeMath.add(tokenVolumeInput[target], _amountOfTokens);
	    
	    // EXECUTE the actual game! 
			// Call into the game with data
	    ZethrGameInterface(target).execute(_from, _amountOfTokens, userDivRate, remaining_data);
	}	
	
	// Function called ONLY by a whitelisted game
	// Sends tokens to the target address (player)
	function gameRequestTokens(address target, uint tokens) 
	    public 
	    contractIsWhiteListed(msg.sender)
    {
			// Don&#39;t sent more tokens than the game owns
	    require(gameTokenAmount[msg.sender] >= tokens);  

			// Subtract the amount of tokens the game owns
	    gameTokenAmount[msg.sender] = gameTokenAmount[msg.sender] - tokens; 

			// Update output volume
	    tokenVolumeOutput[msg.sender] = tokenVolumeOutput[msg.sender] + tokens; 

			// Actually transfer. Re-entrancy possibility
	    ZethrContract.transfer(target, tokens);
	}
	
	// Add a game to the whitelist. Can only be called by dev or bankroll.	
	function addGame(address game, uint allocated)
	    onlyDevOrBankroll
	    public
    {
				// Push the game address to the list
        games.push(game); 

				// Set the token allocation
        gameTokenAllocation[game] = allocated; 

				// If we have enough "free" tokens, allocate them
        if (freeTokens >= allocated){ 
            freeTokens = SafeMath.sub(freeTokens, allocated);
            gameTokenAmount[game] = allocated;
        }

        // Change this tokenbankroll&#39;s allocation
        ZethrBankroll(ZethrMainBankroll).changeAllocation(address(this), int(allocated));

				// Ad the game to the whitelisted addresses
        whitelistedContract[game] = true; 
    }
    
    // Remove the game from the list & dewhitelist it
    function removeGame(address game)
        public
        onlyDevOrBankroll
        contractIsWhiteListed(game) // Only remove games which are added 
    {
        // Loop over games to find the actual index to remove 
        for (uint i=0; i < games.length; i++){
            if (games[i] == game){
                games[i] = address(0x0); // Delete it 
                if (i != games.length){ // If its NOT at the end remove the last game address into the array TO this position
                    games[i] = games[games.length];
                }
                games.length = games.length - 1; // Remove 1 from length 
                break; // Found it, great 
            }
        }

        // Add remaining tokens from game to the "free" list 
        freeTokens = SafeMath.add(freeTokens, gameTokenAmount[game]);

        // Aint got no tokens 
        gameTokenAmount[game] = 0;

        // Aint whitelisted 
        whitelistedContract[game] = false;

        // Change this tokenBankroll&#39;s allocation
        ZethrBankroll(ZethrMainBankroll).changeAllocation(address(this), int(-gameTokenAllocation[game]));

        // No allocate 
        gameTokenAllocation[game] = 0;
    }
	
	// Callable from games to change their own token allocation 
  // The game must have "free" tokens
  // Triggers a change in the tokenBankroll&#39;s allocation amount on the master bankroll
	function changeAllocation(int delta)
	    public
	    contractIsWhiteListed(msg.sender)
	{
	    uint newAlloc;
      // We need to INCREASE token allocation:
	    if (delta > 0){
	        // Calculate new allocation 
	        newAlloc = SafeMath.add(gameTokenAllocation[msg.sender], uint(delta));

	        // It SHOULD have enough tokens
	        require(gameTokenAmount[msg.sender] >= newAlloc);

	        // Set the game&#39;s token allocation
	        gameTokenAllocation[msg.sender] = newAlloc;

          // Set this tokenBankroll&#39;s allocation (increase it)
          ZethrBankroll(ZethrMainBankroll).changeAllocation(address(this), delta);
	    } else {
      // We need to DECREASE token allocation:
	        // Calculate the new allocation 
	        newAlloc = SafeMath.sub(gameTokenAllocation[msg.sender], uint(-delta));

	        // Set the game&#39;s token allocation
	        gameTokenAllocation[msg.sender] = newAlloc;

          // Set this tokenBankroll&#39;s allocation (decrease it)
          ZethrBankroll(ZethrMainBankroll).changeAllocation(address(this), delta);
	    }
	}
	
	// Allocates tokens to games
	// Also buys in if balance >= 0.1 ETH
	function allocateTokens()
	    onlyDevOrBankroll
	    public
	{
	    // Withdraw divs first
	    ZethrContract.withdraw(address(this));

			// Buy in, but only if balance >= 0.1 ETH
	    if (address(this).balance >= (0.1 ether)){
	        zethrBuyIn(); 
	    }

      // Store current game address for loop
      address gameAddress;    
      // Stoe game&#39;s balance for loop
      uint gameBalance;
      // Store game&#39;s allotment for loop 
      uint gameAllotment;
      // Store game&#39;s difference (positive or negative) in tokenBalance vs tokenAllotment
      int difference;

      // Loop over each game
      // Remove any "free" tokens (auto-withdraw) over its allotment
      for (uint i=0; i < games.length; i++) {
        // Grab the info about this game&#39;s token amounts
        gameAddress = games[i];
        gameBalance = gameTokenAmount[gameAddress];
        gameAllotment = gameTokenAllocation[gameAddress];   

        // Calculate deltaTokens (positive if it has more than it needs, negative if it needs tokens)
        difference = int(gameBalance) - int(gameAllotment);

        // If the game has extra tokens, re-allocate them to the "free" balance
        // This reminds me of when I had to write malloc() for my C class
        // I hated that shit
        if (difference > 0) {
          // Game now has exactly the amount of tokens it needs
          gameTokenAmount[gameAddress] = gameAllotment;
 
          // "Free" the extra
          freeTokens = freeTokens + uint(difference);
        } else {
          // This means it needs tokenks. We&#39;ll address that in the next for loop.
        } 
      } 

      // Now that all games have had their excess removed, loop through the games again and allocated them tokens
      // We /will/ have enough tokens to allocate - because we bought in ETH.
      for (uint j=0; j < games.length; j++) {
        // Grab the info about this game&#39;s token amounts
        gameAddress = games[i];
        gameBalance = gameTokenAmount[gameAddress];
        gameAllotment = gameTokenAllocation[gameAddress];

        // Calculate deltaTokens (either zero or negative in this case)
        difference = int(gameBalance) - int(gameAllotment);

        // Game either has zero or negative tokens
        // If it has negative tokens, allocate it tokens out of the free balance
        if (difference < 0) {
          // Sanity check
          require(freeTokens >= uint(-difference));

          // Subtract from free tokens
          freeTokens = freeTokens - uint(-difference);

          // Allocate
          gameTokenAmount[gameAddress] = gameAllotment;
        }
      }

      // After the above two for loops, every game has
      //  a) no excess tokens
      //  b) exactly it&#39;s allotment of tokens

      // There will probably be some free tokens left over due to the 1% extra ETH deposit.
	}

  // Dump all free tokens back to the main bankroll
  function dumpFreeTokens(address stakeAddress) onlyDevOrBankroll public returns (uint) {
    // First, allocate tokens    
    allocateTokens();

    // Don&#39;t transfer tokens if we have less than 1 free token
    if (freeTokens < 1e18) { return 0; }

    // Transfer free tokens to bankroll
    ZethrContract.transfer(stakeAddress, freeTokens);

    // Set free tokens to zero
    uint sent = freeTokens;
    freeTokens = 0;

    // Return the number of tokens we sent
    return sent;
  }

	// Contract withdraw free tokens back to the free tokens 
	function contractTokenWithdrawToFreeTokens(address ctr, uint amount)
	    onlyDevOrBankroll
	    contractIsWhiteListed(ctr)
	    public 
	{
	    uint currentBalance = gameTokenAmount[ctr];
	    uint allocated = gameTokenAllocation[ctr];
	    if ( SafeMath.sub(currentBalance, amount) > allocated){
	        gameTokenAmount[ctr] = gameTokenAmount[ctr] - amount;
	        freeTokens = SafeMath.add(freeTokens, amount);
	    }
	    else{
	        revert();
	    }
	}
	
	// Function to buy in tokens with Ethereum 
	// Updates free tokens so they can be allocated 
	function zethrBuyIn()
	    onlyDevOrBankroll
	    public
	{
      // Only buy in if balance >= 0.1 ETH
      if (address(this).balance < 0.1 ether) { return; } 

      // Grab the tokenBankroll&#39;s token balance
	    uint cBal = ZethrContract.balanceOf(address(this)); 

      // Buy in with entire balance (divs go to bankroll)
	    ZethrContract.buyAndSetDivPercentage.value(address(this).balance)(ZethrMainBankroll, uint8(divRate), "");

      // Calculate and increment freeTokens
	    freeTokens = freeTokens + (ZethrContract.balanceOf(address(this)) - cBal); 
	}
	
	// Emergency this fucks up free tokens 
	// Need a redeploy after this 
	function WithdrawTokensToBankroll(uint amount) 
	    onlyDevOrBankroll
	    public
	{
	    ZethrContract.transfer(ZethrMainBankroll, amount);
	}

  // Withdraw eth 
  function WithdrawToBankroll() public {
    ZethrMainBankroll.transfer(address(this).balance);
  }
    
  // Withdraw divs and send to bankroll 
  function WithdrawAndTransferToBankroll() public {
    ZethrContract.withdraw(ZethrMainBankroll);
    WithdrawToBankroll();
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}