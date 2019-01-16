pragma solidity ^0.5.0;

/**
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
     * Constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Only the owner of contract
     */ 
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    /**
     * @dev transfer the ownership to other
     *      - Only the owner can operate
     */ 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /** 
     * @dev Accept the ownership from last owner
     */ 
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Only new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TripioToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}

contract FoundingTeam is Owned {

    // Team with 4 members
    struct Team {
        address m0;
        address m1;
        address m2;
        address m3;
    }

    struct Deposit {
        address owner;
        uint256 amount;
    }

    Team team;
    Team newTeam;

    // TRIO contract 
    TripioToken tripio;

    // Percentage of funds
    mapping(address => uint16) percentages;
    mapping(address => uint16) newPercentages;

    // Signatures
    mapping(address => bool) signatures;

    // All deposits
    mapping(uint256 => Deposit) deposits;
    uint256 depositIndex;

    // Enable 
    bool public enabled;
    uint8 public newStatus;

    // Terminal
    bool public terminal;

    // Timestamps
    uint256[] timestamps;

    /**
     * This emits when deposited
     */
    event Deposited(address _owner, uint256 _value);

    /**
     * This emits when percentages updated
     */
    event PercentagesUpdated(uint16 _m0, uint16 _m1, uint16 _m2, uint16 _m3);

    /**
     * This emits when members updated
     */
    event MembersUpdated(address _m0, address _m1, address _m2, address _m3);
    
    /**
     * This emits when status updated
     */
    event StatusUpdated(uint8 _status);

    /**
     * This emits when terminated
     */
    event Terminated();

    /**
     * This emits when candied
     */
    event Candy();

    /**
     * @dev Constructor 
     * @param _m0 Team member 0 has 44% found
     * @param _m1 Team member 1 has 25% found
     * @param _m2 Team member 2 has 18.6% found
     * @param _m3 Team member 3 has 12.4% found 
     * @param _trio TRIO contract address
     */
    constructor(address _m0, address _m1, address _m2, address _m3, address _trio) public {
        team = Team(_m0, _m1, _m2, _m3);
        percentages[_m0] = 440;
        percentages[_m1] = 250;
        percentages[_m2] = 186;
        percentages[_m3] = 124;

        tripio = TripioToken(_trio);

        enabled = true;

        // Only for test
        timestamps.push(1544544000); // 2018-12-12	00:00 
        timestamps.push(1544630400); // 2018-12-13	00:00 
        
        // All timestamps from 2019-06-01 to 2021-05-01
        timestamps.push(1559361600); // 2019-06-01	12:00 
        timestamps.push(1561953600); // 2019-07-01	12:00 
        timestamps.push(1564632000); // 2019-08-01	12:00 
        timestamps.push(1567310400); // 2019-09-01	12:00 
        timestamps.push(1569902400); // 2019-10-01	12:00 
        timestamps.push(1572580800); // 2019-11-01	12:00
        timestamps.push(1575172800); // 2019-12-01	12:00
        timestamps.push(1577851200); // 2020-01-01	12:00
        timestamps.push(1580529600); // 2020-02-01	12:00
        timestamps.push(1583035200); // 2020-03-01	12:00
        timestamps.push(1585713600); // 2020-04-01	12:00
        timestamps.push(1588305600); // 2020-05-01	12:00
        timestamps.push(1590984000); // 2020-06-01	12:00
        timestamps.push(1593576000); // 2020-07-01	12:00
        timestamps.push(1596254400); // 2020-08-01	12:00
        timestamps.push(1598932800); // 2020-09-01	12:00
        timestamps.push(1601524800); // 2020-10-01	12:00
        timestamps.push(1604203200); // 2020-11-01	12:00
        timestamps.push(1606795200); // 2020-12-01	12:00
        timestamps.push(1609473600); // 2021-01-01	12:00
        timestamps.push(1612152000); // 2021-02-01	12:00
        timestamps.push(1614571200); // 2021-03-01	12:00
        timestamps.push(1617249600); // 2021-04-01	12:00
        timestamps.push(1619841600); // 2021-05-01	12:00
    }

    /**
     * Only member
     */
    modifier onlyMember {
        require(team.m0 == msg.sender || team.m1 == msg.sender || team.m2 == msg.sender || team.m3 == msg.sender, "Only member");
        _;
    }

    /**
     * Only owner or members
     */
    modifier onlyOwnerOrMember {
        require(msg.sender == owner || team.m0 == msg.sender || team.m1 == msg.sender || team.m2 == msg.sender || team.m3 == msg.sender, "Only member");
        _;
    }

    function _withdraw() private {
        uint256 tokens = tripio.balanceOf(address(this));
        for(uint256 i = 1; i <= depositIndex; i++) {
            if(deposits[i].amount <= tokens) {
                tripio.transfer(deposits[i].owner, deposits[i].amount);
                tokens -= deposits[i].amount;
            }else {
                tripio.transfer(deposits[i].owner, tokens);
                break;
            }
        }

        depositIndex = 0;
    }

    function _resetPercentages() private {
        delete newPercentages[team.m0];
        delete newPercentages[team.m1];
        delete newPercentages[team.m2];
        delete newPercentages[team.m3];
    }

    function _resetMembers() private {
        newTeam.m0 = address(0);
        newTeam.m1 = address(0);
        newTeam.m2 = address(0);
        newTeam.m3 = address(0);
    }

    function _resetStatus() private {
        newStatus = 0;
    }

    function _resetTerminal() private {
        terminal = false;
    }

    /**
     * Current members or new memebers
     */
    function teamMembers(bool _new) external view returns(address[] memory _members) {
        _members = new address[](4);
        if(_new) {  
            _members[0] = newTeam.m0;
            _members[1] = newTeam.m1;
            _members[2] = newTeam.m2;
            _members[3] = newTeam.m3;
        }else {
            _members[0] = team.m0;
            _members[1] = team.m1;
            _members[2] = team.m2;
            _members[3] = team.m3;
        }
    }

    /**
     * Current percentages or new percentages
     */
    function teamPercentages(bool _new) external view returns(uint256[] memory _percentages) {
        _percentages = new uint256[](4);
        if(_new) {
            _percentages[0] = newPercentages[team.m0];
            _percentages[1] = newPercentages[team.m1];
            _percentages[2] = newPercentages[team.m2];
            _percentages[3] = newPercentages[team.m3];
        }else {
            _percentages[0] = percentages[team.m0];
            _percentages[1] = percentages[team.m1];
            _percentages[2] = percentages[team.m2];
            _percentages[3] = percentages[team.m3];
        }
    }

    /**
     * Current signatures
     */
    function teamSignatures() external view returns(bool[] memory _signatures) {
        _signatures = new bool[](4);
        _signatures[0] = signatures[team.m0];
        _signatures[1] = signatures[team.m1];
        _signatures[2] = signatures[team.m2];
        _signatures[3] = signatures[team.m3];
    }

    /**
     * All schedules 
     */
    function teamTimestamps() external view returns(uint256[] memory _timestamps) {
        _timestamps = new uint256[](timestamps.length);
        for(uint256 i = 0; i < timestamps.length; i++) {
            _timestamps[i] = timestamps[i];
        }
    }

    /**
     * Record fund reserve
     */
    function deposit() external returns(bool) {
        uint256 value = tripio.allowance(msg.sender, address(this));
        require(value > 0, "Value must more than 0");
        tripio.transferFrom(msg.sender, address(this), value);
        depositIndex++;
        deposits[depositIndex] = Deposit(msg.sender, value);
        
        // Event
        emit Deposited(msg.sender, value);
    } 

    /**
     * Update the percentages, need all memebers&#39;s signatures
     */
    function updatePercentages(uint16 _m0, uint16 _m1, uint16 _m2, uint16 _m3) external onlyMember {
        _resetStatus();
        _resetMembers();
        _resetTerminal();
        if(_m0 + _m1 + _m2 + _m3 == 1000){
            newPercentages[team.m0] = _m0;
            newPercentages[team.m1] = _m1;
            newPercentages[team.m2] = _m2;
            newPercentages[team.m3] = _m3;

            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
        }

        if (newPercentages[team.m0] + newPercentages[team.m1] + newPercentages[team.m2] + newPercentages[team.m3] == 1000) {
            signatures[msg.sender] = true;
        }
        
        if(signatures[team.m0] && signatures[team.m1] && signatures[team.m2] && signatures[team.m3]) {
            percentages[team.m0] = newPercentages[team.m0];
            percentages[team.m1] = newPercentages[team.m1];
            percentages[team.m2] = newPercentages[team.m2];
            percentages[team.m3] = newPercentages[team.m3];

            _resetPercentages();

            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
        }

        // Event 
        emit PercentagesUpdated(newPercentages[team.m0], newPercentages[team.m1], newPercentages[team.m2], newPercentages[team.m3]);
    }

    /**
     * Update the team members, need all memebers&#39;s signatures
     */
    function updateMembers(address _m0, address _m1, address _m2, address _m3) external onlyMember {
        _resetStatus();
        _resetPercentages();
        _resetTerminal();
        if(_m0 != address(0) && _m1 != address(0) && _m2 != address(0) && _m3 != address(0)) {
            newTeam.m0 = _m0;
            newTeam.m1 = _m1;
            newTeam.m2 = _m2;
            newTeam.m3 = _m3;

            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
        }
        if(newTeam.m0 != address(0) && newTeam.m1 != address(0) && newTeam.m2 != address(0) && newTeam.m3 != address(0)) {
            signatures[msg.sender] = true;
        }
        if(signatures[team.m0] && signatures[team.m1] && signatures[team.m2] && signatures[team.m3]) {
            team.m0 = newTeam.m0;
            team.m1 = newTeam.m1;
            team.m2 = newTeam.m2;
            team.m3 = newTeam.m3;

            _resetMembers();

            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
        }

        // Event
        emit MembersUpdated(newTeam.m0, newTeam.m1, newTeam.m2, newTeam.m3);
    }

    /**
     * Update the contract status, enable or disable
     */
    function updateStatus(uint8 _status)  external onlyMember {
        _resetMembers();
        _resetPercentages();
        _resetTerminal();
        if(_status != 0) {
            newStatus = _status;

            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
        }
        if(newStatus != 0) {
            signatures[msg.sender] = true;
        }
        uint8 sigCount = 0;
        if(signatures[team.m0]) {
            sigCount++; 
        }
        if(signatures[team.m1]) {
            sigCount++; 
        }
        if(signatures[team.m2]) {
            sigCount++; 
        }
        if(signatures[team.m3]) {
            sigCount++; 
        }
        if(sigCount >= 3) {
            if(newStatus == 1) {
                enabled = true;               
                // restart and reset timestamps
                for(uint256 i = 0; i < timestamps.length; i++) {
                    if(timestamps[i] != 0 && timestamps[i] < now) {
                        timestamps[i] = 0;
                    }
                }
            }else if(newStatus == 2) {
                enabled = false;
            }
            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
            _resetStatus();
        }

        // Event
        emit StatusUpdated(newStatus);
    }

    /**
     * Terminate the contract, the remaining candy will transfer to the original owner
     */
    function terminate(bool _terminal) external onlyMember {
        _resetStatus();
        _resetMembers();
        _resetPercentages();
        if(_terminal) {
            terminal = true;
            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];
        }
        if(terminal) {
            signatures[msg.sender] = true;
        }
        if(signatures[team.m0] && signatures[team.m1] && signatures[team.m2] && signatures[team.m3]) {
            _withdraw();

            delete signatures[team.m0];
            delete signatures[team.m1];
            delete signatures[team.m2];
            delete signatures[team.m3];

            _resetTerminal();
        }

        // Event
        emit Terminated();
    }

    /**
     * Candy every month
     */
    function candy() external onlyOwnerOrMember {
        require(enabled, "Must enabled");
        // Remaining tokens
        uint256 tokens = tripio.balanceOf(address(this));
        uint256 count = 0;
        for(uint256 i = 0; i < timestamps.length; i++) {
            if(timestamps[i] != 0) {
                count++;
            }
        }
        require(tokens > count && count > 0, "");
        uint256 part = tokens/count;
        if(count == 1) {
            part = tokens;
        }

        uint256 token0 = part * percentages[team.m0]/1000;
        uint256 token1 = part * percentages[team.m1]/1000;
        uint256 token2 = part * percentages[team.m2]/1000;
        uint256 token3 = part * percentages[team.m3]/1000;

        uint256 enabledCount = 0;
        for(uint256 i = 0; i < timestamps.length; i++) {
            if(timestamps[i] != 0 && timestamps[i] < now) {
                enabledCount++;
                if(token0 > 0) {
                    tripio.transfer(team.m0, token0);
                    tokens -= token0;
                }
                if(token1 > 0) {
                    tripio.transfer(team.m1, token1);
                    tokens -= token1;
                }
                if(token2 > 0) {
                    tripio.transfer(team.m2, token2);
                    tokens -= token2;
                }
                if(token3 > 0) {
                    tripio.transfer(team.m3, token3);
                    tokens -= token3;
                }
                timestamps[i] = 0;
            }
        }
        require(enabledCount > 0, "");

        if(count == 1 && tokens > 0) {
            // withdraw the remaining candy
            _withdraw();
        }

        // Event
        emit Candy();
    }
}