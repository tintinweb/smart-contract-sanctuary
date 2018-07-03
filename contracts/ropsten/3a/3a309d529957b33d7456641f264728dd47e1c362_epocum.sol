pragma solidity ^0.4.18;

contract epocum {
  
    uint public nodes = 0;
    uint public smartCount = 0;
    address public _epocum;
    
    function epocum() public{
       _epocum = msg.sender;
    }
    
     struct Websites {
		string url;
		bool cert;
	} 
	
    struct Delegate {
		string ipfs;
		address wallet;
		uint id;
	}

    struct SmartSharingContract {
		address proprietary;
		bytes32 smartHash;
		string website;
		uint target;
		string tag;
		string ipfs;
		uint duration;
		uint acceptances;
		string info;
		uint tokenAmount;
		string tokenSymbol;
	}
	
	struct Acceptance {
	    uint id;
		bytes32 smartHash;
		string website;
		address advertiser;
		string dLink;
		string info;
		uint numAcceptancesBywallet;
	}
	
    mapping (uint => Delegate) DelegatesById;
    mapping (address => Delegate) DelegatesByAddr;

    mapping (address => mapping (uint => Websites)) WebChain;
    
    mapping (uint => SmartSharingContract) SmartChainId;
    mapping (bytes32 => SmartSharingContract) SmartChainHash;

    mapping (address => mapping (bytes32 => Acceptance)) acceptByAddress;
    mapping (address => mapping (uint => Acceptance)) myAcceptance;
    mapping (string => Acceptance) acceptByIpfs;
    mapping (address => Acceptance) Acceptances;
    
    function () payable public {
        uint amount = msg.value;
    }

    function resetEpocum(address _newEpocum)  public constant returns (bool) {
        if (msg.sender != _epocum) revert();
		 _epocum = _newEpocum;
	}
	
    function isEpocum() public constant returns (bool) {
		return msg.sender == _epocum;
	}

	function isAlreadyDelegate() public constant returns (bool) {
		return msg.sender == DelegatesByAddr[msg.sender].wallet;
	}

    function addDelegate(string ipfs) public {
	    nodes++;
	    DelegatesByAddr[msg.sender] = Delegate(ipfs,msg.sender,nodes++);
	} 
	
	function CertifyDelegate(address inWebAddr, uint x) public {
	    if (!isEpocum()) revert();
        WebChain[inWebAddr][x].cert = true;
    }
	
	function NewSmartSharingContract(string _website,uint _target,uint duration,string tags,string dlink,string others,uint tAmount,string tSymbol) public {
        bytes32 _hash = keccak256(msg.sender,_website,smartCount);
        SmartChainId[smartCount].proprietary = msg.sender;
        SmartChainId[smartCount].smartHash =  _hash;
        SmartChainHash[_hash].proprietary = msg.sender;
        SmartChainHash[_hash].website = _website;
        SmartChainHash[_hash].smartHash =  _hash;
        SmartChainHash[_hash].target = _target;
        SmartChainHash[_hash].ipfs = dlink;
        SmartChainHash[_hash].tag = tags;
        SmartChainHash[_hash].duration = duration;
        SmartChainHash[_hash].acceptances = 0;
        SmartChainHash[_hash].info = others;
        SmartChainHash[_hash].tokenAmount = tAmount;
        SmartChainHash[_hash].tokenSymbol = tSymbol;
        smartCount++; 
    } 
    
	function Accept (bytes32 _smartHash, string _dLink) public {
	    uint numAcc = SmartChainHash[_smartHash].acceptances;
	    uint numAcc4wallet = Acceptances[msg.sender].numAcceptancesBywallet;
	    
	    string _website = SmartChainHash[_smartHash].website;
	    string others = SmartChainHash[_smartHash].info;
	    uint x = acceptByAddress[msg.sender][_smartHash].id;
	    acceptByAddress[msg.sender][_smartHash].advertiser = msg.sender;
	    acceptByAddress[msg.sender][_smartHash].dLink = _dLink;
        acceptByAddress[msg.sender][_smartHash].website = _website;
        acceptByIpfs[_dLink].smartHash = _smartHash;
        uint y = x + 1;
        uint z = numAcc + 1;
        uint wa = numAcc4wallet + 1;
        acceptByAddress[msg.sender][_smartHash].id = y;
        SmartChainHash[_smartHash].acceptances = z;
        myAcceptance[msg.sender][wa].dLink = _dLink;
        myAcceptance[msg.sender][wa].smartHash = _smartHash;
        myAcceptance[msg.sender][wa].info = others;
        Acceptances[msg.sender].numAcceptancesBywallet = wa;
    } 
    
    function countAllSmartSharingContract() public constant returns(uint count) {
        count = smartCount;
    }

    function getSmartSharingByID(uint id) public constant returns(address smartOwner, bytes32 smartHash) {
        smartOwner = SmartChainId[id].proprietary;
        smartHash = SmartChainId[id].smartHash;
    }
    
    function getSmartSharingByHash(bytes32 hash) public constant returns(address smartOwner, string smartWebsite, bytes32 smartHash, uint target, string ipfs, uint numAcc, string others) {
        smartOwner = SmartChainHash[hash].proprietary;
        smartWebsite = SmartChainHash[hash].website;
        smartHash = SmartChainHash[hash].smartHash;
        target = SmartChainHash[hash].target;
        numAcc = SmartChainHash[hash].acceptances;
        others = SmartChainHash[hash].info;
    }
    
    function getAcceptance(bytes32 _smartHash,address addr) public constant returns(string dLink,string web,string others) {
	    dLink = acceptByAddress[addr][_smartHash].dLink;
	    web = acceptByAddress[addr][_smartHash].website;
	    others = acceptByAddress[addr][_smartHash].info;
    }
    
    function getMyAcceptance(address addr,uint y) public constant returns(string dLink,bytes32 smartHash,string others) {
       dLink =  myAcceptance[addr][y].dLink;
       smartHash = myAcceptance[addr][y].smartHash;
       others = myAcceptance[addr][y].info;
    }
    
    function getNumAcceptance(address addr) public constant returns(uint num) {
       num = Acceptances[addr].numAcceptancesBywallet;
    }

    function getSmartHash(string _dLink) public constant returns(bytes32 smartHash) {
	    smartHash = acceptByIpfs[_dLink].smartHash;
    }

}