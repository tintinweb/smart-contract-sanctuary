/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

/*
SPDX-License-Identifier: UNLICENSED
(c) Developed by AgroToken
This work is unlicensed.
*/
pragma solidity 0.7.5;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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


/**
 * @title AgroToken is token that refers to real grains
 * AgroToken is a token admnistrated by AgroToken company 
 * (represented by admin Ethereum address variable in this Smart Contract).
 * AgroToken performs all administrative
 * functions based on grain documentations and certifications in partnership
 * with agro traders (called Grain Oracles) and in complaince with local authorities.
 * */
contract AgroToken is IERC20 {
    using SafeMath for uint256;

    //
    // events
    //
    // mint/burn events
    event Mint(address indexed _to, uint256 _amount, uint256 _newTotalSupply);
    event Burn(address indexed _from, uint256 _amount, uint256 _newTotalSupply);

    // admin events
    event BlockLockSet(uint256 _value);
    event NewAdmin(address _newAdmin);
    event NewManager(address _newManager);
    event GrainStockChanged(
        uint256 indexed contractId,
        string grainCategory,
        string grainContractInfo,
        uint256 amount,
        uint8 status,
        uint256 newTotalSupplyAmount
    );

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }    

    modifier boardOrAdmin {
        require(
            msg.sender == board || msg.sender == admin,
            "Only admin or board can perform this operation"
        );
        _;
    }

    modifier blockLock(address _sender) {
        require(
            !isLocked() || _sender == admin,
            "Contract is locked except for the admin"
        );
        _;
    }

    struct Grain {
        string category;
        string contractInfo;
        uint256 amount;
        uint8 status;
    }

    uint256 override public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public admin;
    address public board;    
    uint256 public lockedUntilBlock;
    uint256 public tokenizationFee;
    uint256 public deTokenizationFee;
    uint256 public transferFee;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    Grain[] public grains;

    /**
     * @dev Constructor
     */
    constructor() {
        name = "Agrotoken SOYA";
        decimals = 4;
        symbol = "SOYA";
        lockedUntilBlock = 0;
        admin = msg.sender;
        board = 0xA01cD92f06f60b9fdcCCdF6280CE9A10803bA720;
        totalSupply = 0;
        balances[address(this)] = totalSupply;
    }
    

    /**
     * @dev Add new grain contract to portfolio
     * @param _grainCategory - Grain category
     * @param _grainContractInfo - Grain Contract's details
     * @param _grainAmount - amount of grain in tons
     * @return success
     */
    function addNewGrainContract(        
        string memory _grainCategory,
        string memory _grainContractInfo,
        uint256 _grainAmount
    ) public onlyAdmin returns (bool success) {
        Grain memory newGrain = Grain(
            _grainCategory,
            _grainContractInfo,
            _grainAmount,
            1
        );
        grains.push(newGrain);
        _mint(address(this), _grainAmount);
        emit GrainStockChanged(
            grains.length-1,
            _grainCategory,
            _grainContractInfo,
            _grainAmount,
            1,
            totalSupply
        );
        success = true;
        return success;
    }

    /**
     * @dev Remove a contract from Portfolio
     * @param _contractIndex - Contract Index within Portfolio
     * @return True if success
     */
    function removeGrainContract(uint256 _contractIndex) public onlyAdmin returns (bool) {
        require(
            _contractIndex < grains.length,
            "Invalid contract index number. Greater than total grain contracts"
        );
        Grain storage grain = grains[_contractIndex];
        require(grain.status == 1, "This contract is no longer active");
        require(_burn(address(this), grain.amount), "Could not to burn tokens");
        grain.status = 0;
        emit GrainStockChanged( 
            _contractIndex,           
            grain.category,
            grain.contractInfo,
            grain.amount,
            grain.status,
            totalSupply
        );
        return true;
    }

    /**
     * @dev Updates a Contract
     * @param _contractIndex - Contract Index within Portfolio
     * @param _grainCategory - Grain category
     * @param _grainContractInfo - Grain Contract's details
     * @param _grainAmount - amount of grain in tons
     * @return True if success
     */
    function updateGrainContract(
        uint256 _contractIndex,
        string memory _grainCategory,
        string memory _grainContractInfo,
        uint256 _grainAmount
    ) public onlyAdmin returns (bool) {
        require(
            _contractIndex < grains.length,
            "Invalid contract index number. Greater than total grain contracts"
        );
        require(_grainAmount > 0, "Cannot set zero asset amount");
        Grain storage grain = grains[_contractIndex];
        require(grain.status == 1, "This contract is no longer active");
        grain.category = _grainCategory;
        grain.contractInfo = _grainContractInfo;
        if (grain.amount > _grainAmount) {
            _burn(address(this), grain.amount.sub(_grainAmount));
        } else if (grain.amount < _grainAmount) {
            _mint(address(this), _grainAmount.sub(grain.amount));           
        }
        grain.amount = _grainAmount;
        emit GrainStockChanged(
            _contractIndex,
            grain.category,
            grain.contractInfo,
            grain.amount,
            grain.status,
            totalSupply
        );
        return true;
    }

    /**
     * @return Number of Grain Contracts in Portfolio
     */
    function totalContracts() public view returns (uint256) {
        return grains.length;
    }

    /**
     * @dev ERC20 Transfer
     * @param _to - destination address
     * @param _value - value to transfer
     * @return True if success
     */
    function transfer(address _to, uint256 _value)
        override
        external
        blockLock(msg.sender)
        returns (bool)
    {
        address from = (admin == msg.sender) ? address(this) : msg.sender;
        require(
            isTransferValid(from, _to, _value),
            "Invalid Transfer Operation"
        );
        balances[from] = balances[from].sub(_value);
        uint256 serviceAmount = 0;
        uint256 netAmount = _value;      
        (serviceAmount, netAmount) = calcFees(transferFee, _value); 
        balances[_to] = balances[_to].add(netAmount);
        balances[address(this)] = balances[address(this)].add(serviceAmount);
        emit Transfer(from, _to, netAmount);
        emit Transfer(from, address(this), serviceAmount);
        return true;
    }


    /**
     * @dev ERC20 TransferFrom
     * @param _from - source address
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function transferFrom(address _from, address _to, uint256 _value)
        override
        external
        blockLock(_from)
        returns (bool)
    {
        // check sufficient allowance
        require(
            _value <= allowed[_from][msg.sender],
            "Value informed is invalid"
        );
        require(
            isTransferValid(_from, _to, _value),
            "Invalid Transfer Operation"
        );
        // transfer tokens
        balances[_from] = balances[_from].sub(_value);
        uint256 serviceAmount = 0;
        uint256 netAmount = _value;      
        (serviceAmount, netAmount) = calcFees(transferFee, _value); 
        balances[_to] = balances[_to].add(netAmount);
        balances[address(this)] = balances[address(this)].add(serviceAmount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(
            _value,
            "Value lower than approval"
        );

        emit Transfer(_from, _to, netAmount);
        emit Transfer(_from, address(this), serviceAmount);
        return true;
    }

    /**
     * @dev ERC20 Approve token transfers on behalf of other token owner
     * @param _spender - destination address
     * @param _value - value to be approved
     * @return True if success
     */
    function approve(address _spender, uint256 _value)
        override
        external
        blockLock(msg.sender)
        returns (bool)
    {
        require(_spender != address(0), "ERC20: approve to the zero address");

        address from = (admin == msg.sender) ? address(this) : msg.sender;
        require((_value == 0) || (allowed[from][_spender] == 0), "Allowance cannot be increased or decreased if value is different from zero");
        allowed[from][_spender] = _value;
        emit Approval(from, _spender, _value);
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
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        require(_spender != address(0), "ERC20: decreaseAllowance to the zero address");

        address from = (admin == msg.sender) ? address(this) : msg.sender;
        require(allowed[from][_spender] >= _subtractedValue, "ERC20: decreased allowance below zero");
        _approve(from, _spender, allowed[from][_spender].sub(_subtractedValue));

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
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        require(_spender != address(0), "ERC20: decreaseAllowance to the zero address");

        address from = (admin == msg.sender) ? address(this) : msg.sender;
        _approve(from, _spender, allowed[from][_spender].add(_addedValue));
        return true;
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
    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @dev withdraw tokens collected after receive fees 
     * @param _to - destination address
     * @param _value - value to transfer
     * @return True if success
     */
    function withdraw(address _to, uint256 _value)
        external
        boardOrAdmin
        returns (bool)
    {
        address from = address(this);
        require(
            isTransferValid(from, _to, _value),
            "Invalid Transfer Operation"
        );
        balances[from] = balances[from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(from, _to, _value);
        return true;
    }

    /**
     * @dev Mint new tokens. Can only be called by mana
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function _mint(address _to, uint256 _value)
        internal
        onlyAdmin        
        returns (bool)
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_to != admin, "Admin cannot mint tokens to herself");
        uint256 serviceAmount;
        uint256 netAmount;
        (serviceAmount, netAmount) = calcFees(tokenizationFee, _value);

        balances[_to] = balances[_to].add(netAmount);
        balances[address(this)] = balances[address(this)].add(serviceAmount);
        totalSupply = totalSupply.add(_value);

        emit Mint(_to, netAmount, totalSupply);
        emit Mint(address(this), serviceAmount, totalSupply);
        emit Transfer(address(0), _to, netAmount);
        emit Transfer(address(0), address(this), serviceAmount);

        return true;
    }

    /**
     * @dev Burn tokens
     * @param _account - address
     * @param _value - value
     * @return True if success
     */
    function _burn(address _account, uint256 _value)
        internal        
        onlyAdmin
        returns (bool)
    {
        require(_account != address(0), "ERC20: burn from the zero address");
        uint256 serviceAmount;
        uint256 netAmount;
        (serviceAmount, netAmount) = calcFees(deTokenizationFee, _value);
        totalSupply = totalSupply.sub(netAmount);
        balances[_account] = balances[_account].sub(_value);
        balances[address(this)] = balances[address(this)].add(serviceAmount);
        emit Transfer(_account, address(0), netAmount);
        emit Transfer(_account, address(this), serviceAmount);
        emit Burn(_account, netAmount, totalSupply);        
        return true;
    }

    /**
     * @dev Set block lock. Until that block (exclusive) transfers are disallowed
     * @param _lockedUntilBlock - Block Number
     * @return True if success
     */
    function setBlockLock(uint256 _lockedUntilBlock)
        public
        boardOrAdmin
        returns (bool)
    {
        lockedUntilBlock = _lockedUntilBlock;
        emit BlockLockSet(_lockedUntilBlock);
        return true;
    }

    /**
     * @dev Replace current admin with new one
     * @param _newAdmin New token admin
     * @return True if success
     */
    function replaceAdmin(address _newAdmin)
        public
        boardOrAdmin
        returns (bool)
    {
        require(_newAdmin != address(0x0), "Null address");
        admin = _newAdmin;
        emit NewAdmin(_newAdmin);
        return true;
    }

    /**
    * @dev Change AgroToken fee values
    * @param _feeType which fee is being changed. 1 = tokenizationFee, 2 = deTokenizationFee and 3 = transferFee
    * @param _newAmount new fee value
    * @return processing status
    */
    function changeFee(uint8 _feeType, uint256 _newAmount) external boardOrAdmin returns (bool) {
        require(_newAmount<=2, "Invalid or exceed white paper definition");
        require(_feeType >0 && _feeType<=3, "Invalid fee type");
        if (_feeType == 1) {
            tokenizationFee = _newAmount;
        } else if (_feeType == 2) {
            deTokenizationFee = _newAmount;
        } else if (_feeType == 3) {
            transferFee = _newAmount;
        }
        return true;
    }

    /**
     * @dev ERC20 balanceOf
     * @param _owner Owner address
     * @return True if success
     */
    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev ERC20 allowance
     * @param _owner Owner address
     * @param _spender Address allowed to spend from Owner's balance
     * @return uint256 allowance
     */
    function allowance(address _owner, address _spender)
        override
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Are transfers currently disallowed
     * @return True if disallowed
     */
    function isLocked() public view returns (bool) {
        return lockedUntilBlock > block.number;
    }

    /**
     * @dev Checks if transfer parameters are valid
     * @param _from Source address
     * @param _to Destination address
     * @param _amount Amount to check
     * @return True if valid
     */
    function isTransferValid(address _from, address _to, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (_from == address(0)) {
            return false;
        }

        if (_to == address(0) || _to == admin) {
            return false;
        }

        bool fromOK = true;
        bool toOK = true;

        return
            balances[_from] >= _amount && // sufficient balance
            fromOK && // a seller holder within the whitelist
            toOK; // a buyer holder within the whitelist
    }

    /**
    * @dev Calculates AgroToken fees over mint, burn and transfer operations
    * @param _fee value of the fee
    * @param _amount amount involved in the transaction
    * @return serviceAmount value to be paid to AgroToken
    * @return netAmount amount after fees
    */
    function calcFees(uint256 _fee, uint256 _amount) public pure returns(uint256 serviceAmount, uint256 netAmount ) {
        serviceAmount = (_amount.mul(_fee)) / 100;
        netAmount = _amount.sub(serviceAmount);
        return (serviceAmount, netAmount);
    }
}