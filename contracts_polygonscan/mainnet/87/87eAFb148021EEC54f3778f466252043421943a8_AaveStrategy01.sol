// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../RLib/Strategy.sol";
import "../LAave/interfaces/ILendingPool.sol";

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './ISwapStrategy01.sol';
import './IStakedToken.sol';

// SET PAIR :::
// COIN
// Aave Matic Market WBTC => STK AAVE => amWBTC 
// Aave Matic Market variable debt mWBTC => variableDebtmWBTC =>
// 0x357D51124f59836DeD84c8a1730D72B749d8BC23
struct AavePair {
    address basic;
    address am;
    address variableDebtm;
    uint256 ltv;
    uint256 liqvi;
}

contract AaveStrategy01 is Strategy {

    using StringUtilsLib for *;
    using SafeMath for uint256;

    ISwapStrategy01 Swap01 = ISwapStrategy01(0x97347e73F880bf950aC185c512146CDfc282B177);
    function set_Swap01(address _strategy) public onlyOwner() {        
        Swap01 = ISwapStrategy01(_strategy);
    }

    // AavePair storage userStaking = userStakingOf[stakingId];
    mapping(string => AavePair) public AavePairOf;

    // ADMIN ONLY
    function aave_add_coin(
            string memory name,
            address basic,
            address am,
            address variableDebtm,
            uint256 ltv,
            uint256 liqvi
        ) public onlyOwner(){
            AavePairOf[name] = AavePair ({
                basic: basic,
                am: am,
                variableDebtm: variableDebtm,
                ltv: ltv,
                liqvi: liqvi
            });
        assets.push(am);
        assets.push(variableDebtm);
    }

    // ETH
    // address public AAVE_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    // POLIGON
    address public AAVE_LENDING_POOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf; // PROXY
    address public AAVE_STAKED_TOKEN = 0x357D51124f59836DeD84c8a1730D72B749d8BC23; // MATIC

    /* ADMIN IS UExecutor */
    constructor() Admin(msg.sender) {
        // string memory name,
        // address basic,
        // address am,
        // address variableDebtm
        aave_add_coin(
            "WBTC",
            0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, // WBTC
            0x5c2ed810328349100A66B82b78a1791B101C9D61, // amWBTC
            0xF664F50631A6f0D72ecdaa0e49b0c019Fa72a8dC, // variableDebtmWBTC
            7000,
            7500
        );
    }

    // 
    // BSC + assets
    //
    ILendingPool private AaveLP = ILendingPool(AAVE_LENDING_POOL);
    IStakedToken private StakedToken = IStakedToken(AAVE_STAKED_TOKEN); // MATIC


    // TODO this istemporary ...
    address[] public assets;
    function aave_claim_matic() public onlyOwner() returns (uint256){        
        return aave_claim_matic_to(address(this));
    }
    function aave_claim_matic_to(address to) public onlyOwner() returns (uint256){
        // claim MATIC
        uint256 amount = StakedToken.getRewardsBalance(assets, to);
        StakedToken.claimRewards(assets, amount, to);
        return amount;
    }



    // MAIN
    function _aave_deposit(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        require(SToken.balanceOf(address(this)) >= tokenAmt);
        if (SToken.allowance(address(this), AAVE_LENDING_POOL) < tokenAmt) {
            require(SToken.approve(AAVE_LENDING_POOL, type(uint256).max), "approve error");
        }
        // approve
        AaveLP.deposit(AAVE.basic, tokenAmt, address(this), 0);
    }
    function _aave_withdraw(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        AaveLP.withdraw(AAVE.basic, tokenAmt, address(this));        
    }

    function _aave_borrow(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        AaveLP.borrow(AAVE.basic, tokenAmt, 2, 0, address(this));
    }

    function _aave_repay(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        require(SToken.balanceOf(address(this)) >= tokenAmt);
        if (SToken.allowance(address(this), AAVE_LENDING_POOL) < tokenAmt) {
            require(SToken.approve(AAVE_LENDING_POOL, type(uint256).max), "approve error");
        }

        // approve
        AaveLP.repay(AAVE.basic, tokenAmt, 2, address(this));
    }





    function aave_loop_deposit_001(string memory Coin) private returns(uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);

        uint256 tokenAmt = SToken.balanceOf(address(this));

        // 65% => max 70% for BTC
        _aave_deposit(Coin, tokenAmt);
        uint256 B1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, B1);

        // _aave_withdraw(Coin, B1);
        return B1;
    }
    function aave_loop_deposit_002(string memory Coin, uint256 tokenAmt) private returns(uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);

        // 65% => max 70% for BTC
        _aave_deposit(Coin, tokenAmt);
        uint256 B1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, B1);

        // _aave_withdraw(Coin, B1);
        return B1;
    }
    function _loop_deposit_x(string memory Coin, uint Count, uint256 x1) private returns (uint256) {
        for(uint256 i; i < Count; i++){
            x1 = aave_loop_deposit_002(Coin, x1);
        }
        _aave_deposit(Coin, x1);
    }

    function ok_loop_deposit_x(string memory Coin, uint Count) public onlyOwner() {
        uint256 x1 = aave_loop_deposit_001(Coin);
        _loop_deposit_x(Coin, Count, x1);
    }


    function aave_claim_matic_reinvest(string memory Coin) public onlyOwner(){

        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);

        uint256 matic = aave_claim_matic();
        if (SToken.allowance(address(this), address(Swap01)) < 1) {
            require(SToken.approve(address(Swap01), type(uint256).max), "approve error");
        }
        (uint256 amountOut) = Swap01.swapTo(Coin, matic);
        _loop_deposit_x(Coin, 7, amountOut);
    }




