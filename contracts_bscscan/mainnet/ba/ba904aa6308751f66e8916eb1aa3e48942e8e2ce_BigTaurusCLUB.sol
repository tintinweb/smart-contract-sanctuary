/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity 0.8.6;




interface IBEP2E {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function _totalSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function send(address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

interface IEternalStorage {
  function setBool(bytes32 h, bool v)  external;
  function setInt(bytes32 h, int v) external;
  function setUint(bytes32 h, uint256 v) external;
  function setAddress(bytes32 h, address v) external;
  function setString(bytes32 h, string calldata v) external;
  function setBytes32(bytes32 h, bytes32 v) external;
  function setBytes(bytes32 h, bytes calldata v) external;
  function getBool(bytes32 h) external view returns (bool);
  function getInt(bytes32 h) external view returns (int);
  function getUint(bytes32 h) external view returns (uint256);
  function getAddress(bytes32 h) external view returns (address);
  function getString(bytes32 h) external view returns (string memory);
  function getBytes32(bytes32 h) external view returns (bytes32);
  function getBytes(bytes32 h) external view returns (bytes memory);
}

contract BigTaurusCLUB is  IBEP2E {
 using SafeMath for uint256;
  string constant private FN_Balance    = "Balance";
  bytes32 constant private H_Balance = keccak256(abi.encodePacked(FN_Balance));
  string constant private FN_Allowance   = "Allowances";
  bytes32 constant private H_Allowance  = keccak256(abi.encodePacked(FN_Allowance));
  string constant private FN_TotalSupply    = "TotalSupply";
  bytes32 constant private H_TotalSupply   = keccak256(abi.encodePacked(FN_TotalSupply));

  // uint256 private _totalSupply;
  uint256 public _decimals;
  string  public _name;
  string  public _symbol;

  uint256 constant private percentProjects = 5;
  uint256 constant private percentLiquidity = 3;
  uint256 constant private percentHolders = 3;
  uint256 constant private percentCharity = 1;

  address  private addressProjects; 
  address  private addressLiquidity;
  address  private addressHolders; 
  address  private addressCharity;

  IEternalStorage private storageContract;



// @notice Developer address
    address  private owner;
    // @dev Emitted when the Owner changes
    event OwnerTransferredEvent(address indexed previousOwner, address indexed newOwner);


    // @dev Throws if called by any account that's not Owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Developer required");
        _;
    }

    // @dev Tris function for transfering owne functions to new Owner
    // @param newOwner An address of new Owner
    function transferOwner(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "This address is 0!");
        emit OwnerTransferredEvent( owner, newOwner);
        owner = newOwner;
    }

   


  constructor(
    address storageAddr,
    address   projectsWallet,
    address   liquidityWallet,
    address   holdersWallet, 
    address   charityWallet)  
    {
    storageContract = IEternalStorage(storageAddr);
    _name = "BigTaurus";
    _symbol = "CLUB";
    _decimals = 10;
  
    addressProjects=projectsWallet; 
    addressLiquidity=liquidityWallet;
    addressHolders=holdersWallet; 
    addressCharity=charityWallet;

    owner = msg.sender;
  }


