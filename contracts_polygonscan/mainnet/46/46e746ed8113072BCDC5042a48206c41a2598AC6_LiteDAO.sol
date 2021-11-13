/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation with COMP-style governance,
/// @author Adapted from RariCapital, https://github.com/Rari-Capital/solmate/blob/main/src/erc20/ERC20.sol,
/// License-Identifier: AGPL-3.0-only.
contract LiteDAOtoken {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    event TogglePause(bool indexed paused);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                              DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    bool public paused;

    bytes32 public constant DELEGATION_TYPEHASH = keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    mapping(address => address) public delegates;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => uint256) public numCheckpoints;

    struct Checkpoint {
        uint32 fromTimestamp;
        uint224 votes;
    }

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] memory voters,
        uint256[] memory shares
    ) {
        require(voters.length == shares.length, 'NO_ARRAY_PARITY');

        name = name_;
        symbol = symbol_;
        paused = paused_;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
        
        // this is reasonably safe from overflow because incrementing `i` loop beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            for (uint256 i; i < voters.length; i++) {
                _mint(voters[i], shares[i]);

                _delegate(voters[i], voters[i]);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external notPaused returns (bool) {
        balanceOf[msg.sender] -= amount;

        // this is safe from overflow because the sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external notPaused returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // this is safe from overflow because the sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              DAO LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier notPaused() {
        require(!paused, 'PAUSED');
        _;
    }

    function getCurrentVotes(address account) external view returns (uint256 votes) {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];

            votes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    function delegate(address delegatee) external {
        _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), 'ZERO_ADDRESS');
        
        // this is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            require(nonce == nonces[signatory]++, 'INVALID_NONCE');
        }

        require(block.timestamp <= expiry, 'SIGNATURE_EXPIRED');

        _delegate(signatory, delegatee);
    }

    function getPriorVotes(address account, uint256 timestamp) public view returns (uint256 votes) {
        require(block.timestamp > timestamp, 'NOT_YET_DETERMINED');

        uint256 nCheckpoints = numCheckpoints[account];

        if (nCheckpoints == 0) {
            return 0;
        }
        
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }

            if (checkpoints[account][0].fromTimestamp > timestamp) {
                return 0;
            }

            uint256 lower;
            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            uint256 upper = nCheckpoints - 1;

            while (upper > lower) {
                // this is safe from underflow because `upper` ceiling is provided
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = checkpoints[account][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

        return checkpoints[account][lower].votes;

        }
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];

        delegates[delegator] = delegatee;

        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];

                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

                uint256 dstRepNew = dstRepOld + amount;

                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = safeCastTo224(newVotes);
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(safeCastTo32(block.timestamp), safeCastTo224(newVotes));
                // this is reasonably safe from overflow because incrementing `nCheckpoints` beyond
                // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function _computeDomainSeparator() internal view returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, 'PERMIT_DEADLINE_EXPIRED');

        // this is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_PERMIT_SIGNATURE');

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    /*///////////////////////////////////////////////////////////////
                           MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        // this is safe because the sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;

        // this is safe because a user won't ever
        // have a balance larger than `totalSupply`
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /*///////////////////////////////////////////////////////////////
                           PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _togglePause() internal {
        paused = !paused;

        emit TogglePause(paused);
    }
    
     /*///////////////////////////////////////////////////////////////
                           SAFECAST LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max);

        y = uint32(x);
    }
    
    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x <= type(uint224).max);

        y = uint224(x);
    }
}

/// @notice Helper for NFT 'safe' transfers.
contract LiteDAOnftHelper {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 sig) {
        sig = 0x150b7a02; // 'onERC721Received(address,address,uint256,bytes)'
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 sig) {
        sig = 0xf23a6e61; // 'onERC1155Received(address,address,uint256,uint256,bytes)'
    }
    
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 sig) {
        sig = 0xbc197c81; // 'onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)'
    }
}

/// @notice Simple gas-optimized DAO core module.
contract LiteDAO is LiteDAOtoken, LiteDAOnftHelper {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewProposal(uint256 indexed proposal);
    
    event VoteCast(address indexed voter, uint256 indexed proposal, bool indexed approve);

    event ProposalProcessed(uint256 indexed proposal);

    /*///////////////////////////////////////////////////////////////
                              DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public proposalCount;

    uint256 public votingPeriod;

    uint256 public quorum; // 1-100

    uint256 public supermajority; // 1-100

    bool private initialized;

    mapping(uint256 => Proposal) public proposals;

    mapping(ProposalType => VoteType) public proposalVoteTypes;
    
    mapping(uint256 => mapping(address => bool)) public voted;

    enum ProposalType {
        MINT,
        BURN,
        CALL,
        GOV
    }

    enum VoteType {
        SIMPLE_MAJORITY,
        SIMPLE_MAJORITY_QUORUM_REQUIRED,
        SUPERMAJORITY,
        SUPERMAJORITY_QUORUM_REQUIRED
    }

    struct Proposal {
        ProposalType proposalType;
        string description;
        address[] account; // member(s) being added/kicked; account(s) receiving payload
        uint256[] amount; // value(s) to be minted/burned/spent; gov setting(s)
        bytes[] payload; // data for CALL proposals
        uint256 yesVotes;
        uint256 noVotes;
        uint256 creationTime;
    }

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] memory voters,
        uint256[] memory shares,
        uint256 votingPeriod_,
        uint256 quorum_,
        uint256 supermajority_
    )
        LiteDAOtoken(
            name_,
            symbol_,
            paused_,
            voters,
            shares
        )

    {
        require(votingPeriod_ <= 365 days, 'VOTING_PERIOD_MAX');
        
        require(quorum_ <= 100, 'QUORUM_MAX');
        
        require(supermajority_ <= 100, 'SUPERMAJORITY_MAX');
        
        votingPeriod = votingPeriod_;
        
        quorum = quorum_;
        
        supermajority = supermajority_;
    }

    function setVoteTypes(
        uint8 mint,
        uint8 burn,
        uint8 call,
        uint8 gov
    ) external {
        require(!initialized, 'INITIALIZED');

        proposalVoteTypes[ProposalType.MINT] = VoteType(mint);

        proposalVoteTypes[ProposalType.BURN] = VoteType(burn);

        proposalVoteTypes[ProposalType.CALL] = VoteType(call);

        proposalVoteTypes[ProposalType.GOV] = VoteType(gov);

        initialized = true;
    }

    /*///////////////////////////////////////////////////////////////
                         PROPOSAL LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier onlyTokenHolders() {
        require(balanceOf[msg.sender] > 0, 'NOT_TOKEN_HOLDER');
        _;
    }

    function propose(
        ProposalType proposalType,
        string calldata description,
        address[] calldata account,
        uint256[] calldata amount,
        bytes[] calldata payload
    ) external onlyTokenHolders {
        require(account.length == amount.length && amount.length == payload.length, "NO_ARRAY_PARITY");
        
        require(payload.length <= 10, "ARRAY_MAX");
        
        if (proposalType == ProposalType.GOV) {
            require(amount[0] <= 365 days, 'VOTING_PERIOD_MAX');
            
            require(amount[1] <= 100, 'QUORUM_MAX');
            
            require(amount[2] <= 100, 'SUPERMAJORITY_MAX');
        }
        
        uint256 proposal = proposalCount;

        proposals[proposal] = Proposal({
            proposalType: proposalType,
            description: description,
            account: account,
            amount: amount,
            payload: payload,
            yesVotes: 0,
            noVotes: 0,
            creationTime: block.timestamp
        });
        
        // this is reasonably safe from overflow because incrementing `proposalCount` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        unchecked {
            proposalCount++;
        }

        emit NewProposal(proposal);
    }

    function vote(uint256 proposal, bool approve) external onlyTokenHolders {
        require(!voted[proposal][msg.sender], 'ALREADY_VOTED');
        
        Proposal storage prop = proposals[proposal];
        
        // this is safe from overflow because `votingPeriod` is capped so it will not combine
        // with unix time to exceed 'type(uint256).max'
        unchecked {
            require(block.timestamp <= prop.creationTime + votingPeriod, 'VOTING_ENDED');
        }

        uint256 weight = getPriorVotes(msg.sender, prop.creationTime);
        
        // this is safe from overflow because `yesVotes` and `noVotes` are capped by `totalSupply`
        // which is checked for overflow in `LiteDAOtoken` contract
        unchecked { 
            if (approve) {
                prop.yesVotes += weight;
            } else {
                prop.noVotes += weight;
            }
        }
        
        voted[proposal][msg.sender] = true;
        
        emit VoteCast(msg.sender, proposal, approve);
    }

    function processProposal(uint256 proposal) external {
        Proposal storage prop = proposals[proposal];
        
        VoteType voteType = proposalVoteTypes[prop.proposalType];

        // * COMMENTED OUT FOR TESTING * ///
        // unchecked {
        // require(block.timestamp > prop.creationTime + votingPeriod, 'VOTING_NOT_ENDED');
        // }

        bool didProposalPass = _countVotes(voteType, prop.yesVotes, prop.noVotes);
        
        // this is reasonably safe from overflow because incrementing `i` loop beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits
        if (didProposalPass) {
            unchecked {
                if (prop.proposalType == ProposalType.MINT) {
                    for (uint256 i; i < prop.account.length; i++) {
                        _mint(prop.account[i], prop.amount[i]);
                    }
                }

                if (prop.proposalType == ProposalType.BURN) {
                    for (uint256 i; i < prop.account.length; i++) {
                        _burn(prop.account[i], prop.amount[i]);
                    }
                }

                if (prop.proposalType == ProposalType.CALL) {
                    for (uint256 i; i < prop.account.length; i++) {
                        prop.account[i].call{value: prop.amount[i]}(prop.payload[i]);
                    }
                }

                if (prop.proposalType == ProposalType.GOV) {
                    if (prop.amount[0] > 0) votingPeriod = prop.amount[0];
                    if (prop.amount[1] > 0) quorum = prop.amount[1];
                    if (prop.amount[2] > 0) supermajority = prop.amount[2];
                    if (prop.amount[3] > 0) _togglePause();
                }
            }
        }

        delete proposals[proposal];

        emit ProposalProcessed(proposal);
    }

    function _countVotes(
        VoteType voteType,
        uint256 yesVotes,
        uint256 noVotes
    ) internal view returns (bool didProposalPass) {
        // rule out any failed quorums
        if (voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED || voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED) {
            uint256 minVotes = (totalSupply * quorum) / 100;
            
            // this is safe from overflow because `yesVotes` and `noVotes` are capped by `totalSupply`
            // which is checked for overflow in `LiteDAOtoken` contract
            unchecked {
                uint256 votes = yesVotes + noVotes;

                require(votes >= minVotes, 'QUORUM_REQUIRED');
            }
        }

        // simple majority
        if (voteType == VoteType.SIMPLE_MAJORITY || voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED) {
            if (yesVotes > noVotes) {
                didProposalPass = true;
            }
        }

        // supermajority
        if (voteType == VoteType.SUPERMAJORITY || voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED) {
            // example: 7 yes, 2 no, supermajority = 66
            // ((7+2) * 66) / 100 = 5.94; 7 yes will pass
            uint256 minYes = ((yesVotes + noVotes) * supermajority) / 100;

            if (yesVotes >= minYes) {
                didProposalPass = true;
            }
        }
    }
}