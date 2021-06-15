/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File contracts/interface/IExchangeQuoter.sol


pragma solidity 0.8.0;


/**
 * @title IExchangeQuoter
 * @author solace.fi
 * @notice Calculates exchange rates for trades between ERC20 tokens.
 */
interface IExchangeQuoter {
    /**
     * @notice Calculates the exchange rate for an _amount of _token to eth.
     * @param _token The token to give.
     * @param _amount The amount to give.
     * @return The amount of eth received.
     */
    function tokenToEth(address _token, uint256 _amount) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity 0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File contracts/interface/IProduct.sol


pragma solidity 0.8.0;

/**
 * @title Interface for product contracts
 * @author solace.fi
 */
interface IProduct {
    event PolicyCreated(uint256 policyID);
    event PolicyExtended(uint256 policyID);
    event PolicyCanceled(uint256 policyID);

    /**** GETTERS + SETTERS
    Functions which get and set important product state variables
    ****/
    function setGovernance(address _governance) external;
    function setClaimsAdjuster(address _claimsAdjuster) external;
    function setPrice(uint256 _price) external;
    function setCancelFee(uint256 _cancelFee) external;
    function setMinPeriod(uint256 _minPeriod) external;
    function setMaxPeriod(uint256 _maxPeriod) external;
    function setMaxCoverAmount(uint256 _maxCoverAmount) external;

    /**** UNIMPLEMENTED FUNCTIONS
    Functions that are only implemented by child product contracts
    ****/
    function appraisePosition(address _policyholder, address _positionContract) external view returns (uint256 positionAmount);

    /**** QUOTE VIEW FUNCTIONS
    View functions that give us quotes regarding a policy
    ****/
    function getQuote(address _policyholder, address _positionContract, uint256 _coverLimit, uint256 _blocks) external view returns (uint256);

    /**** MUTATIVE FUNCTIONS
    Functions that deploy and change policy contracts
    ****/
    function updateActivePolicies() external returns (uint256, uint256);
    function buyPolicy(address _policyholder, address _positionContract, uint256 _coverLimit, uint256 _blocks) external payable returns (uint256 policyID);
    // function updateCoverLimit(address _policy, uint256 _coverLimit) external payable returns (bool);
    function extendPolicy(uint256 _policyID, uint256 _blocks) external payable;
    function cancelPolicy(uint256 _policyID) external;
}


// File contracts/interface/IPolicyManager.sol


pragma solidity 0.8.0;

interface IPolicyManager {
    event ProductAdded(address product);
    event ProductRemoved(address product);
    event PolicyCreated(uint256 tokenID);
    event PolicyBurned(uint256 tokenID);

    struct PolicyTokenURIParams {
        address policyholder;
        address product;
        address positionContract;
        uint256 expirationBlock;
        uint256 coverAmount;
        uint256 price;
    }

    function setGovernance(address _governance) external;
    function addProduct(address _product) external;
    function removeProduct(address _product) external;

    /*** POLICY VIEW FUNCTIONS 
    View functions that give us data about policies
    ****/
    function getPolicyParams(uint256 _policyID) external view returns (PolicyTokenURIParams memory);
    function getPolicyholder(uint256 _policyID) external view returns (address);
    function getPolicyProduct(uint256 _policyID) external view returns (address);
    function getPolicyPositionContract(uint256 _policyID) external view returns (address);
    function getPolicyExpirationBlock(uint256 _policyID) external view returns (uint256);
    function getPolicyCoverAmount(uint256 _policyID) external view returns (uint256);
    function getPolicyPrice(uint256 _policyID) external view returns (uint256);
    function myPolicies() external view returns (uint256[] memory);

    /*** POLICY MUTATIVE FUNCTIONS 
    Functions that create, modify, and destroy policies
    ****/
    function createPolicy(address _policyholder, address _positionContract, uint256 _expirationBlock, uint256 _coverAmount, uint256 _price) external returns (uint256 tokenID);
    function setTokenURI(uint256 _tokenId, address _policyholder, address _positionContract, uint256 _expirationBlock, uint256 _coverAmount, uint256 _price) external;
    function burn(uint256 _tokenId) external;

