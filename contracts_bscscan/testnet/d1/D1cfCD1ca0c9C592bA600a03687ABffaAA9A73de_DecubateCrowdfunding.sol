// SPDX-License-Identifier: MIT

//** Decubate Crowdfunding Contract */
//** Author Vipin */

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IDecubateFactory.sol";
import "./interfaces/IWalletStore.sol";
import "./interfaces/IBracketAllocation.sol";

contract DecubateCrowdfunding is IDecubateFactory, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     *
     * @dev InvestorInfo is the struct type which store investor information
     *
     */
    struct InvestorInfo {
        uint256 joinDate;
        uint256 investAmount;
        address wallet;
        IERC20 token;
        bool whitelist;
        bool active;
    }

    /**
     *
     * @dev TokenModel will store new token informations which will be added to the contract
     *
     */
    struct TokenModel {
        IERC20 token;
        uint256 startDate;
        uint256 endDate;
        uint256 rate;
        uint256 totalRaise;
        uint256 hardCap;
        bool active;
    }

    /**
     *
     * @dev AgreementInfo will have information about agreement.
     * It will contains agreement details between innovator and investor.
     * For now, innovatorWallet will reflect owner of the platform.
     *
     */
    struct AgreementInfo {
        string agreementName;
        address innovatorWallet;
        uint256 softcap;
        uint256 hardcap;
        uint256 createDate;
        uint256 endDate;
        uint256 vote;
        uint256 totalInvestFund;
        bool active;
        mapping(address => InvestorInfo) investorList;
        mapping(address => InvestorInfo) voterList;
    }

    /**
     *
     * @dev tokenPools store all active tokens available on this contract.
     *
     */
    mapping(address => TokenModel) public tokenPools;

    /**
     *
     * @dev this variable is the instance of active DCB token
     *
     */
    IERC20 private _decubateToken;

    /**
     *
     * @dev this variable is the instance of wallet storage
     *
     */
    IWalletStore private _walletStore;

     /**
     *
     * @dev this variable is the instance of Bracket contract
     *
     */
    IBracketAllocation private _bracketAlloc;
    
    /**
     *
     * @dev this variable sets use of brackets
     *
     */
    bool public _useBrackets;

    /**
     *
     * @dev this variable stores total number of participants
     *
     */
    uint256 private _participantCount;
    
    /**
     *
     * @dev this variable set the required vote number for the agreement
     *
     */
    uint256 public _requiredVoteNumber;

    /**
     *
     * @dev dcbAgreement store agreements info of this contract.
     *
     */
    AgreementInfo public dcbAgreement;

    modifier requireDCB(address _wallet) {
        /** check if investor has any DCB token */
        require(
            _decubateToken.balanceOf(address(_wallet)) >= 1,
            "You need to own DCB tokens"
        );
        _;
    }

    modifier requireToken(address _token) {
        /** check if token is available in token pool */
        require(tokenPools[_token].active, "Token does not exist");
        _;
    }

    constructor() public {
        /** here we set required vote number as 100 in constructor but feel free to update this by calling setter function */
        _requiredVoteNumber = 100;
    }

    /**
     *
     * @dev set required vote number for each agreements
     *
     * @param {uint256} number of required vote for active agreement
     * @return {bool} return status
     *
     */
    function setRequiredVote(uint256 _vote)
        external
        override
        onlyOwner
        returns (bool)
    {
        _requiredVoteNumber = _vote;
        return true;
    }

    /**
     *
     * @dev set decubate token address for contract
     *
     * @param {_token} address of IERC20 instance
     * @return {bool} return status of token address
     *
     */
    function setDecubateToken(IERC20 _token)
        external
        override
        onlyOwner
        returns (bool)
    {
        _decubateToken = _token;
        return true;
    }

    /**
     *
     * @dev set decubate token address for contract
     *
     * @param {_contract} address of IERC20 instance
     * @return {bool} return status of token address
     *
     */
    function setWalletStore(address _contract)
        external
        override
        onlyOwner
        returns (bool)
    {
        _walletStore = IWalletStore(_contract);
        return true;
    }

    /**
     *
     * @dev set Bracket contract address for contract
     *
     * @param {_contract} address of Bracket contract
     * @param {_value} Enable/disable bracket usage
     * @return {bool} return status of token address
     *
     */
    function setBracket(address _contract, bool _value)
        external
        onlyOwner
        override
        returns (bool)
    {
        _bracketAlloc = IBracketAllocation(_contract);
        _useBrackets = _value;
        return true;
    }

    /**
     *
     * @dev getter function for deployed decubate token address
     *
     * @return {address} return deployment address of decubate token
     *
     */
    function getDecubateToken() public view override returns (address) {
        return address(_decubateToken);
    }

    /**
     *
     * @dev getter function for total participants
     *
     * @return {uint256} return total participant count of crowdfunding
     *
     */
    function getInfo() 
    public 
    view 
    override 
    returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        return (dcbAgreement.hardcap,
        dcbAgreement.createDate,
        dcbAgreement.endDate,
        dcbAgreement.totalInvestFund,
        _participantCount,
        _requiredVoteNumber
        );
    }

    /**
     *
     * @dev generate the new agreement deal
     * ** originally, this is the function calling from innovator to create new agreement.
     * ** but for initial staging, this should be under owner level and DCB will add all agreements to pools for future investors.
     * ** this function will set hardcap, end date and name of agreement
     *
     * @param {string} set original name of agreement
     * @return {bool} return agreement creation status
     *
     */
    function addDCBAgreement(
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _endDate,
        string calldata _name
    ) external override onlyOwner returns (bool) {
        /** conditions to check if able to create new agreement */
        require(_hardcap > 0, "Hardcap need to be defined");
        require(_softcap > 0, "Softcap need to be defined");
        require(
            _endDate > block.timestamp,
            "Agreement end date passed"
        );
        require(!dcbAgreement.active, "Agreement already exist");

        /** generate the new agreement */
        AgreementInfo memory smartAgreement = AgreementInfo({
            agreementName: _name,
            innovatorWallet: msg.sender,
            softcap: _softcap,
            hardcap: _hardcap,
            createDate: block.timestamp,
            endDate: _endDate,
            vote: 0,
            totalInvestFund: 0,
            active: true
        });

        /** set the agreement as the new agreement */
        dcbAgreement = smartAgreement;

        /** emit the agreement generation event */
        emit CreateAgreement();
        return true;
    }

    /**
     *
     * @dev add individual tokens (IERC20) to use for our DCB.
     * ** possibly, we will support investors to invest funds with different crypto assets.
     * ** but for now, this will be used as boilerplate as we are going to use DCB token for transaction.
     *
     * @param {address} token instance which is going to add
     * @param {uint256} available date
     * @param {uint256} expired date
     * @param {uint256} rate compared to our DCB
     *
     * @return {bool} return if token is successfully add or not
     *
     */
    function addTokenSupport(
        address _token,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _rate,
        uint256 _hardCap
    ) external override onlyOwner returns (bool) {
        require(!tokenPools[address(_token)].active, "Token already exist");

        /** add new token to the token pool */
        tokenPools[_token].rate = _rate;
        tokenPools[_token].totalRaise = 0;
        tokenPools[_token].active = true;
        tokenPools[_token].hardCap = _hardCap;
        tokenPools[_token].token = IERC20(_token);
        tokenPools[_token].startDate = _startDate;
        tokenPools[_token].endDate = _endDate;
        

        /** emit the Add Token event */
        emit AddToken(_token);
        return true;
    }

    /**
     *
     * @dev remove active token from token pool
     * ** set deactive flag for existing token because easy to active status later if needed
     *
     * @param {address} active token address which existing in pool
     *
     * @return {bool} return if token is deactived or not
     *
     */
    function removeTokenFromDCB(address _token)
        external
        override
        requireToken(_token)
        onlyOwner
        returns (bool)
    {
        tokenPools[_token].active = false;

        /** emit the event for removing token */
        emit RemoveToken(_token);
        return true;
    }

    /**
     *
     * @dev Retrieve total amount of token from the contract
     *
     * @param {address} address of the token
     *
     * @return {uint256} total amount of token
     *
     */
    function getTotalToken(IERC20 _token)
        external
        view
        override
        returns (uint256)
    {
        return _token.balanceOf(address(this));
    }

    /**
     *
     * @dev getter function to retrieve token in the pool
     *
     * @param {address} address of token
     *
     * @return {TokenModel} return token info
     *
     */
    function getTokenFromDCB(address _token)
        external
        view
        requireToken(_token)
        returns (TokenModel memory)
    {
        return tokenPools[_token];
    }

    /**
     *
     * @dev investor join available agreement
     *
     * @param {uint256} identifier of agreement
     * @param {uint256} actual join date for investment
     * @param {address} address of token which is going to use as deposit
     *
     * @return {bool} return if investor successfully joined to the agreement
     *
     */
    function joinDCBAgreement(uint256 _investFund, address _token)
        external
        override
        nonReentrant
        requireDCB(msg.sender)
        requireToken(_token)
        returns (bool)
    {
        /** check if agreement is exist */
        require(dcbAgreement.active, "Agreement is not exist");

        /** check if user is verified */
        require(_walletStore.isVerified(msg.sender),"User is not verified");

        /** check if user already invested for this agreement */
        require(
            dcbAgreement.investorList[msg.sender].wallet != msg.sender,
            "User already joined"
        );

        /** check if investor is willing to invest any funds */
        require(_investFund > 0, "You cannot invest 0");

        /** check if investor has enough funds for invest */
        require(
            tokenPools[_token].token.balanceOf(address(msg.sender)) >
                _investFund,
            "Not enough funds"
        );

        /** check if endDate has already passed */
        require(
            block.timestamp < dcbAgreement.endDate,
            "Crowdfunding ended"
        );

        require(
            tokenPools[_token].totalRaise + _investFund <=
            tokenPools[_token].hardCap,
            "Hardcap already met"
        );

        /** Add to bracket if enabled */
        if(_useBrackets){
            _bracketAlloc.setAddress(msg.sender, _investFund);
        }

        /** add new investor to investor list for specific agreeement */
        dcbAgreement.investorList[msg.sender].wallet = msg.sender;
        /** rate should not be decimal, so we use to multplay 10**6 as input with SafeMath */
        /** e.g: if rate is 0.6, input should 0.6 * 10^6 */
        dcbAgreement.investorList[msg.sender].investAmount = _investFund
        .mul(tokenPools[_token].rate)
        .div(10**6);
        dcbAgreement.investorList[msg.sender].active = true;
        dcbAgreement.investorList[msg.sender].token = IERC20(_token);
        _participantCount++;
        dcbAgreement.totalInvestFund += dcbAgreement
        .investorList[msg.sender]
        .investAmount;

        tokenPools[_token].totalRaise += _investFund;

        tokenPools[_token].token.transferFrom(
            msg.sender,
            address(this),
            _investFund
        );

        emit InvestorJoin(msg.sender, _investFund);
        return true;
    }

    /**
     *
     * @dev this function will let investors to vote for available project
     *
     * @param {uint256} unique identifier of the project which investor is willing to vote
     *
     * @return {uint256} return vote number of the project
     *
     */
    function voteDCBAgreement() external requireDCB(msg.sender) override returns (uint256) {
        /** make sure if project is available */
        require(dcbAgreement.active, "Agreement is not active");

        /** check if investor already vote on this project */
        require(
            dcbAgreement.voterList[msg.sender].wallet != msg.sender,
            "Already voted"
        );

        dcbAgreement.vote += 1;
        dcbAgreement.voterList[msg.sender].wallet = msg.sender;
        dcbAgreement.voterList[msg.sender].active = true;
        return dcbAgreement.vote;
    }

    /**
     *
     * @dev boilertemplate function for innovator to claim funds
     *
     * @param {address}
     *
     * @return {bool} return status of claim
     *
     */
    function claimInnovatorFund(address _token)
        external
        override
        nonReentrant
        requireDCB(msg.sender)
        returns (bool)
    {
        /** verify if token is locked or not */
        require(
            tokenPools[_token].startDate < block.timestamp &&
                tokenPools[_token].endDate > block.timestamp,
            "Token is inactive"
        );

        /** make sure if project has enough vote */
        require(
            dcbAgreement.vote >= _requiredVoteNumber,
            "Not enough votes"
        );

        /** check if treasury have enough funds to withdraw to innovator */
        require(
            tokenPools[_token].token.balanceOf(address(this)) >=
                dcbAgreement.totalInvestFund.mul(10**6)
                .div(tokenPools[_token].rate),
            "Not enough funds in treasury"
        );

        /** check if endDate already passed and softcap is reached */
        require(
            block.timestamp >= dcbAgreement.endDate &&
            dcbAgreement.totalInvestFund >= dcbAgreement.softcap,
            "Date and cap not met"
        );

        /** 
            transfer token from treasury to innovator
        */
        tokenPools[_token].token.transfer(
            dcbAgreement.innovatorWallet,
            dcbAgreement.totalInvestFund
            .mul(10**6).div(tokenPools[_token].rate)
        );

        emit ClaimFund(_token);
        return true;
    }

    /**
     *
     * @dev we will have function to transfer stable coins to company wallet
     *
     * @param {address} token address
     *
     * @return {bool} return status of the transfer
     *
     */

    function transferToken(
        address _token,
        uint256 _amount,
        address _to
    ) external override onlyOwner requireToken(_token) returns (bool) {
        /** check if treasury have enough funds  */
        require(
            tokenPools[_token].token.balanceOf(address(this)) > _amount,
            "Not enough funds in treasury"
        );
        tokenPools[_token].token.transfer(_to, _amount);

        emit TransferFund(_token, _amount, _to);
        return true;
    }

    /**
     *
     * @dev Users can claim back their token if softcap isn't reached
     *
     * @return {bool} return status of the refund
     *
     */

    function refund() external override returns (bool) {
        /** check if user is an investor */
        require(
            dcbAgreement.investorList[msg.sender].wallet == msg.sender,
            "User is not an investor"
        );
        /** check if softcap has already reached */
        require(
            dcbAgreement.totalInvestFund <= dcbAgreement.softcap,
            "Softcap already reached"
        );
        /** check if end date have passed or not */
        require(
            block.timestamp >= dcbAgreement.endDate,
            "End date not reached"
        );
        IERC20 _token = dcbAgreement.investorList[msg.sender].token;
        uint256 _amount = dcbAgreement.investorList[msg.sender].investAmount
                .mul(10**6).div(tokenPools[address(_token)].rate);

        /** check if contract have enough balance*/
        require(
            _token.balanceOf(address(this)) >= _amount,
            "Not enough funds in treasury"
        );
        dcbAgreement.investorList[msg.sender].active = false;
        dcbAgreement.investorList[msg.sender].wallet = address(0);
        dcbAgreement.totalInvestFund -= dcbAgreement.investorList[msg.sender].investAmount;

        _token.transfer(msg.sender, _amount);
        
        return true;
    }

    /**
     *
     * @dev revert transaction
     *
     */
    fallback() external {
        revert();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

interface IWalletStore {

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function isVerified(address) external view returns (bool);

    function addUser(address _address) external returns (bool);

    function getVerifiedUsers() external view returns (address[] memory);

}

// SPDX-License-Identifier: MIT

//** Decubate Factory Contract */
//** Author Vipin */

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDecubateFactory {
    /**
     *
     * @dev this event will call when new token added to the contract
     * currently, we are supporting DCB token and this will be used for future implementation
     *
     */
    event AddToken(address token);

    /**
     *
     * @dev this event will call when active token removed from pool
     *
     */
    event RemoveToken(address token);

    /**
     *
     * @dev this event will call when new agreement generated.
     * this is called when innovator create a new agreement but for now, it is calling when owner create new agreement
     *
     */
    event CreateAgreement();

    /**
     *
     * @dev it is calling when new investor joinning to the existing agreement
     *
     */
    event InvestorJoin(address wallet, uint256 amount);

    /**
     *
     * @dev this is called when investor vote for the project
     *
     */
    event Vote(uint256 identifier, address investor);

    /**
     *
     * @dev this event is called when innovator claim withdrawl
     *
     */
    event ClaimFund(address token);

    /**
     *
     * @dev this event is called when transfer fund to other address
     *
     */
    event TransferFund(address token, uint256 amount, address to);

    /**
     *
     * inherit functions will be used in contract
     *
     */
    function setRequiredVote(uint256 _vote) external returns (bool);

    function setDecubateToken(IERC20 _token) external returns (bool);

    function setWalletStore(address _wallet) external returns (bool);

    function setBracket(address _wallet, bool _value) external returns (bool);

    function getDecubateToken() external view returns (address);

    function getInfo() external view returns (uint256,uint256,uint256,uint256,uint256,uint256);

    function getTotalToken(IERC20 _token) external view returns (uint256);

    function addDCBAgreement(
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _endDate,
        string calldata _name
    ) external returns (bool);

    function addTokenSupport(
        address _token,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _rate,
        uint256 _hardCap
    ) external returns (bool);

    function removeTokenFromDCB(address _token) external returns (bool);

    function joinDCBAgreement(uint256 _investFund, address _token)
        external
        returns (bool);

    function voteDCBAgreement() external returns (uint256);

    function claimInnovatorFund(address _token) external returns (bool);

    function refund() external returns (bool);

    function transferToken(
        address _token,
        uint256 _amount,
        address _to
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IBracketAllocation {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function bracketInfo(uint256)
        external
        view
        returns (
            uint256 maxCount,
            uint256 currCount,
            uint256 allowedAmount,
            uint256 minLimit,
            uint256 maxLimit
        );

    function isEnabled() external view returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function addBracket(
        uint256 _maxCount,
        uint256 _allowedAmount,
        uint256 _minLimit,
        uint256 _maxLimit
    ) external returns (bool);

    function setBracket(
        uint256 bracketId,
        uint256 _maxCount,
        uint256 _allowedAmount,
        uint256 _minLimit,
        uint256 _maxLimit
    ) external returns (bool);

    function getTotalDeposit(address addr)
        external
        view
        returns (uint256 amount);

    function getBracketsLength() external view returns(uint256 len);    

    function getBracketUsers(uint8 bracket) external view returns(address[] memory alist);

    function setAddress(address addr, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

