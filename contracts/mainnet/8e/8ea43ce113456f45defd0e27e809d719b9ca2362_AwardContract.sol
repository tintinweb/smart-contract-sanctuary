//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IERC20 {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
interface IERC20Token is IERC20 {
    function maxSupply() external view returns (uint256);
    function issue(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
}

contract DevAward {
    address public dev;
    uint256 public devStartBlock;
    uint256 public devAccAwards;
    uint256 public devPerBlock;
    uint256 public MaxAvailAwards;
}
contract AwardInfo {
    struct TaxInfo {
        uint256 epoch;
        uint256 amount;
    }

    struct UserInfo {
        uint256 freeAmount;
        uint256 taxHead;     // queue head element index
        uint256 taxTail;     // queue tail next element index
        bool notEmpty;       // whether taxList is empty where taxHead = taxTail
        TaxInfo[] taxList;
    }

    // tax epoch info
    uint256 public taxEpoch = 9;     // tax epoch and user taxlist max length
    uint256 public epUnit = 1 weeks;  // epoch unit => week

    // user info
    mapping(address => UserInfo) internal userInfo;

    // tax treasury address
    address public treasury;
}

contract AwardContract is DevAward, AwardInfo, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20Token;

    // platform token
    IERC20Token public platformToken;
    mapping(address => bool) public governors;
    modifier onlyGovernor{
        require(governors[_msgSender()], "RewardContract: RewardContract:: caller is not the governor");
        _;
    }

    event AddFreeAward(address user, uint256 amount);
    event AddAward(address user, uint256 amount);
    event Withdraw(address user, uint256 amount, uint256 tax);

    constructor(
        IERC20Token _platformToken,
        uint256 _taxEpoch,
        address _treasury,
        address _dev,
        uint256 _devStartBlock,
        uint256 _devPerBlock
    ) public {
        require(_taxEpoch > 0, "RewardContract: RewardContract:: taxEpoch invalid");
        require(_dev != address(0), "RewardContract: dev invalid");
        require(address(_platformToken) != address(0), "RewardContract: platform token invalid");
        require(_devStartBlock != 0, "RewardContract: dev start block invalid");

        platformToken = _platformToken;
        taxEpoch = _taxEpoch;
        governors[_msgSender()] = true;

        // get tax fee
        treasury = _treasury;
        // dev info
        dev = _dev;
        // Dev can receive 10% of platformToken
        MaxAvailAwards = platformToken.maxSupply().mul(10).div(100);
        devPerBlock = _devPerBlock;
        devStartBlock = _devStartBlock;
    }

    // get user total rewards
    function getUserTotalAwards(address user) view public returns (uint256){
        UserInfo memory info = userInfo[user];
        uint256 amount = info.freeAmount;
        if (info.notEmpty) {
            uint256 cursor = info.taxHead;
            while (true) {
                amount = amount.add(info.taxList[cursor].amount);
                cursor = cursor.add(1).mod(taxEpoch);
                if (cursor == info.taxTail) {
                    break;
                }
            }
        }
        return amount;
    }

    // get user free rewards amount
    function getCurrentFreeAwards(address user) view public returns (uint256){
        uint256 rebaseEp = getCurrEpoch().sub(taxEpoch);
        UserInfo memory info = userInfo[user];
        uint256 amount = info.freeAmount;
        if (info.notEmpty) {
            uint256 cursor = info.taxHead;
            while (info.taxList[cursor].epoch <= rebaseEp) {
                amount = amount.add(info.taxList[cursor].amount);
                cursor = cursor.add(1).mod(taxEpoch);
                if (cursor == info.taxTail) {
                    break;
                }
            }
        }
        return amount;
    }

    // get available awards
    function getUserAvailAwards(address user) view public returns (uint256){
        uint256 current = getCurrEpoch();
        uint256 rebaseEp = current.sub(taxEpoch);
        UserInfo memory info = userInfo[user];
        uint256 amount = info.freeAmount;
        if (info.notEmpty) {
            uint256 _ep = taxEpoch.add(1);
            uint256 cursor = info.taxHead;
            while (true) {
                if (info.taxList[cursor].epoch > rebaseEp) {
                    uint rate = current.sub(info.taxList[cursor].epoch).add(1).mul(1e12).div(_ep);
                    uint256 available = info.taxList[cursor].amount.mul(rate).div(1e12);
                    amount = amount.add(available);
                } else {
                    amount = amount.add(info.taxList[cursor].amount);
                }
                cursor = cursor.add(1).mod(taxEpoch);
                if (cursor == info.taxTail) {
                    break;
                }
            }
        }
        return amount;
    }

    // add governor
    function addGovernor(address governor) onlyOwner external {
        governors[governor] = true;
    }

    // remove governor
    function removeGovernor(address governor) onlyOwner external {
        governors[governor] = false;
    }

    function estimateTax(uint256 _amount) view external returns (uint256){
        uint256 _current = getCurrEpoch();
        uint256 tax = 0;
        UserInfo memory user = userInfo[msg.sender];
        if (user.freeAmount >= _amount) {
            return 0;
        }
        else {
            uint256 current = _current;
            uint256 arrears = _amount.sub(user.freeAmount);
            uint256 _head = user.taxHead;
            uint256 _ep = taxEpoch.add(1);
            while (user.notEmpty) {
                // non-levied tax rate
                TaxInfo memory taxInfo = user.taxList[_head];
                uint rate = current.sub(taxInfo.epoch).add(1).mul(1e12).div(_ep);
                if (rate > 1e12) {
                    rate = 1e12;
                }
                uint256 available = taxInfo.amount.mul(rate).div(1e12);
                if (available >= arrears) {
                    uint256 newAmount = arrears.mul(1e12).div(rate);
                    tax = tax.add(newAmount.sub(arrears));
                    arrears = 0;
                    break;
                }
                else {
                    arrears = arrears.sub(available);
                    tax = tax.add(taxInfo.amount.sub(available));
                    _head = _head.add(1).mod(taxEpoch);
                    if (_head == user.taxTail) {
                        break;
                    }
                }
            }
            require(arrears == 0, "RewardContract: Insufficient Balance");
            return tax;
        }
    }

