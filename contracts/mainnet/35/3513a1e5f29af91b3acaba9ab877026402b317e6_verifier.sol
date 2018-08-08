pragma solidity ^0.4.21;
contract owned {
    address public owner;
    event Log(string s);

    constructor()payable public {
        owner = msg.sender;
    }
    function fallback() public payable{
        revert();
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    function isOwner()public{
        if(msg.sender==owner)emit Log("Owner");
        else{
            emit Log("Not Owner");
        }
    }
}
contract verifier is owned{
    struct action {
        uint timestamp;
        uint256 value;
        address from;
    }
    mapping(string => mapping(uint => action))register;
    mapping(string => uint256)transactionCount;
    
    event actionLog(uint timestamp, uint256 value,address from);
    event Blog(string);
    
    constructor()public payable{
    }
    function registerTransaction(string neo,address ethA,uint256 value)internal{
        register[neo][transactionCount[neo]]=action(now,value,ethA);
        transactionCount[neo]+=1;
    }
    function verifyYourself(string neo, uint256 value)public payable{
        registerTransaction(neo,msg.sender,value);
    }
    function viewAll(string neo)public onlyOwner{
        uint i;
        for(i=0;i<transactionCount[neo];i++){
            emit actionLog(register[neo][i].timestamp,
                        register[neo][i].value,
                        register[neo][i].from);
        }
    }
    function viewSpecific(string neo, uint256 index)public onlyOwner{
        emit actionLog(register[neo][index].timestamp,
                        register[neo][index].value,
                        register[neo][index].from);
    }
}