/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 * 币的合约
 * 0x0000000000000000000000000000000000000000    拥有者分发
 */
contract Glod  {
    /**
     *********************************** 发币的必要属性 ********************************** 
    */
    /******币全称******/
    string public constant name = "gnbzz";
    /******币简称******/
    string public constant symbol = "gnbzz";
    /******小数位******/
    uint256 public constant decimals = 18;
    /******基准时间******/
    uint256 public baseStartTime;
    /******合约拥有者******/
    address public founder = 0x0;
    /******地址余额******/
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    
    /**
     *********************************** 发币的非必要属性 ********************************** 
    */
    /******总发行量******/
    // uint256 public _totalSupply = 180000 * 10**decimals;
    /******当前发行量******/
    uint256 public distributed = 0;
    /******调用合约地址白名单******/
    address[] public addressWhitelist;
    /******是否允许交易******/
    bool public transaction = true;
    
    
    /**
     *********************************** 本模式需要的方法属性 ********************************** 
    */
    /******持币地址集合******/
    address[] AddressAll;
    /******持币地址集合映射******/
    mapping(address => bool) AddressAllBool;  
    /******持币地址集合分页******/
    mapping(uint256 => address[]) AddressAllPage;
    /******持币地址集合最大页数******/
    uint256 public AddressAllPageNum;
  
  
    /**
     ********************************** 发币的必要方法 ********************************** 
    */
    /******定义合约拥有者(构造函数)******/
    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    /******拥有者******/
    function founder() public view returns (address) {
        return founder;
    }
    /******查询某个地址余额******/
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
    /******当前发行量******/
    function distributed() public view returns (uint256) {
        return distributed;
    }
    /******基准点时间******/
    function baseStartTime() public view returns (uint256) {
        return baseStartTime;
    }
    /******修改合约的拥有者******/
    function modifyOwnerFounder(address newFounder) public returns(address){
        require(msg.sender == founder);
        founder = newFounder;
        return founder;
    }
    /******拥有者修改基准点时间******/
    function setStartTime(uint256 _startTime) public returns(bool){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }
    /******分发代币（只有拥有者可以操作）******/
    function distribute(uint256 _amount, address _to) public returns (bool){
        require(msg.sender == founder);
        require(distributed + _amount >= distributed);
        balances[_to] += _amount;
        distributed += _amount;
        emit Transfer(0x0000000000000000000000000000000000000000,_to, _amount);
        if(AddressAllBool[_to] == false){
            AddressAllBool[_to] = true;
            uint256 p = (AddressAll.length / 1000) + 1;
            AddressAllPage[p].push(_to);
            AddressAllPageNum = p;
            AddressAll.push(_to);
        }
        return true;
    }
    // ["0xa97CD7e465d69c69f420Db71Bd0CBCf2aDFb65B4","0xa97CD7e465d69c69f420Db71Bd0CBCf2aDFb65B4","0xa97CD7e465d69c69f420Db71Bd0CBCf2aDFb65B4","0xa97CD7e465d69c69f420Db71Bd0CBCf2aDFb65B4","0xa97CD7e465d69c69f420Db71Bd0CBCf2aDFb65B4","0xAfC952A3451ad8Da1CAE9301BCf8AfEDf5011B65"]
    // ["10000000000000000000","10000000000000000000","10000000000000000000","10000000000000000000","10000000000000000000","10000000000000000000"]
    /******批量分发代币（只有拥有者可以操作）******/
    function batchDistribute(uint256[] _amount, address[] _to) public returns (bool){
        require(msg.sender == founder);
        require(_amount.length == _to.length);
        for(uint iii = 0; iii < _to.length; iii++){
            require(distributed + _amount[iii] >= distributed);
            balances[_to[iii]] += _amount[iii];
            distributed += _amount[iii];
            emit Transfer(0x0000000000000000000000000000000000000000,_to[iii], _amount[iii]);
            if(AddressAllBool[_to[iii]] == false){
                AddressAllBool[_to[iii]] = true;
                uint256 p = (AddressAll.length / 1000) + 1;
                AddressAllPage[p].push(_to[iii]);
                AddressAllPageNum = p;
                AddressAll.push(_to[iii]);
            }
        }
        return true;
    }
    /******交易******/
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != msg.sender);
        require(now > baseStartTime);
        require(transaction);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            if(AddressAllBool[_to] == false){
                AddressAllBool[_to] = true;
                uint256 p = (AddressAll.length / 1000) + 1;
                AddressAllPage[p].push(_to);
                AddressAllPageNum = p;
                AddressAll.push(_to);
            }
            return true;
        } else {
            require(false);
        }
    }
    function() payable public{
        if (!founder.call.value(msg.value)()) revert();
    }
    /**
     *********************************** 发币的非必要方法 ********************************** 
    */
    /******查看调用合约地址白名单******/
    function checkAddressWhitelist() public view returns(address[]){
        return addressWhitelist;
    }
    /******添加调用合约地址白名单******/
    function addAddressWhitelist(address _address) public returns(bool){
        require(msg.sender == founder);
        if(inquireAddressWhitelist(_address) == false){
             addressWhitelist.push(_address);
        }
        return true;
    }
    /******删除调用合约地址白名单******/
    function deleteAddressWhitelist(address _address) public returns(bool){
        require(msg.sender == founder);
        require(inquireAddressWhitelist(_address));
        if(addressWhitelist.length == 1){
            return false;
        }
        for(uint i=0; i < addressWhitelist.length; i++){
          if(_address == addressWhitelist[i] && i != addressWhitelist.length - 1){
              addressWhitelist[i] = addressWhitelist[i+1];
          }
        }
        addressWhitelist.length --;
        return true;
    }
    /******判断调用合约地址是否在白名单中******/
    function inquireAddressWhitelist(address _address)  internal view returns(bool){
        for(uint i=0; i<addressWhitelist.length; i++){
           if(_address == addressWhitelist[i]){
               return true;
           }
        }
        return false;
    }
    /******是否允许交易******/
    function transaction() public view returns(bool){
        return transaction;
    }
    /******交易开关******/
    function setTransaction(bool _bool) public returns(bool){
        require(msg.sender == founder);
        transaction = _bool;
        return transaction;
    }
    
    
    /**
     *********************************** 本模式需要的方法 ********************************** 
    */
    /******合约分发代币（只有白名单合约可以操作）******/
    function contractDistribute(uint256 _amount, address _to) public returns (bool){
        require(inquireAddressWhitelist(msg.sender));
        require(distributed + _amount >= distributed);
        balances[_to] += _amount;
        distributed += _amount;
        emit Transfer(msg.sender,_to, _amount);
        if(AddressAllBool[_to] == false){
            AddressAllBool[_to] = true;
            uint256 p = (AddressAll.length / 1000) + 1;
            AddressAllPage[p].push(_to);
            AddressAllPageNum = p;
            AddressAll.push(_to);
        }
        return true;
    }
    /******合约批量分发代币（只有白名单合约可以操作）******/
    function contractBatchDistribute(uint256[] _amount, address[] _to) public returns (bool){
        require(inquireAddressWhitelist(msg.sender));
        require(_amount.length == _to.length);
        for(uint iii = 0; iii < _to.length; iii++){
            require(distributed + _amount[iii] >= distributed);
            balances[_to[iii]] += _amount[iii];
            distributed += _amount[iii];
            emit Transfer(msg.sender,_to[iii], _amount[iii]);
            if(AddressAllBool[_to[iii]] == false){
                AddressAllBool[_to[iii]] = true;
                uint256 p = (AddressAll.length / 1000) + 1;
                AddressAllPage[p].push(_to[iii]);
                AddressAllPageNum = p;
                AddressAll.push(_to[iii]);
            }
        }
        return true;
    }
    /******返回持币地址(分页)列表*******/
    function AddressAllPaged(uint256 _page) public view returns(address[]){
        return AddressAllPage[_page];
    }
    /******返回持币地址总分页数*******/
    function AddressAllPageNum() public view returns(uint256){
        return AddressAllPageNum;
    }
    /******返回持币地址总数*******/
    function AddressAllNum() public view returns(uint256){
        return AddressAll.length;
    }
}

