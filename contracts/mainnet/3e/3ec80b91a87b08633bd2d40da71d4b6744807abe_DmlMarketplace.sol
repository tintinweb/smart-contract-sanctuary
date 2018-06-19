pragma solidity ^0.4.22;

contract DmlMarketplace {
    // Public Variables
    mapping(address => bool) public moderators;
    address public token;
    
    // bountyFactory address
    DmlBountyFactory public bountyFactory;
    
    
    mapping(bytes32 => uint) public totals;
    mapping(address => mapping(bytes32 => bool)) public hasPurchased;
    
    constructor() public {
        moderators[msg.sender] = true;
    }
    
    function isReady() view public returns (bool success) {
        if (token == address(0) || bountyFactory == address(0)) {
            return false;
        }

        return true;
    }

    function isModerator(address modAddress) view public returns (bool success) {
        return moderators[modAddress];
    }

    function addModerator(address newModerator) public {
        require(isModerator(msg.sender));
        moderators[newModerator] = true;
    }

    function removeModerator(address mod) public {
        require(isModerator(msg.sender));
        moderators[mod] = false;
    }

    function init (address newTokenAddress) public returns (bool success) {
        require(isModerator(msg.sender));
        token = newTokenAddress;
        DmlBountyFactory f = new DmlBountyFactory(token);
        bountyFactory = f;
        return true;
    }

    function setBountyFactory(address factoryAddress) public {
        require(isModerator(msg.sender));
        DmlBountyFactory f = DmlBountyFactory(factoryAddress);
        bountyFactory = f;
    }
    
    function buy(bytes32 algoId, uint value) public returns (bool success) {
        address sender = msg.sender;
        
        require(!hasPurchased[msg.sender][algoId]);

        ERC20Interface c = ERC20Interface(token);
        
        require(c.transferFrom(sender, address(this), value));

        hasPurchased[sender][algoId] = true;
        
        if (totals[algoId] < 1) {
            totals[algoId] = 1;
        } else {
            totals[algoId]++;
        }
        
        return true;
    }
    
    function transferToken (address receiver, uint amount) public {
        require(isModerator(msg.sender));
        
        ERC20Interface c = ERC20Interface(token);
        require(c.transfer(receiver, amount));
    }
}

contract DmlBountyFactory {
    address public marketplace;
    address public token;
    address[] public allBountyAddresses;
    mapping(address => address[]) public bountyAddressByCreator;
    mapping(address => address[]) public bountyAddressByParticipant;
    
    constructor(address tokenAddress) public {
        marketplace = msg.sender;
        token = tokenAddress;
    }

    function getAllBounties() view public returns (address[] bounties) {
        return allBountyAddresses;
    }

    function getBountiesByCreator(address creatorAddress) view public returns (address[] bounties) {
        return bountyAddressByCreator[creatorAddress];
    }

    function getBountiesByParticipant(address participantAddress) view public returns (address[] bounties) {
        return bountyAddressByParticipant[participantAddress];
    }
    
    function createBounty(string name, uint[] prizes) public {
        address creator = msg.sender;
        address newBounty = new Bounty(token, creator, name, prizes, marketplace);
        allBountyAddresses.push(newBounty);
        bountyAddressByCreator[msg.sender].push(newBounty);
    }
    
    function joinBounty(address bountyAddress) public {
        Bounty b = Bounty(bountyAddress);
        
        require(b.join(msg.sender));
        
        bountyAddressByParticipant[msg.sender].push(bountyAddress);
    }
}

