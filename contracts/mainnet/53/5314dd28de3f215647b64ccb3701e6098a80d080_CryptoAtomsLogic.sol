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

contract CaCoreInterface {
    function createCombinedAtom(uint, uint) external returns (uint);
    function createRandomAtom() external returns (uint);
}

contract CryptoAtomsLogic{
    
    address public CaDataAddress = 0x9b3554E6FC4F81531F6D43b611258bd1058ef6D5;
    CaData public CaDataContract = CaData(CaDataAddress);
    CaCoreInterface private CaCoreContract;
    
    bool public pauseMode = false;
    bool public bonusMode  = true;
    
    uint128   public newAtomFee = 1 finney;
    
    uint8[4]  public levelupValues  = [0, 
                                       2, 
                                       6, 
                                       12];

    event NewSetRent(address sender, uint atom);
    event NewSetBuy(address sender, uint atom);
    event NewUnsetRent(address sender, uint atom);
    event NewUnsetBuy(address sender, uint atom);
    event NewAutoRentAtom(address sender, uint atom);
    event NewRentAtom(address sender, uint atom, address receiver, uint amount);
    event NewBuyAtom(address sender, uint atom, address receiver, uint amount);
    event NewEvolveAtom(address sender, uint atom);
    event NewBonusAtom(address sender, uint atom);
    
    function() public payable{}
    
    function kill() external
	{
	    require(msg.sender == CaDataContract.CTO());
		selfdestruct(msg.sender); 
	}
	
	modifier onlyAdmin() {
      require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CFO() || msg.sender == CaDataContract.CTO());
      _;
     }
	
	modifier onlyActive() {
        require(pauseMode == false);
        _;
    }
    
    modifier onlyOwnerOf(uint _atomId, bool _flag) {
        require((msg.sender == CaDataContract.atomOwner(_atomId)) == _flag);
        _;
    }
    
    modifier onlyRenting(uint _atomId, bool _flag) {
        uint128 isRent;
        (,,,,,,,isRent,,) = CaDataContract.atoms(_atomId);
        require((isRent > 0) == _flag);
        _;
    }
    
    modifier onlyBuying(uint _atomId, bool _flag) {
        uint128 isBuy;
        (,,,,,,,,isBuy,) = CaDataContract.atoms(_atomId);
        require((isBuy > 0) == _flag);
        _;
    }
    
    modifier onlyReady(uint _atomId) {
        uint32 isReady;
        (,,,,,,,,,isReady) = CaDataContract.atoms(_atomId);
        require(isReady <= now);
        _;
    }
    
    modifier beDifferent(uint _atomId1, uint _atomId2) {
        require(_atomId1 != _atomId2);
        _;
    }
    
    function setCoreContract(address _neWCoreAddress) external {
        require(msg.sender == CaDataAddress);
        CaCoreContract = CaCoreInterface(_neWCoreAddress);
    }
    
    function setPauseMode(bool _newPauseMode) external onlyAdmin {
        pauseMode = _newPauseMode;
    }
    
    function setGiftMode(bool _newBonusMode) external onlyAdmin {
        bonusMode = _newBonusMode;
    }
    
    function setFee(uint128 _newFee) external onlyAdmin {
        newAtomFee = _newFee;
    }
    
    function setLevelup(uint8[4] _newLevelup) external onlyAdmin {
        levelupValues = _newLevelup;
    }
    
    function setIsRentByAtom(uint _atomId, uint128 _fee) external onlyActive onlyOwnerOf(_atomId,true) onlyRenting(_atomId, false) onlyReady(_atomId) {
	    require(_fee > 0);
	    CaDataContract.setAtomIsRent(_atomId,_fee);
	    NewSetRent(msg.sender,_atomId);
  	}
  	
  	function setIsBuyByAtom(uint _atomId, uint128 _fee) external onlyActive onlyOwnerOf(_atomId,true) onlyBuying(_atomId, false){
	    require(_fee > 0);
	    CaDataContract.setAtomIsBuy(_atomId,_fee);
	    NewSetBuy(msg.sender,_atomId);
  	}
  	
  	function unsetIsRentByAtom(uint _atomId) external onlyActive onlyOwnerOf(_atomId, true) onlyRenting(_atomId, true){
	    CaDataContract.setAtomIsRent(_atomId,0);
	    NewUnsetRent(msg.sender,_atomId);
  	}
  	
  	function unsetIsBuyByAtom(uint _atomId) external onlyActive onlyOwnerOf(_atomId, true) onlyBuying(_atomId, true){
	    CaDataContract.setAtomIsBuy(_atomId,0);
	    NewUnsetBuy(msg.sender,_atomId);
  	}
  	
  	function autoRentByAtom(uint _atomId, uint _ownedId) external payable onlyActive beDifferent(_atomId, _ownedId) onlyOwnerOf(_atomId, true) onlyOwnerOf(_ownedId,true) onlyReady(_atomId) onlyReady(_ownedId)  {
        require(newAtomFee == msg.value);
        CaDataAddress.transfer(newAtomFee);
        uint id = CaCoreContract.createCombinedAtom(_atomId,_ownedId);
        NewAutoRentAtom(msg.sender,id);
  	}
  	
  	 function rentByAtom(uint _atomId, uint _ownedId) external payable onlyActive beDifferent(_atomId, _ownedId) onlyOwnerOf(_ownedId, true) onlyRenting(_atomId, true) onlyReady(_ownedId) {
	    address owner = CaDataContract.atomOwner(_atomId);
	    uint128 isRent;
        (,,,,,,,isRent,,) = CaDataContract.atoms(_atomId);
	    require(isRent + newAtomFee == msg.value);
	    owner.transfer(isRent);
	    CaDataAddress.transfer(newAtomFee);
        uint id = CaCoreContract.createCombinedAtom(_atomId,_ownedId);
        NewRentAtom(msg.sender,id,owner,isRent);
  	}
  	
  	function buyByAtom(uint _atomId) external payable onlyActive onlyOwnerOf(_atomId, false) onlyBuying(_atomId, true) {
  	    address owner = CaDataContract.atomOwner(_atomId);
  	    uint128 isBuy;
        (,,,,,,,,isBuy,) = CaDataContract.atoms(_atomId);
	    require(isBuy == msg.value);
	    owner.transfer(isBuy);
        CaDataContract.setAtomIsBuy(_atomId,0);
        CaDataContract.setAtomIsRent(_atomId,0);
        CaDataContract.setOwnerAtomsCount(msg.sender,CaDataContract.ownerAtomsCount(msg.sender)+1);
        CaDataContract.setOwnerAtomsCount(owner,CaDataContract.ownerAtomsCount(owner)-1);
        CaDataContract.setAtomOwner(_atomId,msg.sender);
        NewBuyAtom(msg.sender,_atomId,owner,isBuy);
  	}
  	
  	function evolveByAtom(uint _atomId) external onlyActive onlyOwnerOf(_atomId, true) {
  	    uint8 lev;
  	    uint8 cool;
  	    uint32 sons;
  	    (,,lev,cool,sons,,,,,) = CaDataContract.atoms(_atomId);
  	    require(lev < 4 && sons >= levelupValues[lev]);
  	    CaDataContract.setAtomLev(_atomId,lev+1);
  	    CaDataContract.setAtomCool(_atomId,cool-1);
        NewEvolveAtom(msg.sender,_atomId);
  	}
  	
  	function receiveBonus() onlyActive external {
  	    require(bonusMode == true && CaDataContract.bonusReceived(msg.sender) == false);
  	    CaDataContract.setBonusReceived(msg.sender,true);
        uint id = CaCoreContract.createRandomAtom();
        NewBonusAtom(msg.sender,id);
    }
    
}