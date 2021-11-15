// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ForgeInterface.sol";
import "./interfaces/ModelInterface.sol";
import "./interfaces/PunkRewardPoolInterface.sol";
import "./interfaces/ReferralInterface.sol";
import "./Ownable.sol";
import "./ForgeStorage.sol";
import "./libs/Score.sol";
import "./Referral.sol";

contract Forge is ForgeInterface, ForgeStorage, Ownable, Initializable, ERC20, ReentrancyGuard{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint constant SECONDS_DAY = 86400;

    constructor() ERC20("PunkFinance","Forge"){}

    /**
    * Initializing Forge's Variables, If already initialized, it will be reverted.
    * 
    * @param storage_ deployed OnwableStroage's address 
    * @param variables_ deployed Variables's address 
    * @param name_ Forge's name
    * @param symbol_ Forge's symbol
    * @param model_ Address of the Model associated
    * @param token_ ERC20 Token's address
    * @param decimals_ ERC20 (tokens_)'s decimals
    */
    function initializeForge( 
            address storage_, 
            address variables_,
            string memory name_,
            string memory symbol_,
            address model_, 
            address token_,
            uint8 decimals_
        ) public initializer {

        Ownable.initialize( storage_ );
        _variables      = Variables( variables_ );

        __name          = name_;
        __symbol        = symbol_;

        _model          = model_;
        _token          = token_;
        _tokenUnit      = 10**decimals_;
        __decimals      = decimals_;

        _count          = 0;
        _totalScore     = 0;
    }
    
    /**
    * Replace the model. If model_ isn't CA(ContractAddress), it will be reverted.
    * 
    * @param model_ Address of the associated Model
    */
    function setModel( address model_ ) public OnlyAdminOrGovernance returns( bool ){
        require( Address.isContract( model_), "FORGE : Model address must be the contract address.");
        
        ModelInterface( _model ).withdrawAllToForge();
        IERC20( _token ).safeTransfer( model_, IERC20( _token ).balanceOf( address( this ) ) );
        ModelInterface( model_ ).invest();
        
        emit SetModel(_model, model_);
        _model = model_;
        return true;
    }

    /**
    * Return the withdrawable amount.
    * 
    * @param account Saver's owner address
    * @param index Saver's index
    * 
    * @return the withdrawable amount.
    */
    function withdrawable( address account, uint index ) public view override returns( uint ){
        Saver memory s = saver( account, index );
        if( s.startTimestamp > block.timestamp ) return 0;
        if( s.status == 2 ) return 0;

        uint diff = block.timestamp.sub( s.startTimestamp );
        uint count = diff.div( SECONDS_DAY.mul( s.interval ) ).add( 1 );
        count = count < s.count ? count : s.count;

        return s.mint.mul( count ).div( s.count ).sub( s.released );
    }

    /**
    * Return the number of savers created with the account.
    * 
    * @param account : Saver's owner account
    *
    * @return the number of savers created with the account.
    */
    function countByAccount( address account ) public view override returns ( uint ){ 
        return _savers[account].length; 
    }
    
    /**
    * Create Saver with ERC20 Token and set the required parameters
    *
    * This function only stores newly created Savers. The actual investment is operated on AddDeposit.
    * 
    * @param amount ERC20 Amount
    * @param startTimestamp When do you want to start receiving (unixTime:seconds)
    * @param count How often do you want to receive.
    * @param interval Number of times to receive (unit: 1 day)
    */
    function craftingSaver( uint amount, uint startTimestamp, uint count, uint interval ) public override returns( bool ){
        craftingSaver(amount, startTimestamp, count, interval, 0);
        return true;
    }

    /**
    * Create Saver with ERC20 Token and set the required parameters
    *
    * This function only stores newly created Savers. The actual investment is operated on AddDeposit.
    * 
    * @param amount ERC20 Amount
    * @param startTimestamp When do you want to start receiving (unixTime:seconds)
    * @param count How often do you want to receive.
    * @param interval Number of times to receive (unit: 1 day)
    * @param referral Referral code issued from "Referral" Contract
    */
    function craftingSaver( uint amount, uint startTimestamp, uint count, uint interval, bytes12 referral ) public override returns( bool ){
        require( amount > 0 && count > 0 && interval > 0 && startTimestamp > block.timestamp.add( 24 * 60 * 60 ), "FORGE : Invalid Parameters");
        uint index = countByAccount( msg.sender );

        _savers[ msg.sender ].push( Saver( block.timestamp, startTimestamp, count, interval, 0, 0, 0, 0, 0, 0, block.timestamp, referral ) );
        _transactions[ msg.sender ][ index ].push( Transaction( true, block.timestamp, 0 ) );
        _count++;
        
        emit CraftingSaver( msg.sender, index, amount );
        addDeposit(index, amount);
        return true;
    }
    
    /**
    * Add deposit to Saver
    * 
    * It functions to operate the actual investment.
    * It stores the amount deposited on Saver, the new score, the amount, and the timestamp added on _transactions[msg.sender]. 
    * Within 24 hours, it will be combined to the list of the latest _transactions[msg.sender].
    * 
    * @param index Saver's index
    * @param amount ERC20 Amount
    */
    function addDeposit( uint index, uint amount ) public nonReentrant override returns( bool ){
        require( saver( msg.sender, index ).startTimestamp > block.timestamp, "FORGE : Unable to deposit" );
        require( saver( msg.sender, index ).status < 2, "FORGE : Terminated Saver" );

        uint mint = 0;
        uint i = index;

        {
            // Avoid Stack Too Deep issue
            i = i + 0;
            mint = amount.mul( getExchangeRate( ) ).div( _tokenUnit );
            _mint( msg.sender, mint );
            if( _variables.reward() != address(0) ) {
                approve( _variables.reward(), mint);
                PunkRewardPoolInterface( _variables.reward() ).staking( address(this), mint, msg.sender );
            }
        }

        {
            // Avoid Stack Too Deep issue
            i = i + 0;
            uint lastIndex = transactions(msg.sender, i ).length.sub( 1 );
            if( block.timestamp.sub( transactions(msg.sender, i )[ lastIndex ].timestamp ) < SECONDS_DAY ){
                _transactions[msg.sender][ index ][ lastIndex ].amount += amount;
            }else{
                _transactions[msg.sender][ index ].push( Transaction( true, block.timestamp, amount ) );
            }
            _savers[msg.sender][i].mint += mint;
            _savers[msg.sender][i].accAmount += amount;
            _savers[msg.sender][i].updatedTimestamp = block.timestamp;
            _updateScore( msg.sender, i );
        }

        {            
            IERC20( _token ).safeTransferFrom( msg.sender, _model, amount );
            ModelInterface( _model ).invest();
            emit AddDeposit( msg.sender, index, amount );
        }

        return true;
    }
    
    /**
    * Withdraw 
    * 
    * Enter the amount of pLP token ( Do not enter ERC20 Token's Amount )
    * Withdraw excluding service fee. if saver has referral code, then discount service fee.
    *
    * @param index Saver's index
    * @param amountPlp Forge's LP Token Amount
    */
    function withdraw( uint index, uint amountPlp ) public nonReentrant override returns( bool ){
        Saver memory s = saver( msg.sender, index );
        uint withdrawablePlp = withdrawable( msg.sender, index );
        require( s.status < 2 , "FORGE : Terminated Saver");
        require( withdrawablePlp >= amountPlp, "FORGE : Insufficient Amount" );

        uint i = index;
        /* for Underlying ERC20 token */
        {
            i = i + 0;
            ( uint amountOfWithdraw, uint amountOfServiceFee, uint amountOfBuyback , uint amountOfReferral, address ref ) = _withdrawValues(msg.sender, i, amountPlp);
            
            _savers[msg.sender][i].status = 1;
            _savers[msg.sender][i].released += amountPlp;
            _savers[msg.sender][i].relAmount += amountOfWithdraw;
            _savers[msg.sender][i].updatedTimestamp = block.timestamp;
            if( _savers[msg.sender][i].mint == _savers[msg.sender][i].released ){
                _savers[msg.sender][i].status = 3;
                _totalScore = _totalScore.sub( s.score );
            }
            emit Terminate( msg.sender, index, amountOfWithdraw );

            _withdrawTo(amountOfWithdraw, msg.sender);
            _withdrawTo(amountOfServiceFee, _variables.opTreasury() );
            _withdrawTo(amountOfBuyback, _variables.treasury());
            /* If referral code is valid, referral code providers will be rewarded. */
            if( amountOfReferral > 0 && ref != address(0)){
                _withdrawTo( amountOfReferral, ref );
            }
        }

        {
            // For LP Tokens
            i = i+0;
            uint amount = amountPlp;
            uint bonus = balanceOf(address(this)).mul( amountPlp ).mul( s.score ).div( _totalScore ).div( s.mint );
            if( _variables.reward() != address(0) ) PunkRewardPoolInterface( _variables.reward() ).unstaking(address(this), amount, msg.sender );
            _burn( msg.sender, amount );
            _burn( address( this ), bonus );
        }
        return true;
    }
    
    /**
    * Terminate Saver 
    * 
    * Forcibly terminate Saver and return the deposit. However, early termination fee and service fee are charged.
    *
    * @param index Saver's index
    */
    function terminateSaver( uint index ) public nonReentrant override returns( bool ){
        require( saver( msg.sender, index ).status < 2, "FORGE : Already Terminated" );
        Saver memory s = saver( msg.sender, index );

        uint i = index;

        /* for Underlying ERC20 token */
        {   
            i = i + 0;
            (uint amountOfWithdraw, uint amountOfServiceFee, uint amountOfReferral, address ref ) = _terminateValues( msg.sender, i );
            uint remain = s.mint.sub(s.released).mul( _tokenUnit ).div( getExchangeRate() );
            require( remain >= amountOfWithdraw, "FORGE : Insufficient Terminate Fee" );
            
            _totalScore = _totalScore.sub( s.score );
            _savers[msg.sender][i].status = 2;
            _savers[msg.sender][i].updatedTimestamp = block.timestamp;   
            emit Terminate( msg.sender, index, amountOfWithdraw );

            /* the actual amount to be withdrawn. */ 
            _withdrawTo( amountOfWithdraw, msg.sender );
            /* service fee is charged. */
            _withdrawTo( amountOfServiceFee, _variables.opTreasury() );
            /* If referral code is valid, referral code providers will be rewarded. */
            if( amountOfReferral > 0 && ref != address(0)){
                _withdrawTo( amountOfReferral, ref );
            }
        }

        /* for pLP token */
        {
            i = i + 0;
            uint lp = s.mint.sub(s.released);
            uint bonus = s.mint.mul( _variables.earlyTerminateFee( address(this) ) ).div( 100 );
            if( _variables.reward() != address(0) ) PunkRewardPoolInterface( _variables.reward() ).unstaking(address(this), lp, msg.sender );

            /* If the amount is already withdrawn and the remaining amount is less than the fee, it will be reverted. */
            _burn( msg.sender, lp );
            _mint( address( this ), bonus );
            emit Bonus( msg.sender, index, bonus );
        }

        return true;
    }

    /**
    * Return the exchange rate of ERC20 Token to pLP token, utilizing the balance of the total ERC20 Token invested into the model and the total supply of pLP token.
    *
    * @return the exchange rate of ERC20 Token to pLP token
    */
    function getExchangeRate() public view override returns( uint ){
        return totalSupply() == 0 ?_tokenUnit : _tokenUnit.mul( totalSupply() ).div( ModelInterface(_model ).underlyingBalanceWithInvestment() );
    }

    /**
    * Return the bonus(ERC20) amount
    * 
    * Bonus is sum of EarlyTerminationFee 
    * 
    * @return total bonus amount
    */
    function getBonus() public view override returns( uint ){
        return balanceOf( address( this ) ).mul( _tokenUnit ).div( getExchangeRate( ) );
    }

    /**
    * Return the invested amount(ERC20)
    * 
    * @return total invested amount
    */
    function getTotalVolume() public view override returns( uint ){
        return ModelInterface(_model ).underlyingBalanceWithInvestment();
    }
  
    /**
    * Return the associated model address.
    * 
    * @return model address.
    */
    function modelAddress() public view override returns ( address ){ return _model; }

    /**
    * Return the number of all created savers, including terminated Saver
    * 
    * @return the number of all created savers
    */
    function countAll() public view override returns( uint ){ return _count; }
    
    /**
    * Return the Saver's all properties
    * 
    * @param account Saver's index
    * @param index Forge's pLP Token Amount
    *
    * @return model address.
    */
    function saver( address account, uint index ) public view override returns( Saver memory ){ return _savers[account][index]; }

    /**
    * Return deposit & withdrawn histories
    *
    * @param account Saver's index
    * @param index Forge's pLP Token Amount
    * 
    * @return deposit & withdrawn histories
    */
    function transactions( address account, uint index ) public view override returns ( Transaction [] memory ){ return _transactions[account][index]; }


    /**
    * Change the address of Variables.
    *
    * this function checks the admin address through OwnableStorage
    *
    * @param variables_ Vaiables's address
    */
    function setVariable( address variables_ ) public OnlyAdmin{
        _variables = Variables( variables_ );
    }

    /**
    * Call a function withdrawTo from Model contract
    *
    * @param amount amount of withdraw
    * @param account subject to be withdrawn to
    */
    function _withdrawTo( uint amount, address account ) private {
        ModelInterface( modelAddress() ).withdrawTo( amount, account );
    }

    /**
    * Update Saver's score
    *
    * @param account Saver's owner account
    * @param index Saver's index
    */
    function _updateScore( address account, uint index ) internal {
        Saver memory s = saver(account, index);
        uint oldScore = s.score;
        uint newScore = Score.calculate(
            s.createTimestamp, 
            s.startTimestamp, 
            _transactions[account][index],
            s.count,
            s.interval, 
            1
        );
        _savers[account][index].score = newScore;
        _totalScore = _totalScore.add( newScore ).sub( oldScore );
    }

    /**
    * Return the calculated variables needed to termiate.
    *
    * @param account Saver's owner account
    * @param index Saver's index
    *
    * @return amountOfWithdraw
    * @return amountOfServiceFee
    * @return amountOfReferral
    * @return compensation : subject to be rewarded
    */
    function _terminateValues( address account, uint index ) public view returns( uint amountOfWithdraw, uint amountOfServiceFee, uint amountOfReferral, address compensation ){
        Saver memory s = saver( account, index );
        uint tf = _variables.earlyTerminateFee(address(this));
        uint sf = _variables.serviceFee();
        uint dc = _variables.discount();
        uint cm = _variables.compensation();

        compensation = Referral(_variables.referral()).validate( s.ref );
        uint amount = s.mint.mul( _tokenUnit ).div( getExchangeRate() );

        if( compensation == address(0) ){
            uint amountOfTermiateFee = amount.mul( tf ).div( 100 );
            amountOfServiceFee = amount.mul( sf ).div( 100 );
            amountOfWithdraw = amount.sub( amountOfServiceFee ).sub( amountOfTermiateFee );
            amountOfReferral = 0;
        }else{
            uint amountOfTermiateFee = amount.mul( tf ).div( 100 );
            amountOfServiceFee = amount.mul( sf ).div( 100 );

            uint amountOfDc = amountOfServiceFee.mul( dc ).div( 100 );
            amountOfReferral = amountOfServiceFee.mul( cm ).div( 100 );
            amountOfServiceFee = amountOfServiceFee.sub( amountOfDc ).sub( amountOfReferral );
            amountOfWithdraw = amount.sub( amountOfServiceFee ).sub( amountOfTermiateFee );
        }
    }

    /**
    * Return the calculated variables needed to withdraw.
    *
    * @param account Saver's owner account
    * @param index Saver's index
    *
    * @return amountOfWithdraw
    * @return amountOfServiceFee
    * @return amountOfBuyback
    * @return amountOfReferral
    * @return compensation : subject to be rewarded
    */
    function _withdrawValues( address account, uint index, uint hope ) public view returns( uint amountOfWithdraw, uint amountOfServiceFee, uint amountOfBuyback ,uint amountOfReferral, address compensation ){
        Saver memory s = saver( account, index );
        
        uint sf = _variables.serviceFee();
        uint dc = _variables.discount();
        uint cm = _variables.compensation();

        compensation = Referral(_variables.referral()).validate( s.ref );
        amountOfBuyback = _calculateBuyback( account, index, hope );

        uint amount = hope.mul( _tokenUnit ).div( getExchangeRate() );
        uint bonus = getBonus().mul( s.score ).div( _totalScore );
        
        if( compensation == address(0) ){
            bonus = bonus.mul( hope ).div( s.mint );
            amount = amount.add(bonus);
            amountOfServiceFee = amount.mul( sf ).div( 100 );
            amountOfWithdraw = amount.sub(amountOfServiceFee).sub(amountOfBuyback);
        }else{
            bonus = bonus.mul( hope ).div( s.mint );
            amount = amount.add(bonus);
            amountOfServiceFee = amount.mul( sf ).div( 100 );
            uint amountOfDc = amountOfServiceFee.mul( dc ).div( 100 );
            amountOfReferral = amountOfServiceFee.mul( cm ).div( 100 );
            amountOfServiceFee = amountOfServiceFee.sub( amountOfDc ).sub( amountOfReferral );
            amountOfWithdraw = amount.sub(amountOfServiceFee).sub(amountOfBuyback);
        }

    }

    /**
    * Calculate the amount to buyback.
    *
    * It transfers to treasury to buyback a part of profit.
    *
    * @param account Saver's owner account
    * @param index Saver's index
    */
    function _calculateBuyback( address account, uint index, uint hope ) public view returns( uint buyback ) {
        Saver memory s = saver( account, index );
        uint br = _variables.buybackRate();
        uint balance = s.mint.mul( _tokenUnit ).div( getExchangeRate() );
        buyback = balance.sub( s.mint ).mul( hope ).mul (br ).div( s.mint ).div(100);
    }



    // Override ERC20
    function symbol() public view override returns (string memory) {
        return symbol();
    }

    function name() public view override returns (string memory) {
        return __name;
    }

    function decimals() public view override returns (uint8) {
        return __decimals;
    }

    function totalScore() public view override returns(uint256){
        return _totalScore;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Saver.sol";
import "./Variables.sol";

contract ForgeStorage{

    Variables internal _variables;
    address internal _model;
    address internal _token;
    uint internal _tokenUnit;

    string internal __name;
    string internal __symbol;
    uint8 internal __decimals;
    
    
    mapping( address => uint ) internal _tokensBalances;

    mapping( address => Saver [] ) _savers;
    mapping( address => mapping( uint => Transaction [] ) ) _transactions;

    // set to address
    uint internal _count;
    uint internal _totalScore;

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./OwnableStorage.sol";

contract Ownable{

    OwnableStorage _storage;

    function initialize( address storage_ ) public {
        _storage = OwnableStorage(storage_);
    }

    modifier OnlyAdmin(){
        require( _storage.isAdmin(msg.sender) );
        _;
    }

    modifier OnlyGovernance(){
        require( _storage.isGovernance( msg.sender ) );
        _;
    }

    modifier OnlyAdminOrGovernance(){
        require( _storage.isAdmin(msg.sender) || _storage.isGovernance( msg.sender ) );
        _;
    }

    function updateAdmin( address admin_ ) public OnlyAdmin {
        _storage.setAdmin(admin_);
    }

    function updateGovenance( address gov_ ) public OnlyAdminOrGovernance {
        _storage.setGovernance(gov_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract OwnableStorage {

    address public _admin;
    address public _governance;

    constructor() payable {
        _admin = msg.sender;
        _governance = msg.sender;
    }

    function setAdmin( address account ) public {
        require( isAdmin( msg.sender ));
        _admin = account;
    }

    function setGovernance( address account ) public {
        require( isAdmin( msg.sender ) || isGovernance( msg.sender ));
        _admin = account;
    }

    function isAdmin( address account ) public view returns( bool ) {
        return account == _admin;
    }

    function isGovernance( address account ) public view returns( bool ) {
        return account == _admin;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Referral {

    mapping( address=>bytes12 ) private _registers;
    mapping( bytes12=>address ) private _referrals;
    uint private _count;
    
    function issue(address account) public returns(bool){
        require( account != address(0x0), "REF : Account is Zero address" );
        require( _registers[account] == 0, "REF : Already Registry" );
        
        uint salt = 0;
        while( true ){
            bytes12 code = _issueReferralCode(account, salt);
            if( _referrals[code] == address(0x0) ){
                _referrals[code] = account;
                _registers[account] = code;    
                break;
            }
            salt++;
        }
        _count++;
        return true;
    }

    function _issueReferralCode( address sender, uint salt ) private pure returns( bytes12 ){
        return bytes12(bytes32(uint(keccak256(abi.encodePacked(sender, salt)))));
    }
    
    function validate( bytes12 code ) public view returns( address ){
        return _referrals[code];
    }
    
    function referralCode( address account ) public view returns( bytes12 ){
        return _registers[account];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

struct Saver{
    uint256 createTimestamp;
    uint256 startTimestamp;
    uint count;
    uint interval;
    uint256 mint;
    uint256 released;
    uint256 accAmount;
    uint256 relAmount;
    uint score;
    uint status;
    uint updatedTimestamp;
    bytes12 ref;
}

struct Transaction{
    bool pos;
    uint timestamp;
    uint amount;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./Ownable.sol";
import "./Saver.sol";

contract Variables is Ownable{

    address private _initializer;

    uint256 private _earlyTerminateFee;
    uint256 private _buybackRate;
    uint256 private _serviceFee;
    uint256 private _discount;
    uint256 private _compensation;

    address private _treasury;
    address private _opTreasury;
    address private _reward;
    address private _referral;

    bool private _initailize = false;

    mapping( address => bool ) _emergency;

    modifier onlyInitializer{
        require(msg.sender == _initializer,"VARIABLES : Not Initializer");
        _;
    }

    constructor(){
        _initializer = msg.sender;
    }

    function initializeVariables( address storage_) public onlyInitializer{
        require(!_initailize, "VARIABLES : Already Initailized");
        Ownable.initialize(storage_);
        _initailize = true;
        _serviceFee = 1;
        _earlyTerminateFee = 1;
        _buybackRate = 20;
        _discount = 5;
        _compensation = 5;
    }

    function setEarlyTerminateFee( uint256 earlyTerminateFee_ ) public OnlyGovernance {
        require(  1 <= earlyTerminateFee_ && earlyTerminateFee_ < 11, "VARIABLES : Fees range from 1 to 10." );
        _earlyTerminateFee = earlyTerminateFee_;
    }
    function setBuybackRate( uint256 buybackRate_ ) public OnlyGovernance {
        require(  1 <= buybackRate_ && buybackRate_ < 30, "VARIABLES : BuybackRate range from 1 to 30." );
        _buybackRate = buybackRate_;
    }

    function setEmergency( address forge, bool emergency ) public OnlyAdmin {
        _emergency[ forge ] = emergency;
    }

    function setTreasury( address treasury_ ) public OnlyAdmin {
        require(Address.isContract(treasury_), "VARIABLES : must be the contract address.");
        _treasury = treasury_;
    }

    function setReward( address reward_ ) public OnlyAdmin {
        require(Address.isContract(reward_), "VARIABLES : must be the contract address.");
        _reward = reward_;
    }

    function setOpTreasury( address opTreasury_ ) public OnlyAdmin {
        require(Address.isContract(opTreasury_), "VARIABLES : must be the contract address.");
        _opTreasury = opTreasury_;
    }

    function setReferral( address referral_ ) public OnlyAdmin {
        require(Address.isContract(referral_), "VARIABLES : must be the contract address.");
        _referral = referral_;
    }

    function setServiceFee( uint256 serviceFee_ ) public OnlyAdmin {
        require(  1 <= serviceFee_ && serviceFee_ < 5, "VARIABLES : ServiceFees range from 1 to 10." );
        _serviceFee = serviceFee_;
    }

    function setDiscount( uint256 discount_ ) public OnlyAdmin {
        require( discount_ + _compensation <= 100, "VARIABLES : discount + compensation <= 100" );
        _discount = discount_;
    } 

    function setCompensation( uint256 compensation_ ) public OnlyAdmin {
        require( _discount + compensation_ <= 100, "VARIABLES : discount + compensation <= 100" );
        _compensation = compensation_;
    }

    function earlyTerminateFee( ) public view returns( uint256 ){ 
        return _earlyTerminateFee;
    }

    function earlyTerminateFee( address forge ) public view returns( uint256 ){ 
        return isEmergency( forge ) ? 0 : _earlyTerminateFee;
    }

    function buybackRate() public view returns( uint256 ){ return _buybackRate; }


    function isEmergency( address forge ) public view returns( bool ){
        return _emergency[ forge ];
    }

    function treasury() public view returns( address ){
        return _treasury;
    }

    function reward() public view returns( address ){
        return _reward;
    }

    function opTreasury() public view returns( address ){
        return _opTreasury;
    }

    function referral() public view returns( address ){
        return _referral;
    }

    function serviceFee() public view returns( uint256 ){
        return _serviceFee;
    } 

    function discount() public view returns( uint256 ){
        return _discount;
    }

    function compensation() public view returns( uint256 ){
        return _compensation;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../Saver.sol";

interface ForgeInterface{

    event CraftingSaver ( address owner, uint index, uint deposit );
    event AddDeposit ( address owner, uint index, uint deposit );
    event Withdraw ( address owner, uint index, uint amount );
    event Terminate ( address owner, uint index, uint amount );
    event Bonus ( address owner, uint index, uint amount );
    event SetModel ( address from, address to );

    function modelAddress() external view returns (address);

    function withdrawable( address account, uint index ) external view returns(uint);
    function countByAccount( address account ) external view returns (uint);
    
    function craftingSaver( uint amount, uint startTimestamp, uint count, uint interval ) external returns(bool);
    function craftingSaver( uint amount, uint startTimestamp, uint count, uint interval, bytes12 referral ) external returns(bool);
    function addDeposit( uint index, uint amount ) external returns(bool);
    function withdraw( uint index, uint amount ) external returns(bool);
    function terminateSaver( uint index ) external returns(bool);

    function countAll() external view returns(uint);
    function saver( address account, uint index ) external view returns( Saver memory );
    function transactions( address account, uint index ) external view returns ( Transaction [] memory );

    function totalScore() external view returns(uint256);
    function getExchangeRate() external view returns( uint );
    function getBonus() external view returns( uint );
    function getTotalVolume( ) external view returns( uint );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface ModelInterface{

    event Invest( uint amount, uint timestamp );
    event Withdraw( uint amount, address to, uint timestamp  );

    /**
     * @dev Returns the balance held by the model without investing.
     */
    function underlyingBalanceInModel() external view returns ( uint256 );

    /**
     * @dev Returns the sum of the invested amount and the amount held by the model without investing.
     */
    function underlyingBalanceWithInvestment() external view returns ( uint256 );

    /**
     * @dev Invest uninvested amounts according to your strategy.
     *
     * Emits a {Invest} event.
     */
    function invest() external;

    /**
     * @dev After withdrawing all the invested amount, all the balance is transferred to 'Forge'.
     *
     * IMPORTANT: Must use the "OnlyForge" Modifier from "ModelStorage.sol". 
     * 
     * Emits a {Withdraw} event.
     */
    function withdrawAllToForge() external;

    /**
     * @dev After withdrawing 'amount', send it to 'Forge'.
     *
     * IMPORTANT: Must use the "OnlyForge" Modifier from "ModelStorage.sol". 
     * 
     * Emits a {Withdraw} event.
     */
    function withdrawToForge( uint256 amount ) external;

    /**
     * @dev After withdrawing 'amount', send it to 'to'.
     *
     * IMPORTANT: Must use the "OnlyForge" Modifier from "ModelStorage.sol". 
     * 
     * Emits a {Withdraw} event.
     */
    function withdrawTo( uint256 amount, address to )  external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface PunkRewardPoolInterface {
    function addForge( address forge ) external;
    function setForge( address forge, uint weight ) external;
    function getWeightRange( address forge ) external view returns( uint, uint );

    function claimPunk( ) external;
    function claimPunk( address to ) external;
    function claimPunk( address forge, address to ) external;
    function staking( address forge, uint amount ) external;
    function unstaking( address forge, uint amount ) external;
    function staking( address forge, uint amount, address from ) external;
    function unstaking( address forge, uint amount, address from ) external;
    
    function getClaimPunk( address to ) external view returns( uint );
    function getClaimPunk( address forge, address to ) external view returns( uint );
    
    function getWeightSum() external view returns( uint );
    function getWeight( address forge ) external view returns( uint );
    function getTotalDistributed( ) external view returns( uint );
    function getDistributed( address forge ) external view returns( uint );
    function getAllocation( ) external view returns( uint );
    function getAllocation( address forge ) external view returns( uint );
    function staked( address forge, address account ) external view returns( uint );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface ReferralInterface{
    function validate( bytes12 code ) external view returns( address );
    function referralCode( address account ) external view returns( bytes12 );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

library CommitmentWeight {
    
    uint constant DECIMALS = 8;
    int constant ONE = int(10**DECIMALS);

    function calculate( uint day ) external pure returns (uint){
        int x = int(day) * ONE;
        int c = 3650 * ONE;
        
        int numerator = div( div( x, c ) - ONE, sqrt( ( div( pow( x, 2 ), 13322500 * ONE ) - div( x, 1825 * ONE ) + ONE + ONE ) ) ) + div( ONE, sqrt( 2 * ONE ) );
        int denominator = ( ONE + div( ONE, sqrt( 2 * ONE ) ) );
        
        return uint( ONE + div( numerator, denominator ) );
    }
    
    function div( int a, int b ) internal pure returns ( int ){
        return ( a * int(ONE) / b );
    }
    
    function sqrt( int a ) internal pure returns ( int ){
        int s = a * int(ONE);
        if( s < 0 ) s = s * -1;
        uint k = uint(s);
        uint z = (k + 1) / 2;
        uint y = k;
        while (z < y) {
            y = z;
            z = (k / z + z) / 2;
        }
        return int(y);
    }

    function pow( int a, int b ) internal pure returns ( int ){
        return int(uint(a) ** uint(b) / uint(ONE));
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CommitmentWeight.sol";
import "../Saver.sol";

library Score {
    using SafeMath for uint;
    
    uint constant SECONDS_OF_DAY = 24 * 60 * 60;

    function _getTimes( uint createTimestamp, uint startTimestamp, uint count, uint interval ) pure private returns( uint deposit, uint withdraw, uint timeline, uint max ){
        deposit     = startTimestamp.sub( createTimestamp );
        withdraw    = SECONDS_OF_DAY.mul( count ).mul( interval );
        timeline    = deposit + withdraw;
        max         = SECONDS_OF_DAY.mul( 365 ).mul( 30 );
    }
    
    function _getDepositTransactions( uint createTimestamp, uint deposit, Transaction [] memory transactions ) private pure returns( uint depositCount, uint [] memory xAxis, uint [] memory yAxis ){
        depositCount = 0;
        yAxis = new uint [] ( transactions.length );
        xAxis = new uint [] ( transactions.length + 1 );
        
        for( uint i = 0 ; i <  transactions.length ; i++ ){
            if( transactions[i].pos ) {
                yAxis[ depositCount ] = i == 0 ? transactions[ i ].amount : transactions[ i ].amount.add( yAxis[ i - 1 ] );
                xAxis[ depositCount ] = transactions[ i ].timestamp.sub( createTimestamp );
                depositCount++;
            }
        }
        xAxis[ depositCount ] = deposit;
        
        uint tempX = 0;
        for( uint i = 1 ; i <= depositCount ; i++ ){
            tempX = tempX + xAxis[ i - 1 ];
            xAxis[ i ] = xAxis[ i ].sub( tempX );
        }
    }

    function calculate( uint createTimestamp, uint startTimestamp, Transaction [] memory transactions, uint count, uint interval, uint decimals ) public pure returns ( uint ){
        
        ( uint deposit, uint withdraw, uint timeline, uint max ) = _getTimes(createTimestamp, startTimestamp, count, interval);
        ( uint depositCount, uint [] memory xAxis, uint [] memory yAxis ) = _getDepositTransactions( createTimestamp, deposit, transactions );
        
        uint cw = CommitmentWeight.calculate( timeline.div( SECONDS_OF_DAY ) );
        
        if( max <= deposit ){
            
            uint accX = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                accX = accX.add( xAxis[ i + 1 ] );
                if( accX > max ){
                    xAxis[ i + 1 ] = max.sub( accX.sub( xAxis[ i + 1 ] ) );
                    depositCount = i + 1;
                    break;
                }
            }
            
            uint beforeWithdraw = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                beforeWithdraw = beforeWithdraw.add( yAxis[ i ].mul( xAxis[ i + 1 ] ) );
            }
            
            uint afterWithdraw = 0;
            
            return beforeWithdraw.add( afterWithdraw ).div( SECONDS_OF_DAY ).mul( cw ).div( 10 ** decimals );
            
        }else if( max <= timeline ){
            
            uint beforeWithdraw = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                beforeWithdraw = beforeWithdraw.add( yAxis[ i ].mul( xAxis[ i + 1 ] ) );
            }
            
            uint afterWithdraw = 0;
            if( withdraw > 0 ){
                uint tempY = yAxis[ depositCount - 1 ].mul( timeline.sub( max ) ).div( withdraw );
                afterWithdraw = yAxis[ depositCount - 1 ].mul( withdraw ).div( 2 );
                afterWithdraw = afterWithdraw.sub( tempY.mul( timeline.sub( max ) ).div( 2 ) );
            }
            
            return beforeWithdraw.add( afterWithdraw ).div( SECONDS_OF_DAY ).mul( cw ).div( 10 ** decimals );
            
        }else {
            
            uint beforeWithdraw = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                beforeWithdraw = beforeWithdraw.add( yAxis[ i ].mul( xAxis[ i + 1 ] ) );
            }
            
            uint afterWithdraw = yAxis[ depositCount - 1 ].mul( withdraw ).div( 2 );
            
            return beforeWithdraw.add( afterWithdraw ).div( SECONDS_OF_DAY ).mul( cw ).div( 10 ** decimals );
            
        }
        
    }
    
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
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

    constructor () {
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

import "./IERC20.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

