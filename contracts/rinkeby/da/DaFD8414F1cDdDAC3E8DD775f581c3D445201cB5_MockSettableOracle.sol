/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/oracle/IOracle.sol

/*
    Copyright 2020 Cook Finance Devs, based on the works of the Cook Finance Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

abstract contract IOracle {
    function update() external virtual returns (uint256);

    function pairAddress() external view virtual returns (address);
}


// File contracts/mock/MockSettableOracle.sol

/*
    Copyright 2020 Cook Finance Devs, based on the works of the Cook Finance Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.6.2;

contract MockSettableOracle is IOracle {
    uint256 internal _price;
    address internal _pairAddress;

    constructor(address pairAddress_) public {
        _pairAddress = pairAddress_;
    }

    function set(uint256 price) external {
        _price = price;
    }

    function update() external override returns (uint256 price) {
        return _price;
    }

    function pairAddress() public view override returns (address) {
        return _pairAddress;
    }
}