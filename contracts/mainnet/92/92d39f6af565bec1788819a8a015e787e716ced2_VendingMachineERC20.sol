pragma solidity ^0.5.2;

import "./IFactRegistry.sol";
import "./IERC20.sol";
import "./PublicInputOffsets.sol";
/**
  VeeDo is a STARK-based Verifiable Delay Function (VDF) service. VeeDo works in the "Vending
  Machine model" - users can pay in advance for a randomness request, knowing that either the
  request will be served, or they will be able to get their payment back.
  User make a request by calling `addPayment(seed, n_iter)` where seed is used to generate the
  VDF input and n_iter is the number of iterations.
  An off-chain service picks up the request, computes the randomness and generates a proof
  attesting to the validity of the computation. The proof is then sent to the STARK prover. If the
  Verifier accepts the corresponding proof, `registerAndCollect()` allows the off-chain service to
  register the randomness and receive the payment.
  In case a request was not served, the user can reclaim their payment through `reclaimPayment()`
  after RECLAIM_DELAY has passed.
*/
contract VendingMachineERC20 is PublicInputOffsets {


    // Emitted by addPayment() when a user makes a payment for a randomness.
    event LogNewPayment(uint256 seed, uint256 n_iter, uint256 paymentAmount);
    // Emitted by reclaimPayment() when a user reclaims a payment they made.
    event LogPaymentReclaimed(
        address sender,
        uint256 seed,
        uint256 n_iter,
        uint256 tag,
        uint256 reclaimedAmount
    );
    // Emitted by registerAndCollect() when a new randomness is registered.
    event LogNewRandomness(uint256 seed, uint256 n_iter, bytes32 randomness);

    struct Payment {
        // The last time a user sent a payment for given (sender, seed, n_iter, tag).
        uint256 timeSent;
        // The sum of those payments.
        uint256 amount;
    }

    // Mapping: (seed, n_iters) -> total_amount.
    // Represents prize amount for VDF(seed, n_iter) solver.
    // prizes(seed, n_iter) is always equal to the sum of
    // payments(sender, seed, n_iters, tag) over all 'sender' and 'tag'.
    mapping(uint256 => mapping(uint256 => uint256)) public prizes;
    // Mapping: (sender, seed, n_iters, tag) -> Payment.
    // Information to support reclaiming of payments.
    // 'tag' is used to allow a wrapper contract to distinguish between different users.
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => Payment))))
        public payments;
    // Mapping: (seed, n_iters) -> randomness.
    mapping(uint256 => mapping(uint256 => bytes32)) public registeredRandomness;
    // Mapping: address -> isOwner.
    mapping(address => bool) owners;

    // The Verifier contracts verifies the proof of the VDF.
    IFactRegistry public verifierContract;
    // The address of ERC20 tokens being accepted as payments.
    address public tokenAddress;
    uint256 internal constant PRIME = 0x30000003000000010000000000000001;
    uint256 internal constant PUBLIC_INPUT_SIZE = 5;
    uint256 internal constant RECLAIM_DELAY = 1 days;

    // Modifiers.
    modifier onlyOwner {
        require(owners[msg.sender], "ONLY_OWNER");
        _;
    }

    modifier randomnessNotRegistered(uint256 seed, uint256 n_iter) {
        require(
            registeredRandomness[seed][n_iter] == 0,
            "REGSITERED_RANDOMNESS"
        );
        _;
    }

    constructor(address verifierAddress, address token) public {
        owners[msg.sender] = true;
        verifierContract = IFactRegistry(verifierAddress);
        tokenAddress = token;
    }

    function addOwner(address newOwner) external onlyOwner {
        owners[newOwner] = true;
    }

    function removeOwner(address removedOwner) external onlyOwner {
        require(msg.sender != removedOwner, "CANT_REMOVE_SELF");
        owners[removedOwner] = false;
    }

    /*
      Adds a payment from msg.sender, and updates timeSent to 'now'.
      Note - the sender must make an allowance first.
    */
    function addPayment(
        uint256 seed,
        uint256 n_iter,
        uint256 tag,
        uint256 paymentAmount
    ) external randomnessNotRegistered(seed, n_iter) {
        // Sends the payment from the user to the contract.
        transferIn(paymentAmount);

        // Updates mapping.
        payments[msg.sender][seed][n_iter][tag].amount += paymentAmount;
        payments[msg.sender][seed][n_iter][tag].timeSent = now;
        prizes[seed][n_iter] += paymentAmount;

        emit LogNewPayment(seed, n_iter, paymentAmount);
    }

    /*
      Allows a user to reclaim their payment if it was not already served and RECLAIM_DELAY has
      passed since the last payment.
    */
    function reclaimPayment(
        uint256 seed,
        uint256 n_iter,
        uint256 tag
    ) external randomnessNotRegistered(seed, n_iter) {
        Payment memory userPayment = payments[msg.sender][seed][n_iter][tag];

        // Make sure a payment is available to reclaim.
        require(userPayment.amount > 0, "NO_PAYMENT");

        // Make sure enough time has passed.
        uint256 lastPaymentTime = userPayment.timeSent;
        uint256 releaseTime = lastPaymentTime + RECLAIM_DELAY;
        assert(releaseTime >= RECLAIM_DELAY);
        // solium-disable-next-line security/no-block-members
        require(now >= releaseTime, "PAYMENT_LOCKED");

        // Deduct reclaimed payment from mappings.
        prizes[seed][n_iter] -= userPayment.amount;
        payments[msg.sender][seed][n_iter][tag].amount = 0;

        // Send the payment back to the user.
        transferOut(userPayment.amount);

        emit LogPaymentReclaimed(
            msg.sender,
            seed,
            n_iter,
            tag,
            userPayment.amount
        );
    }

    function registerAndCollect(
        uint256 seed,
        uint256 n_iter,
        uint256 vdfOutputX,
        uint256 vdfOutputY
    ) external onlyOwner randomnessNotRegistered(seed, n_iter) {
        registerNewRandomness(seed, n_iter, vdfOutputX, vdfOutputY);
        transferOut(prizes[seed][n_iter]);
    }

    /*
      Registers a new randomness if vdfOutputX and vdfOutputY are valid field elements and the
      fact (n_iter, vdfInputX, vdfInputY, vdfOutputX, vdfOutputY) is valid fact in the Verifier.
    */
    function registerNewRandomness(
        uint256 seed,
        uint256 n_iter,
        uint256 vdfOutputX,
        uint256 vdfOutputY
    ) internal {
        require(vdfOutputX < PRIME && vdfOutputY < PRIME, "INVALID_VDF_OUTPUT");

        (uint256 vdfInputX, uint256 vdfInputY) = seed2vdfInput(seed);

        uint256[PUBLIC_INPUT_SIZE] memory proofPublicInput;
        proofPublicInput[OFFSET_N_ITER] = n_iter;
        proofPublicInput[OFFSET_VDF_INPUT_X] = vdfInputX;
        proofPublicInput[OFFSET_VDF_INPUT_Y] = vdfInputY;
        proofPublicInput[OFFSET_VDF_OUTPUT_X] = vdfOutputX;
        proofPublicInput[OFFSET_VDF_OUTPUT_Y] = vdfOutputY;

        require(
            verifierContract.isValid(
                keccak256(abi.encodePacked(proofPublicInput))
            ),
            "FACT_NOT_REGISTERED"
        );

        // The randomness is the hash of the VDF output and the string "veedo".
        bytes32 randomness = keccak256(
            abi.encodePacked(
                proofPublicInput[OFFSET_VDF_OUTPUT_X],
                proofPublicInput[OFFSET_VDF_OUTPUT_Y],
                "veedo"
            )
        );
        registeredRandomness[seed][n_iter] = randomness;

        emit LogNewRandomness(seed, n_iter, randomness);
    }

    /*
      Transfers funds from the contract to msg.sender.
    */
    function transferOut(uint256 amount) internal {
        safeERC20Call(
            address(tokenAddress),
            abi.encodeWithSelector(
                IERC20(0).transfer.selector,
                msg.sender,
                amount
            )
        );
    }

    /*
      Transfers funds from msg.sender to the contract.
    */
    function transferIn(uint256 amount) internal {
        safeERC20Call(
            address(tokenAddress),
            abi.encodeWithSelector(
                IERC20(0).transferFrom.selector,
                msg.sender,
                address(this),
                amount
            )
        );
    }

    /*
      Safe wrapper around ERC20 calls.
      This is required because many deployed ERC20 contracts don't return a value.
      See https://github.com/ethereum/solidity/issues/4116.
    */
    function safeERC20Call(address tokenAddress, bytes memory callData)
        internal
    {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returndata) = address(tokenAddress).call(
            callData
        );
        require(success, string(returndata));

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "ERC20_OPERATION_FAILED");
        }
    }

    /*
      Generates VDF inputs from seed.
    */
    function seed2vdfInput(uint256 seed)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 vdfInput = uint256(keccak256(abi.encodePacked(seed, "veedo")));
        uint256 vdfInputX = vdfInput & ((1 << 125) - 1);
        uint256 vdfInputY = ((vdfInput >> 125) & ((1 << 125) - 1));
        return (vdfInputX, vdfInputY);
    }
}
