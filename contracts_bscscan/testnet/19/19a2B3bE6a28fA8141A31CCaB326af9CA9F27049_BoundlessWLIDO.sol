/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub32(a, b, "SafeMath: subtraction overflow");
    }

    function sub32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;
        return c;
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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

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
        return _functionCallWithValue(target, data, 0, errorMessage);
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

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IERC20Mintable {
  function mint(address account, uint256 amount) external;
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;

  function pushManagement( address newOwner_ ) external;

  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

contract BoundlessWLIDO is Ownable {

    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    address public BUSD;
    address public preBOUND;

    uint256 public remainingTotalAmount; //BOUND available during WL sale (keeps reducing as people buy)
    uint256 public initialOfferingAmount; //BOUND available during WL sale
    uint256 public salePrice; //BUSD per BOUND during WL sale. Denominated in BUSD
    uint256 public saleStartTime; //when WL sale starts
    uint256 public maxAllotmentResetDoubleTime; //when max allotments per user are doubled
    uint256 public maxAllotmentResetTripleTime; //when max allotments per user are tripled
    uint256 public saleEndTime; //when entire seed presale ends

    bool public initialized;
    bool public finalized;

    uint256 public totalRaisedFunds;
    uint256 public totalSpentFunds;
    uint256 public saleCancellationBuffer = 30 days; //investors will be able to withdraw their share of funds not spent after this period of time

    mapping(address => bool) public whitelisted;
    uint256 public whitelistedCount;
    mapping(address => uint256) public purchasedAmount;

    constructor(
        address _BUSD,
        address _preBOUND
    ) {
        require(_BUSD != address(0));
        require(_preBOUND != address(0));
        BUSD = _BUSD;
        preBOUND = _preBOUND;
    }

    function saleStarted() public view returns (bool) {
        return initialized && saleStartTime <= block.timestamp;
    }

    function saleFinished() public view returns (bool) {
        return block.timestamp >= saleEndTime;
    }

    function setupSaleCancellationBuffer(uint256 _newbuffer) external onlyOwner() {
        saleCancellationBuffer = _newbuffer;
    }

    function whitelistBuyers(address[] memory _buyers)
        external
        onlyOwner
        returns (bool)
    {
        require(saleStarted() == false, 'Already started');
        for (uint256 i; i < _buyers.length; i++) {
            if (!whitelisted[_buyers[i]]) whitelistedCount++;
            whitelisted[_buyers[i]] = true;
        }
        return true;
    }

    function initialize(
        uint256 _totalAmount,
        uint256 _salePrice,
        uint256 _saleLength,
        uint256 _saleStartTime
    ) external onlyOwner returns (bool) {
        require(initialized == false, 'Already initialized');
        initialized = true;
        remainingTotalAmount = _totalAmount;
        initialOfferingAmount = _totalAmount;
        salePrice = _salePrice;
        saleStartTime = _saleStartTime;
        maxAllotmentResetDoubleTime = _saleStartTime.add(_saleLength.div(2));
        maxAllotmentResetTripleTime = _saleStartTime.add(_saleLength.div(2)).add(_saleLength.div(4));
        saleEndTime = _saleStartTime.add(_saleLength);
        return true;
    }

    function purchaseBOUND(uint256 _amountBUSD) external returns (bool) {
        require(saleStarted(), "Not started");
        require(!saleFinished(), "Sale finished");
        require(!finalized, "Sale finalized");
        require(_amountBUSD > 0, "Must be greater than 0");
        require(whitelisted[msg.sender], "Only whitelisted members can buy at the moment");

        uint256 _purchaseAmount = _calculateSaleQuote(_amountBUSD);
        require((purchasedAmount[msg.sender] + _purchaseAmount) <= this.maxAllotmentPerBuyer(), "Exceeds max allotment per buyer");
        require(_purchaseAmount <= remainingTotalAmount, "Sold out!");
        remainingTotalAmount = remainingTotalAmount.sub(_purchaseAmount);
        purchasedAmount[msg.sender] = purchasedAmount[msg.sender] + _purchaseAmount;

        IERC20(BUSD).safeTransferFrom(msg.sender, address(this), _amountBUSD);
        IERC20Mintable(preBOUND).mint(msg.sender, _purchaseAmount);
        totalRaisedFunds = totalRaisedFunds + _amountBUSD;
        return true;
    }

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        view
        returns (uint256)
    {
        return (10 ** IERC20(preBOUND).decimals()).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        external
        view
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    function maxAllotmentPerBuyer() external view returns (uint256) {
        if (block.timestamp > maxAllotmentResetTripleTime) {
          return initialOfferingAmount.div(whitelistedCount).mul(3);
        }
        else if (block.timestamp > maxAllotmentResetDoubleTime) {
          return initialOfferingAmount.div(whitelistedCount).mul(2);
        }
        else {
          return initialOfferingAmount.div(whitelistedCount);
        }
    }

    function remainingPurchase(address _buyer) external view returns (uint256) {
        uint256 allotmentRemaining = this.maxAllotmentPerBuyer().sub(purchasedAmount[_buyer]);
        if (allotmentRemaining > remainingTotalAmount) return remainingTotalAmount;
        else return allotmentRemaining;
    }

    function withdrawIfCancelled() external {
        require(saleFinished(), "Not finished yet");
        require(block.timestamp >= (saleCancellationBuffer + saleEndTime), "Too early to consider the sale cancelled");
        IERC20(preBOUND).safeTransferFrom(msg.sender, address(this), purchasedAmount[msg.sender]);
        uint256 amountBUSD = purchasedAmount[msg.sender].mul(salePrice).div(10 ** IERC20(preBOUND).decimals());
        uint256 fundsLeft = totalRaisedFunds.sub(totalSpentFunds);
        amountBUSD = amountBUSD.mul(fundsLeft).div(totalRaisedFunds);
        if (amountBUSD > IERC20(BUSD).balanceOf(address(this))) amountBUSD = IERC20(BUSD).balanceOf(address(this));
        purchasedAmount[msg.sender] = 0;
        IERC20(BUSD).safeTransfer(msg.sender, amountBUSD);
    }

    function transferExpenditure(address _recipient, uint256 _amount) external onlyOwner() {
        require(finalized, "Not finalized yet");
        IERC20(BUSD).safeTransfer(_recipient, _amount);
        totalSpentFunds = totalSpentFunds + _amount;
    }

    function finalize() external onlyOwner {
        finalized = true;
    }

    function cancelPresale() external onlyOwner{
        saleCancellationBuffer = 0;
    }

}