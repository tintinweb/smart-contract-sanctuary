pragma solidity ^0.4.19;

contract ADM312 {

  address public COO;
  address public CTO;
  address public CFO;
  address private coreAddress;
  address public logicAddress;
  address public superAddress;

  modifier onlyAdmin() {
    require(msg.sender == COO || msg.sender == CTO || msg.sender == CFO);
    _;
  }
  
  modifier onlyContract() {
    require(msg.sender == coreAddress || msg.sender == logicAddress || msg.sender == superAddress);
    _;
  }
    
  modifier onlyContractAdmin() {
    require(msg.sender == coreAddress || msg.sender == logicAddress || msg.sender == superAddress || msg.sender == COO || msg.sender == CTO || msg.sender == CFO);
     _;
  }
  
  function transferAdmin(address _newAdminAddress1, address _newAdminAddress2) public onlyAdmin {
    if(msg.sender == COO)
    {
        CTO = _newAdminAddress1;
        CFO = _newAdminAddress2;
    }
    if(msg.sender == CTO)
    {
        COO = _newAdminAddress1;
        CFO = _newAdminAddress2;
    }
    if(msg.sender == CFO)
    {
        COO = _newAdminAddress1;
        CTO = _newAdminAddress2;
    }
  }
  
  function transferContract(address _newCoreAddress, address _newLogicAddress, address _newSuperAddress) external onlyAdmin {
    coreAddress  = _newCoreAddress;
    logicAddress = _newLogicAddress;
    superAddress = _newSuperAddress;
    SetCoreInterface(_newLogicAddress).setCoreContract(_newCoreAddress);
    SetCoreInterface(_newSuperAddress).setCoreContract(_newCoreAddress);
  }


}

contract ERC721 {
    
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
  
}

contract SetCoreInterface {
   function setCoreContract(address _neWCoreAddress) external; 
}

