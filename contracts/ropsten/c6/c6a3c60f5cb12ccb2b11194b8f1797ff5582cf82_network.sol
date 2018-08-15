pragma solidity ^0.4.18;

interface token {
    function transfer(address _to, uint256 _amount);
    function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract network  {

    uint public nodes = 0;
    uint public proposal_n = 0;
    address public epocum;
    token public epm;
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;

    function network() public{
       epocum = msg.sender;
       epm = token(0xAbC7Ea7892bFEaE4f6e9210454256040C484c504);
    }

    struct Delegate {
        uint id;
		string webservice;
		address wallet;
		uint amount;
		bool cert;
	}

    struct Proposal {
		address proprietary;
		bytes32 proposalHash;
		uint start;
		string website;
		uint target;
		string tag;
		string ipfs;
		uint end;//8888 unlimited
		uint acceptances;
		string info;
		uint amount;
		uint256 law;
		bool finalized;
	}

	struct Acceptance {
	    uint id;
		bytes32 proposalHash;
		string website;
		address advertiser;
		string dLink;
		string info;
		uint numAcceptancesBywallet;
	}

    mapping (uint => Delegate) DelegatesById;
    mapping (address => Delegate) DelegatesByAddr;
    mapping (uint => Proposal) ProposalBy_Id;
    mapping (bytes32 => Proposal) ProposalBy_Hash;
    mapping (address => mapping (bytes32 => Acceptance)) acceptByAddress;
    mapping (address => mapping (uint => Acceptance)) myAcceptance;
    mapping (bytes32 => mapping (uint => Acceptance)) advertisers;
    mapping (string => Acceptance) acceptByIpfs;
    mapping (address => Acceptance) Acceptances;

    function resetEpocum(address newEpocum) public constant returns (bool) {
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
        if ((getEpmBalance(msg.sender) < 1000000*10**18))  revert();
        uint256 amount = getEpmBalance(msg.sender);
        DelegatesByAddr[inWebAddr].cert = true;
        DelegatesByAddr[inWebAddr].amount = amount;
    }

	function unCertifyDelegate(address inWebAddr) public {
        if ((getEpmBalance(msg.sender) <= 1000000*10**18) && (!isActiveDelegate())) revert();
        DelegatesByAddr[inWebAddr].cert = false;
    }

	function New(string _website,uint _target,uint duration,string tags,string others) payable public {
        bytes32 _hash = keccak256(msg.sender,_website,proposal_n);
        uint256 rnd = rand();
        ProposalBy_Id[proposal_n].proprietary = msg.sender;
        ProposalBy_Id[proposal_n].proposalHash =  _hash;
        ProposalBy_Hash[_hash].proprietary = msg.sender;
        ProposalBy_Hash[_hash].start = block.number;
        ProposalBy_Hash[_hash].end = duration;
        ProposalBy_Hash[_hash].website = _website;
        ProposalBy_Hash[_hash].proposalHash =  _hash;
        ProposalBy_Hash[_hash].target = _target;
        ProposalBy_Hash[_hash].tag = tags;
        ProposalBy_Hash[_hash].acceptances = 0;
        ProposalBy_Hash[_hash].info = others;
        ProposalBy_Hash[_hash].amount = msg.value;
        ProposalBy_Hash[_hash].law = rnd;
        ProposalBy_Hash[_hash].finalized = false;
        proposal_n++;
    }

	function Accept (bytes32 _smartHash, string _dLink) public {
	    uint numAcc = ProposalBy_Hash[_smartHash].acceptances;
	    uint numAcc4wallet = Acceptances[msg.sender].numAcceptancesBywallet;
	    advertisers[_smartHash][numAcc].advertiser = msg.sender;
	    advertisers[_smartHash][numAcc].dLink = _dLink;
	    string storage _website = ProposalBy_Hash[_smartHash].website;
	    string storage others = ProposalBy_Hash[_smartHash].info;
	    uint x = acceptByAddress[msg.sender][_smartHash].id;
	    acceptByAddress[msg.sender][_smartHash].advertiser = msg.sender;
	    acceptByAddress[msg.sender][_smartHash].dLink = _dLink;
        acceptByAddress[msg.sender][_smartHash].website = _website;
        acceptByIpfs[_dLink].proposalHash = _smartHash;
        uint y = x + 1;
        uint z = numAcc + 1;
        uint wa = numAcc4wallet + 1;
        acceptByAddress[msg.sender][_smartHash].id = y;
        ProposalBy_Hash[_smartHash].acceptances = z;
        myAcceptance[msg.sender][wa].dLink = _dLink;
        myAcceptance[msg.sender][wa].proposalHash = _smartHash;
        myAcceptance[msg.sender][wa].info = others;
        Acceptances[msg.sender].numAcceptancesBywallet = wa;
    }

    function countAllProposals() public constant returns(uint count) {
        count = proposal_n;
    }

    function getProposalByID(uint id) public constant returns(address smartOwner, bytes32 smartHash) {
        smartOwner = ProposalBy_Id[id].proprietary;
        smartHash = ProposalBy_Id[id].proposalHash;
    }

    function getProposalByHash(bytes32 hash) public constant returns(address smartOwner,string smartWebsite,bytes32 smartHash,uint target,uint duration,string tags, string ipfs,uint numAcc,string others,uint amount,bool finalized) {
        smartOwner = ProposalBy_Hash[hash].proprietary;
        smartWebsite = ProposalBy_Hash[hash].website;
        smartHash = ProposalBy_Hash[hash].proposalHash;
        target = ProposalBy_Hash[hash].target;
        ipfs = ProposalBy_Hash[hash].ipfs;
        numAcc = ProposalBy_Hash[hash].acceptances;
        duration = ProposalBy_Hash[hash].end;
        others = ProposalBy_Hash[hash].info;
        tags = ProposalBy_Hash[hash].tag;
        amount = ProposalBy_Hash[hash].amount;
        finalized = ProposalBy_Hash[hash].finalized;
    }

    function getAcceptance(address addr,uint y) public constant returns(string dLink,bytes32 smartHash,string others) {
        dLink =  myAcceptance[addr][y].dLink;
        smartHash = myAcceptance[addr][y].proposalHash;
        others = myAcceptance[addr][y].info;
    }

    function getDelegate(uint d) public constant returns(string webservice,address wallet,uint amount, bool cert) {
        webservice = DelegatesById[d].webservice;
        wallet = DelegatesById[d].wallet;
        amount = DelegatesByAddr[wallet].amount;
        cert = DelegatesByAddr[wallet].cert;
    }

    function getNumAcceptance(address addr) public constant returns(uint num) {
        num = Acceptances[addr].numAcceptancesBywallet;
    }
    
    function getRandom(bytes32 hash) public constant returns(uint256 r) {
        r = ProposalBy_Hash[hash].law;
    }

    function getProposalHash(string _dLink) public constant returns(bytes32 smartHash) {
	    smartHash = acceptByIpfs[_dLink].proposalHash;
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

	function isProposalEnded(bytes32 smarthash) public constant returns (bool) {
		return true == ProposalBy_Hash[smarthash].finalized;
	}

	function checkDelegation(address addr) public constant returns (bool inProgress, bool cert) {
		address delegate = DelegatesByAddr[addr].wallet; //delegation = true
		if (delegate == addr) inProgress = true;
		cert = DelegatesByAddr[addr].cert; //certification = true
	}

	function getEpmBalance(address delegate) public constant returns (uint256 balance) {
		balance = epm.balanceOf(delegate);
	}

    function rand() constant private returns (uint256 result){
      uint max = 999;
      uint256 factor = FACTOR * 100 / max;
      uint256 lastBlockNumber = block.number - 1;
      uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
      return uint256((uint256(hashVal) / factor)) % max;
    }

	function pay(bytes32 smarthash,address[] addr, uint[] visits) public payable returns (bool status, uint costForVisit, uint fee) {
	    if ((getEpmBalance(msg.sender) < 1000000*10**18) && (!isActiveDelegate())) revert();
        uint amount = ProposalBy_Hash[smarthash].amount;
        fee = amount * 10/100;
        uint numAcc = ProposalBy_Hash[smarthash].acceptances;
        uint target = ProposalBy_Hash[smarthash].target;
        costForVisit = (amount-fee)/target;
        uint256 i = 0;
        while (i < numAcc) {
           address adv = advertisers[smarthash][i].advertiser;
           if (adv == addr[i])
               uint reward = costForVisit * visits[i];
               adv.transfer(reward);
               epm.transfer(msg.sender,50*10**18);
               ProposalBy_Hash[smarthash].finalized = true;
               status = true;
           i += 1;
        }
	}
}