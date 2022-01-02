/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;


interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function lockDays(uint daysAfter) public virtual onlyOwner {
        lock(daysAfter * 1 days);
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
    @dev Compiler Settings
    version v0.8.7+commit.e28d00a7
    Enable Optimization True 500 runs

*/
contract WDAOToken is IERC20, Ownable {
    using SafeMath for uint256;

    struct AccountInfo {
        uint256 balance;
        uint256 index;
        bool created;
    }


    mapping(address => AccountInfo) public _accountInfos;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    // 分红
    uint256 public constant A_BOUNS_CONDITION = 100 ether; // 分红最低限制， >= 100 代币
    mapping(uint256 => address) public _abounsList; // 可领分红的地址
    uint256[] public _abounsIndex;
    uint256 public _abounsOffset;
    

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 public _previousTaxFee;

    // 黑洞地址
    address public _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
    // 池子钱包
    address public _projectParty = address(0x992957022c16B80edC490642e829533260dEcE81);
    // 营销钱包
    address public _projectMarketing = address(0x0A126Bda58Dab896EE4FE5284054E06F15F1d92C);
    // 团队钱包
    address public _projectTeams = address(0xd82BC89600F0480755b61932c38E903267239602);
    // 公募钱包
    address public _projectPlacement = address(0xd919654cAd6FE04299AEC6aC1cC4cA80A6EF897a);


    bool inSwapAndLiquify;
    bool public swapEnabled = true;
    // LP Token Pool Address
    address public lpPoolAddress;
   

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _name = "LPT Token";
        _symbol = "LPT";
        _decimals = 18;

        _tTotal = 60000 * 10**_decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        _projectParty = msg.sender;

        _createAccount(address(this), 0);
        _createAccount(_projectParty, _tTotal);
        _createAccount(_projectMarketing, 0);
        _createAccount(_destroyAddress, 0);
        _abounsOffset = _abounsIndex.length;

        // exclude owner and this contract from fee
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_projectParty] = true;
        _isExcludedFromFee[_projectMarketing] = true;
        _isExcludedFromFee[_projectTeams] = true;
        _isExcludedFromFee[_projectPlacement] = true;

        _owner = _projectParty;
        emit Transfer(address(0), _projectParty, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_accountInfos[account].balance);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _tTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function abounsLength() public view returns(uint256) {
        return _abounsIndex.length - _abounsOffset;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setLPPoolAddress(address account) external onlyOwner {
        require(account != lpPoolAddress, 'This address was already used');
        lpPoolAddress = account;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private pure returns (uint256) {
        //(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return 1;//rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer( address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(lpPoolAddress != from, "LP Pool cannot transfer");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) lockTheSwap private {
        uint256 currentRate = _getRate();

        // 扣除发送人的
        uint256 rAmount = tAmount.mul(currentRate);
        AccountInfo storage senderInfo = _accountInfos[sender];
        senderInfo.balance = senderInfo.balance.sub(rAmount);

        uint256 rate;
        if (takeFee && swapEnabled) {
            // 销毁 2%
            _takeFee(sender, _destroyAddress, tAmount.div(100).mul(2), currentRate);
            // 营销 3%
            _takeFee(sender, _projectMarketing, tAmount.div(100).mul(3), currentRate);
            // 分红 3%
            _takeAbonus(sender, tAmount.div(100).mul(3), currentRate);
            // 滑点 8%
            rate = 8;
        }

        // 接收
        uint256 recipientRate = 100 - rate;
        uint256 amount = rAmount.div(100).mul(recipientRate);
        AccountInfo storage recipientInfo = _accountInfos[recipient];
        recipientInfo.balance = recipientInfo.balance.add(amount);
        emit Transfer(sender, recipient, amount);


        // 转出后如果不满足分红条件，则在分红列表中移除
        if (senderInfo.balance < A_BOUNS_CONDITION && senderInfo.index >= _abounsOffset) {
            uint256 lastIndex = _abounsIndex.length - 1;
            uint256 deleteIndex = senderInfo.index;

            if (lastIndex > deleteIndex) {
                address lastValue = _abounsList[lastIndex];
                AccountInfo storage info = _accountInfos[lastValue];

                // 交换位置
                info.index = deleteIndex;
                _abounsList[deleteIndex] = lastValue;
            }
            senderInfo.created = false;
            senderInfo.index = 0;
            // 删除最后一个
            _abounsIndex.pop();

        }


        // 判断是否特定地址
        if (recipient == _projectTeams || recipient == _projectPlacement || recipient == _projectMarketing || recipient == _projectParty)
            return;
        
        // 判断总数是否达到分红条件
        // 接收后如果满足分红条件，则添加到分红列表
        if (recipientInfo.balance >= A_BOUNS_CONDITION && recipientInfo.created == false) {
            _updateAccount(recipient, recipientInfo);
        }

    }

    function _takeFee( address sender, address recipient, uint256 tAmount, uint256 currentRate) private {
        uint256 rAmount = tAmount.mul(currentRate);
        AccountInfo storage info = _accountInfos[recipient];
        info.balance = info.balance.add(rAmount);
        emit Transfer(sender, recipient, tAmount);
        if (info.created == false) {
            _updateAccount(recipient, info);
        }
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        AccountInfo storage info = _accountInfos[address(this)];
        info.balance = info.balance.add(rLiquidity);
    }

    function _takeAbonus(address sender, uint256 tAmount, uint256 currentRate) private {
        uint256 length = _abounsIndex.length - _abounsOffset;
        if (length == 0) {
            _takeFee(sender, _projectMarketing, tAmount, currentRate);
            return;
        }

        uint256 amount = tAmount.mul(currentRate).div(length);
        for(uint256 i = _abounsOffset; i < _abounsIndex.length; i++) {
            address recipient = _abounsList[i];
            AccountInfo storage info = _accountInfos[recipient];
            if (info.balance >= A_BOUNS_CONDITION) {
                info.balance = info.balance.add(amount);
                emit Transfer(sender, recipient, amount);
            }
        }

    }

    function _createAccount(address user, uint256 balance) private {
        uint256 idx = _abounsIndex.length;
        _accountInfos[user] = AccountInfo(balance, idx, true);
        _abounsList[idx] = user;
        _abounsIndex.push(idx);
    }
    function _updateAccount(address user, AccountInfo storage info) private {
        uint256 idx = _abounsIndex.length;
        info.created = true;
        info.index = idx;
        _abounsList[idx] = user;
        _abounsIndex.push(idx);
    }
}