    // dev get rewards
    function claimDevAwards() external {
        require(msg.sender == dev, "RewardContract: only dev can receive awards");
        require(devAccAwards < MaxAvailAwards, "RewardContract: dev awards exceed permitted amount");
        uint256 amount = block.number.sub(devStartBlock).mul(devPerBlock);
        uint256 rewards = amount.sub(devAccAwards);
        if (amount > MaxAvailAwards) {
            rewards = MaxAvailAwards.sub(devAccAwards);
        }
        safeIssue(dev, rewards, "RewardContract: dev claim awards failed");
        devAccAwards = devAccAwards.add(rewards);
    }


    // add free amount
    function addFreeAward(address _user, uint256 _amount) onlyGovernor external {
        UserInfo storage user = userInfo[_user];
        user.freeAmount = user.freeAmount.add(_amount);
        emit AddFreeAward(_user, _amount);
    }

    // add awards
    function addAward(address _user, uint256 _amount) onlyGovernor external {
        uint256 current = getCurrEpoch();
        // get epoch
        UserInfo storage user = userInfo[_user];
        //
        if (user.taxList.length == 0) {
            user.taxList.push(TaxInfo({
                epoch : current,
                amount : _amount
                }));
            user.taxHead = 0;
            user.taxTail = 1;
            user.notEmpty = true;
        }
        else {
            // taxList not full
            if (user.notEmpty) {
                uint256 end;
                if (user.taxTail == 0) {
                    end = user.taxList.length - 1;
                } else {
                    end = user.taxTail.sub(1);
                }
                if (user.taxList[end].epoch >= current) {
                    user.taxList[end].amount = user.taxList[end].amount.add(_amount);
                } else {
                    if (user.taxList.length < taxEpoch) {
                        user.taxList.push(TaxInfo({
                            epoch : current,
                            amount : _amount
                            }));
                    } else {
                        if (user.taxHead == user.taxTail) {
                            rebase(user, current);
                        }
                        user.taxList[user.taxTail].epoch = current;
                        user.taxList[user.taxTail].amount = _amount;
                    }
                    user.taxTail = user.taxTail.add(1).mod(taxEpoch);
                }
            } else {// user.taxHead == user.taxTail
                user.taxList[user.taxTail].epoch = current;
                user.taxList[user.taxTail].amount = _amount;
                user.taxTail = user.taxTail.add(1).mod(taxEpoch);
                user.notEmpty = true;
            }
        }
        emit AddAward(_user, _amount);
    }

    function withdraw(uint256 _amount) external {
        uint256 current = getCurrEpoch();
        uint256 _destroy = 0;
        // get base time
        UserInfo storage user = userInfo[msg.sender];
        // rebase
        rebase(user, current);

        if (user.freeAmount >= _amount) {
            user.freeAmount = user.freeAmount.sub(_amount);
        }
        else {
            uint256 arrears = _amount.sub(user.freeAmount);
            user.freeAmount = 0;
            uint256 _head = user.taxHead;
            uint256 _ep = taxEpoch.add(1);
            while (user.notEmpty) {
                // non-levied tax rate
                uint rate = current.sub(user.taxList[_head].epoch).add(1).mul(1e12).div(_ep);

                uint256 available = user.taxList[_head].amount.mul(rate).div(1e12);
                // available token
                if (available >= arrears) {
                    uint256 newAmount = arrears.mul(1e12).div(rate);
                    user.taxList[_head].amount = user.taxList[_head].amount.sub(newAmount);
                    _destroy = _destroy.add(newAmount.sub(arrears));
                    arrears = 0;
                    break;
                }
                else {
                    arrears = arrears.sub(available);
                    _destroy = _destroy.add(user.taxList[_head].amount.sub(available));
                    _head = _head.add(1).mod(taxEpoch);
                    if (_head == user.taxTail) {
                        user.notEmpty = false;
                    }
                }
            }

            user.taxHead = _head;
            require(arrears == 0, "RewardContract: Insufficient Balance");
            destroy(_destroy);
        }
        safeIssue(msg.sender, _amount, "RewardContract: claim awards failed");
        emit Withdraw(msg.sender, _amount, _destroy);
    }

    function destroy(uint256 amount) onlyGovernor public {
        safeIssue(treasury, amount, "RewardContract: levy tax failed");
    }

    function getCurrEpoch() internal view returns (uint256) {
        return now.div(epUnit);
    }

    function safeIssue(address user, uint256 amount, string memory err) internal {
        if (amount > 0) {
            require(amount.add(platformToken.totalSupply()) <= platformToken.maxSupply(), "RewardContract: awards exceeds maxSupply");
            require(platformToken.issue(user, amount), err);
        }
    }

    function rebase(UserInfo storage _user, uint256 _current) internal {
        uint256 rebaseEp = _current.sub(taxEpoch);
        uint256 head = _user.taxHead;
        while (_user.notEmpty && _user.taxList[head].epoch <= rebaseEp) {
            _user.freeAmount = _user.freeAmount.add(_user.taxList[head].amount);
            head = head.add(1).mod(taxEpoch);
            if (head == _user.taxTail) {
                _user.notEmpty = false;
            }
        }
        _user.taxHead = head;
    }
}