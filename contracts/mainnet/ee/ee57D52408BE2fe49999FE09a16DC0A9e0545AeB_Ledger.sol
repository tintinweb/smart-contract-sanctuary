pragma solidity ^0.4.8;

contract Owned {
    address public owner;

    function changeOwner(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        owner = _addr;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
}

contract Mutex is Owned {
    bool locked = false;
    modifier mutexed {
        if (locked) throw;
        locked = true;
        _;
        locked = false;
    }

    function unMutex() onlyOwner {
        locked = false;
    }
}


contract Rental is Owned {
    function Rental(address _owner) {
        if (_owner == 0x0) throw;
        owner = _owner;
    }

    function offer(address from, uint num) {

    }

    function claimBalance(address) returns(uint) {
        return 0;
    }

    function exec(address dest) onlyOwner {
        if (!dest.call(msg.data)) throw;
    }
}

contract Token is Owned, Mutex {
    uint ONE = 10**8;
    uint price = 5000;
    Ledger ledger;
    Rental rentalContract;
    uint8 rollOverTime = 4;
    uint8 startTime = 8;
    bool live = false;
    address club;
    uint lockedSupply = 0;
    string public name;
    uint8 public decimals; 
    string public symbol;     
    string public version = &#39;0.1&#39;;  
    bool transfersOn = false;



    function Token(address _owner, string _tokenName, uint8 _decimals, string _symbol, address _ledger, address _rental) {
        if (_owner == 0x0) throw;
        owner = _owner;

        name = _tokenName;
        decimals = _decimals;
        symbol = _symbol;
        ONE = 10**uint(decimals);
        ledger = Ledger(_ledger);
        rentalContract = Rental(_rental);
    }

    /*
    *	Bookkeeping and Admin Functions
    */

    event LedgerUpdated(address,address);

    function changeClub(address _addr) onlyOwner {
        if (_addr == 0x0) throw;

        club = _addr;
    }

    function changePrice(uint _num) onlyOwner {
        price = _num;
    }

    function safeAdd(uint a, uint b) returns (uint) {
        if ((a + b) < a) throw;
        return (a + b);
    }

    function changeLedger(address _addr) onlyOwner {
        if (_addr == 0x0) throw;

        LedgerUpdated(msg.sender, _addr);
        ledger = Ledger(_addr);
    }

    function changeRental(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        rentalContract = Rental(_addr);
    }

    function changeTimes(uint8 _rollOver, uint8 _start) onlyOwner {
        rollOverTime = _rollOver;
        startTime = _start;
    }

    /*
    * Locking is a feature that turns a user&#39;s balances into
    * un-issued tokens, taking them out of an account and reducing the supply.
    * Diluting is so named to remind the caller that they are changing the money supply.
        */

    function lock(address _seizeAddr) onlyOwner mutexed {
        uint myBalance = ledger.balanceOf(_seizeAddr);

        lockedSupply += myBalance;
        ledger.setBalance(_seizeAddr, 0);
    }

    event Dilution(address, uint);

    function dilute(address _destAddr, uint amount) onlyOwner {
        if (amount > lockedSupply) throw;

        Dilution(_destAddr, amount);

        lockedSupply -= amount;

        uint curBalance = ledger.balanceOf(_destAddr);
        curBalance = safeAdd(amount, curBalance);
        ledger.setBalance(_destAddr, curBalance);
    }

    /* 
     * Crowdsale -- 
     *
     */
    function completeCrowdsale() onlyOwner {
        // Lock unsold tokens
        // allow transfers for arbitrary owners
        transfersOn = true;
        lock(owner);
    }

    function pauseTransfers() onlyOwner {
        transfersOn = false;
    }

    function resumeTransfers() onlyOwner {
        transfersOn = true;
    }

    /*
    * Renting -- Logic TBD later. For now, we trust the rental contract
    * to manage everything about the rentals, including bookkeeping on earnings
    * and returning tokens.
    */

    function rentOut(uint num) {
        if (ledger.balanceOf(msg.sender) < num) throw;
        rentalContract.offer(msg.sender, num);
        ledger.tokenTransfer(msg.sender, rentalContract, num);
    }

    function claimUnrented() {  
        uint amount = rentalContract.claimBalance(msg.sender); // this should reduce sender&#39;s claimableBalance to 0

        ledger.tokenTransfer(rentalContract, msg.sender, amount);
    }

    /*
    * Burning -- We allow any user to burn tokens.
    *
     */

    function burn(uint _amount) {
        uint balance = ledger.balanceOf(msg.sender);
        if (_amount > balance) throw;

        ledger.setBalance(msg.sender, balance - _amount);
    }

    /*
    Entry
    */
    function checkIn(uint _numCheckins) returns(bool) {
        int needed = int(price * ONE* _numCheckins);
        if (int(ledger.balanceOf(msg.sender)) > needed) {
            ledger.changeUsed(msg.sender, needed);
            return true;
        }
        return false;
    }

    // ERC20 Support. This could also use the fallback but
    // I prefer the control for now.

    event Transfer(address, address, uint);
    event Approval(address, address, uint);

    function totalSupply() constant returns(uint) {
        return ledger.totalSupply();
    }

    function transfer(address _to, uint _amount) returns(bool) {
        if (!transfersOn && msg.sender != owner) return false;
        if (! ledger.tokenTransfer(msg.sender, _to, _amount)) { return false; }

        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) returns (bool) {
        if (!transfersOn && msg.sender != owner) return false;
        if (! ledger.tokenTransferFrom(msg.sender, _from, _to, _amount) ) { return false;}

        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(address _from, address _to) constant returns(uint) {
        return ledger.allowance(_from, _to); 
    }

    function approve(address _spender, uint _value) returns (bool) {
        if ( ledger.tokenApprove(msg.sender, _spender, _value) ) {
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function balanceOf(address _addr) constant returns(uint) {
        return ledger.balanceOf(_addr);
    }
}

contract Ledger is Owned {
    mapping (address => uint) balances;
    mapping (address => uint) usedToday;

    mapping (address => bool) seenHere;
    address[] public seenHereA;

    mapping (address => mapping (address => uint256)) allowed;
    address token;
    uint public totalSupply = 0;

    function Ledger(address _owner, uint _preMined, uint ONE) {
        if (_owner == 0x0) throw;
        owner = _owner;

        seenHere[_owner] = true;
        seenHereA.push(_owner);

        totalSupply = _preMined *ONE;
        balances[_owner] = totalSupply;
    }

    modifier onlyToken {
        if (msg.sender != token) throw;
        _;
    }

    modifier onlyTokenOrOwner {
        if (msg.sender != token && msg.sender != owner) throw;
        _;
    }


    function tokenTransfer(address _from, address _to, uint amount) onlyToken returns(bool) {
        if (amount > balances[_from]) return false;
        if ((balances[_to] + amount) < balances[_to]) return false;
        if (amount == 0) { return false; }

        balances[_from] -= amount;
        balances[_to] += amount;

        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }

        return true;
    }

    function tokenTransferFrom(address _sender, address _from, address _to, uint amount) onlyToken returns(bool) {
        if (allowed[_from][_sender] <= amount) return false;
        if (amount > balanceOf(_from)) return false;
        if (amount == 0) return false;

        if ((balances[_to] + amount) < amount) return false;

        balances[_from] -= amount;
        balances[_to] += amount;
        allowed[_from][_sender] -= amount;

        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }

        return true;
    }


    function changeUsed(address _addr, int amount) onlyToken {
        int myToday = int(usedToday[_addr]) + amount;
        usedToday[_addr] = uint(myToday);
    }

    function resetUsedToday(uint8 startI, uint8 numTimes) onlyTokenOrOwner returns(uint8) {
        uint8 numDeleted;
        for (uint i = 0; i < numTimes && i + startI < seenHereA.length; i++) {
            if (usedToday[seenHereA[i+startI]] != 0) { 
                delete usedToday[seenHereA[i+startI]];
                numDeleted++;
            }
        }
        return numDeleted;
    }

    function balanceOf(address _addr) constant returns (uint) {
        // don&#39;t forget to subtract usedToday
        if (usedToday[_addr] >= balances[_addr]) { return 0;}
        return balances[_addr] - usedToday[_addr];
    }

    event Approval(address, address, uint);

    function tokenApprove(address _from, address _spender, uint256 _value) onlyToken returns (bool) {
        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function changeToken(address _token) onlyOwner {
        token = Token(_token);
    }

    function reduceTotalSupply(uint amount) onlyToken {
        if (amount > totalSupply) throw;

        totalSupply -= amount;    
    }

    function setBalance(address _addr, uint amount) onlyTokenOrOwner {
        if (balances[_addr] == amount) { return; }
        if (balances[_addr] < amount) {
            // increasing totalSupply
            uint increase = amount - balances[_addr];
            totalSupply += increase;
        } else {
            // decreasing totalSupply
            uint decrease = balances[_addr] - amount;
            //TODO: safeSub
            totalSupply -= decrease;
        }
        balances[_addr] = amount;
    }

}