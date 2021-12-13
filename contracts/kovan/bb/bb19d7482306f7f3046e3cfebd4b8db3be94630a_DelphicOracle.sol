// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

import "./Common.sol";

contract DelphicOracle is Ownable {
    struct Oracle {
        uint256 index;
        string dataA;
        string dataB;
        uint256 ts;
    }

    Oracle[] public oracle;

    /**
     * @dev Pray for an oracle
     * @param _dataA encrypted data
     * @param _dataB cipher
     */
    function pray(string memory _dataA, string memory _dataB) public onlyOwner {
        oracle.push(Oracle(oracle.length, _dataA, _dataB, block.timestamp));
    }

    function latestOracle()
        public
        view
        returns (
            uint256 index,
            string memory dataA,
            string memory dataB,
            uint256 ts
        )
    {
        Oracle memory o = oracle[getLength() - 1];

        index = o.index;
        dataA = o.dataA;
        dataB = o.dataB;
        ts = o.ts;
    }

    function retrieve(uint256 _index)
        public
        view
        returns (
            uint256 index,
            string memory dataA,
            string memory dataB,
            uint256 ts
        )
    {
        Oracle memory o = oracle[_index];

        index = o.index;
        dataA = o.dataA;
        dataB = o.dataB;
        ts = o.ts;
    }

    function getLength() public view returns (uint256 length) {
        return oracle.length;
    }
}