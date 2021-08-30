pragma solidity ^0.5.16;

import "./Uctroller.sol";
import "./CarefulMath.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./InterestRateModel.sol";
import "./UTokenInterfaces.sol";
import "./IUtopiaToken.sol";


contract CDP is CarefulMath, Ownable, TokenErrorReporter, Exponential{
    struct MintSnapshot {
        uint principal;
        uint interestIndex;
    }

    struct MintLocalVars {
        MathError mathErr;
        uint accountMints;
        uint accountMintsNew;
        uint totalMintsNew;
    }

    Uctroller public uctroller;

    address public reservePool;

    address public moatPool;

    mapping(address => MintSnapshot) public accountMints;

    uint public accrualBlockNumber;

    uint public mintIndex;

    uint public totalMints;

    InterestRateModel public interestRateModel;

    uint internal constant mintRateMaxMantissa = 0.0005e16;

    address public uc;

    uint public ucReward;

    DToken public debtToken;
    SToken public stableToken;

    constructor(address _uctroller, address _interestRateModel, address _moatPool, address _reservePool, address _uc) public {
       uctroller = Uctroller(_uctroller);
       interestRateModel = InterestRateModel(_interestRateModel);
       moatPool = _moatPool;
       reservePool = _reservePool;
       mintIndex = 1e18;
       uc = _uc;
    }

    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    function accrue() external{
        accrueInterest();
    }

    function accrueInterest() internal returns (uint) {
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        uint cashPrior = uctroller.getAllUTokenValue();
        uint mintsPrior = totalMints;
        uint mintIndexPrior = mintIndex;

        uint mintRateMantissa = interestRateModel.getMintRate(cashPrior, mintsPrior, 0);
        require(mintRateMantissa <= mintRateMaxMantissa, "mint rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = mintRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalMints
         *  totalMintsNew = interestAccumulated + totalMints
         *  mintIndexNew = simpleInterestFactor * mintIndex + mintIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalMintsNew;
        uint mintIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: mintRateMantissa}), blockDelta);
        require(mathErr == MathError.NO_ERROR,"mulScalar error");

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, mintsPrior);
        require(mathErr == MathError.NO_ERROR,"mulScalarTruncate error");

        (mathErr, totalMintsNew) = addUInt(interestAccumulated, mintsPrior);
        require(mathErr == MathError.NO_ERROR,"addUInt error");

        (mathErr, mintIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, mintIndexPrior, mintIndexPrior);
        require(mathErr == MathError.NO_ERROR,"mulScalarTruncateAddUInt error");

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        mintIndex = mintIndexNew;
        totalMints = totalMintsNew;

        /* We emit an AccrueInterest event */
        // emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    function mintStableCoin(uint amount) external returns(uint){
        address minter = msg.sender;
        accrueInterest();
        MintLocalVars memory vars;

        /*
         *  accountMintsNew = accountMints + MintAmount
         *  totalMintsNew = totalMints + MintAmount
         */
        (vars.mathErr, vars.accountMints) = mintBalanceStoredInternal(minter);
        require(vars.mathErr == MathError.NO_ERROR,"mintBalanceStoredInternal error");

        bool isAllow = uctroller.isSystemSafety(amount, totalMints);
        require(isAllow == true, "system rate error");
        isAllow = uctroller.isAllowMintStableCoin(msg.sender, vars.accountMints, amount);
        require(isAllow == true, "usr rate error");

        (vars.mathErr, vars.accountMintsNew) = addUInt(vars.accountMints, amount);
        require(vars.mathErr == MathError.NO_ERROR,"accountMintsNew error");

        (vars.mathErr, vars.totalMintsNew) = addUInt(totalMints, amount);
        require(vars.mathErr == MathError.NO_ERROR,"totalMintsNew error");

        uctroller.debtToken().mint(minter, amount);
        uctroller.stableToken().mint(minter, amount);

        accountMints[minter].principal = vars.accountMintsNew;
        accountMints[minter].interestIndex = mintIndex;
        totalMints = vars.totalMintsNew;
    }

    function burnStableCoin(address usr,uint amount) external returns(uint){
        address payer = msg.sender;
        accrueInterest();

        MintLocalVars memory vars;
        (vars.mathErr, vars.accountMints) = mintBalanceStoredInternal(usr);
        require(vars.mathErr == MathError.NO_ERROR,"mintBalanceStoredInternal error");

        if (amount > vars.accountMints) {
            amount = vars.accountMints;
        }
        uint payerBalanceOf_s = uctroller.stableToken().balanceOf(payer);
        require(payerBalanceOf_s >= amount, "payerBalanceOf_s error");

        uint balanceOf_d = uctroller.debtToken().balanceOf(usr);
        uint amountToReserve;
        MathError mathErr;
        if (amount > balanceOf_d) {
            (mathErr, amountToReserve) = subUInt(amount, balanceOf_d);
            require(mathErr == MathError.NO_ERROR,"amountToReserve error");
            uctroller.stableToken().burn(payer, amount);
            uctroller.debtToken().burn(usr, balanceOf_d);
            uctroller.stableToken().mint(reservePool, amountToReserve);
        } else {
            uctroller.stableToken().burn(payer, amount);
            uctroller.debtToken().burn(usr, amount);
        }
        (mathErr,vars.accountMintsNew) = subUInt(vars.accountMints,amount);
        require(mathErr == MathError.NO_ERROR,"accountMintsNew error");
        (mathErr,vars.totalMintsNew) = subUInt(vars.accountMints,amount);
        require(mathErr == MathError.NO_ERROR,"totalMintsNew error");
        accountMints[usr].principal = vars.accountMintsNew;
        accountMints[usr].interestIndex = mintIndex;
        totalMints = vars.totalMintsNew;
    }

    function liquidate(address usr) external {
        address liquidater = msg.sender;
        accrueInterest();

        MintLocalVars memory vars;
        (vars.mathErr, vars.accountMints) = mintBalanceStoredInternal(usr);
        require(vars.mathErr == MathError.NO_ERROR,"mintBalanceStoredInternal error");
        bool isAllow = uctroller.isAllowLiquidate(usr,vars.accountMints);
        require(isAllow, "not allow");

        uint state;
        address payer;
        (state,payer) = uctroller.liquidateState(moatPool, reservePool, liquidater, vars.accountMints);

        if (ucReward > 0){
            IUtopiaToken(uc).issueTo(liquidater, ucReward);
        }
        
        MathError mathErr;
        uint toReserve;

        uctroller.stableToken().burn(payer, vars.accountMints);
        uint balanceOf_d = uctroller.debtToken().balanceOf(usr);
        (mathErr, toReserve) = subUInt(vars.accountMints, balanceOf_d);
        require(mathErr == MathError.NO_ERROR,"subUInt error");
        uctroller.debtToken().burn(usr, balanceOf_d);
        uctroller.stableToken().mint(reservePool,toReserve);
        accountMints[usr].principal = 0;
        accountMints[usr].interestIndex = mintIndex;
        UToken[] memory uTokens = uctroller.getAllUtokens();
        for (uint i = 0; i < uTokens.length; i++){
            address uToken = address(uTokens[i]);
            UErc20Interface(uToken).liquidate(usr, payer);
        }
    }

    function mintBalanceStored(address account) external view returns (uint){
        (MathError mathErr, uint mints) = mintBalanceStoredInternal(account);
        require(mathErr == MathError.NO_ERROR,"mintBalanceStoredInternal error");
        return mints;
    }
    function mintBalanceStoredInternal(address account) internal view returns (MathError, uint) {
        MintSnapshot storage mintSnapshot = accountMints[account];

        if (mintSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }
        MathError mathErr;
        uint principalTimesIndex;
        uint result;
        (mathErr, principalTimesIndex) = mulUInt(mintSnapshot.principal, mintIndex);
        require(mathErr == MathError.NO_ERROR,"mulUInt error");
        (mathErr, result) = divUInt(principalTimesIndex, mintSnapshot.interestIndex);
        require(mathErr == MathError.NO_ERROR,"divUInt error");
        return (mathErr, result);
    }

    function _resetUctroller(address _uctroller) external onlyOwner {
        uctroller = Uctroller(_uctroller);
    }

    function _setUcReward(uint _ucReward) external onlyOwner {
        ucReward = _ucReward;
    }

    function _createCoins(string calldata _name ,string calldata _symbol,uint8 _decimals) onlyOwner external {
        address dtoken;
        address stoken;
        bytes memory name_D = abi.encodePacked("D");
        name_D = abi.encodePacked(name_D,_name);
        bytes memory symbol_D = abi.encodePacked("D");
        symbol_D = abi.encodePacked(_symbol,symbol_D);
        bytes memory bytecode_D = type(DToken).creationCode;
        bytes32 salt_D = keccak256(abi.encodePacked(name_D, symbol_D, _decimals));
        assembly {
            dtoken := create2(0, add(bytecode_D, 32), mload(bytecode_D), salt_D)
        }
        DToken(dtoken).initialize(string(name_D), string(symbol_D), _decimals,owner(), address(this),uc);
        bytes memory name_S = abi.encodePacked("U");
        name_S = abi.encodePacked(name_S,_name);
        bytes memory symbol_S = abi.encodePacked("U");
        symbol_S = abi.encodePacked(_symbol,symbol_S);
        bytes memory bytecode_S = type(SToken).creationCode;
        bytes32 salt_S = keccak256(abi.encodePacked(name_S, symbol_S,_decimals));
        assembly {
            stoken := create2(0, add(bytecode_S, 32), mload(bytecode_S), salt_S)
        }
        SToken(stoken).initialize(string(name_S),string(symbol_S),_decimals);

        debtToken = DToken(dtoken);
        stableToken = SToken(stoken);
    }

}

