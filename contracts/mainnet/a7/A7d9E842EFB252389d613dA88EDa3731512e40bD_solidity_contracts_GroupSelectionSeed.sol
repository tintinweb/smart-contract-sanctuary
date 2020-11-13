/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "@keep-network/keep-core/contracts/IRandomBeacon.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract GroupSelectionSeed is IRandomBeaconConsumer, ReentrancyGuard {
    using SafeMath for uint256;

    IRandomBeacon randomBeacon;

    // Gas required for a callback from the random beacon. The value specifies
    // gas required to call `__beaconCallback` function in the worst-case
    // scenario with all the checks and maximum allowed uint256 relay entry as
    // a callback parameter.
    uint256 public constant callbackGas = 30000;

    // Random beacon sends back callback surplus to the requestor. It may also
    // decide to send additional request subsidy fee. What's more, it may happen
    // that the beacon is busy and we will not refresh group selection seed from
    // the beacon. We accumulate all funds received from the beacon in the
    // reseed pool and later use this pool to reseed using a public reseed
    // function on a manual request at any moment.
    uint256 public reseedPool;

    uint256 public groupSelectionSeed;

    constructor(address _randomBeacon) public {
        randomBeacon = IRandomBeacon(_randomBeacon);

        // Initial value before the random beacon updates the seed.
        // https://www.wolframalpha.com/input/?i=pi+to+78+digits
        groupSelectionSeed = 31415926535897932384626433832795028841971693993751058209749445923078164062862;
    }

    /// @notice Adds any received funds to the reseed pool.
    function() external payable {
        reseedPool += msg.value;
    }

    /// @notice Sets a new group selection seed value.
    /// @dev The function is expected to be called in a callback by the random
    /// beacon.
    /// @param _relayEntry Beacon output.
    function __beaconCallback(uint256 _relayEntry) external onlyRandomBeacon {
        groupSelectionSeed = _relayEntry;
    }

    /// @notice Gets a fee estimate for a new random entry.
    /// @return Uint256 estimate.
    function newEntryFeeEstimate() public view returns (uint256) {
        return randomBeacon.entryFeeEstimate(callbackGas);
    }

    /// @notice Calculates the fee requestor has to pay to reseed the factory
    /// for signer selection. Depending on how much value is stored in the
    /// reseed pool and the price of a new relay entry, returned value may vary.
    function newGroupSelectionSeedFee() public view returns (uint256) {
        uint256 beaconFee = randomBeacon.entryFeeEstimate(callbackGas);
        return beaconFee <= reseedPool ? 0 : beaconFee.sub(reseedPool);
    }

    /// @notice Reseeds the value used for a signer selection. Requires enough
    /// payment to be passed. The required payment can be calculated using
    /// reseedFee function. Factory is automatically triggering reseeding after
    /// opening a new keep but the reseed can be also triggered at any moment
    /// using this function.
    function requestNewGroupSelectionSeed() public payable nonReentrant {
        reseedPool = reseedPool.add(msg.value);

        uint256 beaconFee = randomBeacon.entryFeeEstimate(callbackGas);
        require(reseedPool >= beaconFee, "Not enough funds to trigger reseed");
        reseedPool = reseedPool.sub(beaconFee);

        (bool success, bytes memory returnData) = requestRelayEntry(beaconFee);
        if (!success) {
            revert(string(returnData));
        }
    }

    /// @notice Updates group selection seed.
    /// @dev The main goal of this function is to request the random beacon to
    /// generate a new random number. The beacon generates the number asynchronously
    /// and will call a callback function when the number is ready. In the meantime
    /// we update current group selection seed to a new value using a hash function.
    /// In case of the random beacon request failure this function won't revert
    /// but add beacon payment to factory's reseed pool.
    function newGroupSelectionSeed() internal {
        // Calculate new group selection seed based on the current seed.
        // We added address of the factory as a key to calculate value different
        // than sortition pool RNG will, so we don't end up selecting almost
        // identical group.
        groupSelectionSeed = uint256(
            keccak256(abi.encodePacked(groupSelectionSeed, address(this)))
        );

        // Call the random beacon to get a random group selection seed.
        (bool success, ) = requestRelayEntry(msg.value);
        if (!success) {
            reseedPool += msg.value;
        }
    }

    /// @notice Requests for a relay entry using the beacon payment provided as
    /// the parameter.
    function requestRelayEntry(uint256 payment)
        internal
        returns (bool, bytes memory)
    {
        return
            address(randomBeacon).call.value(payment)(
                abi.encodeWithSignature(
                    "requestRelayEntry(address,uint256)",
                    address(this),
                    callbackGas
                )
            );
    }

    /// @notice Checks if the caller is the random beacon.
    /// @dev Throws an error if called by any account other than the random beacon.
    modifier onlyRandomBeacon() {
        require(
            address(randomBeacon) == msg.sender,
            "Caller is not the random beacon"
        );
        _;
    }
}
