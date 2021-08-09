/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract VERSIONtest1  {
    string public constant name = "VER1Token";//币全称
    string public constant symbol = "VER1";//币简称
    uint public constant decimals = 18;//小数位
    uint256 public _totalSupply = 180000 * 10**decimals;//发行量
    mapping(address => uint256) balances;         //地址余额
    mapping(address => uint256) balancesdj;     //地址余额冻结
    mapping(address => uint256) fraction;       //性能分
    struct node{
        string ip;//信任节点IP
        bool status;//信任节点状态
        bool ishave;//信任节点是否被设定
    }
    mapping(address => node) trustnode;     //信任节点映射
    address[] trustnodes;//信任节点集合
    mapping(address => mapping (address => uint256)) allowed;
    uint public baseStartTime; //基准时间
    address public founder = 0x0;//默认拥有者
    uint256 public distributed = 0;//发行量
    uint r = 447213595499957900;//定义计算质押数的常量
    uint k = 998403042759557400;//计算每日分币的常量
    uint dailyoutputnumber = 288;//设定每天的释放次数
    uint dailyoutputtime = 0;//上次分币的时间
    address dailyoutputaddress = 0x00;//上次分币的信任节点
    address[] lsaddress;//当前参与分币的数组

    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //定义合约拥有者(构造函数)
    function VERSIONtest1(){
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    //查询某个地址余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    //查询某个地址总分币量
    function balancesdjd(address _owner) public view returns (uint256) {
        return balancesdj[_owner];
    }
    //查询某个地址性能分
    function fractiond(address _owner) public view returns (uint256) {
        return fraction[_owner];
    }
    
    //查询参与空投的地址
    function lsaddressd() public view returns (address[]) {
        return lsaddress;
    }
    
    
    //查询上次分币时间
    function dailyoutputtimed() public view returns (uint256) {
        return dailyoutputtime;
    }
    //合约拥有者修改基准点时间
    function setStartTime(uint _startTime) public returns(bool success){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }
    //修改合约的拥有者
    function modifyOwnerFounder(address newFounder) public returns(address founders){
        require(msg.sender == founder);
        founder = newFounder;
        return founder;
    }

    //分发代币（只有拥有者可以操作）检查发行量是否已经超出.
    function distribute(uint256 _amount, address _to) public returns (bool success){
        require(msg.sender == founder);
        require(distributed + _amount >= distributed);
        require(distributed + _amount <= _totalSupply);
        distributed += _amount;
        balances[_to] += _amount;
        emit Transfer(0x000000000000,msg.sender, _amount);
        return true;
    }
    //设置信任节点
    function settrustnode(address _address, string _ip) public returns (bool success){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            trustnode[_address].ip = _ip;
            trustnode[_address].status = true;
        }else{
            trustnode[_address].ip = _ip;
            trustnode[_address].status = true;
            trustnode[_address].ishave = true;
            trustnodes.push(_address);
        }
        return true;
    }
    //删除信任节点
    function deltrustnode(address _address) public returns(bool success){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            if(trustnode[_address].status){
                trustnode[_address].status = false;
            }
        }
        return true;
    }
    //查看信任节点列表
    function seetrustnode() public view returns(address[] nodeaddress){
        require(msg.sender == founder);
        return trustnodes;
    }
    //查看信任节点详情
    function seetrustnodedetails(address _address) public view returns(string ip,bool status){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            return (trustnode[_address].ip,trustnode[_address].status);
        }else{
            return (trustnode[_address].ip,false);
        }

    }
    uint whoday = 1;//当前第几天
    uint daynumber = 0;//今天的释放数量
    //计算每天的发行量
    function dailyoutput() public returns(uint){
        if(now > baseStartTime && whoday <=7 ){
            uint dayss = ((now - baseStartTime)/86400)+1;
            if(dayss == whoday){
                whoday += 1;
                daynumber += _totalSupply/7;
            }
            return daynumber;
        }
    }
    //查看每天的发行次数
    function seedailyoutputnumber() public view returns(uint putnumber){
        require(msg.sender == founder);
        return dailyoutputnumber;
    }
    //修改每天的发行次数
    function setdailyoutputnumber(uint _number) public returns(bool success){
        require(msg.sender == founder);
        dailyoutputnumber = _number;
        return true;
    }
    //["0xa2aD3a5feA8A41364dc542EDdAee2D5183AEF824","0x738b8AEE644442ADb8D754476E79889Fd92c625A","0x23d399c290E992aC4D40925d2D86553d7DCBBb38"]
    //每次分币
    function todailyoutput(address[] nodeaddress,uint[] nodefraction,string _ips) public returns(bool success){
        //判断是不是信任节点
        if(trustnode[msg.sender].ishave && trustnode[msg.sender].status && keccak256(trustnode[msg.sender].ip) == keccak256(_ips)){
            if(dailyoutputaddress == msg.sender){
                return false;
            }
            if(nodeaddress.length < 2 && nodeaddress.length != nodefraction.length){
                return false;
            }
            //计算每天的分币时间间隔
            uint jg = 86400/dailyoutputnumber;//计算当前释放间隔
            if(now - dailyoutputtime > jg){
                dailyoutputtime = now;//更新本次释放时间
                dailyoutputaddress = msg.sender;//记录本次的信任节点
                uint znumber = dailyoutput() / dailyoutputnumber;//计算本次释放的数量
                uint zzy = 0;//本次总性能分数量
                for(uint i = 0; i < nodeaddress.length; i++){
                    zzy += nodefraction[i];
                }
                for(uint ii = 0; ii < nodeaddress.length; ii++){
                    uint thisamount = (nodefraction[ii]*znumber) / zzy;
                    distributed += thisamount;
                    require(distributed + thisamount <= _totalSupply);
                    balances[nodeaddress[ii]] += thisamount;
                    balancesdj[nodeaddress[ii]] += thisamount;
                    if(fraction[nodeaddress[ii]] == 0){
                        lsaddress.push(nodeaddress[ii]);
                    }
                    fraction[nodeaddress[ii]] = nodefraction[ii];
                    emit Transfer(0x333333333333,nodeaddress[ii], thisamount);
                }
                return true;
            }else{
                return false;
            }
            return true;
        }else{
            return false;
        }
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_to != msg.sender);
        require(now > baseStartTime);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    function() payable public{
        if (!founder.call.value(msg.value)()) revert();
    }
    //删除合约 
    function killContract() public returns(bool){
        require(msg.sender == founder);
        selfdestruct(founder);
        return true;
    }
}


