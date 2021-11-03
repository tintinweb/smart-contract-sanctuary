/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IPairToken {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}
interface IERC20 {
    
    // IERC20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // IERC20Metadata 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface IDOSC {
    function readAuthorizedAddress() external view returns (address);
    function readEndChangeTime() external view returns (uint);
    function RegisterCall(string memory scname, string memory funcname) external;
}
interface ISwapFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
library Address {
    
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    // use safeIncreaseAllowance of safeDecreaseAllowance
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CommunityIDO {
    
    // using safe transfer
    using SafeERC20 for IERC20;

    // Reentrancy Guard 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // democratic IDO
    address public addressDOSC;
    address public LastAuthorizedAddress;
    uint public LastChangingTime;

    // uint 
    uint256 public end;
    uint256 public duration;
    uint256 public constant LENNYSoldOnDateAndLocked = 25_000_000_000; // how much LENNY we pre-sale
    uint256 public CurrentLENNYSold; // how much LENNY sold on date from pre-sale
    uint256 public CurrentLENNYLocked; // how much LENNY locked from pre-sale

    uint256 public availableContribution; // maximum BUSD we want in exchange
    uint256 public ContributionBalance; // current Contribution in BUSD in SC
    uint public maxPurchasePerAddress;
    uint public minimumSuccess;

    uint public constant LENNYProvided = 50_000_000_000; // how much LENNY we provide in the LP
    uint public initialLiquidityToken; // LT received after adding the liquidity in PancakeSwap
    uint public LPTokenToRedistribute; // LT avaible to be redistributed

    uint public contractClaimId; // 
    uint public ClaimIdDev; //

    bool public liquidityDeployed; //
    bool public liquidityPairCreated;
    bool public liquidityPoolCreated;
    bool public idoAborted;
    bool public idoStopped;
    uint public timeBeforeClaim;
    uint public claimLatency; // minimum number of second between 2 claims

    address public addressLENNY; 
    address public addressBUSD; //
    address public SwapRouter; //
    address public SwapFactory; //
    address public _pairAddress; //

    // liquidity information
    uint public amountA;
    uint public amountB;
    uint public liquidity;

    // Contribution information
    struct Participant {
        address Participant;
        uint amountBUSD;
        bool tokensWithdrawn;
        uint claimId;
    }

    struct Claim {
        uint claimId;
        uint claimPercentage;
        uint amountClaimedLPToken;
        uint date;
    }

    mapping(address => Participant) private _Contributions;
    mapping(uint => Claim) private _claims;

    event ContributionsConfirmed (address Participant, uint amountBUSD);
    event ClaimConfirmed (address Participant, uint TokenClaimed);
    event ClaimLPConfirmed (address Participant, uint LPTokenClaimed);

    receive() external payable {
    }

    function BalanceETH() external view returns(uint){
        return address(this).balance;
    }

    function CheckParticipantInfo(address account) external view returns(Participant memory){
        return _Contributions[account];
    }

    function CheckClaimInfo(uint claimNumber) external view returns(Claim memory){
        return _claims[claimNumber];
    }

    function addLennyAddress(address lennyadd) external Demokratia() preIDO() {
        addressLENNY = lennyadd;
    }

    function setContractAddresses(address newBUSD, address newSwapFactory, address newSwapRouter) external Demokratia() {
        require(newBUSD != address(0), 'BUSD address must be a none 0 address');
        addressBUSD = newBUSD;

        require(newSwapFactory != address(0), 'SwapFactory address must be a none 0 address');
        SwapFactory = newSwapFactory;

        require(newSwapRouter != address(0), 'SwapRouter must be a none 0 address');
        SwapRouter = newSwapRouter;
    }

    function start() external Demokratia() preIDO() {
        end = block.timestamp + duration;
        timeBeforeClaim = block.timestamp + duration + claimLatency;
    }

    function buy(uint256 amount) external activeIDO() IDONotStopped(){

        // Verify that the sender has enough BUSD
        IERC20 BUSDSC = IERC20(addressBUSD);
        uint BUSDDecimals = amount * 10**BUSDSC.decimals();
        uint _balanceBUSD = BUSDSC.balanceOf(_msgSender());
        require(_balanceBUSD>=BUSDDecimals, "Not enough BUSD in this wallet");

        // Verify that the sender does not exceed the 
        Participant storage  _currentContribution = _Contributions[_msgSender()];
        uint _addressAvailableContribution = maxPurchasePerAddress - _currentContribution.amountBUSD;

        require(_addressAvailableContribution >= maxPurchasePerAddress && amount <= maxPurchasePerAddress, 'You can constribute a maximum of 5000 BUSD');
        // compute the amount ok token the sender can buy
        uint tokenAmount = amount;

        if(tokenAmount > _addressAvailableContribution){
            tokenAmount = _addressAvailableContribution;
        }

        if(tokenAmount > availableContribution){
            tokenAmount = availableContribution;
        }

        uint tokenAmountDecimals = tokenAmount * 10 ** BUSDSC.decimals();

        // proceed to the transfer
        BUSDSC.safeTransferFrom(_msgSender(), address(this), tokenAmountDecimals);

        // update Contribution information
        uint totalContribution = tokenAmount + _currentContribution.amountBUSD;
        _Contributions[_msgSender()] = Participant(_msgSender(), totalContribution, false, 0);
        ContributionBalance += tokenAmount;
        availableContribution -= tokenAmount;
        emit ContributionsConfirmed(_msgSender(), tokenAmount);
    }
    

    function createLiquidityPair () external postIDO() Demokratia() {
        require(!liquidityPairCreated, 'Liquidity Pair has already been created');
        ISwapFactory factorySC = ISwapFactory(SwapFactory);
        _pairAddress = factorySC.createPair(addressLENNY, addressBUSD);
        liquidityPairCreated = true;
    }

    function createLiquidityPool () external  postIDO() Demokratia() {
        require(!liquidityPoolCreated, 'Liquidity Pool already created');
        require(liquidityPairCreated, 'Liquidity Pair not yet created');

        ISwapRouter routerSC = ISwapRouter(SwapRouter);
        IERC20 BUSD = IERC20(addressBUSD);
        IERC20 lenny = IERC20(addressLENNY);
        uint decimalsBUSD = BUSD.decimals();
        uint decimalsLENNY = lenny.decimals();

        uint ContributionBalanceDecimals = ContributionBalance * 10 ** decimalsBUSD;
        uint LENNYProvidedDecimals = LENNYProvided * 10 ** decimalsLENNY;

        BUSD.safeIncreaseAllowance(SwapRouter, ContributionBalanceDecimals*2);
        lenny.safeIncreaseAllowance(SwapRouter, LENNYProvidedDecimals*2);

        uint time = block.timestamp + 300;

        (amountA, amountB, liquidity) = routerSC.addLiquidity(
            addressLENNY, addressBUSD,
            LENNYProvidedDecimals, ContributionBalanceDecimals,
            1, 1,
            address(this),
            time
        );

        liquidityPoolCreated = true;
    }

    function initializeLPToken(uint toRoundUp) external postIDO() Demokratia() {
        require(!liquidityDeployed, 'Deployment already done');
        require(liquidityPoolCreated, 'Liquidity Pool not yet created');

        IPairToken pair = IPairToken(_pairAddress);

        uint moduloValue = 10 ** 19;

        // we have to round the 
        uint  newBalance = pair.balanceOf(address(this)) - toRoundUp;
        require (newBalance % moduloValue == 0, "newBalance modulo 100  has to be 0.");
        require (toRoundUp < moduloValue, "Round up has to be less than the modulo value");

        bool isTransfered = pair.transfer(_msgSender(), toRoundUp);

        if(isTransfered){
            initialLiquidityToken = newBalance;

            timeBeforeClaim = block.timestamp + claimLatency;
            liquidityDeployed = true;

            IERC20 lennySC = IERC20(addressLENNY);
            uint8 dec = lennySC.decimals();
            CurrentLENNYLocked = LENNYSoldOnDateAndLocked * 10 ** dec;
            CurrentLENNYSold = LENNYSoldOnDateAndLocked * 10 ** dec;
        }
    }

    function withdrawLENNY() external postIDO() IDONotStopped() nonReentrant() {
        require(liquidityDeployed, 'liquidity pool is not yet deployed');
        require(CurrentLENNYSold > 0, 'All liquidity has been taken');
        Participant storage Contribution = _Contributions[_msgSender()];
        require(Contribution.amountBUSD > 0, 'only participants');
        require(!Contribution.tokensWithdrawn, 'tokens already withdrawned');

        IERC20 lennySC = IERC20(addressLENNY);
        uint lennySoldDecimals = LENNYSoldOnDateAndLocked * 10 ** (lennySC.decimals());
        uint256 TotalLENNY =  lennySoldDecimals * Contribution.amountBUSD  / ContributionBalance;

        bool isTransfered = lennySC.transfer(Contribution.Participant, TotalLENNY);
        
        if(isTransfered){
            Contribution.tokensWithdrawn = true;
            // update current situation 
            CurrentLENNYSold -= TotalLENNY;
            emit ClaimConfirmed(_msgSender(), TotalLENNY);
        }
    }

    function distributeTokens () external postIDO() IDONotStopped() {
        require(block.timestamp > timeBeforeClaim, 'You can only claim once every 3 weeks');
        uint LPTokenToRemove = 10 * initialLiquidityToken / 100;
        LPTokenToRedistribute += LPTokenToRemove;
        contractClaimId += 1;
        _claims[contractClaimId] = Claim(contractClaimId, 10, LPTokenToRemove, block.timestamp);
        timeBeforeClaim = block.timestamp + claimLatency;
    }

    function claimTokensDev () external postIDO() Demokratia() IDONotStopped() {
        require(LPTokenToRedistribute>0, 'No Tokens to redistribute');
        require(contractClaimId > ClaimIdDev, 'dev team already got the claim');

        // identify the claim id
        uint newClaim = ClaimIdDev + 1;
        Claim storage claimDev = _claims[newClaim];

        // detrmine the amount for the dev Team
        uint LPTokenToClaimDev = 2 * claimDev.amountClaimedLPToken / 5 ;

        // send the LP token to the dev team personal address
        IPairToken pair = IPairToken(_pairAddress);
        bool isTransfered = pair.transfer(_msgSender(), LPTokenToClaimDev);
        
        if(isTransfered){
            LPTokenToRedistribute -= LPTokenToClaimDev;
            ClaimIdDev = newClaim;
            emit ClaimLPConfirmed(_msgSender(), LPTokenToClaimDev);
        }
    }

    function claimTokens () external postIDO() IDONotStopped() nonReentrant() {
        require(LPTokenToRedistribute>0, 'No Tokens to redistribute');

        Participant storage Contribution = _Contributions[_msgSender()];
        require(Contribution.amountBUSD > 0, 'only Participants');
        require(contractClaimId > Contribution.claimId, 'You already got your claims');

        // identify the claim id
        uint newClaim = Contribution.claimId + 1;
        Claim storage claim = _claims[newClaim];

        // detrmine the amount to claim
        uint LPTokenToClaim =  claim.amountClaimedLPToken * (3 * Contribution.amountBUSD) / (ContributionBalance * 5);

        // send the LP token to the dev team personal address
        IPairToken pair = IPairToken(_pairAddress);
        bool isPairTransfered = pair.transfer(_msgSender(), LPTokenToClaim);

        if(isPairTransfered){
            // Claim LP tokens
            LPTokenToRedistribute -= LPTokenToClaim;
            _Contributions[_msgSender()].claimId = newClaim;
            emit ClaimLPConfirmed(_msgSender(), LPTokenToClaim);
        }

        // Claim LENNY
        IERC20 lennySC = IERC20(addressLENNY);
        uint lennySoldDecimals = LENNYSoldOnDateAndLocked * 10 ** (lennySC.decimals());

        uint LennyTokenToClaim =  lennySoldDecimals * Contribution.amountBUSD / (ContributionBalance * 10);
        lennySC.safeTransfer(_msgSender(), LennyTokenToClaim);

        CurrentLENNYLocked -= LennyTokenToClaim;
        emit ClaimConfirmed(_msgSender(), LennyTokenToClaim);          
        
    }

    function removeContribution () external postIDOFailed() nonReentrant() {

        Participant storage Contribution = _Contributions[_msgSender()];
 
        require(Contribution.amountBUSD > 0, 'only Participants');
        require(!Contribution.tokensWithdrawn, 'tokens already withdrawned');

        IERC20 BUSDSC = IERC20(addressBUSD);
        uint amountDecimals = Contribution.amountBUSD * 10 ** BUSDSC.decimals();
        bool isTransfered = BUSDSC.transfer(Contribution.Participant, amountDecimals);

        if(isTransfered){
            Contribution.tokensWithdrawn = true;
        }
    }

    function sendBackETH(address payable recipient, uint amount) external Demokratia() IDONotStopped() {
        require(recipient != address(0), 'None 0 Address');
        payable(recipient).transfer(amount);
    }

    function sendBackAnyToken(address tokenAdd, address recipient, uint amount) external Demokratia() IDONotStopped() {
        require(tokenAdd != addressLENNY, 'Can not send Lenny Through this function');
        require(tokenAdd != addressBUSD, 'Can not send BUSD Through this function');
        require(recipient != address(0), 'None 0 Address');
        IERC20 tokensc = IERC20(tokenAdd);
        tokensc.safeTransfer(recipient, amount);
    }

    function stopIDO() external Demokratia() {
        //in case of problem will pause ido until problem is resumed
        idoStopped = !idoStopped;
    }

    function abortIDO() external Demokratia() {
        //in case of problem will unlocks funds for refund
        idoAborted = true;
    }

    // Context
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // Democratic Ownership
    function UpdateSC() external {
        IDOSC dosc = IDOSC(addressDOSC);
        LastAuthorizedAddress = dosc.readAuthorizedAddress();
        LastChangingTime = dosc.readEndChangeTime();
    }

    modifier Demokratia() {
        require(LastAuthorizedAddress == _msgSender(), "You are not authorized to change");
        require(LastChangingTime >= block.timestamp, "Time for changes expired");
        _;
    }

    // IDO Periods
    modifier preIDO() {
        require(end == 0, 'Community IDO should not be active');
        _;
    }

    modifier activeIDO() {
        require(end > 0 && block.timestamp < end &&  availableContribution > 0, 'Community IDO must be active');
        _;
    }

    modifier postIDO() {
        require(end > 0 && (block.timestamp >= end || availableContribution == 0), 'Community IDO must have ended');
        require(ContributionBalance >= minimumSuccess);
        _;
    }

    modifier postIDOFailed() {
        require((end > 0 && (block.timestamp >= end || idoAborted)), 'Community IDO must have failed');
        require(ContributionBalance < minimumSuccess, 'Failed to raise minimum contribution');
        _;
    }

    modifier IDONotStopped() {
        require(!idoStopped, 'Community IDO has been pause');
        _;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(uint _IDOduration,
                uint _availableContribution,
                uint _maxPurchasePerAddress,
                uint _minimumSuccess,
                uint _claimLatency,
                address _addressBUSD,
                address _addressDOSC,
                address _SwapRouter,
                address _SwapFactory) 
                {
                duration = _IDOduration;
                availableContribution = _availableContribution;
                maxPurchasePerAddress = _maxPurchasePerAddress;
                minimumSuccess = _minimumSuccess;
                claimLatency = _claimLatency;
                addressBUSD = _addressBUSD;
                addressDOSC = _addressDOSC;
                SwapRouter = _SwapRouter;
                SwapFactory = _SwapFactory;
                _status = 1;
                }
}