// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyMetaCoin.sol";

contract MetaCoinFactory {
    MyMetaCoin[] public metaCoinAddresses;

    event MetaCoinCreated(MyMetaCoin metaCoin);

    address private metaCoinOwner;

    constructor(address _metaCoinOwner) {
        metaCoinOwner = _metaCoinOwner;
    }

    function createMetaCoin(uint256 initialBalance) external {
        MyMetaCoin metaCoin = new MyMetaCoin(metaCoinOwner, initialBalance);

        metaCoinAddresses.push(metaCoin);
        emit MetaCoinCreated(metaCoin);
    }

    function getMetaCoins() external view returns (MyMetaCoin[] memory) {
        return metaCoinAddresses;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyMetaCoin {
    uint256 private initialBalance;
    address private owner;

    constructor(address _owner, uint256 _initialBalance) {
        owner = _owner;
        initialBalance = _initialBalance;
    }

    function getBalance() public view returns (uint256) {
        return initialBalance;
    }

    function setBalance(uint256 _initialBalance) public {
        initialBalance = _initialBalance;
    }
}