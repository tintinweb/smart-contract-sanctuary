/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract BlackHole {}

interface IClaimer_v1 {
    function isClaimed(uint32 _block, uint8 _bit) external view returns (bool);
}

contract Claimer_v2 {
    using SafeERC20 for IERC20;
    
    address public admin_;
    address public signOwner_;
    //IClaimer_v1 public claimerV1_;
    address public blackHole_;
    mapping(uint32 => uint256) private bitmask_;
    
    event SetAdmin(address indexed oldAdmin, address indexed newAdmin);
    event SetSignOwner(address indexed msgSender, address indexed oldSignOwner, address indexed newSignOwner);
    event Withdraw(address indexed msgSender, address indexed to, IERC20 token, uint256 amount);
    event Claim(address indexed to, uint32 block, uint8 bit, IERC20 indexed fromToken, uint256 fromAmount, IERC20 indexed toToken, uint256 toAmount);
    
    constructor(address _admin, address _signOwner/*, IClaimer_v1 _claimerV1*/) {
        admin_ = _admin;
        signOwner_ = _signOwner;
        //claimerV1_ = _claimerV1;
        
        blackHole_ = address(new BlackHole());
        
        setClaimed(type(uint32).max, type(uint8).max); // gas savings for the first user that will make a claim
    }
    
    modifier onlyAdmin() {
        require(admin_ == msg.sender, "ERR_AUTH_FAIL");
        _;
    }
    
    function setAdmin(address _admin) external onlyAdmin() {
        emit SetAdmin(admin_, _admin);
        admin_ = _admin;
    }
    
    function setSignOwner(address _signOwner) external onlyAdmin() {
        emit SetSignOwner(msg.sender, signOwner_, _signOwner);
        signOwner_ = _signOwner;
    }
    
    function withdraw(address _to, IERC20 _token, uint256 _amount) external onlyAdmin() {
        if(_amount == 0) {
            _amount = IERC20(_token).balanceOf(address(this));
        }
        
        _token.safeTransfer(_to, _amount);
        
        emit Withdraw(msg.sender, _to, _token, _amount);
    }

    function claim(
        uint32 _block,
        uint8 _bit,
        IERC20 _fromToken,
        uint256 _fromAmount,
        IERC20 _toToken,
        uint256 _toAmount,
        bytes calldata _signature) external {

        require(!isClaimed(_block, _bit), "ERR_ALREADY_CLAIMED");
        
        string memory message = string(abi.encodePacked(
            toAsciiString(msg.sender), ";",
            toAsciiString(address(_fromToken)), ";",
            toAsciiString(address(_toToken)), ";",
            uintToString(_block), ";",
            uintToString(_bit), ";",
            uintToString(_fromAmount), ";",
            uintToString(_toAmount)));

        verify(message, _signature);
        
        setClaimed(_block, _bit);
        
        if(_fromAmount > 0) {
            _fromToken.safeTransferFrom(msg.sender, blackHole_, _fromAmount);
        }
        
        _toToken.safeTransfer(msg.sender, _toAmount);
        
        emit Claim(msg.sender, _block, _bit, _fromToken, _fromAmount, _toToken, _toAmount);
    }

    function setClaimed(uint32 _block, uint8 _bit) private {
        uint256 bitBlock = bitmask_[_block];
        uint256 mask = uint256(1) << _bit;
        
        bitmask_[_block] = (bitBlock | mask);
    }
    
    function isClaimed(uint32 _block, uint8 _bit) public view returns (bool) {
        //if(claimerV1_.isClaimed(_block, _bit)) return true;
        
        uint256 bitBlock = bitmask_[_block];
        uint256 mask = uint256(1) << _bit;
        
        return (bitBlock & mask) > 0;
    }
    
   function verify(string memory _message, bytes calldata _sig) private view {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_message))));
        address messageSigner = recover(messageHash, _sig);

        require(messageSigner == signOwner_, "ERR_VERIFICATION_FAILED");
    }

    function recover(bytes32 _hash, bytes memory _sig) private pure returns (address) {
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

    function uintToString(uint _i) private pure returns (string memory) {
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

    function toAsciiString(address _addr) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 value) private pure returns (bytes1) {
        return (uint8(value) < 10) ? bytes1(uint8(value) + 0x30) : bytes1(uint8(value) + 0x57);
    }
}