/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity ^0.5.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract AuuInfo {
    using SafeMath for uint256;
    struct userinfo {
        address parent;
        //uint256 recommends;
        uint256 inversttime;
        //uint256[][100] childs; 
        uint256[] childs;
        uint256 id;
        uint256 inverst;
        uint256 accumulate_staticprofis;
        uint256 accumulate_dynamicprofis;
    }
    mapping(uint256=>address) internal _userid;
    mapping(address=>userinfo) internal _user;
    uint256[2] internal _limit ;
    uint256 [100] internal _dyrates;
    uint256 internal _max ;
    uint256 internal id;
    uint256 internal static_profit_rate;
    uint256 internal inverst_interval;
}

contract AuuTest is AuuInfo {
    
    constructor() public {

        _limit = [100 ether,10000 ether];
        _max = 100;
        for(uint256 i = 0;i<_max;i++){
            _dyrates[i] = i.add(1);
        }
        static_profit_rate = 50;
        // test inverst interval 
        inverst_interval = 2;
        id = 1;
    }
 
    function userstaticprofis() public view returns(uint256){
        address user = msg.sender;
        uint256 _interval;
        if(_user[user].inversttime >0){
            _interval = computeinterval(_user[user].inversttime,now);
        }
        return static_income(user,_interval);
    }
    
    function static_income(address user,uint256 _interval) private view returns(uint256 ){
        require(_interval>=0);
        uint256 profit = _user[user].inverst.mul(_interval).mul(static_profit_rate).div(1000);
        profit = profit.add(_user[user].accumulate_staticprofis);
        return profit>_user[user].inverst.mul(2)?_user[user].inverst.mul(2):profit;
    }
    function getinverstinterval() public view returns(uint256){
        return computeinterval(_user[msg.sender].inversttime,now);
    }
    
    function computeinterval(uint256 starttime,uint256 endtime) private view returns(uint256){
        require(endtime>=starttime);
        return endtime.sub(starttime).div(inverst_interval);
    }
    /*
    function userdynamicprofis() public view returns(uint256 _profit){
        _profit = dynamic_profits(msg.sender);
    }
    function dynamic_profits(address user) private view returns(uint256 _profit){
        
        if(_user[user].inversttime>0){
            _profit = _profit.add(_user[user].accumulate_dynamicprofis);
            if(_user[user].childs[0].length==0){
                return _profit;
            }
            for(uint256 i=0;i<_user[user].childs[0].length&&i<100;i++){
                for(uint256 n=0;n<_user[user].childs[i].length;n++){
                    address _child = _userid[_user[user].childs[i][n]];
                    if(_user[_child].inversttime==0){
                        continue;
                    }
                    uint256 _interval;
                    
                    if(_user[user].inversttime<=_user[_child].inversttime){
                        _interval = computeinterval(_user[_child].inversttime,now);
                    }else{
                        _interval = computeinterval(_user[user].inversttime,now);
                    }
                    //require(_interval>0,"interval must grater than 0");
                    _profit = _profit.add(static_income(_child,_interval).mul(_dyrates[i]).div(100));
                    //require(_profit>0,"profit must grater than 0");
                    if(_profit>_user[user].inverst.mul(3)){
                        return _user[user].inverst.mul(3);
                    }
                    
                }
            }
        }
    }
    */
    function userdynamicprofis2() public view returns(uint256 ){
        uint256 _profits = dynamic_profits2(msg.sender,msg.sender,0);
        //_profits = _profits.add(_user[msg.sender].accumulate_dynamicprofis);
        return _profits;
    }
    //迭代获取动态奖金  
    function dynamic_profits2(address _inituser,address user,uint256 _deep) public view returns(uint256 _profits){
        //uint256[] memory _childs = _user[user].childs[0];
        uint256[] memory _childs = _user[user].childs;
        
        //if(_childs.length>0 && _deep<_user[_inituser].childs[0].length && _deep<_max){
            if(_childs.length>0 && _deep<_user[_inituser].childs.length && _deep<_max){
            for(uint256 i=0;i<_childs.length;i++){
                address _child = _userid[_childs[i]];
                if(_user[_child].inversttime>0){
                    uint256 _interval = computeinterval(_user[_child].inversttime,now);
                    if(_user[_child].inversttime <= _user[_inituser].inversttime){
                        _interval = computeinterval(_user[_inituser].inversttime,now);
                    }
                    uint256 _staticprofis = static_income(_child,_interval).mul(_dyrates[_deep]).div(100);
                    _profits = _profits.add(_staticprofis);
                    if(_profits>=_user[_inituser].inverst.mul(3)){
                        _profits = _user[_inituser].inverst.mul(3);
                        break;
                    }
                }
                //if(_user[_child].childs[0].length>0){
                if(_user[_child].childs.length>0){
                    _profits = _profits.add(dynamic_profits2(_inituser,_child,_deep.add(1)));
                }
            }
        }
    }
    
    function getrate() public view returns(uint256[100] memory _rate){
        _rate =  _dyrates;
    }
    /*
    function testdynamic_income(uint256 i,uint256 n) public view returns(uint256 _l,address _u){
        _l = _user[msg.sender].childs[0].length;
        _u =  _userid[_user[msg.sender].childs[i][n]];
    }
    */
    
    function userinverst(uint256 _amount,address _from) public returns(bool){
        invert(msg.sender,_amount,_from);
    }
    function getuserinverst() public view returns(uint256 _inverst,
        address _parent,
        uint256 _inversttime,
        uint256 _id,
        uint256  _accumulate_dynamicprofis,
        uint256 _accumulate_staticprofis
        )
    {
        _inverst = _user[msg.sender].inverst;
        _parent = _user[msg.sender].parent;
        _inversttime = _user[msg.sender].inversttime;
        _id = _user[msg.sender].id;
        _accumulate_dynamicprofis = _user[msg.sender].accumulate_dynamicprofis;
        _accumulate_staticprofis = _user[msg.sender].accumulate_staticprofis;
        
    }
    function getchilds() public view returns(uint256[]  memory childs){
        //return _user[msg.sender].childs[dy];
        return _user[msg.sender].childs;
    }
    function getuseraddressbyid(uint256 _id) public view returns(address){
        return _userid[_id];
    }
    
    function invert(address user, uint256 _amount,address _from) private returns(bool){
        require(_user[user].inverst == 0,"user has inversted yet");
        require(_from != address(this) && _from != address(0));
        // require(_from != 0x0 &&_from != user && _from !=address(this) && _amount>=_limit[0] && _amount <=_limit[1]);
        // require(_user[user].inversttime == 0);
        address parent;
        if(_user[user].parent != address(0)){
            // require(_from == _user[user].parent);
            _from = _user[user].parent;
        }else{
            /*new user*/
            _user[user].id = id;
            _userid[id] = user;
            id = id.add(1);
            
            if(_from != user){
                require(_user[_from].id>0);
                _user[user].parent = _from;
                parent = _from;
                _user[parent].childs.push(_user[user].id);
                /*
                for(uint256 i=0;i<_max;i++){
                    _user[parent].childs[i].push(_user[user].id);
                    parent = _user[parent].parent;
                    if(parent == address(0)){
                        break;
                    }
                }
                */
            }
        }
        _user[user].inverst = _amount;
        _user[user].inversttime = now;
    }
    
    function updateparentdynamicprofis(address user) private returns(bool){
        
        address parent = _user[user].parent;
        uint256 _stprofis = static_income(user,computeinterval(_user[user].inversttime,now));
        for(uint256 i=0;i<_max;i++){
            if(parent == address(0)){
                break;
            }
            //if(_user[parent].inversttime==0 || _user[parent].childs[0].length <= i){
            if(_user[parent].inversttime==0 || _user[parent].childs.length <= i){
                parent = _user[parent].parent;
                continue;
            }
            if(_user[user].inversttime <= _user[parent].inversttime){
                uint256 _interval = computeinterval(_user[parent].inversttime,now);
                _user[parent].accumulate_dynamicprofis = _user[parent].accumulate_dynamicprofis.add(static_income(user,_interval).mul(_dyrates[i]).div(100));
            }else{
                 _user[parent].accumulate_dynamicprofis = _user[parent].accumulate_dynamicprofis.add(_stprofis.mul(_dyrates[i]).div(100));
            }
            parent = _user[parent].parent;
        }
    }
    function userreinverst() public returns(bool){
        reinverst(msg.sender);
    }
    function reinverst(address user) private returns(bool){
        require(_user[user].inverst>0,"user has no inverst");

        uint256 _dyprofis = dynamic_profits2(user,user,0);
        uint256 _stprofis = static_income(user,computeinterval(_user[user].inversttime,now));
        updateparentdynamicprofis(user);
        
        _user[user].inverst = _user[user].inverst.add(_dyprofis).add(_stprofis);
        _user[user].accumulate_dynamicprofis = 0;
        _user[user].accumulate_staticprofis = 0;
        _user[user].inversttime = now;
    }
    
    function useraddinverst(uint256 _amount) public returns(bool){
        addinverst(msg.sender,_amount);
    }
    
    function addinverst(address user,uint256 _amount) private returns(bool){
        require(_user[user].inverst >0 ,"user has no inverst yet");
        uint256 _staticprofis = static_income(user,computeinterval(_user[user].inversttime,now));
        _user[user].accumulate_staticprofis = _staticprofis;
        updateparentdynamicprofis(user);
        _user[user].inversttime = now;
        _user[user].inverst = _user[user].inverst.add(_amount);
    }
    
    function draw() public returns(bool){
        exitinverst(msg.sender);
    }
    
    function exitinverst(address user) private returns(bool){
        require(_user[user].inversttime >0,"user has not invesrt");
        updateparentdynamicprofis(user);
        _user[user].inversttime = 0;
        _user[user].inverst = 0;
        _user[user].accumulate_dynamicprofis = 0;
        _user[user].accumulate_staticprofis = 0;
    }

}