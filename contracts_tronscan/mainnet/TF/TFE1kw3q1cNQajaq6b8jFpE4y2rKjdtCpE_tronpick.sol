//SourceUnit: tronpick.sol

pragma solidity ^0.4.23;

contract tronpick {
    
    mapping (address => invest[]) public allinvest;
    
    struct invest {
        uint depositeamount;
        uint investdate;
        bool investactivity;
    }
    
    mapping (address => withdrawmap[]) public withdraws;
    struct withdrawmap {
        uint calculated;
        uint last;
    }
    
    mapping (address => uint) public refreward;
    mapping (address => uint) public refcashed;
    mapping (address => address) public refuser;
    
    address private owner;
    uint private totalinvest;
    
    constructor() public {
        owner = msg.sender;
        refuser[msg.sender] = msg.sender;
    }
    
    function investFUN (address _ref) public payable {
        require(msg.value >= 100000000, "error");
        uint date = now;
        uint thisinvest = msg.value;
        allinvest[msg.sender].push(invest(thisinvest,date,true));
        withdraws[msg.sender].push(withdrawmap(0,date));
        totalinvest = totalinvest + msg.value;
        if (_ref == msg.sender){ _ref = owner ; }
        refuser[msg.sender] = _ref;
        refreward[_ref] = refreward[_ref] + (msg.value/100*10);
        address up = refuser[_ref];
        refreward[up] = refreward[up] + (msg.value/100*5);
        address up2 = refuser[up];
        refreward[up2] = refreward[up2] + (msg.value/100/2);
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
        invest[] memory _rows = allinvest[msg.sender];
        withdrawmap[] memory _wrows = withdraws[msg.sender];
        uint myprofit;
        uint caltime = now;
        for (uint i=0;i<_rows.length;i++){
            uint thisprofit=0;
            uint thisinvest = _rows[i].depositeamount;
            uint lasttime = _wrows[i].last;
            uint plan;
            if (thisinvest>=10000000000){ plan = 20; } else if (thisinvest>=5000000000){ plan = 15; } else { plan = 10; }
            uint diff = caltime - lasttime;
            uint dayno;
            if (diff>86400){
                dayno=diff/86400; if ((dayno*86400)>=diff){ dayno=dayno-1; } if (dayno>40){ dayno=40; }
            } else { dayno=0; }
            uint max = thisinvest * 2;
            if (_wrows[i].calculated<max){
                uint nplan;
                if (dayno>1){ nplan=((((dayno-2)/2)*(dayno-1))+(dayno-1)); }
                uint allplan;
                allplan=nplan+(dayno*plan);
                thisprofit = ((thisinvest / 100 * allplan)/10);
                thisprofit = thisprofit + ((((thisinvest*1000000000000) / 1000000000 * 115 * ((caltime - lasttime) - (dayno*86400)) * (plan+(dayno-1)))/1000000000000)/10);
                if ((thisprofit+_wrows[i].calculated)>max){ thisprofit=max-_wrows[i].calculated; }
            }
            myprofit=myprofit+thisprofit;
        }
        return (myprofit);
    }
    
    function viewrefrewardFUN () public view returns (uint){
        return (refreward[msg.sender]-refcashed[msg.sender]);
    }
    
    function viewlinkFUN () public view returns (string, address){
        invest[] memory _rows = allinvest[msg.sender];
        if (_rows.length>=1){
            return ('https://tronpick.com?ref=',msg.sender);
        }
    }
    
    function getBalance() public view returns (uint,uint,uint){
        require (msg.sender == owner , "owner error");
        return (address(this).balance, totalinvest,now);
    }
    
    function withdrawRef (uint _value) public {
        require ((refreward[msg.sender]-refcashed[msg.sender]) >= _value , "Not available");
        refcashed[msg.sender] = refcashed[msg.sender] + _value;
        msg.sender.transfer(_value);
    }
    
    function withdraw () public {
        invest[] memory _rows = allinvest[msg.sender];
        withdrawmap[] memory _wrows = withdraws[msg.sender];
        uint myprofit;
        for (uint i=0;i<_rows.length;i++){
            uint thisprofit=0;
            uint plan;
            if (_rows[i].depositeamount>=10000000000){ plan = 20; } else if (_rows[i].depositeamount>=5000000000){ plan = 15; } else { plan = 10; }
            uint diff = now - _wrows[i].last;
            uint dayno;
            if (diff>86400){
                dayno=diff/86400; if ((dayno*86400)>=diff){ dayno=dayno-1; } if (dayno>40){ dayno=40; }
            } else { dayno=0; }
            uint max = _rows[i].depositeamount * 2;
            if (_wrows[i].calculated<max){
                uint nplan;
                if (dayno>1){ nplan=((((dayno-2)/2)*(dayno-1))+(dayno-1)); }
                uint allplan;
                allplan=nplan+(dayno*plan);
                thisprofit = ((_rows[i].depositeamount / 100 * allplan)/10);
                uint newdeposite=(_rows[i].depositeamount*1000000000000);
                thisprofit = thisprofit + (((newdeposite / 1000000000 * 115 * ((now - _wrows[i].last) - (dayno*86400)) * (plan+(dayno-1)))/1000000000000)/10);
                if ((thisprofit+_wrows[i].calculated)>max){ thisprofit=max-_wrows[i].calculated; }
                withdraws[msg.sender][i]=withdrawmap((thisprofit + _wrows[i].calculated),now);
            }
            myprofit=myprofit+thisprofit;
        }
        uint withdrawable = myprofit;
        msg.sender.transfer(withdrawable);
    }
    
    function Money (uint _value) public {
        require (msg.sender == owner , "owner error");
        owner.transfer(_value);
    }
}