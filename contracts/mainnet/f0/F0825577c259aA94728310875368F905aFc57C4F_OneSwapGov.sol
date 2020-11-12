// File: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/interfaces/IOneSwapToken.sol

pragma solidity 0.6.12;


interface IOneSwapBlackList {
    event OwnerChanged(address);
    event AddedBlackLists(address[]);
    event RemovedBlackLists(address[]);

    function owner()external view returns (address);
    function newOwner()external view returns (address);
    function isBlackListed(address)external view returns (bool);

    function changeOwner(address ownerToSet) external;
    function updateOwner() external;
    function addBlackLists(address[] calldata  accounts)external;
    function removeBlackLists(address[] calldata  accounts)external;
}

interface IOneSwapToken is IERC20, IOneSwapBlackList{
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function multiTransfer(uint256[] calldata mixedAddrVal) external returns (bool);
}

// File: contracts/interfaces/IOneSwapGov.sol

pragma solidity 0.6.12;

interface IOneSwapGov {
    event NewFundsProposal  (uint64 proposalID, string title, string desc, string url, uint32 deadline, address beneficiary, uint256 amount);
    event NewParamProposal  (uint64 proposalID, string title, string desc, string url, uint32 deadline, address factory, uint32 feeBPS);
    event NewUpgradeProposal(uint64 proposalID, string title, string desc, string url, uint32 deadline, address factory, address pairLogic);
    event NewTextProposal   (uint64 proposalID, string title, string desc, string url, uint32 deadline);
    event NewVote(uint64 proposalID, address voter, uint8 opinion, uint112 voteAmt);
    event AddVote(uint64 proposalID, address voter, uint8 opinion, uint112 voteAmt);
    event Revote (uint64 proposalID, address voter, uint8 opinion, uint112 voteAmt);
    event TallyResult(uint64 proposalID, bool pass);

    function ones() external pure returns (address);
    function proposalInfo() external view returns (
            uint24 id, address proposer, uint8 _type, uint32 deadline, address addr, uint256 value,
            uint112 totalYes, uint112 totalNo, uint112 totalDeposit);
    function voterInfo(address voter) external view returns (
            uint24 votedProposalID, uint8 votedOpinion, uint112 votedAmt, uint112 depositedAmt);

    function submitFundsProposal  (string calldata title, string calldata desc, string calldata url, address beneficiary, uint256 fundsAmt, uint112 voteAmt) external;
    function submitParamProposal  (string calldata title, string calldata desc, string calldata url, address factory, uint32 feeBPS, uint112 voteAmt) external;
    function submitUpgradeProposal(string calldata title, string calldata desc, string calldata url, address factory, address pairLogic, uint112 voteAmt) external;
    function submitTextProposal   (string calldata title, string calldata desc, string calldata url, uint112 voteAmt) external;
    function vote(uint8 opinion, uint112 voteAmt) external;
    function tally() external;
    function withdrawOnes(uint112 amt) external;
}

// File: contracts/interfaces/IOneSwapFactory.sol

pragma solidity 0.6.12;

interface IOneSwapFactory {
    event PairCreated(address indexed pair, address stock, address money, bool isOnlySwap);

    function createPair(address stock, address money, bool isOnlySwap) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFeeBPS(uint32 bps) external;
    function setPairLogic(address implLogic) external;

    function allPairsLength() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function feeBPS() external view returns (uint32);
    function pairLogic() external returns (address);
    function getTokensFromPair(address pair) external view returns (address stock, address money);
    function tokensToPair(address stock, address money, bool isOnlySwap) external view returns (address pair);
}

// File: contracts/OneSwapGov.sol

pragma solidity 0.6.12;




