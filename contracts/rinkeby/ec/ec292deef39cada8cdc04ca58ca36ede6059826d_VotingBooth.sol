/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\balancer-labs\configurable-rights-pool\libraries\BalancerConstants.sol

pragma solidity ^0.8.0;

/**
 * @author Balancer Labs
 * @title Put all the constants in one place
 */

library BalancerConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = BONE / 10**6;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint public constant MIN_ASSET_LIMIT = 2;
    uint public constant MAX_ASSET_LIMIT = 8;
    uint public constant MAX_UINT = type(uint).max;
}

// File: contracts\balancer-labs\configurable-rights-pool\libraries\BalancerSafeMath.sol

pragma solidity ^0.8.0;


// Imports


/**
 * @author Balancer Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library BalancerSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint c1 = c0 + (BalancerConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BalancerConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0){
            return 0;
        }

        uint c0 = dividend * BalancerConstants.BONE;
        require(c0 / dividend == BalancerConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts\balancer-labs\configurable-rights-pool\contracts\IBFactory.sol

pragma solidity ^0.8.0;

interface IBPool {
    function rebind(address token, uint balance, uint denorm) external;
    function setSwapFee(uint swapFee) external;
    function setPublicSwap(bool publicSwap) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;
    function isBound(address token) external view returns(bool);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
    function getSwapFee() external view returns (uint);
    function isPublicSwap() external view returns (bool);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint);
 
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint poolAmountIn);

    function getCurrentTokens()
        external view
        returns (address[] memory tokens);
}

interface IBFactory {
    function newBPool() external returns (IBPool);
    function setBLabs(address b) external;
    function collect(IBPool pool) external;
    function isBPool(address b) external view returns (bool);
    function getBLabs() external view returns (address);
}

// File: contracts\utils\Interfaces.sol

pragma solidity ^0.8.0;

contract Interfaces { }

//for the buoy ERC20
interface Buoy {
    function mineMint(uint, address) external;
    function lotteryMint(uint, address) external;
}

//for the smart pool
interface SPool {
    function setController(address newOwner) external;
    function setPublicSwap(bool publicSwap) external;
    function removeToken(address token) external;
    function changeOwner(address newOwner) external;
    function changeWeight(uint[] calldata) external;
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external;
    function applyAddToken() external;
    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    ) external;
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    ) external;
}
    
//for uniswap deposit
interface UniswapInterface {
    function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

//for the address interface
interface  IAddressIndex {
    function setBuoy(address newaddress) external;
    function getBuoy() external view returns(address);
    function setUniswap(address newaddress) external;
    function getUniswap() external view returns(address);
    function setBalancerPool(address newaddress) external;
    function getBalancerPool() external view returns(address);
    function setSmartPool(address newaddress) external;
    function getSmartPool() external view returns(address);
    function setXBuoy(address newaddress) external;
    function getXBuoy() external view returns(address);
    function setProxy (address newaddress) external;
    function getProxy() external view returns(address);
    function setMine(address newaddress) external;
    function getMine() external view returns(address);
    function setVotingBooth(address newaddress) external;
    function getVotingBooth() external view returns(address);
    function setLottery(address newaddress) external;
    function getLottery() external view returns(address);
}

//for the xbuoy NFT
interface IBuoy {
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
    function burn(uint _id) external;
    function setBuoyMine(address newAddress) external;
    function safeTransferfrom(address from, address to, uint256 tokenId) external;
    function setNFT(uint,uint,uint) external;
    function killNFT(uint) external;
    function viewNFT(uint id) external view returns(
        bool active,
        uint contributed, 
        uint allotment, 
        uint rewards, 
        uint payouts, 
        uint nextClaim,
        address platform);
    function craftNFT(
        address sender, 
        uint contributed, 
        uint allotment, 
        uint rewards, 
        uint payouts, 
        uint nextClaim,
        address platform
        ) external;
}

//for the liquidity staking mine
interface Mine {
    function setStakingActive(bool active) external;
    function setSwapingActive(bool active) external;
    function changeStakingMax(uint[] calldata newMax) external;
    function changeStakingShare(uint[] calldata newShare) external;
}

interface ILottery {
    function setShare(uint[] calldata array) external;
    function setDrawLength(uint[] calldata array) external;
    function setIncrementing(uint uintArray, bool boolArray) external;
}

// File: contracts\VotingBooth.sol

pragma solidity ^0.8.0;





/**
 * 
 * make a function to toss a proposal if no one can call enact based on time limt
 * 
 * _changeDelegationMinimum
 * setBuoy
 * setBPool
 * setSwapFee
 * changeOwner
 * setStakingActive
 * setSwapingActive 
 * changeOwner
 * changeWeight
 * changeStakingMax
 * changeStakingShare
 * 
 * update weights must be passed weights as a string
 * add token needs amount of token to add in the contract
 * remove token takes the amount of bpt to be burned
 * 
 * 
 * */

