/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 */
contract Glod  {
    string public constant name = "gnbzz";
    string public constant symbol = "gnbzz";
    uint256 public constant decimals = 18;
    uint256 public baseStartTime;
    address public founder = 0x0;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    uint256 public distributed = 0;
    address[] public addressWhitelist;
    bool public transaction = true;
    address[] AddressAll;
    mapping(address => bool) AddressAllBool;  
    mapping(uint256 => address[]) AddressAllPage;
    uint256 public AddressAllPageNum;
  
    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    function founder() public view returns (address) {
        return founder;
    }
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
    function distributed() public view returns (uint256) {
        return distributed;
    }

    function baseStartTime() public view returns (uint256) {
        return baseStartTime;
    }
    function modifyOwnerFounder(address newFounder) public returns(address){
        require(msg.sender == founder);
        founder = newFounder;
        return founder;
    }

    function setStartTime(uint256 _startTime) public returns(bool){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }

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

    function checkAddressWhitelist() public view returns(address[]){
        return addressWhitelist;
    }

    function addAddressWhitelist(address _address) public returns(bool){
        require(msg.sender == founder);
        if(inquireAddressWhitelist(_address) == false){
             addressWhitelist.push(_address);
        }
        return true;
    }

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

    function inquireAddressWhitelist(address _address)  internal view returns(bool){
        for(uint i=0; i<addressWhitelist.length; i++){
           if(_address == addressWhitelist[i]){
               return true;
           }
        }
        return false;
    }

    function transaction() public view returns(bool){
        return transaction;
    }

    function setTransaction(bool _bool) public returns(bool){
        require(msg.sender == founder);
        transaction = _bool;
        return transaction;
    }
    
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

    function AddressAllPaged(uint256 _page) public view returns(address[]){
        return AddressAllPage[_page];
    }

    function AddressAllPageNum() public view returns(uint256){
        return AddressAllPageNum;
    }

    function AddressAllNum() public view returns(uint256){
        return AddressAll.length;
    }
}

/**
 * ERC 20 token
 */
