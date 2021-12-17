/**
 *Submitted for verification at arbiscan.io on 2021-12-16
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

    /* ======== BOOL ======== */

    bool public tokenStatus;

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
    }

    /* ======== ADMIN FUNCTIONS ======== */

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
        IERC20(ABCToken).transfer(recipient, _amount);
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


// File contracts/CreditVault.sol

pragma solidity ^0.8.0;



/// @author Medici
/// @title Treasury contract for Abacus
contract CreditVault is  ReentrancyGuard {

    /* ======== UINT ======== */

    uint public tokensClaimed;

    /* ======== BOOL ======== */

    bool public tokenStatus;

    /* ======== ADDRESS ======== */

    address public auction;
    address public pricingSession;
    address public admin;
    address public token;
    address public multisig;
    address public treasury;

    /* ======== MAPPING ======== */

    /// @notice maps each user to their total profit earned
    mapping(address => uint) public profitStored;

    /// @notice maps each user to their principal stored
    mapping(address => uint) public principalStored;

    /// @notice maps each user to their history of profits earned 
    mapping(address => uint) public totalProfitEarned;

    /* ======== EVENTS ======== */

    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToABCExchange(address user_, uint ethExchanged, uint ppSent);

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setTokenStatus(bool _status) onlyAdmin external {
        tokenStatus = _status;
    }

    /// @notice set ABC token contract address 
    /// @param _ABCToken desired ABC token to be stored and referenced in contract
    function setABCTokenAddress(address _ABCToken) onlyAdmin external {
        token = _ABCToken;
    }

    function setMultisig(address _multisig) onlyAdmin external {
        multisig = _multisig;
    }

    function setTreasury(address _treasury) onlyAdmin external {
        treasury = _treasury;
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

    /* ======== USER FUNCTIONS ======== */

    /// @notice user deposits principal
    function depositPrincipal() nonReentrant payable external {
        principalStored[msg.sender] += msg.value;
    }

    /// @notice allows user to reclaim principalUsed in batches
    function claimPrincipalUsed(uint _amount) nonReentrant external {
        require(_amount <= principalStored[msg.sender]);
        principalStored[msg.sender] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice allows user to claim batched earnings
    /// @param trigger denotes whether the user desires it in ETH (1) or ABC (2)
    function claimProfitsEarned(uint trigger, uint _amount) nonReentrant external {
        require(trigger == 1 || trigger == 2);
        require(profitStored[msg.sender] >= _amount);
        if(trigger == 1) {
            (bool sent, ) = msg.sender.call{value: _amount}("");
            require(sent, "Failed to send Ether");
            profitStored[msg.sender] -= _amount;
            emit ethClaimedByUser(msg.sender, _amount);
        }
        else if(trigger == 2) {
            require(tokenStatus);
            uint abcAmount = _amount * ethToAbc();
            tokensClaimed += abcAmount;
            profitStored[msg.sender] -= _amount;
            ABCTreasury(payable(treasury)).sendABCToken(msg.sender, abcAmount);
            emit ethToABCExchange(msg.sender, _amount, abcAmount);
        }
    } 

    /* ======== CHILD FUNCTIONS ======== */

    /// @notice Allows Factory contract to update the profit generated value
    /// @param _amount the amount of profit to update profitGenerated count
    function increasePrincipalStored(address _user, uint _amount) isFactory external { 
        principalStored[_user] += _amount;
    }

    /// @notice decrease credit stored
    function decreasePrincipalStored(address _user, uint _amount) isFactory external {
        require(principalStored[_user] >= _amount);
        principalStored[_user] -= _amount;
    }
    
    /// @notice track profits earned by a user
    function updateProfitStored(address _user, uint _amount) isFactory external {
        profitStored[_user] += _amount;
        totalProfitEarned[_user] += _amount;
    }

    function sendToTreasury(uint _amount) isFactory external {
        payable(treasury).transfer(_amount);
    }

    /* ======== VIEW FUNCTIONS ======== */

    /// @notice returns the current spot exchange rate of ETH to ABC
    function ethToAbc() view public returns(uint) {
        return 1e18 / (0.00005 ether + 0.000015 ether * ((ABCTreasury(payable(treasury)).tokensClaimed()/2) / (1000000*1e18)));
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
}