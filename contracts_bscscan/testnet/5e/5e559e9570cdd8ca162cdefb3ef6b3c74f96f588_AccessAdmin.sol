/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

pragma solidity >=0.5.0 <0.6.0;

//721协议
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

//165协议
interface ERC165{
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _from, uint256 _tokenId, bytes calldata data) external returns(bytes4);
}

contract AccessAdmin{
    bool public isPaused = false;
    address public adminAddr;

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        adminAddr = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddr);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(adminAddr, _newAdmin);
        adminAddr = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract SpecialSoldiers is ERC721,AccessAdmin {
    //物品
    struct Item{
        uint256 itemMainType;
        uint256 itemSubtype;
        uint16 itemLevel;
        uint16 itemQuality;
        uint16 itemPhase; 
        uint64 createTime;
        uint64 updateTime;
        uint16 updateCNT;
        uint256 attr1;
        uint256 attr2;
        uint256 attr3;
        uint256 attr4;
        uint256 attr5;
    }

    //物品数组
    Item[] public itemArray; //item ID is the index in this array
    //每个地址拥有的物品的个数
    mapping (address => uint256) public ownershipTokenCount;
    //物品id到地址的mapping地址
    mapping (uint256 => address) public ItemIDToOwner;
    //临时具有操作物品tansfer权限的地址
    mapping (uint256 => address) public ItemIDToApproved;
    //具有对某个地址下所有物品transfer权限的地址
    mapping (address => mapping (address => bool)) operatorToApprovals;
    //信任的地址,官方地址,或者其他合约地址
    mapping (address => bool) trustAddr;
    //物品加锁
    mapping (uint256 => bool) public itemLocked;

    //用来查询合约支持的协议,和实现的协议方法
    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));
    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('setApprovalForAll(address,bool)')) ^
        bytes4(keccak256('getApproved(uint256)')) ^
        bytes4(keccak256('isApprovedForAll(address,address)'));

    //定义通知
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event ItemUpdate(address  _owner,uint256  _itemID);
    event ItemCreate(address  _owner,uint256  _itemID);
    event ItemUnlock(address _caller,address _owner,uint256  _itemID);

    //构造函数
    constructor() public{
        adminAddr = msg.sender;
    }

    //修饰函数,用来在函数执行前判断一些条件
    modifier isValidToken(uint256 _tokenID) {
        require(_tokenID >= 0 && _tokenID <= itemArray.length);
        require(ItemIDToOwner[_tokenID] != address(0));
        _;
    }

    modifier isItemLock(uint256 _tokenID) {
        require(itemLocked[_tokenID]);
        _;
    }

    modifier isItemUnlock(uint256 _tokenID) {
        require(!itemLocked[_tokenID]);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = ItemIDToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == ItemIDToApproved[_tokenId] || operatorToApprovals[owner][msg.sender]);
        _;
    }

    //用于获取itemArray的长度
    function getitemArrayLength() external view returns(uint256){
        return(itemArray.length);
    }

    //用于链上查询合约支持的协议
    function supportsInterface(bytes4 _interfaceId) external pure  returns(bool) {
        return ((_interfaceId == InterfaceSignature_ERC165) || (_interfaceId == InterfaceSignature_ERC721));
    }

    function setTrustAddr(address _addr,bool _trust) external onlyAdmin{
        require(_addr != address(0));
        trustAddr[_addr] = _trust;
    }

    function getTrustAddr(address _addr) external view onlyAdmin returns(bool){
        return (trustAddr[_addr]);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        ItemIDToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete ItemIDToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    //更新物品的状态
    function updateItem(uint256 _tp,uint256 _subTp,uint16 _level,uint256[5] calldata _attr,uint16 _quality,uint16 _phase,uint256 _tokenId) external whenNotPaused isValidToken(_tokenId) isItemUnlock(_tokenId){
        require(msg.sender==adminAddr || trustAddr[msg.sender]);
        
        itemArray[_tokenId].itemMainType = _tp;
        itemArray[_tokenId].itemSubtype = _subTp;
        itemArray[_tokenId].itemLevel = _level;
        itemArray[_tokenId].itemQuality = _quality;
        itemArray[_tokenId].itemPhase = _phase;
        itemArray[_tokenId].updateTime = uint64(now);
        itemArray[_tokenId].updateCNT += 1;
        itemArray[_tokenId].attr1 = _attr[0];
        itemArray[_tokenId].attr2 = _attr[1];
        itemArray[_tokenId].attr3 = _attr[2];
        itemArray[_tokenId].attr4 = _attr[3];
        itemArray[_tokenId].attr5 = _attr[4];

        address owner = ItemIDToOwner[_tokenId];
        itemLocked[_tokenId] = true;
        emit ItemUpdate(owner,_tokenId);
    }
    
    //创建物品
    function createNewItem(uint256 _tp,uint256 _subTp,address _owner,uint256[5] calldata _attr,uint16 _quality,uint16 _phase) external whenNotPaused {
        require(msg.sender==adminAddr || trustAddr[msg.sender]);
        require(_owner != address(0));
        require(itemArray.length < 4294967296);
        
        uint64 currentTime = uint64(now);
        Item memory _newItem = Item({
            itemMainType: _tp,
            itemSubtype: _subTp,
            itemLevel: 1,
            itemQuality:_quality,
            itemPhase:_phase,
            createTime:currentTime,
            updateTime:currentTime,
            updateCNT:0,
            attr1:_attr[0],
            attr2:_attr[1],
            attr3:_attr[2],
            attr4:_attr[3],
            attr5:_attr[4]
        });
        uint256 newItemID = itemArray.push(_newItem) - 1;
        itemLocked[newItemID] = true;
        
        _transfer(address(0), _owner, newItemID);
        emit ItemCreate(_owner,newItemID);
    }

    //物品解锁,解锁后才能更新状态
    function unLockedItem(uint256 _tokenId) external whenNotPaused isValidToken(_tokenId) isItemLock(_tokenId) {
        require(msg.sender==adminAddr || trustAddr[msg.sender]);
        address owner = ItemIDToOwner[_tokenId];
        itemLocked[_tokenId] = false;
        emit ItemUnlock(msg.sender,owner,_tokenId);
    }

    //某个地址所有物品个数
    function balanceOf(address _owner) external view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    //某个物品所属地址
    function ownerOf(uint256 _tokenId) external view returns (address owner)
    {
        owner = ItemIDToOwner[_tokenId];

        require(owner != address(0));
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) internal isValidToken(_tokenId) canTransfer(_tokenId){
        _transfer(_from, _to, _tokenId);

        //only call onERC721Received when _to is a contract address
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }

        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
        // bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
        require(retval == 0xf0b9e5ba);
    }

    //合约之间的物品的transfer,对方合约需要要支持721协议,要做onERC721Received判断
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external whenNotPaused{
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused{
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    //物品的transfer,到一个用户地址
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused isValidToken(_tokenId) canTransfer(_tokenId){
        address owner = ItemIDToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(_from == owner);
        _transfer(_from, _to, _tokenId);
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        ItemIDToApproved[_tokenId] = _approved;
    }

    //让另一个地址具有临时transfer物品的权限
    function approve(address _approved, uint256 _tokenId) external whenNotPaused{
        address owner = ItemIDToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        _approve(_tokenId, _approved);
        emit Approval(msg.sender,  _approved, _tokenId);
    }

    //让另一个地址具有transfer当前地址内所有物品的权限
    function setApprovalForAll(address _operator, bool _approved) external whenNotPaused{
        require(_operator != address(0));
        operatorToApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address){
        return ItemIDToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return operatorToApprovals[_owner][_operator];
    }
}