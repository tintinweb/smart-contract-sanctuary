/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Test2  {
    string public constant name = "Test2Token";//币全称
    string public constant symbol = "Test2";//币简称
    uint public constant decimals = 18;//小数位
    uint256 public _totalSupply = 180000 * 10**decimals;//发行量
    uint public baseStartTime; //基准时间
    address public founder = 0x0;//默认拥有者
    mapping(address => uint256) balances;         //地址余额
    uint256 public distributed = 0;//发行量
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
    uint airdropall;     //空投总量
    uint lastblocknumbeblocknumber = 0;  //上次空投的区块高度
    address[] _nodeaddressnow; //上次参与空投的地址

    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    /*
    * from 0x000000000000 领水
    * to   0x111111111111 质押
    */
    //定义合约拥有者(构造函数)
    function Test2(){
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    //者修改基准点时间
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
    //查询某个地址余额
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    //领取15个币并质押
    function relief() public returns (bool success) {
        if(reliefaddress[msg.sender] == 0){
            balances[msg.sender] += 15 * (10**decimals);
            reliefaddress[msg.sender] += 15 * (10**decimals);
            emit Transfer(0x000000000000,msg.sender, 15 * (10**decimals));
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
            emit Transfer(msg.sender,0x111111111111, 15 * (10**decimals));
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
    function airdropd(address _address) public view returns (uint) {
        return airdrop[_address];
    }

    //分币  ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7"]
    function todailyoutput(address[] _nodeaddress,uint[] _fraction,uint _blocknumber) public returns(bool success){
        uint amountall = _totalSupply/40320;//每个块的出币数
        if(airdropall >= _totalSupply){
            return false;
        }
        if(_nodeaddress.length != _fraction.length){
            return false;
        }

        if(_blocknumber - lastblocknumbeblocknumber != 256 ){
            if(lastblocknumbeblocknumber != 0){
               return false;
            }
        }
        lastblocknumbeblocknumber = _blocknumber;
        if(trustnode[msg.sender].ishave && trustnode[msg.sender].status){
            if(_nodeaddress.length > 0 ){
                uint i = 0;
                _nodeaddressnow.length = 0;
                for(uint ii = 0; ii < _nodeaddress.length; ii++){
                    if(pledgeaddressallbool[_nodeaddress[ii]] == true){
                        i += 1;
                        _nodeaddressnow.push(_nodeaddress[ii]);
                    }
                }
                if(i > 0){
                    uint amount = amountall/i;
                    for(uint iii = 0; iii < _nodeaddressnow.length; iii++){
                        airdrop[_nodeaddressnow[iii]] += amount;
                        airdropall += amount;
                    }
                }
            }else{
                return false;
            }

        }else{
            return false;
        }
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