    /*** ERC721 INHERITANCE FUNCTIONS 
    Overrides that properly set functionality through parent contracts
    ****/
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/interface/ITreasury.sol


pragma solidity 0.8.0;


/**
 * @title ITreasury
 * @author solace.fi
 * @notice The interface of the war chest of Castle Solace.
 */
interface ITreasury {

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    // events
    // Emitted when eth is deposited
    event EthDeposited(uint256 _amount);
    // Emitted when a token is deposited
    event TokenDeposited(address _token, uint256 _amount);
    // Emitted when a token is spent
    event FundsSpent(address _token, uint256 _amount, address _recipient);
    // Emitted when a token swap path is set
    event PathSet(address _token, bytes _path);
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);

    /**
     * Receive function. Deposits eth.
     */
    receive() external payable;

    /**
     * Fallback function. Deposits eth.
     */
    fallback () external payable;

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Sets the swap path for a token.
     * Can only be called by the current governor.
     * @dev Also adds or removes infinite approval of the token for the router.
     * @param _token The token to set the path for.
     * @param _path The path to take.
     */
    function setPath(address _token, bytes calldata _path) external;

    /**
     * @notice Deposits some ether.
     */
    function depositEth() external payable;

    /**
     * @notice Deposit some ERC20 token.
     * @param _token The address of the token to deposit.
     * @param _amount The amount of the token to deposit.
     */
    function depositToken(address _token, uint256 _amount) external;

    /**
     * @notice Spends some tokens.
     * Can only be called by the current governor.
     * @param _token The address of the token to spend.
     * @param _amount The amount of the token to spend.
     * @param _recipient The address of the token receiver.
     */
    function spend(address _token, uint256 _amount, address _recipient) external;

    /**
     * @notice Manually swaps a token.
     * Can only be called by the current governor.
     * @dev Swaps the entire balance in case some tokens were unknowingly received.
     * Reverts if the swap was unsuccessful.
     * @param _path The path of pools to take.
     * @param _amountIn The amount to swap.
     * @param _amountOutMinimum The minimum about to receive.
     */
    function swap(bytes calldata _path, uint256 _amountIn, uint256 _amountOutMinimum) external;

