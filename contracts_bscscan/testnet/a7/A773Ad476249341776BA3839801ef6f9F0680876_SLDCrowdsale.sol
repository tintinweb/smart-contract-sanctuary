pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with BNB. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    fallback () external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() virtual public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) virtual public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) virtual internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) virtual internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) virtual internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) virtual internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which BNB is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) virtual internal view returns (uint256) {
        return weiAmount.mul(rate());
    }

    /**
     * @dev Determines how BNB is stored/forwarded on purchases.
     */
    function _forwardFunds() virtual internal {
        _wallet.transfer(msg.value);
    }
}

/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
abstract contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _tokenWallet;

    /**
     * @dev Constructor, takes token wallet address.
     * @param tokenWallet Address holding the tokens, which has approved allowance to the crowdsale.
     */
    constructor (address tokenWallet) {
        require(tokenWallet != address(0), "AllowanceCrowdsale: token wallet is the zero address");
        _tokenWallet = tokenWallet;
    }

    /**
     * @return the address of the wallet that will hold the tokens.
     */
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    /**
     * @dev Checks the amount of tokens left in the allowance.
     * @return Amount of tokens left in the allowance
     */
    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

    /**
     * @dev Overrides parent behavior by transferring tokens from wallet.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) override virtual internal {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }
}

/**
 * @title ParticipantEnumerable
 * @dev Extension for mapping accounts to participants .
 */
contract ParticipantEnumerable {
    // Mapping from account to the list of participants
    mapping(address => address[]) private _participants;

    // Mapping from participant to index of the account participants list
    mapping(address => uint256) private _participantsIndex;

    // Array with all participants, used for enumeration
    address[] private _allParticipants;

    // Mapping from participant to position in the allParticipants array
    mapping(address => uint256) private _allParticipantsIndex;

    // Mapping from account to parent participant
    mapping(address => address) private _parent;

    /**
     * @dev Getter the address of parent participant.
     */
    function parent(address account) public view returns (address) {
        return _parent[account];
    }

    /**
     * @dev Gets the participant at a given index of the participants list of the requested account.
     * @param account address the participants list
     * @param index uint256 representing the index of requested participants list
     * @return participant address at the given index of the participants list of requested address
     */
    function ParticipantOfAccountByIndex(address account, uint256 index) public view returns (address) {
        require(index < _participants[account].length, "ERC721Enumerable: account index out of bounds");
        return _participants[account][index];
    }

    /**
     * @dev Gets the total amount of participants stored by the contract.
     * @return uint256 representing the total amount of participants
     */
    function totalParticipant() public view returns (uint256) {
        return _allParticipants.length;
    }

    /**
     * @dev Gets the participant at a given index of all the participants in this contract
     * Reverts if the index is greater or equal to the total number of participants.
     * @param index uint256 representing the index of the participants list
     * @return participant address at the given index of the participants list
     */
    function participantByIndex(uint256 index) public view returns (address) {
        require(index < totalParticipant(), "ERC721Enumerable: global index out of bounds");
        return _allParticipants[index];
    }

    /**
     * @dev Gets the list of participants of the requested account.
     * @param account address of participant
     * @return address[] List of children of the requested account.
     */
    function participantsOfAccount(address account) public view returns (address[] memory) {
        return _participants[account];
    }

    /**
     * @dev Private function to add a participant to this extension's ownership-tracking data structures.
     * @param to address representing the new account of the given participant
     * @param participant address of the participant to be added to the participants list of the given address
     */
    function _addParticipant(address to, address participant) internal {
        _addParticipantToAccountEnumeration(to, participant);
        _addParticipantToAllParticipantsEnumeration(participant);
    }

    /**
     * @dev Private function to add a participant to this extension's ownership-tracking data structures.
     * @param to address representing the new account of the given participant
     * @param participant address of the participant to be added to the participants list of the given address
     */
    function _addParticipantToAccountEnumeration(address to, address participant) private {
        _participantsIndex[participant] = _participants[to].length;
        _participants[to].push(participant);
        _parent[participant] = to;
    }

    /**
     * @dev Private function to add a participant to this extension's participant tracking data structures.
     * @param participant address of the participant to be added to the participants list
     */
    function _addParticipantToAllParticipantsEnumeration(address participant) private {
        _allParticipantsIndex[participant] = _allParticipants.length;
        _allParticipants.push(participant);
    }

}

/**
 * @title Airdrop
 * @dev Airdrop is a base contract for managing claim tokens,
 */
