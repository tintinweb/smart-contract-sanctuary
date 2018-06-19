pragma solidity ^0.4.11;


contract Announcement {

    struct Message {
        string ipfsHash;
        uint256 timestamp;
    }

    struct MessageAwaitingAudit {
        uint256 nAudits;
        uint256 nAlarms;
        Message msg;
        mapping (address => bool) auditedBy;
        mapping (address => bool) alarmedBy;
    }

    address public owner;
    mapping(address => bool) public auditors;
    address[] public auditorsList;
    uint256 public nAuditors;
    uint256 public nAuditorsRequired = 1;
    uint256 public nAuditorsAlarm = 1;
    uint256 public nAlarms = 0;
    uint256[] public alarms;
    mapping(uint256 => bool) public alarmRaised;

    uint256 public nMsg = 0;
    mapping(uint256 => Message) public msgMap;

    uint256 public nMsgsWaiting = 0;
    mapping(uint256 => MessageAwaitingAudit) msgsWaiting;
    mapping(uint256 => bool) public msgsWaitingDone;


    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAuditor() {
        require(auditors[msg.sender] == true);
        _;
    }


    function Announcement(address[] _auditors, uint256 _nAuditorsRequired, uint256 _nAuditorsAlarm) {
        require(_nAuditorsRequired >= 1);
        require(_nAuditorsAlarm >= 1);

        for (uint256 i = 0; i < _auditors.length; i++) {
            auditors[_auditors[i]] = true;
            auditorsList.push(_auditors[i]);
        }
        nAuditors = _auditors.length;

        owner = msg.sender;
        nAuditorsRequired = _nAuditorsRequired;
        nAuditorsAlarm = _nAuditorsAlarm;
    }

    function addAnn (string ipfsHash) isOwner external {
        require(bytes(ipfsHash).length > 0);
        msgQPut(ipfsHash);
    }

    function msgQPut (string ipfsHash) private {
        createNewMsgAwaitingAudit(ipfsHash, block.timestamp);
    }

    function addAudit (uint256 msgWaitingN, bool msgGood) isAuditor external {
        // ensure the msgWaiting is not done, and that this auditor has not submitted an audit previously
        require(msgsWaitingDone[msgWaitingN] == false);
        MessageAwaitingAudit msgWaiting = msgsWaiting[msgWaitingN];
        require(msgWaiting.auditedBy[msg.sender] == false);
        require(msgWaiting.alarmedBy[msg.sender] == false);
        require(alarmRaised[msgWaitingN] == false);

        // check if the auditor is giving a thumbs up or a thumbs down and adjust things appropriately
        if (msgGood == true) {
            msgWaiting.nAudits += 1;
            msgWaiting.auditedBy[msg.sender] = true;
        } else {
            msgWaiting.nAlarms += 1;
            msgWaiting.alarmedBy[msg.sender] = true;
        }

        // have we reached the right number of auditors and not triggered an alarm?
        if (msgWaiting.nAudits >= nAuditorsRequired && msgWaiting.nAlarms < nAuditorsAlarm) {
            // then remove msg from queue and add to messages
            addMsgFinal(msgWaiting.msg, msgWaitingN);
        } else if (msgWaiting.nAlarms >= nAuditorsAlarm) {
            msgsWaitingDone[msgWaitingN] = true;
            alarmRaised[msgWaitingN] = true;
            alarms.push(msgWaitingN);
            nAlarms += 1;
        }
    }

    function createNewMsgAwaitingAudit(string ipfsHash, uint256 timestamp) private {
        msgsWaiting[nMsgsWaiting] = MessageAwaitingAudit(0, 0, Message(ipfsHash, timestamp));
        nMsgsWaiting += 1;
    }

    function addMsgFinal(Message msg, uint256 msgWaitingN) private {
        // ensure we store the message first
        msgMap[nMsg] = msg;
        nMsg += 1;

        // finally note that this has been processed and clean up
        msgsWaitingDone[msgWaitingN] = true;
        delete msgsWaiting[msgWaitingN];
    }

    function getMsgWaiting(uint256 msgWaitingN) constant external returns (uint256, uint256, string, uint256, bool) {
        MessageAwaitingAudit maa = msgsWaiting[msgWaitingN];
        return (
            maa.nAudits,
            maa.nAlarms,
            maa.msg.ipfsHash,
            maa.msg.timestamp,
            alarmRaised[msgWaitingN]
        );
    }
}