/**
 * ERC 20 token
 * 别名
 */
contract  Alias  {
    /******基准时间******/
    uint256 public baseStartTime;
    /******合约拥有者******/
    address public founder = 0x0;
    /******地址别名******/
    mapping(address =>string) addressAlias;
    /******地址映射******/
    mapping(address =>address) addressMapping;
    /******地址映射剩量******/
    mapping(address =>uint256) mappingNum;
    
    /******定义合约拥有者(构造函数)******/
    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    /******查看别名******/
    function addressAliasOf(address _address) public view returns(string){
        return addressAlias[_address];
    }
    /******查看映射******/
    function addressMappingOf(address _address) public view returns(address){
        return addressMapping[_address];
    }
    /******查看映射数量******/
    function mappingNumOf(address _address) public view returns(uint256){
        return mappingNum[_address];
    }
    /******设置别名******/
    function  setAddressAlias(string _string) public returns(string){
        addressAlias[msg.sender] = _string;
        return addressAlias[msg.sender];
    }
    /******设置映射******/
    function  setAddressMapping(address _address) public returns(address){
        if(addressMapping[msg.sender] == 0){
            addressMapping[msg.sender] = _address;
            mappingNum[_address] += 1;
        }else{
            mappingNum[addressMapping[msg.sender]] -= 1;
            addressMapping[msg.sender] = _address;
        }
        return addressMapping[msg.sender];
    }
    /******删除合约******/
    function killContract() public returns(bool){
        require(msg.sender == founder);
        selfdestruct(founder);
        return true;
    }
}


