/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

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

    
    //ADMIN
    
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
    
    //MAPPING_SETTERS
    
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
    
    //ATOM_SETTERS
    
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

contract CaTokenInterface {
    function emitTransfer(address, address, uint) external;
}

contract CryptoAtomsCore {
    
    address public CaDataAddress = 0x9b3554E6FC4F81531F6D43b611258bd1058ef6D5;
    CaData public CaDataContract = CaData(CaDataAddress);
    
    CaTokenInterface public CaTokenContract = CaTokenInterface(0xbdaed67214641b7eda3bf8d7431c3ae5fc46f466);
    
    uint64    dnaModulus = 2 ** 50;
    uint16    nucModulus = 2 ** 12;
    uint32    colModulus = 10 ** 8; //=> (16-8) = 8 inherited digits (7 are significant)
                                
    uint32[8] public cooldownValues = [uint32(5 minutes), 
                                       uint32(30 minutes), 
                                       uint32(2 hours), 
                                       uint32(6 hours), 
                                       uint32(12 hours), 
                                       uint32(24 hours), 
                                       uint32(36 hours), 
                                       uint32(48 hours)];
                                       
    uint128[4] public mintedAtomFee = [50 finney, 100 finney, 200 finney, 500 finney];

    event NewMintedAtom(address sender, uint atom);                         
    
    function kill() external
	{
	    require(msg.sender == CaDataContract.CTO());
		selfdestruct(msg.sender); 
	}
    
    modifier onlyLogic() {
      require(msg.sender == CaDataContract.logicAddress());
      _;
    }
    
     modifier onlyAdmin() {
      require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
      _;
    }
     
    function setFee(uint128 _newFee, uint8 _level) external onlyAdmin {
        require(_level > 0 && _level < 5);
        mintedAtomFee[_level-1] = _newFee;
    }
     
    function setCooldown(uint32[8] _newCooldown) external onlyAdmin {
        cooldownValues = _newCooldown;
    }

    function setTokenAddr(address _newTokenAddr) external onlyAdmin {
        CaTokenContract = CaTokenInterface(_newTokenAddr);
    }
    
    function emitTransferBatch(address[200] _fromArray, address[200] _toArray, uint256[200] _tokenIdArray, uint8 _eventsNum) external onlyAdmin {
        require(_eventsNum <= 200);
        for(uint8 tx=0; tx<_eventsNum; tx++)
        {
            CaTokenContract.emitTransfer(_fromArray[tx], _toArray[tx], _tokenIdArray[tx]);
        }
    }
    
    function _defineDna(uint64 _dna1, uint64 _dna2) private returns (uint64 definedDna) {
        uint16 binModulus = nucModulus;
        uint64 decModulus = colModulus;
        uint64 nucDna;
        uint64 colDna;
        uint64 random;
        for (uint8 attemp=16; attemp>0; attemp--)
        {
            CaDataContract.incRandNonce();
            random = uint64(keccak256(now, tx.origin, CaDataContract.randNonce()));
            if (random%2 == 0)
            {
                nucDna = _dna1;
                colDna = _dna2;
            }
            else
            {
                nucDna = _dna2;
                colDna = _dna1;
            }
            definedDna = ((colDna/decModulus)*decModulus) + (random % decModulus);
            definedDna = definedDna - (definedDna % binModulus) + (nucDna % binModulus);
            definedDna = definedDna % dnaModulus;
            if(CaDataContract.dnaExist(definedDna)==true)
            {
                if(attemp > 8)
                {
                    decModulus = decModulus*10;//if attemp=16,15,14,13,12,11,10,9 -> 1 inherited digit removed
                }
                else
                {
                    binModulus = binModulus/2;//if attemp=8,7,6,5,4,3,2,1 -> 1 inherited digit removed
                }
                definedDna = 0;
            }
            else
            {
                attemp = 1;//forced end
            }
        }
    }
    
    function _defineGen(uint8 _gen1, uint8 _lev1, uint8 _gen2, uint8 _lev2) private pure returns (uint8 definedGen) {
        if(_gen1 == _gen2)
        {
            definedGen = _gen1;
            if(_lev1+_lev2 > 6)
            {
                definedGen++;
            }
        }
        if(_gen1 < _gen2)
        {
            definedGen = _gen1;
            if(_lev1 > 2)
            {
                definedGen++;
            }
        }
        if(_gen1 > _gen2)
        {
            definedGen = _gen2;
            if(_lev2 > 2)
            {
                definedGen++;
            }
        }
        if(definedGen > 4)
        {
        	definedGen = 4;
        }
    }
    
    function _beParents(uint _atomId1, uint _atomId2) private {
        uint8 cool1;
        uint8 cool2;
        uint32 sons1;
        uint32 sons2;
        (,,,cool1,sons1,,,,,) = CaDataContract.atoms(_atomId1);
        (,,,cool2,sons2,,,,,) = CaDataContract.atoms(_atomId2);
        CaDataContract.setAtomIsReady(_atomId1, uint32(now + cooldownValues[cool1]));
        CaDataContract.setAtomIsReady(_atomId2, uint32(now + cooldownValues[cool2]));
        CaDataContract.setAtomSons(_atomId1, sons1+1);
        CaDataContract.setAtomSons(_atomId2, sons2+1);
        CaDataContract.setAtomIsRent(_atomId1,0);
        CaDataContract.setAtomIsRent(_atomId2,0);
    }
    
    function _createAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint _fathId, uint _mothId) private returns (uint id) {
        require(CaDataContract.totalSupply()<3000);
        require(CaDataContract.dnaExist(_dna)==false);
        id = CaDataContract.pushAtom(_dna, _gen, _lev, _cool, 0, uint64(_fathId), uint64(_mothId), 0, 0, 0);
        CaDataContract.setAtomOwner(id,tx.origin);
        CaDataContract.setOwnerAtomsCount(tx.origin,CaDataContract.ownerAtomsCount(tx.origin)+1);
        CaDataContract.setDnaExist(_dna,true);
        CaTokenContract.emitTransfer(0x0,tx.origin,id);
    }

    function createCombinedAtom(uint _atomId1, uint _atomId2) external onlyLogic returns (uint id) {
        uint64 dna1;
        uint64 dna2;
        uint8 gen1;
        uint8 gen2;
        uint8 lev1;
        uint8 lev2;
        (dna1,gen1,lev1,,,,,,,) = CaDataContract.atoms(_atomId1);
        (dna2,gen2,lev2,,,,,,,) = CaDataContract.atoms(_atomId2);
        uint8  combGen  = _defineGen(gen1,lev1,gen2,lev2);
        uint64 combDna  = _defineDna(dna1, dna2);
        _beParents(_atomId1, _atomId2);
        id = _createAtom(combDna, combGen, 1, combGen+3, _atomId1, _atomId2);
    }
    
    function createRandomAtom() external onlyLogic returns (uint id) {
        CaDataContract.incRandNonce();
        uint64 randDna = uint64(keccak256(now, tx.origin, CaDataContract.randNonce())) % dnaModulus;
        while(CaDataContract.dnaExist(randDna)==true)
        {
            CaDataContract.incRandNonce();
            randDna = uint64(keccak256(now, tx.origin, CaDataContract.randNonce())) % dnaModulus;
        }
        id = _createAtom(randDna, 1, 1, 4, dnaModulus, dnaModulus);
    }
    
    function createTransferAtom(address _from, address _to, uint _tokenId) external onlyLogic {
        CaTokenContract.emitTransfer(_from, _to, _tokenId);
    }
	
    function shapeAtom(uint _atomId, uint8 _level) external payable {
  	    require(_level > 0 && _level < 5 && CaDataContract.atomOwner(_atomId) == msg.sender && mintedAtomFee[_level-1]/2 == msg.value);
  	    CaDataAddress.transfer(msg.value);
        CaDataContract.setAtomLev(_atomId, _level);
    }
    
    function mintAtom(uint8 _level) external payable {
  	    require(_level > 0 && _level < 5 && mintedAtomFee[_level-1] == msg.value);
		CaDataAddress.transfer(msg.value);
        CaDataContract.incRandNonce();
        uint64 randDna = uint64(keccak256(now, tx.origin, CaDataContract.randNonce())) % dnaModulus;
        while(CaDataContract.dnaExist(randDna)==true)
        {
            CaDataContract.incRandNonce();
            randDna = uint64(keccak256(now, tx.origin, CaDataContract.randNonce())) % dnaModulus;
        }
        uint id = _createAtom(randDna, 1, _level, 4-_level, dnaModulus, dnaModulus);
        NewMintedAtom(tx.origin, id);
    }
    
}