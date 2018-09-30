pragma solidity 0.4.24;
contract Owned 
{
    address public owner;
    address public ownerCandidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
}

contract Priced
{
    modifier costs(uint price)
    {
        //They must pay exactly 0.5 eth
        require(msg.value == price);
        _;
    }
}
//UPDATED 9/8/18: Added auto unlock
//                Changed the Register to track people so it does not have to loop through 
//UPDATED 9/10/18: Changed it to only accept 0.5 eth, anything over or under will just fail

contract Teris is Owned, Priced
{
    string public debugString;
    
    //Wallets
    address adminWallet = 0x45FEbD925Aa0439eE6bF2ffF5996201e199Efb5b;

    //wallet rotations
    uint8 public devWalletRotation = 0;
    
    //To set up for only 4 active transactions
    mapping(address => uint8) transactionLimits;
    
    //Lock the contract after 640 transactions! (uint16 stores up to 65,535)
    // Changednge to 10 for testing
    uint256 maxTransactions = 10;
    uint16 totalTransactions;
    modifier notLocked()
    {
        require(!isLocked());
        _;
    }
    
    //Structs
    struct Participant
    {
        address ethAddress;
        bool paid;
    }
    
    Participant[] allParticipants;
    uint16 lastPaidParticipant;
    
    //Set up a blacklist
     mapping(address => bool) blacklist;

    bool testing = false;
    
    /* ------------------------------------------------
    //              MAIN FUNCTIONS
    ---------------------------------------------------*/   

    //Silentflame - Added costs(500 finney)
    function register() public payable costs(500 finney) notLocked
    {
        //Silentflame - Added to remove exponential gas cost increase on register
        transactionLimits[msg.sender]++;    
        
        if(!testing)
        {
            require(_checkTransactions(msg.sender));
        }
        
        require(!blacklist[msg.sender]);
            
        
        //transfer eth to admin wallet
        _payFees();
        
        //add user to the participant list, as unpaid
        allParticipants.push(Participant(msg.sender, false));
        
        //Count this transaction
        totalTransactions++;
        
        //try and pay whoever you can
        _payout();
        
    }
    
    /* ------------------------------------------------
    //              INTERNAL FUNCTIONS
    ---------------------------------------------------*/
    
    function _checkTransactions(address _toCheck) private view returns(bool)
    {
        //Silentflame - Removed old logic!
        
        //Silentflame - Added to remove exponential gas cost increase on register
        if(transactionLimits[_toCheck] > 4)
            return false;
        else
            return true;
        
        
    }
    
    //Pays the Admin fees
    function _payFees() private
    {
        adminWallet.transfer(162500000000000000); // .1625
   

        address walletAddress ;
        devWalletRotation++;
        
        
        if(devWalletRotation >= 7)
            devWalletRotation = 1;
        
        if(devWalletRotation == 1)
            walletAddress = 0x556FD37b59D20C62A778F0610Fb1e905b112b7DE;
        else if(devWalletRotation == 2)
            walletAddress = 0x92f94ecdb1ba201cd0e4a0a9a9bccb1faa3a3de0;
        else if(devWalletRotation == 3)
            walletAddress = 0x41271507434E21dBd5F09624181d7Cd70Bf06Cbf;
        else if (devWalletRotation == 4)
            walletAddress = 0xbeb07c2d5beca948eb7d7eaf60a30e900f470f8d;
        else if (devWalletRotation == 5)
            walletAddress = 0xcd7c53462067f0d0b8809be9e3fb143679a270bb;
        else if (devWalletRotation == 6)
            walletAddress = 0x9184B1D0106c1b7663D4C3bBDBF019055BB813aC;
        else
            walletAddress = adminWallet;
            
            
            
        
        walletAddress.transfer(25000000000000000);
        

    }

    //Tries to pay people, starting from the last paid transaction
    function _payout() private
    {

        for(uint16 i = lastPaidParticipant; i < allParticipants.length; i++)
        {
            if(allParticipants[i].paid)
            {
                lastPaidParticipant = i;
                continue;
            }
            else
            {
                if(address(this).balance < 625000000000000000)
                    break;
                
                allParticipants[i].ethAddress.transfer(625000000000000000);
                allParticipants[i].paid = true;
                transactionLimits[allParticipants[i].ethAddress]--; //Silentflame - added to remove gas cost on register
                lastPaidParticipant = i;
            }
        }
        
        //Silentflame attemptAutoUnlock
        if(lastPaidParticipant >= maxTransactions)
            _unlockContract();
    }
    
    function _unlockContract() internal
    {
        //Clear all the transaction limits
        for(uint256 i = 0; i < allParticipants.length; i++)
        {
            transactionLimits[allParticipants[i].ethAddress] = 0;
        }
        
        //delete all the participants
        delete allParticipants;

        lastPaidParticipant = 0;
        
        //If there is any remaining funds (there shouldnt be) send it to trading wallet
        adminWallet.transfer(address(this).balance);
        totalTransactions = 0;
    }

    /* ------------------------------------------------
    //                ADMIN FUNCTIONS
    ---------------------------------------------------*/
    function changeMaxTransactions(uint256 _amount) public onlyOwner
    {
        maxTransactions = _amount;
    }
    
    function unlockContract() public onlyOwner
    {
         //Clear all the transaction limits
        for(uint256 i = 0; i < allParticipants.length; i++)
        {
            transactionLimits[allParticipants[i].ethAddress] = 0;
        }
        
        //delete all the participants
        delete allParticipants;

        lastPaidParticipant = 0;
        
        //If there is any remaining funds (there shouldnt be) send it to trading wallet
        adminWallet.transfer(address(this).balance);
        totalTransactions = 0;       
    }

    //Allows an injection to add balance into the contract without
    //creating a new contract.
    function addBalance() payable public onlyOwner
    {
        _payout();
    }
    
    function forcePayout() public onlyOwner
    {
        _payout();
    }
    
    function isTesting() public view onlyOwner returns(bool) 
    {
        return(testing);
    }
    
    function changeAdminWallet(address _newWallet) public onlyOwner
    {
        adminWallet = _newWallet;
    }
    
    function setTesting(bool _testing) public onlyOwner
    {
        testing = _testing;
    }
    
    function addToBlackList(address _addressToAdd) public onlyOwner
    {
        blacklist[_addressToAdd] = true;
    }
    
    function removeFromBlackList(address _addressToRemove) public onlyOwner
    {
        blacklist[_addressToRemove] = false;
    }

    /* ------------------------------------------------
    //                      GETTERS
    ---------------------------------------------------*/
    function checkMyTransactions() public view returns(uint256)
    {
        return transactionLimits[msg.sender];
    }
    
    function getPeopleBeforeMe(address _address) public view returns(uint256)
    {
        uint counter = 0;
        
        for(uint16 i = lastPaidParticipant; i < allParticipants.length; i++)
        {
            if(allParticipants[i].ethAddress != _address)
            {
                counter++;
            }
            else
            {
                break;
            }
        }
        
        return counter;
    }
    
    function getMyOwed(address _address) public view returns(uint256)
    {
        uint counter = 0;
        
        for(uint16 i = 0; i < allParticipants.length; i++)
        {
            if(allParticipants[i].ethAddress == _address)
            {
                if(!allParticipants[i].paid)
                {
                    counter++;
                }
            }
        }
        
        return (counter * 625000000000000000);
    }
    
    //For seeing how much balance is in the contract
    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }
    
    //For seeing if the contract is locked
    function isLocked() public view returns(bool)
    {
        if(totalTransactions >= maxTransactions)
            return true;
        else
            return false;
    }

    //For seeing how many transactions a user has put into the system
    function getParticipantTransactions(address _address) public view returns(uint8)
    {
        return transactionLimits[_address];
    }
    
    //For getting the details about a transaction (the address and if the transaction was paid)
    function getTransactionInformation(uint _id) public view returns(address, bool)
    {
        return(allParticipants[_id].ethAddress, allParticipants[_id].paid);
    }

    //For getting the ID of the last Paid transaction
    function getLastPaidTransaction() public view returns(uint)
    {
        return (lastPaidParticipant);
    }
    
    //For getting how many transactions there are total
    function getNumberOfTransactions() public view returns(uint)
    {
        return (allParticipants.length);
    }
}