contract Airdrop is Context, ParticipantEnumerable {
    using SafeMath for uint256;

    uint256 private _airdropFee;
    mapping(address => uint256) private _airdropReferralCommission;
    mapping(address => bool) private _airdropClaimed;

    // Amount of wei raised for Airdrop
    uint256 private _airdropWeiRaised;
    
     /**
     * Event for token airdrop logging
     * @param claimer who paid for the tokens
     * @param referrer who refer for airdrop
     * @param value weis paid for claim
     * @param amount amount of tokens claimed
     */
    event AirdropClaimed(address indexed claimer, address indexed referrer, uint256 value, uint256 amount);

    constructor(uint256 airdropFee)public
    {
        _airdropFee = airdropFee;
    }

    /**
     * @return the amount of airdrop fee.
     */
    function airdropFee() public view returns (uint256) {
        return _airdropFee;
    }

    /**
     * @param referrer for token claim
     * @return token amount of referrals commission to be claimed with the referrer address.
     */
    function airdropReferralCommission(address referrer) public view returns (uint256) {
        return _airdropReferralCommission[referrer];
    }

    /**
     * @param beneficiary Token claimed account
     * @return the address claimed token state.
     */
    function airdropClaimed(address beneficiary) public view returns (bool) {
        return _airdropClaimed[beneficiary];
    }

    /**
     * @return the amount of wei raised for airdrop.
     */
    function airdropWeiRaised() public view returns (uint256) {
        return _airdropWeiRaised;
    }

    /**
     * @return the amount of airdrop tokens.
     */
    function airdropAmount() virtual public view returns (uint256) {
        return 1;
    }

     /**
     * @dev Return airdrop info for wallet.
     * @param wallet for status of airdrop
     */
    function info(address wallet) public view returns (uint256 commission, bool claimed) {
        commission = airdropReferralCommission(wallet);
        claimed = airdropClaimed(wallet);
    }

    /**
     * @dev This function to claim via referral account
     * @param referrer Refer claimer to claim token
     */
    function claimTokens(address referrer) public payable{
        uint256 weiAmount = msg.value;
        _preValidateAirdrop(_msgSender(), referrer, weiAmount);

        // update state
        _airdropWeiRaised = _airdropWeiRaised.add(weiAmount);

        _processAirdrop(_msgSender(), referrer, airdropAmount());
        emit AirdropClaimed(_msgSender(), referrer, weiAmount, airdropAmount());

        _airdropClaimed[_msgSender()] = true;     
        
        _forwardAirdropFunds();

    }
    
    /**
     * @dev Validation of an incoming claim. Use require statements to revert state when conditions are not met.
     * @param beneficiary Address performing the token claim
     * @param referrer Refer claimer to claim token
     * @param weiAmount Value in wei involved in the claim
     */
    function _preValidateAirdrop(address beneficiary, address referrer, uint256 weiAmount) virtual internal view {
        require(weiAmount >= _airdropFee, 'Airdrop fee not Paid!');
        require(_airdropClaimed[beneficiary] == false, 'Airdrop already claimed!');
        require(referrer != address(0), 'Airdrop already claimed!');
        this;
    }

    /**
     * @dev Executed when a claim has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param referrer Refer claimer to claim token
     * @param tokenAmount Number of tokens to be claimed
     */
    function _processAirdrop(address beneficiary, address referrer, uint256 tokenAmount) virtual internal {

    }

    /**
     * @dev Determines how BNB is stored/forwarded on airdrop.
     */
    function _forwardAirdropFunds() internal virtual {
        
    }
}

/**
 * @title SLDCrowdSale
 * @dev The SLDCrowdSale enables airdrop and purchasing of SLD token.
 */