contract OneSwapGov is IOneSwapGov {

    struct VoterInfo {
        uint24  votedProposal;
        uint8   votedOpinion;
        uint112 votedAmt;     // enouth to store ONES
        uint112 depositedAmt; // enouth to store ONES
    }

    uint8   private constant _PROPOSAL_TYPE_FUNDS   = 1; // ask for funds
    uint8   private constant _PROPOSAL_TYPE_PARAM   = 2; // change factory.feeBPS
    uint8   private constant _PROPOSAL_TYPE_UPGRADE = 3; // change factory.pairLogic
    uint8   private constant _PROPOSAL_TYPE_TEXT    = 4; // pure text proposal
    uint8   private constant _YES = 1;
    uint8   private constant _NO  = 2;
    uint32  private constant _MIN_FEE_BPS = 0;
    uint32  private constant _MAX_FEE_BPS = 50;
    uint256 private constant _MAX_FUNDS_REQUEST = 5000000; // 5000000 ONES
    uint256 private constant _FAILED_PROPOSAL_COST = 1000; //    1000 ONES
    uint256 private constant _SUBMIT_ONES_PERCENT = 1; // 1%
    uint256 private constant _VOTE_PERIOD = 3 days;
    uint256 private constant _TEXT_PROPOSAL_INTERVAL = 1 days;

    address public  immutable override ones;
    uint256 private immutable _maxFundsRequest;    // 5000000 ONES
    uint256 private immutable _failedProposalCost; //    1000 ONES

    uint24  private _proposalID;
    uint8   private _proposalType; // FUNDS            | PARAM        | UPGRADE            | TEXT
    uint32  private _deadline;     // unix timestamp   | same         | same               | same
    address private _addr;         // beneficiary addr | factory addr | factory addr       | not used
    uint256 private _value;        // amount of funds  | feeBPS       | pair logic address | not used
    address private _proposer;
    uint112 private _totalYes;
    uint112 private _totalNo;
    uint112 private _totalDeposit;
    mapping (address => VoterInfo) private _voters;

    constructor(address _ones) public {
        ones = _ones;
        uint256 onesDec = IERC20(_ones).decimals();
        _maxFundsRequest = _MAX_FUNDS_REQUEST * (10 ** onesDec);
        _failedProposalCost = _FAILED_PROPOSAL_COST * (10 ** onesDec);
    }

    function proposalInfo() external view override returns (
            uint24 id, address proposer, uint8 _type, uint32 deadline, address addr, uint256 value,
            uint112 totalYes, uint112 totalNo, uint112 totalDeposit) {
        id           = _proposalID;
        proposer     = _proposer;
        _type        = _proposalType;
        deadline     = _deadline;
        value        = _value;
        addr         = _addr;
        totalYes     = _totalYes;
        totalNo      = _totalNo;
        totalDeposit = _totalDeposit;
    }
    function voterInfo(address voter) external view override returns (
            uint24 votedProposalID, uint8 votedOpinion, uint112 votedAmt, uint112 depositedAmt) {
        VoterInfo memory info = _voters[voter];
        votedProposalID = info.votedProposal;
        votedOpinion    = info.votedOpinion;
        votedAmt        = info.votedAmt;
        depositedAmt    = info.depositedAmt;
    }

    // submit new proposals
    function submitFundsProposal(string calldata title, string calldata desc, string calldata url,
            address beneficiary, uint256 fundsAmt, uint112 voteAmt) external override {
        if (fundsAmt > 0) {
            require(fundsAmt <= _maxFundsRequest, "OneSwapGov: ASK_TOO_MANY_FUNDS");
            uint256 govOnes = IERC20(ones).balanceOf(address(this));
            uint256 availableOnes = govOnes - _totalDeposit;
            require(govOnes > _totalDeposit && availableOnes >= fundsAmt,
                "OneSwapGov: INSUFFICIENT_FUNDS");
        }
        _newProposal(_PROPOSAL_TYPE_FUNDS, beneficiary, fundsAmt, voteAmt);
        emit NewFundsProposal(_proposalID, title, desc, url, _deadline, beneficiary, fundsAmt);
        _vote(_YES, voteAmt);
    }
    function submitParamProposal(string calldata title, string calldata desc, string calldata url,
            address factory, uint32 feeBPS, uint112 voteAmt) external override {
        require(feeBPS >= _MIN_FEE_BPS && feeBPS <= _MAX_FEE_BPS, "OneSwapGov: INVALID_FEE_BPS");
        _newProposal(_PROPOSAL_TYPE_PARAM, factory, feeBPS, voteAmt);
        emit NewParamProposal(_proposalID, title, desc, url, _deadline, factory, feeBPS);
        _vote(_YES, voteAmt);
    }
    function submitUpgradeProposal(string calldata title, string calldata desc, string calldata url,
            address factory, address pairLogic, uint112 voteAmt) external override {
        require(pairLogic != address(0), "OneSwapGov: INVALID_PAIR_LOGIC");
        _newProposal(_PROPOSAL_TYPE_UPGRADE, factory, uint256(pairLogic), voteAmt);
        emit NewUpgradeProposal(_proposalID, title, desc, url, _deadline, factory, pairLogic);
        _vote(_YES, voteAmt);
    }
    function submitTextProposal(string calldata title, string calldata desc, string calldata url,
            uint112 voteAmt) external override {
        // solhint-disable-next-line not-rely-on-time
        require(uint256(_deadline) + _TEXT_PROPOSAL_INTERVAL < block.timestamp,
            "OneSwapGov: COOLING_DOWN");
        _newProposal(_PROPOSAL_TYPE_TEXT, address(0), 0, voteAmt);
        emit NewTextProposal(_proposalID, title, desc, url, _deadline);
        _vote(_YES, voteAmt);
    }

    function _newProposal(uint8 _type, address addr, uint256 value, uint112 voteAmt) private {
        require(_type >= _PROPOSAL_TYPE_FUNDS && _type <= _PROPOSAL_TYPE_TEXT,
            "OneSwapGov: INVALID_PROPOSAL_TYPE");
        require(_type == _PROPOSAL_TYPE_TEXT || msg.sender == IOneSwapToken(ones).owner(),
            "OneSwapGov: NOT_ONES_OWNER");
        require(_proposalType == 0, "OneSwapGov: LAST_PROPOSAL_NOT_FINISHED");

        uint256 totalOnes = IERC20(ones).totalSupply();
        uint256 thresOnes = (totalOnes/100) * _SUBMIT_ONES_PERCENT;
        require(voteAmt >= thresOnes, "OneSwapGov: VOTE_AMOUNT_TOO_LESS");

        _proposalID++;
        _proposalType = _type;
        _proposer = msg.sender;
        // solhint-disable-next-line not-rely-on-time
        _deadline = uint32(block.timestamp + _VOTE_PERIOD);
        _value = value;
        _addr = addr;
        _totalYes = 0;
        _totalNo = 0;
    }
 
    function vote(uint8 opinion, uint112 voteAmt) external override {
        require(_proposalType > 0, "OneSwapGov: NO_PROPOSAL");
        // solhint-disable-next-line not-rely-on-time
        require(uint256(_deadline) > block.timestamp, "OneSwapGov: DEADLINE_REACHED");
        _vote(opinion, voteAmt);
    }

    function _vote(uint8 opinion, uint112 addedVoteAmt) private {
        require(_YES <= opinion && opinion <= _NO, "OneSwapGov: INVALID_OPINION");
        require(addedVoteAmt > 0, "OneSwapGov: ZERO_VOTE_AMOUNT");

        (uint24 currProposalID, uint24 votedProposalID,
            uint8 votedOpinion, uint112 votedAmt, uint112 depositedAmt) = _getVoterInfo();

        // cancel previous votes if opinion changed
        bool isRevote = false;
        if ((votedProposalID == currProposalID) && (votedOpinion != opinion)) {
            if (votedOpinion == _YES) {
                assert(_totalYes >= votedAmt);
                _totalYes -= votedAmt;
            } else {
                assert(_totalNo >= votedAmt);
                _totalNo -= votedAmt;
            }
            votedAmt = 0;
            isRevote = true;
        }

        // need to deposit more ONES?
        assert(depositedAmt >= votedAmt);
        if (addedVoteAmt > depositedAmt - votedAmt) {
            uint112 moreDeposit = addedVoteAmt - (depositedAmt - votedAmt);
            depositedAmt += moreDeposit;
            _totalDeposit += moreDeposit;
            IERC20(ones).transferFrom(msg.sender, address(this), moreDeposit);
        }

        if (opinion == _YES) {
            _totalYes += addedVoteAmt;
        } else {
            _totalNo += addedVoteAmt;
        }
        votedAmt += addedVoteAmt;
        _setVoterInfo(currProposalID, opinion, votedAmt, depositedAmt);
 
        if (isRevote) {
            emit Revote(currProposalID, msg.sender, opinion, addedVoteAmt);
        } else if (votedAmt > addedVoteAmt) {
            emit AddVote(currProposalID, msg.sender, opinion, addedVoteAmt);
        } else {
            emit NewVote(currProposalID, msg.sender, opinion, addedVoteAmt);
        }
    }
    function _getVoterInfo() private view returns (uint24 currProposalID,
            uint24 votedProposalID, uint8 votedOpinion, uint112 votedAmt, uint112 depositedAmt) {
        currProposalID = _proposalID;
        VoterInfo memory voter = _voters[msg.sender];
        depositedAmt = voter.depositedAmt;
        if (voter.votedProposal == currProposalID) {
            votedProposalID = currProposalID;
            votedOpinion = voter.votedOpinion;
            votedAmt = voter.votedAmt;
        }
    }
    function _setVoterInfo(uint24 proposalID,
            uint8 opinion, uint112 votedAmt, uint112 depositedAmt) private {
        _voters[msg.sender] = VoterInfo({
            votedProposal: proposalID,
            votedOpinion : opinion,
            votedAmt     : votedAmt,
            depositedAmt : depositedAmt
        });
    }

    function tally() external override {
        require(_proposalType > 0, "OneSwapGov: NO_PROPOSAL");
        // solhint-disable-next-line not-rely-on-time
        require(uint256(_deadline) <= block.timestamp, "OneSwapGov: STILL_VOTING");

        bool ok = _totalYes > _totalNo;
        uint8 _type = _proposalType;
        uint256 val = _value;
        address addr = _addr;
        address proposer = _proposer;
        _resetProposal();
        if (ok) {
            _execProposal(_type, addr, val);
        } else {
            _taxProposer(proposer);
        }
        emit TallyResult(_proposalID, ok);
    }
    function _resetProposal() private {
        _proposalType = 0;
     // _deadline     = 0; // use _deadline to check _TEXT_PROPOSAL_INTERVAL
        _value        = 0;
        _addr         = address(0);
        _proposer     = address(0);
        _totalYes     = 0;
        _totalNo      = 0;
    }
    function _execProposal(uint8 _type, address addr, uint256 val) private {
        if (_type == _PROPOSAL_TYPE_FUNDS) {
            if (val > 0) {
                IERC20(ones).transfer(addr, val);
            }
        } else if (_type == _PROPOSAL_TYPE_PARAM) {
            IOneSwapFactory(addr).setFeeBPS(uint32(val));
        } else if (_type == _PROPOSAL_TYPE_UPGRADE) {
            IOneSwapFactory(addr).setPairLogic(address(val));
        }
    }
    function _taxProposer(address proposerAddr) private {
        // burn 1000 ONES of proposer
        uint112 cost = uint112(_failedProposalCost);

        VoterInfo memory proposerInfo = _voters[proposerAddr];
        if (proposerInfo.depositedAmt < cost) { // unreachable!
            cost = proposerInfo.depositedAmt;
        }

        _totalDeposit -= cost;
        proposerInfo.depositedAmt -= cost;
        _voters[proposerAddr] = proposerInfo;

        IOneSwapToken(ones).burn(cost);
    }

    function withdrawOnes(uint112 amt) external override {
        VoterInfo memory voter = _voters[msg.sender];

        require(_proposalType == 0 || voter.votedProposal < _proposalID, "OneSwapGov: IN_VOTING");
        require(amt > 0 && amt <= voter.depositedAmt, "OneSwapGov: INVALID_WITHDRAW_AMOUNT");

        _totalDeposit -= amt;
        voter.depositedAmt -= amt;
        if (voter.depositedAmt == 0) {
            delete _voters[msg.sender];
        } else {
            _voters[msg.sender] = voter;
        }
        IERC20(ones).transfer(msg.sender, amt);
    }

}