/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity 0.5.16;


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
 
 
 library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
 
 
 contract Context {
    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; 
        return msg.data;
    }
}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal  whenNotPaused {
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
    function _unpause() internal  whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract SmartChain is  Pausable {
    
    using SafeMath for uint256;
    
    struct User { // user struct
        uint256 cycle; // deposit cycles
        address upline; // referrer
        uint256 referrals; // referrals count
        mapping(uint256 => uint256) payouts; // payout of deposits by cycle
        uint256 direct_bonus; // referral bonus
        uint256 match_bonus; // matching bonus
        mapping(uint256 => uint256) deposit_amount; // deposit amount by cycle
        uint256 currentCycle; // current deposit cycle
        mapping(uint256 => uint256) deposit_payouts;  // deposit payout by cycle
        mapping(uint256 => uint256) deposit_time; // deposit time by cycle
        uint256 total_deposits; // total deposits
        uint256 total_payouts; // total payout received
        uint256 total_structure; // total upline structures
    }

    mapping(address => User) public users;
    
    address maintenance_address; // maintainence address
    address investor_address; // investor address
    address public _owner;

    uint8[] public ref_bonuses;  // upline bonuses
    uint public levelBonus = 10;
    
    uint minimum_deposit = 0.1 ether;
    
    bool public withdrawalLock = false;
    
    // pools money
    uint public general_pool_amount; // daily distribution pool
    uint public referrals_pool_amount; // matching bonus pool
    uint  investor_pool_amount; // investor pool
    uint  maintainence_pool_amount;
    uint public sponser_pool_amount; // top sponsers pool

    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle; // pool cycles

    uint256 public total_withdraw; // total withdrawal amount

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MaintenanceEvent( uint _amount, uint _flag);
    event InvestorEvent( uint _amount, uint _flag);

    constructor( address owner, address _maintenance_address, address _investor_address) public {
        maintenance_address  = _maintenance_address;
        investor_address = _investor_address;
        _owner = owner;
        
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier lockWithdrawal(){
        require(withdrawalLock == false, "Withdrawal lock: withdrawal is locked");
        _;
    }

    function _setUpline(address _addr, address _upline) private { // set 15 generation
        if(users[_addr].upline == address(0) && _upline != _addr && (users[_upline].deposit_time[0] > 0 || _upline == maintenance_address)) { 
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {  // user deposit and pool money distribution
        require(users[_addr].upline != address(0) || _addr == maintenance_address, "No upline");

        if(users[_addr].cycle > 0) {
            
            require(_amount >= users[_addr].deposit_amount[users[_addr].cycle.sub(1)], "Deposit must be greather than the previous one");
        }
        else require(_amount >= minimum_deposit, "Bad amount");
        
        users[_addr].deposit_amount[users[_addr].cycle] = _amount; // deposit to current cycle.
        users[_addr].deposit_time[users[_addr].cycle] = uint40(block.timestamp);
        users[_addr].total_deposits = users[_addr].total_deposits.add(_amount);
        
        users[_addr].cycle++;
        
        emit NewDeposit(_addr, _amount);
        
        users[users[_addr].upline].direct_bonus = (users[users[_addr].upline].direct_bonus).add(_amount.mul(levelBonus).div(100)); // upline 10 %
        emit DirectPayout(users[_addr].upline, _addr, _amount.mul(levelBonus).div(100));
        
        general_pool_amount = general_pool_amount.add(_amount.mul(69 ether).div(100 ether)); // 69% - general pool
        referrals_pool_amount = referrals_pool_amount.add(_amount.mul(15 ether).div(100 ether)); // 15% - referral pool
        investor_pool_amount = investor_pool_amount.add(_amount.mul(5 ether).div(100 ether)); // 5% - invest pool
        maintainence_pool_amount = maintainence_pool_amount.add(_amount.mul(1 ether).div(100 ether)); // 1% - maintenance pool
        sponser_pool_amount = sponser_pool_amount.add(_amount.mul(5 ether).div(100 ether)); // 5% - sponser pool


        address(uint160(_owner)).transfer(_amount.mul(5 ether).div(100 ether)); // owner commission 5 %;
        
        emit MaintenanceEvent( _amount.mul(1 ether).div(100 ether), 1);
        emit InvestorEvent( _amount.mul(5 ether).div(100 ether), 1);
    }



    function _refPayout(address _addr, uint256 _amount) private { // matching bonus distribution
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                users[up].match_bonus = users[up].match_bonus.add(bonus);
                emit MatchPayout(up, _addr, bonus);  
            }

            up = users[up].upline;
        }
    }

    function _drawPool(address [] memory _user_address, uint[] memory _user_amount) private { // sponser pool distribution
        require(_user_address.length == _user_amount.length,"invalid length");
        
        pool_cycle++;
        
        pool_last_draw = uint40(block.timestamp);

        for(uint8 i = 0; i < _user_address.length; i++) {
            if(_user_address[i] == address(0)) break;
                
                if(users[_user_address[i]].deposit_time[0] > 0){
                   uint max_payout = this.maxPayoutOf(users[_user_address[i]].deposit_amount[users[_user_address[i]].currentCycle]);
                   if(_user_amount[i] > max_payout){
                        _user_amount[i] = max_payout.sub(users[_user_address[i]].payouts[users[_user_address[i]].currentCycle]);
                   }    
                   
                   users[_user_address[i]].payouts[users[_user_address[i]].currentCycle]= users[_user_address[i]].payouts[users[_user_address[i]].currentCycle].add(_user_amount[i]) ;
                   
                   if(users[_user_address[i]].payouts[users[_user_address[i]].currentCycle] >= max_payout && _user_amount[i] > 0) {
                        users[_user_address[i]].currentCycle++;
                        emit LimitReached(_user_address[i], users[_user_address[i]].payouts[users[_user_address[i]].currentCycle]);
                    }
                   
                   emit Withdraw(_user_address[i], _user_amount[i]);
                }
                
                if(sponser_pool_amount < _user_amount[i]) break;
                
                require(address(uint160(_user_address[i])).send(_user_amount[i]),"transfer failed");
                sponser_pool_amount = sponser_pool_amount.sub(_user_amount[i]);
                
                emit PoolPayout(_user_address[i], _user_amount[i]);
        }
    }

    function deposit(address _upline) payable external whenNotPaused {
        require(contractCheck(msg.sender) == 0, "cannot be a contract");
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external whenNotPaused lockWithdrawal {
        require(contractCheck(msg.sender) == 0, "cannot be a contract");
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts[users[msg.sender].currentCycle] < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts[users[msg.sender].currentCycle].add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts[users[msg.sender].currentCycle]);
            }
            
            if(general_pool_amount < to_payout) to_payout=0;
            
            users[msg.sender].deposit_payouts[users[msg.sender].currentCycle] = users[msg.sender].deposit_payouts[users[msg.sender].currentCycle].add(to_payout);
            users[msg.sender].payouts[users[msg.sender].currentCycle] = users[msg.sender].payouts[users[msg.sender].currentCycle].add(to_payout);
            general_pool_amount = general_pool_amount.sub(to_payout);
    
            if(to_payout > 0)
                _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts[users[msg.sender].currentCycle] < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts[users[msg.sender].currentCycle].add(direct_bonus) > max_payout) {
                direct_bonus = max_payout.sub(users[msg.sender].payouts[users[msg.sender].currentCycle]);
            }

            users[msg.sender].direct_bonus = users[msg.sender].direct_bonus.sub(direct_bonus);
            users[msg.sender].payouts[users[msg.sender].currentCycle] = users[msg.sender].payouts[users[msg.sender].currentCycle].add(direct_bonus);
            to_payout = to_payout.add(direct_bonus);
        }

        // Match payout
        if(users[msg.sender].payouts[users[msg.sender].currentCycle] < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts[users[msg.sender].currentCycle].add(match_bonus) > max_payout) {
                match_bonus = max_payout.sub(users[msg.sender].payouts[users[msg.sender].currentCycle]);
            }
            
            if(referrals_pool_amount < match_bonus) match_bonus=0;

            users[msg.sender].match_bonus = users[msg.sender].match_bonus.sub(match_bonus);
            users[msg.sender].payouts[users[msg.sender].currentCycle] = users[msg.sender].payouts[users[msg.sender].currentCycle].add(match_bonus);
            referrals_pool_amount = referrals_pool_amount.sub(match_bonus);
            to_payout = to_payout.add(match_bonus);
            
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts = users[msg.sender].total_payouts.add(to_payout);
        total_withdraw = total_withdraw.add(to_payout);

        address(uint160(msg.sender)).transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts[users[msg.sender].currentCycle] >= max_payout) {
            users[msg.sender].currentCycle++;
            emit LimitReached(msg.sender, users[msg.sender].payouts[users[msg.sender].currentCycle]);
        }
    }
    
    function drawPool(address[] calldata _user_address, uint[] calldata _user_amount) external onlyOwner {
        _drawPool(_user_address, _user_amount);
    }
    
    function investorWithdrawal(address payable _toUser, uint _amount) external returns(bool){
        require(investor_pool_amount >= _amount,"insufficient investor pool amount");
        require(_toUser != address(0),"invalid address");
        require(msg.sender == investor_address,"only investor wallet");
        
        require(_toUser.send(_amount),"transfer failed");
        investor_pool_amount = investor_pool_amount.sub(_amount);
        emit InvestorEvent( _amount, 2);
    }


    function maintenanceWithdrawal(address payable _toUser, uint _amount) external returns(bool){
        require(maintainence_pool_amount >= _amount,"insufficient investor pool amount");
        require(_toUser != address(0),"invalid address");
        require(msg.sender == maintenance_address,"only maintenance wallet");
        
        require(_toUser.send(_amount),"transfer failed");
        maintainence_pool_amount = maintainence_pool_amount.sub(_amount);
        emit MaintenanceEvent( _amount, 2);
    }

    function failSafe(address payable _toUser, uint _amount) external onlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function pauseWithdrawal() external onlyOwner {
        withdrawalLock = true;
    }
    
    function unpauseWithdrawal() external onlyOwner {
        withdrawalLock = false;
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount.mul(35).div(10); // maximum payout is set to 350 %
    }

    function payoutOf(address _addr)public view  returns(uint256 payout, uint256 max_payout) { // 1.2 daily ROI
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount[users[_addr].currentCycle]);

        if(users[_addr].deposit_payouts[users[_addr].currentCycle] < max_payout) {
            payout = (((users[_addr].deposit_amount[users[_addr].currentCycle].mul(1.2 ether).div(100 ether)).mul((block.timestamp.sub(users[_addr].deposit_time[users[_addr].currentCycle])).div(86400))).sub(users[_addr].deposit_payouts[users[_addr].currentCycle]));
            
            if(users[_addr].deposit_payouts[users[_addr].currentCycle].add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].deposit_payouts[users[_addr].currentCycle]);
            }
            
        }
    }
    
    function contractCheck(address _user) public view returns(uint){
        uint32 size;
        
        assembly {
            size := extcodesize(_user)
        }
        
        return size;
    }

    /*
        Only external call
    */
    function userInfo(address _addr,uint256 _cycle) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 deposit_payouts) {
        return (users[_addr].upline, users[_addr].deposit_time[_cycle], users[_addr].deposit_amount[_cycle], users[_addr].payouts[_cycle], users[_addr].deposit_payouts[_cycle]);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_withdraw, uint40 _pool_last_draw) {
        return (total_withdraw, pool_last_draw);
    }
}