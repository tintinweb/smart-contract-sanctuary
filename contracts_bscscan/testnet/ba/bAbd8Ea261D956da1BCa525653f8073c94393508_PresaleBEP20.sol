/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// Shibas Whitelist - aBPSHIB

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


pragma solidity 0.6.12;

contract Context {

    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}


pragma solidity 0.6.12;

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


pragma solidity 0.6.12;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


pragma solidity 0.6.12;

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 0 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


pragma solidity ^0.6.12;

contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}


pragma solidity 0.6.12;

contract PresaleBEP20 is Ownable {
    using SafeMath for uint256;

    address private presale_token;
    address public multisigAddress = 0x4a70002Dd61b4eBF2763949644EdE2a253c34fEd;

    uint256 public busdAmount;
    uint256 public totalDepositedAmount;
    
    address public immutable BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address public immutable ETIGER = address(0xdB1BD7e9dCa23e84A6CC6ADc50b4451A35F029A7);

    uint256 public presaleTokenDecimals = 9;

    mapping(address => bool) public _isWhitelisted;
    mapping(address => uint256) public deposits;

    receive() payable external {
        deposit(presale_token, busdAmount);
    }

    function deposit(address presale_token, uint256 busdAmount) private {
        require(_isWhitelisted[msg.sender], 'Not Whitelisted address');
        uint256 tokenAmount = 0;
        uint256 shibaRewardTokenCount = 75;

        if (presale_token == ETIGER) {
            tokenAmount = busdAmount.mul(10).div(shibaRewardTokenCount).div(10 ** presaleTokenDecimals);
        }
        
        require(tokenAmount > 0, "You need to send some ether");

        IBEP20(presale_token).transfer(msg.sender, tokenAmount);
        IBEP20(BUSD).transferFrom(msg.sender, address(this), busdAmount);

        totalDepositedAmount = totalDepositedAmount.add(busdAmount);
        deposits[msg.sender] = deposits[msg.sender].add(busdAmount);
        emit Deposited(msg.sender, busdAmount);
    }

     function whitelistaddress(address account, bool value) external onlyOwner {
        _isWhitelisted[account] = value;
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(multisigAddress, tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedAmount;
    }

    event Deposited(address indexed user, uint256 amount); 
}