contract Bounty {
    // contract addresses
    address public factory;
    
    // public constants
    address public creator;
    address public token;
    address public marketplace;

    // state variables
    string public name;
    uint[] public prizes;
    uint public createdAt;
    address[] public winners;
    address[] public participants;
    Status public status;
    mapping(address => bool) public participantsMap;

    enum Status {
        Initialized,
        EnrollmentStart,
        EnrollmentEnd,
        BountyStart,
        BountyEnd,
        EvaluationEnd,
        Completed,
        Paused
    }
    
    constructor(
        address tokenAddress,
        address creatorAddress,
        string initName,
        uint[] initPrizes,
        address mpAddress
    ) public {
        factory = msg.sender;
        marketplace = mpAddress;
        creator = creatorAddress;
        token = tokenAddress;
        prizes = initPrizes;
        status = Status.Initialized;
        name = initName;
        createdAt = now;
    }
    
    function isFunded() public view returns (bool success) {
        ERC20Interface c = ERC20Interface(token);
        require(getTotalPrize() <= c.balanceOf(address(this)));
        return true;
    }

    function getData() public view returns (string retName, uint[] retPrizes, address[] retWinenrs, address[] retParticipants, Status retStatus, address retCreator, uint createdTime) {
        return (name, prizes, winners, participants, status, creator, createdAt);
    }
    
    function join(address participantAddress) public returns (bool success) {
        require(msg.sender == factory);

        if (status != Status.EnrollmentStart) {
            return false;
        }
        
        if (participantsMap[participantAddress] == true) {
            return false;
        }
        
        participants.push(participantAddress);
        participantsMap[participantAddress] = true;
        
        return true;
    }

    function updateBounty(string newName, uint[] newPrizes) public {
        require(updateName(newName));
        require(updatePrizes(newPrizes));
    }

    function updateName(string newName) public returns (bool success) {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender) || msg.sender == creator);
        name = newName;
        return true;
    }

    function forceUpdateName(string newName) public returns (bool success) {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender));
        name = newName;
        return true;
    }
    
    function updatePrizes(uint[] newPrizes) public returns (bool success) {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender) || msg.sender == creator);
        require(status == Status.Initialized);
        prizes = newPrizes;
        return true;
    }

    function forceUpdatePrizes(uint[] newPrizes) public returns (bool success) {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender));
        prizes = newPrizes;
        return true;
    }

    function setStatus(Status newStatus) private returns (bool success) {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender) || msg.sender == creator);
        status = newStatus;
        return true;
    }

    function forceSetStatus(Status newStatus) public returns (bool success) {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender));
        status = newStatus;
        return true;
    }
    
    function startEnrollment() public {
        require(prizes.length > 0);
        require(isFunded());
        setStatus(Status.EnrollmentStart);
    }
    
    function stopEnrollment() public {
        require(status == Status.EnrollmentStart);
        setStatus(Status.EnrollmentEnd);
    }
    
    function startBounty() public {
        require(status == Status.EnrollmentEnd);
        setStatus(Status.BountyStart);
    }
    
    function stopBounty() public {
        require(status == Status.BountyStart);
        setStatus(Status.BountyEnd);
    }

    function updateWinners(address[] newWinners) public {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender) || msg.sender == creator);
        require(status == Status.BountyEnd);
        require(newWinners.length == prizes.length);

        for (uint i = 0; i < newWinners.length; i++) {
            require(participantsMap[newWinners[i]]);
        }

        winners = newWinners;
        setStatus(Status.EvaluationEnd);
    }

    function forceUpdateWinners(address[] newWinners) public {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender));

        winners = newWinners;
    }

    function payoutWinners() public {
        ERC20Interface c = ERC20Interface(token);
        DmlMarketplace dmp = DmlMarketplace(marketplace);

        require(dmp.isModerator(msg.sender) || msg.sender == creator);
        require(isFunded());
        require(winners.length == prizes.length);
        require(status == Status.EvaluationEnd);

        for (uint i = 0; i < prizes.length; i++) {
            require(c.transfer(winners[i], prizes[i]));
        }
        
        setStatus(Status.Completed);
    }
    
    function getTotalPrize() public constant returns (uint total) {
        uint t = 0;
        for (uint i = 0; i < prizes.length; i++) {
            t = t + prizes[i];
        }
        return t;
    }

    function transferToken (address receiver, uint amount) public {
        DmlMarketplace dmp = DmlMarketplace(marketplace);
        require(dmp.isModerator(msg.sender));
        ERC20Interface c = ERC20Interface(token);
        require(c.transfer(receiver, amount));
    }
    
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}