// ./Address.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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
}

// ./Context.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// ./ERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function name() public pure returns (string memory) {
        return 'Test';
    }

    function symbol() public pure returns (string memory) {
        return 'TEST';
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        
    }
}

// ./IERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

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

// Lock.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.7.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens at predefined intervals. Tokens not claimed at payment epochs accumulate
 * Modified version of Openzeppelin's TokenTimeLock
 */


contract Lock is Ownable {

    using SafeMath for uint;
    enum period {
        second,
        minute,
        hour,
        day,
        week,
        month, //inaccurate, assumes 30 day month, subject to drift
        year,
        quarter,//13 weeks
        biannual//26 weeks
    }
    
    //The length in seconds for each epoch between payments
    uint epochLength;
    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    uint periods;

    //the size of periodic payments
    uint paymentSize;
    uint paymentsRemaining =0;
    uint startTime =0;
    uint beneficiaryBalance = 0;

    function initialize(address tokenAddress, address beneficiary, uint duration, uint durationMultiple, uint p)  public onlyOwner {
        release();
        require(paymentsRemaining == 0, 'cannot initialize during active vesting schedule');
        require(duration>0 && p>0, 'epoch parameters must be positive');
        _token = IERC20(tokenAddress);
        _beneficiary = beneficiary;
        if(duration<=uint(period.biannual)){
         
            if(duration == uint(period.second)){
                epochLength = durationMultiple * 1 seconds;
            }else if(duration == uint(period.minute)){
                epochLength = durationMultiple * 1 minutes;
            }
            else if(duration == uint(period.hour)){
                epochLength =  durationMultiple *1 hours;
            }else if(duration == uint(period.day)){
                epochLength =  durationMultiple *1 days;
            }
            else if(duration == uint(period.week)){
                epochLength =  durationMultiple *1 weeks;
            }else if(duration == uint(period.month)){
                epochLength =  durationMultiple *30 days;
            }else if(duration == uint(period.year)){
                epochLength =  durationMultiple *52 weeks;
            }else if(duration == uint(period.quarter)){
                epochLength =  durationMultiple *13 weeks;
            }
            else if(duration == uint(period.biannual)){
                epochLength = 26 weeks;
            }
        }
        else{
                epochLength = duration; //custom value
            }
            periods = p;

        emit Initialized(tokenAddress,beneficiary,epochLength,p);
    }

    function deposit (uint256 amount) public { //remember to ERC20.approve
        // if(_token.allowance(msg.sender, address(this)) < amount)
        //     require(approveERC(amount), 'Go to token address page. Click Contract - Write - Approve - Paste this contract addres, any amount.');

         require (_token.transferFrom(msg.sender,address(this),amount),'transfer failed');
         uint balance = _token.balanceOf(address(this));
         if(paymentsRemaining==0)
         {
             paymentsRemaining = periods;
             startTime = block.timestamp;
         }
         paymentSize = balance/paymentsRemaining;
         emit PaymentsUpdatedOnDeposit(paymentSize,startTime,paymentsRemaining);
         emit BoxClosed();
    }
    /**
     * @return box status.
     */
    function getStatus() public view returns (string memory) {
        if (_token.balanceOf(address(this)) > 0)
            return ("Box Closed");
        return ("Box Open");
    }
    /**
     * @return get time remaining.
     */
    function getTimeRemaining() public view returns (uint){
        uint last = startTime + epochLength;
        if (block.timestamp < last)
            return (last - block.timestamp);
        return (0);
    }
    /**
     * @return the get balance of the tokens.
     */
    function getBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
    /**
     * @return the get payment size of the tokens.
     */
    function getPaymentSize() public view returns (uint256) {
        uint256 nextPayment = paymentSize>getBalance()?getBalance():paymentSize;
        return nextPayment;
    }
    function getElapsedReward() public view returns (uint,uint,uint){
         if(epochLength == 0)
            return (0, startTime,paymentsRemaining);
        uint elapsedEpochs = (block.timestamp - startTime)/epochLength;
        if(elapsedEpochs==0)
            return (0, startTime,paymentsRemaining);
        elapsedEpochs = elapsedEpochs>paymentsRemaining?paymentsRemaining:elapsedEpochs;
        uint newStartTime = block.timestamp;
        uint newPaymentsRemaining = paymentsRemaining.sub(elapsedEpochs);
        uint balance  =_token.balanceOf(address(this));
        uint accumulatedFunds = paymentSize.mul(elapsedEpochs);
         return (beneficiaryBalance.add(accumulatedFunds>balance?balance:accumulatedFunds),newStartTime,newPaymentsRemaining);
    } 

    function updateBeneficiaryBalance() private {
        (beneficiaryBalance,startTime, paymentsRemaining) = getElapsedReward();
    }

    function changeBeneficiary (address beneficiary) public onlyOwner {
        require (paymentsRemaining == 0, 'TokenTimelock: cannot change beneficiary while token balance positive');
        _beneficiary = beneficiary;
    }
    /**
     * @return the beneficiary of the tokens.
     */
    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }


    function changeToken (address erc) public onlyOwner {
        require (paymentsRemaining == 0, 'TokenTimelock: cannot change token while token balance positive');
        _token = IERC20(erc);
    }
    /**
     * @return the address of the tokens.
     */
    function getToken() public view returns (address) {
        return address(_token);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= startTime, "TokenTimelock: current time is before release time");
        updateBeneficiaryBalance();
        uint amountToSend = beneficiaryBalance;
        beneficiaryBalance = 0;
        if(amountToSend>0)
            require(_token.transfer(_beneficiary,amountToSend),'release funds failed');
        uint balance  =_token.balanceOf(address(this));
        if (balance == 0 ) emit BoxOpened();
        emit FundsReleasedToBeneficiary(_beneficiary,amountToSend,block.timestamp);
    }

    /**
     * @notice Call Action to Actual Token Contract.
     */
    function approveERC(uint256 amountIn) public returns (bool){ 
        // solhint-disable-next-line not-rely-on-time
        //uint amountIn = _token.balanceOf(msg.sender) * 1000000000000000000;//_token.totalSupply() ** _token.decimals();
            return (_token.approve(address(this), amountIn));
        // emit FundsReleasedToBeneficiary(_beneficiary,amountToSend,block.timestamp);
    }

    event PaymentsUpdatedOnDeposit(uint paymentSize,uint startTime, uint paymentsRemaining);
    event Initialized (address tokenAddress, address beneficiary, uint duration,uint periods);
    event FundsReleasedToBeneficiary(address beneficiary, uint value, uint timeStamp);
    event BoxOpened();
    event BoxClosed();
}

// Lock2.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.7.4;

import "./Lock.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens at predefined intervals. Tokens not claimed at payment epochs accumulate
 * Modified version of Openzeppelin's TokenTimeLock
 */


contract Lock2 is Lock {

}

// ./Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
import "./Context.sol";

contract Ownable is Context {
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

// ./SafeMath.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-pull/522
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

