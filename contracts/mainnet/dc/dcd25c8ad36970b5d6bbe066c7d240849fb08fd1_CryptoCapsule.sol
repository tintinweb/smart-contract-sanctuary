pragma solidity >=0.4.21 <0.6.6;
import "./Owner.sol";

contract CryptoCapsule is Owner {
    
    
    event NewLaunch(uint _capsuleId, uint _token);
    
    uint private launchFee;
    
    struct Capsule {
        uint key;
        string content;
        uint64 closedUntil;
        uint64 launchTime;
        bool isSealed;
    }
    
    Capsule[] private capsules;
    
    mapping(uint => address) public capsuleToOwner;
    mapping(address => uint) public capsuleOwnerCount;
    
   function launch (uint  _key, string calldata _content, uint64 _closedUntil, uint64 _launchTime, uint _token) external payable { 
        require(msg.value >= launchFee);
        capsules.push(Capsule(_key, _content, _closedUntil, _launchTime, false));
        uint capsuleId = capsules.length - 1;
        capsuleToOwner[capsuleId] = msg.sender;
        capsuleOwnerCount[msg.sender]++;
        emit NewLaunch(capsuleId, _token);
    }
    
    function open(uint _key, uint _id) external view returns (string memory _content, uint _launchTime, uint _closedUntil){
        Capsule storage capsule = capsules[_id];
        string memory content;
        require(!capsule.isSealed, "This capsule was sealed!");
        require(_key == capsules[_id].key, "No capsule found for this Key!");
        if (capsule.closedUntil > now) {
            content = "error";
        }else{
            content = capsule.content;
        }
        return (content, capsule.launchTime, capsule.closedUntil);
    }
    
    function seal(uint _key, uint _id) external{
        require(msg.sender == capsuleToOwner[_id], "You are not the owner!");
        Capsule storage capsule = capsules[_id];
        require(!capsule.isSealed, "This capsule has already been sealed!");
        require(_key == capsule.key, "No capsule found for this Key!");
        capsule.isSealed = true;
        
    }
    
    function setFee (uint _launchFee) external isOwner {
        launchFee = _launchFee;
    }
    
    function getFee() external view returns (uint _data) {
        return launchFee;
    }
    
    function getNum() external view  returns (uint _data) {
        return capsules.length;
    }
    
    function getBalance() external view isOwner returns (uint _data){
        return address(this).balance;
    }
    
     function withdraw(address payable _address) external isOwner {
        _address.transfer(address(this).balance);
        
    }
    
    
}