// !!!!!!!!!
    function test_loop_withdraw_x(string memory Coin, uint256 Amount) public onlyOwner() {
        // require(Amount >= _amount, "not enough tokens on the balance");
        (
            uint256 balance_basic,
            uint256 balance_am,
            uint256 balance_variableDebtm,
            uint256 free_to_borrow,
            uint256 free_to_withdraw 
        ) = aave_balances(Coin);
        require( free_to_withdraw > 0, "not enough tokens in the pool");

        uint loop = 0;
        uint max_loop = 30;
        bool stop = false;
        while (stop) {
           loop++;
           if (loop > max_loop) {
               stop = true;
           }
        }
        /*
        for(uint256 i; i < Count; i++){
            x1 = aave_loop_deposit_002(Coin, x1);
        }
        _aave_deposit(Coin, x1);
        */
    }


/*
    function aave_borow(uint256 tokenAmt) public onlyOwner(){
        AaveLP.borrow(STRATEGY_TOKEN, tokenAmt, 0, 0, address(0));        
    }
    function aave_repay(uint256 tokenAmt) public onlyOwner(){
        AaveLP.borrow(STRATEGY_TOKEN, tokenAmt, 0, 0, address(0));  
    }

    // +++
    function _aave_borow(uint256 tokenAmt) public onlyOwner(){
        AaveLP.borrow(STRATEGY_TOKEN, tokenAmt, 0, 0, address(0));        
    }
    function _aave_repay(uint256 tokenAmt) public onlyOwner(){
        AaveLP.borrow(STRATEGY_TOKEN, tokenAmt, 0, 0, address(0));  
    }
*/

    // +++
    /*
    function test_claim_stake_token(address[] memory assets, uint256 amount, address to) public onlyOwner(){
        StakedToken.claimRewards(assets, amount, owner);
    }
    */

    /*
    function test_aave_deposit_loop(uint256 tokenAmt) public onlyOwner(){
        
    }

    function test_aave_withdraw_loop(uint256 tokenAmt) public onlyOwner(){
        
    }
    */


