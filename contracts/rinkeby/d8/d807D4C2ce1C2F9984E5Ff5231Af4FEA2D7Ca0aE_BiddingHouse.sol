//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

contract BiddingHouse {
    struct Nft {
        address contractAdr;
        uint256 id;
    }

    struct Bid {
        uint256 value;
        address sender;
        Nft nft;
    }

    event BidPlaced(Bid bid, uint256 slotId, uint256 indexed epochBoundary);

    uint256 public constant NUM_SLOTS = 4;
    uint256 public immutable EPOCH_INTERVAL_SECONDS;
    Bid[4] public winners;
    Bid[4] public candidates;
    // Time that current epoch ends; in seconds since unix epoch
    uint256 public epochBoundary;
    address public owner;

    constructor(
        address _owner,
        uint256 startingEpochBoundary,
        uint256 epochInterval,
        Nft[4] memory initialWinners
    ) {
        owner = _owner;
        epochBoundary = startingEpochBoundary;
        EPOCH_INTERVAL_SECONDS = epochInterval;
        for (uint256 i = 0; i < initialWinners.length; i++) {
            winners[i] = Bid({value: 0, sender: owner, nft: initialWinners[i]});
        }
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function sweep() public {
        require(msg.sender == owner);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    function placeBid(uint256 slotId, Nft calldata nft) public payable {
        require(slotId < NUM_SLOTS);
        tryUpdateEpoch();
        assert(!isCurrentEpochOver());

        uint256 previousFrontrunnerVal = candidates[slotId].value;
        require(previousFrontrunnerVal < msg.value);
        address previousFrontrunnerAdr = candidates[slotId].sender;
        candidates[slotId] = Bid({
            value: msg.value,
            sender: msg.sender,
            nft: nft
        });
        // We don't require this transfer to succeed, otherwise malicious
        // contracts could buy bid spots and throw whenever we attempt to
        // refund them.
        previousFrontrunnerAdr.call{value: previousFrontrunnerVal}("");
        emit BidPlaced(candidates[slotId], slotId, epochBoundary);
    }

    function tryUpdateEpoch() public {
        uint256 calculatedBoundary = getEpochBoundary();
        if (epochBoundary != calculatedBoundary) {
            for (uint256 i = 0; i < NUM_SLOTS; i++) {
                if (candidates[i].value > 0) {
                    winners[i] = candidates[i];
                    delete candidates[i];
                }
            }
            epochBoundary = calculatedBoundary;
        }
    }

    function isCurrentEpochOver() public view returns (bool) {
        return block.timestamp > epochBoundary;
    }

    function getWinners() public view returns (Bid[4] memory) {
        if (!isCurrentEpochOver()) {
            return winners;
        }
        Bid[4] memory _winners;
        for (uint256 i = 0; i < NUM_SLOTS; i++) {
            _winners[i] = candidates[i].value > 0 ? candidates[i] : winners[i];
        }
        return _winners;
    }

    function getCandidates() public view returns (Bid[4] memory _candidates) {
        if (!isCurrentEpochOver()) {
            _candidates = candidates;
        }
    }

    function getEpochBoundary() public view returns (uint256 boundary) {
        if (!isCurrentEpochOver()) {
            return epochBoundary;
        }
        uint256 epochsBehind = (block.timestamp - epochBoundary) /
            EPOCH_INTERVAL_SECONDS;
        uint256 secToGetAhead = (epochsBehind + 1) * EPOCH_INTERVAL_SECONDS;
        return epochBoundary + secToGetAhead;
    }
}

