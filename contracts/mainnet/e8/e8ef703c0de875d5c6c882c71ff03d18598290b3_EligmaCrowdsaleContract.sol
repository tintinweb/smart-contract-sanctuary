pragma solidity ^0.4.21;

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() public {
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

contract KycContractInterface {
    function isAddressVerified(address _address) public view returns (bool);
}

contract MintingContractInterface {

    address public crowdsaleContractAddress;
    address public tokenContractAddress;
    uint public tokenTotalSupply;

    event MintMade(address _to, uint _ethAmount, uint _tokensMinted, string _message);

    function doPresaleMinting(address _destination, uint _tokensAmount) public;
    function doCrowdsaleMinting(address _destination, uint _tokensAmount) public;
    function doTeamMinting(address _destination) public;
    function setTokenContractAddress(address _newAddress) public;
    function setCrowdsaleContractAddress(address _newAddress) public;
    function killContract() public;
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

    state public crowdsaleState = state.pendingStart;
    
    address public multisigAddress = 0x0;
    address public kycAddress = 0x0;
    address public mintingContractAddress = 0x0;

    uint public startPhaseLength = 720;
    uint public startPhaseMaximumcontribution = 10 * 10**18;

    uint public crowdsaleStartBlock;
    uint public crowdsaleEndedBlock;

    mapping(address => ContributorData) public contributorList;
    uint nextContributorIndex;
    mapping(uint => address) contributorIndexes;

    uint public minCap;
    uint public maxCap;
    uint public ethRaised;
    uint public tokensIssued = 0;

    event CrowdsaleStarted(uint blockNumber);
    event CrowdsaleEnded(uint blockNumber);
    event ErrorSendingETH(address to, uint amount);
    event MinCapReached(uint blockNumber);
    event MaxCapReached(uint blockNumber);

    uint nextContributorToClaim;
    mapping(address => bool) hasClaimedEthWhenFail;

    function() noReentrancy payable public {
        require(msg.value >= 100000000000000000);
        require(crowdsaleState != state.crowdsaleEnded);
        require(KycContractInterface(kycAddress).isAddressVerified(msg.sender));

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

    function calculateEthToToken(uint _eth, uint _blockNumber) constant public returns(uint) {
        if (tokensIssued <= 20000000 * 10**18) {
            return _eth * 8640;
        } else if(tokensIssued <= 40000000 * 10**18) {
            return _eth * 8480;
        } else if(tokensIssued <= 60000000 * 10**18) {
            return _eth * 8320;
        } else if(tokensIssued <= 80000000 * 10**18) {
            return _eth * 8160;
        } else {
            return _eth * 8000;
        }
    }

    function calculateTokenToEth(uint _token, uint _blockNumber) constant public returns(uint) {
        uint tempTokenAmount;
        if (tokensIssued <= 20000000 * 10**18) {
            tempTokenAmount = (_token * 1000) / 1008640;
        } else if(tokensIssued <= 40000000 * 10**18) {
            tempTokenAmount = (_token * 1000) / 8480;
        } else if(tokensIssued <= 60000000 * 10**18) {
            tempTokenAmount = (_token * 1000) / 8320;
        } else if(tokensIssued <= 80000000 * 10**18) {
            tempTokenAmount = (_token * 1000) / 8160;
        } else {
            tempTokenAmount = (_token * 1000) / 8000;
        }
        return tempTokenAmount / 1000;
    }

    function processTransaction(address _contributor, uint _amount) internal {
        uint contributionAmount = 0;
        uint returnAmount = 0;
        uint tokensToGive = 0;

        if (block.number < crowdsaleStartBlock + startPhaseLength) {
            if((_amount + contributorList[_contributor].contributionAmount) > startPhaseMaximumcontribution) {
                if (contributorList[_contributor].contributionAmount < startPhaseMaximumcontribution) {
                    contributionAmount = startPhaseMaximumcontribution - contributorList[_contributor].contributionAmount;
                    returnAmount = _amount - contributionAmount;
                } else {
                    revert();
                }
            } else {
                contributionAmount = _amount;
            }
        } else {
            contributionAmount = _amount;
        }
        
        tokensToGive = calculateEthToToken(contributionAmount, block.number);

        if (tokensToGive > (maxCap - tokensIssued)) {
            contributionAmount = calculateTokenToEth(maxCap - tokensIssued, block.number);
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
            MintingContractInterface(mintingContractAddress).doCrowdsaleMinting(_contributor, tokensToGive);
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

    function claimEthIfFailed() public {
        require(block.number > crowdsaleEndedBlock && tokensIssued < minCap);
        require(contributorList[msg.sender].contributionAmount > 0);
        require(!hasClaimedEthWhenFail[msg.sender]);

        uint ethContributed = contributorList[msg.sender].contributionAmount;
        hasClaimedEthWhenFail[msg.sender] = true;
        if (!msg.sender.send(ethContributed)) {
            emit ErrorSendingETH(msg.sender, ethContributed);
        }
    }

    function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner public {
        require(block.number > crowdsaleEndedBlock && tokensIssued < minCap);
        address currentParticipantAddress;
        uint contribution;
        for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
            currentParticipantAddress = contributorIndexes[nextContributorToClaim];
            if (currentParticipantAddress == 0x0) {
                return;
            }
            if (!hasClaimedEthWhenFail[currentParticipantAddress]) {
                contribution = contributorList[currentParticipantAddress].contributionAmount;
                hasClaimedEthWhenFail[currentParticipantAddress] = true;
                if (!currentParticipantAddress.send(contribution)) {
                    emit ErrorSendingETH(currentParticipantAddress, contribution);
                }
            }
            nextContributorToClaim += 1;
        }
    }

    function withdrawRemainingBalanceForManualRecovery() onlyOwner public {
        require(address(this).balance != 0);
        require(block.number > crowdsaleEndedBlock);
        require(contributorIndexes[nextContributorToClaim] == 0x0);
        multisigAddress.transfer(address(this).balance);
    }

    function setMultisigAddress(address _newAddress) onlyOwner public {
        multisigAddress = _newAddress;
    }

    function setMintingContractAddress(address _newAddress) onlyOwner public {
        mintingContractAddress = _newAddress;
    }

    function setKycAddress(address _newAddress) onlyOwner public {
        kycAddress = _newAddress;
    }

    function investorCount() constant public returns(uint) {
        return nextContributorIndex;
    }

    function setCrowdsaleStartBlock(uint _block) onlyOwner public {
        crowdsaleStartBlock = _block;
    }
}

contract EligmaCrowdsaleContract is Crowdsale {
  
    function EligmaCrowdsaleContract() public {

        crowdsaleStartBlock = 5456462;
        crowdsaleEndedBlock = 5584081; 

        minCap = 0 * 10**18;
        maxCap = 161054117 * 10**18;
    }
}