//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IAREA {
    function receiveRevenue(uint _amount) external;
    function borrow(address _to, uint _amount) external;
}

interface IDOLA {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPremiumModel {
    function getPremium(uint planID, uint amount, uint duration, address user) external view returns (uint);
}

/// @title Inverse Guard
/// @author Nour Haridy
/// @notice Contract responsible for selling risk cover products
contract Guard {

    IDOLA public dola;
    IAREA public AREA; // Autonomous Repayment Enforcement Authority contract
    IPremiumModel public premiumModel;
    address public operator; // should be governance
    address public guardian; // can pause plan purchases
    mapping (uint => Plan) public plans; // plan ID -> Plan struct
    uint public plansLength;
    mapping (uint => Position) public positions; // position ID -> Position struct
    uint public positionsLength;
    mapping (address => uint[]) public userPositions; // user address -> array of Position IDs
    mapping(uint => mapping(uint => bool)) public incidentClaimedPerPosition; // incidentID => positionID => isClaimed
    mapping (uint => Incident) public incidents;
    uint public incidentsLength;

    struct Position {
        address purchaser;
        uint planID;
        uint startTimestamp;
        uint endTimestamp;
        uint amount;
        uint claimed;
        bool closed;
    }

    struct Incident {
        string title;
        uint planID;
        uint timestamp;
        uint claimFactor; // 0 is non-claimable (no incident). 1 ether is 100% claimable
    }

    struct Plan {
        string title;
        string conditions;
        address oracle;
        bool paused;
        uint ceiling;
        uint usage;
        uint minCovered; // minimum $ amount covered
        uint minDuration; // in seconds
        uint maxDuration;
    }

    constructor(IDOLA _dola, IAREA _AREA, address _operator, address _guardian, IPremiumModel _premiumModel) {
        dola = _dola;
        AREA = _AREA;
        operator = _operator;
        guardian = _guardian;
        premiumModel = _premiumModel;
        dola.approve(address(AREA), type(uint).max);
    }

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR IS AUTHORIZED");
        _;
    }

    function setPremiumModel(IPremiumModel _premiumModel) public onlyOperator {
        premiumModel = _premiumModel;
    }

    function createPlan(
        string calldata _title,
        string calldata _conditions,
        address _oracle,
        uint _ceiling,
        uint _minCovered,
        uint _minDuration,
        uint _maxDuration
    ) public onlyOperator {
        require(_oracle != address(0), "ORACLE CANNOT BE ADDRESS ZERO");
        require(_ceiling > 0, "CEILING CANNOT BE ZERO");
        plans[plansLength] = Plan({
            title:_title,
            conditions:_conditions,
            oracle:_oracle,
            paused:false,
            ceiling:_ceiling,
            usage:0,
            minCovered:_minCovered,
            minDuration:_minDuration,
            maxDuration:_maxDuration
        });
        emit CreatePlan(plansLength, _title, _conditions, _oracle, _ceiling, _minCovered, _minDuration, _maxDuration);
        plansLength++;
    }

    function pausePlan(uint _planID) public {
        require(msg.sender == guardian || msg.sender == operator, "ONLY GUARDIAN OR OPERATOR CAN PAUSE");
        plans[_planID].paused = true;
        emit PausePlan(_planID);
    }

    function unpausePlan(uint _planID) public {
        require(msg.sender == guardian || msg.sender == operator, "ONLY GUARDIAN OR OPERATOR CAN UNPAUSE");
        plans[_planID].paused = false;
        emit UnpausePlan(_planID);
    }

    function setPlan(
        uint _planID,
        string calldata _title,
        string calldata _conditions,
        uint _ceiling,
        uint _minCovered,
        uint _minDuration,
        uint _maxDuration
    ) public onlyOperator {
        require(_planID < plansLength, "PLAN DOES NOT EXIST");
        require(_ceiling > 0, "CEILING CANNOT BE ZERO");
        Plan memory plan = plans[_planID];
        plan.title = _title;
        plan.conditions = _conditions;
        plan.ceiling = _ceiling;
        plan.minCovered = _minCovered;
        plan.minDuration = _minDuration;
        plan.maxDuration = _maxDuration;
        plans[_planID] = plan;
        emit SetPlan(plansLength, _title, _conditions, _ceiling, _minCovered, _minDuration, _maxDuration);
    }