    // used in Product
    function refund(address _user, uint256 _amount) external;
}


// File contracts/BaseProduct.sol


pragma solidity 0.8.0;




/* TODO
 * - treasury refund() function, check transfer to treasury when buyPolicy()
 * - optimize _updateActivePolicies(), store in the expiration order (minheap)
 * - implement updateCoverLimit() so user can adjust exposure as their position changes in value
 * - implement transferPolicy() so a user can transfer their LP tokens somewhere else and update that on their policy
 */

/**
 * @title BaseProduct
 * @author solace.fi
 * @notice To be inherited by individual Product contracts.
 */
abstract contract BaseProduct is IProduct {
    using Address for address;

    // Governor
    address public governance;

    // Policy Manager
    IPolicyManager public policyManager; // Policy manager ERC721 contract

    // Treasury
    ITreasury public treasury; // Treasury contract

    // Product Details
    address public coveredPlatform; // a platform contract which locates contracts that are covered by this product
                                    // (e.g., UniswapProduct will have Factory as coveredPlatform contract, because
                                    // every Pair address can be located through getPool() function)
    address public claimsAdjuster; // address of the parametric auto claims adjuster
    uint256 public price; // cover price (in wei) per block per wei (multiplied by 1e12 to avoid underflow upon construction or setter)
    uint256 public cancelFee; // policy cancelation fee
    uint256 public minPeriod; // minimum policy period in blocks
    uint256 public maxPeriod; // maximum policy period in blocks
    uint256 public maxCoverAmount; // maximum amount of coverage (in wei) this product can sell

    // Book-keeping varaibles
    uint256 public productPolicyCount; // total policy count this product sold
    uint256 public activeCoverAmount; // current amount covered (in wei)
    uint256[] public activePolicyIDs;


    constructor (
        IPolicyManager _policyManager,
        ITreasury _treasury,
        address _coveredPlatform,
        address _claimsAdjuster,
        uint256 _price,
        uint256 _cancelFee,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxCoverAmount)
    {
        governance = msg.sender;
        policyManager = _policyManager;
        treasury = _treasury;
        coveredPlatform = _coveredPlatform;
        claimsAdjuster = _claimsAdjuster;
        price = _price;
        cancelFee = _cancelFee;
        minPeriod = _minPeriod;
        maxPeriod = _maxPeriod;
        maxCoverAmount = _maxCoverAmount;
        productPolicyCount = 0;
        activeCoverAmount = 0;
    }

    /**** GETTERS + SETTERS
    Functions which get and set important product state variables
    ****/

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    /**
     * @notice Sets the claims adjuster for this product
     * @param _claimsAdjuster address of the claims adjuster contract
     */
    function setClaimsAdjuster(address _claimsAdjuster) external override {
        require(msg.sender == governance, "!governance");
        claimsAdjuster = _claimsAdjuster;
    }

    /**
     * @notice Sets the price for this product
     * @param _price cover price (in wei) per ether per block
     */
    function setPrice(uint256 _price) external override {
        require(msg.sender == governance, "!governance");
        price = _price;
    }

    /**
     * @notice Sets the fee that user must pay upon canceling the policy
     * @param _cancelFee policy cancelation fee
     */
    function setCancelFee(uint256 _cancelFee) external override {
        require(msg.sender == governance, "!governance");
        cancelFee = _cancelFee;
    }

    /**
     * @notice Sets the minimum number of blocks a policy can be purchased for
     * @param _minPeriod minimum number of blocks
     */
    function setMinPeriod(uint256 _minPeriod) external override {
        require(msg.sender == governance, "!governance");
        minPeriod = _minPeriod;
    }

    /**
     * @notice Sets the maximum number of blocks a policy can be purchased for
     * @param _maxPeriod maximum number of blocks
     */
    function setMaxPeriod(uint256 _maxPeriod) external override {
        require(msg.sender == governance, "!governance");
        maxPeriod = _maxPeriod;
    }

    /**
     * @notice Sets the maximum coverage amount this product can provide
     * @param _maxCoverAmount maximum coverage amount (in wei)
     */
    function setMaxCoverAmount(uint256 _maxCoverAmount) external override {
        require(msg.sender == governance, "!governance");
        maxCoverAmount = _maxCoverAmount;
    }


    /**** UNIMPLEMENTED FUNCTIONS
    Functions that are only implemented by child product contracts
    ****/

    /**
     * @notice
     *  Provide the user's total position in the product's protocol.
     *  This total should be denominated in eth.
     * @dev
     *  Every product will have a different mechanism to read and determine
     *  a user's total position in that product's protocol. This method will
     *  only be implemented in the inheriting product contracts
     * @param _policyholder buyer requesting the coverage quote
     * @param _positionContract address of the exact smart contract the buyer has their position in (e.g., for UniswapProduct this would be Pair's address)
     * @return positionAmount The user's total position in wei in the product's protocol.
     */
    function appraisePosition(address _policyholder, address _positionContract) public view override virtual returns (uint256 positionAmount);

    /**** QUOTE VIEW FUNCTIONS
    View functions that give us quotes regarding a policy purchase
    ****/

    /**
     * @notice
     *  Provide a premium quote.
     * @param _coverLimit percentage (in BPS) of cover for total position
     * @param _blocks length for policy
     * @return premium The quote for their policy in wei.
     */
    function _getQuote(uint256 _coverLimit, uint256 _blocks, uint256 _positionAmount) internal view returns (uint256 premium){
        premium = _positionAmount * _coverLimit * _blocks * price / 1e16;
        return premium;
    }

    function getQuote(address _policyholder, address _positionContract, uint256 _coverLimit, uint256 _blocks) external view override returns (uint256){
        uint256 positionAmount = appraisePosition(_policyholder, _positionContract);
        return _getQuote(_coverLimit, _blocks, positionAmount);
    }


    /**** MUTATIVE FUNCTIONS
    Functions that change state variables, deploy and change policy contracts
    ****/

    /**
     * @notice Updates active policy count and active cover amount
     */
    function _updateActivePolicies() internal {
        for (uint256 i=0; i < activePolicyIDs.length; i++) {
            if (policyManager.getPolicyExpirationBlock(activePolicyIDs[i]) < block.number) {
                activeCoverAmount -= policyManager.getPolicyCoverAmount(activePolicyIDs[i]);
                policyManager.burn(activePolicyIDs[i]);
                delete activePolicyIDs[i];
            }
        }
    }

    /**
     * @notice Updates the product's book-keeping variables,
     * removing expired policies from the policies set and updating active cover amount
     * @return activeCoverAmount and activePolicyCount active covered amount and active policy count as a tuple
     */
    function updateActivePolicies() external override returns (uint256, uint256){
        _updateActivePolicies();
        return (activeCoverAmount, activePolicyIDs.length);
    }

    /**
     * @notice
     *  Purchase and deploy a policy on the behalf of the policyholder
     * @param _coverLimit percentage (in BPS) of cover for total position
     * @param _blocks length (in blocks) for policy
     * @param _policyholder who's liquidity is being covered by the policy
     * @param _positionContract contract address where the policyholder has a position to be covered

     * @return policyID The contract address of the policy
     */
    function buyPolicy(address _policyholder, address _positionContract, uint256 _coverLimit, uint256 _blocks) external payable override returns (uint256 policyID){
        // check that the buyer has a position in the covered protocol
        uint256 positionAmount = appraisePosition(_policyholder, _positionContract);
        require(positionAmount != 0, 'zero position value');

        // check that the product can provide coverage for this policy
        uint256 coverAmount = _coverLimit * positionAmount / 1e4;
        require(activeCoverAmount + coverAmount <= maxCoverAmount, "max covered amount is reached");
        // check that the buyer has paid the correct premium
        uint256 premium = _getQuote(_coverLimit, _blocks, positionAmount);
        require(msg.value >= premium && premium != 0, "insufficient payment or premium is zero");
        // TODO: safe return extra
        // check that the buyer provided valid period and coverage limit
        require(_blocks >= minPeriod && _blocks <= maxPeriod, "invalid period");
        require(_coverLimit > 0 && _coverLimit <= 1e4, "invalid cover limit percentage");

        // transfer premium to the treasury
        payable(treasury).transfer(msg.value);

        // create the policy
        uint256 expirationBlock = block.number + _blocks;
        policyID = policyManager.createPolicy(_policyholder, _positionContract, expirationBlock, coverAmount, price);

        // update local book-keeping variables
        activeCoverAmount += coverAmount;
        activePolicyIDs.push(policyID);
        productPolicyCount++;

        emit PolicyCreated(policyID);

        return policyID;
    }

    // /**
    //  * @notice
    //  *  Increase or decrease the cover limit for the policy
    //  * @param _policy address of existing policy
    //  * @param _coverLimit new cover percentage
    //  * @return True if coverlimit is successfully increased else False
    //  */
    // function updateCoverLimit(uint256 _policyID, uint256 _coverLimit) external payable override returns (bool){
    //     // check that the msg.sender is the policyholder
    //     address policyholder = policyManager.getPolicyholder(_policyID);
    //     require(policyholder == msg.sender,'!policyholder');
    //     // compute the extra premium = newPremium - paidPremium (or the refund amount)
    //     // group call to policy info into just policyManager.getPolicyInfo(_policyId)
    //     uint256 previousPrice = policyManager.getPolicyPrice(_policyID);
    //     uint256 expirationBlock = policyManager.getPolicyExpirationBlock(_policyID);
    //     uint256 remainingBlocks = expirationBlock - block.number;
    //     uint256 previousCoverAmount = policyManager.getPolicyCoverAmount(_policyID);
    //     uint256 paidPremium = previousCoverAmount * remainingBlocks * previousPrice;
    //     // whats new cover amount ? should we appraise again?
    //     uint256 newPremium = newCoverAmount * remainingBlocks * price;
    //     if (newPremium >= paidPremium) {
    //         uint256 premium = newPremium - paidPremium;
    //         // check that the buyer has paid the correct premium
    //         require(msg.value == premium && premium != 0, "payment does not match the quote or premium is zero");
    //         // transfer premium to the treasury
    //         payable(treasury).transfer(msg.value);
    //     } else {
    //         uint256 refund = paidPremium - newPremium;
    //         treasury.refund(msg.sender, refundAmount - cancelFee);
    //     }
    //     // update policy's URI
    //     // emit event
    // }

    /**
     * @notice
     *  Extend a policy contract
     * @param _policyID id number of the existing policy
     * @param _blocks length of extension
     */
    function extendPolicy(uint256 _policyID, uint256 _blocks) external payable override {
        // check that the msg.sender is the policyholder
        address policyholder = policyManager.getPolicyholder(_policyID);
        require(policyholder == msg.sender,'!policyholder');
        // compute the premium
        uint256 coverAmount = policyManager.getPolicyCoverAmount(_policyID);
        uint256 premium = coverAmount * _blocks * price / 1e12;
        // check that the buyer has paid the correct premium
        require(msg.value == premium && premium != 0, "payment does not match the quote or premium is zero");
        // transfer premium to the treasury
        payable(treasury).transfer(msg.value);
        // update the policy's URI
        uint256 newExpirationBlock = policyManager.getPolicyExpirationBlock(_policyID) + _blocks;
        address positionContract = policyManager.getPolicyPositionContract(_policyID);
        policyManager.setTokenURI(_policyID, policyholder, positionContract, newExpirationBlock, coverAmount, price);
        emit PolicyExtended(_policyID);
    }

    /**
     * @notice
     *  Cancel and destroy a policy.
     * @param _policyID id number of the existing policy
     */
    function cancelPolicy(uint256 _policyID) external override {
        require(policyManager.getPolicyholder(_policyID) == msg.sender,'!policyholder');
        uint256 blocksLeft = policyManager.getPolicyExpirationBlock(_policyID) - block.number;
        uint256 refundAmount = blocksLeft * policyManager.getPolicyPrice(_policyID);
        require(refundAmount > cancelFee, 'refund amount less than cancelation fee');
        policyManager.burn(_policyID);
        treasury.refund(msg.sender, refundAmount - cancelFee);
        emit PolicyCanceled(_policyID);
    }
}


// File contracts/products/CompoundProduct.sol


pragma solidity 0.8.0;


interface IComptroller {
    //function markets(address market) external view returns (bool isListed, uint256 collateralFactorMantissa, bool isComped); // mainnet
    function markets(address market) external view returns (bool isListed, uint256 collateralFactorMantissa); // rinkeby
}

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function symbol() external view returns (string memory);
    function underlying() external view returns (address);
}

