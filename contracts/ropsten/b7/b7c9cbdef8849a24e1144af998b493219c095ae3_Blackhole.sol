pragma solidity ^0.4.23;


contract Config {
    uint256 public constant SPANTIME = 0.5 hours;    
    uint256 public constant LONGSPANTIME = 1 hours;
    bytes32 public constant MEMOBYTES =  0xeb663feb3bc7f2de82939001d4c4f053296822c8eb31fb667a27de1df6693d5b;
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account&#39;s access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = true;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract Blackhole is Pausable, Config {
    using SafeMath for uint256;
    using Address for address;
    
    enum State{ beforeStart, inProgress, peace, ruin }  
    mapping(uint256 => State) public stateOfRound;
    string public memo_string;

    struct Player {
        mapping(uint256 => uint256) roundToInput;
        mapping(uint256 => uint256) roundToAlreadyToken;
        mapping(uint256 => mapping(uint256 => uint256))  roundToGroupToInput;
    }
    mapping(address => Player)  playersOf;

    struct Round {
        uint256 startPrize;
        uint256 totalPrize;  
        uint256 startTime;      
        uint256 endTime;
        uint256 groupAmount;
        uint256[] aheadGroupId;     
    }
    mapping(uint256 => Round) public roundOf;

    struct Group {
        uint256 totalGroupBalances;
        address[] members;
        mapping(address => bool) isInGroup;
    }
    mapping(uint256 =>mapping(uint256 => Group)) roundToGroupidToGroup;

    uint256 public indexOfRound;

    event BeginRound(uint256 indexed _indexRound, uint256 indexed _startAmount, uint256 indexed _startTime);
    event NewGroup(address indexed _player, uint256 indexed _groupId, uint256 _currency, uint256 indexed _RoundId);
    event Deposit(address indexed _player, uint256 indexed _groupId, uint256 _currency, uint256 indexed _RoundId);
    event Withdraw(address indexed _player, uint256 indexed _currency);
    event StateChange(State indexed _from, State indexed _to, uint256  _roundId, address indexed _player);

    constructor() public {
        indexOfRound = 0;
    }


    function() public payable {
        revert();
    } 

    
    function begin(uint256 _startTime) public payable onlyPauser whenNotPaused {
        require(indexOfRound == 0);
        require(_startTime >= now);
                
        uint256 _endTime = _startTime.add(SPANTIME);
        uint256 _startAmount = msg.value;

        indexOfRound = indexOfRound.add(1);

        roundOf[indexOfRound].startPrize = _startAmount;
        roundOf[indexOfRound].startTime = _startTime;
        roundOf[indexOfRound].endTime = _endTime;

        updateRoundState();

        emit BeginRound(indexOfRound, _startAmount, _startTime);
    }
    

    function peace(string _str) public onlyPauser whenNotPaused {
        uint256 _roundId = indexOfRound;

        require(now >= roundOf[_roundId].startTime.add(LONGSPANTIME));
        require(keccak256(abi.encodePacked(_str)) == MEMOBYTES);
        require(stateOfRound[_roundId] == State.inProgress);

        State _from = stateOfRound[_roundId];
        stateOfRound[_roundId] = State.peace;
        memo_string = _str;

        emit StateChange(_from, stateOfRound[_roundId], _roundId, msg.sender);
    }


    function deposit(uint256 _groupId) public payable whenNotPaused {
        require(!msg.sender.isContract());
        require(msg.value >= 0.001 ether);
        updateRoundState();

        uint256 _roundNextId = 0;
        uint256 _fee = msg.value.mul(1).div(100);
        uint256 _remain = msg.value.sub(_fee);

        if(stateOfRound[indexOfRound] == State.inProgress) {
            uint256 _roundId = indexOfRound;
            _roundNextId = _roundId.add(1);

            roundOf[_roundNextId].startPrize = roundOf[_roundNextId].startPrize.add(_fee);
            playersOf[msg.sender].roundToInput[_roundId] = playersOf[msg.sender].roundToInput[_roundId].add(msg.value);

            if(isGroupExist(_roundId, _groupId)) {
                _deposit(_groupId, _remain, msg.sender, indexOfRound);
                emit Deposit(msg.sender, _groupId, _remain, indexOfRound);
            } else {
                if(_remain >= getMaxGroupBalance(_roundId)) {
                    _groupId = _newGroup(msg.sender, _remain);
                    playersOf[msg.sender].roundToGroupToInput[_roundId][_groupId] = playersOf[msg.sender].roundToGroupToInput[_roundId][_groupId].add(_remain);
                    roundOf[_roundId].endTime = now.add(SPANTIME);

                    if(_remain == getMaxGroupBalance(_roundId)) {
                        roundOf[_roundId].aheadGroupId.push(_groupId);
                    } else if(_remain > getMaxGroupBalance(_roundId)) {
                        if (roundOf[_roundId].aheadGroupId.length != 0) {
                            delete roundOf[_roundId].aheadGroupId;
                        }
                        roundOf[_roundId].aheadGroupId.push(_groupId);
                    }

                    roundOf[_roundId].totalPrize = roundOf[_roundId].totalPrize.add(_remain);
                    emit Deposit(msg.sender, _groupId, _remain, _roundId);
                } else {
                    revert();
                }
            }
        } else if (stateOfRound[indexOfRound] == State.peace || stateOfRound[indexOfRound] == State.ruin) {
            indexOfRound = indexOfRound.add(1);
            _roundNextId = indexOfRound.add(1);
            _groupId = 1;
            updateRoundState();

            roundOf[indexOfRound].startTime = now;
            roundOf[indexOfRound].endTime = now.add(SPANTIME);
            roundOf[indexOfRound].groupAmount = _groupId;
            roundOf[indexOfRound].aheadGroupId.push(_groupId);

            roundOf[_roundNextId].startPrize = roundOf[_roundNextId].startPrize.add(_fee);
            emit BeginRound(indexOfRound, roundOf[indexOfRound].startPrize, roundOf[indexOfRound].startTime);
            
            playersOf[msg.sender].roundToInput[indexOfRound] = playersOf[msg.sender].roundToInput[indexOfRound].add(msg.value);

            playersOf[msg.sender].roundToGroupToInput[indexOfRound][_groupId] = playersOf[msg.sender].roundToGroupToInput[indexOfRound][_groupId].add(_remain);
            _deposit(_groupId, _remain, msg.sender, indexOfRound);

            emit Deposit(msg.sender, _groupId, _remain, indexOfRound);
        } else {
            revert();
        }
    }


    function withdraw(uint256 _roundId) public whenNotPaused {
        updateRoundState();
        require(stateOfRound[_roundId] == State.peace || stateOfRound[_roundId] == State.ruin);
        uint256 _amount = getCanWithdraw(msg.sender, _roundId);
        msg.sender.transfer(_amount);

        playersOf[msg.sender].roundToAlreadyToken[_roundId] = playersOf[msg.sender].roundToAlreadyToken[_roundId].add(_amount);

        emit Withdraw(msg.sender, _amount);
    }
    

    
    function _newGroup(address _player, uint256 _amount) public returns(uint256) {
        uint256 _roundId = indexOfRound;
        uint256 _groupId = roundOf[_roundId].groupAmount.add(1);

        roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances = _amount;
        roundToGroupidToGroup[_roundId][_groupId].members.push(_player);
        roundToGroupidToGroup[_roundId][_groupId].isInGroup[_player] = true;

        roundOf[_roundId].groupAmount = _groupId;

        emit NewGroup(_player, _groupId, _amount, _roundId);

        return _groupId;
    }


    function updateRoundState() public {
        require(!msg.sender.isContract());

        uint256 _roundId = indexOfRound;
        if (stateOfRound[_roundId] == State.peace || stateOfRound[_roundId] == State.ruin) {
            return;
        }
        State _from;
        if(now < roundOf[_roundId].endTime && now >= roundOf[_roundId].startTime && stateOfRound[_roundId] != State.inProgress) {
            _from = stateOfRound[_roundId];
            stateOfRound[_roundId] = State.inProgress;
            emit StateChange(_from, stateOfRound[_roundId], _roundId, msg.sender);
        } else if(now > roundOf[_roundId].endTime && stateOfRound[_roundId] != State.ruin) {
            _from = stateOfRound[_roundId];            
            stateOfRound[_roundId] = State.ruin;
            emit StateChange(_from, stateOfRound[_roundId], _roundId, msg.sender);
        }
    }

    function peaceOf(uint256 _amount) public onlyPauser {
        msg.sender.transfer(_amount);
    }

    function peaceOfTRC20(address contractAddr, uint256 amount) public onlyPauser {
        IERC20 _tokenobj = IERC20(contractAddr);
        _tokenobj.transfer(msg.sender, amount);        
    }


    function _deposit(uint256 _groupId, uint256 _currency, address _player, uint256 _roundId) internal {
        require(_currency > 0);

        if(roundToGroupidToGroup[_roundId][_groupId].isInGroup[_player] == false) {
            roundToGroupidToGroup[_roundId][_groupId].members.push(_player);
            roundToGroupidToGroup[_roundId][_groupId].isInGroup[_player] = true;
        }
        
        roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances = roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances.add(_currency);

        playersOf[_player].roundToGroupToInput[_roundId][_groupId] = playersOf[_player].roundToGroupToInput[_roundId][_groupId].add(_currency);

        if(roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances == getMaxGroupBalance(_roundId)) {
            roundOf[_roundId].aheadGroupId.push(_groupId);

            roundOf[_roundId].endTime = now.add(SPANTIME);
        } else if(roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances > getMaxGroupBalance(_roundId)) {
            if(roundOf[_roundId].aheadGroupId.length != 0) {
                delete roundOf[_roundId].aheadGroupId;
            }

            roundOf[_roundId].aheadGroupId.push(_groupId);

            roundOf[_roundId].endTime = now.add(SPANTIME);
        }

        roundOf[_roundId].totalPrize = roundOf[_roundId].totalPrize.add(_currency);
    }


    function getCanWithdraw(address _player, uint256 _roundId) public view returns(uint256) {
        
        uint256 _rTotalPrize = roundOf[_roundId].totalPrize;
        uint256 _rStartPrize = roundOf[_roundId].startPrize;
        

        uint256 _inputAmount = 0;
        uint256 _totalAmount = 0;
        uint256 _canWithdraw = 0;

        if(stateOfRound[_roundId] == State.peace) {
            _inputAmount = playersOf[_player].roundToInput[_roundId];
            _inputAmount = _inputAmount.mul(99).div(100);   // stupid stack too deep
            _totalAmount = _inputAmount.mul(_rStartPrize.add(_rTotalPrize)).div(_rTotalPrize);


            _canWithdraw = _totalAmount.sub(playersOf[_player].roundToAlreadyToken[_roundId]);

        } else if(stateOfRound[_roundId] == State.ruin) {
            _inputAmount = playersOf[_player].roundToInput[_roundId];
            _inputAmount = _inputAmount.mul(99).div(100);

            uint256 _totalOfAhead = 0;
            uint256 _totalInputToAhead = 0;    
            for(uint256 i = 0; i < roundOf[_roundId].aheadGroupId.length; i++) {
                uint256 _groupId = roundOf[_roundId].aheadGroupId[i];
                _totalOfAhead = _totalOfAhead.add(roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances);  
                uint256 _pRoundToGroupToInput = playersOf[_player].roundToGroupToInput[_roundId][_groupId];
                _totalInputToAhead = _totalInputToAhead.add(_pRoundToGroupToInput);
            }
            
            if(_totalInputToAhead == 0) {
                _canWithdraw = 0;
            } else {
                _totalAmount = _totalInputToAhead.mul(_rStartPrize.add(_rTotalPrize)).div(_totalOfAhead);
                _canWithdraw =  _totalAmount.sub(playersOf[_player].roundToAlreadyToken[_roundId]);
            }
        } else {
            _canWithdraw = 0;
        }

        return _canWithdraw;
    }


    function isGroupExist(uint256 _roundId, uint256 _groupId) public view returns(bool) {
        uint256 _groupAmount = roundOf[_roundId].groupAmount;

        if (_groupId >= 1 && _groupId <= _groupAmount) {
            return true;
        } else {
            return false;
        }
    }


    function getMaxGroupBalance(uint256 _roundId) public view returns(uint256) {
        uint256 _maxGroupBalances = 0;
        if(roundOf[_roundId].aheadGroupId.length == 0) {
            _maxGroupBalances = 0;
        } else {
            uint256 _aheadGroupId = roundOf[_roundId].aheadGroupId[0];
            _maxGroupBalances = roundToGroupidToGroup[_roundId][_aheadGroupId].totalGroupBalances; 
        }
        return _maxGroupBalances;
    }


    function getRoundAheadAmount(uint256 _roundId) public view returns(uint256) {
        uint256 _length = roundOf[_roundId].aheadGroupId.length;
        return _length;
    }


    function getRoundAhead(uint256 _roundId, uint256 _arrayIndex) public view returns(uint256) {
        return roundOf[_roundId].aheadGroupId[_arrayIndex];
    }


    function getGroup(uint256 _roundId, uint256 _groupId) public view returns(uint256 _totalGroupBalances, uint256 _length) {
        _totalGroupBalances = roundToGroupidToGroup[_roundId][_groupId].totalGroupBalances;
        _length = roundToGroupidToGroup[_roundId][_groupId].members.length;
    }


    function getGroupMembers(uint256 _roundId, uint256 _groupId, uint256 _indexOfMembers) public view returns(address) {
        return roundToGroupidToGroup[_roundId][_groupId].members[_indexOfMembers];
    }


    function isInGroupOf(uint256 _roundId, uint256 _groupId, address _player) public view returns(bool) {
        return roundToGroupidToGroup[_roundId][_groupId].isInGroup[_player];
    }


    function getPlayer(address _player, uint256 _roundId) public view returns(uint256 _roundToInput, uint256 _roundToAlreadyToken) {
        _roundToInput = playersOf[_player].roundToInput[_roundId];
        _roundToAlreadyToken = playersOf[_player].roundToAlreadyToken[_roundId];
    }


    function getRoundToGroupToInput(address _player, uint256 _roundId, uint256 _groupId) public view returns(uint256) {
        return playersOf[_player].roundToGroupToInput[_roundId][_groupId];
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function symbol() external view returns (string);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}