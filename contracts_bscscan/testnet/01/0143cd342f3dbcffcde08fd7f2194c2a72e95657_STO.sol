pragma solidity ^0.5.0;

import "./whitelist/ITokenismWhitelist.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol"; // This is to import ERC20 Coin
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol"; // This is to unpause and transfer back ownership
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; // To Mint tokens to other investors after crowd sale

import "./token/ERC20/IERC1400RawERC20.sol"; // This is to use transfer function

import "./crowdsale/Crowdsale.sol"; // This is import Crowd Sale
import "./crowdsale/emission/MintedCrowdsale.sol"; // Instead of sending tokens from admin wallet mint them and create new tokens
import "./crowdsale/validation/CappedCrowdsale.sol"; // Maxium amount of TKUSD that can be raised
import "./crowdsale/validation/TimedCrowdsale.sol"; // Timed Crowd Sale Start and End Date
import "./crowdsale/validation/WhitelistCrowdsale.sol"; // Replace this with your own whitelist
import "./crowdsale/distribution/PostGoalCrowdsale.sol"; // Should pay funds after goal is achived
import "./crowdsale/distribution/RefundableCrowdsale.sol"; // To refund payment if goal never achives
contract STO is
    Crowdsale,
    MintedCrowdsale,
    CappedCrowdsale,
    TimedCrowdsale,
    WhitelistCrowdsale,
    RefundableCrowdsale,
    PostGoalCrowdsale
{
    // address payable public admin;

    // Track investor contributions
    uint256 public investorMinCap = 1000000000000000000000; // Min 10000 TKUSD Tokens
    // uint256 public investorMinCap = 1000000000000000000000; // Min 10000 TKUSD Tokens
    mapping(address => uint256) public contributions;

    // Crowdsale Stages
    enum CrowdsaleStage {PreICO, ICO}
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;

    uint256 public goalPercent;
    uint256 public propertyValue;

    address public contributionAddress; // testcase
    // Tokenism Whitelist
    ITokenismWhitelist whitelist;
    // IERC20 public tokenAdd;
    IERC1400RawERC20 public tokens;

    // Token reserve funds
    address public ownerWallet;
    bool erc1400Capset;

    constructor(
        uint256 _rate,
        address payable _wallet, // Property Owner Wallet
        IERC1400RawERC20 _token, // Property Token
        IERC20 _stableCoin, // Stable Coin
        ITokenismWhitelist _whitelist, // Whitelist Contract
        uint256 _propertyValue,
        uint256 _cap,
        uint256 _goal,
        uint256 _openingTime,
        uint256 _closingTime,
        address _ownerWallet
    )
        public
        Crowdsale(_rate, _wallet, _token, _stableCoin, _whitelist)
        CappedCrowdsale(_cap)
        WhitelistCrowdsale(_whitelist)
        TimedCrowdsale(_openingTime, _closingTime)
        RefundableCrowdsale(_goal)
    {
        require(
            _whitelist.isManager(_msgSender()) ||
                _whitelist.isAdmin(msg.sender),
            "Only deployed by admin Or manager of Tokenism"
        );
        require(
            _propertyValue.mod(_rate) == 0,
            "Property value must be divisble by Rate"
        );
        require(_goal <= _cap, "Goal cannot be greater than Cap");

        // admin = _msgSender();

        goalPercent = _goal;
        ownerWallet = _ownerWallet;
        propertyValue = _propertyValue;
        tokens = _token;
        // uint256 capSet = super.getCap();
        if (!erc1400Capset) {
            _token.cap(_propertyValue); // Set Cap to ERC1400Raw for setting Investor cap percentage
            erc1400Capset = true;
        }
        whitelist = _whitelist;
    }

    modifier onlyAdmin() {
        require(whitelist.isAdmin(msg.sender), "Only admin is allowed");
        _;
    }

    modifier onlyWallet() {
        require(_msgSender() == wallet(), "Only property admin is allowed");
        _;
    }

    /**
     * @dev Returns the amount contributed so far by a sepecific user.
     * @param _beneficiary Address of contributor
     * @return User contribution so far
     */
    function getUserContribution(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return contributions[_beneficiary];
    }

    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.div(_rate);
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _targetTokens
    ) internal view {
        require(
            _weiAmount >= investorMinCap,
            "Investment is less than Minimum Invest Limit"
        );

        require(
            (_weiAmount - (_rate.mul(_targetTokens))).mod(_rate) == 0,
            "Invest amount must be multiple of _rate"
        );
        // Add require for basic Cap of Investor
        if (
            (getUserContribution(_beneficiary).add(_weiAmount) ).div(1 ether) >
            basicCap()
        ) {
            //  string memory userType = whitelist.userType(msg.sender);
            require(
                // whitelist.userType(msg.sender),
                whitelist.userType(_beneficiary),

                "You have need to Upgrade Premium Account"
            );
        }

        super._preValidatePurchase(_beneficiary, _weiAmount, _targetTokens);
    }

    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        if (stage == CrowdsaleStage.ICO)
            _deliverTokens(_beneficiary, _tokenAmount);
        else super._processPurchase(_beneficiary, _tokenAmount);
    }

    /**
     * @dev If goal is Reached then change to change to ICO Stage
     * etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
        internal
    {
        // require(1==2,"is 1==2 true");
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        contributions[_beneficiary] = _newContribution;
        contributionAddress = _beneficiary;

        if (isOpen() && goalReached() && stage == CrowdsaleStage.PreICO)
            stage = CrowdsaleStage.ICO;
        super._updatePurchasingState(_beneficiary, _weiAmount);
        // emit
    }

    /**
     * @dev Determines how TKUSD is stored/forwarded on purchases.
     * @param stableAmount Number of tokens to be purchased
     * @param investor     Investor address who sent that money
     */
    function _processTransfer(address investor, uint256 stableAmount) internal {
        if (stage == CrowdsaleStage.ICO) _forwardTokens(wallet(), stableAmount);
        else super._processTransfer(investor, stableAmount);
    }

    /**
     * @dev enables token transfers, called when admin calls finalize()
     */
    function _finalization() internal {
        if (goalReached()) {
            IERC1400RawERC20 _securityToken = IERC1400RawERC20(
                address(token())
            );

            uint256 _alreadyMinted = _securityToken.totalSupply();
            uint256 _finalTotalSupply = propertyValue.div(rate());

            _securityToken.issue(
                address(ownerWallet),
                _finalTotalSupply.sub(_alreadyMinted), // Add those tokens as well which are left other than cap
                certificate
            );
            _securityToken.transferOwnership(wallet());
            // _mintableToken.finishMinting(); // Look another way to do this
        }
        super._finalization();
    }

    function changeWhitelist(ITokenismWhitelist _whitelist)
        public
        onlyAdmin
        returns (bool)
    {
        whitelist = _whitelist;
        super.changeWhitelistingContract(_whitelist);
        return true;
    }

    function tokenAdd() public returns (address) {
        return address(Crowdsale.token());
    }

    function getBeneficiary() public view returns (address) {
        return contributionAddress;
    }

    // Destruct STO Contract Address
    function closeSTO() public {
        //onlyOwner is custom modifier
        require(
            whitelist.isSuperAdmin(_msgSender()),
            "Only SuperAdmin can destroy Contract"
        );
        selfdestruct(msg.sender); // `admin` is the admin address
    }

    // Basic Cap For User Contribution
    function basicCap() public view returns (uint256) {
        return (propertyValue.mul(20).div(100 ether));
    }

    // function increaseCap(uint256 _value) public returns(uint256){
    //      require(
    //         whitelist.isSuperAdmin(_msgSender()),
    //         "Only SuperAdmin can destroy Contract"
    //     );
    //     return super.increaseCapSuperAdmin(_value);
    // }

}

