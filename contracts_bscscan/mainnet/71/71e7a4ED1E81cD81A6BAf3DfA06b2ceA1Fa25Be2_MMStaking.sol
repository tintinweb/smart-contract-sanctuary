/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
contract MMStaking{
    address constant MYTH_TOKEN_ADDRESS = 0xA60ea04c796E8Fb17B690593fd9c61D31f9AA918;
    
    struct User {
        uint40 deposit_time;
        uint256 total_deposit;
        uint256 compound;
        uint256 unclaimed;
        uint256 unstaked;
        uint256 unstaked_time;
    }
    
    struct Stake {
        uint256 id;
        uint256 fund;
        uint256 withdrawn;
        bool active;
        uint40 activated_time;
    }
    
    mapping(address => User) public users;
    mapping(uint256 => Stake) public stakes;
    
    address public owner;
    uint256 public balance;
    uint256 public total_earnings;
    
    bool public status;
    uint40 public update_status_time;
    
    uint256 public total_users;
    address[] public staked_users;
    
    uint256 public total_stake_count;
    
    mapping(address => uint256[]) staked;
    
    event Compound(address indexed addr, uint256 indexed bot_id, uint256 indexed amount);
    event Staked(address indexed addr, uint256 indexed amount);
    event Claim(address indexed addr, uint256 indexed amount);
    event Unstaked(address indexed addr, uint256 indexed amount);
    event Withdraw(address indexed addr, uint256 indexed amount);
    
    constructor() {
        owner = msg.sender;
        total_stake_count = 0;
        status = true;
        
        IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), IERC20(MYTH_TOKEN_ADDRESS).totalSupply());
    }
    
    function _compound(address _addr, uint256 _amount) internal {
        total_stake_count++;
        
        // initialize stake
        stakes[total_stake_count].id = total_stake_count;
        stakes[total_stake_count].fund = _amount;
        stakes[total_stake_count].active = true;
        stakes[total_stake_count].activated_time = uint40(block.timestamp);
        
        staked[_addr].push(stakes[total_stake_count].id);
        
        users[_addr].compound++;
        
        emit Compound(_addr, stakes[total_stake_count].id, _amount);
    }
    
    function stake(uint256 _amount) external {
        require(status, "Error: Staking is disabled.");
        require(_amount > 999 * 10 ** 18, "Error: Minimum 1000 MYTH.");
        require(IERC20(MYTH_TOKEN_ADDRESS).balanceOf(msg.sender) > 0, "Error: Insufficient balance.");
        require(users[msg.sender].unstaked == 0, "Error: Claim your unstaked MYTH first.");
        
        if(users[msg.sender].deposit_time == 0){
            staked_users.push(msg.sender);
        }
        
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        
        users[msg.sender].deposit_time = uint40(block.timestamp);
        users[msg.sender].total_deposit += _amount;
        
        _compound(msg.sender, _amount);
        
        total_users++;
        
        balance += _amount;
        
        emit Staked(msg.sender, _amount);
    }
    
    function calculateUnlockedTokens(address _addr, uint256 _stake_id) view external returns(uint256) {
        uint256 unlocked = 0;
        uint256 fund = stakes[_stake_id].fund; // + this.calculateUnlockedTokens(_stake_id);
        uint256 every_seconds = (fund * 20 / 100) / 365 / 24 / 60 / 60;
        unlocked = (block.timestamp - stakes[_stake_id].activated_time) * every_seconds;
        
        unlocked = unlocked - stakes[_stake_id].withdrawn;
        
        if(!status || users[_addr].unclaimed > 0){
            unlocked = 0;
        }

        return unlocked;
    }
    
    function getSeconds(uint256 _stake_id) external view returns (uint256){
        return block.timestamp - stakes[_stake_id].activated_time;
    }

    function claim() external {
        if(users[msg.sender].unstaked > 0){
            require(users[msg.sender].unstaked > 0,"Error: No staked MYTH.");
            require((block.timestamp - users[msg.sender].unstaked_time) / 1 days > 7,"Error: Too early.");
            _withdraw(msg.sender);
        } else {
            _claim();
        }
    }
    
    function _claim() internal {
        
        require(users[msg.sender].total_deposit > 0,"Error: No staked MYTH.");
        
        uint256 payout = 0;
        
        for(uint8 i = 0; i < staked[msg.sender].length; i++) {
            uint256 stake_id = staked[msg.sender][i];
            
            if(stakes[stake_id].active){
                
                uint256 to_payout = this.calculateUnlockedTokens(msg.sender, stake_id);
                
                if(to_payout > 0){
                    payout += to_payout;
                }
            }
        }
        
        require(payout > 0, "Error: No withdrawable balance.");
        
        payout = 0;
        
        // get all active compound
        for(uint8 i = 0; i < staked[msg.sender].length; i++) {
            uint256 stake_id = staked[msg.sender][i];
            
            if(stakes[stake_id].active){
                
                uint256 to_payout = this.calculateUnlockedTokens(msg.sender, stake_id);
                
                if(to_payout > 0){
                    
                    stakes[stake_id].withdrawn += to_payout;
                
                    payout += to_payout;
                }
            }
        }
        
        total_earnings += payout;
 
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(owner, msg.sender, payout);
        
        emit Claim(msg.sender, payout);
    }
    
    function _unstake(address _addr) internal {
        
        uint256 payout = 0;
        
        for(uint8 i = 0; i < staked[_addr].length; i++) {
            uint256 stake_id = staked[_addr][i];
            
            if(stakes[stake_id].active){
                
                uint256 to_payout = this.calculateUnlockedTokens(_addr, stake_id);
                
                if(to_payout > 0){
                    payout += to_payout;
                }
            }
        }
        
        users[_addr].unclaimed = payout;
        
        for(uint8 i = 0; i < staked[_addr].length; i++) {
            uint256 stake_id = staked[_addr][i];
            
            if(stakes[stake_id].active){
                stakes[stake_id].active = false;
            }
            
        }
        
        users[_addr].unstaked = users[_addr].total_deposit;
        users[_addr].unstaked_time = uint40(block.timestamp);
        
        emit Unstaked(_addr, users[_addr].unstaked);
    }
    
    function unstake() external {
        require(users[msg.sender].total_deposit > 0,"Error: No staked MYTH.");
        _unstake(msg.sender);
    }
        
    function _withdraw(address _addr) internal {
        
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(owner, _addr, users[_addr].unclaimed);
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(address(this), _addr, users[_addr].unstaked);
        
        users[_addr].unclaimed = 0;
        users[_addr].unstaked = 0;
        users[_addr].unstaked_time = 0;
        
        users[_addr].compound = 0;
        users[_addr].deposit_time = 0;
        users[_addr].total_deposit = 0;
        
        // clear array
        for(uint256 i = 0; i < staked[_addr].length; i++){
            staked[_addr].pop();
        }
        
        uint256 index = 0;
        
        for(uint256 i = 0; i < staked_users.length; i++){
            if(staked_users[i] == _addr){
                index = i;
            }
        }

        staked_users[index] = staked_users[staked_users.length - 1];
        staked_users.pop();
        
        total_users--;
        balance -= users[_addr].total_deposit;
        
        emit Withdraw(_addr, users[_addr].unclaimed + users[_addr].unstaked);
    }
    
    function getStakedUsers() external view returns (address[] memory addrs, uint256 total) {
        addrs = staked_users;
        total = staked_users.length;
    }
    
    function disableStaking() external {
        require(msg.sender == owner, "Error: Insufficient permission.");
        
        uint256 l = staked_users.length;
        for(uint256 i = 0; i < l; i++){
            _unstake(staked_users[0]);
            _withdraw(staked_users[0]);
        }

        status = false;
        update_status_time = uint40(block.timestamp);
    }
    
    function set(uint256 _tag, uint256 _value) external {
        require(msg.sender == owner, "Error: Insufficient permission.");
        
        if(_tag == 0){
            status = 1==_value;
            update_status_time = uint40(block.timestamp);
        }
    }
    
    function getCompounds(address _addr) external view returns (uint256[] memory all_compound, uint256 total) {
        all_compound = staked[_addr];
        total = staked[_addr].length;
    }
}