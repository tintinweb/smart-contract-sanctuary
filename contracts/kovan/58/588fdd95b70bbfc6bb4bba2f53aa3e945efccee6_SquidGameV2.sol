// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

interface ISquidGameNft {
    function mint(address account) external returns (uint256 tokenId_);
}
interface ISquidGame {

}


contract SquidGameV2 is Initializable  {
    //购买NFT事件
    event MintEvent(address indexed account, uint256 tokenId);
    //购买道具时间，后台监听此事件给玩家新增数据
    event BuyEvent( address indexed account, uint256 id, uint256 amounts, bytes32 orderId );
    //燃烧Squid事件
    event BurnEvent(address indexed account, uint256 burn);
    //项目方提取费用事件
    event GetFee(address indexed account, uint256 fee);
    //获取幸运大奖事件
    event GetReward(address indexed account, uint256 reward);
    //获取打金收益事件
    event WithdrawEvent(address indexed account,bytes32 indexed hash,uint fee,uint amount);

    // constructor() initializer  {}

    function initialize(address squidnft_,address recipient_,address referees_) public initializer { 
        _squidNft = ISquidGameNft(squidnft_);
        _recipient = recipient_;
        _referees= referees_;
        _owner = msg.sender;
    }

    address public _owner ;

    //鱿鱼token
    IERC20 public constant SQUID = IERC20(0xa2cEEd97494F5F7b9aaA0034f5fB08eDDa6B4004);
    //销毁地址
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    //nft单价
    uint256 public constant squidNftPrice = 1 * 10 ** 18;
    //nft地址
    ISquidGameNft public _squidNft;
    //项目方费用
    uint256 public _fee;
    //燃烧费用
    uint256 public _burn;
    //幸运奖励费用
    uint256 public _reward;
    //打金奖池费用
    uint256 public _stake;
    //幸运大奖到期时间
    uint256 public endtime;

    //项目放接受地址
    address private _recipient;
    //最后一个购买者
    address public _purchaser;
    //重入锁
    bool private _lock;
    
    //服务器钱包
    address private _referees;  

    //交易hash丢弃池
    mapping(bytes32 => bool) orders;
    //市场价格
    mapping(uint256 => uint256) public prices;

    modifier Reentrant() {
        require(!_lock);
        _lock = true;
        _;
        _lock = false;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    //倔出一个nft
    function mint() public Reentrant {
        SQUID.transferFrom(msg.sender, address(this), squidNftPrice);
        _calculateMintFee(squidNftPrice);
        uint256 tokenId_ = _squidNft.mint(msg.sender);
        emit MintEvent(msg.sender, tokenId_);
    }
    //购买某个服务
    function buy( uint256 id, uint256 amounts, bytes32 orderId ) public Reentrant {
        uint256 price_ = prices[id] * amounts;
        SQUID.transferFrom(msg.sender, address(this), price_);
        _calculateFee(price_);
        emit BuyEvent(msg.sender, id, amounts, orderId);
    }

    //计算购买服务费用
    function _calculateFee(uint256 price_)
        internal
        pure
        returns (uint256 burn_, uint256 stake_)
    {
        burn_ = (price_ * 100) / 1000;
        stake_ = price_ - burn_;
    }
    //计算购买nft费用
    function _calculateMintFee(uint256 price_) internal {
        (
            uint256 fee_,
            uint256 reward_,
            uint256 burn_,
            uint256 stake_
        ) = _getFee(price_);
        _purchaser = msg.sender;
        endtime == 0 ? block.timestamp + 600 : endtime + 600;
        _fee += fee_;
        _reward += reward_;
        _burn += burn_;
        _stake += stake_;
    }
    
    function _getFee(uint256 amount)
        internal
        pure
        returns (
            uint256 fee_,
            uint256 reward_,
            uint256 burn_,
            uint256 stake_
        )
    {
        fee_ = (amount * 200) / 1000;
        reward_ = (amount * 100) / 1000;
        burn_ = (amount * 100) / 1000;
        stake_ = amount - fee_ - reward_ - burn_;
    }
    //燃烧squid
    function burnFee() public Reentrant {
        SQUID.transfer(deadAddress, _burn);
        emit BurnEvent(msg.sender, _burn);
        _burn = 0;
    }
    //获取项目方手续费
    function getFee() public Reentrant {
        require(msg.sender == _recipient);
        SQUID.transfer(_recipient, _fee);
        emit GetFee(msg.sender, _fee);
        _fee = 0;
    }
    //获取幸运大奖
    function getReward() public Reentrant {
        require(block.timestamp > endtime);
        require(msg.sender == _purchaser);
        SQUID.transfer(_purchaser, _reward);
        emit GetReward(msg.sender, _reward);
        _reward = 0;
        endtime = 0;
    }

    //提取打金收益
    function withdraw( address account, uint256 amount, uint256 timestamp, bytes32 hash, bytes memory signature ) public Reentrant returns (uint256 fee_, uint256 amount_) {
        require(!orders[hash]);
        require(hashToVerify(account, amount, timestamp) == hash);
        require(verify(_referees, hash, signature));
        fee_ = ((block.timestamp - timestamp) * 10000) / 86400;
        fee_ = fee_ > 86400 * 10 * 10000 ? 100000 : fee_;
        amount_ = (amount * 20 * fee_) / 1000000;
        require(_stake >= amount_);
        _stake-=amount_;
        orders[hash] = true;
        SQUID.transfer(account, amount_);
        emit WithdrawEvent(account, hash,fee_,amount_);
    }

    function orderHash( address account, uint256 amount, uint256 timestamp ) public pure returns (bytes32 hash) {
        return keccak256(abi.encode(account, amount, timestamp));
    }

    function hashToVerify(
        address account,
        uint256 amount,
        uint256 timestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    orderHash(account, amount, timestamp)
                )
            );
    }

    function verify( address signer, bytes32 hash, bytes memory signature ) public pure returns (bool) {
        require(signer != address(0));
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);
        return signer == ecrecover(hash, v, r, s);
    }

    function updatePrices(uint id,uint price_) public onlyOwner{
        prices[id] = price_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.9.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}