pragma solidity ^0.4.24;
contract MultiSig_Wallet{
    event Agreement(address indexed sender, uint indexed transactionId);
    //event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(address indexed initiator, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    //event RequirementChange(uint required);

    uint8 public votesRequired;
    mapping (address => bool) public owners;
    mapping (uint => Transaction) public transactions;
    uint public transactionCount;

    modifier tValid(uint _transactionId){
        require(transactions[_transactionId].receiver != 0x0);
        _;
    }

    modifier onlyOwners(){
        require(owners[msg.sender]);
        _;
    }

    struct Transaction{
        address receiver;
        uint256 amount;
        bytes data;
        uint8 status; // 0 -> submitted, 1 -> successfully executed, 2 -> voted good but execution failed
        address[] yays; // users who voted for this transaction.
    }

    /**
     * @notice constructor function; reverts if `_participants` has duplicates or `0x0`.
     **/
    constructor(address[] _participants, uint8 _votingThreshold){
        require(_participants.length != 0 &&
                _votingThreshold <= _participants.length &&
                _votingThreshold != 0);

        address currP;
        for (uint i = 0; i<_participants.length; i++){
            currP = _participants[i];
            require (currP == 0x0 || !isOwner(currP));
            owners[currP] = true;
        }
        votesRequired = _votingThreshold;
    }

    function () payable {
        require(msg.value > 0);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice let&#39;s any owner execute a transaction once it&#39;s voted for and returns
     **/
    function executeTransaction(uint _tId) public onlyOwners tValid(_tId) returns (bool success) {
        Transaction memory t = transactions[_tId];
        if (t.status != 1 && t.yays.length >= votesRequired){
            if (t.receiver.send(t.amount)){
                t.status = 1;
                emit Execution(_tId);
                success = true;
            } else {
                t.status = 2;
                emit ExecutionFailure(_tId);
                success = false;
            }
        }
        success = false;
    }

    /**
     * @notice Lets owners propose a new transaction.
     * @param _data is mostly &#39;0x0&#39; and it&#39;s ok that way.
     **/
    function proposeTransaction(address _receiver, uint256 _amount, bytes _data) public onlyOwners returns (bool) {
        require(_receiver != 0x0 && _amount != 0);
        Transaction memory newT;
        newT.receiver = _receiver;
        newT.amount = _amount;
        newT.data = _data;

        transactions[transactionCount] = newT;
        emit Submission(msg.sender, transactionCount);
        transactionCount++;
        return true;
    }

    /**
     * @notice Voting function, reverts if already voted for the transaction.
     */
    function voteForTransaction(uint _tId) public onlyOwners tValid(_tId){
        Transaction memory t = transactions[_tId];
        for(uint i = 0; i < t.yays.length; i++){
            require(t.yays[i] != msg.sender);
        }
        transactions[_tId].yays.push(msg.sender);
        emit Agreement(msg.sender, _tId);
    }

    function quit() public onlyOwners{
        owners[msg.sender] = false;
        emit OwnerRemoval(msg.sender);
    }

    /*
     *  Getter Functions
     */

    function isOwner(address _user) public view returns (bool){
        return (owners[_user]);
    }

    function isVotedGood(uint _tId) public view tValid(_tId) returns (bool) {
        return (transactions[_tId].yays.length >= votesRequired);
    }

    function getYayNum(uint _tId) public view tValid(_tId) returns (uint){
        return (transactions[_tId].yays.length);
    }

    function getYays(uint _tId) public view tValid(_tId) returns (address[]){
        return (transactions[_tId].yays);
    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

}