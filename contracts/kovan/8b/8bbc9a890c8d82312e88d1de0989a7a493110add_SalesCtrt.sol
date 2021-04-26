/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
//import "hardhat/console.sol";

//sol8.0.0
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


//sol8.0.0
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    //function sendValue(address payable recipient, uint256 amount) internal {...}

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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    // functionStaticCall x2
    // functionDelegateCall x2

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token, address from, address to, uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token, address spender, uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token, address spender, uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    )
    internal pure
    returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
}

//--------------------==
contract SalesCtrt {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Private members
    address private governance;
    address private vault;

    // Public members
    address public owner;
    IERC20 public token;
    bool public status = true;

    mapping (uint256 =>  string) public mapStrg;
    mapping (uint256 => uint256) public mapUint;
    mapping (uint256 => address) public mapAddr;
    mapping (uint256 => bytes32) public mapData;

    mapping (uint256 => uint256) public slotPrices;
    mapping (address => uint256) public authLevel;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event WithdrawETH(address indexed payee, uint256 amount, uint256 balance);
    event WithdrawToken(address indexed payee, uint256 amount, uint256 balance);

    constructor() {
        owner = msg.sender;
        governance = owner;
        vault = owner;
        authLevel[owner] = 9;
        token = IERC20(0x1A9dCe212Cd804A7D95B28f6A9AE32861DC12221);
        slotPrices[1] = 1e18;
        slotPrices[2] = 2e18;
        slotPrices[3] = 3e18;
    }

    modifier authorized() {
        require(authLevel[msg.sender] > 0, "not authorized");
        _;
    }
    event SetAccount(address indexed previousAccount, address indexed newAccount, uint256 indexed uintNum);

    function setAccount(uint256 option, address addr, uint256 uintNum) external{
        require(owner == msg.sender, "not owner");
        require(addr != address(0), "zero address");
        if (option == 990) {
            if (uintNum == 0) {
            } else if (uintNum == 1) {
                emit SetAccount(governance, addr, 9);
                governance = addr;
            } else if (uintNum == 9) {
                emit SetAccount(owner, addr, 9);
                owner = addr;
            }
        } else if (option == 991) {
            emit SetAccount(address(0), addr, uintNum);
            authLevel[addr] = uintNum;

        } else if (option == 998) {
          require(addr != address(0), "invalid addr");
          emit OwnershipTransferred(owner, addr);
          owner = addr;
        } else if (option == 999) {
          emit OwnershipTransferred(owner, address(0));
          owner = address(0);
        } else {

        }
    }

    event SetSettings(uint256 indexed option, uint256 uintNum1, uint256 uintNum2, address addr);
    function setSettings(uint256 option, uint256 uintNum1, uint256 uintNum2, address addr)
    external authorized
    {
        if (option > 900) {
            require(address(addr).isContract(), "invalid contract");
        }
        if (option == 101) {
            status = uintNum1 == uintNum2;
        } else if (option == 102) {
            slotPrices[uintNum1] = uintNum2;
        } else if (option == 890) {
            //require(address(token).isContract(), "call to non-contract");
            vault = addr;

        } else if (option == 997) {
            token = IERC20(addr);
        }
        emit SetSettings(option, uintNum1, uintNum2, addr);
    }

    //----------------------==
    event Paused(address account);
    event Unpaused(address account);
    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }
    function _pause() external whenNotPaused authorized {
        paused = true;
        emit Paused(msg.sender);
    }
    function _unpause() external whenPaused authorized {
        paused = false;
        emit Unpaused(msg.sender);
    }

    //----------------------==
    event BuyViaETH(
        address indexed user,
        uint256 indexed slotId,
        uint256 amountPaidETH
    );
    function buyViaETH(uint256 slotId, string memory _str) payable external whenNotPaused {
      //console.log("[sc] ETH:", msg.value, slotPrices[slotId]);
      //console.log("user", msg.sender);
      require(slotPrices[slotId] <= msg.value, "not enough payment");
      mapStrg[slotId] = _str;
      //mapUint[slotId] = _uint;
      //mapAddr[slotId] = _addr;
      //mapData[slotId] = keccak256(abi.encodePacked(_data));
      emit BuyViaETH(msg.sender, slotId, msg.value);
    }

    event BuyViaToken(
        address indexed user,
        uint256 indexed slotId,
        uint256 amountPaidToken
    );
    function buyViaToken(uint256 slotId, string memory _str, uint256 priceInWeiToken) external whenNotPaused {
      //console.log("[sc] Token:", priceInWeiToken, slotPrices[slotId]);
      //console.log("user", msg.sender);
      require(slotPrices[slotId] <= token.balanceOf(msg.sender), "not enough payment");
      mapStrg[slotId] = _str;
      //mapUint[slotId] = _uint;
      //mapAddr[slotId] = _addr;
      //mapData[slotId] = keccak256(abi.encodePacked(_data));
      token.safeTransferFrom(msg.sender, address(this), priceInWeiToken);
      emit BuyViaToken(msg.sender, slotId, priceInWeiToken);
    }

    //-------------------==
    function withdrawETH(address payable _to, uint256 _amount)
        external authorized {
        require(_to != address(0) && _to != address(this), "invalid _to");
        uint256 amount;
        uint256 maxAmount = address(this).balance;
        if(_amount == 0 || _amount > maxAmount) {
          amount = maxAmount;
        } else {
          amount = _amount;
        }
        payable(address(msg.sender)).transfer(amount);
        emit WithdrawETH(_to, amount, address(this).balance);
    }

    function withdrawToken(address _to, uint256 _amount) external authorized {
        require(_to != address(0) && _to != address(this), "invalid _to");
        uint256 amount;
        uint256 maxAmount = token.balanceOf(address(this));
        if(_amount == 0 || _amount > maxAmount) {
          amount = maxAmount;
        } else {
          amount = _amount;
        }
        token.safeTransfer(_to, amount);
        emit WithdrawToken(_to, amount, token.balanceOf(address(this)));
    }


    function hash(string memory _text, uint _num, address _addr)
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_text, _num, _addr));
    }

    fallback() external payable{
        //console.log("no function matched");
        revert("no function matched");
    }
    receive() external payable {
        //called when the call data is empty
        if (msg.value > 0) {
            revert();
        }
    }
}
/**
 * MIT License
 * ===========
 *
 * Copyright (c) 2021 AuroraLantean
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */