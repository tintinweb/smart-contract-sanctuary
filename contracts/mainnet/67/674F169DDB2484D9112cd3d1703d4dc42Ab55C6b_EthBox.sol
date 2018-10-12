pragma solidity ^0.4.24;

contract AddressBook {

    mapping(address => uint32) public uidOf;
    mapping(uint32 => address) public addrOf;

    uint32 public topUid;

    function address_register(address _addr) internal {
        require(uidOf[_addr] == 0, &#39;addr exsists&#39;);
        uint32 uid = ++topUid;
        uidOf[_addr] = uid;
        addrOf[uid] = _addr;
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
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        assert(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);

        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract EthBox is Ownable, AddressBook {
    using SafeMath for uint256;

    event Deposited(uint indexed pid, uint indexed rid, uint number, address indexed payee, uint256 weiAmount, address inviter, RoundState state);
    event RoundFinished(uint indexed pid, uint indexed rid, uint indexed number);

    event NewRound(uint indexed pid, uint indexed rid, uint number, RoundState state);


    // Events that are issued to make statistic recovery easier.
    event FailedPayment(uint indexed pid, uint indexed rid, address indexed beneficiary, uint amount, uint count);
    event Payment(uint indexed pid, uint indexed rid, address indexed beneficiary, uint amount, uint count, RoundState state);
    event LogDepositReceived(address indexed sender);
    event InviterRegistered(address indexed inviter, uint value);
    event InviterWithDraw(address indexed inviter, uint value);

    uint INVITER_FEE_PERCENT = 30; 
    uint constant INVITER_MIN_VALUE = 100 finney; 

    uint public lockedInBets;

    enum RoundState{READY, RUNNING, REMOVED, FINISHED, WITHDRAWED}

    struct Round {
        uint32[] peoples; 
        uint price;
        uint min_amount;
        uint max_amount;
        uint remainPrice;
        uint HOUSE_EDGE_PERCENT;
        RoundState state;
        bool valid;
        bool willremove;
        bytes32 secretEncrypt;
        uint count;
    }

    function() public payable {emit LogDepositReceived(msg.sender);}

    constructor() public Ownable(){}

    mapping(uint => mapping(uint => Round)) public bets;
    mapping(address => uint) public inviters;

    uint public inviterValues;

    modifier onlyHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier onlyIfRoundNotFinished(uint pid, uint rid){
        require(bets[pid][rid].state != RoundState.FINISHED);
        _;
    }

    modifier onlyIfRoundFinished(uint pid, uint rid){
        require(bets[pid][rid].state == RoundState.FINISHED);
        _;
    }

    modifier onlyIfRoundWithdrawed(uint pid, uint rid){
        require(bets[pid][rid].state == RoundState.WITHDRAWED);
        _;
    }

    modifier onlyIfBetExist(uint pid, uint rid){
        require(bets[pid][rid].valid);
        _;
    }

    modifier onlyIfBetNotExist(uint pid, uint rid){
        require(!bets[pid][rid].valid);
        _;
    }

    function setHouseEdge(uint pid, uint rid, uint _edge) public onlyOwner {
        if (bets[pid][rid].valid) {
            bets[pid][rid].HOUSE_EDGE_PERCENT = _edge;
        }
    }

    function setInviterEdge(uint _edge) public onlyOwner {
        INVITER_FEE_PERCENT = _edge;
    }

    function inviterRegister() onlyHuman payable external {
        require(msg.value == INVITER_MIN_VALUE, "register value must greater than min value");

        inviters[msg.sender] = inviters[msg.sender].add(msg.value);
        inviterValues = inviterValues.add(msg.value);
        emit InviterRegistered(msg.sender, msg.value);

    }

    function newRound(uint pid, uint rid, uint _price, uint _min_amount, uint _edge, bytes32 _secretEncrypt, uint count) private {
        Round storage r = bets[pid][rid];
        require(!r.valid);
        r.price = _price;
        r.min_amount = _min_amount;
        r.max_amount = _price;
        r.HOUSE_EDGE_PERCENT = _edge;
        r.state = RoundState.RUNNING;
        r.remainPrice = _price;
        r.valid = true;
        r.secretEncrypt = _secretEncrypt;
        // r.firstBlockNum = block.number;
        r.count = count;

    }


    function buyTicket(uint pid, uint rid, address _inviter) public onlyHuman onlyIfBetExist(pid, rid) onlyIfRoundNotFinished(pid, rid) payable {
        uint256 amount = msg.value;

        require(msg.sender != address(0x0), "invalid payee address");

        Round storage round = bets[pid][rid];

        require(round.remainPrice > 0, "remain price less then zero");
        require(amount >= round.min_amount && amount <= round.max_amount, "Amount should be within range.");
        require(amount <= round.remainPrice, "amount can not greater than remain price");
        require(amount % round.min_amount == 0, "invalid amount");

        if (uidOf[msg.sender] == 0) {
            address_register(msg.sender);
        }

        for (uint i = 0; i < amount.div(round.min_amount); i++) {
            round.peoples.push(uidOf[msg.sender]);
        }

        // round.blockNum = block.number;
        round.remainPrice = round.remainPrice.sub(amount);
        lockedInBets = lockedInBets.add(amount);

        addInviterValue(amount, round.HOUSE_EDGE_PERCENT, msg.sender, _inviter);

        if (round.remainPrice == 0) {
            round.state = RoundState.FINISHED;
            emit RoundFinished(pid, rid, round.count);
        }

        emit Deposited(pid, rid, round.count, msg.sender, amount, _inviter, round.state);
    }

    function addInviterValue(uint amount, uint edge, address sender, address _inviter) private {
        uint fee = amount.mul(edge).div(100);
        //不计算同一帐号买入的抽成
        if (sender != _inviter && inviters[_inviter] >= INVITER_MIN_VALUE) {
            uint _ifee = fee.mul(INVITER_FEE_PERCENT).div(100);
            inviters[_inviter] = inviters[_inviter].add(_ifee);
            inviterValues = inviterValues.add(_ifee);
        }
    }

    function payout(uint pid, uint rid, bytes32 _secret, bytes32 _nextSecretEncrypt) external onlyIfBetExist(pid, rid) onlyIfRoundFinished(pid, rid) {

        Round storage round = bets[pid][rid];
        require(round.secretEncrypt == keccak256(abi.encodePacked(_secret)), "secret is not valid.");

        uint result = uint(keccak256(abi.encodePacked(_secret, blockhash(block.number)))) % (round.price.div(round.min_amount));
        address luckGuy = addrOf[round.peoples[result]];
        require(luckGuy != address(0x0));
        uint256 bonus = round.price.sub(round.price.mul(round.HOUSE_EDGE_PERCENT).div(100));

        if (bonus > 0) {
            if (withdraw(pid, rid, luckGuy, bonus)) {
                round.state = RoundState.WITHDRAWED;
                lockedInBets = lockedInBets.sub(round.price);

                clearRound(pid, rid, _nextSecretEncrypt, round.willremove, round.price, round.min_amount, round.HOUSE_EDGE_PERCENT, round.count);

                emit Payment(pid, rid, luckGuy, bonus, round.count - 1, round.state);

            } else {
                emit FailedPayment(pid, rid, luckGuy, bonus, round.count);
            }
        }
    }

    function clearRound(uint pid, uint rid, bytes32 _secretEncrypt, bool willremove, uint price, uint min_amount, uint edge, uint count) private onlyIfBetExist(pid, rid) onlyIfRoundWithdrawed(pid, rid) {
        delete bets[pid][rid];
        if (!willremove) {
            newRound(pid, rid, price, min_amount, edge, _secretEncrypt, count + 1);
            emit NewRound(pid, rid, count + 1, RoundState.RUNNING);
        } else {
            emit NewRound(pid, rid, count + 1, RoundState.REMOVED);
        }

    }

    function removeRound(uint pid, uint rid) external onlyOwner onlyIfBetExist(pid, rid) {
        Round storage r = bets[pid][rid];
        r.willremove = true;
    }

    function addRound(uint pid, uint rid, uint _price, uint _min_amount, uint _edge, bytes32 _secretEncrypt) external onlyOwner onlyIfBetNotExist(pid, rid) {
        newRound(pid, rid, _price, _min_amount, _edge, _secretEncrypt, 1);
    }


    function withdraw(uint pid, uint rid, address beneficiary, uint withdrawAmount) private onlyIfBetExist(pid, rid) returns (bool){
        Round storage r = bets[pid][rid];
        require(withdrawAmount < r.price);
        require(withdrawAmount <= address(this).balance, "Increase amount larger than balance.");

        return beneficiary.send(withdrawAmount);
    }

    // Funds withdrawal to cover costs of operation.
    function withdrawFunds(address payee) external onlyOwner {
        uint costvalue = costFunds();
        require(costvalue > 0, "has no cost funds");
        payee.transfer(costvalue);
    }

    function costFunds() public view returns (uint){
        return address(this).balance.sub(lockedInBets).sub(inviterValues);
    }

    function payToInviter(uint _value) onlyHuman external {
        _payToInviter(msg.sender, _value);
    }

    function _payToInviter(address _inviter, uint _value) private {
        require(_value > 0 && inviters[_inviter] >= _value, "can not pay back greater then value");
        require(inviters[_inviter] <= address(this).balance);

        inviters[_inviter] = inviters[_inviter].sub(_value);
        inviterValues = inviterValues.sub(_value);
        _inviter.transfer(_value);
        emit InviterWithDraw(_inviter, _value);
    }

    function forceWithDrawToInviter(address _inviter, uint _value) onlyOwner external {
        _payToInviter(_inviter, _value);
    }


    function kill() external onlyOwner {
        require(lockedInBets == 0, "All games should be processed settled before self-destruct.");
        require(inviterValues == 0, "All inviter fee should be withdrawed before self-destruct.");
        selfdestruct(owner);
    }

    function lengthOfKeys(uint pid, uint rid) public onlyIfBetExist(pid, rid) view returns (uint){
        Round storage r = bets[pid][rid];
        return r.peoples.length;
    }

    function roundCount(uint pid, uint rid) public onlyIfBetExist(pid, rid) view returns (uint){
        Round storage r = bets[pid][rid];
        return r.count;
    }

    function roundState(uint pid, uint rid) public onlyIfBetExist(pid, rid) view returns (RoundState){
        Round storage r = bets[pid][rid];
        return r.state;
    }
}