/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity 0.5.0;


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/ERC20Basic.sol
// 
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address approver, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed approver, address indexed spender, uint256 value);
}

//
// base contract for all our horizon contracts and tokens
//
contract HorizonContractBase {
    // The owner of the contract, set at contract creation to the creator.
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // Contract authorization - only allow the owner to perform certain actions.
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}

//
// Base contract that includes authorisation restrictions.
//
contract AuthorisedContractBase is HorizonContractBase {

    /**
     * @notice The list of addresses that are allowed restricted privileges.
     */
    mapping(address => bool) public authorised;

    /**
     * @notice Notify interested parties when an account&#39;s status changes.
     */
    event AuthorisationChanged(address indexed who, bool isAuthorised);

    /**
     * @notice Sole constructor.  Add the owner to the authorised whitelist.
     */
    constructor() public {
        // The contract owner is always authorised.
        setAuthorised(msg.sender, true);
    } 

    /**
     * @notice Add or remove special privileges.
     *
     * @param who           The address of the contract.
     * @param isAuthorised  Whether special privileges are allowed or not.
     */
    function setAuthorised(address who, bool isAuthorised) public onlyOwner {
        authorised[who] = isAuthorised;
        emit AuthorisationChanged(who, isAuthorised);
    }

    /**
     * Whether the specified address has special privileges or not.
     *
     * @param who       The address of the contract.
     * @return True if address has special privileges, false otherwise.
     */
    function isAuthorised(address who) public view returns (bool) {
        return authorised[who];
    }

    /**
     * @notice Restrict access to anyone nominated by the owner.
     */
    modifier onlyAuthorised() {
        require(isAuthorised(msg.sender), "Access denied.");
        _;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
 * Source: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * VOXToken for the Talketh.io ICO by Horizon-Globex.com of Switzerland.
 *
 * An ERC20 standard
 *
 * Author: Horizon Globex GmbH Development Team
 *
 * Dev Notes
 *   NOTE: There is no fallback function as this contract will never contain Ether, only the VOX tokens.
 *   NOTE: There is no approveAndCall/receiveApproval or ERC223 functionality.
 *   NOTE: Coins will never be minted beyond those at contract creation.
 *   NOTE: Zero transfers are allowed - we don&#39;t want to break a valid transaction chain.
 *   NOTE: There is no selfDestruct, changeOwner or migration path - this is the only contract.
 */


contract VOXToken is ERC20Interface, AuthorisedContractBase {
    using SafeMath for uint256;

    // Contract authorization - only allow the official KYC provider to perform certain actions.
    modifier onlyKycProvider {
        require(msg.sender == regulatorApprovedKycProvider, "Only the KYC Provider can call this function.");
        _;
    }

    // The approved KYC provider that verifies all ICO/TGE Contributors.
    address public regulatorApprovedKycProvider;

    // Public identity variables of the token used by ERC20 platforms.
    string public name = "Talketh";
    string public symbol = "VOX";
    
    // There is no good reason to deviate from 18 decimals, see https://github.com/ethereum/EIPs/issues/724.
    uint8 public decimals = 18;
    
    // The total supply of tokens, set at creation, decreased with burn.
    uint256 public totalSupply_;

    // The supply of tokens, set at creation, to be allocated for the referral bonuses.
    uint256 public rewardPool_;

    // The Initial Coin Offering is finished.
    bool public isIcoComplete;

    // The balances of all accounts.
    mapping (address => uint256) public balances;

    // KYC submission hashes accepted by KYC service provider for AML/KYC review.
    bytes32[] public kycHashes;

    // Addresses authorized to transfer tokens on an account&#39;s behalf.
    mapping (address => mapping (address => uint256)) internal allowanceCollection;

    // Lookup an ICO/TGE Contributor address to see if it was referred by another address (referee => referrer).
    mapping (address => address) public referredBy;

    // Emitted when the Initial Coin Offering phase ends, see closeIco().
    event IcoComplete();

    // Notification when tokens are burned by the owner.
    event Burn(address indexed from, uint256 value);

    // Someone who was referred has purchased tokens, when the bonus is awarded log the details.
    event ReferralRedeemed(address indexed referrer, address indexed referee, uint256 value);

    /**
     * Initialise contract with the 50 million initial supply tokens, allocated to
     * the creator of the contract (the owner).
     */
    constructor() public {
        setAuthorised(msg.sender, true);                    // The owner is always approved.

        totalSupply_ = 50000000 * 10 ** uint256(decimals);   // Set the total supply of VOX Tokens.
        balances[msg.sender] = totalSupply_;
        rewardPool_ = 375000 * 10 ** uint256(decimals);   // Set the total supply of VOX Reward Tokens.
    }

    /**
     * The total number of tokens that exist.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * The total number of reward pool tokens that remains.
     */
    function rewardPool() public onlyOwner view returns (uint256) {
        return rewardPool_;
    }

    /**
     * Get the number of tokens for a specific account.
     *
     * @param who    The address to get the token balance of.
     */
    function balanceOf(address who) public view returns (uint256 balance) {
        return balances[who];
    }

    /**
     * Get the current allowanceCollection that the approver has allowed &#39;spender&#39; to spend on their behalf.
     *
     * See also: approve() and transferFrom().
     *
     * @param _approver  The account that owns the tokens.
     * @param _spender   The account that can spend the approver&#39;s tokens.
     */
    function allowance(address _approver, address _spender) public view returns (uint256) {
        return allowanceCollection[_approver][_spender];
    }

    /**
     * Add the link between the referrer and who they referred.
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform offers functionality for referrers to sign-up
     * to refer Contributors. Upon such referred Contributions, Company shall automatically
     * award 1% of our "owner" VOX tokens to the referrer as coded by this Smart Contract.
     *
     * All referrers must successfully complete our ICO KYC review prior to being allowed on-board.
     * -- End ICO-Platform Note --
     *
     * @param referrer  The person doing the referring.
     * @param referee   The person that was referred.
     */
    function refer(address referrer, address referee) public onlyOwner {
        require(referrer != address(0x0), "Referrer cannot be null");
        require(referee != address(0x0), "Referee cannot be null");
        require(!isIcoComplete, "Cannot add new referrals after ICO is complete.");

        referredBy[referee] = referrer;
    }

    /**
     * Transfer tokens from the caller&#39;s account to the recipient.
     *
     * @param to    The address of the recipient.
     * @param value The number of tokens to send.
     */
    // solhint-disable-next-line no-simple-event-func-name
    function transfer(address to, uint256 value) public returns (bool) {
        return _transfer(msg.sender, to, value);
    }
	
    /**
     * Transfer pre-approved tokens on behalf of an account.
     *
     * See also: approve() and allowance().
     *
     * @param from  The address of the sender
     * @param to    The address of the recipient
     * @param value The number of tokens to send
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowanceCollection[from][msg.sender], "Amount to transfer is greater than allowance.");
		
        allowanceCollection[from][msg.sender] = allowanceCollection[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * Allow another address to spend tokens on your behalf.
     *
     * transferFrom can be called multiple times until the approved balance goes to zero.
     * Subsequent calls to this function overwrite the previous balance.
     * To change from a non-zero value to another non-zero value you must first set the
     * allowance to zero - it is best to use safeApprove when doing this as you will
     * manually have to check for transfers to ensure none happened before the zero allowance
     * was set.
     *
     * @param _spender   The address authorized to spend your tokens.
     * @param _value     The maximum amount of tokens they can spend.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(isAuthorised(_spender), "Target of approve has not passed KYC");
        if(allowanceCollection[msg.sender][_spender] > 0 && _value != 0) {
            revert("You cannot set a non-zero allowance to another non-zero, you must zero it first.");
        }

        allowanceCollection[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * Allow another address to spend tokens on your behalf while mitigating a double spend.
     *
     * Subsequent calls to this function overwrite the previous balance.
     * The old value must match the current allowance otherwise this call reverts.
     *
     * @param spender   The address authorized to spend your tokens.
     * @param value     The maximum amount of tokens they can spend.
     * @param oldValue  The current allowance for this spender.
     */
    function safeApprove(address spender, uint256 value, uint256 oldValue) public returns (bool) {
        require(isAuthorised(spender), "Target of safe approve has not passed KYC");
        require(spender != address(0x0), "Cannot approve null address.");
        require(oldValue == allowanceCollection[msg.sender][spender], "The expected old value did not match current allowance.");

        allowanceCollection[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * The hash for all Know Your Customer information is calculated outside but stored here.
     * This storage will be cleared once the ICO completes, see closeIco().
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform&#39;s KYC app will register a hash of the Contributors
     * KYC submission on the blockchain. Our Swiss financial-intermediary KYC provider will be 
     * notified of the submission and retrieve the Contributor data for formal review.
     *
     * All Contributors must successfully complete our ICO KYC review prior to being allowed on-board.
     * -- End ICO-Platform Note --
     *
     * @param sha   The hash of the customer data.
    */
    function setKycHash(bytes32 sha) public onlyOwner {
        require(!isIcoComplete, "The ICO phase has ended, you can no longer set KYC hashes.");

        // This is deliberately vague to reduce the links to user data.  To verify users you
        // must go through the KYC Provider firm off-chain.
        kycHashes.push(sha);
    }

    /**
     * A user has passed KYC verification, store them on the blockchain in the order it happened.
     * This will be cleared once the ICO completes, see closeIco().
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform&#39;s registered KYC provider submits their approval
     * for this Contributor to particpate using the ICO-Platform portal. 
     *
     * Each Contributor will then be sent the Ethereum, Bitcoin and IBAN account numbers to
     * deposit their Approved Contribution in exchange for VOX Tokens.
     * -- End ICO-Platform Note --
     *
     * @param who   The user&#39;s address.
     */
    function kycApproved(address who) public onlyKycProvider {
        require(!isIcoComplete, "The ICO phase has ended, you can no longer approve.");
        require(who != address(0x0), "Cannot approve a null address.");

        // NOTE: setAuthorised is onlyOwner, directly perform the actions as KYC Provider.
        authorised[who] = true;
        emit AuthorisationChanged(who, true);
    }

    /**
     * Set the address that has the authority to approve users by KYC.
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform shall register a fully licensed Swiss KYC
     * provider to assess each potential Contributor for KYC and AML under Swiss law. 
     *
     * -- End ICO-Platform Note --
     *
     * @param who   The address of the KYC provider.
     */
    function setKycProvider(address who) public onlyOwner {
        regulatorApprovedKycProvider = who;
    }

    /**
     * Retrieve the KYC hash from the specified index.
     *
     * @param   index   The index into the array.
     */
    function getKycHash(uint256 index) public view returns (bytes32) {
        return kycHashes[index];
    }

    /**
     * When someone referred (the referee) purchases tokens the referrer gets a 1% bonus from the central pool.
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform&#39;s portal shall award referrers as part of the ICO
     * VOX Token issuance procedure as overseen by the Swiss KYC provider. 
     *
     * -- End ICO-Platform Note --
     *
     * @param referee   The referred account who just purchased some tokens.
     * @param referrer  The account that referred the one purchasing tokens.
     * @param value     The number of tokens purchased by the referee.
    */
    function awardReferralBonus(address referee, address referrer, uint256 value) private {
        uint256 bonus = value / 100;
        balances[owner] = balances[owner].sub(bonus);
        balances[referrer] = balances[referrer].add(bonus);
        rewardPool_ -= bonus;
        emit ReferralRedeemed(referee, referrer, bonus);
    }

    /**
     * During the ICO phase the owner will allocate tokens once KYC completes and funds are deposited.
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform&#39;s portal shall issue VOX Token to Contributors on receipt of 
     * the Approved Contribution funds at the KYC providers Escrow account/wallets.
     * Only after VOX Tokens are issued to the Contributor can the Swiss KYC provider allow the transfer
     * of funds from their Escrow to Company.
     *
     * -- End ICO-Platform Note --
     *
     * @param to       The recipient of the tokens.
     * @param value    The number of tokens to send.
     */
    function icoTransfer(address to, uint256 value) public onlyOwner {
        require(!isIcoComplete, "ICO is complete, use transfer().");

        // If an attempt is made to transfer more tokens than owned, transfer the remainder.
        uint256 toTransfer = (value > (balances[msg.sender] - rewardPool_ )) ? (balances[msg.sender] - rewardPool_) : value;
        
        _transfer(msg.sender, to, toTransfer);

        // Handle a referred account receiving tokens.
        address referrer = referredBy[to];
        if(referrer != address(0x0)) {
            referredBy[to] = address(0x0);
            awardReferralBonus(to, referrer, toTransfer);
        }
    }

    /**
     * End the ICO phase in accordance with KYC procedures and clean up.
     *
     * ---- ICO-Platform Note ----
     * The horizon-globex.com ICO platform&#39;s portal shall halt the ICO at the end of the 
     * Contribution Period, as defined in the ICO Terms and Conditions https://talketh.io/Terms.
     *
     * -- End ICO-Platform Note --
     */
    function closeIco() public onlyOwner {
        require(!isIcoComplete, "The ICO phase has already ended, you cannot close it again.");
        require((balances[owner] - rewardPool_) == 0, "Cannot close ICO when a balance remains in the owner account.");

        isIcoComplete = true;

        emit IcoComplete();
    }
	
    /**
     * Internal transfer, can only be called by this contract
     *
     * @param from     The sender of the tokens.
     * @param to       The recipient of the tokens.
     * @param value    The number of tokens to send.
     */
    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        require(isAuthorised(to), "Target of transfer has not passed KYC");
        require(from != address(0x0), "Cannot send tokens from null address");
        require(to != address(0x0), "Cannot transfer tokens to null");
        require(balances[from] >= value, "Insufficient funds");

        // Quick exit for zero, but allow it in case this transfer is part of a chain.
        if(value == 0)
            return true;
		
        // Perform the transfer.
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
		
        // Any tokens sent to to owner are implicitly burned.
        if (to == owner) {
            _burn(to, value);
        }

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * Permanently destroy tokens belonging to a user.
     *
     * @param addressToBurn    The owner of the tokens to burn.
     * @param value            The number of tokens to burn.
     */
    function _burn(address addressToBurn, uint256 value) private returns (bool success) {
        require(value > 0, "Tokens to burn must be greater than zero");
        require(balances[addressToBurn] >= value, "Tokens to burn exceeds balance");

        balances[addressToBurn] = balances[addressToBurn].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Burn(msg.sender, value);

        return true;
    }
}