//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IDeTrust.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DeTrust is IDeTrust, Initializable {
    uint256 private trustId;

    /*
      Paid directly would be here.
    */
    mapping(address => uint256) private settlorBalance;

    mapping(uint256 => Trust) private trusts;

    mapping(address => uint256[]) private settlorToTrustIds;

    mapping(address => uint256[]) private beneficiaryToTrustIds;

    uint256 private unlocked;

    modifier lock() {
        require(unlocked == 1, "Trust: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function initialize() public initializer {
        unlocked = 1;
    }

    /*
      If ppl send the ether to this contract directly
     */
    receive() external payable {
        require(msg.value > 0, "msg.value is 0");
        settlorBalance[tx.origin] += msg.value;
    }

    function getBalance() external view override returns (uint256 balance) {
        return settlorBalance[tx.origin];
    }

    function sendBalanceTo(address to, uint256 amount) external override {
        address settlor = tx.origin;
        uint256 balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        if (!payable(to).send(amount)) {
            revert("send failed");
        }
    }

    function getTrustListAsBeneficiary()
        external
        view
        override
        returns (Trust[] memory)
    {
        uint256[] memory trustIds = beneficiaryToTrustIds[tx.origin];
        uint256 length = trustIds.length;
        Trust[] memory trustsAsBeneficiary = new Trust[](length);
        for (uint256 i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsBeneficiary[i] = t;
        }
        return trustsAsBeneficiary;
    }

    function getTrustListAsSettlor()
        external
        view
        override
        returns (Trust[] memory)
    {
        uint256[] memory trustIds = settlorToTrustIds[tx.origin];
        uint256 length = trustIds.length;
        Trust[] memory trustsAsSettlor = new Trust[](length);
        for (uint256 i = 0; i < length; i++) {
            Trust storage t = trusts[trustIds[i]];
            trustsAsSettlor[i] = t;
        }
        return trustsAsSettlor;
    }

    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint256 startReleaseTime,
        uint256 timeInterval,
        uint256 amountPerTimeInterval,
        uint256 totalAmount
    ) external override lock returns (uint256 tId) {
        address settlor = tx.origin;
        uint256 balance = settlorBalance[settlor];
        require(balance >= totalAmount, "balance insufficient");

        settlorBalance[settlor] -= totalAmount;

        return
            _addTrust(
                name,
                beneficiary,
                settlor,
                startReleaseTime,
                timeInterval,
                amountPerTimeInterval,
                totalAmount
            );
    }

    function addTrust(
        string memory name,
        address beneficiary,
        uint256 startReleaseTime,
        uint256 timeInterval,
        uint256 amountPerTimeInterval
    ) external payable override lock returns (uint256 tId) {
        uint256 totalAmount = msg.value;
        require(totalAmount > 0, "msg.value is 0");

        return
            _addTrust(
                name,
                beneficiary,
                tx.origin,
                startReleaseTime,
                timeInterval,
                amountPerTimeInterval,
                totalAmount
            );
    }

    function topUp(uint256 tId) external payable override lock {
        uint256 amount = msg.value;
        require(amount > 0, "msg.value is 0");
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function topUpFromBalance(uint256 tId, uint256 amount)
        external
        override
        lock
    {
        address settlor = tx.origin;
        uint256 balance = settlorBalance[settlor];
        require(balance >= amount, "balance insufficient");
        settlorBalance[settlor] -= amount;
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        t.totalAmount += amount;
        emit TrustFundAdded(tId, amount);
    }

    function release(uint256 tId) external override lock {
        address beneficiary = tx.origin;
        _release(tId, beneficiary, beneficiary);
    }

    function releaseTo(uint256 tId, address to) external override lock {
        _release(tId, tx.origin, to);
    }

    function releaseAll() external override lock {
        address beneficiary = tx.origin;
        _releaseAll(beneficiary, beneficiary);
    }

    function releaseAllTo(address to) external override lock {
        _releaseAll(tx.origin, to);
    }

    // internal functions

    function _release(
        uint256 tId,
        address beneficiary,
        address to
    ) internal {
        Trust storage t = trusts[tId];
        require(t.totalAmount > 0, "trust not found");
        require(t.beneficiary == beneficiary, "beneficiary error");
        uint256 releaseAmount = _releaseTrust(t);
        if (releaseAmount == 0) {
            revert("nothing to release");
        }
        bool isDeleted = (t.totalAmount == 0);
        if (isDeleted) {
            delete trusts[tId];
            emit TrustFinished(tId);
            uint256[] storage trustIds = beneficiaryToTrustIds[beneficiary];
            if (trustIds.length == 1) {
                trustIds.pop();
            } else {
                uint256 i;
                for (i = 0; i < trustIds.length; i++) {
                    if (trustIds[i] == tId) {
                        trustIds[i] = trustIds[trustIds.length - 1];
                        trustIds.pop();
                    }
                }
            }
            uint256[] storage settlorTIds = settlorToTrustIds[t.settlor];
            uint256 k;
            for (k = 0; k < settlorTIds.length; k++) {
                if (settlorTIds[k] == trustId) {
                    if (settlorTIds.length > 1 && k != settlorTIds.length - 1) {
                        settlorTIds[k] = settlorTIds[settlorTIds.length - 1];
                    }
                    settlorTIds.pop();
                }
            }
        }
        if (!payable(to).send(releaseAmount)) {
            revert("release failed");
        }
        emit Release(beneficiary, releaseAmount);
    }

    function _releaseAll(address beneficiary, address to) internal {
        uint256[] storage trustIds = beneficiaryToTrustIds[beneficiary];
        require(trustIds.length > 0, "nothing to release");
        uint256 i;
        uint256 j;
        uint256 totalReleaseAmount;
        uint256 tId;
        bool isDeleted;
        uint256 length = trustIds.length;
        for (i = 0; i < length && trustIds.length > 0; i++) {
            tId = trustIds[j];
            Trust storage t = trusts[tId];
            uint256 releaseAmount = _releaseTrust(t);
            if (releaseAmount != 0) {
                totalReleaseAmount += releaseAmount;
            }
            isDeleted = (t.totalAmount == 0);
            if (isDeleted) {
                delete trusts[tId];
                emit TrustFinished(tId);
                if (trustIds.length > 1 && j != trustIds.length - 1) {
                    trustIds[j] = trustIds[trustIds.length - 1];
                }
                trustIds.pop();
                uint256[] storage settlorTIds = settlorToTrustIds[t.settlor];
                uint256 k;
                for (k = 0; k < settlorTIds.length; k++) {
                    if (settlorTIds[k] == trustId) {
                        if (
                            settlorTIds.length > 1 &&
                            k != settlorTIds.length - 1
                        ) {
                            settlorTIds[k] = settlorTIds[
                                settlorTIds.length - 1
                            ];
                        }
                        settlorTIds.pop();
                    }
                }
            } else {
                j++;
            }
        }
        if (totalReleaseAmount == 0) {
            revert("nothing to release");
        }

        if (!payable(to).send(totalReleaseAmount)) {
            revert("release failed");
        }
        emit Release(beneficiary, totalReleaseAmount);
    }

    function _addTrust(
        string memory name,
        address beneficiary,
        address settlor,
        uint256 startReleaseTime,
        uint256 timeInterval,
        uint256 amountPerTimeInterval,
        uint256 totalAmount
    ) internal returns (uint256 _id) {
        _id = ++trustId;
        trusts[_id].name = name;
        trusts[_id].settlor = settlor;
        trusts[_id].beneficiary = beneficiary;
        trusts[_id].startReleaseTime = startReleaseTime;
        trusts[_id].timeInterval = timeInterval;
        trusts[_id].amountPerTimeInterval = amountPerTimeInterval;
        trusts[_id].totalAmount = totalAmount;

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
            totalAmount
        );

        return _id;
    }

    function _releaseTrust(Trust storage t) internal returns (uint256) {
        uint256 startReleaseTime = t.startReleaseTime;
        uint256 nowTimestamp = block.timestamp;
        if (startReleaseTime >= nowTimestamp) {
            return 0;
        }
        if (
            t.lastReleaseTime != 0 &&
            (nowTimestamp <= t.lastReleaseTime + t.timeInterval)
        ) {
            return 0;
        }
        uint256 distributionTime =
            t.lastReleaseTime == 0
                ? nowTimestamp - t.startReleaseTime
                : nowTimestamp - t.lastReleaseTime;
        uint256 distributionAmount = distributionTime / t.timeInterval;
        uint256 releaseAmount = distributionAmount * t.amountPerTimeInterval;
        if (releaseAmount >= t.totalAmount) {
            releaseAmount = t.totalAmount;
            t.totalAmount = 0;
            return releaseAmount;
        }
        t.totalAmount -= releaseAmount;
        uint256 timeRemainder = distributionTime % t.timeInterval;
        if (timeRemainder != 0) {
            t.lastReleaseTime = nowTimestamp - timeRemainder;
        }
        return releaseAmount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDeTrust {

    struct Trust {
        string name;
        address settlor;
        address beneficiary;
        uint startReleaseTime;
        uint timeInterval;
        uint amountPerTimeInterval;
        uint lastReleaseTime;
        uint totalAmount;
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
     */
    event TrustAdded(string name,
                     address indexed settlor,
                     address indexed beneficiary,
                     uint indexed trustId,
                     uint startReleaseTime,
                     uint timeInterval,
                     uint amountPerTimeInterval,
                     uint totalAmount);

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
    function getBalance() external view returns (uint balance);

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
    function getTrustListAsBeneficiary() external view returns(Trust[] memory);


    /*
     * Get settlor's all trusts
     *
     * @return array of trusts which's settlor is the tx.orgigin
     */
    function getTrustListAsSettlor() external view returns(Trust[] memory);

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
     */
    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount) external returns (uint trustId);

    /*
     * Add a new trust by pay
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     */
    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval) payable external returns (uint trustId);

    /*
     * Top up a trust by payment
     * @param trustId the trustId settlor want to top up
     */
    function topUp(uint trustId) payable external;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 50
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}