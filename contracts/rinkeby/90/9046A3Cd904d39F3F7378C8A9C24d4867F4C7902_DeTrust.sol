//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import "./interfaces/IDeTrust.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DeTrust is IDeTrust, Initializable {

    uint private trustId;

    /*
      Paid directly would be here.
    */
    mapping(address => uint) private settlorBalance;

    mapping(uint => Trust) private trusts;

    mapping(address => uint[]) private settlorToTrustIds;

    mapping(address => uint[]) private beneficiaryToTrustIds;


    uint private unlocked;

    modifier lock() {
        require(unlocked == 1, 'Trust: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * constructor replaced by initialize with timelock upgrade
     */
    function initialize() external initializer {
        unlocked = 1;
    }

    /**
     * If ppl send the ether to this contract directly
     */
    receive() external payable {
        require(msg.value > 0, "msg.value is 0");
        settlorBalance[msg.sender] += msg.value;
    }

    function getBalance(address account)
        external
        view
        override
        returns (uint balance)
    {
        return settlorBalance[account];
    }

    function sendBalanceTo(address to, uint amount) external override {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= amount, "Balance insufficient");
        settlorBalance[settlor] -= amount;
        require(payable(to).send(amount), "send balance failed");
    }

    function getTrustListAsBeneficiary(address account)
        external
        view
        override
        returns (Trust[] memory)
    {
        uint[] memory trustIds = beneficiaryToTrustIds[account];
        uint length = trustIds.length;
        Trust[] memory trustsAsBeneficiary = new Trust[](length);
        for (uint i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsBeneficiary[i] = t;
        }
        return trustsAsBeneficiary;
    }

    function getTrustListAsSettlor(address account)
        external
        view
        override
        returns (Trust[] memory)
    {
        uint[] memory trustIds = settlorToTrustIds[account];
        uint length = trustIds.length;
        Trust[] memory trustsAsSettlor = new Trust[](length);
        for (uint i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsSettlor[i] = t;
        }
        return trustsAsSettlor;
    }

    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        external
        override
        lock
        returns (uint tId)
    {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= totalAmount, "balance insufficient");

        settlorBalance[settlor] -= totalAmount;

        return _addTrust(
            name,
            beneficiary,
            settlor,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );
    }

    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        bool revocable
    )
        external
        payable
        override
        lock returns (uint tId)
    {
        uint totalAmount = msg.value;
        require(totalAmount > 0, "msg.value is 0");

        return _addTrust(
            name,
            beneficiary,
            msg.sender,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );
    }

    function setIrrevocable(uint tId) external override lock {
        Trust storage t = trusts[tId];
        uint totalAmount = t.totalAmount;
        require(totalAmount > 0, "trust not found");
        require(t.settlor == msg.sender, "settlor error");
        if (!t.revocable) {
            return;
        }
        t.revocable = false;
    }

    function revoke(uint tId) external override lock {
        Trust storage t = trusts[tId];
        uint totalAmount = t.totalAmount;
        require(totalAmount > 0, "trust not found");
        require(t.settlor == msg.sender, "settlor error");
        require(t.revocable, "trust irrevocable");
        _deleteTrust(tId, t.beneficiary, t.settlor);

        require(payable(msg.sender).send(totalAmount), "revoke failed");
        emit TrustRevoked(tId);
    }

    function topUp(uint tId) external payable override lock {
        uint amount = msg.value;
        require(amount > 0, "msg.value is 0");
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function topUpFromBalance(uint tId, uint amount) external override lock {
        address settlor = msg.sender;
        uint balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function release(uint tId) external override lock {
        address beneficiary = msg.sender;
        _release(tId, beneficiary, beneficiary);
    }

    function releaseTo(uint tId, address to) external override lock {
        _release(tId, msg.sender, to);
    }

    function releaseAll() external override lock {
        address beneficiary = msg.sender;
        _releaseAll(beneficiary, beneficiary);
    }

    function releaseAllTo(address to) external override lock {
        _releaseAll(msg.sender, to);
    }

    // internal functions

    function _release(uint tId, address beneficiary, address to) internal {
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        require(t.beneficiary == beneficiary, "beneficiary error");
        uint releaseAmount = _releaseTrust(t);
        if (releaseAmount == 0) {
            revert("nothing to release");
        }
        bool isDeleted = (t.totalAmount == 0);
        if (isDeleted) {
            _deleteTrust(tId, t.beneficiary, t.settlor);
            emit TrustFinished(tId);
        }
        require(payable(to).send(releaseAmount), "release failed");
        emit Release(beneficiary, releaseAmount);
    }

    function _releaseAll(address beneficiary, address to) internal {
        uint[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        require(trustIds.length > 0, "nothing to release");
        uint i;
        uint j;
        uint totalReleaseAmount;
        uint tId;
        bool isDeleted;
        uint length = trustIds.length;
        for (i = 0; i < length && trustIds.length > 0; i++) {
            tId = trustIds[j];
            Trust storage t = trusts[tId];
            uint releaseAmount = _releaseTrust(t);
            if (releaseAmount != 0) {
                totalReleaseAmount += releaseAmount;
            }
            isDeleted = (t.totalAmount == 0);
            if (isDeleted) {
                _deleteTrust(tId, t.beneficiary, t.settlor);
                emit TrustFinished(tId);
            } else {
                j++;
            }
        }
        if (totalReleaseAmount == 0) {
            revert("nothing to release");
        }

        require(payable(to).send(totalReleaseAmount), "release failed");
        emit Release(beneficiary, totalReleaseAmount);
    }

    function _deleteTrust(uint tId, address beneficiary, address settlor) internal {
        delete trusts[tId];
        uint[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        if (trustIds.length == 1) {
            trustIds.pop();
        } else {
            uint i;
            for (i = 0; i < trustIds.length; i++) {
                if (trustIds[i] == tId) {
                    if (i != trustIds.length - 1) {
                        trustIds[i] = trustIds[trustIds.length - 1];
                    }
                    trustIds.pop();
                }
            }
        }
        uint[] storage settlorTIds = settlorToTrustIds[settlor];
        if (settlorTIds.length == 1) {
            settlorTIds.pop();
            return;
        }
        uint k;
        for (k = 0; k < settlorTIds.length; k++) {
            if (settlorTIds[k] == tId) {
                if (k != settlorTIds.length - 1) {
                    settlorTIds[k] = settlorTIds[settlorTIds.length - 1];
                }
                settlorTIds.pop();
            }
        }
    }

    function _addTrust(
        string memory name,
        address beneficiary,
        address settlor,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        internal
        returns (uint _id)
    {
        require(timeInterval != 0, "timeInterval should be positive");
        _id = ++trustId;
        trusts[_id].id = _id;
        trusts[_id].name = name;
        trusts[_id].settlor = settlor;
        trusts[_id].beneficiary = beneficiary;
        trusts[_id].nextReleaseTime = startReleaseTime;
        trusts[_id].timeInterval = timeInterval;
        trusts[_id].amountPerTimeInterval = amountPerTimeInterval;
        trusts[_id].totalAmount = totalAmount;
        trusts[_id].revocable = revocable;

        settlorToTrustIds[settlor].push(_id);
        beneficiaryToTrustIds[beneficiary].push(_id);

        emit TrustAdded(
            name,
            settlor,
            beneficiary,
            _id,
            startReleaseTime,
            timeInterval,
            amountPerTimeInterval,
            totalAmount,
            revocable
        );

        return _id;
    }

    function _releaseTrust(Trust storage t) internal returns (uint) {
        uint nowTimestamp = block.timestamp;
        if (t.nextReleaseTime > nowTimestamp) {
            return 0;
        }
        uint distributionAmount = (nowTimestamp - t.nextReleaseTime) / t.timeInterval + 1;
        uint releaseAmount = distributionAmount * t.amountPerTimeInterval;
        if (releaseAmount >= t.totalAmount) {
            releaseAmount = t.totalAmount;
            t.totalAmount = 0;
        } else {
            t.totalAmount -= releaseAmount;
            t.nextReleaseTime += distributionAmount * t.timeInterval;
        }
        emit TrustReleased(t.id, t.beneficiary, releaseAmount, t.nextReleaseTime);
        return releaseAmount;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IDeTrust {

    struct Trust {
        uint id;  // the id of the trust
        string name;  // the name of the trust, like 'trust for Bob's son'
        address settlor;  // the settlor of the trust
        address beneficiary;  // the beneficiary of the trust, such as Bob's son
        uint nextReleaseTime;  // when would the money begin to release to beneficiary
        uint timeInterval;  // how often the money is going to release to beneficiary
        uint amountPerTimeInterval;  // how much can a beneficiary to get the money
        uint totalAmount;  // total money in this trust
        bool revocable;  // is this trust revocable or irrevocable
    }

    /*
     * Event that a new trust is added
     *
     * @param name the name of the trust
     * @param settlor the settlor address of the trust
     * @param beneficiary the beneficiary address of the trust
     * @param trustId the trustId of the trust
     * @param startReleaseTime will this trust start to release money, UTC in seconds
     * @param timeInterval how often can a beneficiary to get the money in seconds
     * @param amountPerTimeInterval how much can a beneficiary to get the money
     * @param totalAmount how much money are put in the trust
     * @param revocable whether this trust is revocalbe
     */
    event TrustAdded(
        string name,
        address indexed settlor,
        address indexed beneficiary,
        uint indexed trustId,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    );

    /*
     * Event that new fund are added into a existing trust
     *
     * @param trustId the trustId of the trust
     * @param amount how much money are added into the trust
     */
    event TrustFundAdded(uint indexed trustId, uint amount);

    /*
     * Event that a trust is finished
     *
     * @param trustId the trustId of the trust
     */
    event TrustFinished(uint indexed trustId);

    /*
     * Event that a trust is releaseed
     *
     * @param trustId the trustId of the trust
     */
    event TrustReleased(
        uint indexed trustId,
        address indexed beneficiary,
        uint amount,
        uint nextReleaseTime
    );

    /*
     * Event that a trust is revoked
     *
     * @param trustId the trustId of the trust
     */
    event TrustRevoked(uint indexed trustId);

    /*
     * Event that beneficiary get some money from the contract
     *
     * @param beneficiary the address of beneficiary
     * @param totalAmount how much the beneficiary released from this contract
     */
    event Release(address indexed beneficiary, uint totalAmount);

    /*
     * Get the balance in this contract, which is not send to any trust
     * @return the balance of the settlor in this contract
     *
     */
    function getBalance(address account) external view returns (uint balance);

    /*
     * If money is send to this contract by accident, can use this
     * function to get money back ASAP.
     *
     * @param to the address money would send to
     * @param amount how much money are added into the trust
     */
    function sendBalanceTo(address to, uint amount) external;

    /*
     * Get beneficiary's all trusts
     *
     * @return array of trusts which's beneficiary is the tx.orgigin
     */
    function getTrustListAsBeneficiary(address account)
        external
        view
        returns(Trust[] memory);


    /*
     * Get settlor's all trusts
     *
     * @return array of trusts which's settlor is the tx.orgigin
     */
    function getTrustListAsSettlor(address account)
        external
        view
        returns(Trust[] memory);

    /*
     * Add a new trust from settlor's balance in this contract.
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     * @param totalAmount how much money is added to the trust
     * @param revocable whether this trust is revocable
     */
    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        external
        returns (uint trustId);

    /*
     * Add a new trust by pay
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     * @param revocable whether this trust is revocalbe
     */
    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        bool revocable
    )
        external
        payable
        returns (uint trustId);

    /*
     * Set trust to irrevocable
     *
     * @param trustId the trustId settlor want to set irrevocable
     */
    function setIrrevocable(uint trustId) external;

    /*
     * Revoke a trust, withdraw all the money out
     *
     * @param trustId the trustId settlor want to top up
     */
    function revoke(uint trustId) external;

    /*
     * Top up a trust by payment
     * @param trustId the trustId settlor want to top up
     */
    function topUp(uint trustId) external payable;

    /*
     * Top up from balance to a trust by trustId
     *
     * @param trustId the trustId settlor want add to top up
     * @param amount the amount of money settlor want to top up
     */
    function topUpFromBalance(uint trustId, uint amount) external;

    /*
     * Beneficiary release one trust asset by this function
     *
     * @param trustId the trustId beneficiary want to release
     *
     */
    function release(uint trustId) external;

    /*
     * Beneficiary release one trust asset by this function
     *
     * @param trustId the trustId beneficiary want to release
     * @param to the address beneficiary want to release to
     *
     */
    function releaseTo(uint trustId, address to) external;

    /*
     * Beneficiary get token by this function, release all the
     * trust releaeable assets in the contract
     */
    function releaseAll() external;

    /*
     * Beneficiary get token by this function, release all the
     * trust releaeable assets in the contract
     *
     * @param to the address beneficiary want to release to
     */
    function releaseAllTo(address to) external;

}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

