/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: contracts/balancer/libraries/BalancerConstants.sol

 
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

// File: contracts/balancer/libraries/BalancerSafeMath.sol

 
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

// File: contracts/balancer/interfaces/IERC20.sol

 
pragma solidity ^0.8.0;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// File: contracts/utils/Interfaces.sol


pragma solidity ^0.8.0;

contract Interfaces { }

//for the xbuoy ERC20
interface BuoyMine {
    function mineMint(uint, address) external;
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
    function proposeAddToken(
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
    function setGovernanceProxy(address newaddress) external;
    function getGovernanceProxy() external view returns(address);
    function setMine(address newaddress) external;
    function getMine() external view returns(address);
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

// File: contracts/LiquidityMine.sol

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;



 
contract LiquidityMine {
    using BalancerSafeMath for uint;
    
    address payable public owner;
    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address index = 0x50AdbC26BE7C5136B945927A0A31196c57800049;
    
    uint256 stakingBlock = 1 minutes;

    //these arrays will have 3 uints, 0 is 3 months, 1 is 6 months, 2 is 12 months
    uint256[] public stakingAllocations;
    uint256[] public stakingMaxs;
    uint256[] public stakingShares;

    bool public stakingActive; 

    IAddressIndex addressIndex;
    UniswapInterface routerContract = UniswapInterface(uniswapRouter);

    receive() external payable {
    }
    
    constructor() {
        owner = payable(msg.sender);
        stakingAllocations = [0,0,0];
        stakingMaxs = [10000000000 * (10 ** 18),10000000000 * (10 ** 18),10000000000 * (10 ** 18)];
        stakingShares = [30,75,200];
        stakingActive = true;
        addressIndex = IAddressIndex(index);
    }
    
//==================enactble functions=======================//

    function setStakingActive(bool active) public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        stakingActive = active;
    }

    function setSwapingActive(bool active) public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.setPublicSwap(active);
    }
    
    function changeWeight(uint[] calldata) public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        SPool spool = SPool(addressIndex.getSmartPool());
        uint[] memory weights;
        uint timeCalled = block.timestamp;
        spool.updateWeightsGradually(weights,
        timeCalled,
        timeCalled + 3 days);
    }

    function changeStakingMax(uint[] calldata newMax) public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        require(newMax.length == 3, 'Wrong number of arguments');
        stakingMaxs = newMax;
    }
    
    function changeStakingShare(uint[] calldata newShare) public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        require(newShare.length == 3, 'Wrong number of arguments');
        stakingShares = newShare;
    }
    
    function proposeAddToken(address token, uint balance, uint denormalizedWeight) public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.proposeAddToken(token, balance, denormalizedWeight);
    }

    function applyAddToken() public {
        require(msg.sender == addressIndex.getGovernanceProxy(), 'Not authorized');
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.applyAddToken();
    }
    