pragma solidity ^0.5.0;

import "../utils/Context.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "../token/ERC20/IERC1400RawERC20.sol"; // This is to use transfer function
import './../whitelist/ITokenismWhitelist.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
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
    using SafeERC20 for IERC1400RawERC20;

    // The Stable Coin
    IERC20 private _stableCoin;
    // address payable public admin;
    // The token being sold
    IERC1400RawERC20 public _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 internal _rate;  
    // Whitelisting Address
    ITokenismWhitelist whitelist;
    // Amount of wei raised
    uint256 internal _weiRaised;

    uint256 public amountBuy = 0;
    // uint256 public feePercent = 2; // Deployer payed for admin in TKUSD
    // address feeAddress = 0xDDD48860c1129f70b25937629b6F136C03DB9336; // Admin address for transfer TKUSD fee

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor(
        uint256 rate,
        address payable wallet,
        IERC1400RawERC20 token,
        IERC20 stableCoin,
        ITokenismWhitelist _whitelist
    ) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(
            address(token) != address(0),
            "Crowdsale: token is the zero address"
        );

        _rate = rate;
        _wallet = wallet;
        _token = IERC1400RawERC20(token);
        _stableCoin = stableCoin;
        // admin = _whitelist.admin();
        whitelist = _whitelist;
    }

   modifier onlyAdmin() {
      require(
        whitelist.isAdmin(msg.sender),
                "Only admin is allowed"
        );
         _;
     }
    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */

    /**
     * @return the token being sold.
     */
    function stableCoin() public view returns (IERC20) {
        return _stableCoin;
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC1400RawERC20) {
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
    function rate() public view returns (uint256) {
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
    function tokenFallback(
        address beneficiary,
        uint256 stableCoins,
        bytes memory _data
    ) public nonReentrant returns (bool success) {
        uint256 targetTokens = bytesToUint(_data);
        amountBuy = targetTokens;

        _preValidatePurchase(beneficiary, stableCoins, targetTokens);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(stableCoins);

        // update state
        _weiRaised = _weiRaised.add(stableCoins);

        // require(1 == 2, "Amount added in Wei");

        _processPurchase(beneficiary, tokens);
        // require(1 == 2, "Token Transfered");

        emit TokensPurchased(_msgSender(), beneficiary, stableCoins, tokens);
        // require(1 == 2, "Pre State");

        _updatePurchasingState(beneficiary, stableCoins);

        // _forwardFunds();
        _processTransfer(beneficiary, stableCoins); // Manual Withdrawal and save Investor history for refund
        _postValidatePurchase(beneficiary, stableCoins);

        // require(1 == 2, "Fallback Completed");
        return true;
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     * @param targetTokens Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount,
        uint256 targetTokens
    ) internal view {
        require(
            beneficiary != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(targetTokens != 0, "Crowdsale: targetTokens is 0");

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
    {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount)
        internal
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev Send Stable Coin the receiver address
     * @param stableAmount is the amount of stable coin deposited by investor
     * @param receiver  Address receiving the tokens
     */
    function _forwardTokens(address receiver, uint256 stableAmount) internal {
        _stableCoin.transfer(receiver, stableAmount);
    }

    /**
     * @dev Executed when a investment made needs to be transfered or stored
     * @param stableAmount Number of tokens to be purchased
     */
    function _processTransfer(
        address, /*investor*/
        uint256 stableAmount
    ) internal {
        _forwardTokens(_wallet, stableAmount);
    }

    function bytesToUint(bytes memory b) public pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number =
                number +
                uint256(uint8(b[i])) *
                (2**(8 * (b.length - (i + 1))));
        }
        return number;
    }

    // Change Stable Coin Contract Address in STO
    function changeSTableCoinAddress(IERC20 stableCoin)
     public 
     onlyAdmin
     {
        _stableCoin = stableCoin;
    }

    // Change ERC1400 Token Contract Address in STO
    function changeERC1400Address(IERC1400RawERC20 _erc1400) 
    public
    onlyAdmin {
        _token = _erc1400;
    }

      function adminAddress( address _address 
    ) internal view  returns(bool){
        // return admin;
        return whitelist.isAdmin(_address);
    }

    function changePropertyOwnerAddress(address payable newOwner) public onlyAdmin {
    _wallet = newOwner;
    }

}

pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../validation/TimedCrowdsale.sol";


/**
 * @title FinalizableCrowdsale
 * @dev Extension of TimedCrowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized();

    constructor() internal {
        _finalized = false;
    }

    /**
     * @return true if the crowdsale is finalized, false otherwise.
     */
    function finalized() public view returns (bool) {
        return _finalized;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() public {
        require(!_finalized, "FinalizableCrowdsale: already finalized");
        require(hasClosed(), "FinalizableCrowdsale: not closed");

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super._finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function _finalization() internal {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// pragma solidity ^0.5.0;

// import "./RefundableCrowdsale.sol";
// import "../validation/TimedCrowdsale.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "openzeppelin-solidity/contracts/ownership/Secondary.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
// import "./../../token/ERC20/IERC1400RawERC20.sol";

// /**
//  * @title PostGoalCrowdsale
//  * @dev Crowdsale that locks tokens from withdrawal until it ends.
//  */
// contract PostGoalCrowdsale is TimedCrowdsale, RefundableCrowdsale {
//     using SafeMath for uint256;

//     mapping(address => uint256) private _balances;
//     __unstable__TokenVault public _vault;

//     constructor() public {
//         _vault = new __unstable__TokenVault();
//     }

//     /**
//      * @dev Withdraw tokens only after crowdsale ends.
//      * @param beneficiary Whose tokens will be withdrawn.
//      */
//     function withdrawTokens(address beneficiary) public {
//         require(goalReached(), "PostGoalCrowdsale: Goal not reached");
//         uint256 amount = _balances[beneficiary];
//         require(
//             amount > 0,
//             "PostGoalCrowdsale: beneficiary is not due any tokens"
//         );

//         _balances[beneficiary] = 0;
//         _vault.transfer(token(), beneficiary, amount);
//     }

//     /**
//      * @return the balance of an account.
//      */
//     function balanceOf(address account) public view returns (uint256) {
//         return _balances[account];
//     }

//     /**
//      * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
//      * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
//      * `_deliverTokens` was called later).
//      * @param beneficiary Token purchaser
//      * @param tokenAmount Amount of tokens purchased
//      */
//     function _processPurchase(address beneficiary, uint256 tokenAmount)
//         internal
//     {
//         _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
//         _deliverTokens(address(_vault), tokenAmount);
//     }
// }

// /**
//  * @title __unstable__TokenVault
//  * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
//  * This contract is an internal helper for PostGoalCrowdsale, and should not be used outside of this context.
//  */
// // solhint-disable-next-line contract-name-camelcase
// contract __unstable__TokenVault is Secondary {
//     function transfer(
//         IERC1400RawERC20 token,
//         address to,
//         uint256 amount
//     ) public onlyPrimary {
//         token.transfer(to, amount);
//     }
// }



pragma solidity ^0.5.0;

import "./RefundableCrowdsale.sol";
import "../validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Secondary.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./../../token/ERC20/IERC1400RawERC20.sol";
/**
 * @title PostGoalCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostGoalCrowdsale is TimedCrowdsale, RefundableCrowdsale {
    using SafeMath for uint256;
// to store balances of beneficiaries
    mapping(address => uint256) private _balances;
    // to store _beneficiaries address used in all withdraw tokens
    // mapping (address => bool) private _beneficiaries;
// maintain list of total beneficiaries
    address[] public totalCrowdSaleCustomers ;
    __unstable__TokenVault public _vault;

    constructor() public {
        _vault = new __unstable__TokenVault();
    }

     /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary is address of withdraw tokens to
     */
    function withdrawTokens(address beneficiary) public {
        require(goalReached(), "PostGoalCrowdsale: Goal not reached");
        uint256 amount = _balances[beneficiary];
        require(
            amount > 0,
            "PostGoalCrowdsale: beneficiary is not due any tokens"
        );
        _balances[beneficiary] = 0;
        _vault.transfer(token(), beneficiary, amount);
        
    }


    /**
     * @dev Withdraw tokens only after crowdsale ends.
     */
    function withdrawAllTokens() public {
        require(goalReached(), "PostGoalCrowdsale: Goal not reached");
        for(uint8 i = 0 ; i < totalCrowdSaleCustomers.length ; i++){
        uint256 amount = _balances[totalCrowdSaleCustomers[i]];
        if(amount > 0)
        { 
        _balances[totalCrowdSaleCustomers[i]] = 0;
        _vault.transfer(token(), totalCrowdSaleCustomers[i], amount);
        }
        }
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
    {
        if(_balances[beneficiary]==0){
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(_vault), tokenAmount);
                    totalCrowdSaleCustomers.push(beneficiary);

        }else{

            _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(_vault), tokenAmount);

        }
                // _beneficiaries[beneficiary] = true;

        // bool isAdded = isAdded(beneficiary);
        // if(!isAdded){
        // }
        
    }

}
/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostGoalCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(
        IERC1400RawERC20 token,
        address to,
        uint256 amount
    ) public onlyPrimary {
        token.transfer(to, amount);
    }

}

pragma solidity ^0.5.0;

import "../../utils/Context.sol";
import "./FinalizableCrowdsale.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "openzeppelin-solidity/contracts/ownership/Secondary.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


/**
 * @title RefundableCrowdsale
 * @dev Extension of `FinalizableCrowdsale` contract that adds a funding goal, and the possibility of users
 * getting a refund if goal is not met.
 *
 * Deprecated, use `RefundablePostDeliveryCrowdsale` instead. Note that if you allow tokens to be traded before the goal
 * is met, then an attack is possible in which the attacker purchases tokens from the crowdsale and when they sees that
 * the goal is unlikely to be met, they sell their tokens (possibly at a discount). The attacker will be refunded when
 * the crowdsale is finalized, and the users that purchased from them will be left with worthless tokens.
 */
contract RefundableCrowdsale is Context, FinalizableCrowdsale {
    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 private _goal;

    mapping(address => uint256) private _balances;
    // refund store used to hold funds while crowdsale is running
    __unstable__StableStore public _goalStore;

    /**
     * @param goal Funding goal
     */
    constructor(uint256 goal) public {
        require(goal > 0, "RefundableCrowdsale: goal is 0");
        _goalStore = new __unstable__StableStore();
        _goal = goal;
    }

    /**
     * @return the refund balance of an account.
     */
    function refundAmount(address account) public view returns (uint256) {
        require(!goalReached(), "RefundableCrowdsale: goal reached");
        return _balances[account];
    }

    /**
     * @return minimum amount of funds to be raised in wei.
     */
    function goal() public view returns (uint256) {
        return _goal;
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful.
     * @param refundee Whose refund will be claimed.
     */
    function claimRefund(address refundee) public {
        require(finalized(), "RefundableCrowdsale: not finalized");
        require(!goalReached(), "RefundableCrowdsale: goal reached");

        uint256 amount = _balances[refundee];
        require(
            amount > 0,
            "RefundableCrowdsale: refundee is not due any tokens"
        );

        _balances[refundee] = 0;
        _goalStore.transfer(stableCoin(), refundee, amount);
    }

    /**
     * @dev Checks whether funding goal was reached.
     * @return Whether funding goal was reached
     */
    function goalReached() public view returns (bool) {
        return weiRaised() >= _goal;
    }

    /**
     * @dev Escrow finalization task, called when finalize() is called.
     */
    function withdrawStable() public {
        require(goalReached(), "RefundableCrowdsale: goal not reached");
        uint256 allStableCoin = stableCoin().balanceOf(address(_goalStore));
        _goalStore.transfer(stableCoin(), wallet(), allStableCoin);
    }

    /**
     * @dev Determines how TKUSD is stored/forwarded on purchases.
     * @param stableAmount Number of tokens to be purchased
     * @param investor     Investor address who sent that money
     */
    function _processTransfer(address investor, uint256 stableAmount) internal {
        _balances[investor] = _balances[investor].add(stableAmount);
        _forwardTokens(address(_goalStore), stableAmount);
    }
}


/**
 * @title __unstable__StableStore
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostGoalCrowdsale, and should not be used outside of this context.
 */
contract __unstable__StableStore is Secondary {
    function transfer(IERC20 token, address to, uint256 amount)
        public
        onlyPrimary
    {
        token.transfer(to, amount);
    }

    function tokenFallback(
        address, /*_from*/
        uint256, /*_value*/
        bytes memory /*_data*/
    ) public pure returns (bool success) {
        return true;
    }
}

pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";

import "../../token/ERC20/IERC1400RawERC20.sol";
import "../Crowdsale.sol";


/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {
    bytes
        public constant certificate = "0x1000000000000000000000000000000000000000000000000000000000000000";

    address public testMintedSender; // testcase

    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param beneficiary Token purchaser
     * @param tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        // Potentially dangerous assumption about the type of the token.
        testMintedSender = msg.sender;

        require(
            IERC1400RawERC20(address(token())).issue(
                beneficiary,
                tokenAmount,
                certificate
            ),
            "MintedCrowdsale: minting failed"
        );
    }
}

pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../Crowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param cap Max amount of wei to be contributed
     */
    constructor(uint256 cap) public {
        require(cap > 0, "CappedCrowdsale: cap is 0");
        _cap = cap;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount,
        uint256 targetTokens
    ) internal view {
        super._preValidatePurchase(beneficiary, weiAmount, targetTokens);
        require(
           ( weiRaised().add(weiAmount)).div(1 ether) <= _cap,
            "CappedCrowdsale: cap exceeded"
        );
    }

     /**
    Increase Cap
    Increase Cap by Super Admin on Request of Property Owner
    When Property Owner pay loan back to bank against that property he will 
     */
    //  function increaseCapSuperAdmin(uint256 _value) internal returns(uint256){

    //      _cap = _cap + _value;
    //      return _cap;

    //  }
}

pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../Crowdsale.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;
    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime Crowdsale opening time
     * @param closingTime Crowdsale closing time
     */
    constructor(uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(
            openingTime >= block.timestamp,
            "TimedCrowdsale: opening time is before current time"
        );
        // solhint-disable-next-line max-line-length
        require(
            closingTime > openingTime,
            "TimedCrowdsale: opening time is not before closing time"
        );
        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    //Modifier for only Tokenism Admin Can
    modifier onlyAdmin() {
        require(super.adminAddress(_msgSender()), "Only admin is allowed");
        _;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return
            block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount,
        uint256 targetTokens
    ) internal view onlyWhileOpen {
        super._preValidatePurchase(beneficiary, weiAmount, targetTokens);
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function extendTime(uint256 newClosingTime) public onlyAdmin {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime > _closingTime,
            "TimedCrowdsale: new closing time is before current closing time"
        );

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

pragma solidity ^0.5.0;

import "../Crowdsale.sol";
import "../../whitelist/ITokenismWhitelist.sol";

/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistCrowdsale is Crowdsale {
    // contract WhitelistCrowdsale is WhitelistedRole, Crowdsale {

    ITokenismWhitelist public whitelist;

    constructor(ITokenismWhitelist _whitelist) public {
        whitelist = _whitelist;
    }

    /**
     * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
     * restriction is imposed on the account sending the transaction.
     * @param _beneficiary Token beneficiary
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _targetTokens
    ) internal view {
        uint256 code = whitelist.isWhitelistedUser(_beneficiary);
        require(
            code == 200,
            "WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role"
        );
        super._preValidatePurchase(_beneficiary, _weiAmount, _targetTokens);
    }

    // Change Whitelisting Contract Address
function changeWhitelistingContract(ITokenismWhitelist _whitelisting) internal {
    whitelist = _whitelisting;
}
}

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */
// pragma solidity ^0.5.0;

// /**
//  * @title Exchange Interface
//  * @dev Exchange logic
//  */
// interface IERC1400RawERC20  {

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */

//   function name() external view returns (string memory); // 1/13
//   function symbol() external view returns (string memory); // 2/13
//   function totalSupply() external view returns (uint256); // 3/13
//   function balanceOf(address owner) external view returns (uint256); // 4/13
//   function granularity() external view returns (uint256); // 5/13

//   function controllers() external view returns (address[] memory); // 6/13
//   function authorizeOperator(address operator) external; // 7/13
//   function revokeOperator(address operator) external; // 8/13
//   function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

//   function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
//   function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

//   function redeem(uint256 value, bytes calldata data) external; // 12/13
//   function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
//    // Added Latter
//    function cap(uint256 propertyCap) external;
//   function basicCap() external view returns (uint256);
//   function getStoredAllData() external view returns (address[] memory, uint256[] memory);

//     // function distributeDividends(address _token, uint256 _dividends) external;
//   event TransferWithData(
//     address indexed operator,
//     address indexed from,
//     address indexed to,
//     uint256 value,
//     bytes data,
//     bytes operatorData
//   );
//   event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
//   event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
//   event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
//   event RevokedOperator(address indexed operator, address indexed tokenHolder);

//  function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
// function allowance(address owner, address spender) external view returns (uint256);
// function approve(address spender, uint256 value) external returns (bool);
// function transfer(address to, uint256 value) external  returns (bool);
// function transferFrom(address from, address to, uint256 value)external returns (bool);
// function migrate(address newContractAddress, bool definitive)external;
// function closeERC1400() external;
// function addFromExchange(address investor , uint256 balance) external returns(bool);
// function updateFromExchange(address investor , uint256 balance) external;
// function transferOwnership(address payable newOwner) external; 
// }
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.5.0;

/**
 * @title Exchange Interface
 * @dev Exchange logic
 */
interface IERC1400RawERC20  {

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

  function name() external view returns (string memory); // 1/13
  function symbol() external view returns (string memory); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function controllers() external view returns (address[] memory); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

  function redeem(uint256 value, bytes calldata data) external; // 12/13
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   // Added Latter
   function cap(uint256 propertyCap) external;
  function basicCap() external view returns (uint256);
  function getStoredAllData() external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

 function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 value) external returns (bool);
function transfer(address to, uint256 value) external  returns (bool);
function transferFrom(address from, address to, uint256 value)external returns (bool);
function migrate(address newContractAddress, bool definitive)external;
function closeERC1400() external;
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
function updateFromExchange(address investor , uint256 balance) external returns (bool);
function transferOwnership(address payable newOwner) external; 
}

pragma solidity ^0.5.0;

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;


interface ITokenismWhitelist {
    function addWhitelistedUser(address _wallet, bool _kycVerified, bool _accredationVerified, uint256 _accredationExpiry) external;
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    function suspendUser(address _wallet) external;

    function activeUser(address _wallet) external;

    function updateUserType(address _wallet, string calldata _userType) external;
    function isWhitelistedUser(address wallet) external view returns (uint);
    function removeWhitelistedUser(address _wallet) external;
    function isWhitelistedManager(address _wallet) external view returns (bool);

 function removeSymbols(string calldata _symbols) external returns(bool);
 function closeTokenismWhitelist() external;
 function addSymbols(string calldata _symbols)external returns(bool);

  function isAdmin(address _admin) external view returns(bool);
  function isOwner(address _owner) external view returns (bool);
  function isBank(address _bank) external view returns(bool);
  function isSuperAdmin(address _calle) external view returns(bool);
  function getFeeStatus() external returns(uint8);
  function getFeePercent() external view returns(uint8);
  function getFeeAddress()external returns(address);

    function isManager(address _calle)external returns(bool);
    function userType(address _caller) external view returns(bool);

}

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

pragma solidity ^0.5.2;

import "../Roles.sol";

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity ^0.5.2;

import "../Roles.sol";

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

pragma solidity ^0.5.2;

import "../access/roles/PauserRole.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Secondary
 * @dev A Secondary contract can only be used by its primary account (the one that created it)
 */
contract Secondary {
    address private _primary;

    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

pragma solidity ^0.5.2;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

pragma solidity ^0.5.2;

import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

pragma solidity ^0.5.2;

import "./ERC20.sol";
import "../../lifecycle/Pausable.sol";

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 */
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must equal true).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

