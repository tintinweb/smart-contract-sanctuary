/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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





            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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





            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}





            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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





            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../token/ERC20/IERC20.sol";





            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/interfaces/IERC20.sol";
////import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
////import "@openzeppelin/contracts/security/Pausable.sol";
contract QuantMaster is Initializable, Ownable, Pausable {

    address public  MARTIAN;
    address public pending_martian;
    
    mapping( address => mapping(address => uint256) ) public balances;
    struct Project{
        uint256 projectId;
        uint256 strategyId;
        address token;// foregift token contract address,eth:0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        address investor;
        address strategist;
        uint256 foregift;
        uint256 investment;
        uint256 balance;
        uint256 totalFee;
        uint256 forVotesRewards;
        uint256 endblock; // The end date of the project. In 5 days after this date, if the status == 1, the user can withdraw the pledge deposit
        uint256 status; //1,creative;2.end;3.forceSettle
    }

    /// projectid-->project detail
    mapping( uint256 => Project) public projects;

    /// voter address => (strategyId => rewardsDdebts)
    mapping( address => mapping( uint256 => uint256)) public rewardsDebts;

    event LAUNCH(address investor,uint256 projectId,uint256 foregifts,address token);
    event WITHDRAW(address withdrawer, uint256 amount, uint256 balance);
    event FORCESETTLE(address investor,uint256 amount);
    event DEPOSIT(address investor,uint256 addAmount,uint256 foregift);
    event DEPOSITFEE(address investor,uint256 projectid,uint256 serviceFee,uint256 balance);
    event ENDPROJECT(address martin, uint256 projectid, uint256 totalFee, uint256 strategyFee,uint256 returnForegift);
    event SETTLEMENT(address martin, uint256 projectid, uint256 totalFee, uint256 strategyFee);
    event ADDSTRATEGY(uint256 strategyId, uint256 proposalId,uint256 forVotes);
    event CLAIMREWARDS(address voter, uint256 strategyId, uint256 rewards);
    event SETPROTOCOLRATES(uint24 treasuryRate, uint24 supportRate, uint24 labsRate);

    constructor(address _martian){
        MARTIAN = _martian;
    }
    
    // function initialize(address _martian) public initializer {
    //     MARTIAN = _martian;
    // }

    function setPendingMartian(address _martian) external {
        require(MARTIAN == msg.sender && _martian!=address(0) && MARTIAN != _martian, "MUST MARTIAN");
        pending_martian = _martian;
    }

    function acceptPendingMartian() external {
        require(msg.sender == pending_martian,"ERROR ACCOUNT");
        MARTIAN = pending_martian;
    }


    ///@dev Create a new quantitative project, launch by the investor,If investors have unwithdraw funds, they will be used first.
    /// Before confirming the transaction, the backend must check whether each parameter is correct.
    ///@param _projectId quant prj id, from quant backend
    ///@param _strategyId strategy id, from quant backend
    ///@param _foregift Estimated project fee
    ///@param _token foregift token contract,eth:0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    ///@param _strategist strategist address,from quant backend
    function launch(uint256 _projectId, uint256 _strategyId, uint256 _foregift, address _token, address _strategist) payable external whenNotPaused {
        require(_foregift>0 && _token!=address(0) && _strategist!=address(0),"INVALID PARAM");
        Project storage project = projects[_projectId];
        require(project.projectId == 0,"PROJECT EXIST");

        uint256 inbalance = balances[msg.sender][_token];
        uint256 amount = _foregift;
        if(inbalance > 0){ //The investor still has undrawn funds
            if(inbalance >= _foregift){
                balances[msg.sender][_token] -= _foregift;
            }else{
                balances[msg.sender][_token] = 0;
                amount = _foregift - inbalance;
            }
        }

        if(_token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            require(msg.value >= amount, "INSUFFICIENT FOREGIFT");
            if(msg.value > amount){
                payable(msg.sender).transfer(msg.value - amount);
            }
        }else{
            IERC20(_token).transferFrom(msg.sender, address(this), amount);
        }
        
        
        project.projectId = _projectId;
        project.strategyId = _strategyId;
        project.token = _token;
        project.foregift = _foregift;
        project.strategist = _strategist;
        project.investor = msg.sender;
        project.status = 1;       
        emit LAUNCH(msg.sender, _projectId, _foregift,_token);
    }

    ///@dev Backend query project info
    ///@param _projectId project Id 
    ///@return project struct Project. project.projectId = 0 if _projectId does not exist
    function query(uint256 _projectId) external view returns(Project memory project){
        return projects[_projectId];
    }

    ///@dev When the investor income is close to the forgive, the investor needs to pay a service fee
    ///@param _projectId project
    ///@param _serviceFee service fee,from backend calculate
    function depositFee(uint256 _projectId,uint256 _serviceFee) payable external {
        Project storage project = projects[_projectId];
        require(project.investor == msg.sender, "NON-INVESTOR");
        require(project.status == 1 && project.investor == msg.sender, "ERROR PROJECT");
        if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            require(msg.value >= _serviceFee, "INSUFFICIENT FUNDS");
            if(msg.value > _serviceFee){
                payable(msg.sender).transfer(msg.value - _serviceFee);
            }
        }else{
            require(IERC20(project.token).balanceOf(msg.sender) >= _serviceFee,"INSUFFICIENT FUNDS");
            IERC20(project.token).transferFrom(msg.sender, address(this), _serviceFee);
        }
        project.balance += _serviceFee;

        emit DEPOSITFEE(msg.sender, _projectId, _serviceFee,project.balance);
    }

    ///@dev End project,settle strategist service fee,returns foregift to investor
    ///@param _projectId project ID
    ///@param _totalFee total service fee
    ///@param _strategyFee strategist service fee
    function endProject(uint256 _projectId, uint256 _totalFee, uint256 _strategyFee) external {
        require(MARTIAN == msg.sender, "MUST MARTIAN");
        Project storage project = projects[_projectId];
        require(project.projectId != 0, "ERROR PROJECT");

        settlement(_projectId,_totalFee,_strategyFee,true, true);
    }

    ///@dev MTE Backend call settlement
    ///@param _projectId project id 
    ///@param _totalFee project total service fee = strategyfee + platform fee
    ///@param _strategyFee stategist service fee
    ///@param _useForegift Whether to use the forgift to supplement the service fee
    ///@param _endProjct end project, return foregift/service balance
    function settlement(uint256 _projectId, uint256 _totalFee, uint256 _strategyFee, bool _useForegift, bool _endProjct) public whenNotPaused{
        require(MARTIAN == msg.sender || msg.sender == address(this), "MUST MARTIAN");
        require(_totalFee >= _strategyFee, "TOTALFEE < STRATEGYFEE");      

        Project storage project = projects[_projectId];
        require(project.projectId > 0, "INVALID PID");
        uint256 tokenbalance = project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ? address(this).balance : IERC20(project.token).balanceOf(address(this));
        uint256 projecttoken = project.foregift + project.balance;

        // Use foregift to replenish service fee deficiencies
        if(_useForegift){
            require(project.foregift + project.balance >= _totalFee, "INSUFFICENT FUNDS");
            if(project.balance < _totalFee){
                project.foregift -= (_totalFee - project.balance);
                project.balance = 0;
            }else{
                project.balance -= _totalFee;
            }
        }else{
            require(project.balance >= _totalFee, "INSUFFICENT FUNDS");
            project.balance -= _totalFee;
        }

        if(_totalFee>0){
            if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
                payable(project.strategist).transfer(_totalFee);
            }else{
                IERC20(project.token).transfer(project.strategist,  _totalFee);  
            }
        }      
        
        //Return foregift,transfer token(not MTE) to investor
        uint256 returnForegift = project.foregift + project.balance;
        if(_endProjct && returnForegift > 0){
        
            
            project.foregift = 0;
            project.balance = 0;

            //eth
            if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
                if(address(this).balance < returnForegift){
                   returnForegift =  address(this).balance;
                }
                payable(project.investor).transfer(returnForegift);
            }else{
                if(IERC20(project.token).balanceOf(address(this)) < returnForegift ){
                    returnForegift = IERC20(project.token).balanceOf(address(this));
                }
                IERC20(project.token).transfer(project.investor, returnForegift);
            }
        }
        if(_endProjct){
            project.status = 2;
            emit ENDPROJECT(msg.sender, _projectId, _totalFee, _strategyFee, returnForegift);
        }

        /// Make sure there is no theft
        uint256 tokenbalance_ = project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ? address(this).balance : IERC20(project.token).balanceOf(address(this));
        assert( tokenbalance_ >= tokenbalance - projecttoken );

        emit SETTLEMENT(msg.sender, _projectId, _totalFee, _strategyFee);
    }

    ///@dev Investor add foregift
    function deposit(uint256 _projectId, uint256 _addAmount) payable external{
        Project storage project = projects[_projectId];
        require(project.investor == msg.sender,"ERROR PROJECTID");

        if(project.token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
            require(msg.value >= _addAmount, "INSUFFICIENT");
            if(msg.value > _addAmount){
                payable(msg.sender).transfer(msg.value - _addAmount);
            }
        }else{
            IERC20(project.token).transferFrom(msg.sender, address(this), _addAmount);
        }

        project.foregift += _addAmount;
        emit DEPOSIT(msg.sender,_addAmount,project.foregift);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    receive() external payable {}

}