//=======================================staking========================================//

    function uniswapLiquidityDeposit(uint tokenAmountIn, uint lockLength) public payable returns(uint) {
        address buoy = addressIndex.getBuoy();
        address uniswapToken = addressIndex.getUniswap();
        IERC20 buoyERC20 = IERC20(buoy);
        IERC20 uniswapERC20 = IERC20(uniswapToken);
        require(stakingActive == true);
        require(buoyERC20.balanceOf(address(this)) == 0, 'Call purge');
        require(address(this).balance <= msg.value, 'Not enough eth');
        uint initBalance = uniswapERC20.balanceOf(address(this));
        uint deadline = block.timestamp + 15;
        uint buoyContributed;
        buoyERC20.approve(uniswapRouter, type(uint).max);
        buoyERC20.transferFrom(msg.sender, address(this), tokenAmountIn);
        routerContract.addLiquidityETH{value: msg.value}(buoy, tokenAmountIn, 1, 1, address(this), deadline);
        if(address(this).balance == 0) {
            uint balance = buoyERC20.balanceOf(address(this));
            buoyContributed = tokenAmountIn - balance;
            buoyERC20.transfer(msg.sender, balance);
        } else {
            buoyContributed = tokenAmountIn;
            payable(msg.sender).transfer(address(this).balance);
        }
        uint tokensContributed = uniswapERC20.balanceOf(address(this)).bsub(initBalance);
        _mintxBuoyToken(tokensContributed, buoyContributed, lockLength, uniswapToken);
        return(tokensContributed);
    }

    function balancerLiquidityDeposit(uint tokenAmountIn, uint lockLength) public returns(uint) {
        address buoy = addressIndex.getBuoy();
        address balancerToken = addressIndex.getSmartPool();
        IERC20 balancerERC20 = IERC20(balancerToken);
        SPool spool = SPool(balancerToken);
        IERC20 buoyERC20 = IERC20(addressIndex.getBuoy());
        uint initBalance = balancerERC20.balanceOf(address(this));
        buoyERC20.transferFrom(msg.sender, address(this), tokenAmountIn);
        buoyERC20.approve(addressIndex.getSmartPool(), type(uint).max);
        spool.joinswapExternAmountIn(buoy, tokenAmountIn, 0);
        uint tokensContributed = balancerERC20.balanceOf(address(this)).bsub(initBalance);
        _mintxBuoyToken(tokensContributed, tokenAmountIn/2, lockLength, balancerToken);
        return(tokensContributed);
    }   
    
    function _mintxBuoyToken(uint _contributed, uint _allotment, uint _lockLength, address _platform) private {
        IBuoy buoyERC721 = IBuoy(addressIndex.getXBuoy());
        uint _rewards;
        uint _share;
        uint _payouts; 
        if(_lockLength == 1) {
            _share = stakingShares[0];
            _payouts = 30;
            _rewards = _calculateRewards(_allotment, stakingShares[0], _payouts);
            stakingAllocations[0] = 1;
            require(stakingAllocations[0] <= stakingMaxs[0], 'Not enough room three month allocations');
        } else if(_lockLength == 2) {
            _share = stakingShares[1];
            _payouts = 60;
            _rewards = _calculateRewards(_allotment, stakingShares[1], _payouts);
            stakingAllocations[1] = stakingAllocations[1].badd(_allotment);
            require(stakingAllocations[1] <= stakingMaxs[1], 'Not enough room in six month allocations');
        } else if(_lockLength == 3) {
            _share = stakingShares[2];
            _payouts = 120;
            _rewards = _calculateRewards(_allotment, stakingShares[2], _payouts);
            stakingAllocations[2] = stakingAllocations[2].badd(_allotment);
            require(stakingAllocations[2] <= stakingMaxs[2], 'Not enough room in twelve month allocations');
        } else {
            revert('Invalid lock length');
        }
        uint firstClaim = block.timestamp + stakingBlock;
        buoyERC721.craftNFT(msg.sender, _contributed, _allotment, _rewards, _payouts, firstClaim, _platform);
    }
    
    /* outdated, marked to remove
    function unmintXBuoyToken(uint _id) public {
        IBuoy buoyERC721 = IBuoy(addressIndex.getXBuoy());
        uint _allotment;
        address _platform;        
        (,,_allotment,,,,) = buoyERC721.viewNFT(_id);
        (,,,,,,_platform) = buoyERC721.viewNFT(_id);
        buoyERC721.approve(address(this), _id);
        buoyERC721.burn(_id);
        IERC20 platformContract = IERC20(_platform);
        platformContract.transfer(msg.sender, _allotment);
    }
    */
    
    function purge() public {
        IERC20 buoyERC20 = IERC20(addressIndex.getBuoy());
        uint amountA = address(this).balance;
        uint amountB = buoyERC20.balanceOf(address(this));
        buoyERC20.transfer(owner, amountB);
        owner.transfer(amountA);
    }

    function getRewards(uint _id) public returns(uint) {
        //takes NFT, checks ownership, mints tokens based on allotment
        IBuoy buoyERC721 = IBuoy(addressIndex.getXBuoy());
        BuoyMine buoyMine = BuoyMine(addressIndex.getBuoy());
        uint stakingRewards;
        bool _active;
        uint _contributed;
        uint _allotment;
        uint _rewards;
        uint _nextClaim;
        uint _payouts;
        address _platform;
        (_active,,,,,,) = buoyERC721.viewNFT(_id);
        (,_contributed,,,,,) = buoyERC721.viewNFT(_id);
        (,,_allotment,,,,) = buoyERC721.viewNFT(_id);
        (,,,_rewards,,,) = buoyERC721.viewNFT(_id);
        (,,,,_payouts,,) = buoyERC721.viewNFT(_id);
        (,,,,,_nextClaim,) = buoyERC721.viewNFT(_id);
        (,,,,,,_platform) = buoyERC721.viewNFT(_id);
        require(buoyERC721.ownerOf(_id) == msg.sender);
        require(_active == true, 'xBuoy token already claimed');
        while(block.timestamp >= _nextClaim && _payouts != 0) {
            _nextClaim = _nextClaim + stakingBlock;
            stakingRewards = stakingRewards + _rewards;
            _payouts--;
        } 
        buoyERC721.setNFT(_id, _nextClaim, _payouts);
        if(_payouts == 0) {
            IERC20 returnTokens = IERC20(_platform);
            returnTokens.transfer(msg.sender, _contributed);
            buoyERC721.killNFT(_id);
        }
        buoyMine.mineMint(stakingRewards, msg.sender);
        return(stakingRewards);
    }
    
    function _calculateRewards(uint staked, uint rewards, uint period) private pure returns(uint) {
        uint rewardsCalculation;
        rewardsCalculation = ((staked * rewards) / 100) / period;
        return(rewardsCalculation);
    }

}