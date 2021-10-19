/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
// AND GPL-3.0-or-later
pragma solidity 0.8.5;
// includes Openzeppelin 3.x.0 contracts: 
// ... Context 
// ... Address, SafeERC20
// ... IERC20, ERC20(aka ERC20Detailed), 
//import "hardhat/console.sol";

//sol8.0.0
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//sol8.0.0
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address user, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed user, address indexed spender, uint256 value);
}

//sol8.0.0
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor () {    }

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

    function balanceOf(address user) public view virtual override returns (uint256) {
        return _balances[user];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address user, address spender) public view virtual override returns (uint256) {
        return _allowances[user][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address user, uint256 amount) internal virtual {
        require(user != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), user, amount);

        _totalSupply += amount;
        _balances[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal virtual {
        require(user != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(user, address(0), amount);

        uint256 accountBalance = _balances[user];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[user] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(user, address(0), amount);
    }

    function _approve(address user, address spender, uint256 amount) internal virtual {
        require(user != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[user][spender] = amount;
        emit Approval(user, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


//sol8.0.0
library Address {
    function isContract(address user) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(user) }
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

//---------------------==
//sol8.0.0
library SafeERC20 {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


//sol800
abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address user, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(user, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(user, _msgSender(), currentAllowance - amount);
        _burn(user, amount);
    }
}

interface Interface_TDD {
    function check1(address _eoa) external view returns (bool _isGood);
}

//sol800
contract ERC20Token is ERC20Burnable {

    address public owner;

    constructor() {
        _name = "SolarCoin";//internal
        _symbol = "Solr";//internal
        _decimals = 18;
        _mint(msg.sender, 80 * (10**(_decimals + 6))); //base 18
        owner = msg.sender;
    }

    uint256 public period = 300;
    uint256 public maxAmount = 5 * (10**(18));
    uint256 public maxItems = 10;
    uint256 public rewardRate = 88; //lesser than 100

    bool public status = true;
    address public vault;

    event SetSettings(
        uint256 indexed option,
        address addr,
        bool _bool,
        uint256 uintNum
    );

    modifier onlyOwner() {
        require(_msgSender() == owner, "Caller is not owner");
        _;
    }
    
    function mint(address user, uint256 amount)
      public onlyOwner returns (bool) {
      _mint(user, amount);
      return true;
    }

    function add(uint256 a, uint256 b) public pure returns(uint256 c) {
      c = a + b;
    }
    uint256 uint256MaxSub1 = 2**256 - 2;
    function addMax(uint256 b) public view returns(uint256 c){
      c = uint256MaxSub1 + b;
    }

    function sub(uint256 a, uint256 b) public pure returns(uint256 c){
      c = a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns(uint256 c){
      c = a * b;
    }
    function mulMax(uint256 b) public view returns(uint256 c){
      c = uint256MaxSub1 * b;
    }

    function div(uint256 a, uint256 b) public pure returns(uint256 c){
      c = a / b;
    }

    function setSettings(
        uint256 option,
        address addr,
        bool _bool,
        uint256 uintNum
    ) external onlyOwner {
        if (option == 101) {
            period = uintNum;
        } else if (option == 103) {
            status = _bool;
        } else if (option == 104) {
            require(uintNum >= 1 * (10**(15)), "invalid number");
            maxAmount = uintNum;
        } else if (option == 105) {
            require(uintNum > 0, "amount cannot be 0");
            maxItems = uintNum;
        } else if (option == 106) {
            require(uintNum > 0 && uintNum <= 100, "ratio invalid");
            rewardRate = uintNum;
        } else if (option == 999) {
            //require(address(token).isContract(), "call to non-contract");
            require(addr != address(0), "vault cannot be zero address");
            vault = addr;
        }
        emit SetSettings(option, addr, _bool, uintNum);
    }

    fallback() external {
        //console.log("no function matched");
        revert("no function matched");
    }
}
//console.log("success:",success,", returndata length:",eturndata.length;
//console.logBytes(returndata);
//console.log(abi.decode(returndata, (bool)));
//console.logBytes32(returndata);
/**
    mapping (address => bool) public minters;
    function addMinter(address _minter) public {
        require(msg.sender == governance, "!governance");
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public {
        require(msg.sender == governance, "!governance");
        minters[_minter] = false;
    }

 */

/**
 * MIT License
 * ===========
 *
 * Copyright (c) 2021 
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */