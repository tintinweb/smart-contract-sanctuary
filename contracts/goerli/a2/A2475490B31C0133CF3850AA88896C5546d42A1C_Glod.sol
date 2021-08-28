/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 */
contract Glod  {
    /**
     ***********************************  ********************************** 
    */
    /************/
    string public constant name = "gnbzz";
    /************/
    string public constant symbol = "gnbzz";
    /************/
    uint256 public constant decimals = 18;
    /************/
    uint256 public baseStartTime;
    /************/
    address public founder = 0x0;
    /************/
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    
    /**
     ***********************************  ********************************** 
    */
    /************/
    // uint256 public _totalSupply = 180000 * 10**decimals;
    /************/
    uint256 public distributed = 0;
    /************/
    address[] public addressWhitelist;
    /************/
    bool public transaction = true;
    
    
    /**
     ***********************************  ********************************** 
    */
    /************/
    mapping(address => uint256) contractAirdrop;
    /************/
    mapping(address => uint256) allAirdrop;
    /************/
    mapping(address => mapping(address => uint256)) airdrop;
    /************/
    mapping(address => uint256) allPledge;
    /************/
    mapping(address => mapping(address => uint256)) pledge;
    /************/
    mapping(address => address[]) pledgeAddressAll;
    /************/
    mapping(address => mapping(address => bool)) pledgeAddressAllBool;     
    /************/
    mapping(address => mapping(uint256 => address[])) pledgeAddressAllPage;
    /************/
    mapping(address => uint256) public pledgeAddressAllPageNum;
    /************/
    address[] AddressAll;
    /************/
    mapping(address => bool) AddressAllBool;  
    /************/
    mapping(uint256 => address[]) AddressAllPage;
    /************/
    uint256 public AddressAllPageNum;
  
  
    /**
     **********************************  ********************************** 
    */
    /************/
    constructor() public{
        founder = msg.sender;
        baseStartTime = block.timestamp;
    }
    /************/
    function founder() public view returns (address) {
        return founder;
    }
    /************/
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
    /************/
    function distributed() public view returns (uint256) {
        return distributed;
    }
    /************/
    function baseStartTime() public view returns (uint256) {
        return baseStartTime;
    }
    /************/
    function modifyOwnerFounder(address newFounder) public returns(address){
        require(msg.sender == founder);
        founder = newFounder;
        return founder;
    }
    /************/
    function setStartTime(uint256 _startTime) public returns(bool){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }
    /************/
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
    /************/
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
    /************/
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
     ***********************************  ********************************** 
    */
    /************/
    function checkAddressWhitelist() public view returns(address[]){
        return addressWhitelist;
    }
    /************/
    function addAddressWhitelist(address _address) public returns(bool){
        require(msg.sender == founder);
        if(inquireAddressWhitelist(_address) == false){
             addressWhitelist.push(_address);
        }
        return true;
    }
    /************/
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
    /************/
    function inquireAddressWhitelist(address _address)  internal view returns(bool){
        for(uint i=0; i<addressWhitelist.length; i++){
           if(_address == addressWhitelist[i]){
               return true;
           }
        }
        return false;
    }
    /************/
    function transaction() public view returns(bool){
        return transaction;
    }
    /************/
    function setTransaction(bool _bool) public returns(bool){
        require(msg.sender == founder);
        transaction = _bool;
        return transaction;
    }
    
    
    /**
     ***********************************  ********************************** 
    */
    /******  ******/
    function contractAirdropOf(address _address) public view returns (uint256) {
        return contractAirdrop[_address];
    }
    /******  ******/
    function allPledgeOf(address _address) public view returns (uint256) {
        return allPledge[_address];
    }
    /****** ******/
    function allAirdropOf(address _address) public view returns (uint256) {
        return allAirdrop[_address];
    }
    /************/
    function setContractAirdrop(uint256 _amount) public returns(bool){
        require(inquireAddressWhitelist(msg.sender));
        contractAirdrop[msg.sender] = _amount;
        return true;
    }
    /****** ******/
    function airdropOf(address _contract,address _address) public view returns(uint256){
        return airdrop[_contract][_address];
    }
    /************/
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
    /************/
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
    /************/
    function contractIssueAirdrop(uint256 _amount, address _to) public returns (bool){
        require(inquireAddressWhitelist(msg.sender));
        require(allAirdrop[msg.sender] + _amount >= allAirdrop[msg.sender]);
        require(allAirdrop[msg.sender] + _amount < contractAirdrop[msg.sender]);
        airdrop[msg.sender][_to] += _amount;
        allAirdrop[msg.sender] +=_amount;
        return true;
    }
    /************/
    function contractBatchIssueAirdrop(uint256[] _amount, address[] _to) public returns (bool){
        require(inquireAddressWhitelist(msg.sender));
        require(_amount.length == _to.length);
        for(uint iii = 0; iii < _to.length; iii++){
            require(allAirdrop[msg.sender] + _amount[iii] >= allAirdrop[msg.sender]);
            require(allAirdrop[msg.sender] + _amount[iii] < contractAirdrop[msg.sender]);
            airdrop[msg.sender][_to[iii]] += _amount[iii];
            allAirdrop[msg.sender] += _amount[iii];
        }
        return true;
    }
    /************/
    function contractPledge(address _address,uint256 _amount) public returns (bool){
        require(inquireAddressWhitelist(msg.sender));
        require(balances[_address] >= _amount);
        require(_amount + 1 >= 1);
        balances[_address] -= _amount;
        pledge[msg.sender][_address] += _amount;
        allPledge[msg.sender] +=_amount;
        emit Transfer(_address,msg.sender,_amount);
        if(pledgeAddressAllBool[msg.sender][_address] == false){
            pledgeAddressAllBool[msg.sender][_address] = true;
            uint256 p = (pledgeAddressAll[msg.sender].length / 1000) + 1;
            pledgeAddressAllPage[msg.sender][p].push(msg.sender);
            pledgeAddressAllPageNum[msg.sender] = p;
            pledgeAddressAll[msg.sender].push(_address);
        }
        return true;
    }
     /************/
    function addressIsPledge(address _address) public view returns(uint256){
        require(inquireAddressWhitelist(msg.sender));
        return pledge[msg.sender][_address];
    }
    
    /*************/
    function pledgeAddressAllPaged(address _address,uint256 _page) public view returns(address[]){
        return pledgeAddressAllPage[_address][_page];
    }
    /*************/
    function pledgeAddressAllPageNum(address _address) public view returns(uint256){
        return pledgeAddressAllPageNum[_address];
    }
    /*************/
    function pledgeAddressAllNum(address _address) public view returns(uint256){
        return pledgeAddressAll[_address].length;
    }
    
    /*************/
    function AddressAllPaged(uint256 _page) public view returns(address[]){
        return AddressAllPage[_page];
    }
    /*************/
    function AddressAllPageNum() public view returns(uint256){
        return AddressAllPageNum;
    }
    /*************/
    function AddressAllNum() public view returns(uint256){
        return AddressAll.length;
    }
    

}