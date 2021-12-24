/**
 *Submitted for verification at arbiscan.io on 2021-12-23
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/interfaces/IERC20.sol

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


// File contracts/helpers/ReentrancyGuard.sol

pragma solidity ^0.8.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}


// File contracts/ABCTreasury.sol

pragma solidity ^0.8.0;


/// @author Medici
/// @title Treasury contract for Abacus
contract ABCTreasury is  ReentrancyGuard {
    
    /* ======== UINT ======== */

    uint public nftsPriced;
    uint public profitGenerated;
    uint public tokensClaimed;
    uint public riskFactor;
    uint public spread;
    uint public defender;
    uint public commissionRate;
    uint public payoutMultiplier;

    /* ======== BOOL ======== */

    bool public tokenStatus;
    bool public auctionStatus;

    /* ======== ADDRESS ======== */

    address public auction;
    address public pricingSession;
    address public admin;
    address public ABCToken;
    address public multisig;
    address public creditStore;

    /* ======== EVENTS ======== */

    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToABCExchange(address user_, uint ethExchanged, uint ppSent);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _creditStore) {
        admin = msg.sender;
        creditStore = _creditStore;
        auctionStatus = true;
        riskFactor = 2;
        spread = 10;
        defender = 2;
        commissionRate = 500;
        payoutMultiplier = 200;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    /// @notice set the auction status based on the active/inactive status of the bounty auction
    /// @param status desired auction status to be stored and referenced in contract
    function setAuctionStatus(bool status) onlyAdmin external {
        auctionStatus = status;
    }

    /// @notice set the auction status based on the active/inactive status of the bounty auction
    /// @param _commissionRate desired commission percentage the protocol would like to take
    function setCommissionRate(uint _commissionRate) onlyAdmin external {
        commissionRate = _commissionRate;
    }

    function setPayoutMultiplier(uint _multiplier) onlyAdmin external {
        payoutMultiplier = _multiplier;
    }

    /// @notice set protocol risk factor
    /// @param _risk the protocol risk factor is a multiplier applied to any losses harvested
    function setRiskFactor(uint _risk) onlyAdmin external {
        riskFactor = _risk;
    }

    /// @notice set the protocol spread
    /// @param _spread the protocol spread is the margin of error that correctness is based on
    function setSpread(uint _spread) onlyAdmin external {
        spread = _spread;
    }

    /// @notice set the protocol defender level
    /** @dev the defender is used to determined the amount of
    recursive bound exclusions enforced per session. 
    
    For example, in times of a high volume of extreme value attacks,
    the community can set the defender to level 3 in which case every session
    will have the _boundCheck happen 3 times. What this means is there will be
    one bound check, the final appraisal will be adjusted, then a second check,
    final appraisal will be re-adjusted, then a third, and final appraisal will
    be adjusted one final time. 

    Any values that are removed result in removal from final appraisal affect 
    AND their stake is completely lost. 
    */
    /// @param _defender the defender is a value that determines the amount of recursive bound exclusions enforced per session
    function setDefender(uint _defender) onlyAdmin external {
        defender = _defender;
    }

    /// @notice set ABC token contract address 
    /// @param _ABCToken desired ABC token to be stored and referenced in contract
    function setABCTokenAddress(address _ABCToken) onlyAdmin external {
        ABCToken = _ABCToken;
    }

    function setMultisig(address _multisig) onlyAdmin external {
        multisig = _multisig;
    }

    /// @notice allow admin to withdraw funds to multisig in the case of emergency (ONLY USED IN THE CASE OF EMERGENCY)
    /// @param _amountEth value of ETH to be withdrawn from the treasury to multisig (ONLY USED IN THE CASE OF EMERGENCY)
    function withdrawEth(uint _amountEth) onlyAdmin external {
        (bool sent, ) = payable(multisig).call{value: _amountEth}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice allow admin to withdraw funds to multisig in the case of emergency (ONLY USED IN THE CASE OF EMERGENCY)
    /// @param _amountAbc value of ABC to be withdrawn from the treasury to multisig (ONLY USED IN THE CASE OF EMERGENCY)
    function withdrawAbc(uint _amountAbc) onlyAdmin external {
        bool sent = IERC20(ABCToken).transfer(multisig, _amountAbc);
        require(sent);
    }

    /// @notice set newAdmin (or burn admin when the time comes)
    /// @param _newAdmin desired admin address to be stored and referenced in contract
    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    /// @notice set pricing factory address to allow for updates
    /// @param _pricingFactory desired pricing session principle address to be stored and referenced in contract
    function setPricingSession(address _pricingFactory) onlyAdmin external {
        pricingSession = _pricingFactory;
    }

    /// @notice set auction contract for bounty auction period
    /// @param _auction desired auction address to be stored and referenced in contract
    function setAuction(address _auction) onlyAdmin external {
        auction = _auction;
    }

    function setCreditStore(address _creditStore) onlyAdmin external {
        creditStore = _creditStore;
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    /// @notice send ABC to users that earn 
    /// @param recipient the user that will be receiving ABC 
    /// @param _amount the amount of ABC to be transferred to the recipient
    function sendABCToken(address recipient, uint _amount) public {
        require(msg.sender == creditStore || msg.sender == admin);
        if(msg.sender == creditStore) {
            IERC20(ABCToken).transfer(recipient, payoutMultiplier * _amount / 100);
        }
        else {
            IERC20(ABCToken).transfer(recipient, _amount);
        }
    }

    /// @notice track amount of nfts priced
    function updateNftPriced() isFactory external {
        nftsPriced++;
    }

    /// @notice track total profits generated by the protocol through fees
    function updateTotalProfitsGenerated(uint _amount) isFactory external {
        profitGenerated += _amount;
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    ///@notice check that msg.sender is admin
    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }
    
    ///@notice check that msg.sender is factory
    modifier isFactory() {
        require(msg.sender == pricingSession, "not session contract");
        _;
    }

    ///@notice check that msg.sender is factory
    modifier isCreditStore() {
        require(msg.sender == creditStore, "not credit store contract");
        _;
    }
}