contract CaData is ADM312, ERC721 {
    
    function CaData() public {
        COO = msg.sender;
        CTO = msg.sender;
        CFO = msg.sender;
        createCustomAtom(0,0,4,0,0,0,0);
    }
    
    function kill() external
	{
	    require(msg.sender == COO);
		selfdestruct(msg.sender);
	}
    
    function() public payable{}
    
    uint public randNonce  = 0;
    
    struct Atom 
    {
      uint64   dna;
      uint8    gen;
      uint8    lev;
      uint8    cool;
      uint32   sons;
      uint64   fath;
	  uint64   moth;
	  uint128  isRent;
	  uint128  isBuy;
	  uint32   isReady;
    }
    
    Atom[] public atoms;
    
    mapping (uint64  => bool) public dnaExist;
    mapping (address => bool) public bonusReceived;
    mapping (address => uint) public ownerAtomsCount;
    mapping (uint => address) public atomOwner;
    
    event NewWithdraw(address sender, uint balance);
    
    function createCustomAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint128 _isRent, uint128 _isBuy, uint32 _isReady) public onlyAdmin {
        require(dnaExist[_dna]==false && _cool+_lev>=4);
        Atom memory newAtom = Atom(_dna, _gen, _lev, _cool, 0, 2**50, 2**50, _isRent, _isBuy, _isReady);
        uint id = atoms.push(newAtom) - 1;
        atomOwner[id] = msg.sender;
        ownerAtomsCount[msg.sender]++;
        dnaExist[_dna] = true;
    }
    
    function withdrawBalance() public payable onlyAdmin {
		NewWithdraw(msg.sender, address(this).balance);
        CFO.transfer(address(this).balance);
    }
        
    function incRandNonce() external onlyContract {
        randNonce++;
    }
    
    function setDnaExist(uint64 _dna, bool _newDnaLocking) external onlyContractAdmin {
        dnaExist[_dna] = _newDnaLocking;
    }
    
    function setBonusReceived(address _add, bool _newBonusLocking) external onlyContractAdmin {
        bonusReceived[_add] = _newBonusLocking;
    }
    
    function setOwnerAtomsCount(address _owner, uint _newCount) external onlyContract {
        ownerAtomsCount[_owner] = _newCount;
    }
    
    function setAtomOwner(uint _atomId, address _owner) external onlyContract {
        atomOwner[_atomId] = _owner;
    }
        
    function pushAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint32 _sons, uint64 _fathId, uint64 _mothId, uint128 _isRent, uint128 _isBuy, uint32 _isReady) external onlyContract returns (uint id) {
        Atom memory newAtom = Atom(_dna, _gen, _lev, _cool, _sons, _fathId, _mothId, _isRent, _isBuy, _isReady);
        id = atoms.push(newAtom) -1;
    }
	
	function setAtomDna(uint _atomId, uint64 _dna) external onlyAdmin {
        atoms[_atomId].dna = _dna;
    }
	
	function setAtomGen(uint _atomId, uint8 _gen) external onlyAdmin {
        atoms[_atomId].gen = _gen;
    }
    
    function setAtomLev(uint _atomId, uint8 _lev) external onlyContract {
        atoms[_atomId].lev = _lev;
    }
    
    function setAtomCool(uint _atomId, uint8 _cool) external onlyContract {
        atoms[_atomId].cool = _cool;
    }
    
    function setAtomSons(uint _atomId, uint32 _sons) external onlyContract {
        atoms[_atomId].sons = _sons;
    }
    
    function setAtomFath(uint _atomId, uint64 _fath) external onlyContract {
        atoms[_atomId].fath = _fath;
    }
    
    function setAtomMoth(uint _atomId, uint64 _moth) external onlyContract {
        atoms[_atomId].moth = _moth;
    }
    
    function setAtomIsRent(uint _atomId, uint128 _isRent) external onlyContract {
        atoms[_atomId].isRent = _isRent;
    }
    
    function setAtomIsBuy(uint _atomId, uint128 _isBuy) external onlyContract {
        atoms[_atomId].isBuy = _isBuy;
    }
    
    function setAtomIsReady(uint _atomId, uint32 _isReady) external onlyContractAdmin {
        atoms[_atomId].isReady = _isReady;
    }
    
    //ERC721
    
    mapping (uint => address) tokenApprovals;
    
    function totalSupply() public view returns (uint256 total){
  	    return atoms.length;
  	}
  	
  	function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerAtomsCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return atomOwner[_tokenId];
    }
      
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        atoms[_tokenId].isBuy  = 0;
        atoms[_tokenId].isRent = 0;
        ownerAtomsCount[_to]++;
        ownerAtomsCount[_from]--;
        atomOwner[_tokenId] = _to;
        Transfer(_from, _to, _tokenId);
    }
  
    function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == atomOwner[_tokenId]);
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == atomOwner[_tokenId]);
        tokenApprovals[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    
    function takeOwnership(uint256 _tokenId) public {
        require(tokenApprovals[_tokenId] == msg.sender);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
}

contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

interface ERC721Metadata {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}
          
contract CryptoAtomsToken is Ownable {
    
    address public CaDataAddress = 0x9b3554E6FC4F81531F6D43b611258bd1058ef6D5;
    CaData public CaDataContract = CaData(CaDataAddress);

    function kill() external
	{
	    require(msg.sender == CaDataContract.COO());
		selfdestruct(msg.sender);
	}
    
    function() public payable{}
    
    function withdrawBalance() public payable {
        require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
        CaDataContract.CFO().transfer(address(this).balance);
    }
    
    mapping (address => bool) transferEmittables;
    
    function setTransferEmittables(address _addr, bool _bool) external {
        require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
        transferEmittables[_addr] = _bool;
    }
    
    function emitTransfer(address _from, address _to, uint256 _tokenId) external{
        require(transferEmittables[msg.sender]);
        Transfer(_from, _to, _tokenId);
    }
    
    //ERC721
    
        event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
        event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
        mapping (uint => address) tokenApprovals;
        mapping (uint => address) tokenOperators;
        mapping (address => mapping (address => bool)) ownerOperators;
    
        function _transfer(address _from, address _to, uint256 _tokenId) private {
            CaDataContract.setAtomIsBuy(_tokenId,0);
            CaDataContract.setAtomIsRent(_tokenId,0);
            CaDataContract.setOwnerAtomsCount(_to,CaDataContract.ownerAtomsCount(_to)+1);
            CaDataContract.setOwnerAtomsCount(_from,CaDataContract.ownerAtomsCount(_from)-1);
            CaDataContract.setAtomOwner(_tokenId,_to);
            Transfer(_from, _to, _tokenId);
        }
        
        function _isContract(address _addr) private returns (bool check) {
            uint size;
            assembly { size := extcodesize(_addr) }
            return size > 0;
        }
        
      	function balanceOf(address _owner) external view returns (uint256 balance) {
            return CaDataContract.balanceOf(_owner);
        }
    
        function ownerOf(uint256 _tokenId) external view returns (address owner) {
            return CaDataContract.ownerOf(_tokenId);
        }
        
        /// @notice Transfers the ownership of an NFT from one address to another address
        /// @dev Throws unless `msg.sender` is the current owner, an authorized
        ///  operator, or the approved address for this NFT. Throws if `_from` is
        ///  not the current owner. Throws if `_to` is the zero address. Throws if
        ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
        ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
        ///  `onERC721Received` on `_to` and throws if the return value is not
        ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
        /// @param _from The current owner of the NFT
        /// @param _to The new owner
        /// @param _tokenId The NFT to transfer
        /// @param _data Additional data with no specified format, sent in call to `_to`
        function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable{
            require(msg.sender == CaDataContract.ownerOf(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender] == true || msg.sender == tokenApprovals[_tokenId]);
            require(_from == CaDataContract.ownerOf(_tokenId) && _to != 0x0);
            require(_tokenId < totalSupply());
            _transfer(_from, _to, _tokenId);
            if(_isContract(_to))
            {
                require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == ERC721_RECEIVED);
            }
        }
    
        /// @notice Transfers the ownership of an NFT from one address to another address
        /// @dev This works identically to the other function with an extra data parameter,
        ///  except this function just sets data to ""
        /// @param _from The current owner of the NFT
        /// @param _to The new owner
        /// @param _tokenId The NFT to transfer
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
            require(msg.sender == CaDataContract.ownerOf(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender] == true || msg.sender == tokenApprovals[_tokenId]);
            require(_from == CaDataContract.ownerOf(_tokenId) && _to != 0x0);
            require(_tokenId < totalSupply());
            _transfer(_from, _to, _tokenId);
            if(_isContract(_to))
            {
                require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") == ERC721_RECEIVED);
            }
        }
        
        
        /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
        ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
        ///  THEY MAY BE PERMANENTLY LOST
        /// @dev Throws unless `msg.sender` is the current owner, an authorized
        ///  operator, or the approved address for this NFT. Throws if `_from` is
        ///  not the current owner. Throws if `_to` is the zero address. Throws if
        ///  `_tokenId` is not a valid NFT.
        /// @param _from The current owner of the NFT
        /// @param _to The new owner
        /// @param _tokenId The NFT to transfer
        function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
            require(msg.sender == CaDataContract.ownerOf(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender] == true || msg.sender == tokenApprovals[_tokenId]);
            require(_from == CaDataContract.ownerOf(_tokenId) && _to != 0x0);
            require(_tokenId < totalSupply());
            _transfer(_from, _to, _tokenId);
        }
        
        
        /// @notice Set or reaffirm the approved address for an NFT
        /// @dev The zero address indicates there is no approved address.
        /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
        ///  operator of the current owner.
        /// @param _approved The new approved NFT controller
        /// @param _tokenId The NFT to approve
        function approve(address _approved, uint256 _tokenId) external payable {
            require(msg.sender == CaDataContract.atomOwner(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender]);
            tokenApprovals[_tokenId] = _approved;
            Approval(CaDataContract.atomOwner(_tokenId), _approved, _tokenId);
        }
        
        /// @notice Enable or disable approval for a third party ("operator") to manage
        ///  all of `msg.sender`&#39;s assets.
        /// @dev Emits the ApprovalForAll event. The contract MUST allow
        ///  multiple operators per owner.
        /// @param _operator Address to add to the set of authorized operators.
        /// @param _approved True if the operator is approved, false to revoke approval
        function setApprovalForAll(address _operator, bool _approved) external {
            ownerOperators[msg.sender][_operator] = _approved;
            ApprovalForAll(msg.sender, _operator, _approved);
        }
    
        /// @notice Get the approved address for a single NFT
        /// @dev Throws if `_tokenId` is not a valid NFT
        /// @param _tokenId The NFT to find the approved address for
        /// @return The approved address for this NFT, or the zero address if there is none
        function getApproved(uint256 _tokenId) external view returns (address) {
            return tokenApprovals[_tokenId];
        }
    
        /// @notice Query if an address is an authorized operator for another address
        /// @param _owner The address that owns the NFTs
        /// @param _operator The address that acts on behalf of the owner
        /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
        function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
            return ownerOperators[_owner][_operator];
        }
    
    //ERC165

        bytes4 constant Sign_ERC165 =
            bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
        
        bytes4 constant Sign_ERC721 =
            bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
            bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
            bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;)) ^
            bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
            bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
            bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
            bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
            bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
            bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;));
            
        function supportsInterface(bytes4 interfaceID) external view returns (bool)
        {
            return ((interfaceID == Sign_ERC165) || (interfaceID == Sign_ERC721));
        }
    
    //ERC721TokenReceiver
    
        /// @notice Handle the receipt of an NFT
        /// @dev The ERC721 smart contract calls this function on the
        /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
        /// of other than the magic value MUST result in the transaction being reverted.
        /// @notice The contract address is always the message sender. 
        /// @param _operator The address which called `safeTransferFrom` function
        /// @param _from The address which previously owned the token
        /// @param _tokenId The NFT identifier which is being transferred
        /// @param _data Additional data with no specified format
        /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
        /// unless throwing 
        
        bytes4 constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        
        function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4){
            return ERC721_RECEIVED;
        }
    
    //ERC721MetaData
    
        string baseUri = "https://www.cryptoatoms.org/cres/uri/";
    
        function name() external view returns (string _name) {
            return "Atom";
        }
    
        function symbol() external view returns (string _symbol){
            return "ATH";
        }
    
        /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
        /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
        ///  3986. The URI may point to a JSON file that conforms to the "ERC721
        ///  Metadata JSON Schema".
        function tokenURI(uint256 _tokenId) external view returns (string){
            require(_tokenId < totalSupply());
            uint256 uid;
            bytes32 bid;
            uid = _tokenId;
            if (uid == 0) 
            {
                bid = &#39;0&#39;;
            }
            else 
            {
                while (uid > 0) 
                {
                    bid = bytes32(uint(bid) / (2 ** 8));
                    bid |= bytes32(((uid % 10) + 48) * 2 ** (8 * 31));
                    uid /= 10;
                }
            }
            return string(abi.encodePacked(baseUri, bid));
        }
        
        function setBaseUri (string _newBaseUri) external {
            require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
            baseUri = _newBaseUri;
        }
    
    //ERC721Enumerable
        
        function totalSupply() public view returns (uint256 total){
      	    return CaDataContract.totalSupply();
      	}
      	   
      	/// @notice Enumerate valid NFTs
        /// @dev Throws if `_index` >= `totalSupply()`.
        /// @param _index A counter less than `totalSupply()`
        /// @return The token identifier for the `_index`th NFT,
        ///  (sort order not specified)
        function tokenByIndex(uint256 _index) external view returns (uint256){
            require(_index < totalSupply());
            return _index;
        }
    
        /// @notice Enumerate NFTs assigned to an owner
        /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
        ///  `_owner` is the zero address, representing invalid NFTs.
        /// @param _owner An address where we are interested in NFTs owned by them
        /// @param _index A counter less than `balanceOf(_owner)`
        /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
        ///   (sort order not specified)
        function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
            require(_index < CaDataContract.balanceOf(_owner));
            uint64 counter = 0;
            for (uint64 i = 0; i < CaDataContract.totalSupply(); i++)
            {
                if (CaDataContract.atomOwner(i) == _owner) {
                    if(counter == _index)
                    {
                        uint256 result = i;
                        i = uint64(CaDataContract.totalSupply());
                    }
                    else
                    {
                        counter++;
                    }
                }
            }
            return result;
        }
    
    
    //ERC20
        
        function decimals() external view returns (uint8 _decimals){
            return 0;
        }
        
        function implementsERC721() public pure returns (bool){
            return true;
        }
        
}