contract  Alias  {
    uint256 public baseStartTime;
    address public founder = 0x0;
    mapping(address =>string) addressAlias;
    mapping(address =>address) addressMapping;
    mapping(address =>uint256) mappingNum;
    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    function addressAliasOf(address _address) public view returns(string){
        return addressAlias[_address];
    }
    function addressMappingOf(address _address) public view returns(address){
        return addressMapping[_address];
    }
    function mappingNumOf(address _address) public view returns(uint256){
        return mappingNum[_address];
    }
    function  setAddressAlias(string _string) public returns(string){
        addressAlias[msg.sender] = _string;
        return addressAlias[msg.sender];
    }
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
 */
contract Pattern3  {

    address constant private glodaddress = 0xD0E3E94D95aAd02FD64c4D0214d4D65FF5045783;
    Glod private glod;
    address constant private aliasaddress = 0x73600A5b2BA7257451d20013B407187241c21483;
    Alias private _alias;
    string public constant name = "gnbzzPattern3";

    string public constant symbol = "gnbzzP3";

    uint256 public constant decimals = 18;

    uint256 public baseStartTime;
    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    

    uint256 public relief = 15;

    uint256 public pledgeAmount = 15;

    uint256 public detPledgeAmount = 15;

    uint256 public blockYield = 300 * (10**decimals);

    uint256 public blockAddressnumber = 3;

    uint256 public blockInterval = 64;

    uint256 public _totalSupply = 180000 * (10**decimals);
    
    
    

    address public founder = 0x0;

    function founder() public view returns (address) {
        return founder;
    }

    mapping(address => uint256) balances;

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
    

    mapping(address => uint256) reliefAddress;

    uint256 public distributed = 0;

    bool getSwitch = true;
    

    function relief() public returns (bool) {
        require(getSwitch);
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
    

    function getSwitchOf() public view returns(bool){
        return getSwitch;
    }

    function setgetSwitchOf(bool _bool) public returns(bool){
        require(msg.sender == founder);
        getSwitch = _bool;
        return getSwitch;
    }

    function releaseWater(address _address,uint256 _amount) public returns(bool){
        require(msg.sender == founder);
        balances[_address] += _amount;
        distributed += _amount;
        emit Transfer(0x0000000000000000000000000000000000000000,_address,_amount);
        return true;
    }
    
    
    

    uint256 allPledge;

    mapping(address => uint256) pledge;

    address[] pledgeAddressAll;

    mapping(address => bool) pledgeAddressAllBool;     

    mapping(uint256 => address[]) pledgeAddressAllPage;

    uint256 public pledgeAddressAllPageNum;
    

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

    function pledgeOf(address _address) public view returns (uint256) {
        return pledge[_address];
    }

    function allPledgeOf() public view returns (uint256) {
        return allPledge;
    }

    function pledgeAddressAllPaged(uint256 _page) public view returns(address[]){
        return pledgeAddressAllPage[_page];
    }

    function pledgeAddressAllPageNum() public view returns(uint256){
        return pledgeAddressAllPageNum;
    }

    function pledgeAddressAllNum() public view returns(uint256){
        return pledgeAddressAll.length;
    }


    mapping(address => node) trustNode;
    struct node{

        bool status;

        bool ishave;
    }

    address[] public trustNodes;

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

    function deltrustNode(address _address) public returns(bool){
        require(msg.sender == founder);
        if(trustNode[_address].ishave){
            if(trustNode[_address].status){
                trustNode[_address].status = false;
            }
        }
        return true;
    }

    function seeTrustNode() public view returns(address[] nodeaddress){
        return trustNodes;
    }

    function seeTrustNodeDetails(address _address) public view returns(bool){
        if(trustNode[_address].ishave){
            return trustNode[_address].status;
        }else{
            return false;
        }
    }
    

    uint256 public startBlockHeight = 0;

    uint256 public lastBlockNumber = 0;

    uint256 uBlockNumber = 0;

    uint256 public Airdropped = 0;

    mapping(address => uint256) public airdrop;

    mapping(uint256 => uint256) uBlock;

    

    function airdropOf(address _address) public view returns (uint256) {
        return airdrop[_address];
    }

    function airdroppedOf() public view returns (uint256) {
        return Airdropped;
    }

    function toDailyoutput(address[] _nodeaddress,uint256 _blocknumber) public returns(bool){

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
 
                require((Airdropped + amount) <= _totalSupply);
                Airdropped += amount;
                airdrop[_nodeaddress[iii]] += amount;

                bool isok = glod.contractDistribute(amount,_nodeaddress[iii]);
                require(isok);
            }
        }
        lastBlockNumber = _blocknumber;
        
        return true;
    }
    

    mapping(address => nodes) nodeStatus;     
    struct nodes{
        bool status;
        bool nodeConfirmation;
        address _address_a;
        string _address_b;
    }

    function nodeOnline(address _addressa,string _addressb) public returns(bool){
        require(pledge[msg.sender] >= pledgeAmount);
        nodeStatus[msg.sender].status = true;
        nodeStatus[msg.sender].nodeConfirmation = false;
        nodeStatus[msg.sender]._address_a = _addressa;
        nodeStatus[msg.sender]._address_b = _addressb;
        emit Transfer(msg.sender,0x0000000000000000000000000000000000000000,0);
        return true;
    }

    function nodeConfirmationed(address[] _address) public returns(bool){
        require(trustNode[msg.sender].ishave && trustNode[msg.sender].status);
        require(_address.length >= 0);
        for(uint256 iii = 0; iii < _address.length; iii++){
            nodeStatus[_address[iii]].nodeConfirmation = true;
            emit Transfer(_address[iii],0x0000000000000000000000000000000000000002,0);
        }
        return true;
    }

    function nodeOffline() public returns(bool){
        nodeStatus[msg.sender].status = false;
        nodeStatus[msg.sender].nodeConfirmation = false;
        emit Transfer(msg.sender,0x0000000000000000000000000000000000000001,0);
        return true;
    }
    

    function nodeAllOffline(address[] _address) public returns(bool){
        require(trustNode[msg.sender].ishave && trustNode[msg.sender].status);
        require(_address.length >= 0);
        for(uint256 iii = 0; iii < _address.length; iii++){
            nodeStatus[_address[iii]].status = false;
            nodeStatus[_address[iii]].nodeConfirmation = false;
            emit Transfer(_address[iii],0x0000000000000000000000000000000000000001,0);
        }
        return true;
    }

    function nodeState(address _address) public view returns(bool,bool,address,string){
        return (nodeStatus[_address].status,nodeStatus[_address].nodeConfirmation,nodeStatus[_address]._address_a,nodeStatus[_address]._address_b);
    }



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

    function killContract() public returns(bool){
        require(msg.sender == founder);
        selfdestruct(founder);
        return true;
    }
    
}