    function getHash(bytes32 _hash, uint256 _id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash, _id));
    }

    function getHash(bytes32 _hash, string memory _str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash, _str));
    }

    function getHash(bytes32 _hash, address _addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash, _addr));
    }


     function _totalSupply() external view override returns (uint256) {
      
      return storageContract.getUint(H_TotalSupply);
    }


  // function mint(address receiver, uint amount) public {
  //   require(msg.sender == owner(),  "Permission denied.");
  //   require(amount > 0,  "Amount must be greater than 0.");
  //   balances[receiver] += amount;
  // }

  function mint(address account, uint256 amount) onlyOwner public {
    require(account != address(0), "BEP20: mint to the zero address");
    require(amount > 0,  "Amount must be greater than 0.");
    uint256 balance = storageContract.getUint(getHash(H_Balance,account));
     storageContract.setUint(getHash(H_Balance,account),balance.add(amount));
     uint256 totalSupply= storageContract.getUint(H_TotalSupply);
     totalSupply=totalSupply.add(amount);
     storageContract.setUint(H_TotalSupply,totalSupply);
    // balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
 

 /**
     * @dev Returns the amount of tokens in existence.
     */


      function totalSupply() external view override returns (uint256) {
      return storageContract.getUint(H_TotalSupply);
    }
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view override returns (uint256) {
      return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view override returns (string memory){
      return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view override returns (string memory) {
      return _name;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view  override returns (address){
      return owner;
    }
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view  override returns(uint balance){
      return storageContract.getUint(getHash(H_Balance,account));
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

/**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function send(address recipient, uint256 amount) external override returns (bool){
      uint256 senderBalance=storageContract.getUint(getHash(H_Balance,msg.sender));
      uint256 recipientBalance=storageContract.getUint(getHash(H_Balance,recipient));
      require(amount <= senderBalance, "Insufficient balance.");
      require(msg.sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero address");
      
      senderBalance  = senderBalance.sub(amount);

      recipientBalance = recipientBalance.add(amount);
      
      storageContract.setUint(getHash(H_Balance,msg.sender),senderBalance);

      storageContract.setUint(getHash(H_Balance,recipient),recipientBalance);

     emit Transfer(msg.sender, recipient, amount);
      return true;
    }
 /**
     * @dev Moves `amount` tokens  with commision from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool){
      uint256 senderBalance=storageContract.getUint(getHash(H_Balance,msg.sender));
      uint256 recipientBalance=storageContract.getUint(getHash(H_Balance,recipient));
      require(amount <= senderBalance, "Insufficient balance.");
      require(msg.sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero address");
      
      senderBalance  = senderBalance.sub(amount);

      uint256 projectsBalance=storageContract.getUint(getHash(H_Balance,addressProjects));
      uint256 liquidityBalance=storageContract.getUint(getHash(H_Balance,addressLiquidity));
      uint256 holdersBalance=storageContract.getUint(getHash(H_Balance,addressHolders));
      uint256 charityBalance=storageContract.getUint(getHash(H_Balance,addressCharity));


      uint256  amountWithouComission=amount.sub(amount.mul(percentProjects).div(100));
      amountWithouComission=amountWithouComission.sub(amount.mul(percentLiquidity).div(100));
      amountWithouComission=amountWithouComission.sub(amount.mul(percentHolders).div(100));
      amountWithouComission=amountWithouComission.sub(amount.mul(percentCharity).div(100));


      recipientBalance = recipientBalance.add(amount);
       recipientBalance = recipientBalance.sub(amount.mul(percentProjects).div(100));
       recipientBalance = recipientBalance.sub(amount.mul(percentLiquidity).div(100));
       recipientBalance = recipientBalance.sub(amount.mul(percentHolders).div(100));
       recipientBalance = recipientBalance.sub(amount.mul(percentCharity).div(100));


        projectsBalance= projectsBalance.add(amount.mul(percentProjects).div(100));
        liquidityBalance= liquidityBalance.add(amount.mul(percentLiquidity).div(100));
        holdersBalance= holdersBalance.add(amount.mul(percentHolders).div(100));
        charityBalance= charityBalance.add(amount.mul(percentCharity).div(100));

      

      storageContract.setUint(getHash(H_Balance,msg.sender),senderBalance);

      storageContract.setUint(getHash(H_Balance,addressProjects),projectsBalance);
      storageContract.setUint(getHash(H_Balance,addressLiquidity),liquidityBalance);
      storageContract.setUint(getHash(H_Balance,addressHolders),holdersBalance);
      storageContract.setUint(getHash(H_Balance,addressCharity),charityBalance);
  
      storageContract.setUint(getHash(H_Balance,recipient),recipientBalance);

     emit Transfer(msg.sender, recipient, amountWithouComission);
      return true;
    }



    function allowance(address owner, address spender) public view  override returns (uint256) {
      return  storageContract.getUint(getHash(getHash(H_Allowance,owner),spender));  
    }

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


  function approve(address spender, uint256 amount) external override returns (bool) {
    uint256 allowance=storageContract.getUint(getHash(getHash(H_Allowance,msg.sender),spender));
    require(msg.sender != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    allowance=allowance.add(amount);
    storageContract.setUint(getHash(getHash(H_Allowance,msg.sender),spender),allowance); 
    // allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }


    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) onlyOwner external override returns (bool){
      
      uint256 senderBalance=storageContract.getUint(getHash(H_Balance,msg.sender));
      uint256 recipientBalance=storageContract.getUint(getHash(H_Balance,recipient));
      require(amount <= senderBalance, "Insufficient balance.");
      senderBalance  = senderBalance.sub(amount);
      recipientBalance = recipientBalance.add(amount);

      
      
      storageContract.setAddress(getHash(H_Balance,recipient),recipient);
      storageContract.setAddress(getHash(H_Balance,msg.sender),msg.sender);

 
      storageContract.setUint(getHash(H_Balance,recipient),recipientBalance);
      storageContract.setUint(getHash(H_Balance,msg.sender),senderBalance);
        emit Transfer(sender, recipient, amount);
        return true;
 
    }



 /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    uint256 allowance=storageContract.getUint(getHash(H_Balance,account));
    require(account != address(0), "BEP20: burn from the zero address");
    require(amount <= allowance, "Insufficient balance.");
    allowance = allowance.sub(amount, "BEP20: burn amount exceeds balance");
    storageContract.setUint(getHash(H_Balance,account),allowance);
    // _totalSupply = _totalSupply.sub(amount);
     uint256 totalSupply= storageContract.getUint(H_TotalSupply);
     totalSupply=totalSupply.sub(amount);
     storageContract.setUint(H_TotalSupply,totalSupply);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function burnFrom(address account, uint256 amount)  public returns (bool){
    uint256 allowanceBalance=storageContract.getUint(getHash(getHash(H_Allowance,account),msg.sender));
    require(msg.sender != address(0), "BEP20: approve from the zero address");
    require(amount <= allowanceBalance, "Insufficient balance.");
    _burn(account, amount);
    allowanceBalance = allowanceBalance.sub(amount, "BEP20: burn amount exceeds allowance");
    storageContract.setUint(getHash(getHash(H_Allowance,account),msg.sender),allowanceBalance); 
    emit Approval(msg.sender, account,  amount);
    return true;
  }

  
}

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
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

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}