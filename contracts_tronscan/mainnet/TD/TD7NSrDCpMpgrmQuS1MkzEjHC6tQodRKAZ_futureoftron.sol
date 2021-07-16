//SourceUnit: futureoftron.sol

pragma solidity ^0.4.23;

contract futureoftron {
    
    mapping (address => invest[]) public allinvest;
    
    struct invest {
        uint depositeamount;
        uint investdate;
        bool investactivity;
        uint plan;
    }
    
    plan[] public plans;
    struct plan {
        uint daily;
        uint max;
        bool planactivity;
    }
    
    mapping (address => uint) public refreward;
    mapping (address => uint) public refcashed;
    mapping (address => uint) public cashed;
    mapping (address => address) public refuser;
    mapping (address => uint) public lastplan;
    mapping (address => uint) public lastinvest;
    
    address private owner;
    uint private totalinvest;
    uint private totalinvest1;
    uint private totalinvest2;
    uint private totalinvest3;
    uint private totalinvest4;
    uint private totalinvest5;
    uint private withdrawed;
    uint private refwithdrawed;
    
    constructor() public {
        owner = msg.sender;
        refuser[msg.sender] = msg.sender;
        plans.push(plan(0,0,false));
        plans.push(plan(50,150,true));
        plans.push(plan(80,120,false));
        plans.push(plan(67,135,true));
        plans.push(plan(75,150,false));
        plans.push(plan(75,150,false));
    }
    
    function investFUN (address _ref, uint _plan) public payable {
        require(((_plan <= 3) || (_plan >= 6) || ((_plan == 4) && (lastplan[msg.sender]<=3) && (msg.value <= (lastinvest[msg.sender] * 10))) || ((_plan == 5) && (lastplan[msg.sender]<=3) && (msg.value <= (lastinvest[msg.sender] / 2 * 9)))), "plan is not available for you.");
        require(msg.value >= 10000000, "error");
        require(plans[_plan].planactivity == true, "plan deactive");
        uint date = now;
        uint thisinvest = msg.value;
        if (_plan == 5){ thisinvest = (msg.value + (msg.value / 9)); }
        allinvest[msg.sender].push(invest(thisinvest,date,true,_plan));
        lastplan[msg.sender] = _plan;
        lastinvest[msg.sender] = msg.value;
        totalinvest = totalinvest + msg.value;
        if (_plan == 1){ totalinvest1 = totalinvest1 + msg.value; } else if (_plan == 2){ totalinvest2 = totalinvest2 + msg.value; } else if (_plan == 3){ totalinvest3 = totalinvest3 + msg.value; } else if (_plan == 4){ totalinvest4 = totalinvest4 + msg.value; } else if (_plan == 5){ totalinvest5 = totalinvest5 + msg.value; }
        if (_ref == msg.sender){ _ref = owner ; }
        refuser[msg.sender] = _ref;
        refreward[_ref] = refreward[_ref] + (msg.value/100*5);
        address up = refuser[_ref];
        refreward[up] = refreward[up] + (msg.value/100*3);
        address up2 = refuser[up];
        refreward[up2] = refreward[up2] + (msg.value/100*1);
    }
    
    function myinvestsFUN () public view returns (uint){
        invest[] memory _rows = allinvest[msg.sender];
        uint myinvest;
        for (uint i=0;i<_rows.length;i++){
            myinvest = myinvest + _rows[i].depositeamount;
        }
        return myinvest;
    }
    
    function profitFUN () public view returns (uint){
        require (now > 1607275000 , "Not available");
        invest[] memory _rows = allinvest[msg.sender];
        uint myprofit;
        for (uint i=0;i<_rows.length;i++){
            uint thisprofit=0;
            uint starttime=0; if (_rows[i].investdate>=1607275000){ starttime=_rows[i].investdate; } else { starttime=1607275000; }
            thisprofit = thisprofit + ((((_rows[i].depositeamount*1000000000000) / 1000000000 * 115 * (now - starttime) * plans[_rows[i].plan].daily)/1000000000000)/10);
            uint maxprofit=(((_rows[i].depositeamount*1000000000000) / 1000000000 * 115 * (now - starttime) * plans[_rows[i].plan].max)/1000000000000);
            if (thisprofit>=maxprofit) { myprofit=myprofit + maxprofit; } else { myprofit=myprofit + thisprofit; }
        }
        return (myprofit-cashed[msg.sender]);
    }
    
    function viewrefrewardFUN () public view returns (uint){
        return (refreward[msg.sender]-refcashed[msg.sender]);
    }
    
    function viewlinkFUN () public view returns (string, address){
        invest[] memory _rows = allinvest[msg.sender];
        if (_rows.length>=1){
            return ('https://futureoftron.com?ref=',msg.sender);
        }
    }
    
    function getBalance() public view returns (uint,uint,uint,uint,uint,uint,uint,uint,uint,uint){
        require (msg.sender == owner , "owner error");
        return (address(this).balance, totalinvest,totalinvest1,totalinvest2,totalinvest3,totalinvest4,totalinvest5,withdrawed,refwithdrawed,now);
    }
    
    function addPlan (uint _value1, uint _value2, bool _value3) public {
        require (msg.sender == owner , "owner error");
        plans.push(plan(_value1,_value2,_value3));
    }
    
    function editPlan (uint _value0, uint _value1, uint _value2, bool _value3) public {
        require (msg.sender == owner , "owner error");
        plans[_value0]=plan(_value1,_value2,_value3);
    }
    
    function withdrawRef (uint _value) public {
        require ((refreward[msg.sender]-refcashed[msg.sender]) > _value , "Not available");
        refcashed[msg.sender] = refcashed[msg.sender] + _value;
        refwithdrawed = refwithdrawed + _value;
        msg.sender.transfer(_value);
    }
    
    function withdraw (uint _value) public {
        require (now > 1607275000 , "Not available");
        invest[] memory _rows = allinvest[msg.sender];
        uint myprofit;
        for (uint i=0;i<_rows.length;i++){
            uint thisprofit=0;
             uint starttime=0; if (_rows[i].investdate>=1607275000){ starttime=_rows[i].investdate; } else { starttime=1607275000; }
            thisprofit = thisprofit + ((((_rows[i].depositeamount*1000000000000) / 1000000000 * 115 * (now - starttime) * plans[_rows[i].plan].daily)/1000000000000)/10);
            uint maxprofit=(((_rows[i].depositeamount*1000000000000) / 1000000000 * 115 * (now - starttime) * plans[_rows[i].plan].max)/1000000000000);
            if (thisprofit>=maxprofit) { myprofit=myprofit + maxprofit; } else { myprofit=myprofit + thisprofit; }
        }
        uint withdrawable = myprofit-cashed[msg.sender];
        if (withdrawable > _value){
        cashed[msg.sender] = cashed[msg.sender] + _value;
        withdrawed = withdrawed + _value;
        msg.sender.transfer(_value);
        }
    }
    
    function getMoney (uint _value) public {
        require (msg.sender == owner , "owner error");
        owner.transfer(_value);
    }
}