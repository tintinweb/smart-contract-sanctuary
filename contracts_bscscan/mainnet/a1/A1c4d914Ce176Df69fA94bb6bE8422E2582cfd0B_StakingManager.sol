/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract StakingManager {
    using SafeBEP20 for IBEP20;
    
    address public custodian_;
    address public signOwner_;
    mapping(uint32 => uint256) private bitmask_;
    
    event Deposit(address indexed caller, IBEP20 indexed asset, uint256 amount);
    event Withdraw(address indexed caller, uint32 block, uint8 bit, IBEP20 indexed asset, uint256 amount);
    
    constructor(address _custodian, address _signOwner) {
        custodian_ = _custodian;
        signOwner_ = _signOwner;
    }
    
    function deposit(IBEP20 _asset, uint256 _amount) external {
        _asset.safeTransferFrom(msg.sender, custodian_, _amount);

        emit Deposit(msg.sender, _asset, _amount);
    }

    function withdraw(
        uint32 _block,
        uint8 _bit,
        IBEP20 _asset,
        uint256 _amount,
        bytes calldata _signature) external {

        require(!isWithdrawn(_block, _bit), "ERR_ALREADY_WITHDRAWN");
        
        string memory message = string(abi.encodePacked(
            _toAsciiString(msg.sender), ";",
            _toAsciiString(address(_asset)), ";",
            _uintToString(_block), ";",
            _uintToString(_bit), ";",
            _uintToString(_amount)));

        _verify(message, _signature);
        
        _setWithdrawn(_block, _bit);
        
        _asset.safeTransfer(msg.sender, _amount);
        
        emit Withdraw(msg.sender, _block, _bit, _asset, _amount);
    }

    function isWithdrawn(uint32 _block, uint8 _bit) public view returns (bool) {
        uint256 bitBlock = bitmask_[_block];
        uint256 mask = uint256(1) << _bit;

        return (bitBlock & mask) > 0;
    }
    
    function _setWithdrawn(uint32 _block, uint8 _bit) private {
        uint256 bitBlock = bitmask_[_block];
        uint256 mask = uint256(1) << _bit;
        
        bitmask_[_block] = (bitBlock | mask);
    }
    
   function _verify(string memory _message, bytes calldata _sig) private view {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_message))));
        address messageSigner = _recover(messageHash, _sig);

        require(messageSigner == signOwner_, "ERR_VERIFICATION_FAILED");
    }

    function _recover(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        require(_sig.length == 65, "ERR_RECOVER_SIG_SIZE");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "ERR_RECOVER_INVALID_SIG");

        return ecrecover(_hash, v, r, s);
    }

    function _uintToString(uint _i) private pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _toAsciiString(address _addr) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 value) private pure returns (bytes1) {
        return (uint8(value) < 10) ? bytes1(uint8(value) + 0x30) : bytes1(uint8(value) + 0x57);
    }
}