contract CompoundProduct is BaseProduct {

    IComptroller public comptroller;
    IExchangeQuoter public quoter;

    constructor (
        IPolicyManager _policyManager,
        ITreasury _treasury,
        address _coveredPlatform,
        address _claimsAdjuster,
        uint256 _price,
        uint256 _cancelFee,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxCoverAmount,
        address _quoter
    ) BaseProduct(
        _policyManager,
        _treasury,
        _coveredPlatform,
        _claimsAdjuster,
        _price,
        _cancelFee,
        _minPeriod,
        _maxPeriod,
        _maxCoverAmount
    ) {
        comptroller = IComptroller(_coveredPlatform);
        quoter = IExchangeQuoter(_quoter);
    }

    /**
     * @notice Sets a new Comptroller.
     * Can only be called by the current governor.
     * @param _comptroller The new comptroller address.
     */
    function setComptroller(address _comptroller) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        comptroller = IComptroller(_comptroller);
    }

    /**
     * @notice Sets a new ExchangeQuoter.
     * Can only be called by the current governor.
     * @param _quoter The new quoter address.
     */
    function setExchangeQuoter(address _quoter) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        quoter = IExchangeQuoter(_quoter);
    }

    // _positionContract must be a cToken including cETH
    // see https://compound.finance/markets
    // and https://etherscan.io/accounts/label/compound
    function appraisePosition(address _policyholder, address _positionContract) public view override returns (uint256 positionAmount) {
        // verify _positionContract
        //(bool isListed, , ) = comptroller.markets(_positionContract); // mainnet
        (bool isListed, ) = comptroller.markets(_positionContract); // rinkeby
        require(isListed, "Invalid position contract");
        // swap math
        ICToken token = ICToken(_positionContract);
        uint256 balance = token.balanceOf(_policyholder);
        // TODO: may lag behind accrueInterest() ?
        uint256 exchangeRate = token.exchangeRateStored();
        balance = balance * exchangeRate / 1e18;
        if(compareStrings(token.symbol(), "cETH")) return balance;
        return quoter.tokenToEth(token.underlying(), balance);
    }

    /**
     * @notice String equality.
     * @param a The first string.
     * @param b The second string.
     * @return True if equal.
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}