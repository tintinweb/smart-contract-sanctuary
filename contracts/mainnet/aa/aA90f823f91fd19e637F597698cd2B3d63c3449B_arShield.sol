/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/IOracle.sol

pragma solidity 0.8.4;

interface IOracle {
    function getTokensOwed(uint256 ethOwed, address pToken, address uTokenLink) external view returns (uint256);
    function getEthOwed(uint256 tokensOwed, address pToken, address uTokenLink) external view returns (uint256);
}


// File contracts/interfaces/ICovBase.sol

pragma solidity 0.8.4;

interface ICovBase {
    function editShield(address shield, bool active) external;
    function updateShield(uint256 ethValue) external payable;
    function checkCoverage(uint256 pAmount) external view returns (bool);
    function getShieldOwed(address shield) external view returns (uint256);
}


// File contracts/interfaces/IController.sol

pragma solidity 0.8.4;

interface IController {
    function bonus() external view returns (uint256);
    function refFee() external view returns (uint256);
    function governor() external view returns (address);
    function depositAmt() external view returns (uint256);
    function beneficiary() external view returns (address payable);
}


// File contracts/interfaces/IArmorToken.sol

pragma solidity 0.8.4;

interface IArmorToken {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    // Putting in for now to replicate the compound-like token function where I can find balance at a certain block.
    function balanceOfAt(address account, uint256 blockNo) external view returns (uint256);

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/core/arShield.sol

// SPDX-License-Identifier: (c) Armor.Fi, 2021

pragma solidity 0.8.4;

/**
 * @title Armor Shield
 * @dev arShield base provides the base functionality of arShield contracts.
 * @author Armor.fi -- Robert M.C. Forster
**/
contract arShield {

    /**
     * @dev Universal requirements:
     *      - notLocked functions must never be able to be accessed if locked.
     *      - onlyGov functions must only ever be able to be accessed by governance.
     *      - Total of refBals must always equal refTotal.
     *      - depositor should always be address(0) if contract is not locked.
     *      - totalTokens must always equal pToken.balanceOf( address(this) ) - (refTotal + sum(feesToLiq) ).
    **/

    // Denominator for % fractions.
    uint256 constant DENOMINATOR = 10000;
    
    // Whether or not the pool has capped coverage.
    bool public capped;
    // Whether or not the contract is locked.
    bool public locked;
    // Limit of tokens (in Wei) that can be entered into the shield.
    uint256 public limit;
    // Address that will receive default referral fees and excess eth/tokens.
    address payable public beneficiary;
    // User who deposited to notify of a hack.
    address public depositor;
    // Amount to payout in Ether per token for the most recent hack.
    uint256 public payoutAmt;
    // Block at which users must be holding tokens to receive a payout.
    uint256 public payoutBlock;
    // Total amount to be paid to referrers.
    uint256 public refTotal;
    // 0.25% paid for minting in order to pay for the first week of coverage--can be immediately liquidated.
    uint256[] public feesToLiq;
    // Different amounts to charge as a fee for each protocol.
    uint256[] public feePerBase;
    // Total tokens to protect in the vault (tokens - fees).
    uint256 public totalTokens;

    // Balance of referrers.
    mapping (address => uint256) public refBals;
   // Whether user has been paid for a specific payout block.
    mapping (uint256 => mapping (address => uint256)) public paid;

    // Chainlink address for the underlying token.
    address public uTokenLink;
    // Protocol token that we're providing protection for.
    IERC20 public pToken;
    // Oracle to find uToken price.
    IOracle public oracle;
    // The armorToken that this shield issues.
    IArmorToken public arToken;
    // Coverage bases that we need to be paying.
    ICovBase[] public covBases;
    // Used for universal variables (all shields) such as bonus for liquidation.
    IController public controller;

    event Unlocked(uint256 timestamp);
    event Locked(address reporter, uint256 timestamp);
    event HackConfirmed(uint256 payoutBlock, uint256 timestamp);
    event Mint(address indexed user, uint256 amount, uint256 timestamp);
    event Redemption(address indexed user, uint256 amount, uint256 timestamp);

    modifier onlyGov 
    {
        require(msg.sender == controller.governor(), "Only governance may call this function.");
        _;
    }

    modifier isLocked 
    {
        require(locked, "You may not do this while the contract is unlocked.");
        _;
    }

    // Only allow minting when there are no claims processing (people withdrawing to receive Ether).
    modifier notLocked 
    {
        require(!locked, "You may not do this while the contract is locked.");
        _;
    }

    // Used for initial soft launch to limit the amount of funds in the shield. 0 if unlimited.
    modifier withinLimits
    {
        _;
        uint256 _limit = limit;
        require(_limit == 0 || pToken.balanceOf( address(this) ) <= _limit, "Too much value in the shield.");
    }
    
    receive() external payable {}
    
    /**
     * @notice Controller immediately initializes contract with this.
     * @dev - Must set all included variables properly.
     *      - Must set covBases and fees in correct order.
     *      - Must not allow improper lengths.
     * @param _oracle Address of our oracle for this family of tokens.
     * @param _pToken The protocol token we're protecting.
     * @param _arToken The Armor token that the vault controls.
     * @param _uTokenLink ChainLink contract for the underlying token.
     * @param _fees Mint/redeem fees for each coverage base.
     * @param _covBases Addresses of the coverage bases to pay for coverage.
    **/
    function initialize(
        address _oracle,
        address _pToken,
        address _arToken,
        address _uTokenLink, 
        uint256[] calldata _fees,
        address[] calldata _covBases
    )
      external
    {
        require(address(arToken) == address(0), "Contract already initialized.");

        uTokenLink = _uTokenLink;
        pToken = IERC20(_pToken);
        oracle = IOracle(_oracle);
        arToken = IArmorToken(_arToken);
        controller = IController(msg.sender);
        beneficiary = controller.beneficiary();

        // CovBases and fees must always be the same length.
        require(_covBases.length == _fees.length, "Improper length array.");
        for(uint256 i = 0; i < _covBases.length; i++) {
            covBases.push( ICovBase(_covBases[i]) );
            feePerBase.push(_fees[i]);
            feesToLiq.push(0);
        }
    }

    /**
     * @notice User deposits pToken, is returned arToken. Amount returned is judged based off amount in contract.
     *         Amount returned will likely be more than deposited because pTokens will be removed to pay for cover.
     * @dev - Must increase referrer bal 0.25% (in tests) if there is a referrer, beneficiary bal if not.
     *      - Important: must mint correct value of tokens in all scenarios. Conversion from pToken to arToken - (referral fee - feePerBase amounts - liquidator bonus).
     *      - Must take exactly _pAmount from user and deposit to this address.
     *      - Important: must save all fees correctly.
     * @param _pAmount Amount of pTokens to deposit to the contract.
     * @param _referrer The address that referred the user to arShield.
    **/
    function mint(
        uint256 _pAmount,
        address _referrer
    )
      external
      notLocked
      withinLimits
    {
        address user = msg.sender;

        // fee is total including refFee
        (
         uint256 fee, 
         uint256 refFee, 
         uint256 totalFees,
         uint256[] memory newFees
        ) = _findFees(_pAmount);

        uint256 arAmount = arValue(_pAmount - fee);
        pToken.transferFrom(user, address(this), _pAmount);
        _saveFees(newFees, _referrer, refFee);

        // If this vault is capped in its coverage, we check whether the mint should be allowed, and update.
        if (capped) {
            uint256 ethValue = getEthValue(pToken.balanceOf( address(this) ) - totalFees);
            require(checkCapped(ethValue), "Not enough coverage available.");

            // If we don't update here, two shields could get big deposits at the same time and allow both when it shouldn't.
            // This update runs the risk of making CoverageBase need to pay more than it has upfront, but in that case we liquidate.
            for (uint256 i = 0; i < covBases.length; i++) covBases[i].updateShield(ethValue);
        }

        arToken.mint(user, arAmount);
        emit Mint(user, arAmount, block.timestamp);
    }

    /**
     * @notice Redeem arTokens for underlying pTokens.
     * @dev - Must increase referrer bal 0.25% (in tests) if there is a referrer, beneficiary bal if not.
     *      - Important: must return correct value of tokens in all scenarios. Conversion from arToken to pToken - (referral fee - feePerBase amounts - liquidator bonus).
     *      - Must take exactly _arAmount from user and deposit to this address.
     *      - Important: must save all fees correctly.
     * @param _arAmount Amount of arTokens to redeem.
     * @param _referrer The address that referred the user to arShield.
    **/
    function redeem(
        uint256 _arAmount,
        address _referrer
    )
      external
    {
        address user = msg.sender;
        uint256 pAmount = pValue(_arAmount);
        arToken.transferFrom(user, address(this), _arAmount);
        arToken.burn(_arAmount);
        
        (
         uint256 fee, 
         uint256 refFee,
         uint256 totalFees,
         uint256[] memory newFees
        ) = _findFees(pAmount);

        pToken.transfer(user, pAmount - fee);
        _saveFees(newFees, _referrer, refFee);

        // If we don't update this here, users will get stuck paying for coverage that they are not using.
        uint256 ethValue = getEthValue(pToken.balanceOf( address(this) ) - totalFees);
        for (uint256 i = 0; i < covBases.length; i++) covBases[i].updateShield(ethValue);

        emit Redemption(user, _arAmount, block.timestamp);
    }

    /**
     * @notice Liquidate for payment for coverage by selling to people at oracle price.
     * @dev - Must give correct amount of tokens.
     *      - Must take correct amount of Ether back.
     *      - Must adjust fees correctly afterwards.
     *      - Must not allow any extra to be sold than what's needed.
     * @param _covId covBase ID that we are liquidating.
    **/
    function liquidate(
        uint256 _covId
    )
      external
      payable
    {
        // Get full amounts for liquidation here.
        (
         uint256 ethOwed, 
         uint256 tokensOwed,
         uint256 tokenFees
        ) = liqAmts(_covId);
        require(msg.value <= ethOwed, "Too much Ether paid.");

        // Determine eth value and amount of tokens to pay?
        (
         uint256 tokensOut,
         uint256 feesPaid,
         uint256 ethValue
        ) = payAmts(
            msg.value,
            ethOwed,
            tokensOwed,
            tokenFees
        );

        covBases[_covId].updateShield{value:msg.value}(ethValue);
        feesToLiq[_covId] -= feesPaid;
        pToken.transfer(msg.sender, tokensOut);
    }

    /**
     * @notice Claim funds if you were holding tokens on the payout block.
     * @dev - Must return correct amount of funds to user according to their balance at the time.
     *      - Must subtract if paid mapping has value.
     *      - Must correctly set paid.
     *      - Must only ever work for users who held tokens at exactly payout block.
    **/
    function claim()
      external
      isLocked
    {
        // Find balance at the payout block, multiply by the amount per token to pay, subtract anything paid.
        uint256 balance = arToken.balanceOfAt(msg.sender, payoutBlock);
        uint256 owedBal = balance - paid[payoutBlock][msg.sender];
        uint256 amount = payoutAmt
                         * owedBal
                         / 1 ether;

        require(balance > 0 && amount > 0, "Sender did not have funds on payout block.");
        paid[payoutBlock][msg.sender] += owedBal;
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Used by referrers to withdraw their owed balance.
     * @dev - Must allow user to withdraw correct referral balance from the contract.
     *      - Must allow no extra than referral balance to be withdrawn.
    **/
    function withdraw(
        address _user
    )
      external
    {
        uint256 balance = refBals[_user];
        refBals[_user] = 0;
        pToken.transfer(_user, balance);
    }

    /**
     * @notice Inverse of arValue (find yToken value of arToken amount).
     * @dev - Must convert correctly in any scenario.
     * @param _arAmount Amount of arTokens to find yToken value of.
     * @return pAmount Amount of pTokens the input arTokens are worth.
    **/
    function pValue(
        uint256 _arAmount
    )
      public
      view
    returns (
        uint256 pAmount
    )
    {
        uint256 totalSupply = arToken.totalSupply();
        if (totalSupply == 0) return _arAmount;

        pAmount = ( pToken.balanceOf( address(this) ) - totalFeeAmts() )
                  * _arAmount 
                  / totalSupply;
    }

    /**
     * @notice Find the arToken value of a pToken amount.
     * @dev - Must convert correctly in any scenario.
     * @param _pAmount Amount of yTokens to find arToken value of.
     * @return arAmount Amount of arToken the input pTokens are worth.
    **/
    function arValue(
        uint256 _pAmount
    )
      public
      view
    returns (
        uint256 arAmount
    )
    {
        uint256 balance = pToken.balanceOf( address(this) );
        if (balance == 0) return _pAmount;

        arAmount = arToken.totalSupply()
                   * _pAmount 
                   / ( balance - totalFeeAmts() );
    }

    /**
     * @notice Amounts owed to be liquidated.
     * @dev - Must always return correct amounts that can currently be liquidated.
     * @param _covId Coverage Base ID lol
     * @return ethOwed Amount of Ether owed to coverage base.
     * @return tokensOwed Amount of tokens owed to liquidator for that Ether.
     * @return tokenFees Amount of tokens owed to liquidator for that Ether.
    **/
    function liqAmts(
        uint256 _covId
    )
      public
      view
    returns(
        uint256 ethOwed,
        uint256 tokensOwed,
        uint256 tokenFees
    )
    {
        // Find amount owed in Ether, find amount owed in protocol tokens.
        // If nothing is owed to coverage base, don't use getTokensOwed.
        ethOwed = covBases[_covId].getShieldOwed( address(this) );
        if (ethOwed > 0) tokensOwed = oracle.getTokensOwed(ethOwed, address(pToken), uTokenLink);

        tokenFees = feesToLiq[_covId];
        require(tokensOwed + tokenFees > 0, "No fees are owed.");

        // Find the Ether value of the mint fees we have.
        uint256 ethFees = ethOwed > 0 ?
                            ethOwed
                            * tokenFees
                            / tokensOwed
                          : getEthValue(tokenFees);
        ethOwed += ethFees;
        tokensOwed += tokenFees;

        // Add a bonus for liquidators (0% to start).
        // As it stands, this will lead to a small loss of arToken:pToken conversion immediately so in bigger
        // amounts it could be taken advantage of, but we do not think real damage can happen given the small amounts.
        uint256 liqBonus = tokensOwed 
                           * controller.bonus()
                           / DENOMINATOR;
        tokensOwed += liqBonus;
    }

    /**
     * @notice Find amount to pay a liquidator--needed because a liquidator may not pay all Ether.
     * @dev - Must always return correct amounts to be paid according to liqAmts and Ether in.
    **/
    function payAmts(
        uint256 _ethIn,
        uint256 _ethOwed,
        uint256 _tokensOwed,
        uint256 _tokenFees
    )
      public
      view
    returns(
        uint256 tokensOut,
        uint256 feesPaid,
        uint256 ethValue
    )
    {
        // Actual amount we're liquidating (liquidator may not pay full Ether owed).
        tokensOut = _ethIn
                    * _tokensOwed
                    / _ethOwed;

        // Amount of fees for this protocol being paid.
        feesPaid = _ethIn
                   * _tokenFees
                   / _ethOwed;

        // Ether value of all of the contract minus what we're liquidating.
        ethValue = (pToken.balanceOf( address(this) ) 
                    - totalFeeAmts())
                   * _ethOwed
                   / _tokensOwed;
    }

    /**
     * @notice Find total amount of tokens that are not to be covered (ref fees, tokens to liq, liquidator bonus).
     * @dev - Must always return correct total fees owed.
     * @return totalOwed Total amount of tokens owed in fees.
    **/
    function totalFeeAmts()
      public
      view
    returns(
        uint256 totalOwed
    )
    {
        for (uint256 i = 0; i < covBases.length; i++) {
            uint256 ethOwed = covBases[i].getShieldOwed( address(this) );
            if (ethOwed > 0) totalOwed += oracle.getTokensOwed(ethOwed, address(pToken), uTokenLink);
            totalOwed += feesToLiq[i];
        }

        // Add a bonus for liquidators (0.5% to start). Removed for now.
        /**uint256 liqBonus = totalOwed 
                           * controller.bonus()
                           / DENOMINATOR;

        totalOwed += liqBonus;**/
        totalOwed += refTotal;
    }

    /**
     * @notice If the shield requires full coverage, check coverage base to see if it is available.
     * @dev - Must return false if any of the covBases do not have coverage available.
     * @param _ethValue Ether value of the new tokens.
     * @return allowed True if the deposit is allowed.
    **/
    function checkCapped(
        uint256 _ethValue
    )
      public
      view
    returns(
        bool allowed
    )
    {
        if (capped) {
            for(uint256 i = 0; i < covBases.length; i++) {
                if( !covBases[i].checkCoverage(_ethValue) ) return false;
            }
        }
        allowed = true;
    }

    /**
     * @notice Find the Ether value of a certain amount of pTokens.
     * @dev - Must return correct Ether value for _pAmount.
     * @param _pAmount The amount of pTokens to find Ether value for.
     * @return ethValue Ether value of the pTokens (in Wei).
    **/
    function getEthValue(
        uint256 _pAmount
    )
      public
      view
    returns(
        uint256 ethValue
    )
    {
        ethValue = oracle.getEthOwed(_pAmount, address(pToken), uTokenLink);
    }

    /**
     * @notice Allows frontend to find the percents that are taken from mint/redeem. 10 == 0.1%.
    **/
    function findFeePct()
      external
      view
    returns(
        uint256 percent
    )
    {
        // Find protocol fees for each coverage base.
        uint256 end = feePerBase.length;
        for (uint256 i = 0; i < end; i++) percent += feePerBase[i];
        percent += controller.refFee() 
                   * percent
                   / DENOMINATOR;
    }

    /**
     * @notice Find the fee for deposit and withdrawal.
     * @param _pAmount The amount of pTokens to find the fee of.
     * @return userFee coverage + mint fees + liquidator bonus + referral fee.
     * @return refFee Referral fee.
     * @return totalFees Total fees owed from the contract including referrals (used to calculate amount to cover).
     * @return newFees New fees to save in feesToLiq.
    **/
    function _findFees(
        uint256 _pAmount
    )
      internal
      view
    returns(
        uint256 userFee,
        uint256 refFee,
        uint256 totalFees,
        uint256[] memory newFees
    )
    {
        // Find protocol fees for each coverage base.
        newFees = feesToLiq;
        for (uint256 i = 0; i < newFees.length; i++) {
            totalFees += newFees[i];
            uint256 fee = _pAmount
                          * feePerBase[i]
                          / DENOMINATOR;
            newFees[i] += fee;
            userFee += fee;
        }

        // Add referral fee.
        refFee = userFee 
                 * controller.refFee() 
                 / DENOMINATOR;
        userFee += refFee;

        // Add liquidator bonus.
        /**uint256 liqBonus = (userFee - refFee) 
                           * controller.bonus()
                           / DENOMINATOR;**/

        // userFee += liqBonus; <-- user not being charged liqBonus fee
        totalFees += userFee + refTotal/* + liqBonus*/;
    }

    /**
     * @notice Save new coverage fees and referral fees.
     * @param liqFees Fees associated with depositing to a coverage base.
     * @param _refFee Fee given to the address that referred this user.
    **/
    function _saveFees(
        uint256[] memory liqFees,
        address _referrer,
        uint256 _refFee
    )
      internal
    {
        refTotal += _refFee;
        if ( _referrer != address(0) ) refBals[_referrer] += _refFee;
        else refBals[beneficiary] += _refFee;
        for (uint256 i = 0; i < liqFees.length; i++) feesToLiq[i] = liqFees[i];
    }
    
    /**
     * @notice Anyone may call this to pause contract deposits for a couple days.
     * @notice They will get refunded + more when hack is confirmed.
     * @dev - Must allow any user to lock contract when a deposit is sent.
     *      - Must set variables correctly.
    **/
    function notifyHack()
      external
      payable
      notLocked
    {
        require(msg.value == controller.depositAmt(), "You must pay the deposit amount to notify a hack.");
        depositor = msg.sender;
        locked = true;
        emit Locked(msg.sender, block.timestamp);
    }
    
    /**
     * @notice Used by governor to confirm that a hack happened, which then locks the contract in anticipation of claims.
     * @dev - On success, depositor paid exactly correct deposit amount (10 Ether in tests.).
     *      - depositor == address(0).
     *      - payoutBlock and payoutAmt set correctly.
     * @param _payoutBlock Block that user must have had tokens at. Will not be the same as when the hack occurred
     *                     because we will need to give time for users to withdraw from dexes and such if needed.
     * @param _payoutAmt The amount of Ether PER TOKEN that users will be given for this claim.
    **/
    function confirmHack(
        uint256 _payoutBlock,
        uint256 _payoutAmt
    )
      external
      isLocked
      onlyGov
    {
        // low-level call to avoid push problems
        payable(depositor).call{value: controller.depositAmt()}("");
        delete depositor;
        payoutBlock = _payoutBlock;
        payoutAmt = _payoutAmt;
        emit HackConfirmed(_payoutBlock, block.timestamp);
    }
    
    /**
     * @notice Used by controller to confirm that a hack happened, which then locks the contract in anticipation of claims.
     * @dev - On success, locked == false, payoutBlock == 0, payoutAmt == 0.
    **/
    function unlock()
      external
      isLocked
      onlyGov
    {
        locked = false;
        delete payoutBlock;
        delete payoutAmt;
        emit Unlocked(block.timestamp);
    }

    /**
     * @notice Funds may be withdrawn to beneficiary if any are leftover after a hack.
     * @dev - On success, full token/Ether balance should be withdrawn to beneficiary.
     *      - Tokens/Ether should never be withdrawn anywhere other than beneficiary.
     * @param _token Address of the token to withdraw excess for. Cannot be protocol token.
    **/
    function withdrawExcess(address _token)
      external
      notLocked
    {
        if ( _token == address(0) ) beneficiary.transfer( address(this).balance );
        else if ( _token != address(pToken) ) {
            IERC20(_token).transfer( beneficiary, IERC20(_token).balanceOf( address(this) ) );
        }
    }

    /**
     * @notice Block a payout if an address minted tokens after a hack occurred.
     *      There are ways people can mess with this to make it annoying to ban people,
     *      but ideally the presence of this function alone will stop malicious minting.
     * 
     *      Although it's not a likely scenario, the reason we put amounts in here
     *      is to avoid a bad actor sending a bit to a legitimate holder and having their
     *      full balance banned from receiving a payout.
     * @dev - On success, paid[_payoutBlock][_users] for every user[i] should be incremented by _amount[i].
     * @param _payoutBlock The block at which the hack occurred.
     * @param _users List of users to ban from receiving payout.
     * @param _amounts Bad amounts (in arToken wei) that the user should not be paid.
    **/
    function banPayouts(
        uint256 _payoutBlock,
        address[] calldata _users,
        uint256[] calldata _amounts
    )
      external
      onlyGov
    {
        for (uint256 i = 0; i < _users.length; i++) paid[_payoutBlock][_users[i]] += _amounts[i];
    }

    /**
     * @notice Change the fees taken for minting and redeeming.
     * @dev - On success, feePerBase == _newFees.
     *      - No success on inequal lengths.
     * @param _newFees Array for each of the new fees. 10 == 0.1% fee.
    **/
    function changeFees(
        uint256[] calldata _newFees
    )
      external
      onlyGov
    {
        require(_newFees.length == feePerBase.length, "Improper fees length.");
        for (uint256 i = 0; i < _newFees.length; i++) feePerBase[i] = _newFees[i];
    }

    /**
     * @notice Change the main beneficiary of the shield.
     * @dev - On success, contract variable beneficiary == _beneficiary.
     * @param _beneficiary New address to withdraw excess funds and get default referral fees.
    **/
    function changeBeneficiary(
        address payable _beneficiary
    )
      external
      onlyGov
    {
        beneficiary = _beneficiary;
    }

    /**
     * @notice Change whether this arShield has a cap on tokens submitted or not.
     * @dev - On success, contract variable capped == _capped.
     * @param _capped True if there should now be a cap on the vault.
    **/
    function changeCapped(
        bool _capped
    )
      external
      onlyGov
    {
        capped = _capped;
    }

    /**
     * @notice Change whether this arShield has a limit to tokens in the shield.
     * @dev - On success, contract variable limit == _limit.
     * @param _limit Limit of funds in the contract, 0 if unlimited.
    **/
    function changeLimit(
        uint256 _limit
    )
      external
      onlyGov
    {
        limit = _limit;
    }

}