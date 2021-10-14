//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IPepitoAddressesProvider} from './interfaces/IPepitoAddressesProvider.sol';

contract Pepito {
    IPepitoAddressesProvider internal _addressesProvider;

    constructor(IPepitoAddressesProvider provider) {
        _addressesProvider = provider;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPepitoAddressesProvider {
  function setOracle(address oracle) external;
}