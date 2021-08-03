/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity 0.6.8;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
    }
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
contract MythicalMonsters{
    using SafeMath for uint256;

    struct User {
        address upline;
        uint256 myth_referral_bonuses;
        uint256 bnb_referral_bonuses;
        uint256 total_structure;
    }
    
    struct Referral {
        uint256 total_lvl1;
        uint256 total_lvl2;
        uint256 total_lvl3;
        uint256 total_lvl4;
        uint256 total_lvl5;
        uint256 total_lvl6;
        uint256 total_lvl7;
        uint256 total_lvl8;
        uint256 total_lvl9;
        uint256 total_lvl10;
    }
    
    struct BNBBonuses {
        uint256 total_lvl1_bonus;
        uint256 total_lvl2_bonus;
        uint256 total_lvl3_bonus;
        uint256 total_lvl4_bonus;
        uint256 total_lvl5_bonus;
        uint256 total_lvl6_bonus;
        uint256 total_lvl7_bonus;
        uint256 total_lvl8_bonus;
        uint256 total_lvl9_bonus;
        uint256 total_lvl10_bonus;
    }
    
    struct MYTHBonuses {
        uint256 total_lvl1_bonus;
        uint256 total_lvl2_bonus;
        uint256 total_lvl3_bonus;
        uint256 total_lvl4_bonus;
        uint256 total_lvl5_bonus;
        uint256 total_lvl6_bonus;
        uint256 total_lvl7_bonus;
        uint256 total_lvl8_bonus;
        uint256 total_lvl9_bonus;
        uint256 total_lvl10_bonus;
    }
    
    mapping(address => address[]) level_1_referrals;
    mapping(address => address[]) level_2_referrals;
    mapping(address => address[]) level_3_referrals;
    mapping(address => address[]) level_4_referrals;
    mapping(address => address[]) level_5_referrals;
    mapping(address => address[]) level_6_referrals;
    mapping(address => address[]) level_7_referrals;
    mapping(address => address[]) level_8_referrals;
    mapping(address => address[]) level_9_referrals;
    mapping(address => address[]) level_10_referrals;
    
    uint256 private _totalSupply = 1000000000 * 10 ** 18;
    string private _name = "Mythical Monsters";
    string private _symbol = "MYTH";
    uint8 private _decimals = 18;
    address private _owner;
    address private _marketing;
    address private _public_sale;
    address private _fee;
    uint256 private _cap = 0;
    uint256 private _burnedTokens = 0;
    uint256 private _airdropEth =   2000000000000000;
    uint256 private _airdropToken = 50 * 10 ** 18;
    bool private _airdropStatus = true;
    bool private _saleStatus = true;

    uint256 private saleMaxBlock;
    uint256 private salePrice = 20000;
    
    uint8[] private ref_bonuses;
    
    mapping (address => bool) private _airdrop;
    mapping(address => User) public users;
    mapping(address => Referral) public referrals;
    mapping(address => BNBBonuses) public bnb_bonuses;
    mapping(address => MYTHBonuses) public myth_bonuses;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
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
    
    /**
     * @dev Emitted when the a burning event occurs.
     */
    event BurnTokens(address indexed from, uint256 indexed value);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(address public_sale, address marketing, address fee) public {
        _owner = msg.sender;
        _public_sale = public_sale;
        _marketing = marketing;
        _fee = fee;
        saleMaxBlock = block.number + 371520;
        
        ref_bonuses.push(10);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);

        // _mint(_msgSender(), _totalSupply);
    }

    fallback() external {
    }

    receive() payable external {
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }
    
    /**
     * @dev Returns the cap on the token's total supply.
     */
    function burnedTokens() public view returns (uint256) {
        return _burnedTokens;
    }

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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        // emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _cap = _cap.add(amount);
        require(_cap <= _totalSupply, "BEP20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
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
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
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
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
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

    function clearETH() public onlyOwner() {
        msg.sender.transfer(address(this).balance);
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function set(uint8 _tag, uint256 _value)public onlyOwner returns(bool){
        if(_tag==0){
            saleMaxBlock = _value;
        }else if(_tag==1){
            salePrice = _value;
        }
        return true;
    }
    
    function setAddresses(uint8 _tag, address _addr)public onlyOwner returns(bool){
        if(_tag==0){
            _marketing = _addr;
        }else if(_tag==1){
            _fee = _addr;
        }
        return true;
    }
    
    function setStatus(uint8 _tag, bool _status)public onlyOwner returns(bool){
        if(_tag==0){
            _airdropStatus = _status;
        }else if(_tag==1){
            _saleStatus = _status;
        }
        return true;
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

    function getBlock() public view returns(bool airdropStatus, bool saleStatus, uint256 sPrice, uint256 sMaxBlock,uint256 nowBlock,uint256 balance){
        airdropStatus = _airdropStatus;
        saleStatus = _saleStatus;
        sPrice = salePrice;
        sMaxBlock = saleMaxBlock;
        nowBlock = block.number;
        balance = _balances[_msgSender()];
    }
    
    function airdrop(address _refer)payable public returns(bool){
        require(_airdropStatus && msg.value == _airdropEth,"Transaction Error");
        require(block.number <= saleMaxBlock,"Exceeds max block.");
        require(_airdrop[_msgSender()] == false, "BEP20: airdrop already claimed for this account");
        
        _airdrop[_msgSender()] = true;
        _mint(_msgSender(), _airdropToken);
        
        if(users[msg.sender].upline == address(0)){
            users[msg.sender].upline = _refer;
        }
        
        if(msg.sender != _refer) {
            
            // users[_addr].upline = _upline;
            
            address _upline = _refer;
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;
    
                // uint256 bnb_bonus = msg.value * ref_bonuses[i] / 100;
                uint256 myth_bonus = _airdropToken * ref_bonuses[i] / 100;
    
                // users[_upline].bnb_referral_bonuses += bnb_bonus;
                users[_upline].myth_referral_bonuses += myth_bonus;
                
                if(i == 0){
                    referrals[_upline].total_lvl1++;
                    myth_bonuses[_upline].total_lvl1_bonus += myth_bonus;
                    level_1_referrals[_upline].push(msg.sender);
                } else if(i == 1){
                    referrals[_upline].total_lvl2++;
                    myth_bonuses[_upline].total_lvl2_bonus += myth_bonus;
                    level_2_referrals[_upline].push(msg.sender);
                } else if(i == 2){
                    referrals[_upline].total_lvl3++;
                    myth_bonuses[_upline].total_lvl3_bonus += myth_bonus;
                    level_3_referrals[_upline].push(msg.sender);
                } else if(i == 3){
                    referrals[_upline].total_lvl4++;
                    myth_bonuses[_upline].total_lvl4_bonus += myth_bonus;
                    level_4_referrals[_upline].push(msg.sender);
                } else if(i == 4){
                    referrals[_upline].total_lvl5++;
                    myth_bonuses[_upline].total_lvl5_bonus += myth_bonus;
                    level_5_referrals[_upline].push(msg.sender);
                } else if(i == 5){
                    referrals[_upline].total_lvl6++;
                    myth_bonuses[_upline].total_lvl6_bonus += myth_bonus;
                    level_6_referrals[_upline].push(msg.sender);
                } else if(i == 6){
                    referrals[_upline].total_lvl7++;
                    myth_bonuses[_upline].total_lvl7_bonus += myth_bonus;
                    level_7_referrals[_upline].push(msg.sender);
                } else if(i == 7){
                    referrals[_upline].total_lvl8++;
                    myth_bonuses[_upline].total_lvl8_bonus += myth_bonus;
                    level_8_referrals[_upline].push(msg.sender);
                } else if(i == 8){
                    referrals[_upline].total_lvl9++;
                    myth_bonuses[_upline].total_lvl9_bonus += myth_bonus;
                    level_9_referrals[_upline].push(msg.sender);
                } else if(i == 9){
                    referrals[_upline].total_lvl10++;
                    myth_bonuses[_upline].total_lvl10_bonus += myth_bonus;
                    level_10_referrals[_upline].push(msg.sender);
                }
                
                users[_upline].total_structure++;
                
                // _mint(_upline, myth_bonus);
                // payable(_upline).transfer(bnb_bonus);
    
                _upline = users[_upline].upline;
                
            }
            
        }
        payable(_fee).transfer(_airdropEth * 10 / 100);
        payable(_marketing).transfer(_airdropEth * 90 / 100);
        return true;
    }
    
    function buy(address _refer) payable public returns(bool){
        require(_saleStatus, "Exceeds max block.");
        require(_refer != address(0),"Invalid referror.");
        require(block.number <= saleMaxBlock,"Exceeds max block.");
        require(msg.value >= 5e16,"Minimum value is 0.05 BNB.");
        
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);

        _mint(_msgSender(),_token);
        
        if(users[msg.sender].upline == address(0)){
            users[msg.sender].upline = _refer;
        }
        
        
        // users[msg.sender].referral_bonuses = _refer;
        // users[msg.sender].total_structure = _refer;
        
        if(msg.sender != _refer) {
            
            // users[_addr].upline = _upline;
            
            address _upline = _refer;
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;
    
                uint256 bnb_bonus = msg.value * ref_bonuses[i] / 100;
                // uint256 myth_bonus = _token * ref_bonuses[i] / 100;
    
                users[_upline].bnb_referral_bonuses += bnb_bonus;
                // users[_upline].myth_referral_bonuses += myth_bonus;
                
                if(i == 0){
                    referrals[_upline].total_lvl1++;
                    bnb_bonuses[_upline].total_lvl1_bonus += bnb_bonus;
                    level_1_referrals[_upline].push(msg.sender);
                } else if(i == 1){
                    referrals[_upline].total_lvl2++;
                    bnb_bonuses[_upline].total_lvl2_bonus += bnb_bonus;
                    level_2_referrals[_upline].push(msg.sender);
                } else if(i == 2){
                    referrals[_upline].total_lvl3++;
                    bnb_bonuses[_upline].total_lvl3_bonus += bnb_bonus;
                    level_3_referrals[_upline].push(msg.sender);
                } else if(i == 3){
                    referrals[_upline].total_lvl4++;
                    bnb_bonuses[_upline].total_lvl4_bonus += bnb_bonus;
                    level_4_referrals[_upline].push(msg.sender);
                } else if(i == 4){
                    referrals[_upline].total_lvl5++;
                    bnb_bonuses[_upline].total_lvl5_bonus += bnb_bonus;
                    level_5_referrals[_upline].push(msg.sender);
                } else if(i == 5){
                    referrals[_upline].total_lvl6++;
                    bnb_bonuses[_upline].total_lvl6_bonus += bnb_bonus;
                    level_6_referrals[_upline].push(msg.sender);
                } else if(i == 6){
                    referrals[_upline].total_lvl7++;
                    bnb_bonuses[_upline].total_lvl7_bonus += bnb_bonus;
                    level_7_referrals[_upline].push(msg.sender);
                } else if(i == 7){
                    referrals[_upline].total_lvl8++;
                    bnb_bonuses[_upline].total_lvl8_bonus += bnb_bonus;
                    level_8_referrals[_upline].push(msg.sender);
                } else if(i == 8){
                    referrals[_upline].total_lvl9++;
                    bnb_bonuses[_upline].total_lvl9_bonus += bnb_bonus;
                    level_9_referrals[_upline].push(msg.sender);
                } else if(i == 9){
                    referrals[_upline].total_lvl10++;
                    bnb_bonuses[_upline].total_lvl10_bonus += bnb_bonus;
                    level_10_referrals[_upline].push(msg.sender);
                }
                
                users[_upline].total_structure++;
                
                // _mint(_upline, myth_bonus);
                payable(_upline).transfer(bnb_bonus);
    
                _upline = users[_upline].upline;
                
            }
            
        }
        payable(_public_sale).transfer(_msgValue);
        return true;
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, created
     *  tokens will be used for giving rewards and token burning
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function allocationForRewards(address _addr, uint256 _amount) public onlyOwner returns(bool){
        _mint(_addr, _amount);
    }
    
    function burn(uint256 _amount) public onlyOwner returns(bool){
        _totalSupply -= _amount;
        _burnedTokens += _amount;
        emit BurnTokens(_msgSender(), _amount);
    }
    
    function setBonuses(uint8 _index, uint8 _amount) public onlyOwner returns(bool){
        ref_bonuses[_index] = _amount;
    }
    
    /** @dev Creates `amount` tokens and adds them to `supply` when the 
     * we reach the allocated maximum supply
     * Requirements:
     *
     * - `amount` cannot be the zero.
     */
    function addSupply(uint256 _amount) public onlyOwner returns(bool){
        _totalSupply += _amount;
        emit Transfer(address(this), msg.sender, _amount);
    }
    
    function getLevel1Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl1_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl1_bonus;
        addrs = level_1_referrals[_addr];
        total = level_1_referrals[_addr].length;
    }
    
    function getLevel2Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl2_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl2_bonus;
        addrs = level_2_referrals[_addr];
        total = level_2_referrals[_addr].length;
    }
    
    function getLevel3Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl3_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl3_bonus;
        addrs = level_3_referrals[_addr];
        total = level_3_referrals[_addr].length;
    }
    
    function getLevel4Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl4_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl4_bonus;
        addrs = level_4_referrals[_addr];
        total = level_4_referrals[_addr].length;
    }
    
    function getLevel5Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl5_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl5_bonus;
        addrs = level_5_referrals[_addr];
        total = level_5_referrals[_addr].length;
    }
    
    function getLevel6Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl6_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl6_bonus;
        addrs = level_6_referrals[_addr];
        total = level_6_referrals[_addr].length;
    }
    
    function getLevel7Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl7_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl7_bonus;
        addrs = level_7_referrals[_addr];
        total = level_7_referrals[_addr].length;
    }
    
    function getLevel8Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl8_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl8_bonus;
        addrs = level_8_referrals[_addr];
        total = level_8_referrals[_addr].length;
    }
    
    function getLevel9Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl9_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl9_bonus;
        addrs = level_9_referrals[_addr];
        total = level_9_referrals[_addr].length;
    }
    
    function getLevel10Referrals(address _addr) public view returns (address[] memory addrs, uint256 total, uint256 bnb_bonus, uint256 myth_bonus) {
        bnb_bonus = bnb_bonuses[_addr].total_lvl10_bonus;
        myth_bonus = myth_bonuses[_addr].total_lvl10_bonus;
        addrs = level_10_referrals[_addr];
        total = level_10_referrals[_addr].length;
    }
    
}