/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

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
contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

interface ISHP {
  function balanceOfAt(address owner, uint256 blockNumber) external pure returns (uint256);
  function totalSupplyAt(uint256 blockNumber) external pure returns (uint256);
}

interface IVegaVesting {
  function tranche_count() external view returns(uint8);
  function withdraw_from_tranche(uint8 tranche_id) external;
  function get_vested_for_tranche(address user, uint8 tranche_id) external view returns(uint256);
  function user_total_all_tranches(address user) external view returns(uint256);
}

contract VEGA_Pool is Ownable {

  uint256 public constant EXEPECTED_VEGA = 422000 ether;
  uint256 public constant EQUITY_RATIO = 2500;

  uint256 public assignSharesCutoff;
  uint256 public equityTokens;
  uint256 public equityTokensRedeemed;
  uint256 public preferentialTokens;
  uint256 public preferentialTokensRedeemed;

  address public preferentialAddress;

  bool public initialized = false;

  ISHP public shp;
  IERC20 public vega;
  IVegaVesting public vegaVesting;

  uint256 public referenceBlock;

  bool public voteComplete = false;
  bool public approveDistribution = false;

  mapping(address => uint256) public equityShares;
  mapping(address => bool) public permittedEquityHolders;
  mapping(uint256 => address) public equityHolders;
  mapping(address => int8) public distributionVotes;
  mapping(address => bool) public shpTokensRedeemed;

  uint256 public totalEquityHolders;
  uint256 public totalShares;
  uint256 public totalVotes;
  int256 public voteOutcome;
  uint256 public shpRedemptionCount;

  event VoteCast(int8 vote, address shareholder);
  event TokensClaimed(uint256 amount, address recipient);
  event ERC20TokenWithdrawn(uint256 amount, address tokenAddress);
  event EtherWithdrawn(uint256 amount);
  event EquityIssued(address holder, uint256 amount,
    uint256 totalEquityHolders, uint256 totalShares);
  event PreferentialTokensRedeemed(uint256 amount);
  event EquityTokensRedeemed(address recipient, uint256 amount);
  event ExcessTokensRedeemed(uint256 amount);
  event PermittedEquityHolderAdded(address holder);
  event VegaPoolInitialized(address vegaAddress, address vestingAddress,
    address preferentialAddress, uint256 assignSharesCutoff,
    uint256 referenceBlock, address shpTokenAddress);

  // This modifier makes sure the contract has been initialized
  modifier requireInitialized() {
     require(initialized, "Contract is not initialized.");
     _;
  }

  // This modifier makes sure the contract is not initialized
  modifier notInitialized() {
     require(!initialized, "Contract has been initialized.");
     _;
  }

  receive() external payable { }

  /**
  * This function allows equity holders to vote on whether tokens should
  * remain theirs, or whether they should be made available for redemption
  * by SHP token holders.
  *
  * If they vote to allow SHP token holders to redeem VEGA from the contract
  * then SHP token holders will be able to call the claimTokens function
  * and the amount of VEGA will be calculated based on their SHP holding
  * at the reference Ethereum block.
  *
  * Once the vote has been successfully completed, if the equity holders vote
  * AGAINST distrubiton, they will be able to redeem tokens by calling
  * redeemTokensViaEquity. If they vote FOR distribution they will not be
  * able to redeem any tokens. Instead SHP token holders will be able to
  * redeem tokens by calling claimTokens.
  *
  * _vote   the user's vote (1 = for, -1 = against)
  **/
  function castVote(int8 _vote) requireInitialized public {
    require(block.timestamp > assignSharesCutoff,
      "Cannot vote whilst shares can still be assigned.");
    require(distributionVotes[msg.sender] == 0,
      "You have already cast your vote.");
    require(_vote == 1 || _vote == -1,
      "Vote must be 1 or -1");
    require(voteComplete == false,
      "Voting has already concluded.");
    require(equityShares[msg.sender] > 0,
      "You cannot vote without equity shares.");
    int256 weight = int256(getUserEquity(msg.sender));
    distributionVotes[msg.sender] = _vote;
    totalVotes += 1;
    voteOutcome += (_vote * weight);
    if(totalVotes == totalEquityHolders) {
      voteComplete = true;
      approveDistribution = voteOutcome > 0;
    }
    emit VoteCast(_vote, msg.sender);
  }

  /**
  * This function withdraws any vested tokens and redeems the preferential
  * tokens if they have not already been redeemed.
  **/
  function syncTokens() requireInitialized internal {
    withdrawVestedTokens();
    if(preferentialTokens > preferentialTokensRedeemed) {
      redeemPreferentialTokens();
    }
  }

  /**
  * This function allows users that held SHP at the reference Ethereum block
  * to claim VEGA from the smart contract, provided the equity holders have
  * voted to permit them to do so.
  *
  * If permitted to do so, the equityTokens will be made available to users
  * in direct proportion to the SHP held (divided by total supply) at the
  * reference block.
  **/
  function claimTokens() requireInitialized public {
    require(approveDistribution, "Distribution is not approved");
    syncTokens();
    require(preferentialTokens == preferentialTokensRedeemed,
      "Cannot claim until preferential tokens are redeemed.");
    uint256 shpBalance = shp.balanceOfAt(msg.sender, referenceBlock);
    require(shpTokensRedeemed[msg.sender] == false,
      "SHP holder already claimed tokens.");
    uint256 vegaBalance = vega.balanceOf(address(this));
    require(shpRedemptionCount > 0 || vegaBalance >= equityTokens,
      "Cannot claim until all equity tokens are fully vested.");
    uint256 shpSupply = shp.totalSupplyAt(referenceBlock);
    uint256 mod = 1000000000000;
    uint256 tokenAmount = (((shpBalance * mod) / shpSupply) *
      equityTokens) / mod;
    vega.transfer(msg.sender, tokenAmount);
    equityTokensRedeemed += tokenAmount;
    shpTokensRedeemed[msg.sender] = true;
    shpRedemptionCount += 1;
    emit TokensClaimed(tokenAmount, msg.sender);
  }

  /**
  * This function allows the owner to withdraw any ERC20 which is not VEGA
  * from the contract at-will. This can be used to redeem staking rewards,
  * or other ERC20s which might end up in this contract by mistake, or by
  * something like an airdrop.
  *
  * _tokenAddress    the contract address for the ERC20
  **/
  function withdrawArbitraryTokens(
    address _tokenAddress
  ) requireInitialized onlyOwner public {
    require(_tokenAddress != address(vega),
      "VEGA cannot be withdrawn at-will.");
    IERC20 token = IERC20(_tokenAddress);
    uint256 amount = token.balanceOf(address(this));
    token.transfer(owner(), amount);
    emit ERC20TokenWithdrawn(amount, _tokenAddress);
  }

  /**
  * This function performs the same role as withdrawArbitraryTokens, except
  * it is used to withdraw ETH.
  **/
  function withdrawEther() requireInitialized onlyOwner public {
    uint256 amount = address(this).balance;
    payable(owner()).transfer(amount);
    emit EtherWithdrawn(amount);
  }

  /**
  * This function can be called by anybody and it withdraws unlocked
  * VEGA tokens from the vesting contract. The tokens are transferred
  * to this contract, which allows them to be redeemed by the rightful owner
  * when they call one of the redemption functions.
  **/
  function withdrawVestedTokens() requireInitialized internal {
    for(uint8 i = 1; i < vegaVesting.tranche_count(); i++) {
      if(vegaVesting.get_vested_for_tranche(address(this), i) > 0) {
        vegaVesting.withdraw_from_tranche(i);
      }
    }
  }

  /**
  * This function allows the owner to issue equity to new users. This is done
  * by assigning an absolute number of shares, which in turn dilutes all
  * existing share holders.
  *
  * _holder    the Ethereum address of the equity holder
  * _amount    the number of shares to be assigned to the holder
  **/
  function issueEquity(
    address _holder,
    uint256 _amount
  ) requireInitialized onlyOwner public {
    require(permittedEquityHolders[_holder],
      "The holder must be permitted to own equity.");
    require(assignSharesCutoff > block.timestamp,
      "The cutoff has passed for assigning shares.");
    if(equityShares[_holder] == 0) {
      equityHolders[totalEquityHolders] = _holder;
      totalEquityHolders += 1;
    }
    totalShares += _amount;
    equityShares[_holder] += _amount;
    emit EquityIssued(_holder, _amount, totalEquityHolders, totalShares);
  }

  /**
  * This function allows the preferential tokens to be distributed to the
  * rightful owner. This function can be called by anybody.
  **/
  function redeemPreferentialTokens() requireInitialized public {
    require(preferentialTokens > preferentialTokensRedeemed,
      "All preferntial tokens have been redeemed.");
    withdrawVestedTokens();
    uint256 availableTokens = preferentialTokens - preferentialTokensRedeemed;
    uint256 vegaBalance = vega.balanceOf(address(this));
    if(availableTokens > vegaBalance) {
      availableTokens = vegaBalance;
    }
    vega.transfer(preferentialAddress, availableTokens);
    preferentialTokensRedeemed += availableTokens;
    emit PreferentialTokensRedeemed(availableTokens);
  }

  /**
  * This function distributes tokens to equity holders based on the amount
  * of shares they own.
  *
  * Anybody can call this function in order to ensure all of the tokens are
  * distributed when it becomes eligible to do so.
  **/
  function redeemTokensViaEquity() requireInitialized public {
    require(totalShares > 0, "There are are no equity holders");
    require(assignSharesCutoff < block.timestamp,
      "Tokens cannot be redeemed whilst equity can still be assigned.");
    syncTokens();
    require(preferentialTokens == preferentialTokensRedeemed,
      "Cannot redeem via equity until all preferential tokens are collected.");
    require(voteComplete, "Cannot redeem via equity until vote is completed.");
    require(approveDistribution == false,
      "Tokens can only be redeemed by SHP holders.");
    uint256 availableTokens = equityTokens - equityTokensRedeemed;
    uint256 vegaBalance = vega.balanceOf(address(this));
    if(availableTokens > vegaBalance) {
      availableTokens = vegaBalance;
    }
    for(uint256 i = 0; i < totalEquityHolders; i++) {
      uint256 tokensToRedeem = (availableTokens *
        getUserEquity(equityHolders[i])) / 10000;
      vega.transfer(equityHolders[i], tokensToRedeem);
      equityTokensRedeemed += tokensToRedeem;
      emit EquityTokensRedeemed(equityHolders[i], tokensToRedeem);
    }
  }

  /**
  * This function allows anybody to redeem excess VEGA to the owner's wallet
  * provided the following conditions are met:
  *
  * 1) No equity shares exist, which happens under two scenarios:
  *      a) They are never issued in the first place
  *      b) They are burnt after redeeming VEGA
  * 2) The cut-off for assigning equity shares is in the past
  *
  * This function transfers the entire VEGA balance held by the
  * smart contract at execution time.
  **/
  function redeemExcessTokens() requireInitialized public {
    if(totalEquityHolders > 0) {
      require(equityTokens == equityTokensRedeemed,
        "Cannot redeem excess tokens until equity tokens are collected.");
    }
    require(preferentialTokens == preferentialTokensRedeemed,
      "Cannot redeem excess tokens until preferential tokens are collected.");
    withdrawVestedTokens();
    uint256 amount = vega.balanceOf(address(this));
    emit ExcessTokensRedeemed(amount);
    vega.transfer(owner(), amount);
  }

  /**
  * This function calculates the equity of the specified user
  *
  * _holder    the Ethereum address of the equity holder
  **/
  function getUserEquity(
    address _holder
  ) public view returns(uint256) {
    return (equityShares[_holder] * 10000) / totalShares;
  }

  /**
  * This function allows the contract to be initialized only once.
  * We do not use the constructor, because the Vega vesting contract needs to
  * know the address of this smart contract when it is deployed. Therefore,
  * this contract needs to be deployed, and then updated with the address of
  * the Vega vesting contract afterwards.
  *
  * _vegaAdress           the Ethereum address of the VEGA token contract
  * _vegaVestingAddress   the Ethereum address of Vega's vesting contract
  * _preferentialAddress  Ethereum address for preferential tokens
  * _holders              an array of permitted equity holders
  * _assignSharesCutoff   timestamp after which shares cannot be assigned
  * _referenceBlock       the Ethereum block to lookup SHP balances with
  * _shpTokenAddress      the Ethereum address for SHP token contract
  **/
  function initialize(
    address _vegaAddress,
    address _vegaVestingAddress,
    address _preferentialAddress,
    address[] memory _holders,
    uint256 _assignSharesCutoff,
    uint256 _referenceBlock,
    address _shpTokenAddress
  ) public onlyOwner notInitialized {
    vega = IERC20(_vegaAddress);
    shp = ISHP(_shpTokenAddress);
    vegaVesting = IVegaVesting(_vegaVestingAddress);
    uint256 totalTokens = vegaVesting.user_total_all_tranches(address(this));
    preferentialAddress = _preferentialAddress;
    assignSharesCutoff = _assignSharesCutoff;
    referenceBlock = _referenceBlock;
    require(totalTokens >= EXEPECTED_VEGA,
      "The balance at the vesting contract is too low.");
    for(uint8 x = 0; x < _holders.length; x++) {
      permittedEquityHolders[_holders[x]] = true;
      emit PermittedEquityHolderAdded(_holders[x]);
    }
    equityTokens = (totalTokens * EQUITY_RATIO) / 10000;
    preferentialTokens = totalTokens - equityTokens;
    initialized = true;
    emit VegaPoolInitialized(_vegaAddress, _vegaVestingAddress,
      _preferentialAddress, _assignSharesCutoff,
      _referenceBlock, _shpTokenAddress);
  }
}