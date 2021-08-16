/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

pragma solidity 0.6.12;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;


        bytes32 accountHash
        = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account)
    internal
    pure
    returns (address payable)
    {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FACBridge is Ownable {

    using SafeBEP20 for IBEP20;
    using Address for address;
    using SafeMath for uint256;

    struct Data {
        uint256 index;
        address currency;
        address sender;
        address receiver;
        uint256 amount;
    }

    struct UserData {
        uint256 timestamp;
        uint256 swapAmount;
    }

    uint256 public MAX_DAILY_SWAP;

    uint256 public MAX_AMOUNT_SWAP;

    uint256 public index;

    mapping(address => mapping(address => UserData)) public userDatas;

    mapping(uint256 => bool) public  isUnlocked;

    mapping(uint256 => Data[]) public indexSwaps;

    mapping(address => bool) public unlocker;

    event Unlock(uint256 index, address currency, address receiver, uint256 amount);
    event Lock(uint256 index, address currency, address sender, address receiver, uint256 amount);

    mapping(address => bool) public whiteList;

    constructor(address _token, uint256 _maxDailyAmount, uint256 _maxAmountInTx) public {
        MAX_AMOUNT_SWAP = _maxAmountInTx;
        MAX_DAILY_SWAP = _maxDailyAmount;

        whiteList[_token] = true;
        unlocker[msg.sender] = true;
    }

    function setWhiteList(address _token) public onlyOwner {
        whiteList[_token] = true;
    }

    function setUnlocker(address _user, bool _result) public onlyOwner {
        unlocker[_user] = _result;
    }

    function getLengthIndexSwap(uint256 _index) public view returns (uint256){
        return indexSwaps[_index].length;
    }
    
    function setDailyAmount(uint256 _amount) public onlyOwner {
        MAX_DAILY_SWAP = _amount;
    }

    function setMaxAmountInTx(uint256 _amount) public onlyOwner {
        MAX_AMOUNT_SWAP = _amount;
    }

    function lock(address _receiver, uint256 _amount, address _token) public {
        require(whiteList[_token] == true, "Currency not support");

        uint256 timestamp = block.timestamp;
        UserData storage _user = userDatas[msg.sender][_token];

        if (timestamp - _user.timestamp > 1 days) {
            _user.timestamp = timestamp;
            _user.swapAmount = _amount;
        } else {
            _user.swapAmount = _user.swapAmount.add(_amount);
        }

        require(_amount <= MAX_AMOUNT_SWAP, "Exceed amount limit");
        require(_user.swapAmount <= MAX_DAILY_SWAP, "Exceed daily limit");

        Data memory _data = Data(index, _token, msg.sender, _receiver,_amount);

        IBEP20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        indexSwaps[index].push(_data);

        emit Lock(index, _token, msg.sender, _receiver, _amount);
    }


    function updateIndex() public {
        require(unlocker[msg.sender], "must unlocker");
        require(indexSwaps[index].length > 0, "data is empty");
        index++;
    }

    function unlockBatch(address[] memory _tokens, address[] memory _receives, uint256[] memory _amounts, uint256 index) external {
        require(unlocker[msg.sender], "must is unlocker");

        require(_receives.length == _amounts.length, "Invalid data");

        require(isUnlocked[index] == false, "already unlock");

        isUnlocked[index] = true;

        for (uint256 i = 0; i < _receives.length; i++) {
            require(whiteList[_tokens[i]], "Currency not support");
            IBEP20(_tokens[i]).safeTransfer(_receives[i], _amounts[i]);
            emit Unlock(index, _tokens[i], _receives[i], _amounts[i]);
        }

    }

    function transferOnlyOwner(IBEP20 token, address to, uint256 amount) public onlyOwner {
        token.safeTransfer(to, amount);
    }
}