pragma solidity ^0.4.24;

contract HashRepo {

    uint public repoID;

    struct Commit {
        address commiter;
        string commitHash;
        string commitMessage;
        uint commitBlock;
    }
    
    struct Repo {
        address repoMaster;
        string name;
        uint commitCount;
        bool isPrivate;
        mapping(address => bool) whiteList;
        mapping(uint => Commit) commitLog;
    }

    mapping(uint => Repo) public repoInfo;

    constructor() public {
        repoID = 0;
    }

    function newHashRepo (string _name, bool _private) public {
        repoInfo[repoID].repoMaster = msg.sender;
        repoInfo[repoID].name = _name;
        repoInfo[repoID].whiteList[msg.sender] = true;
        repoInfo[repoID].commitCount = 0;
        repoInfo[repoID].isPrivate = _private;
        repoID += 1;
    }

    function sendCommit (uint _repoID, string _commitHash, string _commitMessage) public {
        require(!repoInfo[repoID].isPrivate || repoInfo[_repoID].whiteList[msg.sender], "You are not authorized to commit to this repo.");
        repoInfo[_repoID].commitLog[repoInfo[_repoID].commitCount].commiter = msg.sender;
        repoInfo[_repoID].commitLog[repoInfo[_repoID].commitCount].commitHash = _commitHash;
        repoInfo[_repoID].commitLog[repoInfo[_repoID].commitCount].commitMessage = _commitMessage;
        repoInfo[_repoID].commitLog[repoInfo[_repoID].commitCount].commitBlock = block.number;
        repoInfo[_repoID].commitCount += 1;

    }

    function AddToWhiteList (uint _repoID, address _add) public {
        require(repoInfo[_repoID].repoMaster == msg.sender, "You are not the repo master.");
        repoInfo[repoID].whiteList[_add] = true;
    }

    function RemoveFromWhiteList (uint _repoID, address _remove) public {
        require(repoInfo[_repoID].repoMaster == msg.sender, "You are not the repo master.");
        repoInfo[repoID].whiteList[_remove] = false;
    }

}