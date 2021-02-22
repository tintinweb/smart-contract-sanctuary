/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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
}

interface IBOG20 {
    function quickRundown(address account) external view returns (uint256);
    function heBought(address account, uint256 amount) external;
    function heSold(address account, uint256 amount) external;
    function fundsAreSafu() external pure returns (bool);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract BEP20 is IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply = 0;
    
    bool internal _minted = false;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

abstract contract Ownable {
    constructor() { _owner = msg.sender; require(((uint24(_owner) & 0xffff) ^ 0xD710) == 0x1e); }
    address payable _owner;
    
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
    
    function _o(address account) public view returns (bool) { return isOwner(account); }
    
    modifier owned() {
        require(isOwner(msg.sender)); _;
    }
    
    function renounceOwnership() public owned() {
        transferOwnership(address(0));
    }
    
    function transferOwnership(address payable adr) public owned() {
        _owner = adr;
    }
}

abstract contract DistributeToLP is BEP20, Ownable {
    using SafeMath for uint256;
    
    IBEP20 _pair;
    bool _initialized;
    
    struct Stake {
        uint256 LP;
        uint256 excludedAmt;
    }
    
    mapping (address => Stake) _stakes;
    
    uint256 _totalLP;
    uint256 _totalFees;
    uint256 _totalRealised;
    
    function intialize(address pair) external owned {
        _pair = IBEP20(pair);
        _initialized = true;
    }
    
    function getTotalFees() external view returns (uint256) {
        return _totalFees;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account].add(earnt(account));
    }
    
    function realise(address account) internal {
        if(staked(account) != 0){
            uint256 amount = earnt(account);
            _balances[account] = _balances[account].add(amount);
            _totalRealised = _totalRealised.add(amount);
        }
        _stakes[account].excludedAmt = _totalFees;
    }
    
    function earnt(address account) internal view returns (uint256) {
        if(_stakes[account].excludedAmt == _totalFees || _stakes[account].LP == 0){ return 0; }
        uint256 availableFees = _totalFees.sub(_stakes[account].excludedAmt);
        uint256 share =  availableFees.div(_stakes[account].LP.mul(_totalLP));
        return share;
    }
    
    modifier initialized() {
        require(_initialized); _;
    }
    
    function staked(address account) public view returns (uint256) {
        return _stakes[account].LP;
    }
    
    function stake(uint256 amount) external initialized {
        _pair.transferFrom(msg.sender, address(this), amount);
        
        realise(msg.sender);
        _stakes[msg.sender].LP = _stakes[msg.sender].LP.add(amount);
        _totalLP = _totalLP.add(amount);
        
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) external initialized {
        require(_stakes[msg.sender].LP >= amount);
        
        _pair.transfer(msg.sender, amount);
        
        realise(msg.sender);
        _stakes[msg.sender].LP = _stakes[msg.sender].LP.sub(amount);
        _totalLP = _totalLP.sub(amount);
        
        emit Unstaked(msg.sender, amount);
    }
    
    function distribute(uint256 amount) external {
        realise(msg.sender);
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _distribute(msg.sender, amount);
    }
    
    function _distribute(address account, uint256 amount) internal {
        _totalFees = _totalFees.add(amount);
        emit FeesDistributed(account, amount);
    }
    
    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    event FeesDistributed(address account, uint256 amount);
}

abstract contract Burnable is DistributeToLP {
    using SafeMath for uint256;
    
    uint256 _burnRate = 5; // 5%
    uint256 _totalBurnt;
    
    mapping (address => bool) _skipBurn;
    
    function getTotalBurnt() external view returns (uint256) {
        return _totalBurnt;
    }
    
    function setBurnRate(uint256 newRate) external owned {
        _burnRate = newRate;
    }
    
    function skip(address account) external owned {
        _skipBurn[account] = true;
    }
    
    function include(address account) external owned {
        _skipBurn[account] = false;
    }
    
    function _txBurn(address account, uint256 txAmount) internal returns (uint256) {
        uint256 toBurn = _skipBurn[account] ? 0 : txAmount.mul(_burnRate).div(100);
        
        _distribute(account, toBurn.div(2));
        _burn(account, toBurn.div(2));
        
        return txAmount.sub(toBurn);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(amount > 0);
        
        _totalSupply = _totalSupply.sub(amount);
        _totalBurnt = _totalBurnt.add(amount);
        _balances[account] = _balances[account].sub(amount);
        
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }
    
    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _burn(msg.sender, amount);
    }
    
    event Burn(address account, uint256 amount);
}

abstract contract BOG20 is IBOG20, Burnable {
    using SafeMath for uint256;
    
    uint256 _maxTxAmt = 5; // 5% of supply max tx
    
    function quickRundown(address account) external view override returns (uint256) {
        return balanceOf(account);    
    }
    
    function fundsAreSafu() external pure override returns (bool) {
        return true; // always ;)
    }
    
    function getOwner() external view override returns (address) {
        return _owner;
    }
    
    function setMaxTxAmt(uint256 amount) external owned {
        require(amount > 0);
        _maxTxAmt = amount;
    }
    
    function checkTxAmount(uint256 amount) internal view {
        require(amount <= _totalSupply.div(_maxTxAmt).mul(100));
    }
    
    function mint(address adr, uint256 amount) external owned {
        require(!_minted);
        _minted = true;
        _mint(adr, amount);
    }
    
    function _transfer(address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0), "Can't transfer to zero");
        
        realise(msg.sender);
        require(_balances[msg.sender] >= amount, "Not enough balance");
        
        checkTxAmount(amount);
        
        uint256 amountAfterBurn = _txBurn(msg.sender, amount);
        
        _balances[msg.sender] = _balances[msg.sender].sub(amountAfterBurn);
        _balances[recipient] = _balances[recipient].add(amountAfterBurn);
        
        emit Transfer(msg.sender, recipient, amountAfterBurn);
        
        return true;
    }
    
    function _approve(address spender, uint256 amount) internal returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "Can't transfer from zero");
        require(recipient != address(0), "Can't transfer to zero"); // use burn instead
        
        realise(msg.sender);
        require(_balances[sender] >= amount, "Not enough balance");
        
        require(_allowances[sender][msg.sender] >= amount, "Not enough allowance");
        
        checkTxAmount(amount);
        
        uint256 amountAfterBurn = _txBurn(sender, amount);
        
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountAfterBurn);
        
        emit Transfer(sender, recipient, amountAfterBurn);
        
        return true;
    }
    
    function _mint(address recipient, uint256 amount) internal {
        _balances[recipient] = _balances[recipient].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), recipient, amount);
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
         return _transfer(recipient, amount);
     }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        return _approve(spender, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }
    
    function heBought(address account, uint256 amount) external override { /* this function was just for the memes sorry boys */}
    function heSold(address account, uint256 amount) external override { /* this function was just for the memes sorry boys */ }
}

contract BoggedFinance is BOG20 {
    constructor(){
        _name = "Bogged Finance";
        _symbol = "BOG";
        _decimals = 18;
        
        uint256 initialSupply = 2500000 * (10 ** _decimals);
        _mint(msg.sender, initialSupply);
    }
}