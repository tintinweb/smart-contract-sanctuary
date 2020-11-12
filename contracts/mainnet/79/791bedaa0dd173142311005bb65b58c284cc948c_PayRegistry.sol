// File: contracts/lib/interface/IPayRegistry.sol

pragma solidity ^0.5.1;

/**
 * @title PayRegistry interface
 */
interface IPayRegistry {
    function calculatePayId(bytes32 _payHash, address _setter) external pure returns(bytes32);

    function setPayAmount(bytes32 _payHash, uint _amt) external;

    function setPayDeadline(bytes32 _payHash, uint _deadline) external;

    function setPayInfo(bytes32 _payHash, uint _amt, uint _deadline) external;

    function setPayAmounts(bytes32[] calldata _payHashes, uint[] calldata _amts) external;

    function setPayDeadlines(bytes32[] calldata _payHashes, uint[] calldata _deadlines) external;

    function setPayInfos(bytes32[] calldata _payHashes, uint[] calldata _amts, uint[] calldata _deadlines) external;

    function getPayAmounts(
        bytes32[] calldata _payIds,
        uint _lastPayResolveDeadline
    ) external view returns(uint[] memory);

    function getPayInfo(bytes32 _payId) external view returns(uint, uint);

    event PayInfoUpdate(bytes32 indexed payId, uint amount, uint resolveDeadline);
}

// File: contracts/PayRegistry.sol

pragma solidity ^0.5.1;


/**
 * @title Pay Registry contract
 * @notice Implementation of a global registry to record payment results
 *   reported by different PayResolvers.
 */
contract PayRegistry is IPayRegistry {
    struct PayInfo {
        uint amount;
        uint resolveDeadline;
    }

    // bytes32 payId => PayInfo payInfo
    mapping(bytes32 => PayInfo) public payInfoMap;

    /**
     * @notice Calculate pay id
     * @param _payHash hash of serialized condPay
     * @param _setter payment info setter, i.e. pay resolver
     * @return calculated pay id
     */
    function calculatePayId(bytes32 _payHash, address _setter) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_payHash, _setter));
    }

    function setPayAmount(bytes32 _payHash, uint _amt) external {
        bytes32 payId = calculatePayId(_payHash, msg.sender);
        PayInfo storage payInfo = payInfoMap[payId];
        payInfo.amount = _amt;

        emit PayInfoUpdate(payId, _amt, payInfo.resolveDeadline);
    }

    function setPayDeadline(bytes32 _payHash, uint _deadline) external {
        bytes32 payId = calculatePayId(_payHash, msg.sender);
        PayInfo storage payInfo = payInfoMap[payId];
        payInfo.resolveDeadline = _deadline;

        emit PayInfoUpdate(payId, payInfo.amount, _deadline);
    }

    function setPayInfo(bytes32 _payHash, uint _amt, uint _deadline) external {
        bytes32 payId = calculatePayId(_payHash, msg.sender);
        PayInfo storage payInfo = payInfoMap[payId];
        payInfo.amount = _amt;
        payInfo.resolveDeadline = _deadline;

        emit PayInfoUpdate(payId, _amt, _deadline);
    }

    function setPayAmounts(bytes32[] calldata _payHashes, uint[] calldata _amts) external {
        require(_payHashes.length == _amts.length, "Lengths do not match");

        bytes32 payId;
        address msgSender = msg.sender;
        for (uint i = 0; i < _payHashes.length; i++) {
            payId = calculatePayId(_payHashes[i], msgSender);
            PayInfo storage payInfo = payInfoMap[payId];
            payInfo.amount = _amts[i];

            emit PayInfoUpdate(payId, _amts[i], payInfo.resolveDeadline);
        }
    }

    function setPayDeadlines(bytes32[] calldata _payHashes, uint[] calldata _deadlines) external {
        require(_payHashes.length == _deadlines.length, "Lengths do not match");

        bytes32 payId;
        address msgSender = msg.sender;
        for (uint i = 0; i < _payHashes.length; i++) {
            payId = calculatePayId(_payHashes[i], msgSender);
            PayInfo storage payInfo = payInfoMap[payId];
            payInfo.resolveDeadline = _deadlines[i];

            emit PayInfoUpdate(payId, payInfo.amount, _deadlines[i]);
        }
    }

    function setPayInfos(bytes32[] calldata _payHashes, uint[] calldata _amts, uint[] calldata _deadlines) external {
        require(
            _payHashes.length == _amts.length && _payHashes.length == _deadlines.length,
            "Lengths do not match"
        );

        bytes32 payId;
        address msgSender = msg.sender;
        for (uint i = 0; i < _payHashes.length; i++) {
            payId = calculatePayId(_payHashes[i], msgSender);
            PayInfo storage payInfo = payInfoMap[payId];
            payInfo.amount = _amts[i];
            payInfo.resolveDeadline = _deadlines[i];

            emit PayInfoUpdate(payId, _amts[i], _deadlines[i]);
        }
    }

    /**
     * @notice Get the amounts of a list of queried pays
     * @dev pay results must have been unchangable before calling this function.
     *   This API is for CelerLedger
     * @param _payIds ids of queried pays
     * @param _lastPayResolveDeadline the last pay resolve deadline of all queried pays
     * @return queried pay amounts
     */
    function getPayAmounts(
        bytes32[] calldata _payIds,
        uint _lastPayResolveDeadline
    )
        external view returns(uint[] memory)
    {
        uint[] memory amounts = new uint[](_payIds.length);
        for (uint i = 0; i < _payIds.length; i++) {
            if (payInfoMap[_payIds[i]].resolveDeadline == 0) {
                // should pass last pay resolve deadline if never resolved
                require(block.number > _lastPayResolveDeadline, "Payment is not finalized");
            } else {
                // should pass resolve deadline if resolved
                require(
                    block.number > payInfoMap[_payIds[i]].resolveDeadline,
                    "Payment is not finalized"
                );
            }
            amounts[i] = payInfoMap[_payIds[i]].amount;
        }
        return amounts;
    }

    function getPayInfo(bytes32 _payId) external view returns(uint, uint) {
        PayInfo storage payInfo = payInfoMap[_payId];
        return (payInfo.amount, payInfo.resolveDeadline);
    }
}