pragma solidity ^0.5.0;

contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


pragma solidity ^0.5.0;

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


pragma solidity ^0.5.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


pragma solidity ^0.5.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


pragma solidity ^0.5.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.5.0;

interface IFairStockEquity {
    function business(address user, uint256 payAmount, uint256 availableAmount, uint256 bonusAmount) external;

}


pragma solidity ^0.5.0;

interface IFSERandom {
    function genRandom(uint256 seed) external returns (bytes32);
}


pragma solidity ^0.5.0;

contract FSEGoldMiner is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IFairStockEquity public FairStockEquity;
    IFSERandom public FSERandom;
    IERC20 public mainToken;
    uint256 public running = 1;
    uint256 public stakeMin = 10 * (10 ** 18);
    uint256 public stakeMax = 200 * (10 ** 18);
    mapping(address => uint256) public users;

    event ePlay(address indexed user, uint256 payAmount, uint256 bonusAmount, uint256 timestamp);

    modifier onlyRunning() {
        require(running == 1, "Contract is not running!");
        _;
    }

    modifier onlyRegisted() {
        require(users[_msgSender()] > 0 && users[_msgSender()] < block.timestamp, "User NOT regist!");
        require(!Address.isContract(_msgSender()), "Illegal address!");
        _;
    }

    constructor (address _fairStockEquity, address _fseRandom, address _mainToken) public {
        mainToken = IERC20(_mainToken);
        setFairStockEquity(_fairStockEquity);
        setFSERandom(_fseRandom);
    }

    function setFairStockEquity(address addr)
    public onlyOwner {
        FairStockEquity = IFairStockEquity(addr);
        _setTokenApprove(addr);
    }

    function setFSERandom(address addr)
    public onlyOwner {
        FSERandom = IFSERandom(addr);
    }

    function setRunning(uint256 _running)
    public onlyOwner {
        running = _running;
    }

    function _setTokenApprove(address addr)
    internal {
        mainToken.approve(address(addr), uint(- 1));
    }

    function setStakeAmounts(uint256 _stakeMin, uint256 _stakeMax)
    public onlyOwner {
        stakeMin = _stakeMin;
        stakeMax = _stakeMax;
    }

    function regist()
    public {
        users[_msgSender()] = block.timestamp;
    }

    function getStakeAmounts()
    public view
    returns (uint256 _stakeMin, uint256 _stakeMax){
        return (stakeMin, stakeMax);
    }

    function play(uint256 payAmount)
    public onlyRunning onlyRegisted {
        require(payAmount >= stakeMin, "The amount is too little!");
        require(mainToken.allowance(_msgSender(), address(this)) >= payAmount, "The allowance is too little!");
        mainToken.safeTransferFrom(_msgSender(), address(this), payAmount);

        uint256 randNumber = uint256(FSERandom.genRandom(uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), payAmount, gasleft())))));

        uint256 amount = payAmount;
        uint256 bonusAmount = 0;
        uint256 betAmount = 0;
        uint256 bonus = 0;
        uint256 availableAmount = 0;
        while (amount > 0) {
            if (amount > stakeMax) {
                betAmount = stakeMax;
            } else {
                betAmount = amount;
            }
            amount = amount.sub(betAmount);

            randNumber = uint256(keccak256(abi.encodePacked(block.difficulty, randNumber, bonusAmount, gasleft())));

            bonus = betAmount.mul(randNumber % 100).div(55);
            if (bonus < betAmount) {
                availableAmount = availableAmount + betAmount;
            }
            bonusAmount = bonusAmount + bonus;
        }

        FairStockEquity.business(_msgSender(), payAmount, availableAmount, bonusAmount);
        emit ePlay(_msgSender(), payAmount, bonusAmount, block.timestamp);
    }
}