pragma solidity ^0.5.16;

/**
  * @title Careful Math
  * @author Utopia
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity ^0.5.16;

import "./DTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./Ownable.sol";
import "./IUtopiaToken.sol";
import "./SafeMath.sol";

contract DToken is Ownable, DTokenInterface, Exponential, TokenErrorReporter {
    using SafeMath for uint;
    modifier onlyCDP() {
        require(cdp == _msgSender(), "Ownable: caller is not the cdp");
        _;
    }

    function initialize(string memory name_,
                        string memory symbol_,
                        uint8 decimals_,
                        address owner_,
                        address cdp_,
                        address uc_) public {
        require(msg.sender == owner(), "only _owner may initialize the market");
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        transferOwnership(owner_);
        cdp = cdp_;
        uc = uc_;
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    function _setUcRewardPerBlock(uint _ucReward) external onlyOwner {
        updatePool();
        ucPerBlock = _ucReward;
    }

    function pendingUtopia(address _user)
        external
        view
        returns (uint256)
    {
        uint _accPerShare = accPerShare;
        if (block.number > lastRewardBlock && totalSupply != 0) {
            uint256 blockDelta = block.number.sub(lastRewardBlock);
            uint256 ucReward_e12 = blockDelta.mul(ucPerBlock).mul(1e12);
            _accPerShare = ucReward_e12.div(totalSupply).add(_accPerShare);
        }
        return uint(accountTokens[_user]).mul(_accPerShare).div(1e12).sub(
                    accountUcDebts[_user]
                );
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock)
            return;
        if (totalSupply == 0)
            return;  
        uint256 blockDelta = block.number.sub(lastRewardBlock);
        uint256 ucReward_e12 = blockDelta.mul(ucPerBlock).mul(1e12);
        accPerShare = ucReward_e12.div(totalSupply).add(accPerShare);
        lastRewardBlock = block.number;
    }    

    function mint(address minter,uint mintAmount) external onlyCDP nonReentrant {
        updatePool();
        if (accountTokens[minter] > 0) {
            uint256 pending =
                accountTokens[minter].mul(accPerShare).div(1e12).sub(
                    accountUcDebts[minter]
                );
            if (pending > 0) {
                IUtopiaToken(uc).issueTo(minter, pending);
            }
        }
        MathError mathError;
        (mathError,totalSupply) = addUInt(totalSupply,mintAmount);
        require(mathError == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");
        (mathError,accountTokens[minter]) = addUInt(accountTokens[minter],mintAmount);
        require(mathError== MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");
        emit Mint(minter, mintAmount);
        accountUcDebts[minter] = uint(accountTokens[minter])
            .mul(accPerShare)
            .div(1e12);
    }

    function burn(address burner,uint burnAmount) external onlyCDP nonReentrant {
        updatePool();
        if (accountTokens[burner] > 0) {
            uint256 pending =
                accountTokens[burner].mul(accPerShare).div(1e12).sub(
                    accountUcDebts[burner]
                );
            if (pending > 0) {
                IUtopiaToken(uc).issueTo(burner, pending);
            }
        }
        if (burnAmount == 0){
            return;
        }
        MathError mathError;
        (mathError,totalSupply) = subUInt(totalSupply,burnAmount);
        require(mathError == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");
        (mathError,accountTokens[burner]) = subUInt(accountTokens[burner],burnAmount);
        require(mathError== MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");
        emit Burn(burner, burnAmount);
        accountUcDebts[burner] = uint(accountTokens[burner])
            .mul(accPerShare)
            .div(1e12);        
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}

pragma solidity ^0.5.16;

import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";

contract DTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    mapping (address => uint) public accountUcDebts;
    
    address public cdp;

    address public uc;

    uint public lastRewardBlock;

    uint public ucPerBlock;

    uint public accPerShare;
}

contract DTokenInterface is DTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isDToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Burn(address redeemer, uint burnAmount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    /*** User Interface ***/

    function balanceOf(address owner) external view returns (uint);
}