contract VERSION1  {
    string public constant name = "VERSION1 Token";//币全称
    string public constant symbol = "VERSION1";//币简称
    uint256 public constant decimals = 18;//小数位
    uint256 public _totalSupply = 62500000 * 10**decimals;//发行量
    uint256 public pledgeamountall; //总质押数量
    uint256 public technical = 0;//技术团队锁仓
    uint256 public baseStartTime; //基准时间
    address public founder = 0x0;//默认拥有者
    uint256 public distributed = 0;//发行量
    uint256 r = 447213595499957900;//定义计算质押数的常量
    uint256 k = 998403042759557400;//计算每日分币的常量
    uint256 dailyoutputnumber = 288;//设定每天的释放次数
    uint256 dailyoutputtime = 0;//上次分币的时间
    address dailyoutputaddress = 0x00;//上次分币的信任节点
    uint256 pledgehours = 0;//需要质押的小时数默认0
    address[] lsaddress;//当前参与分币的数组
    address[] nownodesnumber;//历史有效节点数组
    uint256 technicalupnum = 0;//技术团队当前解锁数量
    uint256 technicaluptime = 0;//技术团队上次解锁时间
    struct node{
        string ip;//信任节点IP
        bool status;//信任节点状态
        bool ishave;//信任节点是否被设定
    }
    address[] trustnodes;//信任节点集合
    address technicaladdress = 0x00;//技术团队收币地址
    mapping(address => uint256) Receiveairdrop;     //已经领取过空投的地址
    mapping(address => uint256) balances;         //地址余额
    mapping(address => uint256) pledgeamount;     //质押数量
    mapping(address => uint256) pledgetime;       //达到质押标准的质押时间
    mapping(address => uint256) fraction;       //性能分
    mapping(address => uint256) pledgeamountfreeze;     //质押冻结
    mapping(address => uint256) pledgeamountfreezetime;     //质押冻结时间
    mapping(address => uint256) balanceslockup;         //分币锁仓
    mapping(address => uint256) balanceslockupbase;     //分币锁仓基数
    mapping(address => uint256) lockuptime;     //上次领取分币锁仓时间
    mapping(address => node) trustnode;     //信任节点映射
    mapping(address => bool) nownodesnumberbool;     //历史有效节点映射
    mapping(address => mapping (address => uint256)) allowed;
    

    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    //定义合约拥有者(构造函数)
    function VERSION1(){
        founder = msg.sender;
        baseStartTime = block.timestamp;
        technical = _totalSupply*5/100;
        distributed += technical;
    }
    
    
    //领取空投
    //0xd7A4FB646bc07A0Bccf89eb0bB8deEc6b5FaDD4C;
    function Inquire(VERSIONtest1 accessget) public returns(uint){
        require(msg.sender == founder);
        address[] memory abc =  accessget.lsaddressd();
        for(uint i = 0; i < abc.length; i++){
            if(Receiveairdrop[abc[i]] == 0){
                uint amount = accessget.balancesdjd(abc[i]);
                uint fractiontest = accessget.fractiond(abc[i]);
                pledgeamount[abc[i]] += amount;
                fraction[abc[i]] += fractiontest;
                pledgeamountall += amount;
                distributed += amount;
                uint _pledgeamoun = calculatePledgeAmount(fractiontest);
                if(pledgeamount[abc[i]] >= _pledgeamoun && pledgetime[abc[i]] == 0 && pledgeamount[abc[i]] >= 5){
                    pledgetime[abc[i]] = now;
                    if(nownodesnumberbool[abc[i]] == false){
                        nownodesnumberbool[abc[i]] = true;
                        nownodesnumber.push(abc[i]);
                        Technicaldividend();
                    }

                }
                Receiveairdrop[abc[i]] = amount;
            }
        }
       
    }

    //查询某个地址余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    //查询某地址的质押数量
    function numberOfAddressPledges(address user) public view returns (uint256 amount) {
        amount = pledgeamount[user];
        return amount;
    }
    //查询某地址达到质押标准的时间
    function numberOfAddressPledgestime(address user) public view returns (uint256 pledgestime) {
        return pledgetime[user];
    }
    
    //查询某地址质押冻结中的币数
    function pledgeamountfreezed(address user) public view returns (uint256 amount) {
        return pledgeamountfreeze[user];
    }

    //查询某地址申请解压的时间
    function pledgeamountfreezetimed(address user) public view returns (uint256 freezetime) {
        return pledgeamountfreezetime[user];
    }
    
    //查询上次分币时间
    function dailyoutputtimed() public view returns (uint256) {
        return dailyoutputtime;
    }
    
    //查询需要质押的小时数
    function pledgehoursd() public view returns (uint256 hourss) {
        require(msg.sender == founder);
        return pledgehours;
    }
    
    //修改需要质押的小时数
    function setpledgehoursd(uint _pledgehours) public returns(bool success){
        require(msg.sender == founder);
        pledgehours = _pledgehours;
        return true;
    }
    
    //合约拥有者修改基准点时间
    function setStartTime(uint _startTime) public returns(bool success){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }
    
    //修改合约的拥有者
    function modifyOwnerFounder(address newFounder) public returns(address founders){
        require(msg.sender == founder);
        founder = newFounder;
        return founder;
    }

    //进行质押
    function pledge(uint256 _value,uint _fraction) public returns (bool success) {
        //查询是否有解压冻结的币
        if(pledgeamountfreeze[msg.sender] > 0){
            return false;
        }
        //查询地址可用余额
        if (balances[msg.sender] >= _value){
            balances[msg.sender] -= _value;
            pledgeamount[msg.sender] += _value;
            fraction[msg.sender] += _fraction;
            pledgeamountall += _value;
            emit Transfer(msg.sender,0x1111111111, _value);
            uint _pledgeamoun = calculatePledgeAmount(_fraction);
            if(pledgeamount[msg.sender] >= _pledgeamoun && pledgetime[msg.sender] == 0 && pledgeamount[msg.sender] >= 5){
                pledgetime[msg.sender] = now;
                if(nownodesnumberbool[msg.sender] == false){
                    nownodesnumberbool[msg.sender] = true;
                    nownodesnumber.push(msg.sender);
                    Technicaldividend();
                }
            }
            return true;
        }else{
            return false;
        }
    }
    
    //进行解押
    function pledgeOut() public returns (bool success) {
        //查询是否有质押币
        if(pledgeamount[msg.sender] > 0){
            pledgeamountfreeze[msg.sender] += pledgeamount[msg.sender];
            pledgeamount[msg.sender] -= pledgeamount[msg.sender];
            pledgetime[msg.sender] = 0;
            pledgeamountfreezetime[msg.sender] = now;
            // nownodesnumber -= 1;
            pledgeamountall -= pledgeamount[msg.sender];
            return true;
        }else{
            return false;
        }
    }
    
    //解押领取
    function pledgeOutReceive() public returns (bool success) {
        //查询是否有质押冻结币
        if(pledgeamountfreeze[msg.sender] > 0){
            uint a = pledgeamountfreezetime[msg.sender] - now;
            //七天以后才可以领取解压
            if(a > 604800){
                pledgeamountfreeze[msg.sender] -= pledgeamountfreeze[msg.sender];
                pledgeamountfreezetime[msg.sender] = 0;
                balances[msg.sender] += pledgeamountfreeze[msg.sender];
                emit Transfer(0x222222222222,msg.sender, pledgeamountfreeze[msg.sender]);
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }
    //根据性能分数计算质押数量
    function calculatePledgeAmount(uint _fraction) internal view returns (uint256){
        //取平方根（向下取整）
        uint z = (_fraction + 1 ) / 2;
        uint y = _fraction;
        while(z < y){
          y = z;
          z = ( _fraction / z + z ) / 2;
        }
        uint a1 = r * y;
        uint a2 = r * y / (10**decimals);
        uint a3 = a2 * (10**decimals);
        if(a1 - a3 > 10**decimals){
            return  (a2+1)* (10**decimals);
        }else{
            return  a2 * (10**decimals);
        }
    }

    //分发代币（只有拥有者可以操作）检查发行量是否已经超出.
    function distribute(uint256 _amount, address _to) public returns (bool success){
        require(msg.sender == founder);
        require(distributed + _amount >= distributed);
        require(distributed + _amount <= _totalSupply);
        distributed += _amount;
        balances[_to] += _amount;
        emit Transfer(0x000000000000,msg.sender, _amount);
        return true;
    }
    
    //设置信任节点
    function settrustnode(address _address, string _ip) public returns (bool success){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            trustnode[_address].ip = _ip;
            trustnode[_address].status = true;
        }else{
            trustnode[_address].ip = _ip;
            trustnode[_address].status = true;
            trustnode[_address].ishave = true;
            trustnodes.push(_address);
        }
        return true;
    }
    
    //删除信任节点
    function deltrustnode(address _address) public returns(bool success){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            if(trustnode[_address].status){
                trustnode[_address].status = false;
            }
        }
        return true;
    }
    
    //查看信任节点列表
    function seetrustnode() public view returns(address[] nodeaddress){
        require(msg.sender == founder);
        return trustnodes;
    }
    
    //查看信任节点详情
    function seetrustnodedetails(address _address) public view returns(string ip,bool status){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            return (trustnode[_address].ip,trustnode[_address].status);
        }else{
            return (trustnode[_address].ip,false);
        }

    }
    
    //计算每天的发行量
    function dailyoutput() public view returns(uint){
        if(now > baseStartTime){
            uint dayss = ((now - baseStartTime)/86400)+1;
            uint sy = _totalSupply;
            uint js = (10**decimals) - k;
            uint zl = sy*js;
            uint r0 = zl / (10**decimals);
            uint amo = r0*(k**dayss)/((10**(decimals))**dayss);
            return amo;
        }
    }

    //查看每天的发行次数
    function seedailyoutputnumber() public view returns(uint putnumber){
        require(msg.sender == founder);
        return dailyoutputnumber;
    }
    
    //修改每天的发行次数
    function setdailyoutputnumber(uint _number) public returns(bool success){
        require(msg.sender == founder);
        dailyoutputnumber = _number;
        return true;
    }
    
    //   ["0xa2aD3a5feA8A41364dc542EDdAee2D5183AEF824","0x738b8AEE644442ADb8D754476E79889Fd92c625A","0x23d399c290E992aC4D40925d2D86553d7DCBBb38"]
    //每次分币
    function todailyoutput(address[] nodeaddress,uint[] nodefraction,string _ips) public returns(bool success){
        //判断是不是信任节点
        if(trustnode[msg.sender].ishave && trustnode[msg.sender].status && keccak256(trustnode[msg.sender].ip) == keccak256(_ips)){
            if(dailyoutputaddress == msg.sender){
                return false;
            }
            //计算每天的分币时间间隔
            uint jg = 86400/dailyoutputnumber;//计算当前释放间隔
            if(now - dailyoutputtime > jg){
                dailyoutputtime = now;//更新本次释放时间
                dailyoutputaddress = msg.sender;//记录本次的信任节点
                uint znumber = dailyoutput() / dailyoutputnumber;//计算本次释放的数量
                uint zzy = 0;//本次总质押数量
                lsaddress.length = 0 ;//清空参与结算的地址集合
                for(uint i = 0; i < nodeaddress.length; i++){
                    if(now - pledgetime[nodeaddress[i]] > (pledgehours*3600) && fraction[nodeaddress[i]] == nodefraction[i]){
                        zzy += pledgeamount[nodeaddress[i]];
                        lsaddress.push(nodeaddress[i]);
                    }
                }
                for(uint ii = 0; ii < lsaddress.length; ii++){
                    uint thisamount = (pledgeamount[lsaddress[ii]]*znumber) / zzy;
                    distributed += thisamount;
                    balances[lsaddress[ii]] += thisamount/2;
                    emit Transfer(0x333333333333,lsaddress[ii], thisamount/2);
                    balanceslockup[lsaddress[ii]] += thisamount/2;
                    balanceslockupbase[lsaddress[ii]] += thisamount/2;
                }
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }
    
    //用户领取分币锁仓
    function userunlock() public returns(bool){
        if(balanceslockup[msg.sender] > 0){
            uint dayss = (now - baseStartTime)/86400;
            if(dayss > 0){
                uint amount = balanceslockupbase[msg.sender]/200*dayss;
                if(amount > balanceslockup[msg.sender]){
                    amount = balanceslockup[msg.sender];
                }
                balanceslockup[msg.sender] -=amount;
                balances[msg.sender] +=amount;
                emit Transfer(0x444444444444,msg.sender, amount);
                lockuptime[msg.sender] = now;
                return true;
            }
        }
        return false;
    }
    
    //交易
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_to != msg.sender);
        require(now > baseStartTime);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    

    function Technicaldividend() internal returns(bool){
        return true;
        //technicaladdress 技术团队地址   
        //technical 技术团队锁仓数量   
        //nownodesnumber 历史有效节点数组
        //technicalupnum  技术团队当前解锁数量  
        //technicaluptime 技术团队上次解锁时间
        uint amount = 31250 * (10**decimals);
        if(technical < amount && technical > 0){
            amount = technical;
        }
        if(technicalupnum == 0 && nownodesnumber.length >= 5000 && now-technicaluptime >= 2592000){
            technicalupnum = 5000;
            technicaluptime = now;
        }else if(technicalupnum == 5000 && nownodesnumber.length >= 10000 && now-technicaluptime >= 2592000){
            technicalupnum = 10000;
            technicaluptime = now;
        }else if(technicalupnum == 10000 && nownodesnumber.length >= 15000 && now-technicaluptime >= 2592000){
            technicalupnum = 15000;
            technicaluptime = now;
        }else if(technicalupnum == 15000 && nownodesnumber.length >= 20000 && now-technicaluptime >= 2592000){
            technicalupnum = 20000;
            technicaluptime = now;
        }else if(technicalupnum == 20000 && nownodesnumber.length >= 25000 && now-technicaluptime >= 2592000){
            technicalupnum = 25000;
            technicaluptime = now;
        }else if(technicalupnum == 25000 && nownodesnumber.length >= 35000 && now-technicaluptime >= 2592000){
            technicalupnum = 35000;
            technicaluptime = now;
        }else if(technicalupnum == 35000 && nownodesnumber.length >= 40000 && now-technicaluptime >= 2592000){
            technicalupnum = 40000;
            technicaluptime = now;
        }else if(technicalupnum == 40000 && nownodesnumber.length >= 45000 && now-technicaluptime >= 2592000){
            technicalupnum = 45000;
            technicaluptime = now;
        }else if(technicalupnum == 45000 && nownodesnumber.length >= 50000 && now-technicaluptime >= 2592000){
            technicalupnum = 50000;
            technicaluptime = now;
        }else if(technicalupnum == 50000 && nownodesnumber.length >= 55000 && now-baseStartTime >= 31536000){
            technicalupnum = 55000;
            technicaluptime = now;
        }else{
            return false;
        }
        balances[technicaladdress] += amount;
        technical -= amount;
        emit Transfer(0x888888888888,technicaladdress,amount);
        return true;
    }

    function() payable public{
        if (!founder.call.value(msg.value)()) revert();
    }

    //删除合约 
    function killContract() public returns(bool){
        require(msg.sender == founder);
        selfdestruct(founder);
        return true;
    }

}