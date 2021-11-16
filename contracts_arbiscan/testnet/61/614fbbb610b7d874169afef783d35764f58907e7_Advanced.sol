/**
 *Submitted for verification at arbiscan.io on 2021-11-15
*/

pragma solidity ^0.8.0;
abstract contract IGI {
    function transfer(address to, uint256 id, uint256 value) public virtual;
    function multiTransfer(address[] memory to, uint256[] memory id, uint256[] memory value) public virtual;
    function transferFrom(address from, address to,  uint256 id, uint256 value) public virtual;
    
    //balance of
    function balanceOf(address owner, uint256 id) public view virtual returns (uint256);
    
    function approve(address spender, uint256 id, bool status) public virtual;
    function approveAll(address spender, bool status) public virtual;
    function allowance(address owner, uint256 id, address spender) public view virtual returns (bool status);
}
contract Ownable {
    address public owner = msg.sender;
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}
contract Manager is Ownable {
    mapping(address => bool) manager;

    function setManager(address _target, bool status) public onlyOwner {
        manager[_target] = status;
    }

    function isManager(address _target) public view returns (bool) {
        return manager[_target];
    }

    modifier onlyManager() {
        if (manager[msg.sender] != true) {
            revert();
        }
        _;
    }
}
contract GIDS{
    //input properties 
    struct _propInput{
        string name;
        uint256 value;
    }
    //input infor 
    struct _inforInput{
        string name;
        string value;
    }
    //properties 
    struct _prop{
        uint256 id;
        string name;
        uint256 value;
    }
    //information
    struct _infor{
        uint256 id;
        string name;
        string value;
    }
    struct _properties{
        _prop[] prop;
        _infor[] infor;
    }
    
    //user address => item id => quantity
    mapping(address=>mapping(uint256=>uint256)) public balances;
    //owner => spender => status
    mapping(address=>mapping(address=>bool)) public allowAll;
    //owner => spender => item =>status
    mapping(address=>mapping(address=>mapping(uint256=>bool))) public allow;
    
    //current id item
    uint256 public itemId;
    uint256 public totalSupply;
    
    //id item => Current attribute id
    mapping(uint256=>uint256) public currentProp;
    //id item => name attribute => value;
    mapping(uint256=>mapping(string=>_prop)) public properties;
    //id item => key => name attribute 
    mapping(uint256=>mapping(uint256=>string)) public key;

    
    //id item => Current information id
    mapping(uint256=>uint256) public currentInfor;
    //id item => name attribute => value
    mapping(uint256=>mapping(string=>_infor)) public information;
    //id item => key => name attribute
    mapping(uint256=>mapping(uint256=>string)) public keyInfor;
    
    
    event Transfer(address indexed from, address indexed to, uint256 indexed id, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, bool status);
    event ApprovalAll(address indexed owner, address indexed spender, bool status);
    event Create(address indexed creater, address indexed to, uint256 indexed id, _propInput[] prop, _inforInput[] infor, uint256 value);
}
contract Basic is GIDS, Manager{
    //Get attribute value
    function getProp(string memory name, uint256 id) public view returns(uint256){
        return properties[id][name].value;
    }
    //Get information value
    function getInfor(string memory name, uint256 id) public view returns(string memory){
        return information[id][name].value;
    }
    
    //balance of
    function balanceOf(address owner, uint256 id) public view returns(uint256){
        return balances[owner][id];
    }
    //allowance
    function allowance(address owner, uint256 id, address spender) public view returns (bool status) {
        if(allow[owner][spender][id]==false && allowAll[owner][spender]==false){
            return false;
        }
        return true;
    }
    function transfer(address to, uint256 id, uint256 quantity) public{
            require (balances[msg.sender][id]>=quantity&&quantity>0&&balances[to][id]+quantity>balances[to][id]);
            balances[msg.sender][id]-=quantity;
            balances[to][id]+=quantity;
            emit Transfer(msg.sender,to,id,quantity);
    }
    //transfer from
    function transferFrom(address from, address to, uint256 id, uint256 quantity) public{
        require(allow[from][msg.sender][id]==true || allowAll[from][msg.sender]==true,"Not Allow");
        require (balances[from][id]>=quantity&&quantity>0&&balances[to][id]+quantity>balances[to][id]);
        balances[from][id]-=quantity;
        balances[to][id]+=quantity;
        emit Transfer(from, to, id, quantity);
    }
    //approve
    function approve(address spender, uint256 id, bool status) public{
        allow[msg.sender][spender][id]=status;
        emit Approval(msg.sender, spender, id, status);
    }
    function approveAll(address spender, bool status) public{
        allowAll[msg.sender][spender]=status;
        emit ApprovalAll(msg.sender, spender, status);
    }
    
    //create new item
    function create(address to, _propInput[] memory prop, _inforInput[] memory infor, uint256 quantity) public onlyManager{
        require(prop.length>0 || infor.length>0,"Invalid input!");
        uint256 nextId = itemId+1;
        uint256 count = prop.length;
        uint256 countInfor = infor.length;
        uint256 i;
        uint256 j;
        
        totalSupply=totalSupply+quantity;
        
        itemId = nextId;
        //add attribute
        for(i=0;i<count;i++){
            properties[nextId][prop[i].name]=_prop(i+1, prop[i].name, prop[i].value);
            key[nextId][i+1]=prop[i].name;
        }
        currentProp[nextId] = count;
        //add extended infor
        for(j=0;j<countInfor;j++){
            information[nextId][infor[j].name]=_infor(j+1, infor[j].name, infor[j].value);
            keyInfor[nextId][j+1]=infor[j].name;
        }
        currentInfor[nextId] = countInfor;
        
        balances[to][nextId]=quantity;
        emit Create(msg.sender, to, nextId, prop, infor, quantity);
        emit Transfer(address(0), to, nextId, quantity);
    }
    //mint item
    function mint(address to, uint256 id, uint256 quantity) public onlyManager{
        require(quantity>0,"Require - Quantity>0!");
        require(currentProp[id]>0 || currentInfor[id]>0, "Unknown item!");
        balances[to][id]+=quantity;
        
        _prop memory supplyAttr = properties[id]["totalSupply"];
        properties[id]["totalSupply"]=_prop(supplyAttr.id, supplyAttr.name, supplyAttr.value+quantity);
        emit Transfer(address(0), to, id, quantity);
    }
}
contract Advanced is Basic{
    //get attribute item
    function getItem(uint256 id) public view returns(_properties memory){
        _prop[] memory a = new _prop[](currentProp[id]);
        _infor[] memory b = new _infor[](currentInfor[id]);
        
        for(uint256 i=1;i<=currentProp[id];i++){
            string memory name = key[id][i];
            a[i-1]=properties[id][name];
        }
        for(uint256 j=1;j<=currentInfor[id];j++){
            string memory name = keyInfor[id][j];
            b[j-1] = information[id][name];
        }
        return _properties(a, b);
    }
    //get attribute items
    function getItems(uint256[] memory id) public view returns(_properties[] memory){
        uint256 i;
        uint256 count = id.length;
        _properties[] memory all = new _properties[](count);
        for(i=0;i<count;i++){
            all[i] = getItem(id[i]);
        }
        return all;
    }
    //multi send
    function multiTransfer(address[] memory to, uint256[] memory id, uint256[] memory quantity) public{
        uint256 count = to.length;
        uint256 i;
        require(count == id.length && count == quantity.length, "Data of different lengths!");
        for(i=0;i<count;i++){
            transfer(to[i], id[i], quantity[i]);
        }
    }

    //add new attribute
    function createNewProp(uint256 id, string memory name, uint256 value) public onlyManager{
        uint256 propId = properties[id][name].id;
        if(propId==0 && bytes(name).length>0){
            uint256 newId = currentProp[id]+1;
            currentProp[id] = newId;
            properties[id][name]=_prop(newId, name, value);
            key[id][newId]=name;
        }
    }
    //update attribute
    function updateProp(uint256 id, string memory name, uint256 value, string memory newKey) public onlyManager{
        uint256 propId = properties[id][name].id;
        if(propId>0 && bytes(name).length>0){
            if(bytes(newKey).length>0){
                key[id][propId]=newKey;
                //reset old attribute
                properties[id][name]=_prop(0, '', 0);
                //set new attribute
                properties[id][newKey]=_prop(propId, newKey, value);
            }
            else{
                properties[id][name]=_prop(propId, name, value);
            }
        }
    }
    
    //add new information
    function createNewInfor(uint256 id, string memory name, string memory value) public onlyManager{
        uint256 inforId = information[id][name].id;
        if(inforId==0 && bytes(name).length>0){
            uint256 newId = currentInfor[id]+1;
            currentInfor[id]=newId;
            
            information[id][name]=_infor(newId, name, value);
            keyInfor[id][newId]=name;
        }
    }
    //update information
    function updateInfor(uint256 id, string memory name, string memory value, string memory newKey) public onlyManager{
        uint256 inforId = information[id][name].id;
         if(inforId>0 && bytes(name).length>0){
            if(bytes(newKey).length>0){
                keyInfor[id][inforId]=newKey;
                //reset old attribute
                information[id][name]=_infor(0,'','');
                //set new attribute
                information[id][newKey]=_infor(inforId, newKey, value);
            }
            else{
                information[id][name]=_infor(inforId, name, value);
            }
         }
    }
    //list prop of items
    // my items
    struct _userItem{
        _prop[] prop;
        _infor[] infor;
        uint256 quantity;
    }
    
    function getUserItem(address owner) public view returns(_userItem[] memory){
        uint256 i;
        uint256 size;
        for(i=0;i<itemId;i++){
            if(balanceOf(owner,i+1)>0){
                size++;
            }
        }
        _userItem[] memory all = new _userItem[](size);
        uint256 k=0;
        for(i=0;i<itemId;i++){
            if(balanceOf(owner,i+1)>0){
                all[k]=_userItem(getItem(i+1).prop, getItem(i+1).infor, balanceOf(owner,i+1));
                k++;
            }
        }
        return all;
    }
}