    function openPosition(uint _planID, uint _amount, uint _duration) public {
        require(_planID < plansLength, "PLAN DOES NOT EXIST");
        Plan memory plan = plans[_planID];
        require(plan.paused == false, "PLAN IS PAUSED");
        require(plan.usage + _amount <= plan.ceiling, "PLAN CEILING EXCEEDED");
        require(_amount > plan.minCovered, "AMOUNT COVERED TOO LOW");
        require(_duration > plan.minDuration, "DURATION TOO SHORT");
        require(_duration < plan.maxDuration, "DURATION TOO LONG");
        uint premium = premiumModel.getPremium(_planID, _amount, _duration, msg.sender);
        require(premium > 0, "PREMIUM CANNOT BE ZERO");
        dola.transferFrom(msg.sender, address(this), premium);
        AREA.receiveRevenue(premium);
        plans[_planID].usage += _amount;
        positions[positionsLength] = Position({
            purchaser:msg.sender,
            planID:_planID,
            startTimestamp:block.timestamp,
            endTimestamp:block.timestamp + _duration,
            amount:_amount,
            claimed:0,
            closed:false
        });
        userPositions[msg.sender].push(positionsLength);
        emit OpenPosition(msg.sender, _planID, _amount, _duration);
        positionsLength++;
    }

    function closePositions(uint[] calldata _positionIDs) public {
        for (uint i = 0; i < _positionIDs.length; i++) {
            Position storage position = positions[_positionIDs[i]];
            if(position.endTimestamp < block.timestamp && position.closed == false) {
                plans[position.planID].usage -= position.amount;
                position.closed = true;
                emit ClosePosition(position.planID);
            }
        }
    }

    function createIncident(string calldata _title, uint _planID, uint _timestamp, uint _claimFactor) public {
        require(msg.sender == plans[_planID].oracle, "ONLY PLAN ORACLE CAN SUBMIT INCIDENTS");
        require(_claimFactor > 0, "CLAIM FACTOR CANNOT BE ZERO");
        require(_claimFactor <= 1 ether, "CLAIM FACTOR CANNOT BE HIGHER THAN 100%");
        Incident memory incident = Incident({
            title:_title,
            planID:_planID,
            timestamp:_timestamp,
            claimFactor:_claimFactor
        });
        incidents[incidentsLength] = incident;
        emit CreateIncident(msg.sender, _planID, incidentsLength, _timestamp, _claimFactor);
        incidentsLength++;
    }

    function changeOracle(uint _planID, address _oracle) public {
        require(msg.sender == plans[_planID].oracle, "ONLY PLAN ORACLE CAN CHANGE ORACLE");
        require(_oracle != address(0), "ORACLE CANNOT BE ADDRESS ZERO");
        plans[_planID].oracle = _oracle;
        emit ChangeOracle(_planID, _oracle);
    }

    function claimIncident(uint _incidentID, uint _positionID) public {
        require(incidentClaimedPerPosition[_incidentID][_positionID] == false, "INCIDENT ALREADY CLAIMED");
        Position memory position = positions[_positionID];
        require(position.purchaser == msg.sender, "ONLY POSITION PURCHASER CAN CLAIM");
        Incident memory incident = incidents[_incidentID];
        require(incident.claimFactor > 0, "INCIDENT NOT CLAIMABLE");
        require(incident.timestamp > position.startTimestamp, "INCIDENT OCCURRED BEFORE POSITION PURCHASE");
        require(incident.timestamp < position.endTimestamp, "INCIDENT OCCURRED AFTER POSITION EXPIRY");
        uint remainder = position.amount - position.claimed;
        require(remainder > 0, "POSITION FULLY CLAIMED");
        uint compensation = position.amount * incident.claimFactor / 1 ether;
        if(compensation > remainder) compensation = remainder;
        AREA.borrow(msg.sender, compensation);
        positions[_positionID].claimed += compensation;
        incidentClaimedPerPosition[_incidentID][_positionID] = true;
        emit ClaimIncident(msg.sender, _incidentID, _positionID);
    }

    event CreatePlan(uint indexed _planID, string _title, string _description, address _oracle, uint _ceiling, uint _minCovered, uint _minDuration, uint _maxDuration);
    event SetPlan(uint indexed _planID, string _title, string _description, uint _ceiling, uint _minCovered, uint _minDuration, uint _maxDuration);
    event PausePlan(uint indexed _planID);
    event UnpausePlan(uint indexed _planID);
    event OpenPosition(address indexed user, uint indexed _planID, uint _amount, uint _duration);
    event ClosePosition(uint indexed _planID);
    event CreateIncident(address indexed user, uint indexed _planId, uint incidentID, uint _timestamp, uint _claimFactor);
    event ChangeOracle(uint indexed _planID, address _oracle);
    event ClaimIncident(address indexed user, uint indexed _incidentID, uint indexed _positionID);
}

