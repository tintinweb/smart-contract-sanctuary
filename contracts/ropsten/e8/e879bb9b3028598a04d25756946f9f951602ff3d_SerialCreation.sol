pragma solidity 0.4.25;


contract Serial {

    event theWasaBuz(address initiator, address oSingleThing);
    mapping(address => bool) public doesntMatter;
    mapping(address => address[]) public Matter;


    function getInstantiationCount(address creator)
        public
        constant
        returns (uint)
    {
        return Matter[creator].length;
    }


    function register(address oSingleThing)
        internal
    {
        doesntMatter[oSingleThing] = true;
        Matter[msg.sender].push(oSingleThing);
        emit theWasaBuz(msg.sender, oSingleThing);
    }
}


contract TheBox {

    event Yes(address indexed sender, uint indexed transactionId);
    event NoNo(address indexed sender, uint indexed transactionId);
    event Ok(uint indexed transactionId);
    event LetsGo(uint indexed transactionId);
    event YouMissed(uint indexed transactionId);
    event More(address indexed sender, uint value);
    event PlusOne(address indexed owner);
    event MinusOne(address indexed owner);
    event ChngVal(uint required);
    event MocountChng(uint newMocount);
    uint private mocount;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ocount, uint _required) {
        require(ocount <= mocount
            && _required <= ocount
            && _required != 0
            && ocount != 0);
        _;
    }

    function() public
        payable
    {
        if (msg.value > 0)
            emit More(msg.sender, msg.value);
    }


    constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        mocount = 5000;
    }


    function addOne(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit PlusOne(owner);
    }


    function remOne(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            chngReNo(owners.length);
        emit MinusOne(owner);
    }


    function replOne(address owner, address newOwner)
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
        emit MinusOne(owner);
        emit PlusOne(newOwner);
    }

    function whatIsMocount()
        public
        view
        returns(uint)
        {
        return mocount;
    }

    function setMocount(uint newMocount)
        public
        {
        require(newMocount > 0);
        mocount = newMocount;
        emit MocountChng(newMocount);
    }

    function chngReNo(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit ChngVal(_required);
    }


    function subTx(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTx(destination, value, data);
        sayYes(transactionId);
    }


    function sayYes(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Yes(msg.sender, transactionId);
        excTx(transactionId);
    }


    function sayNoNo(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit NoNo(msg.sender, transactionId);
    }


    function excTx(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isYes(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (txn.destination.call.value(txn.value)(txn.data))
                emit LetsGo(transactionId);
            else {
                emit YouMissed(transactionId);
                txn.executed = false;
            }
        }
    }


    function isYes(uint transactionId)
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


    function addTx(address destination, uint value, bytes data)
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
        emit Ok(transactionId);
    }


    function getYesCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }


    function getTxCon(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }


    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }


    function getYes(uint transactionId)
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


    function getTxIds(uint from, uint to, bool pending, bool executed)
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
}


contract TheLimBox is TheBox {


    event DLC(uint theDL);


    uint public theDL;
    uint public LDwas;
    uint public justTD;


    constructor(address[] _owners, uint _required, uint _dailyLimit)
        public
        TheBox(_owners, _required)
    {
        theDL = _dailyLimit;
    }


    function chngDL(uint _dailyLimit)
        public
        onlyWallet
    {
        theDL = _dailyLimit;
        emit DLC(_dailyLimit);
    }


    function exTx(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isYes(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) {
            txn.executed = true;
            if (!_confirmed)
                justTD += txn.value;
            if (txn.destination.call.value(txn.value)(txn.data))
                emit LetsGo(transactionId);
            else {
                emit YouMissed(transactionId);
                txn.executed = false;
                if (!_confirmed)
                    justTD -= txn.value;
            }
        }
    }


    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (now > LDwas + 24 hours) {
            LDwas = now;
            justTD = 0;
        }
        if (justTD + amount > theDL || justTD + amount < justTD)
            return false;
        return true;
   }


    function calcMaxWithdraw()
        public
        constant
        returns (uint)
    {
        if (now > LDwas + 24 hours)
            return theDL;
        if (theDL < justTD)
            return 0;
        return theDL - justTD;
    }


}


contract SerialCreation is Serial {


    function create(address[] _someone, uint _requi, uint _dL)
        public
        returns (address wallet)
    {
        wallet = new TheLimBox(_someone, _requi, _dL);
        register(wallet);
    }

}