// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './BEP20.sol';
import './SafeBEP20.sol';

// EggToken with Governance.
contract EggToken is BEP20('Goose Golden Egg', 'EGG') {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "EGG::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "EGG::delegateBySig: invalid nonce");
        require(now <= expiry, "EGG::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "EGG::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying EGGs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "EGG::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract Lottery is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;


    // The EGG TOKEN!
    IBEP20 public egg;
    uint public perEggAmount = 1000000000000000000;
    uint public upperLimit =   5000000000000000000;
    
    uint firstPrizes = 1;
    uint secondPrizes = 1;
    uint thirdPrizes = 1;
    uint fourthPrizes = 2;

    bool public drawPrize = false;
    struct rewardInfo {
        address addr;
        uint prizes;
    }
    uint public round = 1;  //第几轮
    mapping(uint=>address[]) public players; //第几轮的玩家地址
    mapping(uint=>mapping(address=>bool)) hasParticipate; //第几轮的玩家是否已参与
    mapping(uint=>uint) public roundAccumulatedAmount; //第几轮的积累资金
    mapping(uint=>uint[]) public roundWinner; //第几轮的中奖id
    mapping(uint=>mapping(uint=>rewardInfo)) public roundReward; //第几轮的中奖id对应的奖励
    mapping(uint=>mapping(address=>uint)) public prizes;


    event Participate(address indexed user, uint amount,uint round);

    constructor(IBEP20 _egg) public {
        egg=_egg;
    }

    
    function participate() public {
        require(roundAccumulatedAmount[round]<upperLimit,"Participation has reached the limit");
        require(!hasParticipate[round][msg.sender],"this user has participate this round!");
        hasParticipate[round][msg.sender]=true;
        players[round].push(msg.sender);

        roundAccumulatedAmount[round]=roundAccumulatedAmount[round].add(perEggAmount);
        egg.safeTransferFrom(address(msg.sender), address(this), perEggAmount);
        if(roundAccumulatedAmount[round]>=upperLimit){
            pickWinner();
        }
        emit Participate(msg.sender, perEggAmount,round);
    }

    function winnerNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players[round])));
    }


    function pickWinner() private {
        //require(roundAccumulatedAmount[round]>=upperLimit,"Participation has not reached the limit");
        //require(drawPrize == false,"it has draw");
        _openFirstPrize();
        _openSecondPrize();
        _openThirdPrize();
        _openFourthPrize();
        round=round.add(1);
        //drawPrize=true;
    }

    function _openThirdPrize() private {
        for(uint i=thirdPrizes;i>0;i--) {
        uint playerId=winnerNumber()% players[round].length;
        address winner = players[round][playerId];
        if (prizes[round][winner] != 0) {
                i++;
        }else{
        prizes[round][winner] = 3;
        roundWinner[round].push(playerId);
        roundReward[round][playerId].addr=winner;
        roundReward[round][playerId].prizes=3;
            }
        }
    }

    function _openSecondPrize() private {
        for(uint i=secondPrizes;i>0;i--) {
        uint playerId=winnerNumber()% players[round].length;
        address winner = players[round][playerId];
        if (prizes[round][winner] != 0) {
                i++;
        }else{
        prizes[round][winner] = 2;
        roundWinner[round].push(playerId);
        roundReward[round][playerId].addr=winner;
        roundReward[round][playerId].prizes=2;
            }
        }
    }

    function _openFirstPrize() private {
        for(uint i=firstPrizes;i>0;i--) {
        uint playerId=winnerNumber()% players[round].length;
        address winner = players[round][playerId];
        if (prizes[round][winner] != 0) {
                i++;
        }else{
        prizes[round][winner] = 1;
        roundWinner[round].push(playerId);
        roundReward[round][playerId].addr=winner;
        roundReward[round][playerId].prizes=1;
            }
        }
    }

    
    function _openFourthPrize() private {
        for(uint i=fourthPrizes;i>0;i--) {
        uint playerId=winnerNumber()% players[round].length;
        address winner = players[round][playerId];
        if (prizes[round][winner] != 0) {
                i++;
        }else{
        prizes[round][winner] = 4;
        roundWinner[round].push(playerId);
        roundReward[round][playerId].addr=winner;
        roundReward[round][playerId].prizes=4;
            }
        }
    }

    function getAllPlayers(uint _round) public view returns (address[] memory) {
        return players[_round];
    }

    function getWinnerIds(uint _round) public view returns (uint[] memory) {
        return roundWinner[_round];
    }

    function getRewardById(uint _round,uint _id) public view returns (address,uint) {
        return (roundReward[_round][_id].addr,roundReward[_round][_id].prizes);
    }

    function withdrawEgg(address _user,uint _amount) public onlyOwner{
        egg.safeTransfer(_user,_amount);
    } 
}