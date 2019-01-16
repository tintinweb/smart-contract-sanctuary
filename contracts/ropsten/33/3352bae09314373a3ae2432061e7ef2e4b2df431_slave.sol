pragma solidity ^0.4.25;

//2019.01.15
///設定合約管理者為master合約

contract owned {
    address public master;
    address public contract_owner;

    constructor() public{
        master = 0x0; //測試
        contract_owner = msg.sender;
    }

    modifier onlyMaster{
        require(msg.sender == master);
        _;
    }

    modifier onlyowner{
        require(msg.sender == contract_owner);
        _;
    }

    function transferMastership(address new_master) public onlyMaster {
        master = new_master;
    }

    function transferownership(address new_owner) public onlyowner {
        contract_owner = new_owner;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}


///ERC20 interface
interface ERC20_interface {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns(bool);
}

///ERC20 標準
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeMath{
    
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    
 }
 
 library SafeMath16{
     function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        require(c >= a);

        return c;
    }
    
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b <= a);
        uint16 c = a - b;
        return c;
    }
    
     function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b > 0);
        uint16 c = a / b;
        return c;
    }
 }

///ERC721標準
contract ERC721{

     event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
     event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
     event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     function balanceOf(address _owner) public view returns (uint256);
     function ownerOf(uint256 _tokenId) public view returns (address);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public payable;
     function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;
     function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
     function approve(address _approved, uint256 _tokenId) external payable;
     function setApprovalForAll(address _operator, bool _approved) external;
     function getApproved(uint256 _tokenId) public view returns (address);
     function isApprovedForAll(address _owner, address _operator) public view returns (bool);
 }

contract external_function{
    function inquire_totdomains_amount() public view returns(uint);
    function inquire_domain_id(uint16 _citys, uint16 _domains) public pure returns(uint);
    
    function domain_build(address _user, uint16 _id, uint8 _index, uint8 _building) external;
    function domain_reward(address _user, uint16 _id) external;
    function transfer_master(address _user, address _to, uint _id) public;
    function retrieve_domain(address _user, uint _id) external;
}



contract slave is ERC165, ERC721, external_function, owned{
    
    constructor() public{
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721);
    }
    
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using Address for address;
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;


    // Mapping from owner to number of owned domain
    mapping (address => uint256) private owned_domain_amount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    string public Area_name = "魔幻魔法區";
    uint public Area_number = 1; //給主合約辨識，每個Area編號不能重複

    struct domain{
        address owner; //領土擁有者
        address backup; //避免擁有者丟失地址
        address approvals; //轉移權所有者 (ERC721標準)
        uint8 level; //等級
        uint8[] building; //建築(開始時四座建築) 
        uint cooltime; //收割冷卻結束時間
    }

    uint public building_amount = 4;
    uint every_cooltime = 86400;

    struct city_info{
        address mayor; //市長
    }
    
    uint16 public citys_amount = 4; //每個區域城市數量
    uint16 public domains_amount = 100; //每個城市土地數量
    
    domain[400] private citys; //一個區域有400個土地

//manage
    function set_building_amount(uint _building_amount) public onlyowner{
        building_amount = _building_amount;
    }

    function set_Area_name(string _Area_name) public onlyowner{
        Area_name = _Area_name;
    }

//inquire function
    function inquire_totdomains_amount() public view returns(uint){
      return citys.length;
    }//查詢共有幾座城市

    function inquire_domain_id(uint16 _citys, uint16 _domains) public pure returns(uint){
        return _citys.mul(_domains).sub(1);
    }


//external function

    function domain_build(address _user, uint16 _id, uint8 _index, uint8 _building) external onlyMaster{
        require(_index <= building_amount);
        require(citys[_id].owner == _user);
        citys[_id].building[_index] = _building;
    }//建立城市

    function domain_reward(address _user, uint16 _id) external onlyMaster{
        require(citys[_id].owner == _user);
        require(citys[_id].cooltime <= now);
        citys[_id].cooltime = now.add(every_cooltime);
        _user.transfer(0);
        //測試版暫不實做
    }//領取領土獎勵

    function transfer_master(address _user, address _to, uint _id) public onlyMaster{
        require(_user == citys[_id].owner);
        emit Transfer(_user, _to, _id);
    }//透過master合約執行的轉移
/*
    function domain_buy_useArina() external onlyMaster{

    }
*/
    function retrieve_domain(address _user, uint _id) external onlyMaster{
        require(_user == citys[_id].backup);
        citys[_id].owner;
        transfer_master(citys[_id].owner, contract_owner, _id);
        emit Transfer(citys[_id].owner, contract_owner, _id);
    }//領土遺失領回



//ERC721 function
    function balanceOf(address _owner) public view returns (uint256){
        require(_owner != address(0));
        return owned_domain_amount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns (address){
        address owner = citys[_tokenId].owner;
        require(owner != address(0));
        return owner;
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public payable{
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data));
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable{
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _transferFrom(_from, _to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) external payable{
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        citys[_tokenId].approvals = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) public view returns (address){
        require(_exists(_tokenId));
        return citys[_tokenId].approvals;
    }
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }
    
    function _exists(uint256 _tokenId) internal view returns (bool) {
        address owner = citys[_tokenId].owner;
        return owner != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }
    
    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApproval(_tokenId);

        owned_domain_amount[_from] = owned_domain_amount[_from].sub(1);
        owned_domain_amount[_to] = owned_domain_amount[_to].add(1);

        citys[_tokenId].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }
    
    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 _tokenId) private {
        if (citys[_tokenId].approvals != address(0)) {
            citys[_tokenId].approvals = address(0);
        }
    }


}