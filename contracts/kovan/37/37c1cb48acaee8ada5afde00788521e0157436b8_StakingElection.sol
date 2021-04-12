/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/IStakingRewards.sol

pragma solidity >=0.6.0 <0.8.0;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerEth(address[] calldata tokenList, uint256[] calldata prices) external view returns (uint256);

    function earned(address account, address[] calldata tokenList) external view returns (uint256);

    function forEthPrice(address token) external view returns (uint256);

    function totalETHSupply(address[] calldata tokenList, uint256[] calldata prices) external view returns (uint256);

    function totalTokenSupply(address token) external view returns (uint256);

    function getTokenValueForEth(address token) external view returns (uint256);

    function balanceOfToken(address token, address account)
        external
        view
        returns (uint256);

    function getIssueCounter() external view returns (uint256);

    // Mutative

    function stake(address token, uint256 amount) external;

    function stakeWithEth(uint256 amount) payable external;

    function withdraw(
        address token,
        uint256 amount,
        address recipient
    ) external;

    function getReward() external;
}

// File: contracts/StakingElection.sol

pragma solidity >=0.6.0 <0.8.0;




interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract StakingElection is Ownable {
    struct Currency {
        address tokenAddr;
        uint256 total;
    }

    uint256 proposalCounter = 0;

    mapping(uint256 => address[]) public proposalResults;
    mapping(uint256 => uint256) public proposalTimes;

    address[] public candidateTokens;

    uint256 public stakingLimit;

    // stakingLimit * 7
    uint256 public candidateLimit;

    //stakingLimit * 5
    uint256 public proposalLimit;

    uint256 public bufferTime;

    //rinkeby
    //0xc778417E063141139Fce010982780140Aa0cD5Ab
    address public WETH;
    //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    address
        public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public stakingRewards;

    event CreateCandidate(address indexed tokenIn, address indexed tokenOut);
    event Proposal(address user, uint256 proposalCounter);
    event SetStakingLimit(address user, uint256 limit);

    //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,0xc778417E063141139Fce010982780140Aa0cD5Ab,10
    constructor(
        address _WETH,
        uint256 _stakingLimit,
        uint256 _bufferTime
    ) public {
        candidateLimit = _stakingLimit * 7;
        stakingLimit = _stakingLimit;
        proposalLimit = _stakingLimit * 5;
        WETH = _WETH;
        bufferTime = _bufferTime;
    }

    ///candidateTokens length inevitable >=  stakingTokens length
    function proposal() external returns (bool) {
        proposalCounter += 1;

        address[] memory proposalRes;
        address[] memory proposalList = getProposalList();
        //候选名单列表长度小于等于质押名单长度 新加入的立即生效
        if (proposalList.length <= stakingLimit) {
            proposalRes = new address[](proposalList.length);
            for (uint256 i = 0; i < proposalList.length; i++) {
                proposalRes[i] = candidateTokens[i];
            }
            proposalTimes[proposalCounter] = 0;
            //候选列表长多大于质押质押列表长度，进行排名取前{stakingLimit}名
        } else {
            proposalRes = new address[](stakingLimit);
            Currency[] memory all = new Currency[](proposalList.length);
            for (uint256 i = 0; i < proposalList.length; i++) {
                uint256 value = IStakingRewards(stakingRewards)
                    .getTokenValueForEth(proposalList[i]);
                all[i] = Currency(proposalList[i], value);
            }
            _getMaxValues(all, stakingLimit);

            for (uint256 i = 0; i < stakingLimit; i++) {
                proposalRes[i] = all[i].tokenAddr;
            }
            if (proposalCounter == 1) {
                proposalTimes[proposalCounter] = 0;
            } else {
                proposalTimes[proposalCounter] = block.timestamp;
            }
        }

        proposalResults[proposalCounter] = proposalRes;
        emit Proposal(msg.sender, proposalCounter);
        return true;
    }

    function applyCandidate(address _token) external returns (bool) {
        // check pair is created
        address pair = _getPair(_token);
        require(pair != address(0), "pair not created");
        if (candidateTokens.length < candidateLimit) {
            for (uint256 i = 0; i < candidateTokens.length; i++) {
                if (_token == candidateTokens[i]) {
                    return false;
                }
            }
            candidateTokens.push(_token);
            emit CreateCandidate(_token, address(0));
            //Replace the one with the smallest market value
        } else {
            uint256 minKey = candidateTokens.length;
            uint256 minBalance = IERC20(WETH).balanceOf(pair);
            uint256 balance;
            for (uint256 i = 0; i < candidateTokens.length; i++) {
                if (_token == candidateTokens[i]) {
                    return false;
                }
                balance = _getPairWETH(candidateTokens[i]);
                if (balance < minBalance) {
                    minBalance = balance;
                    minKey = i;
                }
            }
            if (minKey < candidateTokens.length) {
                emit CreateCandidate(_token, candidateTokens[minKey]);
                candidateTokens[minKey] = _token;
            }
        }
        return true;
    }

    function getProposalList() internal view returns(address[] memory proposalList){
        if (candidateTokens.length <= proposalLimit) {
            proposalList = new address[](candidateTokens.length);
            for (uint256 i = 0; i < candidateTokens.length; i++) {
                proposalList[i] = candidateTokens[i];
            }
        } else {
            proposalList = new address[](proposalLimit);
            Currency[] memory all = new Currency[](candidateTokens.length);
            for (uint256 i = 0; i < candidateTokens.length; i++) {
                address pair = _getPair(candidateTokens[i]);
                uint256 value = IERC20(WETH).balanceOf(pair);
                all[i] = Currency(candidateTokens[i], value);
            }
            _getMaxValues(all, proposalLimit);
            for (uint256 i = 0; i < proposalLimit; i++) {
                proposalList[i] = all[i].tokenAddr;
            }
        }
    }

    //提案成功后 原质押列表有{bufferTime}的缓冲时间
    function stakingTokensList() external view returns (address[] memory) {
        address[] memory tokenList;
        uint256 key;
        if (proposalCounter > 0) {
            for (uint256 i = proposalCounter; i > 0; i--) {
                uint256 proposalTime = proposalTimes[i];
                if (proposalTime + bufferTime <= block.timestamp) {
                    key = i;
                    break;
                }
            }
            tokenList = new address[](proposalResults[key].length + 1);
            for (uint256 i = 0; i < proposalResults[key].length; i++) {
                tokenList[i] = proposalResults[key][i];
            }
            tokenList[proposalResults[key].length] = WETH;
        }
        return tokenList;
    }

    function candidateTokensList() external view returns (address[] memory) {
        address[] memory tokenlist = new address[](candidateTokens.length);
        for (uint256 i = 0; i < candidateTokens.length; i++) {
            tokenlist[i] = candidateTokens[i];
        }
        return tokenlist;
    }

    function proposalResult(uint256 _proposalCounter)
        external
        view
        returns (address[] memory)
    {
        address[] memory tokenList;
        if (_proposalCounter <= proposalCounter && _proposalCounter >= 1) {
            tokenList = new address[](proposalResults[_proposalCounter].length);
            for (
                uint256 i = 0;
                i < proposalResults[_proposalCounter].length;
                i++
            ) {
                tokenList[i] = proposalResults[_proposalCounter][i];
            }
        }
        return tokenList;
    }

    function _getPair(address _token) internal view returns (address) {
        address pair = IUniswapV2Factory(FACTORY).getPair(_token, WETH);
        return pair;
    }

    function _getPairWETH(address _token) internal view returns (uint256) {
        uint256 balance = IERC20(WETH).balanceOf(
            IUniswapV2Factory(FACTORY).getPair(_token, WETH)
        );
        return balance;
    }

    function _getMaxValues(Currency[] memory arr, uint256 k) internal pure {
        uint256 hi = 0;
        uint256 lo = arr.length - 1;
        while (hi <= lo) {
            uint256 index = _partition(arr, hi, lo);
            if (index == k - 1) {
                // find the kth maximal element.
                break;
            } else if (index < k - 1) {
                hi = index + 1;
            } else {
                lo = index - 1;
            }
        }
    }

    function _partition(
        Currency[] memory arr,
        uint256 start,
        uint256 end
    ) internal pure returns (uint256) {
        uint256 pivot = arr[end].total;
        uint256 larger = start - 1;
        while (start < end) {
            if (arr[start].total > pivot) {
                _swap(arr, start++, ++larger);
            } else {
                start++;
            }
        }
        _swap(arr, end, ++larger);
        return larger;
    }

    function _swap(
        Currency[] memory arr,
        uint256 a,
        uint256 b
    ) internal pure returns (bool) {
        Currency memory temp = arr[b];
        arr[b] = arr[a];
        arr[a] = temp;
        return true;
    }

    function setStakingRewards(address _stakingRewards) external onlyOwner {
        // require(stakingRewards == address(0), "stakingRewards address already set");
        stakingRewards = _stakingRewards;
    }

    function setStakingLimit(uint256 limit) external onlyOwner {
        candidateLimit = limit * 7;
        stakingLimit = limit;
        proposalLimit = limit * 5;
        emit SetStakingLimit(msg.sender, limit);
    }
}