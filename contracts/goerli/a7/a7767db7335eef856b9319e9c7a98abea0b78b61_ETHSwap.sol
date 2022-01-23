/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: BlueOak-1.0.0
// pragma should be as specific as possible to allow easier validation.
pragma solidity = 0.8.6;

// ETHSwap creates a contract to be deployed on an ethereum network. After
// deployed, it keeps a map of swaps that facilitates atomic swapping of
// ethereum with other crypto currencies that support time locks.
//
// It accomplishes this by holding funds sent to this contract until certain
// conditions are met. An initiator sends an amount of funds along with byte
// code that tells the contract to insert a swap struct into the public map. At
// this point the funds belong to the contract, and cannot be accessed by
// anyone else, not even the contract's deployer. The initiator sets a
// participant, a secret hash, a blocktime the funds will be accessible should
// they not be redeemed, and a participant who can redeem before or after the
// locktime. The participant can redeem at any time after the initiation
// transaction is mined if they have the secret that hashes to the secret hash.
// Otherwise, the initiator can refund funds any time after the locktime.
//
// This contract has no limits on gas used for any transactions.
//
// This contract cannot be used by other contracts or by a third party mediating
// the swap or multisig wallets.
//
// This code should be verifiable as resulting in a certain on-chain contract
// by compiling with the correct version of solidity and comparing the
// resulting byte code to the data in the original transaction.
contract ETHSwap {
    // State is a type that hold's a contract's state. Empty is the uninitiated
    // or null value.
    enum State { Empty, Filled, Redeemed, Refunded }

    // Swap holds information related to one side of a single swap. The order of
    // the struct fields is important to efficiently pack the struct into as few
    // 256-bit slots as possible to reduce gas cost. In particular, the 160-bit
    // address can pack with the 8-bit State.
    struct Swap {
        bytes32 secret;
        uint256 value;
        uint initBlockNumber;
        uint refundBlockTimestamp;
        address initiator;
        address participant;
        State state;
    }

    // swaps is a map of swap secret hashes to swaps. It can be read by anyone
    // for free.
    mapping(bytes32 => Swap) public swaps;

    // constructor is empty. This contract has no connection to the original
    // sender after deployed. It can only be interacted with by users
    // initiating, redeeming, and refunding swaps.
    constructor() {}

    // isRefundable checks that a swap can be refunded. The requirements are
    // the initiator is msg.sender, the state is Filled, and the block
    // timestamp be after the swap's stored refundBlockTimestamp.
    function isRefundable(bytes32 secretHash) public view returns (bool) {
        Swap storage swapToCheck = swaps[secretHash];
        return swapToCheck.state == State.Filled &&
               swapToCheck.initiator == msg.sender &&
               block.timestamp >= swapToCheck.refundBlockTimestamp;
    }

    // senderIsOrigin ensures that this contract cannot be used by other
    // contracts, which reduces possible attack vectors.
    modifier senderIsOrigin() {
        require(tx.origin == msg.sender, "sender != origin");
        _;
    }

    // swap returns a single swap from the swaps map.
    function swap(bytes32 secretHash)
        public view returns(Swap memory)
    {
        return swaps[secretHash];
    }

    struct Initiation {
        uint refundTimestamp;
        bytes32 secretHash;
        address participant;
        uint value;
    }

    // initiate initiates an array of swaps. It checks that all of the
    // swaps have a non zero redemptionTimestamp and value, and that none of
    // the secret hashes have ever been used previously. The function also makes
    // sure that msg.value is equal to the sum of the values of all the swaps.
    // Once initiated, each swap's state is set to Filled. The msg.value is now
    // in the custody of the contract and can only be retrieved through redeem
    // or refund.
    function initiate(Initiation[] calldata initiations)
        public
        payable
        senderIsOrigin()
    {
        uint initVal = 0;
        for (uint i = 0; i < initiations.length; i++) {
            Initiation calldata initiation = initiations[i];
            Swap storage swapToUpdate = swaps[initiation.secretHash];

            require(initiation.value > 0, "0 val");
            require(initiation.refundTimestamp > 0, "0 refundTimestamp");
            require(swapToUpdate.state == State.Empty, "dup swap");

            swapToUpdate.initBlockNumber = block.number;
            swapToUpdate.refundBlockTimestamp = initiation.refundTimestamp;
            swapToUpdate.initiator = msg.sender;
            swapToUpdate.participant = initiation.participant;
            swapToUpdate.value = initiation.value;
            swapToUpdate.state = State.Filled;

            initVal += initiation.value;
        }

        require(initVal == msg.value, "bad val");
    }

    struct Redemption {
        bytes32 secret;
        bytes32 secretHash;
    }

    // isRedeemable returns whether or not a swap identified by secretHash
    // can be redeemed using secret.
    function isRedeemable(bytes32 secretHash, bytes32 secret)
        public
        view
        returns (bool)
    {
        return swaps[secretHash].state == State.Filled &&
               swaps[secretHash].participant == msg.sender &&
               sha256(abi.encodePacked(secret)) == secretHash;
    }

    // redeem redeems a contract. It checks that the sender is not a contract,
    // and that the secret hash hashes to secretHash. msg.value is tranfered
    // from the contract to the sender.
    //
    // It is important to note that this uses call.value which comes with no
    // restrictions on gas used. This has the potential to open the contract up
    // to a reentry attack. A reentry attack inserts extra code in call.value
    // that executes before the function returns. This is why it is very
    // important to check the state of the contract first, and change the state
    // before proceeding to send. That way, the nested attacking function will
    // throw upon trying to call redeem a second time. Currently, reentry is also
    // not possible because contracts cannot use this contract.
    function redeem(Redemption[] calldata redemptions)
        public
        senderIsOrigin()
    {
        uint amountToRedeem = 0;
        for (uint i = 0; i < redemptions.length; i++) {
            Redemption calldata redemption = redemptions[i];
            Swap storage swapToRedeem = swaps[redemption.secretHash];

            require(swapToRedeem.state == State.Filled, "bad state");
            require(swapToRedeem.participant == msg.sender, "bad participant");
            require(sha256(abi.encodePacked(redemption.secret)) == redemption.secretHash,
                "bad secret");

            swapToRedeem.state = State.Redeemed;
            swapToRedeem.secret = redemption.secret;
            amountToRedeem += swapToRedeem.value;
        }

        (bool ok, ) = payable(msg.sender).call{value: amountToRedeem}("");
        require(ok == true, "transfer failed");
    }

    // refund refunds a contract. It checks that the sender is not a contract,
    // and that the refund time has passed. msg.value is tranfered from the
    // contract to the sender.
    //
    // It is important to note that this also uses call.value which comes with no
    // restrictions on gas used. See redeem for more info.
    function refund(bytes32 secretHash)
        public
        senderIsOrigin()
    {
        require(isRefundable(secretHash), "not refundable");
        Swap storage swapToRefund = swaps[secretHash];
        swapToRefund.state = State.Refunded;
        (bool ok, ) = payable(msg.sender).call{value: swapToRefund.value}("");
        require(ok == true, "transfer failed");
    }
}