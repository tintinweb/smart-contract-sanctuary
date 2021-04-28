// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


import "./vendors/interfaces/IERC20.sol";
import "./vendors/interfaces/IDelegableERC20.sol";
import "./vendors/libraries/SafeMath.sol";
import "./vendors/libraries/SafeERC20.sol";
import "./vendors/contracts/access/Ownable.sol";


contract TeamPoolPACT is Ownable{
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    event Withdraw(uint tokensAmount);

    address public _PACT;
    uint constant oneYear = 365 days;

    uint[2][4] private annualSupplyPoints = [
        [block.timestamp, 12500000e18],
        [block.timestamp.add(oneYear.mul(1)), 12500000e18],
        [block.timestamp.add(oneYear.mul(2)), 12500000e18],
        [block.timestamp.add(oneYear.mul(3)), 12500000e18]
    ];
 
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner (`ownerAddress`) 
     * and pact contract address (`PACT`).
     */
    constructor (
        address ownerAddress,
        address PACT
    ) public {
        require (PACT != address(0), "PACT ADDRESS SHOULD BE NOT NULL");
        _PACT = PACT;
        transferOwnership(ownerAddress == address(0) ? msg.sender : ownerAddress);
        IDelegableERC20(_PACT).delegate(ownerAddress);
    }

    
    /**
     * @dev Returns the annual supply points of the current contract.
     */
    function getReleases() external view returns(uint[2][4] memory) {
        return annualSupplyPoints;
    } 

    /**
     * @dev Withdrawal tokens the address  (`to`) and amount (`amount`).
     * Can only be called by the current owner.
    */
    function withdraw(address to,uint amount) external onlyOwner {
        IERC20 PACT = IERC20(_PACT);
        require (to != address(0), "ADDRESS SHOULD BE NOT NULL");
        require(amount <= PACT.balanceOf(address(this)), "NOT ENOUGH PACT TOKENS ON TEAMPOOL CONTRACT BALANCE");
        for(uint i; i < 4; i++) {
            if(annualSupplyPoints[i][1] >= amount && block.timestamp >= annualSupplyPoints[i][0]) {
               annualSupplyPoints[i][1] = annualSupplyPoints[i][1].sub(amount);
               PACT.safeTransfer(to, amount);
               return ;
            }
        }
        require (false, "TokenTimelock: no tokens to release");              
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../utils/Context.sol";

// Copied from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Copied from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IDelegable {
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IDelegable.sol";
import "./IERC20WithMaxTotalSupply.sol";

interface IDelegableERC20 is IDelegable, IERC20WithMaxTotalSupply {}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IERC20WithMaxTotalSupply is IERC20 {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Mint(address indexed account, uint tokens);
    event Burn(address indexed account, uint tokens);
    function maxTotalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeApprove(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: Add Overflow");
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);// "SafeMath: Add Overflow"

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;// "SafeMath: Underflow"

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: Mul Overflow");
    }
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);// "SafeMath: Mul Overflow"

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}