/*
    function test_change_aave_address(address _AAVE_LENDING_POOL) public onlyOwner(){
        AAVE_LENDING_POOL = _AAVE_LENDING_POOL;
    }
*/



    // TODO ADD OPERATOR FUNCTION
    // create wallet ...


    // TODO ????? this is for strategy only
    // view
    // HELPERS
    string public STRATEGY_NAME = "-";
    address public STRATEGY_TOKEN = address(0);
    IERC20 private STRTOKEN = IERC20(STRATEGY_TOKEN);
    function token_info(address _user) private view returns(uint256 ST_balance, uint256 ST_allowance) {
        // STAKE_TOKEN
        ST_balance = STRTOKEN.balanceOf(_user);
        ST_allowance = STRTOKEN.allowance(_user, address(this));
    }

    // TODO ADD DESCRIPTION NAME ETC...

    // TODO private and not used ...
    // DEPOSIT OR WITHDRAW STAKE TOKEN
    function _deposit(uint256 _amount) private {
        (uint256 ST_balance, uint256 ST_allowance) = token_info(msg.sender);
        require(ST_balance >= _amount, "not enough tokens on the balance");
        require(ST_allowance >= _amount, "allowance is to low");        
        require(STRTOKEN.transferFrom(msg.sender,address(this),_amount), "transferFrom error");
    }

    // TODO THIS IS WITHDRAWAL FUNCTION
    function _withdraw(address token, uint256 _amount) private {
        IERC20 myTOKEN = IERC20(token);
        require( myTOKEN.balanceOf(address(this)) >= _amount, "not enough tokens in the pool"); // that's just incase
        require( myTOKEN.transfer(msg.sender,_amount), "transfer error"); 
    }


    // SET PAIR :::
    // COIN
    // Aave Matic Market WBTC => STK AAVE => amWBTC 
    // Aave Matic Market variable debt mWBTC => variableDebtmWBTC =>
    // 0x357D51124f59836DeD84c8a1730D72B749d8BC23
    /*
        function sendJson(string memory _function, string memory _values) public override {
            if (_function.toSlice().equals("swap".toSlice())) {
                SWAP(_values);
            } else if (_function.toSlice().equals("swap2".toSlice())) {
                SWAP2(_values);
            }
        }
    */

    /**
    function test_loop_deposit_x7(string memory Coin) public onlyOwner() {
        uint256 x1 = aave_loop_deposit_001(Coin);
        uint256 x2 = aave_loop_deposit_002(Coin, x1);
        uint256 x3 = aave_loop_deposit_002(Coin, x2);
        uint256 x4 = aave_loop_deposit_002(Coin, x3);
        uint256 x5 = aave_loop_deposit_002(Coin, x4);
        uint256 x6 = aave_loop_deposit_002(Coin, x5);
        uint256 x7 = aave_loop_deposit_002(Coin, x6);
        _aave_deposit(Coin, x7);
    }
    */



    // view #1 PRIVATE
    function aave_balances(string memory Coin) public view returns (
            uint256 balance_basic,
            uint256 balance_am,
            uint256 balance_variableDebtm,
            uint256 free_to_borrow,
            uint256 free_to_withdraw 
        ) {
        
        AavePair storage AAVE = AavePairOf[Coin];
        address _user = address(this);

        uint256 basic =         IERC20(AAVE.basic).balanceOf(_user);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);

        ( uint256 to_borrow, uint256 to_withdraw ) = aave_limits(Coin, am, variableDebtm);

        free_to_borrow = to_borrow;
        free_to_withdraw = to_withdraw;

        balance_basic = basic;
        balance_am = am;
        balance_variableDebtm = variableDebtm;

    }
    function aave_limits(string memory Coin, uint256 Amount, uint256 Variable) private view returns (
            uint256 to_borrow,
            uint256 to_withdraw 
        ) {
        AavePair storage AAVE = AavePairOf[Coin];
        uint256 ltv   =     Amount.mul(AAVE.ltv - 100).div(10000);
        uint256 liqvi =     Amount.mul(AAVE.liqvi - 100).div(10000);
        uint256 index =     Amount - Variable;
        to_borrow = ltv - index;
        to_withdraw = liqvi - index;
    }

    // view #2
    function aave_global_stats() public view returns (
        uint256 matic,
        string memory coin,
        uint256 balance_basic,
        uint256 balance_am,
        uint256 balance_variableDebtm,
        uint256 free_to_borrow,
        uint256 free_to_withdraw 
        ) {
        matic = StakedToken.getRewardsBalance(assets, address(this));

        // TODO SET IT LIKE A VALUE
        coin = "WBTC";        
        ( balance_basic,
          balance_am,
          balance_variableDebtm,
          free_to_borrow,
          free_to_withdraw ) = aave_balances(coin);

        // matic = StakedToken.getRewardsBalance(assets, address(this));
        // StakedToken.claimRewards(assets, amount, owner);
        // claimRewards(address[] memory assets, uint256 amount, address to)
        // AaveLP.deposit(STRATEGY_TOKEN, tokenAmt, address(0), 0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './interfaces/IStrategy.sol';
import './StringUtilsLib.sol';
import './Admin.sol';
abstract contract Strategy is IStrategy, Admin{
    using StringUtilsLib for *;

    /*
     *
     * EXAMPLE
     *
     */
    function getJson(string memory _function, string memory _values) view public override returns (string memory) {

        // EXAMPLE HOW BUILD JSON ...
        string memory tojson;

        // FIRST ELEMENT MAKING WITH : _JSONelement
        // tojson = JSON();
        tojson = '{';
        tojson = _JSONAddString(tojson, "test_2", _values, true);
        tojson = _JSONAddString(tojson, "test_3", _values, true);
        tojson = _JSONAddString(tojson, "test_4", _values, true);
        tojson = _JSONAddString(tojson, "test_5", _values, true);
        tojson = _JSONAddString(tojson, "test_6", _values, true);
        tojson = _JSONAddString(tojson, "test_7", _values, true);

/*
        // TEST 1
        tojson = tojson.toSlice().concat(','.toSlice())
                       .toSlice().concat(_JSONelement("test_2", _values, true).toSlice());

        tojson = tojson.toSlice().concat(','.toSlice())
                       .toSlice().concat(_JSONelement("test_3", _values, true).toSlice());

        tojson = tojson.toSlice().concat(','.toSlice())
                       .toSlice().concat(_JSONelement("test_4", _values, true).toSlice());

        tojson = tojson.toSlice().concat(','.toSlice())
                       .toSlice().concat(_JSONelement("test_5", _values, true).toSlice());

        tojson = tojson.toSlice().concat(','.toSlice())
                       .toSlice().concat(_JSONelement("test_6", _values, true).toSlice());

        tojson = tojson.toSlice().concat(','.toSlice())
                       .toSlice().concat(_JSONelement("test_7", _values, true).toSlice());
*/

        // SECOND ELEMENT MAKING WITH : _JSONadd
        // tojson = _JSONadd(tojson, 'function_value', _values, true);

    /********
        // STRING TEST
        tojson = _JSONadd(tojson, 'simple_string', "123 42 this is string ... ??? !!!", true);

        // uint to string example:
        uint256 test_uint = 70000;
        tojson = _JSONadd(tojson, 'score', string(abi.encodePacked(test_uint)), false);

        // address test
        address TESTADDRESS = address(this);
        tojson = _JSONadd(tojson, 'address', string(abi.encodePacked(TESTADDRESS)), true);
    ********/

        // COMPILE UNIG JSONcompile FUNCTION
        return JSONcompile(tojson);
    }

    // bytes memory
    /*
     *
     * if quotes
     *      "key":"value"
     * else 
     *      "key":0 or "key":{...}
     *
     */
    function _JSONAddString(string memory prev, string memory key, string memory value, bool quotes) pure internal returns (string memory) {
        // if (prev.toSlice().equals("{".toSlice())) { 
        //     return prev.toSlice().concat(_JSONelement(key, value, quotes).toSlice());
        // } else {
            return prev.toSlice().concat(','.toSlice())
                        .toSlice().concat(_JSONelement(key, value, quotes).toSlice());
        // }
    }
    function _JSONelement(string memory key, string memory value, bool quotes) pure private returns (string memory) {
        // SET VALUE
        string memory _value;
        if (quotes) {
            _value = _quotes(value);
        } else {
            _value = value;
        }
        // ADD COLON
        string memory fin = _quotes(key).toSlice().concat(':'.toSlice());
        return fin.toSlice().concat(_value.toSlice());
    }
    function _quotes(string memory value) pure internal returns (string memory) {
        string memory _value = '"'.toSlice().concat(value.toSlice());
        return _value.toSlice().concat('"'.toSlice());
    }
    function JSONcompile(string memory elements) pure internal returns (string memory) {
        string memory fin = '{'.toSlice().concat(elements.toSlice());
        return fin.toSlice().concat('}'.toSlice());
    }

    // SEND
    function sendJson(string memory _reactor) public virtual override returns (bool){
        // _reactor
        // ++++
        // if ()
        return true;
    }

    /*
    function withdrawAll() public payable onlyOwner {
        // require(payable(t1).send(address(this).balance));
    }
    */


}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from '../libraries/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
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
pragma solidity ^0.8.4;
interface ISwapStrategy01 {
    function swapToWBTC( uint256 _amountIn ) external returns(uint256 amountOut);
    function swapToDAI( uint256 _amountIn ) external returns(uint256 amountOut);
    function swapToUSDC( uint256 _amountIn ) external returns(uint256 amountOut);
    function swapByIndex( uint256 _amountIn, address _router, address[] memory path ) external returns(uint256 amountOut);
    
    function swapTo( string memory Coin, uint256 _amountIn ) external returns(uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IStakedToken {

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IStrategy {
    function getJson(string memory _function, string memory _values) external view returns (string memory);
    function sendJson(string memory _reactor) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 * @author Smart Insider <[email protected]>
 *
 * version 1.2.2
 * updated from 0.4.21 to version 0.8.4
 *
 * version 1.2.1
 * Copyright 2016 Nick Johnson
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This utility library was forked from https://github.com/Arachnid/solidity-stringutils
 * into the Modular ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * with permission. It has been updated to be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library StringUtilsLib {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint lenx) private pure {
        // Copy word-length chunks while possible
        for(; lenx >= 32; lenx -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - lenx) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & bytes32(uint(0xffffffffffffffffffffffffffffffff)) == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & bytes32(uint(0xffffffffffffffff)) == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & bytes32(uint(0xffffffff)) == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & bytes32(uint(0xffff)) == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & bytes32(uint(0xff)) == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-termintaed utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */

    function len(slice memory self) internal pure returns (uint) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        uint Len0 = 0;
        for (uint Len = 0; ptr < end; Len++) {
            Len0 = Len;
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
        return Len0;
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `rune`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint Len;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            Len = 1;
        } else if(b < 0xE0) {
            Len = 2;
        } else if(b < 0xF0) {
            Len = 3;
        } else {
            Len = 4;
        }

        // Check for truncated codepoints
        if (Len > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += Len;
        self._len -= Len;
        rune._len = Len;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint Len;
        uint Div = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint256 b = word / Div;
        if (b < 0x80) {
            ret = b;
            Len = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            Len = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            Len = 3;
        } else {
            ret = b & 0x07;
            Len = 4;
        }

        // Check for truncated codepoints
        if (Len > self._len) {
            return 0;
        }

        for (uint i = 1; i < Len; i++) {
            Div = Div / 256;
            b = (word / Div) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let lenx := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let lenx := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let lenx := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let lenx := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, lenx), keccak256(needleptr, lenx))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr)
      private
      pure
      returns (uint)
    {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 68 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    let loop := selfptr

                    for { } lt(loop, end) { } {
                        switch eq(and(mload(loop), mask), needledata)
                        case 1 {
                            ptr := loop
                            loop := end
                        }
                        case 0 {
                            loop := add(loop,1)
                        }
                    }
                    switch eq(and(mload(ptr), mask), needledata)
                    case 0 {
                        ptr := add(selfptr, selflen)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr)
      private
      pure
      returns (uint)
    {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 69 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let loop := add(selfptr, sub(selflen, needlelen))

                    for { } gt(loop, selfptr) { } {
                        switch eq(and(mload(loop), mask), needledata)
                        case 1 {
                            ptr := loop
                            loop := selfptr
                        }
                        case 0 {
                            loop := sub(loop,1)
                        }
                    }
                    switch eq(and(mload(ptr), mask), needledata)
                    case 1 {
                        ptr := add(ptr, needlelen)
                    }
                    case 0 {
                        ptr := selfptr
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint Count) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            Count++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint Len = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            Len += parts[i]._len;

        string memory ret = new string(Len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Admin {

    constructor (address _owner) {
        owner = _owner;
    }
    
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    address public receiver;
    modifier onlyReceiver() {
        require(receiver == msg.sender, "Receiver: caller is not the receiver");
        require(receiver != address(0), "Receiver: caller is not the receiver");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner() {
        address oldOwner = owner;
        require(newOwner != oldOwner, "changeOwner: the owner must be different from the current one");
        require(newOwner != address(0), "changeOwner: owner need to be different from zero address");
        receiver = newOwner;
        // emit OwnershipTransferred(oldOwner, newOwner);
    }

    function acceptOwner() public onlyReceiver() {
        address oldOwner = owner;
        address receiverOwner = receiver;
        require(receiverOwner != oldOwner, "changeOwner: the owner must be different from the current one");
        owner = receiverOwner;
        receiver = address(0);
        emit OwnershipTransferred(oldOwner, receiverOwner);
    }

    function renounceOwnership() public onlyOwner() {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipRenounced(oldOwner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

interface ILendingPoolAddressesProvider {

    function getLendingPool() external view returns (address);
    function setLendingPoolImpl(address _pool) external;

    function getLendingPoolCore() external view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) external;

    function getLendingPoolConfigurator() external view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) external;

    function getLendingPoolDataProvider() external view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) external;

    function getLendingPoolParametersProvider() external view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) external;

    function getTokenDistributor() external view returns (address);
    function setTokenDistributor(address _tokenDistributor) external;


    function getFeeProvider() external view returns (address);
    function setFeeProviderImpl(address _feeProvider) external;

    function getLendingPoolLiquidationManager() external view returns (address);
    function setLendingPoolLiquidationManager(address _manager) external;

    function getLendingPoolManager() external view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) external;

    function getPriceOracle() external view returns (address);
    function setPriceOracle(address _priceOracle) external;

    function getLendingRateOracle() external view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}