pragma solidity ^0.4.25;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
              return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
contract IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
contract ERC165 is IERC165 {
    mapping(bytes4 => bool) internal _supportedInterfaces;
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    constructor() public {
        _registerInterface(_InterfaceId_ERC165);
    }
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return _supportedInterfaces[interfaceID];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}
contract IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}
contract ERC721Receiver is IERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4) {
        return this.onERC721Received.selector;
    }
}
contract IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function approve(address _approved, uint256 _tokenId) public payable;
    function getApproved(uint256 _tokenId) public view returns (address);
    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;    
}
contract ERC721 is IERC721,ERC165 {

    using SafeMath for uint256;
    using Address for address;
    
    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Mapping from token ID to owner
    mapping (uint256 => address) public _tokenOwner;
    // Mapping from owner to number of owned token
    mapping (address => uint256) public _ownedTokensCount;
    // Mapping from token ID to approved address
    mapping (uint256 => address) public _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) public _operatorApprovals;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
     *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
     *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
     *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
    */
    constructor() public {
        _registerInterface(_InterfaceId_ERC721);
    }
    function balanceOf(address _owner) public view returns (uint256){
        require(_owner != address(0));
        return _ownedTokensCount[_owner];
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }
    function approve(address to, uint256 tokenId) public payable {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));

        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
        // solium-disable-next-line arg-overflow
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes _data) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
    function _clearApproval(address owner, uint256 tokenId) public {
        require(ownerOf(tokenId) == owner);
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
contract Owned {
	address public owner;
	constructor() public {
		owner = msg.sender;
		owner = 0x5d6f5579e115bca2dc3411d028304ec70c6d4741;
	}
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}
contract ERC721token is ERC721,Owned {
    uint256 public totalSupply = 0;
    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;
    
    string public constant name = "T513 Tea Token";
    string public constant symbol = "T513";
    
    bool public pause=false;
    mapping(address => bool) internal lockAddresses;
    mapping(uint256 => bool) internal burned;
    
    struct T513{
        uint256 yr;     //year;
        uint256 weight; //gram;
    }
    T513[] T513s;
     
    function constructor(){
        createT513(2018,msg.sender);
        createT513(2018,msg.sender);
        createT513(2018,0x5d6f5579e115bca2dc3411d028304ec70c6d4741);
        createT513(2018,0x5d6f5579e115bca2dc3411d028304ec70c6d4741);
        createT513(2018,0x5d6f5579e115bca2dc3411d028304ec70c6d4741);
        createT513(2018,0x5d6f5579e115bca2dc3411d028304ec70c6d4741);
        createT513(2018,0x5d6f5579e115bca2dc3411d028304ec70c6d4741);
    }
    
    event CreateT513(uint256 _yr,uint256 _amount);
    function createT513(uint256 _yr,address _owner) public onlyOwner{
        uint256 _id = totalSupply.add(1);
        totalSupply = totalSupply.add(1);
        _ownedTokensCount[_owner] = _ownedTokensCount[_owner].add(1);
        _tokenOwner[_id] = _owner;
        T513 memory _newT = T513({yr:_yr,weight:10});
        T513s.push(_newT);
        emit CreateT513(_yr,1);
    }
    function createT513many(uint256 _amount,uint256 _yr,address _owner) public onlyOwner{
        for(uint256 _id=totalSupply.add(1) ; _id<=totalSupply.add(_amount) ; _id++){
            _tokenOwner[_id] = _owner;
            T513 memory _newT = T513({yr:_yr,weight:10});
            T513s.push(_newT);            
        }
        totalSupply = totalSupply.add(_amount);
        _ownedTokensCount[_owner] = _ownedTokensCount[_owner].add(_amount);
        emit CreateT513(_yr,_amount);
    }

    event Burn(address _owner,uint256 _tokenId);
    function burn(address _owner, uint256 _tokenId) public onlyOwner {
        _clearApproval(_owner, _tokenId);
        _removeTokenFrom(_owner, _tokenId);
        burned[_tokenId] = true;
        emit Burn(_owner, _tokenId);
    }
    

    /////////////////////////////////////////////////////////////////////
    //////////////// Pause contract ; lock address //////////////////////
    /////////////////////////////////////////////////////////////////////     
    // pause all the transfer on the contract
    event PauseContract();
    function pauseContract() public onlyOwner{
        pause = true;
        emit PauseContract();
    }
    event ResumeContract();
    function resumeContract() public onlyOwner{
        pause = false;
        emit ResumeContract();
    }
    function is_contract_paused() public view returns(bool){
        return pause;
    }
    // lock one&#39;s wallet
    event Lock(address _addr);
    function lock(address _addr) public onlyOwner{
        lockAddresses[_addr] = true;
        emit Lock(_addr);
    }
    event Unlock(address _addr);
    function unlock(address _addr) public onlyOwner{
        lockAddresses[_addr] = false; 
        emit Unlock(_addr);
    }
    function am_I_locked(address _addr) public view returns(bool){
    	return lockAddresses[_addr];
    }

    /////////////////////////////////////////////////////////////////////
    ///////////////// ERC721 function overloading ///////////////////////
    ///////////////////////////////////////////////////////////////////// 
    modifier transferable(address _addr,uint256 tokenId){
        require(!pause);
    	require(!lockAddresses[_addr]);
        require(!burned[tokenId]);
    	_;
    }
    function transferFrom(address from, address to, uint256 tokenId) public transferable(from,tokenId) {
        super.transferFrom(from,to,tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public transferable(from,tokenId) {
        super.safeTransferFrom(from,to,tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public transferable(from,tokenId) {
        super.safeTransferFrom(from,to,tokenId,_data);
    }
    
    
}