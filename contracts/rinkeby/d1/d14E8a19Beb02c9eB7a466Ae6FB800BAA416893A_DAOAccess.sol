pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "./interfaces/IDAOAccess.sol";

contract DAOAccess is IDAOAccess {
    // Address of setter
    address guardian;

    // Array of admins (Top 100)
    address[100] public admins;

    // Array of DDFs
    mapping(uint256 => address[10]) DDFs;

    // DDF checkpoint (prevents new DDF members on voting on things before their membership)
    struct DDFCheckpoint {
        uint256 fromBlock;
        // using DDFs mapping to get the array.
    }
    mapping(uint256 => DDFCheckpoint) DDFCheckpoints;
    uint32 numDDFCheckpoints;

    /**
     * Initalize contract with new DDF and admins
     */
    constructor(address _guardian) {
        guardian = _guardian;
    }

    /**
     * Returns whether sender is a guardian or not. Used externally for Access Control.
     */
    function isGuardian(address sender) public view override returns (bool) {
        return sender == guardian;
    }

    /**
     * Returns whether sender is a DDF member or not. Used externally for Access Control.
     */
    function isDDF(address sender, uint256 blockNumber)
        public
        view
        override
        returns (bool)
    {
        return _isDDFByBlock(sender, blockNumber);
    }

    /**
     * Returns whether sender is an Admin or not. Used externally for Access Control.
     */
    function isAdmin(address sender) public view override returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == sender) {
                return true;
            }
        }
        return false;
    }

    /**
     * Modifier for restricting to only guardian
     */
    modifier onlyGuardian() {
        require(isGuardian(msg.sender), "Needs Guardian permissions");
        _;
    }

    /**
     * Sets the new DDF (Top 10 xASKO holders).
     */
    function setDDF(address[10] memory newDDF) public onlyGuardian {
        numDDFCheckpoints++;
        DDFCheckpoints[numDDFCheckpoints - 1].fromBlock = block.number;
        for (uint256 i = 0; i < newDDF.length; i++){
            DDFs[numDDFCheckpoints - 1][i] = newDDF[i];
        }
    }

    /**
     * Sets new admins (Top 100 xASKO holders).
     */
    function setAdmins(address[100] memory newAdmins) public onlyGuardian {
        admins = newAdmins;
    }

    function _isDDFByBlock(address sender, uint256 blockNumber) internal view returns (bool) {
        require(blockNumber < block.number, "DDF not determined.");
        require(numDDFCheckpoints > 0, "DDF does not exist.");
        require(
            DDFCheckpoints[0].fromBlock <= blockNumber,
            "DDF does not exist."
        );

        address[10] memory desiredDDF;

        // check the most recent balance
        if (DDFCheckpoints[numDDFCheckpoints - 1].fromBlock <= blockNumber) {
            desiredDDF = DDFs[DDFCheckpoints[numDDFCheckpoints - 1].fromBlock];
        }

        // binary search to get the desired checkpoint
        uint32 lower = 0;
        uint32 upper = numDDFCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DDFCheckpoint memory ddfCp = DDFCheckpoints[center];
            if (ddfCp.fromBlock == blockNumber) {
                desiredDDF = DDFs[center];
                break;
            } else if (ddfCp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        // if it breaks the while loop
        if (upper <= lower) {
            desiredDDF = DDFs[lower];
        }

        // linear search to see if it's a DDF member
        for (uint256 i = 0; i < desiredDDF.length; i++) {
            if (desiredDDF[i] == sender) {
                return true;
            }
        }
        return false;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

interface IDAOAccess {

    function isGuardian(address sender) external view returns (bool);

    function isDDF(address sender, uint256 blockNumber) external view returns (bool);

    function isAdmin(address sender) external view returns (bool);

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}