// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../MetaCoin.sol";
import "../interfaces/IMetaCoin.sol";

contract MetaCoinFactory {
    MetaCoin[] public metaCoinAddresses;
    event MetaCoinCreated(MetaCoin metaCoin);

    address private metaCoinOwner;

    constructor(address _metaCoinOwner ) public {
        metaCoinOwner = _metaCoinOwner ;
    }

    function createMetaCoin(uint256 initialBalance) external {
        MetaCoin metaCoin = new MetaCoin(metaCoinOwner, initialBalance);

        metaCoinAddresses.push(metaCoin);
        emit MetaCoinCreated(metaCoin);
    }

    function getMetaCoins() external view returns (MetaCoin[] memory) {
        return metaCoinAddresses;
    }

    function changeBalance(address metaCoinAddress, uint256 balance) external {
        IMetaCoin(metaCoinAddress).changeBalance(balance);
    }

    function getBalance(address metaCoinAddress) external view returns (uint256){
        return IMetaCoin(metaCoinAddress).getBalance();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMetaCoin.sol";

contract MetaCoin is IMetaCoin {
    address _owner;
    uint256 _totalBalance;
    constructor (
        address owner,
        uint256 balance
    )  {
        _owner = owner;
        _totalBalance = balance;
    }


    function changeBalance(uint256 balance) external override {
        _totalBalance = balance;
    }

    function getBalance() external override view returns (uint256) {
        return _totalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaCoin {
    function changeBalance(uint256) external;
    function getBalance() external view returns (uint256);
}