/**
 * ERC 20 token
 * 二期模式
 * 0x0000000000000000000000000000000000000000    领水
 * 0x1111111111111111111111111111111111111111    质押
 * 0x2222222222222222222222222222222222222222    扣除质押
 */
contract Pattern2  {
    /******币全称******/
    string public constant name = "gnbzzPattern2";
    /******币简称******/
    string public constant symbol = "gnbzzP2";
    /******小数位******/
    uint256 public constant decimals = 18;
    /******基准时间******/
    uint256 public baseStartTime;
    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    /******定义合约拥有者(构造函数)******/
    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    
    
    /******************************************需要配置的参数*****************************************/
    /******领水金额******/
    uint256 public relief = 15;
    /******质押金额******/
    uint256 public pledgeAmount = 15;
    /******扣除质押金额******/
    uint256 public detPledgeAmount = 15;
    /******块产量******/
    uint256 public blockYield = 15 * (10**decimals);
    /******块地址数量******/
    uint256 public blockAddressnumber = 3;
    /******块间隔******/
    uint256 public blockInterval = 64;
    /******本合约的空投数量******/
    uint256 public _totalSupply = 180000 * (10**decimals);
    /******合约拥有者******/
    address public founder = 0x0;
    /******拥有者******/
    function founder() public view returns (address) {
        return founder;
    }
    
    
    /******地址余额******/
    mapping(address => uint256) balances;
    /******查询某个地址余额******/
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
    
    /******领水地址******/
    mapping(address => uint256) reliefAddress;
    /******总领水量******/
    uint256 public distributed = 0;
    /****** 领水 ******/
    function relief() public returns (bool) {
        if(reliefAddress[msg.sender] == 0){
            balances[msg.sender] += relief * (10**decimals);
            reliefAddress[msg.sender] += relief * (10**decimals);
            distributed += relief * (10**decimals);
            emit Transfer(0x0000000000000000000000000000000000000000,msg.sender, relief * (10**decimals));
            return true;
        }else{
            require(false);
        }
    }
    
    /******合约质押总量******/
    uint256 allPledge;
    /******地址的质押数量******/
    mapping(address => uint256) pledge;
    /******质押地址集合******/
    address[] pledgeAddressAll;
    /******质押地址集合映射******/
    mapping(address => bool) pledgeAddressAllBool;     
    /******质押地址集合分页******/
    mapping(uint256 => address[]) pledgeAddressAllPage;
    /******质押地址集合最大页数******/
    uint256 public pledgeAddressAllPageNum;
    
    /******质押******/
    function contractPledge() public returns (bool){
        require(balances[msg.sender] >= (pledgeAmount * (10**decimals)));
        balances[msg.sender] -= pledgeAmount* (10**decimals);
        pledge[msg.sender] += pledgeAmount* (10**decimals);
        allPledge += pledgeAmount * (10**decimals);
        emit Transfer(msg.sender,0x1111111111111111111111111111111111111111,pledgeAmount* (10**decimals));
        if(pledgeAddressAllBool[msg.sender] == false){
            pledgeAddressAllBool[msg.sender] = true;
            uint256 p = (pledgeAddressAll.length / 1000) + 1;
            pledgeAddressAllPage[p].push(msg.sender);
            pledgeAddressAllPageNum = p;
            pledgeAddressAll.push(msg.sender);
        }
        return true;
    }
    /******扣除质押******/
    function deductionOfPledge(address _address) public returns(bool){
        require(trustNode[msg.sender].ishave && trustNode[msg.sender].status);
        if(pledge[_address] < detPledgeAmount){
            detPledgeAmount = pledge[_address];
        }
        pledge[_address] -= detPledgeAmount* (10**decimals);
        allPledge -= detPledgeAmount * (10**decimals);
        emit Transfer(_address,0x2222222222222222222222222222222222222222,detPledgeAmount * (10**decimals));
        nodeStatus[_address].status = false;
        return true;
    }
    /******查询某个质押数量******/
    function pledgeOf(address _address) public view returns (uint256) {
        return pledge[_address];
    }
    /******查询质押总量******/
    function allPledgeOf() public view returns (uint256) {
        return allPledge;
    }
    /******返回合约质押地址(分页)列表*******/
    function pledgeAddressAllPaged(uint256 _page) public view returns(address[]){
        return pledgeAddressAllPage[_page];
    }
    /******返回合约质押地址总分页数*******/
    function pledgeAddressAllPageNum() public view returns(uint256){
        return pledgeAddressAllPageNum;
    }
    /******返回合约的质押地址总数*******/
    function pledgeAddressAllNum() public view returns(uint256){
        return pledgeAddressAll.length;
    }

    /******信任节点映射******/
    mapping(address => node) trustNode;
    struct node{
        /******信任节点状态******/
        bool status;
        /******信任节点是否被设定******/
        bool ishave;
    }
    /******信任节点集合******/
    address[] public trustNodes;
    /****** 设置信任节点 ******/
    function setTrustNode(address _address) public returns (bool){
        require(msg.sender == founder);
        if(trustNode[_address].ishave){
            trustNode[_address].status = true;
        }else{
            trustNode[_address].status = true;
            trustNode[_address].ishave = true;
            trustNodes.push(_address);
        }
        return true;
    }
    /****** 删除信任节点 ******/
    function deltrustNode(address _address) public returns(bool){
        require(msg.sender == founder);
        if(trustNode[_address].ishave){
            if(trustNode[_address].status){
                trustNode[_address].status = false;
            }
        }
        return true;
    }
    /****** 查看信任节点列表 ******/
    function seeTrustNode() public view returns(address[] nodeaddress){
        return trustNodes;
    }
    /****** 查看信任节点详情 ******/
    function seeTrustNodeDetails(address _address) public view returns(bool){
        if(trustNode[_address].ishave){
            return trustNode[_address].status;
        }else{
            return false;
        }
    }
    
    /******起始高度******/
    uint256 public startBlockHeight = 0;
    /******上次空投的区块高度******/
    uint256 public lastBlockNumber = 0;
    /******释放的次数******/
    uint256 uBlockNumber = 0;
    /******已经空投数量******/
    uint256 public Airdropped = 0;
    /******地址空投数量******/
    mapping(address => uint256) public airdrop;
    /******块详情******/
    mapping(uint256 => uint256) uBlock;
    /******地址空投数量******/
    function airdropOf(address _address) public view returns (uint256) {
        return airdrop[_address];
    }
    /******已经空投数量******/
    function airdroppedOf() public view returns (uint256) {
        return Airdropped;
    }
    
    // ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xa97CD7e465d69c69f420Db71Bd0CBCf2aDFb65B4","0xAfC952A3451ad8Da1CAE9301BCf8AfEDf5011B65"]
    /******分币******/
    function toDailyoutput(Glod glod,Alias _alias,address[] _nodeaddress,uint256 _blocknumber) public returns(bool){
        /******每个块的出币数******/
        require(_nodeaddress.length == blockAddressnumber);
        require(trustNode[msg.sender].ishave && trustNode[msg.sender].status);
        if(_blocknumber - lastBlockNumber != blockInterval ){
            if(lastBlockNumber != 0){
                require(false);
            }
        }
        if(startBlockHeight == 0){
            startBlockHeight = _blocknumber;
        }
        uBlockNumber += 1;
        uBlock[uBlockNumber] = _blocknumber;
        uint256 amount = blockYield / _nodeaddress.length;
        for(uint256 iii = 0; iii < _nodeaddress.length; iii++){
            if(pledge[_nodeaddress[iii]] >= pledgeAmount){
                if(_alias.addressMappingOf(_nodeaddress[iii]) != 0x00){
                     _nodeaddress[iii] = _alias.addressMappingOf(_nodeaddress[iii]);
                }
                /******发放空投******/
                require((Airdropped + amount) < _totalSupply);
                Airdropped += amount;
                airdrop[_nodeaddress[iii]] += amount;
                /******发放代币******/
                bool isok = glod.contractDistribute(amount,_nodeaddress[iii]);
                require(isok);
            }
        }
        lastBlockNumber = _blocknumber;
        
        return true;
    }
    
    /******节点运行状态******/
    mapping(address => nodes) nodeStatus;     
    struct nodes{
        bool status;//节点状态
        address _address_a;//地址
        address _address_b;//地址
    }
    /******节点上线******/
    function nodeOnline(address _addressa,address _addressb) public returns(bool){
        nodeStatus[msg.sender].status = true;
        nodeStatus[msg.sender]._address_a = _addressa;
        nodeStatus[msg.sender]._address_b = _addressb;
        return true;
    }
    /******节点下线******/
    function nodeOffline() public returns(bool){
        nodeStatus[msg.sender].status = false;
        return true;
    }
    /******节点状态******/
    function nodeState(address _address) public view returns(bool,address,address){
        return (nodeStatus[_address].status,nodeStatus[_address]._address_a,nodeStatus[_address]._address_b);
    }


    /******交易******/
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != msg.sender);
        require(now > baseStartTime);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            require(false);
        }
    }
    function() payable public{
        if (!founder.call.value(msg.value)()) revert();
    }
    /******删除合约******/
    function killContract() public returns(bool){
        require(msg.sender == founder);
        selfdestruct(founder);
        return true;
    }
    
}