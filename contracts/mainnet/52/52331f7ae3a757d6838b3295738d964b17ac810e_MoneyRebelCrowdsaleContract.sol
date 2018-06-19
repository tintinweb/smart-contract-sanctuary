pragma solidity ^0.4.23;

contract Owned {
    address public owner;
    address public newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}
contract ReentrancyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract ERC20TokenInterface {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Crowdsale is ReentrancyHandlingContract, Owned {
    
    enum state { pendingStart, crowdsale, crowdsaleEnded }
    struct ContributorData {
        uint contributionAmount;
        uint tokensIssued;
    }
    struct Tier {
        uint minContribution;
        uint maxContribution;
        uint bonus;
        bool tierActive;
    }
    mapping (address => uint) public verifiedAddresses;
    mapping(uint => Tier) public tierList;
    uint public nextFreeTier = 1;
    

    state public crowdsaleState = state.pendingStart;
    
    address public multisigAddress;

    uint public crowdsaleStartBlock;
    uint public crowdsaleEndedBlock;

    mapping(address => ContributorData) public contributorList;
    uint public nextContributorIndex;
    mapping(uint => address) public contributorIndexes;

    uint public minCap;
    uint public maxCap;
    uint public ethRaised;
    uint public tokensIssued = 0;
    uint public blocksInADay;
    uint public ethToTokenConversion;

    event CrowdsaleStarted(uint blockNumber);
    event CrowdsaleEnded(uint blockNumber);
    event ErrorSendingETH(address to, uint amount);
    event MinCapReached(uint blockNumber);
    event MaxCapReached(uint blockNumber);

    function() noReentrancy payable public {
        require(crowdsaleState != state.crowdsaleEnded);
        require(isAddressVerified(msg.sender));
        
        bool stateChanged = checkCrowdsaleState();

        if (crowdsaleState == state.crowdsale) {
            processTransaction(msg.sender, msg.value);
        } else {
            refundTransaction(stateChanged);
        }
    }

    function checkCrowdsaleState() internal returns (bool) {
        if (tokensIssued == maxCap && crowdsaleState != state.crowdsaleEnded) {
            crowdsaleState = state.crowdsaleEnded;
            emit CrowdsaleEnded(block.number);
            return true;
        }

        if (block.number >= crowdsaleStartBlock && block.number <= crowdsaleEndedBlock) {
            if (crowdsaleState != state.crowdsale) {
                crowdsaleState = state.crowdsale;
                emit CrowdsaleStarted(block.number);
                return true;
            }
        } else {
            if (crowdsaleState != state.crowdsaleEnded && block.number > crowdsaleEndedBlock) {
                crowdsaleState = state.crowdsaleEnded;
                emit CrowdsaleEnded(block.number);
                return true;
            }
        }
        return false;
    }

    function refundTransaction(bool _stateChanged) internal {
        if (_stateChanged) {
            msg.sender.transfer(msg.value);
        } else {
            revert();
        }
    }
    
    function setEthToTokenConversion(uint _ratio) onlyOwner public {
        require(crowdsaleState == state.pendingStart);
        ethToTokenConversion = _ratio;
    }
    
    function setMaxCap(uint _maxCap) onlyOwner public {
        require(crowdsaleState == state.pendingStart);
        maxCap = _maxCap;
    }
    
    function calculateEthToToken(uint _eth, uint _bonus) constant public returns(uint) {
        uint bonusTokens;
        if (_bonus != 0) {
            bonusTokens = ((_eth * ethToTokenConversion) * _bonus) / 100;
        } 
        return (_eth * ethToTokenConversion) + bonusTokens;
    }

    function calculateTokenToEth(uint _token, uint _bonus) constant public returns(uint) {
        uint ethTokenWithBonus = ethToTokenConversion;
        if (_bonus != 0){
            ethTokenWithBonus = ((ethToTokenConversion * _bonus) / 100) + ethToTokenConversion;
        }
        return _token / ethTokenWithBonus;
    }

    function processTransaction(address _contributor, uint _amount) internal {
        uint contributionAmount = 0;
        uint returnAmount = 0;
        uint tokensToGive = 0;
        uint contributorTier;
        uint minContribution;
        uint maxContribution;
        uint bonus;
        (contributorTier, minContribution, maxContribution, bonus) = getContributorData(_contributor); 

        if (block.number >= crowdsaleStartBlock && block.number < crowdsaleStartBlock + blocksInADay){
            require(_amount >= minContribution);
            require(contributorTier == 1 || contributorTier == 2 || contributorTier == 5 || contributorTier == 6 || contributorTier == 7 || contributorTier == 8);
            if (_amount > maxContribution && maxContribution != 0){
                contributionAmount = maxContribution;
                returnAmount = _amount - maxContribution;
            } else {
                contributionAmount = _amount;
            }
            tokensToGive = calculateEthToToken(contributionAmount, bonus);
        } else if (block.number >= crowdsaleStartBlock + blocksInADay && block.number < crowdsaleStartBlock + 2 * blocksInADay) {
            require(_amount >= minContribution);
            require(contributorTier == 3 || contributorTier == 5 || contributorTier == 6 || contributorTier == 7 || contributorTier == 8);
            if (_amount > maxContribution && maxContribution != 0) {
                contributionAmount = maxContribution;
                returnAmount = _amount - maxContribution;
            } else {
                contributionAmount = _amount;
            }
            tokensToGive = calculateEthToToken(contributionAmount, bonus);
        } else {
            require(_amount >= minContribution);
            if (_amount > maxContribution && maxContribution != 0) {
                contributionAmount = maxContribution;
                returnAmount = _amount - maxContribution;
            } else {
                contributionAmount = _amount;
            }
            if(contributorTier == 5 || contributorTier == 6 || contributorTier == 7 || contributorTier == 8){
                tokensToGive = calculateEthToToken(contributionAmount, bonus);
            }else{
                tokensToGive = calculateEthToToken(contributionAmount, 0);
            }
        }

        if (tokensToGive > (maxCap - tokensIssued)) {
            if (block.number >= crowdsaleStartBlock && block.number < crowdsaleStartBlock + blocksInADay){
                contributionAmount = calculateTokenToEth(maxCap - tokensIssued, bonus);
            }else if (block.number >= crowdsaleStartBlock + blocksInADay && block.number < crowdsaleStartBlock + 2 * blocksInADay) {
                contributionAmount = calculateTokenToEth(maxCap - tokensIssued, bonus);
            }else{
                if(contributorTier == 5 || contributorTier == 6 || contributorTier == 7 || contributorTier == 8){
                    contributionAmount = calculateTokenToEth(maxCap - tokensIssued, bonus);
                }else{
                    contributionAmount = calculateTokenToEth(maxCap - tokensIssued, 0);
                }
            }

            returnAmount = _amount - contributionAmount;
            tokensToGive = maxCap - tokensIssued;
            emit MaxCapReached(block.number);
        }

        if (contributorList[_contributor].contributionAmount == 0) {
            contributorIndexes[nextContributorIndex] = _contributor;
            nextContributorIndex += 1;
        }

        contributorList[_contributor].contributionAmount += contributionAmount;
        ethRaised += contributionAmount;

        if (tokensToGive > 0) {
            contributorList[_contributor].tokensIssued += tokensToGive;
            tokensIssued += tokensToGive;
        }
        if (returnAmount != 0) {
            _contributor.transfer(returnAmount);
        } 
    }

    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }

    function withdrawEth() onlyOwner public {
        require(address(this).balance != 0);
        require(tokensIssued >= minCap);

        multisigAddress.transfer(address(this).balance);
    }

    function investorCount() constant public returns(uint) {
        return nextContributorIndex;
    }

    function setCrowdsaleStartBlock(uint _block) onlyOwner public {
        require(crowdsaleState == state.pendingStart);
        crowdsaleStartBlock = _block;
    }

    function setCrowdsaleEndBlock(uint _block) onlyOwner public {
        require(crowdsaleState == state.pendingStart);
        crowdsaleEndedBlock = _block;
    }
    
    function isAddressVerified(address _address) public view returns (bool) {
        if (verifiedAddresses[_address] == 0){
            return false;
        } else {
            return true;
        }
    }

    function getContributorData(address _contributor) public view returns (uint, uint, uint, uint) {
        uint contributorTier = verifiedAddresses[_contributor];
        return (contributorTier, tierList[contributorTier].minContribution, tierList[contributorTier].maxContribution, tierList[contributorTier].bonus);
    }
    
    function addAddress(address _newAddress, uint _tier) public onlyOwner {
        require(verifiedAddresses[_newAddress] == 0);
        
        verifiedAddresses[_newAddress] = _tier;
    }
    
    function removeAddress(address _oldAddress) public onlyOwner {
        require(verifiedAddresses[_oldAddress] != 0);
        
        verifiedAddresses[_oldAddress] = 0;
    }
    
    function batchAddAddresses(address[] _addresses, uint[] _tiers) public onlyOwner {
        require(_addresses.length == _tiers.length);
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(verifiedAddresses[_addresses[cnt]] != 0);
            verifiedAddresses[_addresses[cnt]] = _tiers[cnt];
        }
    }
}

contract MoneyRebelCrowdsaleContract is Crowdsale {
  
    constructor() public {

        crowdsaleStartBlock = 5578000;
        crowdsaleEndedBlock = 5618330;

        minCap = 0 * 10**18;
        maxCap = 744428391 * 10**18;

        ethToTokenConversion = 13888;

        blocksInADay = 5760;

        multisigAddress = 0x352C30f3092556CD42fE39cbCF585f33CE1C20bc;
 
        tierList[1] = Tier(2*10**17,35*10**18,10, true);
        tierList[2] = Tier(2*10**17,35*10**18,10, true);
        tierList[3] = Tier(2*10**17,25*10**18,0, true);
        tierList[4] = Tier(2*10**17,100000*10**18,0, true);
        tierList[5] = Tier(2*10**17,100000*10**18,8, true);
        tierList[6] = Tier(2*10**17,100000*10**18,10, true); 
        tierList[7] = Tier(2*10**17,100000*10**18,12, true);
        tierList[8] = Tier(2*10**17,100000*10**18,15, true);
    }
}