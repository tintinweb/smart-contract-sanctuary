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
import "./Common/SafeMath256.sol";
import "./Common/SafeConvert.sol";

// ----------------------------------------------------------------------------
// --- Contract Harvest 
// ----------------------------------------------------------------------------

contract Harvest is Upgradable {
    using SafeMath256 for uint256;
    using SafeConvert for uint256;

    uint256 restAmount;
    uint256 releasedAmount;
    uint256 lastBlock;
    uint256 interval; 

    uint256 constant NUMBER_OF_TOMATO_TYPES = 5;

    constructor() public {
        releasedAmount = 10000;
        restAmount = releasedAmount;
        lastBlock = block.number; 
        interval = 1;
    }

    function _updateInterval() internal {
        if (restAmount == 5000) {
            interval = 2;
        } else if (restAmount == 3750) {
            interval = 4;
        } else if (restAmount == 2500) {
            interval = 8;
        } else if (restAmount == 1250) {
            interval = 16;
        }
    }

    function _burnGas() internal pure {
        uint256[26950] memory _local;
        for (uint256 i = 0; i < _local.length; i++) {
            _local[i] = i;
        }
    }

    function claim(uint8 _requestedType) external onlyFarmer returns (uint256, uint256, uint256) {
        require(restAmount > 0, "seeds are over");
        require(lastBlock.add(interval) <= block.number, "too early");
        uint256 _index = releasedAmount.sub(restAmount);
        uint8 currentType = (_index % NUMBER_OF_TOMATO_TYPES).toUint8();
        require(currentType == _requestedType, "not a current type of tomato");
        lastBlock = block.number;
        restAmount = restAmount.sub(1);
        _updateInterval();
        _burnGas();
        return (restAmount, lastBlock, interval);
    }

    function getInfo() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            restAmount,
            releasedAmount,
            lastBlock,
            interval,
            NUMBER_OF_TOMATO_TYPES
        );
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