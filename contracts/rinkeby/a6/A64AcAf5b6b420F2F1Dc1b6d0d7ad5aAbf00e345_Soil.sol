pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Common/Upgradable.sol";
import "./Common/Random.sol";
import "./Common/SafeMath8.sol";
import "./Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract Soil 
// ----------------------------------------------------------------------------

contract Soil is Upgradable {
    using SafeMath8 for uint8;
    using SafeMath256 for uint256;
    Random random;
    uint256[2] seeds;
    uint256 lastBlockNumber;
    bool isFull;
    mapping (uint256 => bool) public inSoil;

    function add(
        uint256 _id
    ) external onlyFarmer returns (
        bool isSprouted,
        uint256 sproutedId,
        uint256 randomForSeedOpening
    ) {
        require(!inSoil[_id], "seed is already in soil");
        require(block.number > lastBlockNumber, "only 1 seed in a block");
        lastBlockNumber = block.number;
        inSoil[_id] = true;

        if (isFull) {
            isSprouted = true;
            sproutedId = seeds[0];
            randomForSeedOpening = random.random(2**256 - 1);
            seeds[0] = seeds[1];
            seeds[1] = _id;
            delete inSoil[sproutedId];
        } else {
            uint8 _index = seeds[0] == 0 ? 0 : 1;
            seeds[_index] = _id;
            if (_index == 1) {
                isFull = true;
            }
        }
    }

    function getSeeds() external view returns (uint256[2]) {
        return seeds;
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        random = Random(_newDependencies[0]);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Controllable.sol";

// ----------------------------------------------------------------------------
// --- Contract Upgradable 
// ----------------------------------------------------------------------------

contract Upgradable is Controllable {
    address[] internalDependencies;
    address[] externalDependencies;

    function getInternalDependencies() public view returns(address[]) {
        return internalDependencies;
    }

    function getExternalDependencies() public view returns(address[]) {
        return externalDependencies;
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        for (uint256 i = 0; i < _newDependencies.length; i++) {
            _validateAddress(_newDependencies[i]);
        }
        internalDependencies = _newDependencies;
    }

    function setExternalDependencies(address[] _newDependencies) public onlyOwner {
        _setFarmers(externalDependencies, false); 
        externalDependencies = _newDependencies;
        _setFarmers(_newDependencies, true);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./SafeMath256.sol";
import "./SafeConvert.sol";
import "./Upgradable.sol";

// ----------------------------------------------------------------------------
// --- Contract Random 
// ----------------------------------------------------------------------------

contract Random is Upgradable {
    using SafeMath256 for uint256;
    using SafeConvert for uint256;

    function _safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b > a ? 0 : a.sub(b);
    }

    modifier validBlock(uint256 _blockNumber) {
        require(
            _blockNumber < block.number &&
            _blockNumber >= _safeSub(block.number, 256),
            "not valid block number"
        );
        _;
    }

    function getRandom(
        uint256 _upper,
        uint256 _blockNumber
    ) internal view validBlock(_blockNumber) returns (uint256) {
        bytes32 _hash = keccak256(abi.encodePacked(blockhash(_blockNumber), now)); 
        return uint256(_hash) % _upper;
    }

    function random(uint256 _upper) external view returns (uint256) {
        return getRandom(_upper, block.number.sub(1));
    }

    function randomOfBlock(
        uint256 _upper,
        uint256 _blockNumber
    ) external view returns (uint256) {
        return getRandom(_upper, _blockNumber);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath8 {

    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        return a / b;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint8 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath256 {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint256 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Ownable.sol";

// ----------------------------------------------------------------------------
// --- Contract Controllable 
// ----------------------------------------------------------------------------

contract Controllable is Ownable {
    mapping(address => bool) farmers;

    modifier onlyFarmer {
        require(_isFarmer(msg.sender), "no farmer rights");
        _;
    }

    function _isFarmer(address _farmer) internal view returns (bool) {
        return farmers[_farmer];
    }

    function _setFarmers(address[] _farmers, bool _active) internal {
        for (uint256 i = 0; i < _farmers.length; i++) {
            _validateAddress(_farmers[i]);
            farmers[_farmers[i]] = _active;
        }
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract Ownable 
// ----------------------------------------------------------------------------

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not a contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _validateAddress(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeConvert {

    function toUint8(uint256 _value) internal pure returns (uint8) {
        assert(_value <= 255);
        return uint8(_value);
    }

    function toUint16(uint256 _value) internal pure returns (uint16) {
        assert(_value <= 2**16 - 1);
        return uint16(_value);
    }

    function toUint32(uint256 _value) internal pure returns (uint32) {
        assert(_value <= 2**32 - 1);
        return uint32(_value);
    }
}