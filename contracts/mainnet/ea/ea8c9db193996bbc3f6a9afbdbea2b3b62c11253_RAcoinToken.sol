pragma solidity ^0.4.23;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title Ownable
 * The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    // The Ownable constructor sets the original `owner` 
    // of the contract to the sender account.
    constructor()  public {
        owner = msg.sender;
    } 

    // Throw if called by any account other than the current owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Allow the current owner to transfer control of the contract to a newOwner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract RAcoinToken is Ownable, ERC20Interface {
    string public constant symbol = "RAC";
    string public constant name = "RAcoinToken";
    uint private _totalSupply;
    uint public constant decimals = 18;
    uint private unmintedTokens = 20000000000*uint(10)**decimals; 
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    //Struct to hold lockup records
    struct LockupRecord {
        uint amount;
        uint unlockTime;
    }
    
    // Balances for each account
    mapping(address => uint) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint)) allowed; 
    
    // Balances for lockup accounts
    mapping(address => LockupRecord)balancesLockup;



    /**
     ====== JACKPOT IMPLEMENTATION ====== 
     */

    // Percentage for jackpot reserving during tokens transfer, 1% is default
    uint public reservingPercentage = 100;
    
    // Minimum allowed variable percentage for jackpot reserving during tokens transfer, 0.01% is default
    uint public minAllowedReservingPercentage = 1;
    
    // Maximu, allowed variable percentage for jackpot reserving during tokens transfer, 10% is default
    uint public maxAllowedReservingPercentage = 1000;
    
    // Minimum amount of jackpot, before reaching it jackpot cannot be distributed. 
    // Default value is 100,000 RAC
    uint public jackpotMinimumAmount = 100000 * uint(10)**decimals; 
    
    // reservingStep is used for calculating how many times a user will be added to jackpot participants list:
    // times user will be added to jackpotParticipants list = transfer amount / reservingStep
    // the more user transfer tokens using transferWithReserving function the more times he will be added and, 
    // as a result, more chances to win the jackpot. Default value is 10,000 RAC
    uint public reservingStep = 10000 * uint(10)**decimals; 
    
    // The seed is used each time Jackpot is distributing for generating a random number.
    // First seed has some value, after the every turn of the jackpot distribution will be changed 
    uint private seed = 1; // Default seed 
    
    // The maximum allowed times when jackpot amount and distribution time will be set by owner,
    // Used only for token sale jackpot distribution 
    int public maxAllowedManualDistribution = 111; 

    // Either or not clear the jackpot participants list after the Jackpot distribution
    bool public clearJackpotParticipantsAfterDistribution = false;

    // Variable that holds last actual index of jackpotParticipants collection
    uint private index = 0; 

    // The list with Jackpot participants. The more times address is in the list, the more chances to win the Jackpot
    address[] private jackpotParticipants; 

    event SetReservingPercentage(uint _value);
    event SetMinAllowedReservingPercentage(uint _value);
    event SetMaxAllowedReservingPercentage(uint _value);
    event SetReservingStep(uint _value);
    event SetJackpotMinimumAmount(uint _value);
    event AddAddressToJackpotParticipants(address indexed _sender, uint _times);
    
    //Setting the reservingPercentage value, allowed only for owner
    function setReservingPercentage(uint _value) public onlyOwner returns (bool success) {
        assert(_value > 0 && _value < 10000);
        
        reservingPercentage = _value;
        emit SetReservingPercentage(_value);
        return true;
    }
    
    //Setting the minAllowedReservingPercentage value, allowed only for owner
    function setMinAllowedReservingPercentage(uint _value) public onlyOwner returns (bool success) {
        assert(_value > 0 && _value < 10000);
        
        minAllowedReservingPercentage = _value;
        emit SetMinAllowedReservingPercentage(_value);
        return true;
    }
    
    //Setting the maxAllowedReservingPercentage value, allowed only for owner
    function setMaxAllowedReservingPercentage(uint _value) public onlyOwner returns (bool success) {
        assert(_value > 0 && _value < 10000);
        
        minAllowedReservingPercentage = _value;
        emit SetMaxAllowedReservingPercentage(_value);
        return true;
    }
    
    //Setting the reservingStep value, allowed only for owner
    function setReservingStep(uint _value) public onlyOwner returns (bool success) {
        assert(_value > 0);
        reservingStep = _value;
        emit SetReservingStep(_value);
        return true;
    }
    
    //Setting the setJackpotMinimumAmount value, allowed only for owner
    function setJackpotMinimumAmount(uint _value) public onlyOwner returns (bool success) {
        jackpotMinimumAmount = _value;
        emit SetJackpotMinimumAmount(_value);
        return true;
    }

    //Setting the clearJackpotParticipantsAfterDistribution value, allowed only for owner
    function setPoliticsForJackpotParticipantsList(bool _clearAfterDistribution) public onlyOwner returns (bool success) {
        clearJackpotParticipantsAfterDistribution = _clearAfterDistribution;
        return true;
    }
    
    // Empty the jackpot participants list
    function clearJackpotParticipants() public onlyOwner returns (bool success) {
        index = 0;
        return true;
    }
    
    // Using this function a user transfers tokens and participates in operating jackpot 
    // User sets the total transfer amount that includes the Jackpot reserving deposit
    function transferWithReserving(address _to, uint _totalTransfer) public returns (bool success) {
        uint netTransfer = _totalTransfer * (10000 - reservingPercentage) / 10000; 
        require(balances[msg.sender] >= _totalTransfer && (_totalTransfer > netTransfer));
        
        if (transferMain(msg.sender, _to, netTransfer) && (_totalTransfer >= reservingStep)) {
            processJackpotDeposit(_totalTransfer, netTransfer, msg.sender);
        }
        return true;
    }

    // Using this function a user transfers tokens and participates in operating jackpot 
    // User sets the net value of transfer without the Jackpot reserving deposit amount 
    function transferWithReservingNet(address _to, uint _netTransfer) public returns (bool success) {
        uint totalTransfer = _netTransfer * (10000 + reservingPercentage) / 10000; 
        require(balances[msg.sender] >= totalTransfer && (totalTransfer > _netTransfer));
        
        if (transferMain(msg.sender, _to, _netTransfer) && (totalTransfer >= reservingStep)) {
            processJackpotDeposit(totalTransfer, _netTransfer, msg.sender);
        }
        return true;
    }
    
    // Using this function a user transfers tokens and participates in operating jackpot 
    // User sets the total transfer amount that includes the Jackpot reserving deposit and custom reserving percentage
    function transferWithCustomReserving(address _to, uint _totalTransfer, uint _customReservingPercentage) public returns (bool success) {
        require(_customReservingPercentage > minAllowedReservingPercentage && _customReservingPercentage < maxAllowedReservingPercentage);
        uint netTransfer = _totalTransfer * (10000 - _customReservingPercentage) / 10000; 
        require(balances[msg.sender] >= _totalTransfer && (_totalTransfer > netTransfer));
        
        if (transferMain(msg.sender, _to, netTransfer) && (_totalTransfer >= reservingStep)) {
            processJackpotDeposit(_totalTransfer, netTransfer, msg.sender);
        }
        return true;
    }
    
    // Using this function a user transfers tokens and participates in operating jackpot 
    // User sets the net value of transfer without the Jackpot reserving deposit amount and custom reserving percentage
    function transferWithCustomReservingNet(address _to, uint _netTransfer, uint _customReservingPercentage) public returns (bool success) {
        require(_customReservingPercentage > minAllowedReservingPercentage && _customReservingPercentage < maxAllowedReservingPercentage);
        uint totalTransfer = _netTransfer * (10000 + _customReservingPercentage) / 10000; 
        require(balances[msg.sender] >= totalTransfer && (totalTransfer > _netTransfer));
        
        if (transferMain(msg.sender, _to, _netTransfer) && (totalTransfer >= reservingStep)) {
            processJackpotDeposit(totalTransfer, _netTransfer, msg.sender);
        }
        return true;
    }

    // Using this function a spender transfers tokens and make an owner of funds a participant of the operating Jackpot 
    // User sets the total transfer amount that includes the Jackpot reserving deposit
    function transferFromWithReserving(address _from, address _to, uint _totalTransfer) public returns (bool success) {
        uint netTransfer = _totalTransfer * (10000 - reservingPercentage) / 10000; 
        require(balances[_from] >= _totalTransfer && (_totalTransfer > netTransfer));
        
        if (transferFrom(_from, _to, netTransfer) && (_totalTransfer >= reservingStep)) {
            processJackpotDeposit(_totalTransfer, netTransfer, _from);
        }
        return true;
    }

    // Using this function a spender transfers tokens and make an owner of funds a participatants of the operating Jackpot 
    // User set the net value of transfer without the Jackpot reserving deposit amount 
    function transferFromWithReservingNet(address _from, address _to, uint _netTransfer) public returns (bool success) {
        uint totalTransfer = _netTransfer * (10000 + reservingPercentage) / 10000; 
        require(balances[_from] >= totalTransfer && (totalTransfer > _netTransfer));

        if (transferFrom(_from, _to, _netTransfer) && (totalTransfer >= reservingStep)) {
            processJackpotDeposit(totalTransfer, _netTransfer, _from);
        }
        return true;
    }


    // Using this function a spender transfers tokens and make an owner of funds a participant of the operating Jackpot 
    // User sets the total transfer amount that includes the Jackpot reserving deposit
    function transferFromWithCustomReserving(address _from, address _to, uint _totalTransfer, uint _customReservingPercentage) public returns (bool success) {
        require(_customReservingPercentage > minAllowedReservingPercentage && _customReservingPercentage < maxAllowedReservingPercentage);
        uint netTransfer = _totalTransfer * (10000 - _customReservingPercentage) / 10000; 
        require(balances[_from] >= _totalTransfer && (_totalTransfer > netTransfer));
        
        if (transferFrom(_from, _to, netTransfer) && (_totalTransfer >= reservingStep)) {
            processJackpotDeposit(_totalTransfer, netTransfer, _from);
        }
        return true;
    }

    // Using this function a spender transfers tokens and make an owner of funds a participatants of the operating Jackpot 
    // User set the net value of transfer without the Jackpot reserving deposit amount and custom reserving percentage
    function transferFromWithCustomReservingNet(address _from, address _to, uint _netTransfer, uint _customReservingPercentage) public returns (bool success) {
        require(_customReservingPercentage > minAllowedReservingPercentage && _customReservingPercentage < maxAllowedReservingPercentage);
        uint totalTransfer = _netTransfer * (10000 + _customReservingPercentage) / 10000; 
        require(balances[_from] >= totalTransfer && (totalTransfer > _netTransfer));

        if (transferFrom(_from, _to, _netTransfer) && (totalTransfer >= reservingStep)) {
            processJackpotDeposit(totalTransfer, _netTransfer, _from);
        }
        return true;
    }
    
    // Withdraw deposit of Jackpot amount and add address to Jackpot Participants List according to transaction amount
    function processJackpotDeposit(uint _totalTransfer, uint _netTransfer, address _participant) private returns (bool success) {
        addAddressToJackpotParticipants(_participant, _totalTransfer);

        uint jackpotDeposit = _totalTransfer - _netTransfer;
        balances[_participant] -= jackpotDeposit;
        balances[0] += jackpotDeposit;

        emit Transfer(_participant, 0, jackpotDeposit);
        return true;
    }

    // Add address to Jackpot Participants List
    function addAddressToJackpotParticipants(address _participant, uint _transactionAmount) private returns (bool success) {
        uint timesToAdd = _transactionAmount / reservingStep;
        
        for (uint i = 0; i < timesToAdd; i++){
            if(index == jackpotParticipants.length) {
                jackpotParticipants.length += 1;
            }
            jackpotParticipants[index++] = _participant;
        }

        emit AddAddressToJackpotParticipants(_participant, timesToAdd);
        return true;        
    }
    
    // Distribute jackpot. For finding a winner we use random number that is produced by multiplying a previous seed  
    // received from previous jackpot distribution and casted to uint last available block hash. 
    // Remainder from the received random number and total number of participants will give an index of a winner in the Jackpot participants list
    function distributeJackpot(uint _nextSeed) public onlyOwner returns (bool success) {
        assert(balances[0] >= jackpotMinimumAmount);
        assert(_nextSeed > 0);

        uint additionalSeed = uint(blockhash(block.number - 1));
        uint rnd = 0;
        
        while(rnd < index) {
            rnd += additionalSeed * seed;
        }
        
        uint winner = rnd % index;
        balances[jackpotParticipants[winner]] += balances[0];
        emit Transfer(0, jackpotParticipants[winner], balances[0]);
        balances[0] = 0;
        seed = _nextSeed;

        if (clearJackpotParticipantsAfterDistribution) {
            clearJackpotParticipants();
        }
        return true;
    }

    // Distribute Token Sale Jackpot by minting token sale jackpot directly to 0x0 address and calling distributeJackpot function 
    function distributeTokenSaleJackpot(uint _nextSeed, uint _amount) public onlyOwner returns (bool success) {
        require (maxAllowedManualDistribution > 0);
        if (mintTokens(0, _amount) && distributeJackpot(_nextSeed)) {
            maxAllowedManualDistribution--;
        }
        return true;
    }



    /** 
     ====== ERC20 IMPLEMENTATION ====== 
     */
    
    // Return total supply of tokens including locked-up funds and current Jackpot deposit
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    // Get the balance of the specified address
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    // Transfer token to a specified address   
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        return transferMain(msg.sender, _to, _value);
    }

    // Transfer tokens from one address to another 
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        if (transferMain(_from, _to, _value)){
            allowed[_from][msg.sender] -= _value;
            return true;
        } else {
            return false;
        }
    }

    // Main transfer function. Checking of balances is made in calling function
    function transferMain(address _from, address _to, uint _value) private returns (bool success) {
        require(_to != address(0));
        assert(balances[_to] + _value >= balances[_to]);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Function to check the amount of tokens than an owner allowed to a spender
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    


    /**
     ====== LOCK-UP IMPLEMENTATION ====== 
     */

    function unlockOwnFunds() public returns (bool success) {
        return unlockFunds(msg.sender);
    }

    function unlockSupervisedFunds(address _from) public onlyOwner returns (bool success) {
        return unlockFunds(_from);
    }
    
    function unlockFunds(address _owner) private returns (bool success) {
        require(balancesLockup[_owner].unlockTime < now && balancesLockup[_owner].amount > 0);

        balances[_owner] += balancesLockup[_owner].amount;
        emit Transfer(_owner, _owner, balancesLockup[_owner].amount);
        balancesLockup[_owner].amount = 0;

        return true;
    }

    function balanceOfLockup(address _owner) public view returns (uint balance, uint unlockTime) {
        return (balancesLockup[_owner].amount, balancesLockup[_owner].unlockTime);
    }



    /**
     ====== TOKENS MINTING IMPLEMENTATION ====== 
     */

    // Mint RAcoin tokens. No more than 20,000,000,000 RAC can be minted
    function mintTokens(address _target, uint _mintedAmount) public onlyOwner returns (bool success) {
        require(_mintedAmount <= unmintedTokens);
        balances[_target] += _mintedAmount;
        unmintedTokens -= _mintedAmount;
        _totalSupply += _mintedAmount;
        
        emit Transfer(1, _target, _mintedAmount); 
        return true;
    }

    // Mint RAcoin locked-up tokens
    // Using different types of minting functions has no effect on total limit of 20,000,000,000 RAC that can be created
    function mintLockupTokens(address _target, uint _mintedAmount, uint _unlockTime) public onlyOwner returns (bool success) {
        require(_mintedAmount <= unmintedTokens);

        balancesLockup[_target].amount += _mintedAmount;
        balancesLockup[_target].unlockTime = _unlockTime;
        unmintedTokens -= _mintedAmount;
        _totalSupply += _mintedAmount;
        
        emit Transfer(1, _target, _mintedAmount); //TODO
        return true;
    }

    // Mint RAcoin tokens for token sale participants and add them to Jackpot list
    // Using different types of minting functions has no effect on total limit of 20,000,000,000 RAC that can be created
    function mintTokensWithIncludingInJackpot(address _target, uint _mintedAmount) public onlyOwner returns (bool success) {
        require(maxAllowedManualDistribution > 0);
        if (mintTokens(_target, _mintedAmount)) {
            addAddressToJackpotParticipants(_target, _mintedAmount);
        }
        return true;
    }

    // Mint RAcoin tokens and approve the passed address to spend the minted amount of tokens
    // Using different types of minting functions has no effect on total limit of 20,000,000,000 RAC that can be created
    function mintTokensWithApproval(address _target, uint _mintedAmount, address _spender) public onlyOwner returns (bool success) {
        require(_mintedAmount <= unmintedTokens);
        balances[_target] += _mintedAmount;
        unmintedTokens -= _mintedAmount;
        _totalSupply += _mintedAmount;
        allowed[_target][_spender] += _mintedAmount;
        
        emit Transfer(1, _target, _mintedAmount);
        return true;
    }

    // After firing this function no more tokens can be created  
    function stopTokenMinting() public onlyOwner returns (bool success) {
        unmintedTokens = 0;
        return true;
    }
}