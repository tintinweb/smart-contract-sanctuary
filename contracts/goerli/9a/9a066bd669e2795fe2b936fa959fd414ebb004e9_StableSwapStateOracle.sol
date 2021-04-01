// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import {RLPReader} from "./RLPReader.sol";
import {StateProofVerifier as Verifier} from "./StateProofVerifier.sol";
import {SafeMath} from "./SafeMath.sol";

interface IPriceHelper {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory xp,
        uint256 A,
        uint256 fee
    ) external pure returns (uint256);
}


interface IStableSwap {
    function fee() external view returns (uint256);
    function A_precise() external view returns (uint256);
}


contract StableSwapStateOracle {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using SafeMath for uint256;

    event SlotValuesUpdated(
        uint256 timestamp,
        uint256 poolEthBalance,
        uint256 poolAdminEthBalance,
        uint256 poolAdminStethBalance,
        uint256 stethPoolShares,
        uint256 stethTotalShares,
        uint256 stethBeaconBalance,
        uint256 stethBufferedEther,
        uint256 stethDepositedValidators,
        uint256 stethBeaconValidators
    );

    event PriceUpdated(
        uint256 timestamp,
        uint256 etherBalance,
        uint256 stethBalance,
        uint256 stethPrice
    );

    event PriceUpdateThresholdChanged(uint256 threshold);
    event AdminChanged(address admin);


    // Prevent reporitng data that is more fresh than this number of blocks ago
    uint256 constant public MIN_BLOCK_DELAY = 2;

    // Constants for offchain proof generation

    address constant public POOL_ADDRESS = 0x12edd9e2073E480cc546e1E0aD7F1c9D60c0cA1E;
    address constant public STETH_ADDRESS = 0x5feB011F04Ec47cA42E75F5AC2bea4C50A646054;

    // keccak256(abi.encodePacked(uint256(1)))
    bytes32 constant public POOL_ADMIN_BALANCES_0_POS = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;

    // bytes32(uint256(POOL_ADMIN_BALANCES_0_POS) + 1)
    bytes32 constant public POOL_ADMIN_BALANCES_1_POS = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf7;

    // keccak256(uint256(0xdc24316b9ae028f1497c275eb9192a3ea0f67022) . uint256(0))
    bytes32 constant public STETH_POOL_SHARES_POS = 0xba532dade4d5adf55019f2054555f8be92825f42f1b1f887c463e0eaecae13e5;

    // keccak256("lido.StETH.totalShares")
    bytes32 constant public STETH_TOTAL_SHARES_POS = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;

    // keccak256("lido.Lido.beaconBalance")
    bytes32 constant public STETH_BEACON_BALANCE_POS = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483;

    // keccak256("lido.Lido.bufferedEther")
    bytes32 constant public STETH_BUFFERED_ETHER_POS = 0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0;

    // keccak256("lido.Lido.depositedValidators")
    bytes32 constant public STETH_DEPOSITED_VALIDATORS_POS = 0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c;

    // keccak256("lido.Lido.beaconValidators")
    bytes32 constant public STETH_BEACON_VALIDATORS_POS = 0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10;

    // Constants for onchain proof verification

    // keccak256(abi.encodePacked(POOL_ADDRESS))
    bytes32 constant POOL_ADDRESS_HASH = 0x51642a1ce0d19b5f448a8b759c59a3973187a95542ae93dc6ac87b53594c77fc;

    // keccak256(abi.encodePacked(STETH_ADDRESS))
    bytes32 constant STETH_ADDRESS_HASH = 0x2d5198234730c9418bc83ad60aa9aa90c4d750fc905af78315c137983ca38545;

    // keccak256(abi.encodePacked(POOL_ADMIN_BALANCES_0_POS))
    bytes32 constant POOL_ADMIN_BALANCES_0_HASH = 0xb5d9d894133a730aa651ef62d26b0ffa846233c74177a591a4a896adfda97d22;

    // keccak256(abi.encodePacked(POOL_ADMIN_BALANCES_1_POS)
    bytes32 constant POOL_ADMIN_BALANCES_1_HASH = 0xea7809e925a8989e20c901c4c1da82f0ba29b26797760d445a0ce4cf3c6fbd31;

    // keccak256(abi.encodePacked(STETH_POOL_SHARES_POS)
    bytes32 constant STETH_POOL_SHARES_HASH = 0x3df4689e9ec9f560b62a1bcfda201a53d5c4d2f95046bb4ccb63e24e71eb04e9;

    // keccak256(abi.encodePacked(STETH_TOTAL_SHARES_POS)
    bytes32 constant STETH_TOTAL_SHARES_HASH = 0x4068b5716d4c00685289292c9cdc7e059e67159cd101476377efe51ba7ab8e9f;

    // keccak256(abi.encodePacked(STETH_BEACON_BALANCE_POS)
    bytes32 constant STETH_BEACON_BALANCE_HASH = 0xa6965d4729b36ed8b238f6ba55294196843f8be2850c5f63b6fb6d29181b50f8;

    // keccak256(abi.encodePacked(STETH_BUFFERED_ETHER_POS)
    bytes32 constant STETH_BUFFERED_ETHER_HASH = 0xa39079072910ef75f32ddc4f40104882abfc19580cc249c694e12b6de868ee1d;

    // keccak256(abi.encodePacked(STETH_DEPOSITED_VALIDATORS_POS)
    bytes32 constant STETH_DEPOSITED_VALIDATORS_HASH = 0x17216d3ffd8719eeee6d8052f7c1e6269bd92d2390d3e3fc4cde1f026e427fb3;

    // keccak256(abi.encodePacked(STETH_BEACON_VALIDATORS_POS)
    bytes32 constant STETH_BEACON_VALIDATORS_HASH = 0x6fd60d3960d8a32cbc1a708d6bf41bbce8152e61e72b2236d5e1ecede9c4cc72;

    uint256 constant internal STETH_DEPOSIT_SIZE = 32 ether;


    IPriceHelper internal helper;

    /**
     * The admin has the right to set the suggested price update threshold (see below).
     */
    address public admin;

    /**
     * The price update threshold percentage advised to oracle clients. If the current price
     * in the pool differs less than this, the clients are advised to skip updating the oracle.
     * However, this threshold is not enforced, so clients are free to update the oracle with
     * any valid price.
     *
     * Expressed in basis points: 10000 BP equal to 100%, 100 BP to 1%.
     */
    uint256 public priceUpdateThreshold;

    /**
     * The proven pool state and its timestamp.
     */
    uint256 public timestamp;
    uint256 public etherBalance;
    uint256 public stethBalance;
    uint256 public stethPrice;


    constructor(IPriceHelper _helper, address _admin, uint256 _priceUpdateThreshold) public {
        helper = _helper;
        _setAdmin(_admin);
        _setPriceUpdateThreshold(_priceUpdateThreshold);
    }


    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        _setAdmin(_admin);
    }


    function setPriceUpdateThreshold(uint256 _priceUpdateThreshold) external {
        require(msg.sender == admin);
        _setPriceUpdateThreshold(_priceUpdateThreshold);
    }


    function getProofParams() external view returns (
        address poolAddress,
        address stethAddress,
        bytes32 poolAdminEtherBalancePos,
        bytes32 poolAdminCoinBalancePos,
        bytes32 stethPoolSharesPos,
        bytes32 stethTotalSharesPos,
        bytes32 stethBeaconBalancePos,
        bytes32 stethBufferedEtherPos,
        bytes32 stethDepositedValidatorsPos,
        bytes32 stethBeaconValidatorsPos,
        uint256 advisedPriceUpdateThreshold
    ) {
        return (
            POOL_ADDRESS,
            STETH_ADDRESS,
            POOL_ADMIN_BALANCES_0_POS,
            POOL_ADMIN_BALANCES_1_POS,
            STETH_POOL_SHARES_POS,
            STETH_TOTAL_SHARES_POS,
            STETH_BEACON_BALANCE_POS,
            STETH_BUFFERED_ETHER_POS,
            STETH_DEPOSITED_VALIDATORS_POS,
            STETH_BEACON_VALIDATORS_POS,
            priceUpdateThreshold
        );
    }


    function getState() external view returns (
        uint256 _timestamp,
        uint256 _etherBalance,
        uint256 _stethBalance,
        uint256 _stethPrice
    ) {
        return (timestamp, etherBalance, stethBalance, stethPrice);
    }


    function submitState(bytes memory _blockHeaderRlpBytes, bytes memory _proofRlpBytes)
        external
    {
        Verifier.BlockHeader memory blockHeader = Verifier.verifyBlockHeader(_blockHeaderRlpBytes);

        {
            uint256 currentBlock = block.number;
            // ensure block finality
            require(
                currentBlock > blockHeader.number &&
                currentBlock - blockHeader.number >= MIN_BLOCK_DELAY,
                "block too fresh"
            );
        }

        require(blockHeader.timestamp > timestamp, "stale data");

        RLPReader.RLPItem[] memory proofs = _proofRlpBytes.toRlpItem().toList();
        require(proofs.length == 10, "total proofs");

        Verifier.Account memory accountPool = Verifier.extractAccountFromProof(
            POOL_ADDRESS_HASH,
            blockHeader.stateRootHash,
            proofs[0].toList()
        );

        require(accountPool.exists, "accountPool");

        Verifier.Account memory accountSteth = Verifier.extractAccountFromProof(
            STETH_ADDRESS_HASH,
            blockHeader.stateRootHash,
            proofs[1].toList()
        );

        require(accountSteth.exists, "accountSteth");

        Verifier.SlotValue memory slotPoolAdminBalances0 = Verifier.extractSlotValueFromProof(
            POOL_ADMIN_BALANCES_0_HASH,
            accountPool.storageRoot,
            proofs[2].toList()
        );

        require(slotPoolAdminBalances0.exists, "adminBalances0");

        Verifier.SlotValue memory slotPoolAdminBalances1 = Verifier.extractSlotValueFromProof(
            POOL_ADMIN_BALANCES_1_HASH,
            accountPool.storageRoot,
            proofs[3].toList()
        );

        require(slotPoolAdminBalances1.exists, "adminBalances1");

        Verifier.SlotValue memory slotStethPoolShares = Verifier.extractSlotValueFromProof(
            STETH_POOL_SHARES_HASH,
            accountSteth.storageRoot,
            proofs[4].toList()
        );

        require(slotStethPoolShares.exists, "poolShares");

        Verifier.SlotValue memory slotStethTotalShares = Verifier.extractSlotValueFromProof(
            STETH_TOTAL_SHARES_HASH,
            accountSteth.storageRoot,
            proofs[5].toList()
        );

        require(slotStethTotalShares.exists, "totalShares");

        Verifier.SlotValue memory slotStethBeaconBalance = Verifier.extractSlotValueFromProof(
            STETH_BEACON_BALANCE_HASH,
            accountSteth.storageRoot,
            proofs[6].toList()
        );

        require(slotStethBeaconBalance.exists, "beaconBalance");

        Verifier.SlotValue memory slotStethBufferedEther = Verifier.extractSlotValueFromProof(
            STETH_BUFFERED_ETHER_HASH,
            accountSteth.storageRoot,
            proofs[7].toList()
        );

        require(slotStethBufferedEther.exists, "bufferedEther");

        Verifier.SlotValue memory slotStethDepositedValidators = Verifier.extractSlotValueFromProof(
            STETH_DEPOSITED_VALIDATORS_HASH,
            accountSteth.storageRoot,
            proofs[8].toList()
        );

        require(slotStethDepositedValidators.exists, "depositedValidators");

        Verifier.SlotValue memory slotStethBeaconValidators = Verifier.extractSlotValueFromProof(
            STETH_BEACON_VALIDATORS_HASH,
            accountSteth.storageRoot,
            proofs[9].toList()
        );

        require(slotStethBeaconValidators.exists, "beaconValidators");

        emit SlotValuesUpdated(
            blockHeader.timestamp,
            accountPool.balance,
            slotPoolAdminBalances0.value,
            slotPoolAdminBalances1.value,
            slotStethPoolShares.value,
            slotStethTotalShares.value,
            slotStethBeaconBalance.value,
            slotStethBufferedEther.value,
            slotStethDepositedValidators.value,
            slotStethBeaconValidators.value
        );

        uint256 newEtherBalance = accountPool.balance.sub(slotPoolAdminBalances0.value);
        uint256 newStethBalance = _getStethBalanceByShares(
            slotStethPoolShares.value,
            slotStethTotalShares.value,
            slotStethBeaconBalance.value,
            slotStethBufferedEther.value,
            slotStethDepositedValidators.value,
            slotStethBeaconValidators.value
        ).sub(slotPoolAdminBalances1.value);

        uint256 newStethPrice = _calcPrice(newEtherBalance, newStethBalance);

        timestamp = blockHeader.timestamp;
        etherBalance = newEtherBalance;
        stethBalance = newStethBalance;
        stethPrice = newStethPrice;

        emit PriceUpdated(blockHeader.timestamp, newEtherBalance, newStethBalance, newStethPrice);
    }


    function _getStethBalanceByShares(
        uint256 _shares,
        uint256 _totalShares,
        uint256 _beaconBalance,
        uint256 _bufferedEther,
        uint256 _depositedValidators,
        uint256 _beaconValidators
    )
        internal pure returns (uint256)
    {
        // https://github.com/lidofinance/lido-dao/blob/v1.0.0/contracts/0.4.24/StETH.sol#L283
        // https://github.com/lidofinance/lido-dao/blob/v1.0.0/contracts/0.4.24/Lido.sol#L719
        // https://github.com/lidofinance/lido-dao/blob/v1.0.0/contracts/0.4.24/Lido.sol#L706
        if (_totalShares == 0) {
            return 0;
        }
        uint256 transientBalance = _depositedValidators.sub(_beaconValidators).mul(STETH_DEPOSIT_SIZE);
        uint256 totalPooledEther = _bufferedEther.add(_beaconBalance).add(transientBalance);
        return _shares.mul(totalPooledEther).div(_totalShares);
    }


    function _calcPrice(uint256 _etherBalance, uint256 _stethBalance) internal view returns (uint256) {
        uint256 A = IStableSwap(POOL_ADDRESS).A_precise();
        uint256 fee = IStableSwap(POOL_ADDRESS).fee();
        return helper.get_dy(1, 0, 10**18, [_etherBalance, _stethBalance], A, fee);
    }


    function _setPriceUpdateThreshold(uint256 _priceUpdateThreshold) internal {
        require(_priceUpdateThreshold <= 10000);
        priceUpdateThreshold = _priceUpdateThreshold;
        emit PriceUpdateThresholdChanged(_priceUpdateThreshold);
    }


    function _setAdmin(address _admin) internal {
        require(_admin != address(0));
        admin = _admin;
        emit AdminChanged(_admin);
    }
}