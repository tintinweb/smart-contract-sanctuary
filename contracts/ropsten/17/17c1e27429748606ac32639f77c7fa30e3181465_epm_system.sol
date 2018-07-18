pragma solidity ^0.4.18;

contract epm_system  {
  
    uint public nodes = 0;
    uint public smartCount = 0;
    uint public delegation_amount;
    address public epocum;

    function epm_system() public{
       epocum = msg.sender;
    }
    
    struct Delegate {
        uint id;
		string webservice;
		address wallet;
		uint amount;
		bool cert;
	}

    struct SmartSharingContract {
		address proprietary;
		bytes32 smartHash;
		uint start;
		string website;
		uint target;
		string tag;
		string ipfs;
		uint end;//8888 unlimited
		uint acceptances;
		string info;
		uint amount;
		bool finalized;
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
    mapping (uint => SmartSharingContract) SmartChainId;
    mapping (bytes32 => SmartSharingContract) SmartChainHash;
    mapping (address => mapping (bytes32 => Acceptance)) acceptByAddress;
    mapping (address => mapping (uint => Acceptance)) myAcceptance;
    mapping (bytes32 => mapping (uint => Acceptance)) advertisers;
    mapping (string => Acceptance) acceptByIpfs;
    mapping (address => Acceptance) Acceptances;

    function resetEpocum(address newEpocum)  public constant returns (bool) {
        if (msg.sender != epocum) revert();
		 epocum = newEpocum;
	}
	
    function isEpocum() public constant returns (bool) {
		return msg.sender == epocum;
	}

    function addDelegate(string webservice) public {
        uint d = nodes++;
	    DelegatesByAddr[msg.sender] = Delegate(d,webservice,msg.sender,0,false);
	    DelegatesById[d] = Delegate(d,webservice,msg.sender,0,false);
	} 
	
	function CertifyDelegate(address inWebAddr) public {
	    if (!isEpocum()) revert();
        DelegatesByAddr[inWebAddr].cert = true;
    }
	
	function NewSmartSharingContract(string _website,uint _target,uint duration,string tags,string dlink,string others) payable public {
        bytes32 _hash = keccak256(msg.sender,_website,smartCount);
        SmartChainId[smartCount].proprietary = msg.sender;
        SmartChainId[smartCount].smartHash =  _hash;
        SmartChainHash[_hash].proprietary = msg.sender;
        SmartChainHash[_hash].start = block.number;
        SmartChainHash[_hash].end = duration;
        SmartChainHash[_hash].website = _website;
        SmartChainHash[_hash].smartHash =  _hash;
        SmartChainHash[_hash].target = _target;
        SmartChainHash[_hash].ipfs = dlink;
        SmartChainHash[_hash].tag = tags;
        SmartChainHash[_hash].acceptances = 0;
        SmartChainHash[_hash].info = others;
        SmartChainHash[_hash].amount = msg.value;
        SmartChainHash[_hash].finalized = false;
        smartCount++; 
    } 
    
	function Accept (bytes32 _smartHash, string _dLink) public {
	    uint numAcc = SmartChainHash[_smartHash].acceptances;
	    uint numAcc4wallet = Acceptances[msg.sender].numAcceptancesBywallet;
	    advertisers[_smartHash][numAcc].advertiser = msg.sender;
	    advertisers[_smartHash][numAcc].dLink = _dLink;
	    string storage _website = SmartChainHash[_smartHash].website;
	    string storage others = SmartChainHash[_smartHash].info;
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
    
    function getSmartSharingByHash(bytes32 hash) public constant returns(address smartOwner,string smartWebsite,bytes32 smartHash,uint target,uint duration,string tags, string ipfs,uint numAcc,string others,uint amount) {
        smartOwner = SmartChainHash[hash].proprietary;
        smartWebsite = SmartChainHash[hash].website;
        smartHash = SmartChainHash[hash].smartHash;
        target = SmartChainHash[hash].target;
        ipfs = SmartChainHash[hash].ipfs;
        numAcc = SmartChainHash[hash].acceptances;
        duration = SmartChainHash[hash].end;
        others = SmartChainHash[hash].info;
        tags = SmartChainHash[hash].tag;
        amount = SmartChainHash[hash].amount;
    }

    function getAcceptance(address addr,uint y) public constant returns(string dLink,bytes32 smartHash,string others) {
       dLink =  myAcceptance[addr][y].dLink;
       smartHash = myAcceptance[addr][y].smartHash;
       others = myAcceptance[addr][y].info;
    }
    
    function getDelegate(uint d) public constant returns(string webservice,address wallet,uint amount, bool cert) {
       webservice = DelegatesById[d].webservice;
       wallet = DelegatesById[d].wallet;
       amount = DelegatesById[d].amount;
       cert = DelegatesById[d].cert;
    }
    
    function getNumAcceptance(address addr) public constant returns(uint num) {
       num = Acceptances[addr].numAcceptancesBywallet;
    }

    function getSmartHash(string _dLink) public constant returns(bytes32 smartHash) {
	    smartHash = acceptByIpfs[_dLink].smartHash;
    }
    
	function getAdvertisers(bytes32 hash, uint x) public constant returns (address adv,string dLink) {
			adv = advertisers[hash][x].advertiser;
			dLink = advertisers[hash][x].dLink;
	}	
	
	function isAlreadyDelegate() public constant returns (bool) {
		return msg.sender == DelegatesByAddr[msg.sender].wallet;
	}
	
	function isActiveDelegate() public constant returns (bool) {
		return true == DelegatesByAddr[msg.sender].cert;
	}

	function checkDelegation(address addr) public constant returns (bool inProgress, bool cert) {
		address delegate = DelegatesByAddr[addr].wallet; //delegation = true
		if (delegate == addr) inProgress = true;
		cert = DelegatesByAddr[addr].cert; //certification = true
	}
	
	function paySmartContract(bytes32 smarthash,address[] addr, uint[] visits) public payable returns (bool status, uint costForVisit, uint fee) {
	    if (!isActiveDelegate()) revert();
        uint amount = SmartChainHash[smarthash].amount;
        fee = amount * 10/100;
        uint numAcc = SmartChainHash[smarthash].acceptances;
        uint target = SmartChainHash[smarthash].target;
        costForVisit = (amount-fee)/target;
        uint256 i = 0;
        while (i < numAcc) {
           address adv = advertisers[smarthash][i].advertiser;
           if (adv == addr[i])
               uint reward = costForVisit * visits[i];
               adv.transfer(reward);
               status = true;
               SmartChainHash[smarthash].finalized = true;
           i += 1;
        }
	}

}