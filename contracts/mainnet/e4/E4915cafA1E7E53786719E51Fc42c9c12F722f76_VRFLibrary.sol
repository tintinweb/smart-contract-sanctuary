// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomnessProvider {
    function newRandomnessRequest() external returns (bytes32);

    function updateFee(uint256) external;

    function rescueLINK(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IRandomnessProvider.sol';

library VRFLibrary {
    struct VRFData {
        IRandomnessProvider randomnessProvider;
        bytes32 lastRequestId;
        mapping(uint256 => uint256) highestIdForRandomness;
        mapping(uint256 => uint256) randomResults;
        uint256 lastRequest;
        uint256 minResultIndex;
        uint256 resultsReceived;
    }

    modifier onlyRandomnessProvider(VRFData storage self) {
        require(
            msg.sender == address(self.randomnessProvider),
            'Required to be randomnessProvider'
        );
        _;
    }

    function processingStats(
        VRFData storage self,
        uint256 maxId,
        uint256 processedId,
        uint256 interval
    )
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        timeTellNextRandomnessRequest = self.lastRequest + interval < block.timestamp
                ? 0
                : (self.lastRequest + interval) - block.timestamp;

        return (
            self.lastRequestId != '' && timeTellNextRandomnessRequest > interval / 2,
            self.highestIdForRandomness[self.resultsReceived],
            self.highestIdForRandomness[self.resultsReceived] - processedId,
            maxId - self.highestIdForRandomness[self.resultsReceived],
            timeTellNextRandomnessRequest
        );
    }

    function checkRandomness(
        VRFData storage self,
        uint256 maxId,
        uint256 processedId,
        uint256 interval,
        uint256 needed,
        uint256 minimum
    ) external {
        (
            bool requested,
            ,
            ,
            uint256 processingNeeded,
            uint256 timeTellNext
        ) = processingStats(self, maxId, processedId, interval);

        if (
            !requested &&
            (processingNeeded >= needed ||
                (timeTellNext == 0 && processingNeeded > minimum))
        ) {
            newRequest(self);
        }
    }

    function newRequest(VRFData storage self) public {
        bytes32 requestId = self.randomnessProvider.newRandomnessRequest();

        if (requestId != '') {
            self.lastRequest = block.timestamp;
            self.lastRequestId = requestId;
        }
    }

    function setRequestResults(
        VRFData storage self,
        bytes32 requestId,
        uint256 randomness,
        uint256 maxId
    ) public onlyRandomnessProvider(self) {
        if (self.lastRequestId == requestId) {
            self.resultsReceived++;
            self.randomResults[self.resultsReceived] = randomness;
            self.highestIdForRandomness[self.resultsReceived] = maxId;
            self.lastRequestId = '';
        }
    }

    function randomnessForId(VRFData storage self, uint256 id)
        public
        returns (bool available, uint256 randomness)
    {
        while (
            self.highestIdForRandomness[self.minResultIndex] < id &&
            self.minResultIndex < self.resultsReceived
        ) {
            delete self.randomResults[self.minResultIndex];
            delete self.highestIdForRandomness[self.minResultIndex];
            self.minResultIndex++;
        }

        if (self.highestIdForRandomness[self.minResultIndex] >= id) {
            return (true, self.randomResults[self.minResultIndex]);
        }

        return (false, 0);
    }

    function setRandomnessProvider(
        VRFData storage self,
        address randomnessProvider
    ) public {
        self.randomnessProvider = IRandomnessProvider(randomnessProvider);
    }

    function updateFee(VRFData storage self, uint256 fee) public {
        self.randomnessProvider.updateFee(fee);
    }

    function rescueLINK(
        VRFData storage self,
        address to,
        uint256 amount
    ) public {
        self.randomnessProvider.rescueLINK(to, amount);
    }
}