contract SLDCrowdsale is AllowanceCrowdsale, Airdrop {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Maximum sales amount of SoldiersToken
    uint256 private _maxSale;
    
    // Amount of SoldiersToken sold
    uint256 private _totalSold;

    uint256[] private _percentage = [1200, 500, 300, 250, 200, 150, 100, 75, 50, 25];

    // Mapping from account to amount of participant
    mapping(address => uint256) private _participantAmount;

    /**
     * Event for change rate after token purchased
     * @param newRate value of new calculated rate
     */
    event UpdateRate(uint256 newRate);

    /**
     * @dev Constructor, calls the inherited classes constructors
     * @param rate Number of token units a buyer gets per wei
     * @param fundWallet Address that will receive the deposited BNB
     * @param soldierLandToken The soldierLandToken address, must be an ERC20 contract
     * @param soldierLandTokensOwner Address holding the tokens, which has approved allowance to the crowdsale
     * @param maxSale Maximum sales amount of SoldiersToken
     * @param airdropFee amount of BNB for claim airdrop
     */
    constructor(uint256 rate, address payable fundWallet, IERC20 soldierLandToken, address soldierLandTokensOwner, uint256 maxSale, uint256 airdropFee)
        Crowdsale(rate, fundWallet, soldierLandToken)
        AllowanceCrowdsale(soldierLandTokensOwner)
        Airdrop(airdropFee)
        public
    {
        _maxSale = maxSale;
        _addParticipant(address(0), _msgSender());
        _addParticipant(_msgSender(), fundWallet);
        _updatePurchasingState(fundWallet, 1);
    }

    /**
     * @return maximum sales amount of SoldiersToken
     */
    function maxSale() public view returns (uint256) {
        return _maxSale;
    }

    /**
     * @return the amount of SoldiersToken sold
     */
    function totalSold() public view returns (uint256) {
        return _totalSold;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public override view returns (uint256) {
        return super.rate().mul(totalSold().add(maxSale()).mul(100).div(maxSale())).div(100);
    }

    /**
     * @dev the amount of participant by an account.
     */
    function participantAmount(address account) public view returns (uint256) {
        return _participantAmount[account];
    }

    /**
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public override payable {
        buyTokensWithRefer(beneficiary, wallet());
    }

     /**
     * @dev This function to purchase via reffral account
     * @param beneficiary Recipient of the token purchase
     * @param referrer Refer purchaser to purchase token
     */
    function buyTokensWithRefer(address beneficiary, address referrer) public payable {
        require(referrer != beneficiary, "Beneficiary participant can't referrer to self");
        require(parent(referrer) != address(0), "Referrer participant not exist!");
        require(participantAmount(referrer) > 0, "Referer must be participant befor!");
        require(parent(beneficiary) == address(0) || parent(beneficiary) == referrer, "Invalid referrer participant");

        super.buyTokens(beneficiary);
        if (parent(beneficiary) == address(0)){
            _addParticipant(referrer, beneficiary);
        }
        _forwardFunds(referrer);
        emit UpdateRate(rate());
    }

    /**
     * @dev Overrides function in the Crowdsale contract to revert contributions less than
     *      50 TRX during the first period and less than 500 trx during the rest of the crowdsale
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in sun involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override view {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(weiAmount >= 1 * 1e17, "Contributions must be at least 0.1 BNB during the crowdsale");
        require(_totalSold < _maxSale, "Limit token sale");
    }

    /**
     * @dev Overrides function in the Crowdsale contract to enable a custom phased distribution
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) override internal view returns (uint256) {
        uint256 amount = weiAmount.mul(rate());
        if (amount >= 2000000 * 1e18) {
            return amount.mul(122).div(100);
        } else if (amount >= 700000 * 1e18) {
            return amount.mul(116).div(100);
        } else if (amount >= 250000 * 1e18) {
            return amount.mul(111).div(100);
        } else if (amount >= 100000 * 1e18) {
            return amount.mul(107).div(100);
        } else if (amount >= 40000 * 1e18) {
            return amount.mul(104).div(100);
        } else {
            return amount;
        }
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal override {
        _deliverTokens(beneficiary, tokenAmount);
        _totalSold = _totalSold.add(tokenAmount);
        _deliverTokens(wallet(), tokenAmount.mul(5).div(95));
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in sun involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal override {
        _participantAmount[beneficiary] = _participantAmount[beneficiary].add(weiAmount);
    }

    /**
     * @dev Determines how BNB is stored/forwarded on purchases.
     */
    function _forwardFunds() internal override {
        
    }

    /**
     * @dev Determines how TRX is stored/forwarded on purchases.
     * @param referrer Refer purchaser to purchase token
     */
    function _forwardFunds(address referrer) internal {
        uint256 amount = msg.value;
        uint256 relased = 0;
        uint256 levelNo = 0;
        uint256 value = 0;
        address payable ParticipantWallet = payable(referrer);

        while(ParticipantWallet != address(0) && levelNo < 10){
            value = amount.mul(_percentage[levelNo]).div(10000);
            relased = relased.add(value);
            ParticipantWallet.transfer(value);
            ParticipantWallet = payable(parent(ParticipantWallet));
            levelNo = levelNo.add(1);
        }

        amount = amount.sub(relased);
        wallet().transfer(amount);
    }

    /**
     * @return the amount of airdrop tokens.
     */
    function airdropAmount() public override view returns (uint256) {
        return airdropFee().mul(rate()).mul(120).div(100);
    }

    /**
     * @dev Validation of an incoming claim. Use require statements to revert state when conditions are not met.
     * @param beneficiary Address performing the token claim
     * @param referrer Refer claimer to claim token
     * @param weiAmount Value in wei involved in the claim
     */
    function _preValidateAirdrop(address beneficiary, address referrer, uint256 weiAmount) override internal view {
        require(participantAmount(referrer) > 0, "Referer must be participant befor!");
        super._preValidateAirdrop(beneficiary, referrer, weiAmount);
    }

    /**
     * @dev Executed when a claim has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param referrer Refer claimer to claim token
     * @param tokenAmount Number of tokens to be claimed
     */
    function _processAirdrop(address beneficiary, address referrer, uint256 tokenAmount) internal override{
        _deliverTokens(beneficiary, tokenAmount);
        if (parent(beneficiary) == address(0) && referrer != beneficiary){
            _addParticipant(referrer, beneficiary);
        }
        if (parent(beneficiary) != address(0)){
            _deliverTokens(parent(beneficiary), tokenAmount.mul(10).div(100));
        }
    }

    /**
     * @dev Determines how TRX is stored/forwarded on purchases.
     */
    function _forwardAirdropFunds() internal override {
        wallet().transfer(msg.value);
    }
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

