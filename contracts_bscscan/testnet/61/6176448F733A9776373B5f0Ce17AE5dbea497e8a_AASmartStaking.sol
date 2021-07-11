/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



/* ~~~~~~~~~~~~ STAKING PREPARE ~~~~~~~~~~~~~~ */
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// TOKEN CONTROLS
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BIP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BIP20: transfer from the zero address");
        require(recipient != address(0), "BIP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BIP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BIP20: approve from the zero address");
        require(spender != address(0), "BIP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 
        // add some actions whot's goingon
    }
    
}
contract Token is ERC20 {}





struct UserStaking {        
    address account;
    uint256 steps;
    uint256 stakingId;
    uint256 startDate;
    uint256 unstakeDate;
    uint256 REWARD_shares;
    uint256 COIN_to_recive; 
    uint256 COIN_staked;
    uint256 COIN_interest;
    uint256 COIN_apy;
    uint256 COIN_bonus;
    bool STAKE_ACTIVE;
}
contract AASmartStaking is Ownable, ERC20 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    
    // 7, 14, 30, 60, 180, 300
    mapping (uint => bool) public Step;
    mapping (uint256 => uint256) private StepBonus;

    // Reword Shares
    string public name = 'Reward Shares';
    string public symbol = 'SHARES';
    uint8 public decimals = 0;

    // FREE DEPOSIT
    receive() external payable {}
    constructor (address _Staking_token) payable {
        setStakingToken(_Staking_token);
        // 7, 14, 30, 60, 180, 300
        Step[7] = true;
        Step[14] = true;
        Step[30] = true;
        Step[60] = true;
        Step[180] = true;
        Step[300] = true;
        StepBonus[7] = 1;
        StepBonus[14] = 5;
        StepBonus[30] = 7;
        StepBonus[60] = 10;
        StepBonus[180] = 15;
        StepBonus[300] = 20;
    }
    
    // WITHDRAW ALL TOKENS
    event WithdrawTOKEN(address indexed token, address indexed account, uint256 amount);
    function emergencyWithdrawToken(address token_address) external onlyOwner() {
        Token token = Token(token_address);
        uint256 balance = token.balanceOf(address(this));
        if (token != getStakingToken) {
            require(balance > 0, "not enoph tokens for withdraw");
            token.transfer(msg.sender, balance);
        } else {
            uint256 TBalance = pool_free();
            require(TBalance > 0, "not enoph tokens for withdraw");
            token.transfer(msg.sender, TBalance);
        }
        emit WithdrawTOKEN(token_address, msg.sender, balance);
    }
    
    function forcedWithdrawToken(uint _value) external onlyOwner() {
        Token token = Token(getStakingToken);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "not enoph tokens for withdraw");
        token.transfer(msg.sender, _value);
        emit WithdrawTOKEN(address(getStakingToken), msg.sender, _value);
    }

    // WITHDRAW ALL BNB
    event WithdrawBNB(address indexed account, uint256 amount);
    function emergencyWithdrawBNB() external onlyOwner() {
       uint256 balance = address(this).balance;
       payable( msg.sender ).transfer(balance);
       emit WithdrawBNB(msg.sender, balance);
    }

    // TOKEN FOR STAKING
    event StakingTokenUpdate(address indexed token);
    Token public getStakingToken;
    function setStakingToken(address token_address) public onlyOwner() {
        getStakingToken = Token(token_address);
        emit StakingTokenUpdate(token_address);
    }

    // ANNUAL PERCENTAGE YIELD
    uint public getAPY = 100; // 1%
    event NewAPY(uint256 apy);
    event NewBonusAPY(uint256 _apy_bonus, uint _days);
    function setAPY(uint APY) external onlyOwner() {
        getAPY = APY;
        emit NewAPY(APY);
    }
    function setBonusAPY(uint256 Bonus,uint _days) external onlyOwner() {
        require(Step[_days], "This step not exists");
        StepBonus[_days] = Bonus;
        emit NewBonusAPY(Bonus,_days);
    }
    function getBonusAPY(uint _days) public virtual view returns ( uint256 ) {
        return StepBonus[_days];
    }
    
    // POOL FOR STAKING
    uint256 public pool_locked = 0;  // locked amount of tokens
    uint256 public pool_reserve = 0;
    function pool_balance() public virtual view returns (uint256) {
        return getStakingToken.balanceOf(address(this));
    }
    function pool_free() public virtual view returns (uint256) { // free amount of tokens
        return pool_balance() - pool_locked;
    }
    function pool_deposit(uint256 amount) public {
        pool_locked.add(amount);
        pool_reserve.add(amount);
        getStakingToken.transferFrom(msg.sender, address(this), amount);
    }
    
    

    
    // UPDATE Reword Shares Multiplier
    uint256 public RPointCorrection = 1000000;
    event RewordSharesCorrection(uint256 correction);
    function set_rp_multiplier(uint256 correction) external onlyOwner() {
        RPointCorrection = correction;
        emit RewordSharesCorrection(correction);
    }
    
    function stake_interest(uint256 _deposit, uint _days) public virtual view returns (
        uint256 interest,
        uint256 apy,
        uint256 reword,
        uint256 shares
        ) {
        require(Step[_days], "This step not exists");
        apy = getAPY + getBonusAPY(_days);
        interest = apy.mul(_days).mul(_deposit).div(10000).div(365);
        reword = interest + _deposit;
        shares = reword.div(RPointCorrection);
    }

    uint256 private currentStakingId = 0;
    uint256 private oneday = 60 * 60 * 24;
    uint256 public totalStakedCOIN = 0;
    uint256 public totalUnstakedCOIN;
    uint256 public interestPoolCOIN;
    uint256 public totalPaidCOIN;
    uint256 public shares_stake = 0;
    uint256 public active_stakers = 0;
    uint256 public totalToPay = 0;
    
    // stakingId => UserStaking
    mapping(uint256 => UserStaking) public userStakingOf;
    
    // account => stakingId[]
    mapping(address => EnumerableSet.UintSet) private stakingIdsOf;
    event Stake(
        address indexed account,
        uint256 steps,
        uint256 indexed stakingId,
        uint256 startDate,
        uint256 unstakeDate,
        uint256 REWARD_shares,
        uint256 COIN,
        uint256 COIN_interest,
        uint256 COIN_apy
    );
    // stake address
    function stake(uint256 _value, uint256 _days) public  {
        require(_value <= getStakingToken.balanceOf(msg.sender), "not enoph tokens on the balance");
        require(Step[_days], "This step not exists");
        
        uint256 COIN = _value;
        uint256 DAYS = _days;
        
        // oneday
        uint256 startDate = block.timestamp;
        uint256 unstakeDate = block.timestamp + (oneday * DAYS);
        
        // TOKENS DEPOSIT
        getStakingToken.transferFrom(msg.sender, address(this), COIN);

        // REWORD CALCULATE
        (uint256 interest, uint256 apy, uint256 reword,uint256 shares) = stake_interest( COIN,  DAYS );
        
        
        require(interest > pool_reserve, "not enoph tokens for locked on the pool balance");
        
        pool_reserve = pool_reserve.sub(interest);

        // state - update
        uint256 stakingId = currentStakingId;
        userStakingOf[currentStakingId] = UserStaking({
            account: msg.sender,
            steps: DAYS,
            stakingId: stakingId,
            startDate: startDate, 
            unstakeDate: unstakeDate,
            REWARD_shares: shares,
            COIN_to_recive: reword, 
            COIN_staked: COIN,
            COIN_interest: interest,
            COIN_apy: apy, /// in tokens
            COIN_bonus: 0,
            STAKE_ACTIVE: true
        });
        stakingIdsOf[msg.sender].add(currentStakingId);
        totalStakedCOIN = totalStakedCOIN.add(COIN);
        pool_locked = pool_locked.add(reword).sub(interest); // sub beacouse intrest already loked
        currentStakingId = currentStakingId.add(1);
        shares_stake = shares_stake.add(shares);
        active_stakers = active_stakers.add(1);
        
        totalToPay = totalToPay.add(reword);
        
        // GIVE AIRDROP
        if (pool_free() > 0) { pool_bonus(); }
        
        emit Stake(
            msg.sender,
            _days,
            stakingId,
            startDate, 
            unstakeDate,
            shares,
            COIN,
            interest,
            apy
        );
    }
    event Unstake(
        address indexed account,
        uint256 unstakeDate,
        uint256 indexed stakingId,
        uint256 indexed payoutCOIN,
        uint256 penaltyCOIN,
        uint256 StakedCOIN,
        uint256 StakedShares
    );
    function unstake(uint256 stakingId) public {
        if (pool_free() > 0) {
          pool_bonus();
        }
        UserStaking storage userStaking = userStakingOf[stakingId];
        address userAccount = msg.sender;
        require(
            userStaking.account == userAccount,
            'COINStaking[unstake]: userStaking.account != userAccount');
        require(
            userStaking.STAKE_ACTIVE,
            'COINStaking[unstake]: userStaking.unstakeDate != 0');
        uint256 penaltyCOIN = 0;
        uint256 coin_staked = userStaking.COIN_staked;
        uint256 penalty_index = 3000;
        uint256 toPay;
        uint256 shares = userStaking.REWARD_shares;
        uint256 shares_toPay = shares;
        if (userStaking.unstakeDate > block.timestamp) {
            // PENALTY
            toPay = coin_staked.add(userStaking.COIN_bonus);
            shares_toPay = 0;
            penaltyCOIN = toPay.mul(penalty_index).div(10000);
        } else {
            // NO PENALTY
            toPay = userStaking.COIN_to_recive.add(userStaking.COIN_bonus);
        }
        getStakingToken.transferFrom(address(this), userAccount, toPay);
        
        // actions to record
        userStaking.STAKE_ACTIVE = false;
        active_stakers = active_stakers.sub(1);
        shares_stake = shares_stake.sub(shares);
        totalStakedCOIN = totalStakedCOIN.sub(coin_staked);
        totalToPay = totalToPay.sub(toPay);
        totalPaidCOIN = totalPaidCOIN.add(toPay);
        emit Unstake(
            userAccount,
            block.timestamp,
            userStaking.stakingId,
            toPay,
            penaltyCOIN,
            coin_staked,
            shares_toPay);
    }
    
    // BONUS TO ALL
    mapping (uint256 => uint256) private BonusFeeAddress;
    function share_percent( uint256 IHave ) private view returns(uint percent) {
        percent = IHave.mul(10000).div(shares_stake);
    }
    function pool_bonus() public {
         uint256 to_airdrop = pool_free();
         for (uint256 i=0; i < currentStakingId; i++) {
             UserStaking storage userStaking = userStakingOf[i+1];
             if (userStaking.STAKE_ACTIVE) {
                 (uint256 percent) = share_percent( userStaking.REWARD_shares );
                 userStaking.COIN_bonus = userStaking.COIN_bonus.add(
                     percent.mul(to_airdrop).div(10000));
             }
         }
         pool_locked.add(to_airdrop);
         totalToPay = totalToPay.add(to_airdrop);
    }
    
    // OTHER data
    function getUserStakingCount(address _account)
        external
        view
        returns (uint256)
    {
        return stakingIdsOf[_account].length();
    }
    function getUserStakingId(address _account, uint256 idx)
        external
        view
        returns (uint256)
    {
        return stakingIdsOf[_account].at(idx);
    }
    
}