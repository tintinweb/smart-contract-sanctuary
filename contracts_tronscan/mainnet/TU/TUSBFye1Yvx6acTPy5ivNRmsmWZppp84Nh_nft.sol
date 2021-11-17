//SourceUnit: Context.sol

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


//SourceUnit: IERC20.sol

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


//SourceUnit: IJustswapExchange.sol

pragma solidity ^0.8.0;


interface IJustswapExchange {
  event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
  event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
  event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);


  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

  function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);


  function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);

  function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);

  function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

  function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

  function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

  function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

  function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);


  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);

  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_trx_bought, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_trx_sold, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);


  function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

  function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

  function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

  function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

  function tokenAddress() external view returns (address);

  function factoryAddress() external view returns (address);

  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

  function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}


//SourceUnit: Ownable.sol

pragma solidity ^0.8.0;

import "../Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


//SourceUnit: nft.sol

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../Ownable.sol";
import "../IJustswapExchange.sol";


contract nft is Ownable {
    
    IERC20 public nftToken;
    IERC20 public nftcToken;
    IERC20 public lpToken;
    IJustswapExchange public usdtSwapContract;     //  USDT 交易合约
    IJustswapExchange public nftcSwapContract;      // NFTC 交易合约
    address public destroyAddress;
    uint256 outNFTCAmount;   // 产出总数量
    uint256 calculatedForceValueAll; // 总算力值
    uint256 lpAmountAll;    //  LP 总数量
    uint256 foundationNFTCAmount;   // 基金会总数量
    uint256 technicalTeamNFTCAmount;    // 技术团队总数量
    
    uint256 foundationOutputScale = 8;      //  基金会产出比例
    uint256 technicalTeamOutputScale = 5;   //  技术团产出比例

    struct UserInfo {
        uint256 calculatedForceValue; // 算力值
        uint256 lpAmount;       // LP 数量
        uint256 nftDestroyAmount;      // NFT销毁数量
        uint256 nftcDestroyAmount;      // NFTC销毁数量
        uint256 nftcAmount;      // NFTC数量
        uint256 rewardDebt;     // NFTC提取数量
        uint256 rewardRemain;   // NFTC持有
        uint256 lpRewardRemain; //  LP 收益
    }
    
    mapping (address => UserInfo) userInfos;
    
    event Swap(address indexed user, uint256 amount);
    event Swap1(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event SetRewardRemain(address indexed user, uint256 _amount);
    event SetBatchRewardRemain(address indexed user, address[] _account, uint256[] _amount);
    
    function setNftToken(IERC20 _nftToken) public {
        nftToken = _nftToken;
    }
    
    function setNftcToken(IERC20 _nftcToken) public {
        nftcToken = _nftcToken;
    }
    
    function setDestroyAddress(address _destroyAddress) public {
        destroyAddress = _destroyAddress;
    }
    
    function setUsdtSwapContract(IJustswapExchange _usdtSwapContract) public {
        usdtSwapContract = _usdtSwapContract;
    }
    
    function setNftcSwapContract(IJustswapExchange _nftcSwapContract) public {
        nftcSwapContract = _nftcSwapContract;
    }

    /**
     * NFT兑换算力值（NFT直接销毁）
     **/
    function swap(uint256 _amount) external {
        nftToken.transferFrom(address(msg.sender), destroyAddress, _amount);
        
        UserInfo memory user = userInfos[address(msg.sender)];
        if (user.calculatedForceValue == 0) {
            user.calculatedForceValue = (_amount * 15)/1500;
            user.nftDestroyAmount = _amount;
        } else {
            user = userInfos[address(msg.sender)];
            user.calculatedForceValue += ((_amount * 15)/1500);
            user.nftDestroyAmount += _amount;
        }
        
        userInfos[address(msg.sender)] = user;
        
        emit Swap(msg.sender, _amount);
    }
    
    function getNFTCPrice(uint256 _amount) public view returns (uint256 _nftcPrice) {
        uint256 trxAmount = nftcSwapContract.getTokenToTrxOutputPrice(_amount);
        _nftcPrice = usdtSwapContract.getTokenToTrxInputPrice(trxAmount);
    }
    
    /**
     * NFTC兑换算力值（NFTC直接销毁）
     **/
    function swap1(uint256 _amount) external {
        nftcToken.transferFrom(address(msg.sender), destroyAddress, _amount);
        
        UserInfo memory user = userInfos[address(msg.sender)];
        if (user.calculatedForceValue == 0) {
            user.calculatedForceValue = (_amount * getNFTCPrice(_amount))/1500;
            user.nftcDestroyAmount = _amount;
        } else {
            user = userInfos[address(msg.sender)];
            user.calculatedForceValue += ((_amount * getNFTCPrice(_amount))/1500);
            user.nftcDestroyAmount += _amount;
        }
        
        userInfos[address(msg.sender)] = user;
        
        emit Swap1(msg.sender, _amount);
    }
    
    
    /**
     * 提取收益（NFTC）
     **/
    function withdraw(uint256 _rewardRemain) public {
        
        UserInfo memory user = userInfos[address(msg.sender)];
        require(user.rewardRemain >= _rewardRemain, "withdraw: not good");
        
        user.rewardRemain -= _rewardRemain;
        user.rewardDebt += _rewardRemain;
        nftcToken.transfer(address(msg.sender), _rewardRemain);
        userInfos[address(msg.sender)] = user;
        emit Withdraw(msg.sender, _rewardRemain);
    }
    
    /**
     * JEY授权额度
     **/
    function nftTokenAllowance(address _from) public view returns (uint256 _currentAllowance) {
        _currentAllowance = nftToken.allowance(_from, address(this));
    }
    
    function nftcTokenAllowance(address _from) public view returns (uint256 _currentAllowance) {
        _currentAllowance = nftcToken.allowance(_from, address(this));
    }
    
    /**
     * 查询可提取NFTC
     **/
    function getJEWAmount() public view returns (uint256 _nftcAmount) {
        UserInfo memory user = userInfos[address(msg.sender)];
        _nftcAmount = user.rewardRemain;
    }
    
    /**
     * 获取算力值、销毁数量
     **/
    function getCalculatedForceValue() public view returns (uint256 _calculatedForceValue,uint256 _lpAmount,uint256 _nftDestroyAmount,
    uint256 _nftcDestroyAmount,uint256 _nftcAmount,uint256 _rewardDebt,uint256 _rewardRemain,uint256 _lpRewardRemain) {
        
        UserInfo memory user = userInfos[address(msg.sender)];
        _calculatedForceValue = user.calculatedForceValue;
        _lpAmount = lpToken.balanceOf(address(msg.sender));       // LP 数量
        _nftDestroyAmount = user.nftDestroyAmount;      // NFT销毁数量
        _nftcDestroyAmount = user.nftcDestroyAmount;      // NFTC销毁数量
        _nftcAmount = user.nftcAmount;      // NFTC数量
        _rewardDebt = user.rewardDebt;     // NFTC提取数量
        _rewardRemain = user.rewardRemain;   // NFTC持有
        _lpRewardRemain = user.lpRewardRemain; //  LP 收益
    }
    
    
    /**
     * 计算收益
     **/
    function setBatchRewardRemain(address[] memory _account, uint256[] memory _amount) public {
        
        emit SetBatchRewardRemain(msg.sender, _account, _amount);
    }
}