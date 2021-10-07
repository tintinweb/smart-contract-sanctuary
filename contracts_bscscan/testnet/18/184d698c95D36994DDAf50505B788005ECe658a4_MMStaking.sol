/**
 *Submitted for verification at BscScan.com on 2021-10-07
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
    address constant MYTH_TOKEN_ADDRESS = 0xF242a188c50d5182EC6D7653d3D6B3ED23b431cC;
    
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
    mapping(uint256 => Stake) public stakes; // bot_stats
    
    address public owner;
    uint256 public balance;
    uint256 public total_earnings;
    
    bool public status;
    
    uint256 public total_users;
    address[] public staked_users;
    
    uint256 public total_stake_count;
    
    mapping(address => uint256[]) staked; // bots
    
    event Compound(address indexed addr, uint256 indexed bot_id, uint256 indexed amount);
    event Staked(address indexed addr, uint256 indexed amount);
    event Claim(address indexed addr, uint256 indexed amount);
    event Unstaked(address indexed addr, uint256 indexed amount);
    event Withdraw(address indexed addr, uint256 indexed amount);
    
    constructor() {
        owner = msg.sender;
        total_stake_count = 0;
        status = true;
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
        require(_amount > 999 * 10 ** 18, "Error: Minimum 1000 MYTH.");
        require(IERC20(MYTH_TOKEN_ADDRESS).balanceOf(msg.sender) > 0, "Error: Insufficient balance.");
        require(users[msg.sender].unstaked == 0, "Error: Claim your unstaked MYTH first.");
        
        // _amount = _amount * 10 ** 18;
        
        IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), _amount);
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        
        users[msg.sender].deposit_time += uint40(block.timestamp);
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
        
        // if(users[_addr].total_withdraw < users[_addr].activated_time) {
        //     unlocked = (users[_addr].total_deposit * ((block.timestamp - users[_addr].deposit_time) / 1 years) * 2 / 100) - users[_addr].total_withdraw;
            
        //     if(users[_addr].total_withdraw + unlocked > users[_addr].total_deposit) {
        //         unlocked = users[_addr].total_deposit - users[_addr].total_withdraw;
        //     }
        // }
        
        return unlocked;
    }
    
    // function getSeconds(uint256 _stake_id) external view returns (uint256){
    //     return block.timestamp - stakes[_stake_id].activated_time;
    // }
    
    // function checkEarnings(uint256 _stake_id) public view returns (uint256 _seconds, uint256 _amount){
    //     uint256 every_seconds = (stakes[_stake_id].fund * 20 / 100) / 24 / 60 / 60;
    //     _amount = (block.timestamp - stakes[_stake_id].activated_time) * every_seconds;
    //     _seconds = (stakes[_stake_id].fund * 20 / 100) / 24 / 60 / 60;
    // }
    
    // function claim() public {
    //     require(users[msg.sender].total_deposit > 0, "Error: Insufficient permission.");
    //     require(this.calculateUnlockedTokens(msg.sender) > 0, "Error: No withdrawable balance.");
        
    //     uint256 amount = this.calculateUnlockedTokens(msg.sender);
        
    //     IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), amount); // ?
    //     IERC20(MYTH_TOKEN_ADDRESS).transferFrom(address(this), msg.sender, amount);
        
    //     users[msg.sender].total_withdraw += amount;
    //     balance -= amount;
        
    //     emit Withdraw(msg.sender, amount);
    // }
    
    function claim() external {
        if(users[msg.sender].unstaked > 0){
            _withdraw();
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
    
        balance -= payout;
        
        IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), payout); 
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(owner, msg.sender, payout);
        
        emit Claim(msg.sender, payout);
    }
    
    function unstake() external {
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
        
        users[msg.sender].unclaimed = payout;
        
        for(uint8 i = 0; i < staked[msg.sender].length; i++) {
            uint256 stake_id = staked[msg.sender][i];
            
            if(stakes[stake_id].active){
                stakes[stake_id].active = false;
            }
            
        }
        
        users[msg.sender].unstaked = users[msg.sender].total_deposit;
        users[msg.sender].unstaked_time = uint40(block.timestamp);
        
        emit Unstaked(msg.sender, users[msg.sender].unstaked);
    }
    
    // function getDays() public pure returns (uint256){
    //     return 1 days;
    // }
        
    function _withdraw() internal {
        require(users[msg.sender].unstaked > 0,"Error: No staked MYTH.");
        // require((block.timestamp - users[msg.sender].unstaked_time) / 1 days > 7,"Error: Too early."); // check days remaining
        require((block.timestamp - users[msg.sender].unstaked_time) / 1 minutes > 1,"Error: Too early.");
        
        IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), users[msg.sender].unclaimed);
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(owner, msg.sender, users[msg.sender].unclaimed);
        
        IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), users[msg.sender].unstaked);
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(address(this), msg.sender, users[msg.sender].unstaked);
        
        users[msg.sender].unclaimed = 0;
        users[msg.sender].unstaked = 0;
        users[msg.sender].unstaked_time = 0;
        
        users[msg.sender].compound = 0;
        users[msg.sender].deposit_time = 0;
        users[msg.sender].total_deposit = 0;
        
        // clear array
        for(uint256 i = 0; i < staked[msg.sender].length; i++){
            // delete staked[msg.sender][i];
            staked[msg.sender].pop();
        }
        
        // uint256 amount = users[msg.sender].unstaked + users[msg.sender].unclaimed;
        
        total_users--;
        balance -= users[msg.sender].unstaked;
        
        emit Withdraw(msg.sender, users[msg.sender].unclaimed + users[msg.sender].unstaked);
    }
    
    function set(uint256 _tag, uint256 _value) external {
        require(msg.sender == owner, "Error: Insufficient balance.");
        
        if(_tag == 0){
            status = 1==_value;
        }
    }
    
    function getCompounds(address _addr) public view returns (uint256[] memory all_compound, uint256 total) {
        all_compound = staked[_addr];
        total = staked[_addr].length;
    }
    
    function withdrawAll() external {
        IERC20(MYTH_TOKEN_ADDRESS).approve(address(this), balance);
        IERC20(MYTH_TOKEN_ADDRESS).transferFrom(address(this), msg.sender, balance);
    }
}