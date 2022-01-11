/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract ICO is Ownable, Initializable {
    event Buy( address indexed buyer, uint buyAmount, uint amount);
    event Claim( address indexed claimer, uint amount);

    mapping(address => userStruct) public user;

    struct userStruct {
        uint balance;
        uint totalClaimed;
        uint lastClaim;
    }

    IERC20 public token;
    uint public price;
    uint public initialClaim = 50e18;
    uint public monthClaim = 10e18;
    uint public claimPeriod = 30 days;
    uint[2] public saleTime; // 0- start time, 1- end time
    uint[2] public total; //0- total raised, 1- total sold

    receive() external payable {
        revert("No receive calls");
    }

    function initialize( IERC20 tokenAdd, uint[2] memory saleTimestamp) external initializer {
        require(saleTimestamp[0] > block.timestamp, "ICO : sale start time > block.timestamp");
        require(saleTimestamp[1] > saleTimestamp[0], "ICO : start time > end time");
        token = tokenAdd;
        saleTime = saleTimestamp;
    }

    function setPrice( uint value) external onlyOwner {
        price = value;
    }

    function setClaimPeriod( uint period) external onlyOwner {
        claimPeriod = period;
    }

    function setInitialClaim( uint initClaim) external onlyOwner {
        initialClaim = initClaim;
    }

    function setMonthClaim( uint mnthClaim) external onlyOwner {
        monthClaim = mnthClaim;
    }

    function buy() external payable {
        require(price > 0, "ICO : price > 0");
        require(saleTime[0] < block.timestamp, "ICO : start time < block.timestamp");
        require(saleTime[1] > block.timestamp, "ICO : end time > block.timestamp");
        require(msg.value > 0, "ICO : msg.value > 0");

        uint value = cal(msg.value);
        require(token.balanceOf(address(this)) >= value, "ICO : insufficient balance");

        total[0] += msg.value;
        total[1] += value;
        user[msg.sender].balance += value;

        if(user[msg.sender].lastClaim == 0)
            user[msg.sender].lastClaim = block.timestamp;

        token.transfer(msg.sender, value);
        emit Buy( msg.sender, msg.value, value);
    }

    function claim() external {
        require(saleTime[1] < block.timestamp, "ICO : end time < block.timestamp");
        require((user[msg.sender].lastClaim + claimPeriod) < block.timestamp, "ICO : claim time < block.timestamp");
        require(user[msg.sender].totalClaimed < user[msg.sender].balance, "ICO : total claim < total balance");
        
        uint totDays = block.timestamp - user[msg.sender].lastClaim / claimPeriod;

        user[msg.sender].lastClaim = block.timestamp;

        uint claimAmount;

        if(user[msg.sender].lastClaim == 0)
            claimAmount = user[msg.sender].balance * (initialClaim + (monthClaim * totDays)) / 100e18;
        else 
            claimAmount = user[msg.sender].balance * (monthClaim + (monthClaim * totDays)) / 100e18;

        if((user[msg.sender].totalClaimed + claimAmount) > user[msg.sender].balance) 
            claimAmount = user[msg.sender].balance - user[msg.sender].totalClaimed; 

        user[msg.sender].totalClaimed += claimAmount;
        token.transfer(msg.sender, claimAmount);
        emit Claim( msg.sender, claimAmount);
    }

    function cal( uint amount) public view returns (uint) {
        return price*amount/10**18;
    }

    function failcase( address tokenAdd, uint amount) external onlyOwner{
        address self = address(this);
        if(tokenAdd == address(0)) {
            require(self.balance >= amount, "ICO : insufficient balance");
            require(payable(owner()).send(amount), "ICO : transfer failed");
        }
        else {
            require(IERC20(tokenAdd).balanceOf(self) >= amount, "ICO : insufficient balance");
            require(IERC20(tokenAdd).transfer(owner(),amount), "ICO : transfer failed");
        }
    }
}