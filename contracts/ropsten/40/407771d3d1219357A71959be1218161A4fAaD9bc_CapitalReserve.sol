// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./Globals.sol";
import './OFERC20.sol';
import "./FeatureControl.sol";
import "./libraries/Fractional.sol";
import "./libraries/ContinuousInterest.sol";
import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Capital Reserve
 * @notice Capital reserve in the contract that accept the user tokens (Weth, WBTC etc) 
 * Deposit them in the capital reserve and mints its own tokens (LP tokens)
 * User can transfer the LP tokens to another user
 * @dev Interest is deposited in the Allocated Interest pool by the ReserveGovernance
 * LP tokens will be minted after calculating the current value of one LP token according to capital pool balance 
 */
contract CapitalReserve is Globals, OFERC20, FeatureControl {
    
    using Fractional for uint256;
    using ContinuousInterest for ContinuousInterest.Pool;  
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ContinuousInterest.Pool continuousinterest;
    
    //capital reserve token
    IERC20 token; 
    
    IFactory factory;
    
    uint256 constant tenPOW18 = 1000000000000000000;
    uint256 public immutable interestRate;

    uint256 public maxTimeLimit;

    event DepositedToCapitalReserve(address _depositer, uint256 _amount);
    event WithdrawnFromCapitalReserve(address _withdrawer, uint256 _amount);
    
    event DepositedToInterestPool(address _depositer, uint256 _amount);
    event WithdrawnFromInterestPool(address _withdrawer, uint256 _amount);
    
    event TransactionPending(address _from, address _to, uint256 _amount, uint256 _expireTime);
    
    modifier _whiteList(address _user){
        require(factory.isWhitelisted(_user),"Factory._whitelisted : User is not In the WhiteList");
        _;
    }
    
    /** 
     * @notice constructor will set all the roles, features, ERC20 token and Interest rate to the respected value
     * @param _reserveGov : Reserve Governance of the capital reserve. Assigned in Factory contract
     * @param _regulator : Regulator Of the capital reserve. Assigned in Factory contract
     * @param _token : token like Weth,WBTC etc, that user will deposit in this reserve
     * @param _interestRate : interest rate of the reserve, Must be in the fixed point notation
     * @param _admin : deployer of the contract, Will be the address of the user who calls the deployCapitalReserve function of the Factory contract
     * @param _factory : address of the factory contract that deploy the capital reserve
     * @param _intervalSeconds : time interval after which the interest will calculate and deposit in the interest pool. Must be in seconds
     */
    constructor(address _reserveGov, address _regulator, address _token, uint256 _interestRate, address _admin, address _factory, uint _intervalSeconds) {
    	require(_token != address(0), "CapitalReserve.constructor : Token address is not set");
    	require(_interestRate != 0, "CapitalReserve.constructor : Interest rate can not be zero");
        token = IERC20(_token);    
        interestRate = _interestRate;
        continuousinterest.interestRate = _interestRate;
        continuousinterest.intervalSeconds = _intervalSeconds;

	    _setupRole(DEFAULT_ADMIN_ROLE,_admin);
	    _setupRole(DEFAULT_ADMIN_ROLE,address(_factory));
        _setupRole(ROLE_OCEAN_FALLS_GOVERNANCE , _admin);
        _setupRole(ROLE_RESERVE_GOVERNANCE , _reserveGov);
        _setupRole(ROLE_REGULATOR, _regulator);
        _setupRole(ROLE_WHITELIST_OPERATOR, _admin);
        _setupRole(ROLE_WHITELISTED_USER, _admin);
        setFeature(FEATURE_TRADING, true);        
        factory = IFactory(_factory);
    }
   
    /**
     * @notice user needs to approve sufficient tokens before calling this function
     * @dev mints sufficient amount of LP tokens according to capital reserve balance to users address
     * @param _amount : Amount of ERC20 tokens that user deposit is the capital pool and wants to get interest
     * @return function return true if executed successfully
     */
    function depositToCapitalReservePool(uint256 _amount) external _whiteList(msg.sender) returns(bool) {
                 
        token.safeTransferFrom(msg.sender,address(this),_amount);
        (uint256 _capitalBal, /* uint256 interestBal */) = continuousinterest.poolBalances();

        if(_capitalBal>0){
            uint _total = totalSupply().lpTokensForCapital(_capitalBal, _amount);
            _mint(msg.sender,_total);
        } else {
            _mint(msg.sender,_amount);
        }
        continuousinterest.increaseCapitalPoolBalance(_amount);
        emit DepositedToCapitalReserve(msg.sender, _amount);
        return true;
    }
    
    /**	
     * @notice Only Whitelist user can call this function
     * @dev LP tokens are taken from the users balance and burnt, the user is transferred token based on accumulated interest 
     * @param _amount : Amount of ERC20 deposited token that user wants to claim
     * @return function return true if executed successfully
     */
     function withdrawFromCapitalReservePool(uint256 _amount) external _whiteList(msg.sender) withFeature(FEATURE_TRADING) returns(bool) {
        (uint256 _capitalBal, /* uint256 interestBal */) = continuousinterest.poolBalances();
        uint256 _share = totalSupply().capitalForLpTokens(_capitalBal, _amount);
        token.safeTransfer(msg.sender, _share);
        _burn(msg.sender, _amount);
        continuousinterest.decreaseCapitalPoolBalance(_share);
        emit WithdrawnFromCapitalReserve(msg.sender, _amount);
        return true;
    }

    /**
     * @notice Reserve Governance can only claim tokens from interest pool that are not paid to capital pool
     * @param _amount : Amount of ERC20 tokens that reserve governance wants to withdraw from interest pool
     */
    function withdrawFromInterestPool(uint256 _amount) external onlyRole(ROLE_RESERVE_GOVERNANCE) {
        continuousinterest.decreaseInterestPoolBalance(_amount);
        token.safeTransfer(msg.sender,_amount);
        emit WithdrawnFromInterestPool(msg.sender, _amount);
    }

    /**
     * @notice only Reserve Governance can deposit funds to the Allocated Interest pool    
     * @param _amount : Amount of tokens Reserve Governance Wants to deposit in interest pool
     */
    function depositToInterestPool(uint256 _amount) external onlyRole(ROLE_RESERVE_GOVERNANCE) {
        token.safeTransferFrom(msg.sender,address(this),_amount);
        continuousinterest.increaseInterestPoolBalance(_amount);
        emit DepositedToInterestPool(msg.sender, _amount);
    }

    /**
     * @notice This function only transfer LP tokens to whitelisted user
     * @param _to : address of the receiver 
     * @param _amount: amount of LP tokens that user wants to send
     * @return success : function return true if executed successfully
     */
    function transfer(address _to, uint _amount) public override returns(bool success) {
        require(factory.isWhitelisted(_to), "CapitalReserve.transfer : receive is not whitelisted. Use safeTransfer");
        _transfer(_msgSender(), _to, _amount);
        return true;
    }
    
    /**
     * @notice if the receiver is not in the whitelist the tokens goes in the pending state    
     * @param _to : address of the receiver
     * @param _amount : amount of reserve tokens
     * @param _expireTime : time till when the receiver can claim the tokens (UNIX Timestamp)
     */
    function safeTransfer(address _to, uint256 _amount, uint256 _expireTime) external _whiteList(msg.sender) {
        require(_expireTime > block.timestamp,"CapitalReserve.safeTransfer : Invalid expire time");
        require(_expireTime-block.timestamp <= maxTimeLimit, "CapitalReserve.safeTransfer : expire time exceeds Maximum timeLimit");
        if(!factory.isWhitelisted(_to)) {
            _newPendingTransaction(msg.sender, _to, _amount, _expireTime);
            emit TransactionPending(msg.sender, _to, _amount, _expireTime);
        } else {
           _transfer(msg.sender, _to, _amount); 
        }       
    }

    /**
     * @notice returns the value stored in the Pool struct of ContinuosInterest
     * @return the ContinuosInterest type Object
     */
    function state() external view returns(ContinuousInterest.Pool memory) {
        return continuousinterest;
    }

    /**
     * @notice User can check the current values of Capital and Interest pool
     * @return capitalPool : Capital pool current balance
     * @return interestPool : Interest pool current balance
     */
    function getPoolBalances() public view returns(uint256 capitalPool, uint256 interestPool) {
        (capitalPool, interestPool) = continuousinterest.poolBalances();
    }

    /**
     * @return Interface ID
     */
    function interfaceId() external view returns(bytes4) {
        return token.totalSupply.selector ^ token.balanceOf.selector ^ token.transfer.selector ^ token.allowance.selector ^ token.approve.selector  ^ token.transferFrom.selector ;
    }    
    
    /**
     * @notice Limit Should be in seconds. 1 hour = 3600(Input value)
     * @param _limit = Maximum Time Limit allowed for the pending transactions
     */ 
    function setMaxTimeLimit(uint256 _limit) external onlyRole(ROLE_RESERVE_GOVERNANCE) {
        maxTimeLimit = _limit;
    }
    
    /**
     * @notice Only Reserve Governance can send the tokens to a user that are sent to this contract address accidentally
     * @dev Accidental tokens are those which a user sends directly to this contract address
     * @param _token : address of the ERC20 token from which the accidental transfer happened
     * @param _user : address of the user that has sent the tokens accidentally
     */ 
    function recoverAccidentalTransfer(address _token, address _user) external onlyRole(ROLE_RESERVE_GOVERNANCE) {
    	require(_token != address(0), "CapitalReserve.recoverAccidentalTransfer : Token address is invalid");
    	IERC20 temp = IERC20(_token);
    	if(temp == token){
    	    (uint256 _capitalPool, uint256 _interestPool) = continuousinterest.poolBalances();
    	    uint256 _total = _capitalPool.add(_interestPool);
    	    _total = token.balanceOf(address(this)).sub(_total);
    	    require(_total>0,"CapitalReserve.recoverAccidentalTransfer : No Accidental transfer of tokens");
    	    token.safeTransfer(_user, _total);
    	} else {
    	    require(temp.balanceOf(address(this))>0,"CapitalReserve.recoverAccidentalTransfer : No Accidental transfer of tokens");
    	    temp.safeTransfer(_user, temp.balanceOf(address(this)));
    	}
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract Globals {
    // keccak256("ROLE_OCEAN_FALLS_GOVERNANCE")
    bytes32 public constant ROLE_OCEAN_FALLS_GOVERNANCE = 0xca07b9c1a2c0f12042b730fc371fc801cef2a7d2f03d4ee553b83200ccad032b;  

    // keccak256("ROLE_RESERVE_GOVERNANCE")  
    bytes32 public constant ROLE_RESERVE_GOVERNANCE = 0x357a672225bb6aeb630226af9da3a8ee5194399a812cca8e204cc76154158d6b;       
    
    // keccak256("ROLE_REGULATOR")  
    bytes32 public constant ROLE_REGULATOR = 0x6875f2084ac6ef0df0fefc0f79fad0f79cebc70445f0963b34e72ad37013406b;             
    
    // keccak256("ROLE_WHITELIST_OPERATOR")  
    bytes32 public constant ROLE_WHITELIST_OPERATOR = 0xe0616c68c377b30cd2e1f32e28c349edb49dd408cb68b4ae4ea1d18bb7d68799;      
    
    // keccak256("ROLE_WHITELISTED_USER")
    bytes32 public constant ROLE_WHITELISTED_USER = 0xd719c281ea0ec612ab10a7c47410009934d7cfdd7ea175dda614a480727628fc;  

    // keccak256('FEATURE_TRADING') 
    bytes32 public constant FEATURE_TRADING = 0x6d549dfec25827802a4ef58e6968d93a468e7c5a4e53c662a28ca8657ca155da;              
}

//SPDX-License-Identifier: MIT;

pragma solidity 0.8.4;

import './interfaces/IOFERC20.sol';
import './libraries/HitchensUnorderedKeySet.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OFERC20 is ERC20, IOFERC20 {
    using SafeMath for uint;

    bytes32 private constant NULL_BYTES32 = bytes32(0);
    string private constant _name = 'Ocean Falls Capital Pool';
    string public constant _symbol = 'OFCP';
    uint8 public constant _decimals = 18;

    uint256 public nonce = 1;
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;

    //Struct to store the information of the pending transaction
    struct PendingTransaction {
         address sender;
         address receiver;
         uint256 amount;
         uint256 expireTime;
    }    
    mapping(bytes32 => PendingTransaction) public override pendingTransactions;
    HitchensUnorderedKeySetLib.Set pendingTransactionsSet;
    
    event LogNewPendingTransaction(bytes32 key, address sender, address reciever, uint256 balance, uint256 expiryTime);
    event LogRemPendingTransaction(address sender, bytes32 key);

    struct UserPending {
        HitchensUnorderedKeySetLib.Set pendingOut;
        HitchensUnorderedKeySetLib.Set pendingIn;
    }
    mapping(address => UserPending) userPending;

    constructor() ERC20(_name, _symbol) {}

    /**
     * @notice Transaction first needs to get expire. If the receiver does not claim it then the sender can cancel it
     * @param _txnId : Transaction Id of the pending transaction that sender of the transaction wants to cancel
     */
    function cancelPendingTransaction(bytes32 _txnId) external override virtual {
        PendingTransaction storage t = pendingTransactions[_txnId];
        require(t.sender == msg.sender, "OFERC20.cancelPendingTransaction: not transaction sender");
        require(t.expireTime < block.timestamp, "OFERC20.cancelPendingTransaction: not expired");
        require(_txnId != NULL_BYTES32, "OFERC20.cancelPendingTransaction: invalid txn id");
        _remPendingTransaction(_txnId, t.sender);
    }
    
    /**
     * @notice Receiver can only claim the transaction before it gets expire. Receiver will receive full amount of tokens that were send to him/her.    
     * @param _txnId : Transaction Id of the pending transaction that receiver wants to claim 
     */
    function claimPendingTransaction(bytes32 _txnId) external override {
        PendingTransaction storage t = pendingTransactions[_txnId];
        require(t.receiver == msg.sender, "OFERC20.claimPendingTransaction: not transaction receiver");
        require(t.expireTime >= block.timestamp, "OFERC20.cancelPendingTransaction: expired");
        require(_txnId != NULL_BYTES32, "OFERC20.claimPendingTransaction: invalid txn id");
        _remPendingTransaction(_txnId, t.receiver);
    }

    /**
     * @notice Store new pending transaction all info
     * @dev Called in safe transfer of capital reserve 
     * @param _sender : sender of the LP tokens
     * @param _receiver : receiver of the LP tokens 
     * @param _amount : amount of LP tokens that user sends to the non whitelisted user
     * @param _expiryTime : expiry time of the transaction (UNIX time stamp)
     */
    function _newPendingTransaction(address _sender, address _receiver, uint256 _amount, uint256 _expiryTime) internal {
        bytes32 key = _genId();
        PendingTransaction storage t = pendingTransactions[key];
        UserPending storage s = userPending[_sender];
        UserPending storage r = userPending[_receiver];
        s.pendingOut.insert(key);
        r.pendingIn.insert(key);
        pendingTransactionsSet.insert(key);
        t.sender = _sender;
        t.receiver = _receiver;
        t.amount = _amount;
        t.expireTime = _expiryTime;
        _transfer(_sender, address(this), _amount);
        emit LogNewPendingTransaction(key, _sender, _receiver, _amount, _expiryTime);
    }

    /**
     * @notice removes all traces of a pending transaction
     * @dev Called when a user claim or reject a pending transaction
     * @param _key : Transaction ID of the pending transaction
     * @param _user : address of the sender/receiver depending on the scenario
     */
    function _remPendingTransaction(bytes32 _key, address _user) internal {
        PendingTransaction storage t = pendingTransactions[_key];
        UserPending storage s = userPending[t.sender];
        UserPending storage r = userPending[t.receiver];
        s.pendingOut.remove(_key);
        r.pendingIn.remove(_key);
        pendingTransactionsSet.remove(_key);
        _transfer(address(this), _user, t.amount);
        delete pendingTransactions[_key];
        emit LogRemPendingTransaction(msg.sender, _key);
    }

    /**
     * @notice Generates the ID based on the contract address and number of the pending transactions send.
     * @return returns the txnID of the pending transaction
     */
    function _genId() private returns(bytes32) {
        nonce++;
        return keccak256(abi.encodePacked(address(this), nonce));
    }    

    /**
     * View functions
     */
    
    /**
     * @notice returns total count of pending transactions that a user had send and received.
     * @param _user : address of the user who sends/receives pending transaction
     * @return countOut : Total number of the pending transaction user send
     * @return countIn : Total number of the pending transactions user receive
     */
    function userPendingCount(address _user) external override view returns(uint countOut, uint countIn) {
        UserPending storage u = userPending[_user];
        countOut = u.pendingOut.count();
        countIn = u.pendingIn.count();
    }

    /**
     * @notice returns the pending transaction ID that a user has send to another user at a given Index
     * @param _user : address of the sender of pending transactions
     * @param _index : index of the pending out transaction array
     * @return txnId : pending transaction id
     */
    function userPendingOutAtIndex(address _user, uint _index) external override view returns(bytes32 txnId) {
        UserPending storage u = userPending[_user];
        txnId = u.pendingOut.keyAtIndex(_index);
    }

    /**
     * @notice returns the pending transaction ID that a user has received at a given Index
     * @param _user : address of the receiver of pending transactions
     * @param _index : index of the pending in transaction array
     * @return txnId : pending transaction id
     */
    function userPendingInAtIndex(address _user, uint _index) external override view returns(bytes32 txnId) {
        UserPending storage u = userPending[_user];
        txnId = u.pendingIn.keyAtIndex(_index);
    }

    /**
     * @notice returns true if the give transaction ID exits in a users Pending In list (array) else returns false
     * @param _user : address of the receiver of pending transactions
     * @param _txnId : Transaction Id that user wants to check, If exits or not
     * @return isPending : true if the user has a pending received transaction of the given id
     */
    function isUserPendingIn(address _user, bytes32 _txnId) external override view returns(bool isPending) {
        UserPending storage u = userPending[_user];
        isPending = u.pendingIn.exists(_txnId);
    }

    /**
     * @notice returns true if the give transaction ID exits in a users Pending Out list (array) else returns false
     * @param _user : address of the sender of pending transactions
     * @param _txnId : Transaction Id that user wants to check, If exits or not
     * @param _txnId : Transaction Id that user wants to check, If exits or not
     * @return isPending : true if the user has a pending sent transaction of the given id
     */
    function isUserPendingOut(address _user, bytes32 _txnId) external override view returns(bool isPending) {
        UserPending storage u = userPending[_user];
        isPending = u.pendingOut.exists(_txnId);
    }

    /**
     * @notice returns the total number of transactions that are pending
     * @return count : total pending transactions in the system
     */
    function pendingTxnCount() external override view returns(uint count) {
        count = pendingTransactionsSet.count();
    }
    
    /**
     * @notice returns transaction ID at the given index in pending transaction array
     * @return txnId : transaction id
     */
    function pendingTxnAtIndex(uint _index) external override view returns(bytes32 txnId) {
        txnId = pendingTransactionsSet.keyAtIndex(_index);
    }

    /**
     * @notice returns true if the given transaction Id is valid else return false
     * @return isPending : true if the transaction id is a pending transaction
     */
    function isPendingTxn(bytes32 _txnId) external override view returns(bool isPending) {
        isPending = pendingTransactionsSet.exists(_txnId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IFeatureControl is IAccessControl {
	function setFeature(bytes32 feature, bool enabled) external;
	function isEnabled(bytes32 feature) external view returns(bool);
}

contract FeatureControl is IFeatureControl, AccessControl {

	modifier withFeature(bytes32 _feature) {
		require(hasRole(_feature, address(this)), "FeatureControl.withFeature: feature disabled");
		_;
	}

	/**
	 * @inheritdoc IERC165
	 * @param interfaceId : interface ID user wants to check
	 * @return true if contract supports given interface id else false
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		 //reconstruct from current interface and super interface
		return interfaceId == type(IFeatureControl).interfaceId || super.supportsInterface(interfaceId);
	}

	/**
	 * @param _feature a feature to enable/disable
	 * @param _enabled: true: enable, false: disable
	 * @notice Removes the feature from the set of the globally enabled features
	 * @dev Requires transaction sender to have a permission to set the feature requested
	 */
	function setFeature(bytes32 _feature, bool _enabled) public override {
		if(_enabled) {
			grantRole(_feature, address(this));
		} else {
			revokeRole(_feature, address(this));
		}
	}

	/**
	 * @notice Checks if requested feature is enabled globally on the contract
	 * @param _feature the feature to check
	 * @return true if the feature requested is enabled, false otherwise
	 */
	function isEnabled(bytes32 _feature) public override view returns(bool) {
		return hasRole(_feature, address(this));
	}
}

// SPDX-License-Identifier: UNLICENSED


/**
  * @notice capital pool balance must be obtained from ContinuousInterest so is up-to-the-moment
  * @dev this might work better as simple pure functions in the host contract
  */
pragma solidity 0.8.4; 

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Fractional {

    using SafeMath for uint256;
    uint constant PRECISION = 10 ** 18;

    /**
     * @notice calculates the capital pool balance for the given amount of LP tokens
     * @dev used when a user wants to withdraw tokens from the capital pool  
     * @param circulatingLP : Total number of currently minted LP tokens
     * @param capitalPoolBalance : Capital pool current balance
     * @param lpTokens : Amount of LP tokens user wants to withdraw from capital pool
     * @return capital : Amount of capital pool balance for the given LP tokens
     */
    function capitalForLpTokens(uint circulatingLP, uint capitalPoolBalance, uint lpTokens) internal pure returns(uint capital) {
        capital = lpTokens.mul(capitalPoolBalance).div(circulatingLP);
    }

    /**
     * @notice calculates the amount of LP tokens that will mint by calculating the current balance of capital pool, Interest given to it and amount of currently minted LP tokens
     * @dev used when a user deposit tokens in the capital pool  
     * @param circulatingLP : Total number of currently minted LP tokens
     * @param capitalPoolBalance : Capital pool current balance
     * @param capital : Amount of capital pool balance user wants to deposit in the capital pool
     * @return lpTokens : Amount of LP tokens that will be minted according the amount of tokens user deposit in the capital pool
     */
    function lpTokensForCapital(uint circulatingLP, uint capitalPoolBalance, uint capital) internal pure returns(uint lpTokens) {
	    //value of one LP token 
        uint tokenCapital = capitalForLpTokens(circulatingLP, capitalPoolBalance, PRECISION);      

        lpTokens = capital.mul(PRECISION).div(tokenCapital);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4; 

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PRBMathUD60x18.sol";

library ContinuousInterest {

    using SafeMath for uint256;
    using PRBMathUD60x18 for uint256;

    struct Pool {
        //rate to pay per interval, Must be in the fixed point notation
        uint interestRate;                
        
        //micro-interest rate, not APR. Smaller units interest gas cost for O(log n) exponentiation  
        uint intervalSeconds;               
        
        //timeStamp when these values were last updated
        uint processedTimeStamp;            
        
        //last computed pool balance. always use poolBalances() 
        uint processedCapitalPoolBalance;   
        
        //last computed remaining interest funds on hand. always use poolBalances() 
        uint processedInterestPoolBalance;  
    }
    
    /**
     * @notice increases the balance of capital reserve pool whenever a user deposits the ERC20 tokens in it 
     * @param self : ContinouInterest (this library) type object 
     * @param amount : Number of tokens user wants to Deposit in capital reserve pool
     */
    function increaseCapitalPoolBalance(Pool storage self, uint amount) internal {
        //compute and store interest first
        _updatePoolBalances(self); 
        self.processedCapitalPoolBalance = self.processedCapitalPoolBalance.add(amount);
    }
    
    /**
     * @notice decreases the balance of capital reserve pool whenever a user withdraws the ERC20 tokens from it 
     * @param self : ContinouInterest (this library) type object 
     * @param amount : Number of tokens user wants to WithDraw from capital reserve pool
     */
    function decreaseCapitalPoolBalance(Pool storage self, uint amount) internal {
        //compute and store interest first
        _updatePoolBalances(self);
        self.processedCapitalPoolBalance = self.processedCapitalPoolBalance.sub(amount ,"ContinuousInterest : Insufficient capital balance");        
    }

    /**
     * @notice increases the balance of interest pool whenever Reserve Governence deposits the ERC20 tokens in it 
     * @param self : ContinouInterest (this library) type object 
     * @param amount : Number of tokens Reserve Governance wants to Deposit in Interest pool
     */
   function increaseInterestPoolBalance(Pool storage self, uint amount) internal {
         //compute and store interest first
        _updatePoolBalances(self); 
        self.processedInterestPoolBalance = self.processedInterestPoolBalance.add(amount);        
    }

    /**
     * @notice decreases the balance of interest pool whenever Reserve Governence withdraws the ERC20 tokens from it 
     * @param self : ContinouInterest (this library) type object 
     * @param amount : Number of tokens Reserve Governance wants to Withdraw from Interest pool
     */
    function decreaseInterestPoolBalance(Pool storage self, uint amount) internal {
        //compute and store interest first
        _updatePoolBalances(self); 
        self.processedInterestPoolBalance = self.processedInterestPoolBalance.sub(amount ,"ContinuousInterest : Insufficient interest balance");        
    }    
    
    /**
     * @notice This function returns the current balances of the capital and interest pool 
     * @dev This function calculates the current Interest, subtract it from the interest pool add it to the capital pool and the returns it
     * In case of insolvency when Interest pool balance becomes too low to pay the interest to capital pool, This function will give all the balance in Interest pool to capital pool and make Interest pool balance 0    
     * @param self : ContinouInterest (this library) type object
     * @return capitalPoolBal : Capital reserve pool current balance
     * @return interestPoolBal : Interest pool current balance
     */
    function poolBalances(Pool storage self) internal view returns(uint256 capitalPoolBal, uint256 interestPoolBal) 
    {
        uint timeStamp = block.timestamp;
        uint processedTimeStamp = self.processedTimeStamp;
        uint intervalSeconds = self.intervalSeconds;
        uint interestRate = self.interestRate;
             interestPoolBal = self.processedInterestPoolBalance;
        
        capitalPoolBal = _compoundBalance(self.processedCapitalPoolBalance, interestRate, intervalSeconds, processedTimeStamp, timeStamp);  
        uint interestDeducted = capitalPoolBal.sub(self.processedCapitalPoolBalance,"Capital Pool Balance overflow");

        if(interestPoolBal >= interestDeducted) { //continuous allocation of interest capital available to capital pool
               interestPoolBal = interestPoolBal.sub(interestDeducted,"ContinuousInterest : insufficient Balance in Interest Pool");
        } else { //insolvent, all available interest to capital pool
            capitalPoolBal = self.processedCapitalPoolBalance.add(self.processedInterestPoolBalance);
            interestPoolBal = 0; 
        }
    }

    /**
     * @notice Does not apply interest retroactively if the interest pool balance is allowed to fall to zero
     * @param self : ContinouInterest (this library) type object
     */
    function _updatePoolBalances(Pool storage self) private {
        (uint capitalPoolBal, uint interestPoolBal) = poolBalances(self);
        self.processedCapitalPoolBalance = capitalPoolBal;
        self.processedInterestPoolBalance = interestPoolBal;
        self.processedTimeStamp = block.timestamp;
    }

    /**
     * @notice calculates the Interest on the capital pool balance according to the given interest rate after the given time interval
     * @param initialBalance : current balance of capital pool before any further calculation
     * @param interestRate : initial interest rate
     * @param intervalSeconds : after every, that many seconds the interest will be calculated
     * @param startTime : last time when the capital and interest pool balances were calculated
     * @param endTime : current time stamp
     * @return balanceWithInterest : Balance of the capital pool with interest
     */
    function _compoundBalance(uint initialBalance, uint interestRate, uint intervalSeconds, uint startTime, uint endTime) private pure returns(uint balanceWithInterest) {
        balanceWithInterest = initialBalance.mulPrb(_periodInterest(interestRate, _getPeriods(intervalSeconds, startTime, endTime)));
    }

    /**
     * @notice calculates exponential part of the Interest formula
     * @param intervalInterest : Interest rate of one Interval
     * @param periods : Total number of Time Intervals that have been passed
     * @return compoundedRate : Interest according to the interest rate and time intervals passed
     */
    function _periodInterest(uint intervalInterest, uint periods) private pure returns(uint compoundedRate) {
        compoundedRate = _mathPower(intervalInterest, periods);
    }
    
    /**
     * @notice calculates the number of intervals that has been passed until now from the last time it was called
     * @param intervalSeconds : Time spam after which the interest has to calculated
     * @param startTime : last time when the capital and interest pool balances were calculated
     * @param endTime : current time stamp
     */
    function _getPeriods(uint intervalSeconds, uint startTime, uint endTime) private pure returns(uint intervalPeriods) {
        intervalPeriods = endTime.sub(startTime,"ContinuousInterest : Error while Computing Intervals");
        intervalPeriods = intervalPeriods.div(intervalSeconds);
    }

    /**
     * @notice calculates the per interval rate to the intervals passed
     * @param x : base of the Power
     * @param y : Exponent of the power
     * @return  xPowerY : Power of the x base to the exponent y
     */
    function _mathPower(uint x, uint y) private pure returns(uint xPowerY) {  
        xPowerY = x.powu(y);  
    }
}

//SPDX-License-Identifier: UNLICENSED;

pragma solidity 0.8.4;

interface IFactory{
    function isWhitelisted(address _user) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

//SPDX-License-Identifier: MIT;

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOFERC20 is IERC20 {

    function cancelPendingTransaction(bytes32 txnId) external;
    function claimPendingTransaction(bytes32 txnId) external;
    function pendingTransactions(bytes32 txnId) external view returns(address sender, address receiver, uint amount, uint expireTime);
    function userPendingCount(address user) external view returns(uint countOut, uint countIn);
    function userPendingOutAtIndex(address user, uint index) external view returns(bytes32 txnId);
    function userPendingInAtIndex(address user, uint index) external view returns(bytes32 txnId);
    function isUserPendingIn(address user, bytes32 txnId) external view returns(bool isPending);
    function isUserPendingOut(address user, bytes32 txnId) external view returns(bool isPending);
    function pendingTxnCount() external view returns(uint count);
    function pendingTxnAtIndex(uint index) external view returns(bytes32 txnId);
    function isPendingTxn(bytes32 txnId) external view returns(bool isPending);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4; 

/* 
Hitchens UnorderedKeySet v0.93
Library for managing CRUD operations in dynamic key sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensUnorderedKeySetLib {
    
    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }
    
    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length-1;
    }
    
    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
        bytes32 keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }
    
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }
    
    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }
    
    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }
    
    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/** 
 * @title PRBMathUD60x18
 * @author Paul Razvan Berg
 * @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
 * trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
 * digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
 * maximum values permitted by the Solidity type uint256.
 */ 
library PRBMathUD60x18 {
    /**
     * @dev Half the SCALE number.
     */ 
    uint256 internal constant HALF_SCALE = 5e17;

    /**
     * @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
     */ 
    uint256 internal constant LOG2_E = 1442695040888963407;

    /**
     * @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
     */ 
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /**
     * @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
     */ 
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /**
     * @dev How many trailing decimals can be represented.
     */ 
    uint256 internal constant SCALE = 1e18;
    
    
    

    /**
     * @notice Calculates arithmetic average of x and y, rounding down.
     * @param x The first operand as an unsigned 60.18-decimal fixed-point number.
     * @param y The second operand as an unsigned 60.18-decimal fixed-point number.
     * @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
     */ 
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        /** 
         * The operations can never overflow.
         */ 
        unchecked {
            /**
             * The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
             * to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
             */ 
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /** 
     * @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
     *
     * @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
     * See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
     *
     * Requirements:
     * - x must be less than or equal to MAX_WHOLE_UD60x18.
     *
     * @param x The unsigned 60.18-decimal fixed-point number to ceil.
     * @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
     */ 
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            /**
             * Equivalent to "x % SCALE" but faster.
             */ 
            let remainder := mod(x, SCALE)

            /**
             * Equivalent to "SCALE - remainder" but faster.
             */ 
            let delta := sub(SCALE, remainder)

            /**
             * Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
             */
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /** @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
     * 
     * @dev Uses mulDiv to enable overflow-safe multiplication and division.
     *
     * Requirements:
     * - The denominator cannot be zero.
     *
     * @param x The numerator as an unsigned 60.18-decimal fixed-point number.
     * @param y The denominator as an unsigned 60.18-decimal fixed-point number.
     * @param result The quotient as an unsigned 60.18-decimal fixed-point number.
     */ 
    function divPrb(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /**
     * @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
     * @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
     */ 
    function e() internal pure returns (uint256 result) {
        result = 2718281828459045235;
    }

    /**
     * @notice Calculates the natural exponent of x.
     *
     * @dev Based on the insight that e^x = 2^(x * log2(e)).
     *
     * Requirements:
     * - All from "log2".
     * - x must be less than 133.084258667509499441.
     *
     * @param x The exponent as an unsigned 60.18-decimal fixed-point number.
     * @return result The result as an unsigned 60.18-decimal fixed-point number.
     */ 
    function exp(uint256 x) internal pure returns (uint256 result) {
        /**
         * Without this check, the value passed to "exp2" would be greater than 192.
         */ 
        if (x >= 133084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        /**
         * Do the fixed-point multiplication inline to save gas.
         */ 
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /** @notice Calculates the binary exponent of x using the binary fraction method.
     *
     * @dev See https://ethereum.stackexchange.com/q/79903/24693.
     *
     * Requirements:
     * - x must be 192 or less.
     * - The result must fit within MAX_UD60x18.
     *
     * @param x The exponent as an unsigned 60.18-decimal fixed-point number.
     * @return result The result as an unsigned 60.18-decimal fixed-point number.
     */ 
    function exp2(uint256 x) internal pure returns (uint256 result) {
        /**
         * 2^192 doesn't fit within the 192.64-bit format used internally in this function.
         */ 
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            /**
             * Convert x to the 192.64-bit fixed-point format.
             */ 
            uint256 x192x64 = (x << 64) / SCALE;

            /**
             * Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
             */ 
            result = PRBMath.exp2(x192x64);
        }
    }

    /** 
     * @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
     * @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
     * See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
     * @param x The unsigned 60.18-decimal fixed-point number to floor.
     * @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
     */ 
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            /**
             * Equivalent to "x % SCALE" but faster.
             */ 
            let remainder := mod(x, SCALE)

            /**
             * Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
             */ 
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /** 
     * @notice Yields the excess beyond the floor of x.
     * @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
     * @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
     * @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
     */ 
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /**
     * @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
     *
     * @dev Requirements:
     * - x must be less than or equal to MAX_UD60x18 divided by SCALE.
     *
     * @param x The basic integer to convert.
     * @param result The same number in unsigned 60.18-decimal fixed-point representation.
     */ 
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /**
     * @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
     *
     * @dev Requirements:
     * - x * y must fit within MAX_UD60x18, lest it overflows.
     *
     * @param x The first operand as an unsigned 60.18-decimal fixed-point number.
     * @param y The second operand as an unsigned 60.18-decimal fixed-point number.
     * @return result The result as an unsigned 60.18-decimal fixed-point number.
     */ 
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            /**
             * Checking for overflow this way is faster than letting Solidity do it.
             */ 
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            /**
             * We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
             * during multiplication. See the comments within the "sqrt" function.
             */ 
            result = PRBMath.sqrt(xy);
        }
    }

    /**
     * @notice Calculates 1 / x, rounding towards zero.
     *
     * @dev Requirements:
     * - x cannot be zero.
     *
     * @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
     * @return result The inverse as an unsigned 60.18-decimal fixed-point number.
     */ 
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            /**
             * 1e36 is SCALE * SCALE.
             */ 
            result = 1e36 / x;
        }
    }

    /** 
     * @notice Calculates the natural logarithm of x.
     *
     * @dev Based on the insight that ln(x) = log2(x) / log2(e).
     *
     * Requirements:
     * - All from "log2".
     *
     * Caveats:
     * - All from "log2".
     * - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
     *
     * @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
     * @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
     */ 
    function ln(uint256 x) internal pure returns (uint256 result) {
        /**
         * Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
         * can return is 196205294292027477728.
         */ 
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /** 
     * @notice Calculates the common logarithm of x.
     *
     * @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
     * logarithm based on the insight that log10(x) = log2(x) / log2(10).
     *
     * Requirements:
     * - All from "log2".
     *
     * Caveats:
     * - All from "log2".
     *
     * @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
     * @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
     */ 
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        /**
         * Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
         * in this contract.
         * prettier-ignore
         */ 
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            /**
             * Do the fixed-point division inline to save gas. The denominator is log2(10).
             */ 
            unchecked {
                result = (log2(x) * SCALE) / 3321928094887362347;
            }
        }
    }

    /** 
     * @notice Calculates the binary logarithm of x.
     *
     * @dev Based on the iterative approximation algorithm.
     * https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
     *
     * Requirements:
     * - x must be greater than or equal to SCALE, otherwise the result would be negative.
     *
     * Caveats:
     * - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
     *
     * @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
     * @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
     */ 
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            /**
             * Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
             */ 
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            /**
             * The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
             * because n is maximum 255 and SCALE is 1e18.
             */ 
            result = n * SCALE;

            /**
             * This is y = x * 2^(-n).
             */ 
            uint256 y = x >> n;

            /**
             * If y = 1, the fractional part is zero.
             */ 
            if (y == SCALE) {
                return result;
            }

            /**
             * Calculate the fractional part via the iterative approximation.
             * The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
             */ 
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                /**
                 * Is y^2 > 2 and so in the range [2,4)?
                 */ 
                if (y >= 2 * SCALE) {
                    /**
                     * Add the 2^(-m) factor to the logarithm.
                     */ 
                    result += delta;

                    /**
                     * Corresponds to z/2 on Wikipedia.
                     */ 
                    y >>= 1;
                }
            }
        }
    }

    /** 
     * @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
     * fixed-point number.
     * @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
     * @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
     * @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
     * @return result The product as an unsigned 60.18-decimal fixed-point number.
     */ 
    function mulPrb(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /**
     * @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
     */ 
    function pi() internal pure returns (uint256 result) {
        result = 3141592653589793238;
    }

    /**
     * @notice Raises x to the power of y.
     * 
     * @dev Based on the insight that x^y = 2^(log2(x) * y).
     *
     * Requirements:
     * - All from "exp2", "log2" and "mul".
     *
     * Caveats:
     * - All from "exp2", "log2" and "mul".
     * - Assumes 0^0 is 1.
     *
     * @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
     * @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
     * @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
     */ 
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mulPrb(log2(x), y));
        }
    }

    /**
     * @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
     * famous algorithm "exponentiation by squaring".
     *
     * @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
     *
     * Requirements:
     * - The result must fit within MAX_UD60x18.
     *
     * Caveats:
     * - All from "mul".
     * - Assumes 0^0 is 1.
     *
     * @param x The base as an unsigned 60.18-decimal fixed-point number.
     * @param y The exponent as an uint256.
     * @return result The result as an unsigned 60.18-decimal fixed-point number.
     */ 
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        /**
         * Calculate the first iteration of the loop in advance.
         */ 
        result = y & 1 > 0 ? x : SCALE;

        /**
         * Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
         */ 
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            /**
             * Equivalent to "y % 2 == 1" but faster.
             */ 
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /** 
     * @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
     */ 
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /**
     * @notice Calculates the square root of x, rounding down.
     * @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
     *
     * Requirements:
     * - x must be less than MAX_UD60x18 / SCALE.
     *
     * @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
     * @return result The result as an unsigned 60.18-decimal fixed-point .
     */ 
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            /**
             * Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
             * 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
             */ 
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /** 
     * @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
     * @param x The unsigned 60.18-decimal fixed-point number to convert.
     * @return result The same number in basic integer form.
     */ 
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/** 
 * @notice Emitted when the result overflows uint256.
 */
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/** 
  * @notice Emitted when the result overflows uint256.
 */
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/** 
 * @notice Emitted when one of the inputs is type(int256).min.
 */
error PRBMath__MulDivSignedInputTooSmall();

/**
 * @notice Emitted when the intermediary absolute result overflows int256.
 */
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/**
 * @notice Emitted when the input is MIN_SD59x18.
 */
error PRBMathSD59x18__AbsInputTooSmall();

/**
 * @notice Emitted when ceiling a number overflows SD59x18.
 */
error PRBMathSD59x18__CeilOverflow(int256 x);

/** 
 * @notice Emitted when one of the inputs is MIN_SD59x18.
 */
error PRBMathSD59x18__DivInputTooSmall();

/**
 * @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
 */
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/**
 * @notice Emitted when the input is greater than 133.084258667509499441.
 */
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/**
 * @notice Emitted when the input is greater than 192.
 */
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/** 
 * @notice Emitted when flooring a number underflows SD59x18.
 */
error PRBMathSD59x18__FloorUnderflow(int256 x);

/**
 * @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
 */
error PRBMathSD59x18__FromIntOverflow(int256 x);

/**
 * @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
 */
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/**
 * @notice Emitted when the product of the inputs is negative.
 */
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/**
 * @notice Emitted when multiplying the inputs overflows SD59x18.
 */
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/**
 * @notice Emitted when the input is less than or equal to zero.
 */
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/**
 * @notice Emitted when one of the inputs is MIN_SD59x18.
 */
error PRBMathSD59x18__MulInputTooSmall();

/**
 * @notice Emitted when the intermediary absolute result overflows SD59x18.
 */
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/**
 * @notice Emitted when the intermediary absolute result overflows SD59x18.
 */
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/**
 * @notice Emitted when the input is negative.
 */
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/**
 * @notice Emitted when the calculting the square root overflows SD59x18.
 */
error PRBMathSD59x18__SqrtOverflow(int256 x);

/** 
 * @notice Emitted when addition overflows UD60x18.
 */
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/** 
 * @notice Emitted when ceiling a number overflows UD60x18.
 */
error PRBMathUD60x18__CeilOverflow(uint256 x);

/**
 * @notice Emitted when the input is greater than 133.084258667509499441.
 */
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/**
 * @notice Emitted when the input is greater than 192.
 */
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/**
 * @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
 */ 
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/**
 * @notice Emitted when multiplying the inputs overflows UD60x18.
 */ 
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/**
 * @notice Emitted when the input is less than 1.
 */ 
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/**
 * @notice Emitted when the calculting the square root overflows UD60x18.
 */ 
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/**
 * @notice Emitted when subtraction underflows UD60x18.
 */ 
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/**
 * @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
 * 
 * does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
 * representation. When it does not, it is explictly mentioned in the NatSpec documentation.
 */ 
library PRBMath {
    /**
     * STRUCTS 
     */ 

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /** 
     * STORAGE 
     */

    /**
     * @dev How many trailing decimals can be represented.
     */
    uint256 internal constant SCALE = 1e18;

    /**
     * @dev Largest power of two divisor of SCALE.
     */ 
    uint256 internal constant SCALE_LPOTD = 262144;

    /**
     * @dev SCALE inverted mod 2^256.
     */ 
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /**
     * FUNCTIONS 
     */

    /**
     * @notice Calculates the binary exponent of x using the binary fraction method.
     * @dev Has to use 192.64-bit fixed-point numbers.
     * See https://ethereum.stackexchange.com/a/96594/24693.
     * @param x The exponent as an unsigned 192.64-bit fixed-point number.
     * @return result The result as an unsigned 60.18-decimal fixed-point number.
     */
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            /** 
             * Start from 0.5 in the 192.64-bit fixed-point format.
             */ 
            result = 0x800000000000000000000000000000000000000000000000;

            /**
             * Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
             * because the initial result is 2^191 and all magic factors are less than 2^65.
             */ 
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            /**
             * We're doing two things at the same time:
             *
             *   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
             *      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
             *      rather than 192.
             *   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
             *
             * This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
             */ 
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /** 
     * @notice Finds the zero-based index of the first one in the binary representation of x.
     * @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
     * @param x The uint256 number for which to find the index of the most significant bit.
     * @return msb The index of the most significant bit as an uint256.
     */ 
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /* @notice Calculates floor(x*y÷denominator) with full precision.
     *
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
     *
     * Requirements:
     * - The denominator cannot be zero.
     * - The result must fit within uint256.
     *
     * Caveats:
     * - This function does not work with fixed-point numbers.
     *
     * @param x The multiplicand as an uint256.
     * @param y The multiplier as an uint256.
     * @param denominator The divisor as an uint256.
     * @return result The result as an uint256.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        /**
         * 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
         * use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
         * variables such that product = prod1 * 2^256 + prod0.
         */ 
         
         /**
          * Least significant 256 bits of the product
          */ 
        uint256 prod0; 
        
        /**
         * Most significant 256 bits of the product
         */ 
        uint256 prod1; 
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        /**
         * Handle non-overflow cases, 256 by 256 division.
         */ 
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        /**
         * Make sure the result is less than 2^256. Also prevents denominator == 0.
         */ 
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        /**
         *  512 by 256 division.
         */

        /**
         * Make division exact by subtracting the remainder from [prod1 prod0].
         */ 
        uint256 remainder;
        assembly {
            /**
             * Compute remainder using mulmod.
             */ 
            remainder := mulmod(x, y, denominator)

            /**
             * Subtract 256 bit number from 512 bit number.
             */ 
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        /**
         * Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
         * See https://cs.stackexchange.com/q/138556/92363.
         */ 
        unchecked {
            /** 
             * Does not overflow because the denominator cannot be zero at this stage in the function.
             */ 
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                /**
                 * Divide denominator by lpotdod.
                 */ 
                denominator := div(denominator, lpotdod)

                /**
                 * Divide [prod1 prod0] by lpotdod.
                 */ 
                prod0 := div(prod0, lpotdod)

                /**
                 * Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                 */ 
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            /**
             * Shift in bits from prod1 into prod0.
             */ 
            prod0 |= prod1 * lpotdod;

            /**
             * Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
             * that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
             * four bits. That is, denominator * inv = 1 mod 2^4.
             */ 
            uint256 inverse = (3 * denominator) ^ 2;

            /**
             * Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
             * in modular arithmetic, doubling the correct bits in each step.
             */ 
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            /**
             * Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
             * This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
             * less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
             * is no longer required.
             */ 
            result = prod0 * inverse;
            return result;
        }
    }

    /** 
     * @notice Calculates floor(x*y÷1e18) with full precision.
     *
     * @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
     * final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
     * being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
     *
     * Requirements:
     * - The result must fit within uint256.
     *
     * Caveats:
     * - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
     * - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
     *     1. x * y = type(uint256).max * SCALE
     *     2. (x * y) % SCALE >= SCALE / 2
     *
     * @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
     * @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
     * @return result The result as an unsigned 60.18-decimal fixed-point number.
     */ 
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /** @notice Calculates floor(x*y÷denominator) with full precision.
     *
     * @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
     *
     * Requirements:
     * - None of the inputs can be type(int256).min.
     * - The result must fit within int256.
     *
     * @param x The multiplicand as an int256.
     * @param y The multiplier as an int256.
     * @param denominator The divisor as an int256.
     * @return result The result as an int256.
     */ 
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        /**
         * Get hold of the absolute values of x, y and the denominator.
         */ 
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        /**
         * Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
         */ 
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        /**
         * Get the signs of x, y and the denominator.
         */ 
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        /**
         * XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
         * If yes, the result should be negative.
         */ 
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /** 
     * @notice Calculates the square root of x, rounding down.
     * @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
     *
     * Caveats:
     * - This function does not work with fixed-point numbers.
     *
     * @param x The uint256 number for which to calculate the square root.
     * @return result The result as an uint256.
     */ 
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        /**
         * Set the initial guess to the closest power of two that is higher than x.
         */ 
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        /**
         * The operations can never overflow because the result is max 2^127 when it enters this block.
         */ 
        unchecked {
             /**
             * Seven iterations should be enough
             */
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; 
            
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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