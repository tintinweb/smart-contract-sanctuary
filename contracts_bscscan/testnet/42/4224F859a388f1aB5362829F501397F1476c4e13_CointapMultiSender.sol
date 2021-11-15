/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract SafeTransfer {
    
    function _safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(_isContract(address(token)), "SafeTransfer: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTransfer: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTransfer: ERC20 operation did not succeed");
        }
    }

    function _isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract CointapMultiSender is Context, Ownable, SafeTransfer {

    address public SERVICE_ADDRESS = address(0xbe44ddE2875D023D8de11518b4b4e351d6A7bC58);
    uint256 public SERVICE_COST = 0.04 * 10**18;

    // Used to calculate fee if the number of tx is less than 5
    uint256 public MULTIPLIER_TRIAL = 1;

    // Used to calculate fee if the number of tx is less than 50 and more than 5
    uint256 public MULTIPLIER_PREMEUM = 10;

    // Extra fee for each transaction if the number of transfers is more than 50 (Excluding the first 50 transfers)
    uint256 public COST_PER_TX_DIAMOND = 0.0001 * 10**18;

    uint256 public MAX_APPLY_FEE_PER_TX = 10000;

    // Used to disable contract for upgrade or repair contract purpose 
    bool public isDisabled = false;

    address[] public managers;

    constructor() {}

    function _estFeeTransferBulk(uint256 noOfTxs) internal view returns (uint256) {
        // if the number of transfer is more than {MAX_APPLY_FEE_PER_TX} then only apply fee for {MAX_APPLY_FEE_PER_TX} transfers
        if(noOfTxs >= MAX_APPLY_FEE_PER_TX) {
            noOfTxs = MAX_APPLY_FEE_PER_TX;
        }
        if(noOfTxs <= 5) {
           return SERVICE_COST * MULTIPLIER_TRIAL;
        }
        if(noOfTxs > 50) {
           return (SERVICE_COST * MULTIPLIER_TRIAL) + (COST_PER_TX_DIAMOND * (noOfTxs - 50));
        }
        return SERVICE_COST * MULTIPLIER_PREMEUM;
    }
    
    function _sumTotal(uint256[] memory amounts) internal pure returns (uint256) {
        uint256 total = 0;
        for(uint256 i = 0; i < amounts.length; i++) {
           total = total + amounts[i];
        }
        return total;
    } 

    // The same as the simple transfer function
    // But for multiple transfer instructions
    function transferBulk(address token, address[] memory _tos, uint256[] memory _values) public payable virtual returns(bool) {
        require(!isDisabled, "MultiSend Bulk: Service stopped by owner");

        uint256 necessaryCost = _estFeeTransferBulk(_tos.length);
        require(msg.value >= necessaryCost, "MultiSend Bulk: Service cost too low");
        
        // Transfer token amount from sender to MultiSender
        // bool isTransfered;
        uint256 totalTokens = _sumTotal(_values);
        IERC20 erc20token = IERC20(token);

        _safeTransferFrom(erc20token, msg.sender, address(this), totalTokens);

        // Send token from MultiSender to recipients
        for(uint256 i=0; i < _tos.length; i++) {
            // If one fails, revert the tx, including previous transfers
            _safeTransfer(erc20token, _tos[i], _values[i]);
        }

        payable(SERVICE_ADDRESS).transfer(msg.value);
        return true;
   }
   
    function estFeeTransferBulk(uint256 noOfTxs) external view returns(uint256) {
        return _estFeeTransferBulk(noOfTxs);
    }
   
    function setService(address newSerAdd) public virtual onlyManager returns (bool) {
        SERVICE_ADDRESS = newSerAdd;
        return true;
    }
    
    function setBaseCost(uint256 newBaseCost) public virtual onlyManager returns (bool) {
        SERVICE_COST = newBaseCost;
        return true;
    }

    function setMultilierTrial(uint256 newMul) public virtual onlyManager returns (bool) {
        MULTIPLIER_TRIAL = newMul;
        return true;
    }

    function setMultilierPremeum(uint256 newMul) public virtual onlyManager returns (bool) {
        MULTIPLIER_PREMEUM = newMul;
        return true;
    }

    function setCostPerTxForDiamond(uint256 newMul) public virtual onlyManager returns (bool) {
        COST_PER_TX_DIAMOND = newMul;
        return true;
    }
    
    function setDisable(bool newStatus) public virtual onlyManager returns (bool) {
        isDisabled = newStatus;
        return true;
    }

    function setMaxApplyFeePerTx(uint256 newMax) public virtual onlyManager returns (bool) {
        MAX_APPLY_FEE_PER_TX = newMax;
        return true;
    }
    
    // Manager functions
    function _isManager(address newManager) private view returns (bool) {
        for(uint8 i = 0; i < managers.length; i++) {
            if(managers[i] == newManager) {
                return true;
            }
        }
        return false;
    }

    function addManager(address newManager) public virtual onlyOwner returns (bool) {
        require(!_isManager(newManager), "Manager: the address is already a manager");
        managers.push(newManager);
        return true;
    }

    function removeManager(address newManager) public virtual onlyOwner returns (bool) {
        require(_isManager(newManager), "Manager: the address isn't a manager");
        for(uint8 i = 0; i < managers.length; i++) {
            if(managers[i] == newManager) {
                delete managers[i];
                break;
            }
        }
        return true;
    }

    modifier onlyManager() {
        require(_owner == _msgSender() || _isManager(_msgSender()), "Permission: caller is not the manager");
        _;
    }
}

