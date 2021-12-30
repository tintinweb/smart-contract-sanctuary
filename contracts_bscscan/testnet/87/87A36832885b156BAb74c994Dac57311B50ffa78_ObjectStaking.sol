pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;


interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface INodeRunnersNFT {
    function getFighter(uint256 tokenId) external view returns (uint256);
}

contract ObjectStaking is ReentrancyGuard, Pausable, Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct NftToken {
        bool hasValue;
        mapping(address => uint256) balances;
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public TOKEN_;
    IERC1155 public NFT;

    uint256 public DURATION = 0;
    uint256 public starttime = 0;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 125 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    //总算力
    uint256 public _totalStrength;
    //总质押数
    uint256 public _totalSupply;
    //已领取奖励
    uint256 public rewardReceived;
    uint256 public fee = 0;

    //算力配置
    mapping(uint256 => uint256) public weightConfig;
    mapping(address => uint256) public userRewardPerTokenPaid;
    //当前用户算力，上次的
    mapping(address => uint256) public pureStrengthWeight;
    //当前用户算力
    mapping(address => uint256) public strengthWeight;
    //用户奖励
    mapping(address => uint256) public rewards;
    //卡槽使用数量
    mapping(address => uint256) public _balances;

    //质押nft总数
    uint256 public tokenMaxAmount;
    uint256[] public nftTokens;
    mapping(address => uint256[]) public nftTokenMap;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _NFT, address _TOKEN_, uint256 _starttime, uint256 daye) public {
        NFT = IERC1155(_NFT);
        TOKEN_ = IERC20(_TOKEN_);
        // ##########################
        DURATION = daye.mul(86400);
        starttime = _starttime;
        //设置插槽，使用8个
        setTokenMaxAmount(8);

        //测试参数
        setWeightConfig(1, 1);
        setWeightConfig(2, 2);
        setWeightConfig(3, 1);
        starttime = block.timestamp + 10;
        notifyRewardAmount(15000000000000000000);
    }

    /* ========== VIEWS ========== */

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getNftTokens() external view returns (uint256[] memory) {
        return nftTokens;
    }

    function timeMining() public virtual returns (uint256) {
        return block.timestamp.sub(starttime).mul(rewardRate);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalStrength == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(_totalStrength)
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        strengthWeight[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    function earned_2(address account) public view returns (uint256, uint256) {
        return (earned(account), block.timestamp);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setWeightConfig(uint256 _type, uint256 _weight) public onlyOwner {
        weightConfig[_type] = _weight;
    }

    function setTokenMaxAmount(uint256 _tokenMaxAmount) public onlyOwner {
        tokenMaxAmount = _tokenMaxAmount;
    }

    function setWithdrawRewardFee(uint256 _withdrawRewardFee) external onlyOwner {
        fee = _withdrawRewardFee;
    }

    function changeAddresses(address _TOKEN_, address _NFT) public onlyOwner {
        TOKEN_ = IERC20(_TOKEN_);
        NFT = IERC1155(_NFT);
    }

    function stake(uint256[] calldata tokenIds) external nonReentrant whenNotPaused updateReward(msg.sender) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeInternal(tokenIds[i]);
        }
    }

    function stakeInternal(uint256 tokenId) internal {
        //获得该地块产出算力
        (uint256 strength) = weightConfig[INodeRunnersNFT(address(NFT)).getFighter(tokenId)];
        nftTokens.push(tokenId);

        //总算力清除老旧的，准备赋予新算例力
        _totalStrength = _totalStrength.sub(strengthWeight[msg.sender]);
        //计算最新算力：当前总算力+新算力
        pureStrengthWeight[msg.sender] = pureStrengthWeight[msg.sender].add(strength);
        //更新当前算力
        strengthWeight[msg.sender] = pureStrengthWeight[msg.sender];

        //总算力增加。随着用户算力上升，插入卡槽，总算力随之上升了
        _totalStrength = _totalStrength.add(strengthWeight[msg.sender]);
        //总质押增加
        _totalSupply = _totalSupply.add(1);
        //使用卡槽数增加
        _balances[msg.sender] = _balances[msg.sender].add(1);
        //卡槽使用不超过X个
        require(_balances[msg.sender] <= tokenMaxAmount, "NFT max reached");
        //使用卡槽数记载
        nftTokenMap[msg.sender].push(tokenId);

        NFT.safeTransferFrom(msg.sender, address(this), tokenId, "0x0");
        emit Staked(msg.sender, tokenId, block.timestamp);
    }

    function withdrawNFT(uint256[] memory tokenIds) public updateReward(msg.sender) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            withdrawNFTInternal(tokenIds[i]);
        }
    }

    function withdrawNFTInternal(uint256 tokenId) internal {
        (uint256 strength) = weightConfig[INodeRunnersNFT(address(NFT)).getFighter(tokenId)];

        //总算力清除老旧的，准备赋予新算例力
        _totalStrength = _totalStrength.sub(strengthWeight[msg.sender]);
        //取出卡槽，减少算力
        pureStrengthWeight[msg.sender] = pureStrengthWeight[msg.sender].sub(strength);
        //更新当前算力
        strengthWeight[msg.sender] = pureStrengthWeight[msg.sender];

        //赋予新算力。随着用户算力下降，拔出卡槽，总算力随之下降了
        _totalStrength = _totalStrength.add(strengthWeight[msg.sender]);
        //总流通增加
        _totalSupply = _totalSupply.sub(1);
        //卡槽使用数减少
        _balances[msg.sender] = _balances[msg.sender].sub(1);
        //删除元素，按照位置
        removeUserToken(tokenId);

        NFT.safeTransferFrom(address(this), msg.sender, tokenId, "0x0");
        emit Withdrawn(msg.sender, tokenId, 1);
    }

    function removeUserToken(uint tokenId) internal returns (uint256[] memory) {
        uint256[] storage array = nftTokenMap[msg.sender];
        uint256 index = 0;
        for (uint256 i = 0; i < array.length; i++) if (array[i] == tokenId) index = i;

        if (index >= array.length) require(false, "error param");
        for (uint i = index; i < array.length - 1; i++) array[i] = array[i + 1];

        delete array[array.length - 1];
        array.pop();
        return array;
    }

    function withdraw() public updateReward(msg.sender) {
        uint256[] memory myStake = nftTokenMap[msg.sender];
        //遍历nft数组，逐一查看该nft使用情况，如果锁仓过金额是1是当前用户的，如果是0是其他用户的
        for (uint8 i = 0; i < myStake.length; i++) {
            withdrawNFTInternal(myStake[i]);
        }
    }

    function getRewardInternal() internal nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            TOKEN_.safeTransfer(msg.sender, reward);
            rewardReceived = rewardReceived.add(reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function getReward() public payable {
        require(msg.value == fee, "Get reward fee required");
        getRewardInternal();
    }

    function exit() external payable {
        require(msg.value == fee, "Get reward fee required");
        withdraw();
        getRewardInternal();
    }

    function withdrawRewardFee() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed");
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function notifyRewardAmount(uint256 reward)
    public
    onlyOwner
    updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
    external
    onlyOwner
    {
        require(
            tokenAddress != address(NFT) &&
            tokenAddress != address(TOKEN_),
            "Cannot withdraw the staking or rewards tokens"
        );
        IERC20(tokenAddress).safeTransfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId, uint256 number);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 number);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    receive() external payable {
    }
}

// ####################### 实现思路
/*
先设置每秒产矿量，例如每秒产出1个
接着每个地块，都有个默认算力，例如：灰色地块算力1，黄色地块算力2，黑色地块算力3
用户丢入1个灰色地块，那1S就产出1个
用户丢入1个灰色地块，+ 1个黄色地块，求和算力是3，那1S就产出3个，以此类推
以后升级算力的时候，只需要累计产出系数，上面这个值即可
就兼容了每个地块等级产出不一样，也可以做到普通地块升级算力，提高产出量的作用
基础的每秒产出 * 产出系数 = 应获得奖励
*/