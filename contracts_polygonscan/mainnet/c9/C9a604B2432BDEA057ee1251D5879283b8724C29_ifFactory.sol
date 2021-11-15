pragma solidity 0.5.16;

import "./ifToken.sol";

interface EZERC20 {
    function decimals() external view returns (uint8);
    function symbol() external returns (string memory);
    function name() external returns (string memory);
}

contract ifFactory {
    using SafeMath for uint256;

    mapping(uint256 => address) public list;
    uint256 public count;

    mapping(address => address) public ifTokens;
    mapping(address => bool) public exists;

    string public name="Impermax ";
    string public prefix="im";

    address public manager;

    constructor()   public    {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(manager==address(0) || msg.sender ==  manager, "onlyManager: not allowed");
        _;
    }

    function updateManager(address _manager) onlyManager() public {
        manager=_manager;
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function createIfToken(address _underlying) onlyManager() external returns(address) {
        require(!exists[_underlying], "createIfToken: already exists.");

        EZERC20 Token = EZERC20(_underlying);

        ifToken token = new ifToken(_underlying, append(prefix, Token.symbol()), append(name, Token.name() ), msg.sender);
        exists[_underlying] = true;
        ifTokens[_underlying] = address(token);

        count = count.add(1);
        list[count] = _underlying;

        return ifTokens[_underlying];
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ImperMax {
    function getLendingPool(address) external view returns (address, address, address);
    function mint(address poolToken, uint256 amount, address to, uint256 deadline) external;
    function redeem(address poolToken, uint256 tokens, address to, uint256 deadline, bytes calldata permitData) external;
    function isStakedLPToken(address lpToken) external returns(bool);
}

interface ImperMaxBrrwble {
    function decimals() external view returns (uint8);
    function borrowRate() external view returns (uint48);
    function reserveFactor() external view returns (uint256);
    function totalBalance() external view returns (uint256);
    function totalBorrows() external view returns (uint112);
    function totalSupply() external view returns (uint256);
    function balanceOf(address from) external view returns (uint256);
    function exchangeRateLast() external view returns (uint256);
    function exchangeRate() external returns (uint256);
}

// stake Token to earn more Token
contract ifToken is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    event AddPool(uint8 _pool, address _LP, bool _toggle, uint8 _points);
    event updatePool(uint8 _pool, uint8 _points);

    event UpdateOperator(address _operator);
    event UpdateTreasury(address _treasury);
    event UpdateAdmin(address _admin);

    event UpdateWithdrawFee(uint256 _fee);
    event UpdateDepositFee(uint256 _fee);
    event UpdateManagementFee(uint256 _fee);
    event UpdatePerformanceFee(uint256 _fee);

    event AccruePerformanceFee(uint256 _fee);
    event AccrueManagementFee(uint256 _fee);

    event TotalTokenLocked(uint256 _amount);

    address public Token;

    address public treasury;
    address public operator;
    address public admin;

    uint256 public depositFeeBP;
    uint256 public withdrawFeeBP;

    uint256 public performanceFee;

    uint256 public mgmtFeeLastTime;
    uint256 public oldExchangeRate;

    uint256 public mgmtFee; // BPS, 200/10000 initially (2%)
    uint256 public oneYear = 31556952000;

    ImperMax router = ImperMax(0xfAe767b7442B65B2d5e50c59C72E79fd39f6790A);
 
    uint8 public count;

    mapping(uint8 => address) public pools;
    mapping(uint8 => bool) public settings;
    mapping(uint8 => uint256) public points;
    mapping(uint8 => bool) public exists;

    mapping(uint8 => uint256) public optimalInvest;

    // Define the impermax Token contracts
    constructor(address _token, string memory name, string memory symbol, address _treasury) ERC20Detailed(name, symbol, ImperMaxBrrwble(_token).decimals() ) public {
        depositFeeBP = 0;
        withdrawFeeBP = 0;
        operator = address(0);
        treasury = _treasury;
        performanceFee = 2000;
        mgmtFee = 20; // 2% per year
        Token = _token;
    }

    // track total deposited mai
    // track total withdrawn mai
        // total net mai
    // track current total mai 
        // net mai + (interestAccrued) = total mai

    function setPool(uint8 _pool, address _LP, bool _toggle, uint8 _points) public onlyTreasury() {
        require(!exists[_pool], "setPool: pool's already been created. Use setPoints() to update.");
        require(router.isStakedLPToken(_LP), "setPool: LP address is invalid.");

        pools[_pool] = _LP;
        settings[_pool] = _toggle;
        points[_pool] = _points;
        exists[_pool] = true;

        if(_pool > count){
            count = _pool;
        }
        emit AddPool(_pool, _LP, _toggle, _points);
    }

    function setPoints(uint8 _pool, uint8 _points) public onlyOperator() {
        points[_pool] = _points;
        emit updatePool(_pool, _points);
    }

    function runApprovals() public {
        for(uint8 i=1; i<=count; i++){
            IERC20(getBrrwable(i)).approve(address(router), 0xffffffffffffffffffffffffffffffffffff);
        }
        IERC20(Token).approve(address(router), 0xffffffffffffffffffffffffffffffffffff);
    }

    modifier onlyOperator() {
        require(operator==address(0) || msg.sender ==  operator, "onlyOperator: not allowed");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender ==  operator, "onlyTreasury: not allowed");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender ==  admin, "onlyAdmin: not allowed");
        _;
    }

    /* management & operator calls */

    function updateOperator(address _operator) public onlyAdmin() {
        operator=_operator;
        emit UpdateOperator(_operator);
    }

    function updateTreasury(address _treasury) public onlyAdmin() {
        treasury=_treasury;
        emit UpdateTreasury(_treasury);
    }

    function updateAdmin(address _admin) public onlyAdmin(){
        admin=_admin;
        emit UpdateAdmin(_admin);
    }

    function updateDepositFee(uint256 _depositFee) public onlyAdmin() {
        depositFeeBP=_depositFee;
        emit UpdateDepositFee(_depositFee);
    }

    function updateWithdrawFee(uint256 _withdrawFee) public onlyAdmin() {
        withdrawFeeBP=_withdrawFee;
        emit UpdateWithdrawFee(_withdrawFee);
    }

    function updatePerformanceFee(uint256 _perfFee) public onlyAdmin() {
        performanceFee=_perfFee;
        emit UpdatePerformanceFee(_perfFee);
    }

    function updateManagementFee(uint256 _mgmtFee) public onlyAdmin() {
        mgmtFee=_mgmtFee;
        emit UpdateManagementFee(_mgmtFee);
    }

    function rebalance() public onlyOperator() {
        pull();
        invest();
    }

    /* fee functions */

    function accrueManagementFee() public onlyOperator() {
        if(mgmtFee >0){
            uint256 totalShares = totalSupply(); // Gets the amount of maToken in existence

            uint256 currentTime = block.timestamp;

            if(mgmtFeeLastTime>1){
                uint256 timeDelta = currentTime.sub(mgmtFeeLastTime);

                uint256 feeAccrued = mgmtFee.mul(totalShares).mul(timeDelta).div(oneYear).div(10000).div(10**uint256(decimals()));
                _mint(treasury, feeAccrued);
                emit AccrueManagementFee(feeAccrued);
            }
            mgmtFeeLastTime = currentTime;
        }
    }

    function accruePerformanceFee() public onlyOperator() {
        if(performanceFee > 0){
            uint256 totalInvestable= IERC20(Token).balanceOf(address(this));
            uint256 totalTokenLocked = totalInvestable.add(checkInvestedLatest());

            uint256 totalShares = totalSupply(); // Gets the amount of maToken in existence
            uint256 exchangeRate = (totalShares).mul(1e18).div(totalTokenLocked); // this should be a ratio that increases over time.

            if(!(oldExchangeRate>1)){
                oldExchangeRate = exchangeRate;
            }

            if(oldExchangeRate == exchangeRate ){
                oldExchangeRate=exchangeRate;
                return;
            }  
            
            uint256 interestFactor;
            uint256 totalInterestAccrued;

            interestFactor = (oldExchangeRate.sub(exchangeRate) ).mul(performanceFee).div(10000);
            totalInterestAccrued = interestFactor.mul(totalShares).div(1e18);

            if(totalInterestAccrued > 0){
                _mint(treasury, totalInterestAccrued);
                emit AccruePerformanceFee(totalInterestAccrued);
                emit TotalTokenLocked(totalTokenLocked);
                oldExchangeRate= (totalSupply()).mul(1e18).div(totalTokenLocked);
            }
        }
    }

    function updateExchangeRate() internal {
        uint256 totalInvestable= IERC20(Token).balanceOf(address(this));
        uint256 totalTokenLocked = totalInvestable.add(checkInvestedLatest());
        oldExchangeRate= (totalSupply()).mul(1e18).div(totalTokenLocked);
    }

    /* utils */

    function checkUnderlyingLast(address _check, uint8 _pool) public view returns (uint256) {

        address brrwbleMai = getBrrwable(_pool);

        ImperMaxBrrwble mai = ImperMaxBrrwble(brrwbleMai);

        uint256 totalBalance = mai.totalBalance();
        uint256 totalBorrows = uint256(mai.totalBorrows());
        uint256 supply = totalBalance.add(totalBorrows);

        if(mai.balanceOf(_check) > 0 && supply > 0 ){
            return mai.balanceOf(_check).mul(supply).div(mai.totalSupply());
        }else{
            supply=0;
        }
    }

    function checkBorrowsLast(uint8 _pool) public view returns (uint256) {

        address brrwbleMai = getBrrwable(_pool);

        ImperMaxBrrwble mai = ImperMaxBrrwble(brrwbleMai);

        uint256 totalBalance = mai.totalBalance();
        uint256 totalBorrows = uint256(mai.totalBorrows());
        uint256 supply = totalBorrows;

        if(mai.balanceOf(address(this)) > 0 && supply > 0 ){
            return mai.balanceOf(address(this)).mul(supply).div(mai.totalSupply());
        }else{
            supply=0;
        }
    }

    function checkInvestedLast() public view returns (uint256){
        uint256 total;
        for(uint8 i=1; i<=count; i++){
            total=total.add(checkUnderlyingLast(address(this), i));
        }
        return total;
    }

    function getBrrwable(uint8 _pool) public view returns(address) {
        address brrwbleMai;

        if(settings[_pool]){
            (,,brrwbleMai) = router.getLendingPool(pools[_pool]);
        }else{
            (,brrwbleMai,) = router.getLendingPool(pools[_pool]);
        }
        return brrwbleMai;
    }

    function checkUserBalance() public view returns (uint256) {
        return IERC20(Token).balanceOf(msg.sender);
    }

    function checkMsgSender() public view returns (address){
        return address(msg.sender);
    }

    // needs exchangeRate() to be called beforehand. Otherwise its just approximation.
    function getLiquid() view public returns (uint256) {
        // pull as much as you can, based on totalBalance.

        uint256 total;

        // check pullable from all
        for (uint8 i=1; i<=count; i++) {
            address brrwbleMai = getBrrwable(i);
            ImperMaxBrrwble mai = ImperMaxBrrwble(brrwbleMai);

            uint256 bal = mai.balanceOf(address(this));
            uint256 totalBal = mai.totalBalance().mul(10**uint256(mai.decimals())).div(mai.exchangeRateLast());

            if(bal>2){
                if(bal >= totalBal){
                    total = total.add(totalBal.sub(1));
                } else {
                    total = total.add(bal.sub(1));
                }                
            }
            //redeem(address poolToken, uint256 tokens, address to, uint256 deadline, bytes permitData) 
        }
        return total;
    }

    function checkPoolAPR(uint8 _pool) view public returns(uint256) {

        address brrwbleMai = getBrrwable(_pool);

        ImperMaxBrrwble mai = ImperMaxBrrwble(brrwbleMai);

        uint256 borrowRate = uint256(mai.borrowRate());
        uint256 reserveFactor = mai.reserveFactor();

        uint256 totalBalance = mai.totalBalance();
        uint256 totalBorrows = uint256(mai.totalBorrows());
        uint256 supply = totalBalance.add(totalBorrows);

        uint256 supplyRate=0;

        if(supply > 1 && totalBorrows > 1 && borrowRate > 1 ){
            supplyRate = borrowRate.mul(totalBorrows).mul(1000000000000000000-reserveFactor).div(supply).div(1000000000000000000);
        }

        return supplyRate; // * 365 * 24 * 3600 to get APY
    }

    function findBestPool() view public returns(uint8) {
        
        uint8 top;
        uint256 apr;

        for(uint8 i=1; i<=count; i++){
            if(!(apr > 1)){
                top = i;
                apr = checkPoolAPR(i);
            }else{
                if(checkPoolAPR(i)>apr){
                    top = i;
                    apr = checkPoolAPR(i);
                }
            }
        }
        return top;
    }

    function currentAPY() public view returns(uint256) {
        uint256 total = 0;

        uint256 totalInvestable= IERC20(Token).balanceOf(address(this));
        uint256 totalTokenLocked = totalInvestable.add(checkInvestedLast());

        for(uint8 i=1; i<=count; i++){
            uint256 invested = checkUnderlyingLast(address(this), i);

            uint256 investedAPY;

            if(invested > 0){
                investedAPY = checkPoolAPR(i);
            }

            if(investedAPY > 0){                                                      
                total = total.add( investedAPY.mul(invested).div(totalTokenLocked) );
            }
        }

        return total;
    }

    /* mutative utils */

    function checkInvestedLatest() public returns (uint256){
        uint256 total;
        for(uint8 i=1; i<=count; i++){
            address brrwbleMai = getBrrwable(i);
            ImperMaxBrrwble mai = ImperMaxBrrwble(brrwbleMai);
            mai.exchangeRate();
            total=total.add(checkUnderlyingLast(address(this), i));
        }
        return total;
    }

    function pull() internal {
        // pull as much as you can, based on totalBalance.

        uint256 deadline = now.add(3600);

        // pull from all
        for (uint8 i=1; i<=count; i++) {
            address brrwbleMai = getBrrwable(i);
            ImperMaxBrrwble mai = ImperMaxBrrwble(brrwbleMai);

            uint256 bal = mai.balanceOf(address(this));
            uint256 totalBal = mai.totalBalance();//.div(mai.exchangeRate());

            if(bal>2){
                bytes memory nothing;
                if(bal >= totalBal){
                    router.redeem(brrwbleMai, totalBal.sub(1), address(this), deadline, nothing);
                } else {
                    router.redeem(brrwbleMai, bal.sub(1), address(this), deadline, nothing);
                }                
            }
            //redeem(address poolToken, uint256 tokens, address to, uint256 deadline, bytes permitData) 
        }
        // charge performance fee here.
    }

    function invest() internal {
        uint256 deadline = now.add(3600);

        uint256 totalPoints;
        for (uint8 i=1; i<=count; i++) {
            totalPoints=totalPoints.add(points[i]);
        }
        // balanceOf * points / totalPoints

        uint256 totalInvestable= IERC20(Token).balanceOf(address(this));
        uint256 totalBalance = totalInvestable.add(checkInvestedLatest());

        uint256 totalInvestment;

        // calculate optimal points first, then invest using those
        for (uint8 i=1; i<=count; i++) {

            uint256 thisPoints = 0;

            if(points[i] > 0 ){
                thisPoints = (totalBalance).mul(points[i]).div(totalPoints);
            }

            address brrwbleMai = getBrrwable(i);
            
            uint256 alrdyInvested = checkUnderlyingLast(address(this), i);

            if( alrdyInvested >= thisPoints ){
                optimalInvest[i] = 0;
            }else {// alreadyInvested < thisPoints
                optimalInvest[i] = thisPoints.sub(alrdyInvested);
                totalInvestment = totalInvestment.add(optimalInvest[i]);
            }
        }
            
        for (uint8 i=1; i<=count; i++) {
            // calculate pseudo points based on what's already been invested and what we want to invest.

            uint256 _invest = optimalInvest[i].mul(totalInvestable).div(totalInvestment);

            address brrwbleMai = getBrrwable(i);
            if(_invest>0){
                router.mint(brrwbleMai, _invest, address(this), deadline);
            }

            // mint(address poolToken, uint256 amount, address to, uint256 deadline) 
        }
        accrueManagementFee();
    }

    /* user functions */

    // Locks Token and mints maToken (shares)
    function enter(uint256 _amount) public {
        pull();

        uint256 totalInvestable= IERC20(Token).balanceOf(address(this));
        uint256 totalTokenLocked = totalInvestable.add(checkInvestedLatest());

        uint256 totalShares = totalSupply(); // Gets the amount of maToken in existence

        // Lock the Token in the contract
        IERC20(Token).transferFrom(msg.sender, address(this), _amount);

        accruePerformanceFee();
        if (totalShares == 0 || totalTokenLocked == 0) {
            if(depositFeeBP > 0){
                uint256 depositFee = _amount.mul(depositFeeBP).div(10000);
                _mint(treasury, depositFee);
                _mint(msg.sender, _amount.sub(depositFee));
            }else{
                _mint(msg.sender, _amount);
            }
        } else {
            uint256 maTokenAmount = _amount.mul(totalShares).div(totalTokenLocked);
            if(depositFeeBP > 0){
                uint256 depositFee = maTokenAmount.mul(depositFeeBP).div(10000);
                _mint(treasury, depositFee);
                _mint(msg.sender, maTokenAmount.sub(depositFee));
            }else{
                _mint(msg.sender, maTokenAmount);
            }
        }
        updateExchangeRate();
        invest();
    }

    // claim Token by burning maToken
    function leave(uint256 _share) public {
        require(balanceOf(msg.sender) >= _share, "leave: balance to withdraw larger than balance.");

        pull();
        if(_share>0){
            uint256 totalShares = totalSupply(); // Gets the amount of camToken in existence

            uint256 totalInvestable= IERC20(Token).balanceOf(address(this));
            uint256 totalTokenLocked = totalInvestable.add(checkInvestedLatest());

            uint256 maTokenAmount = _share.mul( totalTokenLocked ).div(totalShares);

            require(maTokenAmount<totalInvestable, "leave: Not enough liquidity to withdraw from lending market. Please try a smaller amount.");
            
            accruePerformanceFee();
            _burn(msg.sender, _share);
            if(depositFeeBP > 0){
                uint256 withdrawFee = maTokenAmount.mul(withdrawFeeBP).div(10000);
                IERC20(Token).transfer(treasury, withdrawFee);
                IERC20(Token).transfer(msg.sender, maTokenAmount.sub(withdrawFee));
            }else{
                IERC20(Token).transfer(msg.sender, maTokenAmount);
            }
            updateExchangeRate();
        }
        invest();
    }
}

pragma solidity ^0.5.0;

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
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
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
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