pragma solidity ^0.5.16;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

contract UctrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.5.16;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Utopia
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity ^0.5.16;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Utopia
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.5.16;

interface IHarvest {
    function _withdrawFromReinvestStrategy() external;
}

pragma solidity 0.5.16;

interface IUtopiaToken {
    function issueTo(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

pragma solidity ^0.5.16;

contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    function getMintRate(uint cash, uint borrows, uint reserves) external view returns (uint);

}

pragma solidity ^0.5.16;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
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
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.16;

import "./UToken.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    function getUnderlyingPrice(UToken uToken) external view returns (uint);
}

pragma solidity ^0.5.16;

import "./STokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./Ownable.sol";

contract SToken is Ownable, STokenInterface, Exponential, TokenErrorReporter {

    function initialize(string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        require(msg.sender == owner(), "only _owner may initialize the market");
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Do not allow self-transfers */
        if (src == dst) {
            return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        MathError mathErr;
        uint allowanceNew;
        uint srcTokensNew;
        uint dstTokensNew;

        (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
        require(mathErr == MathError.NO_ERROR,"allowanceNew error");

        (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
        require(mathErr == MathError.NO_ERROR,"srcTokensNew error");

        (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
        require(mathErr == MathError.NO_ERROR,"dstTokensNew error");

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != uint(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        // unused function
        // comptroller.transferVerify(address(this), src, dst, tokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    function mint(address minter,uint mintAmount) external onlyOwner nonReentrant {
        MathError mathError;
        (mathError,totalSupply) = addUInt(totalSupply,mintAmount);
        require(mathError == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");
        (mathError,accountTokens[minter]) = addUInt(accountTokens[minter],mintAmount);
        require(mathError== MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");
        emit Mint(minter, mintAmount);
        emit Transfer(address(this), minter, mintAmount);
    }

    function burn(address burner,uint burnAmount) external onlyOwner nonReentrant {
        MathError mathError;
        (mathError,totalSupply) = subUInt(totalSupply,burnAmount);
        require(mathError == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");
        (mathError,accountTokens[burner]) = subUInt(accountTokens[burner],burnAmount);
        require(mathError== MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");
        emit Burn(burner, burnAmount);
        emit Transfer(burner,address(this), burnAmount);
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}

pragma solidity ^0.5.16;

import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";

contract STokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;
}

contract STokenInterface is STokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isSToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount);

    /**
     * @notice Event emitted when tokens are burn
     */
    event Burn(address burner, uint burnAmount);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
}

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
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

pragma solidity ^0.5.16;

import "./UToken.sol";

contract UEther is UToken {

    constructor(address cdp_,
                address uc_,
                uint ucPerBlock_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) public {
        super.initialize(cdp_, uc_, ucPerBlock_, name_, symbol_, decimals_);
    }

    function syncInternal() internal {
        uint balanceOf = address(this).balance;
        if (balanceOf >= totalCash) {
            totalCash = balanceOf;
        }
    } 

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable {
        mintInternal(msg.sender,msg.value);
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     */
    function redeem(uint redeemTokens) external{
        redeemInternal(msg.sender, redeemTokens);
    }

    function liquidate(address usr, address dst) external{
        liquidateInternal(usr, dst);
    }

    /**
     * @notice Send Ether to CEther to mint
     */
    function () external payable {
        mintInternal(msg.sender,msg.value);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of Ether, before this message
     * @dev This excludes the value of the current message, if any
     * @return The quantity of Ether owned by this contract
     */
    function getCashPrior() internal view returns (uint) {
        uint startingBalance = address(this).balance.sub(msg.value);
        return startingBalance;
    }

    /**
     * @notice Perform the actual transfer in, which is a no-op
     * @param from Address sending the Ether
     * @param amount Amount of Ether being sent
     * @return The actual amount of Ether transferred
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }

    function doTransferOut(address payable to, uint amount) internal {
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
    }
}

pragma solidity ^0.5.16;

import "./UTokenInterfaces.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./Ownable.sol";
import "./CDP.sol";
import "./Uctroller.sol";
import "./SafeMath.sol";
import "./IUtopiaToken.sol/";
import "./IHarvest.sol/";

contract UToken is Ownable, UTokenInterface{
    using SafeMath for uint;

    function initialize(address cdp_,
                        address uc_,
                        uint ucPerBlock_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        require(msg.sender == owner(), "only admin may initialize the market");
        cdp = cdp_;
        uc = uc_;
        ucPerBlock = ucPerBlock_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        lastRewardBlock = block.number;
        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    function _sync() external {
        syncInternal();
    }

    function _setUcRewardPerBlock(uint _ucReward) onlyOwner external {
        updatePool();
        ucPerBlock = _ucReward;
    }

    function _setReinvestStrategy(address payable _harvest,uint _maxRate,uint _minAmount) onlyOwner external {
        harvest = _harvest;
        maxRate = _maxRate;
        minAmount = _minAmount;
    }

    function _reinvest(uint amount) external {
        require(msg.sender == harvest,"forbidden");
        uint curBalance = getCashPrior();
        require(amount.mul(10000).div(curBalance) < maxRate, "error : maxRate");
        require(curBalance.sub(amount) > minAmount,"error: minAmount");
        doTransferOut(harvest, amount);
    }

    function transferTokens(address spender, address src, address dst, uint tokens) internal {
        require(CDP(cdp).mintBalanceStored(src) == 0, "src mints not 0");
        if (src == dst) {
            return;
        }

        if (accountTokens[src] > 0){
            uint pending = accountTokens[src].mul(accPerShare).div(1e12).sub(accountUcDebts[src]);
            if (pending > 0){
                IUtopiaToken(uc).issueTo(src, pending);
            }
        }
        if (accountTokens[dst] > 0){
            uint pending = accountTokens[dst].mul(accPerShare).div(1e12).sub(accountUcDebts[dst]);
            if (pending > 0) {
                IUtopiaToken(uc).issueTo(dst, pending);
            }
        }        

        uint startingAllowance = 0;
        if (spender == src || spender == cdp) {
            startingAllowance = uint(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        uint allowanceNew = startingAllowance.sub(tokens);
        uint srcTokensNew = accountTokens[src].sub(tokens);
        uint dstTokensNew = accountTokens[dst].add(tokens);

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        if (startingAllowance != uint(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        accountUcDebts[src] = accountTokens[src].mul(accPerShare).div(1e12);
        accountUcDebts[dst] = accountTokens[dst].mul(accPerShare).div(1e12);

        emit Transfer(src, dst, tokens);
    }

     /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external nonReentrant {
        updatePool();
        transferTokens(msg.sender, msg.sender, dst, amount);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(address src, address dst, uint256 amount) external nonReentrant{
        updatePool();
        transferTokens(msg.sender, src, dst, amount);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    function balanceOfUnderlying(address owner) external view returns(uint){
        return accountTokens[owner].mul(totalCash).div(totalSupply);
    }

    function getCash() external view returns (uint) {
        return totalCash;
    }

    function getCashActual() external view returns (uint) {
        return getCashPrior();
    }

    function pendingUtopia(address _user)
        external
        view
        returns (uint256)
    {
        uint _accPerShare = accPerShare;
        if (block.number > lastRewardBlock && totalSupply != 0) {
            uint256 blockDelta = block.number.sub(lastRewardBlock);
            uint256 ucReward_e12 = blockDelta.mul(ucPerBlock).mul(1e12);
            _accPerShare = ucReward_e12.div(totalSupply).add(_accPerShare);
        }
        return uint(accountTokens[_user]).mul(_accPerShare).div(1e12).sub(
                    accountUcDebts[_user]
                );
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock)
            return;
        if (totalSupply == 0)
            return;        
        uint blockDelta = block.number.sub(lastRewardBlock);
        uint ucReward_e12 = blockDelta.mul(ucPerBlock).mul(1e12);
        accPerShare = ucReward_e12.div(totalSupply).add(accPerShare);
        lastRewardBlock = block.number;
    }


    function mintInternal(address minter, uint mintAmount) internal nonReentrant {
        CDP(cdp).accrue();
        updatePool();
        if (accountTokens[minter] > 0){
            uint pending = accountTokens[minter].mul(accPerShare).div(1e12).sub(accountUcDebts[minter]);
            if(pending > 0){
                IUtopiaToken(uc).issueTo(minter, pending);
            }
        }
        mintAmount = doTransferIn(minter, mintAmount);
        uint mintTokens;
        if (totalSupply == 0){
            mintTokens = mintAmount;
            totalSupply = totalSupply.add(mintAmount);
            totalCash = mintAmount;
            accountTokens[minter] = accountTokens[minter].add(mintAmount);
        } else {
            uint mintAmount_995 = mintAmount.mul(995).div(1000);
            totalCash = totalCash.add(mintAmount.sub(mintAmount_995));
            mintTokens = totalSupply.mul(mintAmount_995).div(totalCash); 
            totalCash = totalCash.add(mintAmount_995);
            totalSupply = totalSupply.add(mintTokens);
            accountTokens[minter] = accountTokens[minter].add(mintTokens);
        }
        accountUcDebts[minter] = accountTokens[minter].mul(accPerShare).div(1e12);
        emit Mint(minter, mintTokens);
        emit Transfer(address(this), minter, mintTokens);
    }

    function redeemInternal(address payable redeemer, uint redeemTokens) internal nonReentrant {
        CDP(cdp).accrue();
        updatePool();
        if (accountTokens[redeemer] > 0){
            uint pending = accountTokens[redeemer].mul(accPerShare).div(1e12).sub(accountUcDebts[redeemer]);
            if (pending > 0) {
                IUtopiaToken(uc).issueTo(redeemer, pending);
            }
        }
        if (redeemTokens == 0){
            return;
        }
        uint redeemAmount = redeemTokens.mul(totalCash).div(totalSupply);
        if(redeemAmount > getCashPrior()){
            IHarvest(harvest)._withdrawFromReinvestStrategy();
        }
        doTransferOut(redeemer, redeemAmount);
        totalSupply = totalSupply.sub(redeemTokens);
        accountTokens[redeemer] = accountTokens[redeemer].sub(redeemTokens);
        accountUcDebts[redeemer] = accountTokens[redeemer].mul(accPerShare).div(1e12);
        totalCash = totalCash.sub(redeemAmount);
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemTokens);

        uint mints = CDP(cdp).mintBalanceStored(redeemer);
        bool isSafe = Uctroller(CDP(cdp).uctroller()).isUsrSafety(redeemer, mints);
        require(isSafe, "isSafe error");
    }

    function liquidateInternal(address src, address dst) internal {
        require(msg.sender == cdp, "forbidden");
        updatePool();

        transferTokens(msg.sender, src, dst, accountTokens[src]);
    }

    function syncInternal() internal;

    function getCashPrior() internal view returns (uint);

    function doTransferIn(address from, uint amount) internal returns (uint);

    function doTransferOut(address payable to, uint amount) internal;


    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

pragma solidity ^0.5.16;

import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";

contract UTokenStorage {

    bool internal _notEntered;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint public totalSupply;

    uint public totalCash;

    mapping (address => uint) internal accountTokens;

    mapping (address => uint) public accountUcDebts;

    mapping (address => mapping (address => uint)) internal transferAllowances;

    address public cdp;

    address public uc;

    uint public lastRewardBlock;

    uint public ucPerBlock;

    uint public accPerShare;

    address payable public harvest;

    uint public minAmount;

    uint public maxRate;
}

contract UTokenInterface is UTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isUToken = true;


    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    /*** User Interface ***/
    function balanceOf(address owner) external view returns (uint);
    function getCash() external view returns (uint);
}

contract UErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

contract UErc20Interface is UErc20Storage {

    /*** User Interface ***/
    function mint(uint mintAmount) external;
    function redeem(uint redeemTokens) external;
    function liquidate(address src, address payer) external;
}

pragma solidity ^0.5.16;

import "./UctrollerStorage.sol";
import "./ErrorReporter.sol";
import "./PriceOracle.sol";
import "./Exponential.sol";
import "./CarefulMath.sol";


contract Uctroller is CarefulMath, Ownable, Exponential, UctrollerStorage, UctrollerErrorReporter{
    /// @notice Emitted when an admin supports a market
    event MarketListed(address uToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address uToken, address account);

    event MarketExited(address uToken, address account);

    constructor(uint _maxAssets, address _oralce) public {
        maxAssets = _maxAssets;
        oralce = _oralce;
    }

    function getUtokensLength() external view returns(uint){
        return uTokens.length;
    }

    function getAllUtokens() public view returns (UToken[] memory) {
        return uTokens;
    }

    function getUserUtokens(address usr) public view returns(UToken[] memory){
        return accountAssets[usr];
    }

    function getStablePrice() public view returns(uint){
        uint decimal = stableToken.decimals();
        return 10**18 * (10**6) / (10**decimal);
    }

    function getAllUTokenValue() external view returns(uint value) {
        return getAllUTokenValueInternal();
    }

    function getAllUTokenValueInternal() internal view returns(uint value) {
        uint len = uTokens.length;
        for (uint i = 0; i < len; i++){
            UToken uToken = uTokens[i];
            uint cash = uToken.getCash();
            if (cash > 0 ) {
                uint price = PriceOracle(oralce).getUnderlyingPrice(uToken);
                value += cash * price;
            }
        }
    }

    function getUsrUTokenValue(address usr) external view returns(uint value){
        return getUsrUTokenValueInternal(usr);
    }

    function getUsrUTokenValueInternal(address usr) internal view returns(uint value){
        UToken[] memory uTokens = accountAssets[usr];
        uint len = uTokens.length;
        for (uint i = 0; i < len; i++){
            UToken uToken = uTokens[i];
            uint amount = uToken.balanceOfUnderlying(usr);
            if (amount > 0 ) {
                uint price = PriceOracle(oralce).getUnderlyingPrice(uToken);
                value += amount * price;
            }
        }
    }

    function getUsrSTokenValue(address usr) external view returns(uint value){
        uint amount = stableToken.balanceOf(usr);
        if (amount > 0 ) {
            uint price = getStablePrice();
            value += amount * price;
        }
    }

    function isSystemSafety(uint mints, uint totalMints) external view returns(bool) {
        uint totalValue_u = getAllUTokenValueInternal();
        uint price = getStablePrice();
        uint totalValue_mints = (mints + totalMints) * price;
        (MathError mathErr, uint rate) = divUInt((totalValue_u * factor_10000),totalValue_mints);
        require(mathErr == MathError.NO_ERROR,"divUInt error");
        if (rate > minSystemSafeRate) {
            return true;
        } else {
            return false;
        }
    }

    function isAllowMintStableCoin(address usr,uint mints,uint amount) public view returns(bool) {
        uint value_u = getUsrUTokenValueInternal(usr);
        uint price = getStablePrice();
        /**
            usrTotalMint = mints + amount
            usrTotalMintValue = usrtotalMint * price 
            rate = value_u / usrtotalMintValue
         */
        MathError mathErr;
        uint usrTotalMintValue;
        uint rate;
        (mathErr, usrTotalMintValue) = mulUInt((amount + mints), price);
        require(mathErr == MathError.NO_ERROR,"mulUInt error");
        (mathErr, rate)= divUInt((value_u * factor_10000), usrTotalMintValue);
        require(mathErr == MathError.NO_ERROR,"divUInt error");
        if(rate > mincollateraRate){
            return true;
        } else {
            return false;
        }
    }

    function isUsrSafety(address usr, uint mints) external view returns (bool){
        return isAllowMintStableCoin(usr, mints, 0);
    }

    function isAllowLiquidate(address usr, uint totalMints) external view returns(bool) {
        uint value_u = getUsrUTokenValueInternal(usr);
        uint price = getStablePrice();

        MathError mathErr;
        uint usrTotalMintValue;
        uint rate;
        (mathErr, usrTotalMintValue) = mulUInt(totalMints, price);
        require(mathErr == MathError.NO_ERROR,"mulUInt error");
        (mathErr, rate) = divUInt((value_u * factor_10000), usrTotalMintValue);
        require(mathErr == MathError.NO_ERROR,"divUInt error");
        if(rate < mincollateraRate){
            return true;
        }
        return false;
    }

    function liquidateState(address moatPool, address reservePool, address liquidater, uint mints) external view returns(uint,address){
        uint moatAmount_u = stableToken.balanceOf(moatPool);
        uint reserveAmount_u = stableToken.balanceOf(reservePool);
        uint liquidaterAmount_u = stableToken.balanceOf(liquidater);
        if (mints <= moatAmount_u) {
            return (1, moatPool);
        } else if (mints <= reserveAmount_u) {
            return (2, reservePool);
        } else if (mints <= liquidaterAmount_u) {
            return (3, liquidater);
        } else {
            revert();
        }

    }

    function enterMarkets(address[] calldata uTokens) external returns (uint[] memory) {
        uint len = uTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            UToken uToken = UToken(uTokens[i]);

            results[i] = uint(addToMarketInternal(uToken, msg.sender));
        }

        return results;
    }
    function addToMarketInternal(UToken uToken, address minter) internal returns (Error) {
        Market storage marketToJoin = markets[address(uToken)];

        if (!marketToJoin.isListed) {
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[minter] == true) {
            return Error.NO_ERROR;
        }

        if (accountAssets[minter].length >= maxAssets)  {
            return Error.TOO_MANY_ASSETS;
        }
        marketToJoin.accountMembership[minter] = true;
        accountAssets[minter].push(uToken);

        emit MarketEntered(address(uToken), minter);

        return Error.NO_ERROR;
    }

    function exitMarket(address uTokenAddress) external {
        UToken uToken = UToken(uTokenAddress);
        uint balanceOf = uToken.balanceOf(msg.sender);

        require(balanceOf == 0, "balanceOf error");

        Market storage marketToExit = markets[uTokenAddress];

        require(marketToExit.accountMembership[msg.sender] == true, "accountMembership error");

        delete marketToExit.accountMembership[msg.sender];

        UToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (address(userAssetList[i]) == uTokenAddress) {
                assetIndex = i;
                break;
            }
        }

        assert(assetIndex < len);

        UToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(uTokenAddress, msg.sender);
    }

    function _supportMarket(UToken uToken) onlyOwner external returns (uint) {
        if (markets[address(uToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        uToken.isUToken();

        markets[address(uToken)] = Market({isListed: true, collateralFactorMantissa: 0});

        _addMarketInternal(address(uToken));

        emit MarketListed(address(uToken));

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address uToken) internal {
        for (uint i = 0; i < uTokens.length; i ++) {
            require(uTokens[i] != UToken(uToken), "utoken already added");
        }
        uTokens.push(UToken(uToken));
    }

    function _changeMaxAssets(uint _maxAssets) onlyOwner external{
        maxAssets = _maxAssets;
    }

    function _changeMinCollateraRate(uint _mincollateraRate) onlyOwner external {
        mincollateraRate = _mincollateraRate;
    }

    function _changeMinSystemSafeRate(uint _minSystemSafeRate) onlyOwner external {
        minSystemSafeRate = _minSystemSafeRate;
    }

    function _changeOracle(address _oracle) onlyOwner external {
        oralce = _oracle;
    }

    function _resetTokens(address _dToken,address _sToken) onlyOwner external {
        debtToken = DToken(_dToken);
        stableToken = SToken(_sToken);
    }

    function _setStableUToken(address _stablePriceAddress) onlyOwner external {
        stablePriceAddress = _stablePriceAddress;
    }
}

pragma solidity ^0.5.16;

import "./UToken.sol";
import "./DToken.sol";
import "./SToken.sol";

contract UctrollerStorage {
    struct Market {
        bool isListed;

        uint collateralFactorMantissa;

        mapping(address => bool) accountMembership;
    }

    mapping(address => Market) public markets;

    uint public maxAssets;

    address public oralce;

    uint public factor_10000 = 10000;

    uint public mincollateraRate = 11000;

    uint public minSystemSafeRate = 15000;

    mapping(address => UToken[]) public accountAssets;

    UToken[] public uTokens;

    SToken public stableToken;

    DToken public debtToken;

    address public stablePriceAddress;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}