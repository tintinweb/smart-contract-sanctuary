/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Test  {
    string public constant name = "TToken";//币全称
    string public constant symbol = "T";//币简称
    uint public constant decimals = 18;//小数位
    uint256 public _totalSupply = 180000 * 10**decimals;//发行量
    uint public baseStartTime; //基准时间
    address public founder = 0x0;//默认拥有者
    mapping(address => uint256) balances;         //地址余额
    uint256 distributed = 0;//发行量
    mapping(address => uint256) reliefaddress;     //领取救济
    mapping(address => uint256) pledgeamount;     //质押数量
    uint256 public pledgeamountall; //总质押数量
    address[] internal pledgeaddressall; //质押地址集合
    mapping(address => bool) pledgeaddressallbool;     //质押地址集合映射
    struct node{
        bool status;//信任节点状态
        bool ishave;//信任节点是否被设定
    }

    mapping(address => node) trustnode;     //信任节点映射
    address[] trustnodes;//信任节点集合

    mapping(address => uint256) airdrop;     //空投数量
    uint public airdropall;     //空投总量
    uint public lastblocknumbeblocknumber = 0;  //上次空投的区块高度
    // address[] _nodeaddressnow; //上次参与空投的地址

    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public startblockheight = 0;     //起始高度
    uint public startcents = 0;     //开始分币


    uint256 ublocknumber = 0;//释放的次数
    mapping(uint256 => blockdetails) ublock;//块详情
    struct blockdetails{
        uint _blocknumber;//本次的高度
        address[] _address;//本块的地址集合
        uint256[] _amount;//本块的数量集合
    }

    /*
    * from 0x0000000000000000000000000000000000000000 领水
    * to   0x1111111111111111111111111111111111111111 质押
    */
    //定义合约拥有者(构造函数)
    function Test(){
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }

    //总质押数量
    function pledgeamountall() public view returns(uint){
        return pledgeamountall;
    }

    //起始块高
    function startblockheight() public view returns(uint){
        return startblockheight;
    }


    //总空投数量
    function airdropall() public view returns(uint){
        return airdropall;
    }

    //拥有者修改基准点时间
    function setStartTime(uint _startTime) public returns(bool success){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }

    //拥有者设置是否开始分币
    function setstartcents() public returns(bool success){
        require(msg.sender == founder);
        if(startcents == 0){
            startcents = 1;
        }
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
        emit Transfer(0x0000000000000000000000000000000000000000,msg.sender, _amount);
        return true;
    }
    //查询某个地址余额
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    //领取15个币并质押
    function relief() public returns (bool success) {
        if(reliefaddress[msg.sender] == 0){
            balances[msg.sender] += 15 * (10**decimals);
            reliefaddress[msg.sender] += 15 * (10**decimals);
            emit Transfer(0x0000000000000000000000000000000000000000,msg.sender, 15 * (10**decimals));
            return true;
        }else{
            return false;
        }
    }
    //质押
    function pledge() public returns(bool success){
        if(balances[msg.sender] >= 15 * (10**decimals)){
            balances[msg.sender] -= 15 * (10**decimals);
            pledgeamount[msg.sender] += 15 * (10**decimals);
            pledgeamountall += 15 * (10**decimals);
            emit Transfer(msg.sender,0x1111111111111111111111111111111111111111, 15 * (10**decimals));
            if(pledgeaddressallbool[msg.sender] == false){
                pledgeaddressallbool[msg.sender] = true;
                pledgeaddressall.push(msg.sender);
            }
            return true;
        }else{
            return false;
        }

    }
    //返回当前的质押地址列表
    function pledgeaddressalld() public view returns(address[]){
        return pledgeaddressall;
    }
    //查询地址质押数量
    function addresspledge(address _address) public view returns (uint) {
        return pledgeamount[_address];
    }

    //设置信任节点
    function settrustnode(address _address) public returns (bool success){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            trustnode[_address].status = true;
        }else{
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
    function seetrustnodedetails(address _address) public view returns(bool status){
        require(msg.sender == founder);
        if(trustnode[_address].ishave){
            return trustnode[_address].status;
        }else{
            return false;
        }
    }


    //查询某地址的空投数量
    function airdropd(address _address) public view returns (uint256) {
        return airdrop[_address];
    }

    //查询释放次数
    function ublocknumberd() public view returns(uint256){
        return ublocknumber;
    }

    //查询释放详情
    function ublockd(uint256 _blcoknum) public view returns(uint _blocknumber,address[] _address,uint256[] _amount){
        return (ublock[_blcoknum]._blocknumber,ublock[_blcoknum]._address,ublock[_blcoknum]._amount);
    }

    //分币  ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7"] [1,2,3]
    function todailyoutput(address[] _nodeaddress,uint[] _fraction,uint _blocknumber) public returns(bool success){
        uint amountall = 300 * (10**decimals);//每个块的出币数
        require(airdropall < _totalSupply);
        require(_nodeaddress.length == _fraction.length);
        require(_nodeaddress.length == 2);
        require(startcents == 1);
        // require(pledgeaddressall.length >= 2000);

        if(_blocknumber - lastblocknumbeblocknumber != 64 ){
            if(lastblocknumbeblocknumber != 0){
              return false;
            }
        }
        if(startblockheight == 0){
            startblockheight = _blocknumber;
        }
        ublocknumber += 1;//释放次数加一
        ublock[ublocknumber]._blocknumber = _blocknumber;//本次释放真实块高
        if(trustnode[msg.sender].ishave && trustnode[msg.sender].status){
            if(_nodeaddress.length > 0 ){
                uint amount = amountall/_nodeaddress.length;
                for(uint iii = 0; iii < _nodeaddress.length; iii++){
                    airdrop[_nodeaddress[iii]] += amount;
                    airdropall += amount;
                    distributed += amount;
                    ublock[ublocknumber]._address.push(_nodeaddress[iii]);//将地址放入快详情
                    ublock[ublocknumber]._amount.push(amount);//将数量放入快详情
                }
                // uint i = 0;
                // _nodeaddressnow.length = 0;
                // for(uint ii = 0; ii < _nodeaddress.length; ii++){
                //     if(pledgeaddressallbool[_nodeaddress[ii]] == true){
                //         i += 1;
                //         _nodeaddressnow.push(_nodeaddress[ii]);
                //     }
                // }
                // if(i > 0){
                //     uint amount = amountall/i;
                //     for(uint iii = 0; iii < _nodeaddressnow.length; iii++){
                //         airdrop[_nodeaddressnow[iii]] += amount;
                //         airdropall += amount;
                //         distributed += amount;
                //     }
                // }
            }else{
                return false;
            }

        }else{
            return false;
        }
        lastblocknumbeblocknumber = _blocknumber;
        return true;
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