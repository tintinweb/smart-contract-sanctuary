// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OracleClient.sol";
import "../../utils/SafeMath.sol";


contract SeedmonGachapon is Ownable, OracleClient {
    using SafeMath for uint256;

    event Result(address player, bytes32 seedmonName, uint256[] stats);
    event RequestCreated(address player, uint256 requestId);
    event RequestRefunded(address player, uint256 requestId);

    struct RequestInfo {
        address player;
        uint256 requestId;
    }

    mapping(address => RequestInfo) public userToRequest;
    mapping(uint256 => RequestInfo) public requestIdToRequest;
    uint256 public latestRequestId;

    mapping(uint256 => bytes32[]) public packToNames;
    mapping(uint256 => uint256[]) public packToBirthRates;
    mapping(uint256 => uint256) public packToAdditionalBonusMin;
    mapping(uint256 => uint256) public packToAdditionalBonusMax;

    constructor(IOracle oracleAddress) {
        __randomOracle_init(oracleAddress);
    }

    function gacha(uint256 packId) payable external {
        RequestInfo storage request = userToRequest[msg.sender];
        require(request.requestId == 0, "Your request is still not end");

        latestRequestId = latestRequestId + 1;
        RequestInfo memory requestInfo = RequestInfo({
            player:  msg.sender,
            requestId: latestRequestId
        });

        userToRequest[msg.sender] = requestInfo;
        requestIdToRequest[latestRequestId] = requestInfo;
        
        requestRandomSeedmon(latestRequestId, packId, packToAdditionalBonusMin[packId], packToAdditionalBonusMax[packId], msg.value);

        emit RequestCreated(requestInfo.player, requestInfo.requestId);
    }

    function requestRefund() external {
        RequestInfo memory requestInfo = userToRequest[msg.sender];
        require(requestInfo.requestId != 0, "No transaction for refund");

        refund(requestInfo.requestId);       
    }

    function processRandomSeedmon(uint256 requestId, bytes32 seedmonName, uint256[] memory bonusStats) internal override {
        RequestInfo memory requestInfo = requestIdToRequest[requestId];
        require(requestInfo.player != address(0), "No bet for this request Id");

        address player = requestInfo.player;

        delete requestIdToRequest[requestId];
        delete userToRequest[player];

        emit Result(player, seedmonName, bonusStats);
    }

    function processRefund(uint256 requestId, uint256 providedGas) internal override {
        RequestInfo memory requestInfo = requestIdToRequest[requestId];
        require(requestInfo.player != address(0), "No transaction for refund processing");

        if (providedGas > 0) {
            payable(requestInfo.player).transfer(providedGas);
        }

        delete requestIdToRequest[requestInfo.requestId];
        delete userToRequest[requestInfo.player]; 

        emit RequestRefunded(requestInfo.player, requestInfo.requestId);
    }

    function listSeedmon(uint256 _packID)
        external
        view
        returns (bytes32[] memory name, uint256[] memory birthRate)
    {
        birthRate = new uint256[](packToNames[_packID].length);
        name = new bytes32[](packToNames[_packID].length);
        for (uint256 i = 0; i < packToNames[_packID].length; i++) {
           name[i] = packToNames[_packID][i];
           birthRate[i] = packToBirthRates[_packID][i];
        }
        return (name, birthRate);
    }

    function setSeedmonList(uint256 _packID, bytes32[] memory name, uint256[] memory birthRate, uint256 min, uint256 max) external {
        packToNames[_packID] = name;
        packToBirthRates[_packID] = birthRate;
        packToAdditionalBonusMin[_packID] = min;
        packToAdditionalBonusMax[_packID] = max;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IClient.sol";
import "../interface/IOracle.sol";


abstract contract OracleClient is IClient {
    IOracle public oracle;

    modifier onlyOracle() {
        require(address(oracle) == msg.sender, "Oracle Client: Caller is not the oracle");
        _;
    }

    function __randomOracle_init(IOracle oracleAddress) internal {
        oracle = oracleAddress;
    }

    // ============ Client Request ============
    function requestRandomNumber(uint256 requestId, uint256 min, uint256 max, uint256 requiredNumber, uint256 providedGas) internal {
        require(requestId > 0, "OracleClient: Invalid request Id for requesting random number");

        oracle.requestRandomNumber{value: providedGas}(requestId, min, max, requiredNumber);
    }

    function requestRandomSeedmon(uint256 requestId, uint256 packId, uint256 min, uint256 max, uint256 providedGas) internal {
        require(requestId > 0, "OracleClient: Invalid request Id for requesting random number");

        oracle.requestRandomSeedmon{value: providedGas}(requestId, packId, min, max);
    }

    function refund(uint256 requestId) internal {
        require(requestId > 0, "OracleClient: Invalid request Id for requesting refund");
        bool isRequestPending = oracle.isRequestPending(address(this), requestId);

        if (isRequestPending) {
            oracle.refund(requestId);
        } else {
            processRefund(requestId, 0);
        }
    }

    // =========== Process ====================
    function processRefund(uint256 requestId, uint256 providedGas) internal virtual {
    }

    function processRandomNumber(uint256 requestId, uint256[] memory randomNumbers) internal virtual {
    }

    function processRandomSeedmon(uint256 requestId, bytes32 seedmonName, uint256[] memory bonusStats) internal virtual {
    }

    // ============ Prophet method ============
    function onRandomNumberReceived(uint256 requestId, uint256[] memory randomNumbers) override external onlyOracle returns (bool isCompleted) {
        processRandomNumber(requestId, randomNumbers);
        isCompleted = true;
    }

    function onRandomSeedmonReceived(uint256 requestId, bytes32 seedmonName,  uint256[] memory bonusStats) override external onlyOracle returns (bool isCompleted) {
        processRandomSeedmon(requestId, seedmonName, bonusStats);
        isCompleted = true;
    }

    function onRefund(uint256 requestId) payable override external onlyOracle { // test onlyOracle
        processRefund(requestId, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a + b;
        require(result >= a, "overflow is prevented");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(a >= b, "overflow is prevented");
        result = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a * b;

        if (b > 0) {
            require((result / b) == a, "overflow is prevented");
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b > 0, "divide by zero error");
        result = a / b;
    }

    // Sample data: precision = 1E6
    function div(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256 result, uint256 returnPrecision) {
        require(b > 0, "divide by zero error");
        returnPrecision = precision;
        result = (a * precision) / b;

        require(a <= (a * precision), "overflow is prevented");
        require((result * b) <= (a * precision), "overflow is prevented");
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b > 0, "divide by zero error");
        result = a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IClient {
    function onRandomNumberReceived(uint256 requestId, uint256[] memory randomNumbers) external returns (bool isCompleted);
    function onRandomSeedmonReceived(uint256 requestId, bytes32 seedmonName,  uint256[] memory bonusStats) external returns (bool isCompleted);
    function onRefund(uint256 requestId) payable external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOracle {
    function refund(uint256 requestId) external;
    function isRequestPending(address requester, uint256 requestId) external returns (bool result);

    function requestRandomNumber(uint256 requestId, uint256 minNumber, uint256 maxNumber, uint256 requiredNumber) payable external;
    function requestRandomSeedmon(uint256 requestId, uint256 packId, uint256 minBonusStat, uint256 maxBonusStat) payable external;
}

