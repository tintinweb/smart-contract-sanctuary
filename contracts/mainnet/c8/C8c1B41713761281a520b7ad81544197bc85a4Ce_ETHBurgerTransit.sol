// Dependency file: contracts/ETH/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Dependency file: contracts/ETH/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Root file: contracts/ETH/ETHBurgerTransit.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

// import 'contracts/ETH/libraries/SafeMath.sol';
// import 'contracts/ETH/libraries/TransferHelper.sol';

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract ETHBurgerTransit {
    using SafeMath for uint;
    
    address public owner;
    address public signWallet;
    address public developWallet;
    address public WETH;
    
    uint public totalFee;
    uint public developFee;
    
    // key: payback_id
    mapping (bytes32 => bool) public executedMap;
    
    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    event Transit(address indexed from, address indexed token, uint amount);
    event Withdraw(bytes32 paybackId, address indexed to, address indexed token, uint amount);
    event CollectFee(address indexed handler, uint amount);
    
    constructor(address _WETH, address _signer, address _developer) public {
        WETH = _WETH;
        signWallet = _signer;
        developWallet = _developer;
        owner = msg.sender;
    }
    
    receive() external payable {
        assert(msg.sender == WETH);
    }
    
    function changeSigner(address _wallet) external {
        require(msg.sender == owner, "CHANGE_SIGNER_FORBIDDEN");
        signWallet = _wallet;
    }
    
    function changeDevelopWallet(address _developWallet) external {
        require(msg.sender == owner, "CHANGE_DEVELOP_WALLET_FORBIDDEN");
        developWallet = _developWallet;
    } 
    
    function changeDevelopFee(uint _amount) external {
        require(msg.sender == owner, "CHANGE_DEVELOP_FEE_FORBIDDEN");
        developFee = _amount;
    }
    
    function collectFee() external {
        require(msg.sender == owner, "FORBIDDEN");
        require(developWallet != address(0), "SETUP_DEVELOP_WALLET");
        require(totalFee > 0, "NO_FEE");
        TransferHelper.safeTransferETH(developWallet, totalFee);
        totalFee = 0;
    }
    
    function transitForBSC(address _token, uint _amount) external {
        require(_amount > 0, "INVALID_AMOUNT");
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        emit Transit(msg.sender, _token, _amount);
    }
    
    function transitETHForBSC() external payable {
        require(msg.value > 0, "INVALID_AMOUNT");
        IWETH(WETH).deposit{value: msg.value}();
        emit Transit(msg.sender, WETH, msg.value);
    }
    
    function withdrawFromBSC(bytes calldata _signature, bytes32 _paybackId, address _token, uint _amount) external lock payable {
        require(executedMap[_paybackId] == false, "ALREADY_EXECUTED");
        executedMap[_paybackId] = true;
        
        require(_amount > 0, "NOTHING_TO_WITHDRAW");
        require(msg.value == developFee, "INSUFFICIENT_VALUE");
        
        bytes32 message = keccak256(abi.encodePacked(_paybackId, _token, msg.sender, _amount));
        require(_verify(message, _signature), "INVALID_SIGNATURE");
        
        if(_token == WETH) {
            IWETH(WETH).withdraw(_amount);
            TransferHelper.safeTransferETH(msg.sender, _amount);
        } else {
            TransferHelper.safeTransfer(_token, msg.sender, _amount);
        }
        totalFee = totalFee.add(developFee);
        
        emit Withdraw(_paybackId, msg.sender, _token, _amount);
    }
    
    function _verify(bytes32 _message, bytes memory _signature) internal view returns (bool) {
        bytes32 hash = _toEthBytes32SignedMessageHash(_message);
        address[] memory signList = _recoverAddresses(hash, _signature);
        return signList[0] == signWallet;
    }
    
    function _toEthBytes32SignedMessageHash (bytes32 _msg) pure internal returns (bytes32 signHash)
    {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msg));
    }
    
    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure internal returns (address[] memory addresses)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }
    
    function _parseSignature(bytes memory _signatures, uint _pos) pure internal returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }
    
    function _countSignatures(bytes memory _signatures) pure internal returns (uint)
    {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}