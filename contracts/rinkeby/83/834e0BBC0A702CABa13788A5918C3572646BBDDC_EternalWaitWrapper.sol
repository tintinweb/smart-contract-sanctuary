/**
 * @dev original contract...
 */
interface IEternalWait {
	function _dateTimeContract() external pure returns (address);
	function _defaultOwner() external pure returns (address);
	function _getFinalized(uint256 niftyType) external pure returns (bool);
	function _id() external pure returns (uint256);
    function _mintCount(uint256 niftyType) external view returns (uint256);
    function _typeCount() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function creator() external pure returns (string memory);
    function name() external view returns (string memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenIPFSHash(uint256 tokenId) external view returns (string memory);
    function tokenName(uint256 tokenId) external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IDateTime {
    function getHour(uint timestamp) external view returns (uint8);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract EternalWaitWrapper {

	IEternalWait _eternalWait;

	address internal _eternalWaitContract;

    mapping (uint256 => address) internal _owners;
    mapping (address => uint256) internal _balances;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

	constructor() {
        //_eternalWaitContract = 0x1d57A4C1D91F617E42D1B103895a673A60631abF; //Mainnet
        _eternalWaitContract = 0xA8641aFB0802708F7b0D3aFE15FE80B939ea3e00; //Rinkeby
        _eternalWait = IEternalWait(_eternalWaitContract);      
    }

    // READ

    function _dateTimeContract() public view returns (address) {
    	return _eternalWait._dateTimeContract();
    }

    function _defaultOwner() public view returns (address) {
    	return _eternalWait._defaultOwner();
    }

    function _getFinalized(uint256 niftyType) public view returns (bool) {
    	return _eternalWait._getFinalized(niftyType);
    }

    function _id() public view returns (uint256) {
    	return _eternalWait._id();
    }

    function _mintCount(uint256 niftyType) public view returns (uint256) {
    	return _eternalWait._mintCount(niftyType);
    }

    function _typeCount() public view returns (uint256) {
    	return _eternalWait._typeCount();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
    	return _eternalWait.balanceOf(owner);
    }

    function creator() public view virtual returns (string memory) {
    	return _eternalWait.creator();
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
    	require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function name() public view virtual returns (string memory) {
    	return _eternalWait.name();
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    	return _eternalWait.supportsInterface(interfaceId);
    }

    function symbol() public view virtual returns (string memory) {
    	return _eternalWait.symbol();
    }

    function tokenIPFSHash(uint256 tokenId, uint256 param) external view returns (string memory) {
    	uint8 hour = IDateTime(_dateTimeContract()).getHour(block.timestamp);
    	if(hour == param){
    		return "QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    	}
    	return _eternalWait.tokenIPFSHash(tokenId);
    }

    function tokenName(uint256 tokenId) external view returns (string memory) {
    	return _eternalWait.tokenName(tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
    	return _eternalWait.tokenURI(tokenId);
    }

    // Write

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);

        // Clear approvals
        approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }


    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

	//uint256 tokenId00 = 100010001;
    //uint256 tokenId01 = 100010080;
    function mintNifty(uint256 tokenId) public {  
    	require(!_exists(tokenId), "EternalWaitWrapper: tokenId already minted");

        address holder = _eternalWait.ownerOf(tokenId);
        address sender = _msgSender();
        address burner = 0x000000000000000000000000000000000000dEaD;
        
        if(sender == holder){

        	address operator = _eternalWait.getApproved(tokenId);
        	require(operator == address(this), "EternalWaitWrapper: set approval on EternalWait");

        	_eternalWait.transferFrom(address(this), burner, tokenId);
        	
        	_owners[tokenId] = sender;
        	_balances[sender] += 1;
        	emit Transfer(address(0), sender, tokenId);
        }
        
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

}

