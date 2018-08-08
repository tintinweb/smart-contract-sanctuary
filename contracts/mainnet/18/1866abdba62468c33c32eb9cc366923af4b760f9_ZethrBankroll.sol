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
    function tokensToEthereum_(uint _tokens) public view returns(uint);
}

contract ZethrTokenBankroll {
    function zethrBuyIn() public;
    function allocateTokens() public;
    function addGame(address game, uint allocated) public;
    function removeGame(address game) public;
    function dumpFreeTokens(address toSendTo) public returns (uint);
}

contract ERC223Receiving {
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

contract ZethrBankroll is ERC223Receiving {
    using SafeMath for uint;

    /*=================================
    =              EVENTS            =
    =================================*/

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event WhiteListAddition(address indexed contractAddress);
    event WhiteListRemoval(address indexed contractAddress);
    event RequirementChange(uint required);
    event DevWithdraw(uint amountTotal, uint amountPerPerson);
    event EtherLogged(uint amountReceived, address sender);
    event BankrollInvest(uint amountReceived);
    event DailyTokenAdmin(address gameContract);
    event DailyTokensSent(address gameContract, uint tokens);
    event DailyTokensReceived(address gameContract, uint tokens);

    /*=================================
    =        WITHDRAWAL CONSTANTS     =
    =================================*/

    uint constant public MAX_OWNER_COUNT = 10;
    uint constant public MAX_WITHDRAW_PCT_DAILY = 15;
    uint constant public MAX_WITHDRAW_PCT_TX = 5;
    uint constant internal resetTimer = 1 days;

    /*=================================
    =          ZTH INTERFACE          =
    =================================*/

    address internal zethrAddress;
    ZTHInterface public ZTHTKN;

    /*=================================
    =             VARIABLES           =
    =================================*/

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    mapping (address => bool) public isAnAddedGame;
    address internal divCardAddress;
    address[] public owners;
    address[] public games;
    uint public required;
    uint public transactionCount;
    bool internal reEntered = false;

    /*=================================
    =         CUSTOM CONSTRUCTS       =
    =================================*/

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    struct TKN {
        address sender;
        uint value;
    }

    /*=================================
    =            MODIFIERS            =
    =================================*/

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }

    modifier isOwnerOrWhitelistedGame() {
        address caller = msg.sender;
        if (!isOwner[caller] || isAnAddedGame[caller])
            revert();
        _;
    }

    modifier isAnOwner() {
        address caller = msg.sender;
        if (!isOwner[caller])
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            revert();
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }

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


    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor (address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        // Add owners
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }

        // Set owners
        owners = _owners;

        // Set required
        required = _required;
    }

    /** Testing only.
    function exitAll()
        public
    {
        uint tokenBalance = ZTHTKN.balanceOf(address(this));
        ZTHTKN.sell(tokenBalance - 1e18);
        ZTHTKN.sell(1e18);
        ZTHTKN.withdraw(address(0x0));
    }
    **/

    function addZethrAddresses(address _zethr, address _divcards)
        public
        isAnOwner
    {
        zethrAddress   = _zethr;
        divCardAddress = _divcards;
        ZTHTKN = ZTHInterface(zethrAddress);
    }

    /// @dev Fallback function allows Ether to be deposited.
    function()
        public
        payable
    {

    }

    uint NonICOBuyins;

    function deposit()
        public
        payable
    {
        NonICOBuyins = NonICOBuyins.add(msg.value);
    }

    /// @dev Function to buy tokens with contract eth balance.
    function buyTokens()
        public
        payable
        isAnOwner
    {
        uint savings = address(this).balance;
        if (savings > 0.01 ether) {
            ZTHTKN.buyAndSetDivPercentage.value(savings)(address(0x0), 33, "");
            emit BankrollInvest(savings);
        }
        else {
            emit EtherLogged(msg.value, msg.sender);
        }
    }

		function tokenFallback(address /*_from*/, uint /*_amountOfTokens*/, bytes /*_data*/) public returns (bool) {
			// Nothing, for now. Just receives tokens.
		}	

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
        validRequirement(owners.length, required)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txToExecute = transactions[transactionId];
            txToExecute.executed = true;
            if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txToExecute.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*=================================
    =        OPERATOR FUNCTIONS       =
    =================================*/

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    // Dev withdrawal of tokens - splits equally among all owners of contract
    function devTokenWithdraw(uint amount) public
        onlyWallet
    {
        uint amountPerPerson = SafeMath.div(amount, owners.length);

        for (uint i=0; i<owners.length; i++) {
            ZTHTKN.transfer(owners[i], amountPerPerson);
        }

        emit DevWithdraw(amount, amountPerPerson);
    }

    // Change the dividend card address. Can&#39;t see why this would ever need
    // to be invoked, but better safe than sorry.
    function changeDivCardAddress(address _newDivCardAddress)
        public
        isAnOwner
    {
        divCardAddress = _newDivCardAddress;
    }

    // Receive Ether (from Zethr itself or any other source) and purchase tokens at the 33% dividend rate.
    // If the amount is less than 0.01 Ether, the Ether is stored by the contract until the balance
    // exceeds that limit and then purchases all it can.
    function receiveDividends() public payable {
      if (!reEntered) {
        uint ActualBalance = (address(this).balance.sub(NonICOBuyins));
        if (ActualBalance > 0.01 ether) {
          reEntered = true;
          ZTHTKN.buyAndSetDivPercentage.value(ActualBalance)(address(0x0), 33, "");
          emit BankrollInvest(ActualBalance);
          reEntered = false;
        }
      }
    }

    // Use all available balance to buy in
    function buyInWithAllBalance() public payable onlyWallet {
      if (!reEntered) {
        uint balance = address(this).balance;
        require (balance > 0.01 ether);
        ZTHTKN.buyAndSetDivPercentage.value(balance)(address(0x0), 33, ""); 
      }
    }
    
    // Withdraws dividends, then buys in half of balance @ 33% if balance > 0.01 eth 
    function buyInSaturday() public payable isAnOwner {
        if (!reEntered) {
            ZTHTKN.withdraw(address(this));
            uint balance = address(this).balance;
            require (balance > 0.01 ether);
            ZTHTKN.buyAndSetDivPercentage.value(balance/2)(address(0x0), 33, ""); 
        }
    }
   
    // Multi allocate ETH to all token bankrolls 
    function allocateETH(bool callBuy)
        isAnOwner
        public
    {
        // Withdraw divs first
        ZTHTKN.withdraw(address(this));

        // Allocate eth to each of the sub-bankrolls
        _allocateETH(2, callBuy);
        _allocateETH(5, callBuy);
        _allocateETH(10, callBuy);
        _allocateETH(15, callBuy);
        _allocateETH(20, callBuy);
        _allocateETH(25, callBuy);
        _allocateETH(33, callBuy);
    }
    
    // Actually allocate 
    function _allocateETH(uint8 divRate, bool doBuy)
        internal
    {
        // Retreive bankroll address from divrate mapping
        address targetBankroll = tokenBankrollMapping[divRate]; 

        // Make sure the target tokenBankroll is actually set  
        require(targetBankroll != address(0x0));

        // Check the token balance of the target tokenBankroll
        uint balance = ZTHTKN.balanceOf(targetBankroll); 

        // Check the token allocation of the target tokenBankroll
        uint allocated = tokenBankrollAllocation[targetBankroll];

        // If the target tokenBankroll doesn&#39;t have enough tokens, send it ETH so it can buy in
        if (balance < allocated){
            // Calculate how much eth it needs to buy in
            uint toSend = ZTHTKN.tokensToEthereum_(allocated - balance);

            // Add 1% to account for variance
            toSend = (toSend * 101)/100;

            // Send the ETH!
            targetBankroll.transfer(toSend);
        }

        // if doBuy is set, call tokenBankrollBuyIn()
        if (doBuy) {
          tokenBankrollBuyIn();
        }
    }
    
    uint public stakingBonusTokens; 
    address public stakeAddress;

    // Set the staking address
    function setStakeAddress(address anAddress) isAnOwner public {
      stakeAddress = anAddress; 
    }

    // Transfer tokens from all tokenBankrolls to the master staking contract
    // Also record how many were transferred
    function collectStakingBonusTokens() isAnOwner public {
      // Stake address can&#39;t be 0, dumbass
      require(stakeAddress != address(0x0));

      // Reset staking bonus counter
      stakingBonusTokens = 0;

      // Collect them tokens
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[2]).dumpFreeTokens(stakeAddress);
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[5]).dumpFreeTokens(stakeAddress);
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[10]).dumpFreeTokens(stakeAddress);
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[15]).dumpFreeTokens(stakeAddress);
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[20]).dumpFreeTokens(stakeAddress);
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[25]).dumpFreeTokens(stakeAddress);
      stakingBonusTokens += ZethrTokenBankroll(tokenBankrollMapping[33]).dumpFreeTokens(stakeAddress);
    }

    // Actually buy in IF this is necessary (can be manually called after allocateETH if necessary)
    function tokenBankrollBuyIn()
        isAnOwner
        public
    {
        _tokenBankrollBuyIn(2);
        _tokenBankrollBuyIn(5);
        _tokenBankrollBuyIn(10);
        _tokenBankrollBuyIn(15);
        _tokenBankrollBuyIn(20);
        _tokenBankrollBuyIn(25);
        _tokenBankrollBuyIn(33);
    }
    
    // Calls zethrBuyIn okn the selected tokenBankroll
    function _tokenBankrollBuyIn(uint8 divRate)
        internal
    {
        // Get the correct address based off the selected divRate
        address targetBankroll = tokenBankrollMapping[divRate];

        // Tell the target tokenBankroll to buy in
        ZethrTokenBankroll(targetBankroll).zethrBuyIn();  
    }
    
    // Call token allocate function on all token bankrolls 
    function tokenAllocate()
        isAnOwner
        public
    {
        _tokenAllocate(2);
        _tokenAllocate(5);
        _tokenAllocate(10);
        _tokenAllocate(15);
        _tokenAllocate(20);
        _tokenAllocate(25);
        _tokenAllocate(33);
    }
    
    // Token bankroll token-allocate function
    function _tokenAllocate(uint8 divRate)
        internal
    {
        // Get the correct address based off the selected div rate
        address targetBankroll = tokenBankrollMapping[divRate];

        // Tell the token bankroll to allocate tokens
        ZethrTokenBankroll(targetBankroll).allocateTokens();
    }
    
    function gameGetTokenBankrollList() public view returns (address[7]){
        address[7] memory output;
        output[0] = tokenBankrollMapping[2];
        output[1] = tokenBankrollMapping[5];
        output[2] = tokenBankrollMapping[10];
        output[3] = tokenBankrollMapping[15];
        output[4] = tokenBankrollMapping[20];
        output[5] = tokenBankrollMapping[25];
        output[6] = tokenBankrollMapping[33];
        return output;
    }
    
    // Whitelist a game on all token bankrolls
    function addGame(address ctr, uint allocate)
        isAnOwner
        public
    {
        // Add to list of games
        require(!isAnAddedGame[ctr]);
        isAnAddedGame[ctr] = true;
        games.push(ctr);

        ZethrTokenBankroll(tokenBankrollMapping[2]).addGame(ctr, allocate);
        ZethrTokenBankroll(tokenBankrollMapping[5]).addGame(ctr, allocate);
        ZethrTokenBankroll(tokenBankrollMapping[10]).addGame(ctr, allocate);
        ZethrTokenBankroll(tokenBankrollMapping[15]).addGame(ctr, allocate);
        ZethrTokenBankroll(tokenBankrollMapping[20]).addGame(ctr, allocate);
        ZethrTokenBankroll(tokenBankrollMapping[25]).addGame(ctr, allocate);
        ZethrTokenBankroll(tokenBankrollMapping[33]).addGame(ctr, allocate);
    }
    
    // Dewhitelist a game on all token bankrolls 
    function removeGame(address ctr)
        isAnOwner
        public
    {
        // Remove from the list of games
        require(isAnAddedGame[ctr]);    
        isAnAddedGame[ctr] = false;
 
        // Loop over the games list to find the index to remove  
        for (uint i=0; i < games.length; i++) {
          if (games[i] == ctr) {
            // If we&#39;ve found the game, null it out
            games[i] = address(0x0);

            // And if it&#39;s not at the end, swap the last element to this position
            if (i != games.length) {
              games[i] = games[games.length]; 
            }

            // Remove 1 from length
            // This will not overflow because if games.length == 0 we do not execute the for loop
            // (also would not pass the first require in this function)
            games.length = games.length - 1;  
            break;
          }  
        }

        ZethrTokenBankroll(tokenBankrollMapping[2]).removeGame(ctr);
        ZethrTokenBankroll(tokenBankrollMapping[5]).removeGame(ctr);
        ZethrTokenBankroll(tokenBankrollMapping[10]).removeGame(ctr);
        ZethrTokenBankroll(tokenBankrollMapping[15]).removeGame(ctr);
        ZethrTokenBankroll(tokenBankrollMapping[20]).removeGame(ctr);
        ZethrTokenBankroll(tokenBankrollMapping[25]).removeGame(ctr);
        ZethrTokenBankroll(tokenBankrollMapping[33]).removeGame(ctr);
    }
    
    // Mapping of div rate to addresses (token bankrolls) //1000000000000000000000
    mapping(uint8 => address) public tokenBankrollMapping; 

    // Mapping of token bankrolls to their token allocations
    mapping(address => uint) public tokenBankrollAllocation;
    
    // Set address of a token bankroll (via divrate)
    function setTokenBankrollAddress(uint8 divRate, address where)
        isAnOwner
        public
    {
        tokenBankrollMapping[divRate] = where;
    }
    
    // Set allocation of a token bankroll
    // This can come from an owner OR a game
    function setAllocation(address what, uint amount)
        isOwnerOrWhitelistedGame
        public
    {
        tokenBankrollAllocation[what] = amount;
    }

    // Change allocation of the specified token bankroll by an amount
    // This is similar to above, but uses delta instead of just the amount
    function changeAllocation(address what, int amount)
        isOwnerOrWhitelistedGame
        public
    {
        // Sanity check - can&#39;t go negative
        if (amount < 0) {
          require(int(tokenBankrollAllocation[what]) + amount >= 0);
        }
        
        // Set the allocation amount
        tokenBankrollAllocation[what] = uint(int(tokenBankrollAllocation[what]) + amount);
    }

    /*=================================
    =            UTILITIES            =
    =================================*/

    // Convert an hexadecimal character to their value
    function fromHexChar(uint c) public pure returns (uint) {
        if (byte(c) >= byte(&#39;0&#39;) && byte(c) <= byte(&#39;9&#39;)) {
            return c - uint(byte(&#39;0&#39;));
        }
        if (byte(c) >= byte(&#39;a&#39;) && byte(c) <= byte(&#39;f&#39;)) {
            return 10 + c - uint(byte(&#39;a&#39;));
        }
        if (byte(c) >= byte(&#39;A&#39;) && byte(c) <= byte(&#39;F&#39;)) {
            return 10 + c - uint(byte(&#39;A&#39;));
        }
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string s) public pure returns (bytes) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = byte(fromHexChar(uint(ss[2*i])) * 16 +
                    fromHexChar(uint(ss[2*i+1])));
        }
        return r;
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