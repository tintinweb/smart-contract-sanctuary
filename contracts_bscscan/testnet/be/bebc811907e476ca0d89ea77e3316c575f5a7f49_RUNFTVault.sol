/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Signed {
    function getSigner(bytes32 data, uint8 v, bytes32 r, bytes32 s) pure internal returns (address){
        return ecrecover(getEthSignedMessageHash(data), v, r, s);
    }
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IERC721Base {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
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

    function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
    private
    view
    returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
    {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
    internal
    returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
    internal
    returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
    internal
    returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

contract RUNFTVault is Ownable, Signed {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserInfo {
        uint256 amountRU;
        uint256 amountRUAndNFT2RU;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 requestWithdrawTime;
    }

    IBEP20 public RU;
    IERC721Base public nftContract;

    uint256 lastRewardBlock = 0;
    uint256 accRUPerShare = 0;
    uint256 public totalDeposit = 0;
    uint256 rewardsAmount = 0;
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => uint256) public nft2RU;
    mapping(address => bool) public isSigner;

    uint internal constant FRACTIONAL_SCALE = 1e21;
    uint256 public rewardPerBlock = 75*1e15;
    uint256 public unboundingTime = 24 * 3600;

    event Deposit(address indexed user, uint256[] tokenIds, uint256 amount);
    event Withdraw(address indexed user, uint256[] tokenIds, uint256 amount);
    event WithdrawAll(address indexed user);
    event Claim(address indexed user, uint256 amount);

    constructor(address _nftPlayer, address _RU) {
        nftContract = IERC721Base(_nftPlayer);
        RU = IBEP20(_RU);
    }

    function setRUToken(IBEP20 _RU) external onlyOwner {
        require(address(RU) == address(0), 'Token already set!');
        RU = _RU;
    }

    function startStaking(uint256 startBlock) external onlyOwner {
        require(lastRewardBlock == 0, 'Staking already started');
        lastRewardBlock = startBlock;
    }

    function setUnboundingTime(uint256 _unboundingTime) external onlyOwner {
        unboundingTime = _unboundingTime;
    }

    function getBalanceRU(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.amountRU;
    }

    function getBalanceNFT(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function getUnclaimedReward(address _user) external view returns (uint256) {
        require(lastRewardBlock > 0 && block.number >= lastRewardBlock, 'Staking not yet started');
        UserInfo storage user = userInfo[_user];
        uint256 tempAccRUPerShare = accRUPerShare;
        if (block.number > lastRewardBlock && totalDeposit != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 RUReward = multiplier.mul(rewardPerBlock);
            tempAccRUPerShare = tempAccRUPerShare.add(RUReward.mul(FRACTIONAL_SCALE).div(totalDeposit));
        }
        uint256 lastPendingReward = user.amountRUAndNFT2RU.mul(tempAccRUPerShare).div(FRACTIONAL_SCALE).sub(user.rewardDebt);
        lastPendingReward = lastPendingReward.add(user.pendingRewards);
        return lastPendingReward;
    }

    function updateVault() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalDeposit == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 RUReward = multiplier.mul(rewardPerBlock);
        rewardsAmount = rewardsAmount.add(RUReward);
        accRUPerShare = accRUPerShare.add(RUReward.mul(FRACTIONAL_SCALE).div(totalDeposit));
        lastRewardBlock = block.number;
    }

    function setSigner(address _account, bool _is) public onlyOwner {
        isSigner[_account] = _is;
    }

    function deposit(
            uint256[] memory _tokenIds,
            uint256[] memory _nfts2RU,
            bytes memory adminSignedData,
            uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        updateVault();

        uint256 totalAmountDeposit = amount;
        if (_tokenIds.length > 0) {
            (uint8 v, bytes32 r, bytes32 s) = abi.decode(adminSignedData, (uint8, bytes32, bytes32));
            address signer = getSigner(keccak256(abi.encode(_tokenIds, _nfts2RU)), v, r, s);
            require(isSigner[signer], "Signer is not correct");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                require(nftContract.ownerOf(_tokenIds[i]) == msg.sender, "Caller is not owner");
                nftContract.transferFrom(msg.sender, address(this), _tokenIds[i]);
                _holderTokens[msg.sender].add(_tokenIds[i]);
                totalAmountDeposit = totalAmountDeposit.add(_nfts2RU[i]);
                nft2RU[_tokenIds[i]] = _nfts2RU[i];
            }
        }

        if (user.amountRUAndNFT2RU > 0) {
            uint256 lastPendingReward = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE).sub(user.rewardDebt);
            if (lastPendingReward > 0) {
                user.pendingRewards = user.pendingRewards.add(lastPendingReward);
            }
        }

        if (amount > 0) {
            RU.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amountRU = user.amountRU.add(amount);
        }

        user.amountRUAndNFT2RU = user.amountRUAndNFT2RU.add(totalAmountDeposit);
        totalDeposit = totalDeposit.add(totalAmountDeposit);

        user.rewardDebt = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE);
        emit Deposit(msg.sender, _tokenIds, amount);
    }

    function requestWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        user.requestWithdrawTime = block.timestamp;
    }

    function withdraw(uint256[] memory _tokenIds, uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.requestWithdrawTime > 0 && user.requestWithdrawTime + unboundingTime <= block.timestamp, "Withdrawing more than you have!");
        require(user.amountRU >= amount, "Withdrawing more than you have!");
        user.requestWithdrawTime = 0;
        updateVault();

        uint256 lastPendingReward = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE).sub(user.rewardDebt);
        if (lastPendingReward > 0) {
            user.pendingRewards = user.pendingRewards.add(lastPendingReward);
        }

        uint256 totalAmountWithdraw = amount;
        if (_tokenIds.length > 0) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                require(_holderTokens[msg.sender].contains(_tokenIds[i]), "Caller is not deposit owner");
                nftContract.transferFrom(address(this), msg.sender, _tokenIds[i]);
                _holderTokens[msg.sender].remove(_tokenIds[i]);
                totalAmountWithdraw = totalAmountWithdraw.add(nft2RU[_tokenIds[i]]);
            }
        }

        if (amount > 0) {
            RU.safeTransfer(address(msg.sender), amount);
        }

        user.amountRUAndNFT2RU = user.amountRUAndNFT2RU.sub(totalAmountWithdraw);
        user.amountRU = user.amountRU.sub(amount);
        totalDeposit = totalDeposit.sub(totalAmountWithdraw);

        user.rewardDebt = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE);
        emit Withdraw(msg.sender, _tokenIds, amount);
    }

    function withdrawAll() external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.requestWithdrawTime > 0 && user.requestWithdrawTime + unboundingTime <= block.timestamp, "Withdrawing more than you have!");
        user.requestWithdrawTime = 0;
        updateVault();

        uint256 lastPendingReward = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE).sub(user.rewardDebt);
        if (lastPendingReward > 0) {
            user.pendingRewards = user.pendingRewards.add(lastPendingReward);
        }

        uint256 totalAmountWithdraw = user.amountRU;
        if (_holderTokens[msg.sender].length() > 0) {
            for (uint256 i = 0; i < _holderTokens[msg.sender].length(); i++) {
                uint256 tokenId = _holderTokens[msg.sender].at(i);
                nftContract.transferFrom(address(this), msg.sender, tokenId);
                _holderTokens[msg.sender].remove(tokenId);
                totalAmountWithdraw = totalAmountWithdraw.add(nft2RU[tokenId]);
            }
        }

        if (user.amountRU > 0) {
            RU.safeTransfer(address(msg.sender), user.amountRU);
        }

        user.amountRUAndNFT2RU = user.amountRUAndNFT2RU.sub(totalAmountWithdraw);
        user.amountRU = 0;
        totalDeposit = totalDeposit.sub(totalAmountWithdraw);

        user.rewardDebt = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE);
        emit WithdrawAll(msg.sender);
    }

    function withdrawRURemain(uint256 amount) external onlyOwner {
        uint256 totalRU = RU.balanceOf(address(this));
        require(totalRU > totalDeposit + amount, "Cannot withdraw remain RU");
        RU.safeTransfer(address(msg.sender), amount);
    }

    function claimReward() public {
        UserInfo storage user = userInfo[msg.sender];
        updateVault();
        uint256 lastPendingReward = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE).sub(user.rewardDebt);
        if (lastPendingReward > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards.add(lastPendingReward);
            uint256 claimedAmount = safeRUTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = user.pendingRewards.sub(claimedAmount);
            rewardsAmount = rewardsAmount.sub(claimedAmount);
        }
        user.rewardDebt = user.amountRUAndNFT2RU.mul(accRUPerShare).div(FRACTIONAL_SCALE);
    }

    function safeRUTransfer(address to, uint256 amount) internal returns (uint256) {
        if (amount > RU.balanceOf(address(this))){
            RU.safeTransfer(to, 0);
            return 0;
        }

        if (amount > rewardsAmount) {
            RU.safeTransfer(to, rewardsAmount);
            return rewardsAmount;
        } else {
            RU.safeTransfer(to, amount);
            return amount;
        }
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock > 0, "RU per block should be greater than 0!");
        rewardPerBlock = _rewardPerBlock;
    }
}