contract VotingBooth {
    using BalancerSafeMath for uint256;
    address index;
    uint256 public lastProposed;
    uint256 public proposalCount; //used to assign a unique ID to each proposal
    uint256 public proposalDelegationMinimum;
    uint256 public activeProposals;
    uint256 public pruned;
    uint256 public proposalLength;
    mapping (address => Delegation) delegation;
    mapping (address => bool) proposers;
    mapping (uint => Proposal) proposal;

    struct Delegation {
        uint withdrawDate;
        uint delegated;
    }

    struct Proposal {
        uint proposaltype;
        uint creationDate;
        uint startDate;
        address proposer;
        uint[] uints;
        address[] addresses;
        bool[] bools;
        uint yesVotes;
        uint noVotes;
        bool active;
    }
    
    event ProposalMade(uint id, address proposer);
    event ProposalVoted(uint id, bool outcome);
    event ProposalPurged(uint id);

    IAddressIndex addressIndex;
    
    constructor(address x) 
    {
        index = x;
        addressIndex = IAddressIndex(index);
        proposalDelegationMinimum = 1*(10**18);
        proposalLength = 6 hours;
    }
    
    
//=======================enactable functions======================//
    
    function _setSwapFee(uint _swapFee) private {
        IBPool ibpool = IBPool(addressIndex.getSmartPool());
        ibpool.setSwapFee(_swapFee);
    }    
    
    function _setDelegationMinimum(uint a) private {
        proposalDelegationMinimum = a;
    }
    
    function setSwapingActive(bool active) public {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.setPublicSwap(active);
    }

    function applyAddToken() public {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.applyAddToken();
    }
    
//========================vote functions=============================//
    
    //modified for testing
    function newProposal(uint propType, uint[] calldata uints, address[] calldata addresses, bool[] calldata bools) public  {
        IERC20 buoyERC20 = IERC20(addressIndex.getBuoy());
        require(propType > 0 && propType <= 15);
        require(buoyERC20.balanceOf(msg.sender) >= proposalDelegationMinimum, "Need more buoy for delegation");
        //require(proposers[msg.sender] == false, "Address has an active proposal already");
        buoyERC20.transferFrom(msg.sender, address(this), proposalDelegationMinimum);
        uint creationDate = block.timestamp;
        uint startDate;
        if(lastProposed > (creationDate - proposalLength) && lastProposed != 0) {
            startDate = lastProposed + proposalLength;
        } else {
            startDate = creationDate;
        }
        delegation[msg.sender] = Delegation(startDate + proposalLength, proposalDelegationMinimum);
        proposal[proposalCount] = Proposal(propType, creationDate, startDate, msg.sender, uints, addresses, bools, 0, 0, true);
        emit ProposalMade(proposalCount, msg.sender);
        proposers[msg.sender] = true;
        prune();
        activeProposals++;
        proposalCount++;
        lastProposed = startDate;
    }
    
    // 0 = no, 1 = yes. voteWeight is measured in wei. approvals must be made before you can delegate
    function castVoteERC20(uint propID, uint vote, uint voteWeight) public {
        IERC20 BuoyERC20 = IERC20(addressIndex.getBuoy());
        uint256 maxVoteWeight = BuoyERC20.balanceOf(msg.sender);
        //require(propID <= proposalCount && propID >= proposalsVoted, 'Not a valid ID');        
        require(vote == 0 || vote == 1, 'Vote must be 0 or 1');
        require(voteWeight > 0 && voteWeight <= maxVoteWeight, 'Vote weight not valid');
        //require(block.timestamp >= proposal[propID].startDate, 'Proposal not started');
        //require(block.timestamp <= proposal[propID].startDate+proposalLength, 'Proposal ended');
        BuoyERC20.transferFrom(msg.sender, address(this), voteWeight);
        delegation[msg.sender] = Delegation(proposal[propID].startDate+proposalLength,voteWeight);
        if(vote == 0) {
            proposal[propID].noVotes = proposal[propID].noVotes.badd(voteWeight);
        } else {
            proposal[propID].yesVotes = proposal[propID].yesVotes.badd(voteWeight);
        }
    }

    // 0 = no, 1 = yes. voteWeight is based on tokens given to stake. approvals must be made before you can delegate
    function castVoteERC721(uint propID, uint vote,  uint id) public {
        IBuoy buoyERC721 = IBuoy(addressIndex.getXBuoy());
        uint256 _voteWeight;
        (,,_voteWeight,,,,) = buoyERC721.viewNFT(id);
        //require(proposalActive == true, 'No active proposal'); change to check the proposal itself
        require(vote == 0 || vote == 1, 'Vote must be 0 or 1');
        //require(block.timestamp >= proposal[propID].startDate, 'Proposal not started');
        //require(block.timestamp <= proposal[propID].startDate+proposalLength, 'Proposal ended');
        buoyERC721.safeTransferfrom(msg.sender, address(this), id);
        delegation[msg.sender] = Delegation(proposal[propID].startDate+proposalLength,_voteWeight);
        if(vote == 0) {
            proposal[propID].noVotes = proposal[propID].noVotes.badd(_voteWeight);
        } else {
            proposal[propID].yesVotes = proposal[propID].yesVotes.badd(_voteWeight);
        }
    }
    
    function withdrawDelegation() public {
        IERC20 BuoyERC20 = IERC20(addressIndex.getBuoy());
        uint delegated = delegation[msg.sender].delegated;
        require(delegated > 0, 'No tokens delegated');
        require(block.timestamp > delegation[msg.sender].withdrawDate, 'Too early');
        delegation[msg.sender].delegated = 0;
        BuoyERC20.transfer(msg.sender, delegated);
    }
    
    
    function endVote(uint id) public returns (bool) {
        uint startDate = proposal[id].startDate;
        //require(block.timestamp > startDate + proposalLength && startDate != 0, 'Not an endable proposal');
        require(proposal[id].active == true, 'Proposal not active');
        bool passed;
        address propAcc = proposal[id].proposer;
        if(proposal[id].yesVotes > proposal[id].noVotes) {
            passed = true;
            _enactProposal(id);
        }
        proposers[propAcc] = false;
        proposal[id].active = false;
        activeProposals--;
        emit ProposalVoted(id, passed);
        return passed;
    }
    
    //in case of proposal being voted in but throws error when enacted
    function purgeProposal(uint id) public {
        require(proposal[id].active == true, 'Proposal no longer active');
        require(block.timestamp > proposal[id].startDate + 6 hours);
        proposal[id].active = false;
        proposers[proposal[id].proposer] = false;
        activeProposals--;
        emit ProposalPurged(id);
    }
    
    function prune() public {
        uint pruneLine = pruned;
        for(pruneLine; pruneLine < proposalCount-pruned; pruneLine++) {
            if(proposal[pruneLine].active == true) {
                pruned = pruneLine;
                pruneLine = proposalCount-pruned;
            }
        } 
    }
    
    function applyt() public {
        SPool spool = SPool(addressIndex.getProxy());
        spool.applyAddToken();
    }
    
    function _enactProposal(uint id) public {
        //type 1 - change minimum delegation needed to make a proposal
        if(proposal[id].proposaltype == 1) {
            _setDelegationMinimum(proposal[id].uints[0]);
        } else 
        //type 2 - change the swap fee for the smart pool (program in requirements for proper input)
        if(proposal[id].proposaltype == 2) {
            _setSwapFee(proposal[id].uints[0]);
        } else 
        //type 3 - change the liquidity mine 
        if(proposal[id].proposaltype == 3) {
            addressIndex.setMine(proposal[id].addresses[0]);
        } else
        //type 4 - change the Balancer Smartpool 
        if(proposal[id].proposaltype == 4) {
            addressIndex.setSmartPool(proposal[id].addresses[0]);
        } else
        //type 5 - change the owner of the Balancer Smartpool
        if(proposal[id].proposaltype == 5) {
            SPool spool = SPool(addressIndex.getSmartPool());
            spool.setController(proposal[id].addresses[0]);
            addressIndex.setProxy(proposal[id].addresses[0]);
        } else
        //type 6 - de or re activate staking
        if(proposal[id].proposaltype == 6) {
            Mine mine = Mine(addressIndex.getMine());
            mine.setStakingActive(proposal[id].bools[0]);
        } else
        //type 7 - de or re activate trades in the Smartpool
        if(proposal[id].proposaltype == 7) {
            setSwapingActive(proposal[id].bools[0]);
        } else
        //type 8 - change the staking maxs for each period
        if(proposal[id].proposaltype == 8) {
            Mine mine = Mine(addressIndex.getMine());
            mine.changeStakingMax(proposal[id].uints);
        } else
        //type 9 - change the share given by each period
        if(proposal[id].proposaltype == 9) {
            Mine mine = Mine(addressIndex.getMine());
            mine.changeStakingShare(proposal[id].uints);
        } else
        //type 10 - change the weights of each token
        if(proposal[id].proposaltype == 10) {
            SPool spool = SPool(addressIndex.getSmartPool());
            spool.updateWeightsGradually(proposal[id].uints, block.number, block.number + 3 days);
        } else
        //type 11 - add a new token to the pool
        if(proposal[id].proposaltype == 11) {
            SPool spool = SPool(addressIndex.getSmartPool());
            spool.commitAddToken(proposal[id].addresses[0], proposal[id].uints[0], proposal[id].uints[1]);
        } else
        //type 12 - remove a token to the pool
        if(proposal[id].proposaltype == 12) {
            require(proposal[id].addresses[0] != addressIndex.getBuoy());
            SPool spool = SPool(addressIndex.getSmartPool());
            spool.removeToken(proposal[id].addresses[0]);
        } else
        //type 13 - set shares
        if(proposal[id].proposaltype == 13) {
            ILottery lottery = ILottery(addressIndex.getLottery());
            lottery.setShare(proposal[id].uints);
        } else
        //type 14 - set draw length
        if(proposal[id].proposaltype == 14) {
            ILottery lottery = ILottery(addressIndex.getLottery());
            lottery.setDrawLength(proposal[id].uints);
        } else
        //type 15 - set incrementing
        if(proposal[id].proposaltype == 15) {
            ILottery lottery = ILottery(addressIndex.getLottery());
            lottery.setIncrementing(proposal[id].uints[0],proposal[id].bools[0]);
        } 
    } 
    
//=======================view functions======================//

    function viewProposal(uint id) public view returns(uint propType,
        uint creationDate,
        uint startDate,
        address proposer,
        uint [] memory uints,
        address [] memory addresses,
        bool [] memory bools,
        uint yesVotes,
        uint noVotes,
        bool active) {
            Proposal memory prop = proposal[id];
            return(prop.proposaltype,
            prop.creationDate,
            prop.startDate,
            prop.proposer,
            prop.uints,
            prop.addresses,
            prop.bools,
            prop.yesVotes,
            prop.noVotes,
            prop.active);
    }

    function viewActiveProposals() public view returns(uint[] memory) {
        uint[] memory array = new uint[](activeProposals);
        uint nonce;
        uint i = pruned;
        for(i; i < proposalCount; i++) {
            if(proposal[i].active == true) {
                array[nonce] = i;
                nonce++;
            }
        }
        return(array);
    }
    
    function viewDelgated(address a) public view returns(uint,uint) {
        return(delegation[a].withdrawDate,delegation[a].delegated);
    }
    
    function viewMyDelgated() public view returns(uint,uint) {
        return(delegation[msg.sender].withdrawDate,delegation[msg.sender].delegated);
    }

//========================testing functions======================//

    function quickKill(uint id) public {
        proposal[id].active = false;
        activeProposals--;
    }
    
    function changePoolOwner(address x) public {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.setController(x);
        addressIndex.setProxy(x);
    }
    
}