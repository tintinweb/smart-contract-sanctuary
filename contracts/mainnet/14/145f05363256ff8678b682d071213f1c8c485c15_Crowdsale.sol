/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

abstract contract Whitelist is Ownable {
    mapping (address => bool) private _members;

    event MemberAdded(address member);
    event MemberRemoved(address member);

    function isMember(address _member) public view returns(bool) {
        return _members[_member];
    }

    function addMember(address _member) public onlyOwner {
        require(!isMember(_member), "Whitelist: address is member already.");
        _members[_member] = true;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(isMember(_member), "Whitelist: Not member of whitelist.");
        delete _members[_member];
        emit MemberRemoved(_member);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IDepository {
    function deposit(address owner, uint256 amount) external;
}

contract Crowdsale is Whitelist, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private _token = IERC20(0xc878c93B5087887B908331Fcf8809B2C958cc5Ec); // ARK

    uint256 private _phaseOneEndTime;
    uint256 private _phaseTwoEndTime;

    uint256 private _phaseOneRate = 10;
    uint256 private _phaseTwoRate = 5;

    mapping (IERC20 => bool) private _stableCoins;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor () {
        _stableCoins[IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53)] = true; // busd
        _stableCoins[IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)] = true; // dai
        _stableCoins[IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1)] = true; // pax
        _stableCoins[IERC20(0x0000000000085d4780B73119b644AE5ecd22b376)] = true; // tusd
        _stableCoins[IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = true; // usdc
        _stableCoins[IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = true; // usdt

        _phaseOneEndTime = block.timestamp.add(30 days);
        _phaseTwoEndTime = _phaseOneEndTime.add(60 days);
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > _phaseTwoEndTime;
    }

    function phaseOneEndTime() external view returns (uint256) {
        return _phaseOneEndTime;
    }

    function phaseTwoEndTime() external view returns (uint256) {
        return _phaseTwoEndTime;
    }

    function phaseOneRate() external view returns (uint256) {
        return _phaseOneRate;
    }

    function phaseTwoRate() external view returns (uint256) {
        return _phaseTwoRate;
    }

    function buyTokens(address purchaser, address beneficiary, IERC20 stableCoin, uint256 amount) external nonReentrant {
        require(!hasClosed(), "Crowdsale: already closed");
        require(isMember(purchaser), "Crowdsale: Not purchaser of whitelist.");
        require(_stableCoins[stableCoin], "Crowdsale: invalid stable token");

        stableCoin.safeTransferFrom(purchaser, address(this), amount);

        if (stableCoin.decimals() < _token.decimals()) {
            amount = amount * 10 ** uint256(_token.decimals() - stableCoin.decimals());
        }

        uint256 tokens = amount.mul(_phaseOneRate);
        if (block.timestamp > _phaseOneEndTime && block.timestamp < _phaseTwoEndTime) {
            tokens = amount.mul(_phaseTwoRate);
        }

        _token.safeTransfer(beneficiary, tokens);

        emit TokensPurchased(_msgSender(), beneficiary, amount, tokens);
    }

    function withdraw(IERC20 stableCoin, address beneficiary) external onlyOwner {
        stableCoin.safeTransfer(beneficiary, stableCoin.balanceOf(address(this)));
    }
}