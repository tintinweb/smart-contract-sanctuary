/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity 0.8.4;

contract Lottery
{
    /* structs */
    struct LotteryRegistry
    {
        address participant;
        uint256 amount;
    }
    
    /* Core Attributes */
    LotteryRegistry[] private _participants;
    uint256 private _comissions;
    uint256 private _totalPool;

    /* Ownership Attributes */
    address private _master;
    uint private _comissionPercentage;
    
    //constructor
    constructor(uint comissionPercentage_){
        _master = msg.sender;
        _comissionPercentage = comissionPercentage_;
    }
    
    /* AUX */
    function isParticipating(address participant_) private view returns(bool success){
        for(uint i = 0; i < _participants.length; i++){
            if(_participants[i].participant == participant_){
                return true;
            }
        }
        return false;
    }
    
    function random() private view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _comissions)));
    }
    
    /* Getters/Setter For Master */
    function getComissions() public view returns(uint256 comissions_){
        require(msg.sender == _master, "Unauthorized.");
        return  _comissions;
    }
    
    function getComissionPercentage() public view returns(uint comissionPercentage_){
        return _comissionPercentage;
    }
    
    function setComissionPercentage(uint comissionPercentage_) public{
        require(msg.sender == _master, "Unauthorized");
        _comissionPercentage = comissionPercentage_;
    }
    
    /* Getters/Setters For Public */
    function getTotalPool() public view returns(uint256 totalPool_){
        return _totalPool;
    }
    
    /* Lottery Methods */
    function joinLottery() public payable returns(bool success){
        require(isParticipating(msg.sender) == false, "Already participating");
        uint256 comission_ = (msg.value * _comissionPercentage) / 100;
        uint256 poolStake_ = msg.value - comission_;
        _comissions += comission_;
        _totalPool += poolStake_;
        _participants.push(LotteryRegistry(msg.sender, poolStake_));
        return true;
    }
    
    function executeLottery() public{
        require(msg.sender == _master, "Unauthorized");
        require(_participants.length > 0, "No Participants!");
        LotteryRegistry memory winner = _participants[random() % _participants.length];
        address payable transferTarget = payable( winner.participant);
        transferTarget.transfer(_totalPool);
        delete _participants;
        _totalPool = 0;
    }
    
    /* EVENTS */
    event Transfer(address indexed _from, address indexed _to, uint256 amount);
}