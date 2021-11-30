/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// Sources flattened with hardhat v2.6.3 https://hardhat.org

// File contracts/libraries/CowSwapUtils.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library CowSwapUtils {
    struct Order {
        address sellToken;
        address buyToken;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        bytes32 kind;
        bool partiallyFillable;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
    }
}


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


// File contracts/Enum.sol

pragma solidity ^0.8.0;

contract Enum {
    enum GnosisSafeOperation {
        Call,
        DelegateCall
    }
}


// File contracts/interfaces/IGnosisSafe.sol

pragma solidity ^0.8.0;

interface IGnosisSafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.GnosisSafeOperation operation
    ) external returns (bool success);

    function getOwners() external view returns (address[] memory);
}


// File contracts/interfaces/IGPv2Settlement.sol

pragma solidity ^0.8.0;

interface IGPv2Settlement {
    function filledAmount(bytes calldata) external view returns (uint256);
    function vaultRelayer() external view returns (address);
    function domainSeparator() external view returns (bytes32);
    function setPreSignature(bytes calldata orderUid, bool signed) external;
}


// File contracts/ScoreLabClientsGnosisSafeModuleCowSwap.sol

pragma solidity ^0.8.0;



contract ScoreLabClientsGnosisSafeModuleCowSwap {
    struct Allowance {
        uint256 amount;
        uint256 expiration;
    }

    struct SafeOrder {
        bytes orderUid;
        uint256 expiration;
        address sellToken;
        address buyToken;
        uint256 sellAmount;
    }

    event Deposit(address indexed safe, uint256 value);
    event Refund(address indexed safe, uint256 value);

    address private constant GPV2_SETTLEMENT = address(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);

    bytes32 private constant COWSWAP_TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";
    uint256 private constant COWSWAP_UID_LENGTH = 56;
    uint256 private constant COWSWAP_ORDER_TIMEOUT = 720; //12 minutes

    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _isScoreLab;
    mapping(address => uint256) private _gasTanks;
    mapping(address => mapping(address => mapping(address => Allowance)))
        private _allowances;
    mapping(address => SafeOrder) private _safesOrders;

    /**
      SL#01: admin only operation
      SL#02: ScoreLab only operation
      SL#03: admin cannot revoke itself
      SL#04: invalid token pair parameters
      SL#05: insufficient gas tank
      SL#06: unable to payback gas, recipient may have reverted
      SL#07: insufficient allowance
      SL#08: lapsed allowance
      SL#09: invalid beneficiary
      SL#10: error presigning order
      SL#11: approve error
      SL#12: safe order in progress
      SL#13: cannot finalize expired order
      SL#14: wrong provided order expiration
     */

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "SL#01");
        _;
    }

    modifier onlyScoreLab() {
        require(_isScoreLab[msg.sender], "SL#02");
        _;
    }

    modifier onlyForSafe(address safe, address beneficiary) {
        require(beneficiary == safe, "SL#09");
        _;
    }

    constructor(address admin) {
        _isAdmin[admin] = true;
    }

    function deposit(address safe) external payable {
        _gasTanks[safe] += msg.value;

        emit Deposit(safe, msg.value);
    }

    function refund(
        address safe,
        uint256 value,
        address to
    ) external onlyScoreLab {
        require(_gasTanks[safe] >= value, "SL#05");
        (bool success, ) = to.call{value: value}("");
        require(success, "SL#06");
        _gasTanks[safe] -= value;

        emit Refund(safe, value);
    }

    function placeOrder(
        address safe,
        CowSwapUtils.Order memory order
    ) 
        external
        onlyScoreLab
        onlyForSafe(safe, order.receiver) 
        {
            Allowance storage allowance = _allowances[safe][order.sellToken][order.buyToken];
            require(allowance.amount >= order.sellAmount, "SL#07");
            require(allowance.expiration >= order.validTo, "SL#08");
            require(order.validTo <= block.timestamp + COWSWAP_ORDER_TIMEOUT, "SL#14");

            SafeOrder storage safeOrder = _safesOrders[safe];
            require(safeOrder.expiration == 0, "SL#12");
            
            bytes memory orderUid = _generateOrderUid(order);

            require (
                IGnosisSafe(safe).execTransactionFromModule(
                    GPV2_SETTLEMENT,
                    0,
                    abi.encodeWithSignature("setPreSignature(bytes,bool)", orderUid, true),
                    Enum.GnosisSafeOperation.Call
                ),
                "SL#10"
            );

            safeOrder.orderUid = orderUid;
            safeOrder.expiration = uint256(order.validTo);
            safeOrder.sellToken = order.sellToken;
            safeOrder.buyToken = order.buyToken;
            safeOrder.sellAmount = order.sellAmount;
        }

    function finalizeOrder(
        address safe
    )
        external
        onlyScoreLab
        {
            SafeOrder storage safeOrder = _safesOrders[safe];
            require(safeOrder.expiration > 0, "SL#13");

            Allowance storage allowance = _allowances[safe][safeOrder.sellToken][safeOrder.buyToken];

            uint256 orderFilledAmount = IGPv2Settlement(GPV2_SETTLEMENT)
                        .filledAmount(safeOrder.orderUid);

            if (orderFilledAmount == safeOrder.sellAmount) {
                //Order successfull
                allowance.amount -= safeOrder.sellAmount;

                safeOrder.expiration = 0;
            } else if (orderFilledAmount == type(uint256).max) {
                //Order killed
                safeOrder.expiration = 0;
            } else if (safeOrder.expiration < block.timestamp) {
                //Order expired
                safeOrder.expiration = 0;
            } else {
                revert("SL#12");
            } 
        }

    function approveSwap(
        address safe,
        address fromToken,
        address toToken,
        uint256 amount
        ) 
        external
        onlyScoreLab
        {
            Allowance storage allowance = _allowances[safe][fromToken][toToken];
            require(allowance.amount >= amount, "SL#07");
            require(allowance.expiration >= block.timestamp, "SL#08");

            address vaultRelayer = IGPv2Settlement(GPV2_SETTLEMENT)
                        .vaultRelayer();

            //Init approval to 0 to avoid attack vectors
            require (
                IGnosisSafe(safe).execTransactionFromModule(
                    fromToken,
                    0,
                    abi.encodeWithSelector(0x095ea7b3, vaultRelayer, 0),
                    Enum.GnosisSafeOperation.Call
                ),
                "SL#11"
            );

            //Approval with the specified amount
            require(
                IGnosisSafe(safe).execTransactionFromModule(
                    fromToken,
                    0,
                    abi.encodeWithSelector(0x095ea7b3, vaultRelayer, amount),
                    Enum.GnosisSafeOperation.Call
                ),
                "SL#11"
            );
    }

    function setTokenPair(
        address from,
        address to,
        uint256 amount,
        uint256 expiration
    ) external {
        require(amount == 0 || expiration > block.timestamp, "SL#04");
        require(amount != 0 || expiration == 0, "SL#04");

        _allowances[msg.sender][from][to] = Allowance({
            amount: amount,
            expiration: expiration
        });
    }

    function setAdmin(address account, bool isAdmin) external onlyAdmin {
        require(isAdmin || msg.sender != account, "SL#03");

        _isAdmin[account] = isAdmin;
    }

    function setScoreLab(address account, bool isScoreLab) external onlyAdmin {
        _isScoreLab[account] = isScoreLab;
    }

    function _generateOrderUid(CowSwapUtils.Order memory order)
        internal
        view
        returns (bytes memory)
        {
            bytes32 domainSeparator = IGPv2Settlement(GPV2_SETTLEMENT)
                            .domainSeparator();

            bytes32 orderDigest;

            bytes32 structHash;

            assembly {
                let dataStart := sub(order, 32)
                let temp := mload(dataStart)
                mstore(dataStart, COWSWAP_TYPE_HASH)
                structHash := keccak256(dataStart, 416)
                mstore(dataStart, temp)
            }

            assembly {
                let freeMemoryPointer := mload(0x40)
                mstore(freeMemoryPointer, "\x19\x01")
                mstore(add(freeMemoryPointer, 2), domainSeparator)
                mstore(add(freeMemoryPointer, 34), structHash)
                orderDigest := keccak256(freeMemoryPointer, 66)
            }

            address receiver = order.receiver;

            uint32 validTo = order.validTo;

            bytes memory orderUid = new bytes(COWSWAP_UID_LENGTH);

            assembly {
                mstore(add(orderUid, 56), validTo)
                mstore(add(orderUid, 52), receiver)
                mstore(add(orderUid, 32), orderDigest)
            }

            return orderUid;
        }
}