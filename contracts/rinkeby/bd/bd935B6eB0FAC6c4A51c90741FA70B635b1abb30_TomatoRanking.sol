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

import "../Common/Upgradable.sol";
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoRanking 
// ----------------------------------------------------------------------------

contract TomatoRanking is Upgradable {
    using SafeMath256 for uint256;

    struct Ranking {
        uint256 id;
        uint32 rarity;
    }

    Ranking[10] ranking;

    uint256 constant REWARDED_TOMATOS_AMOUNT = 10;
    uint256 constant DISTRIBUTING_FRACTION_OF_REMAINING_BEAN = 10000;
    uint256 rewardPeriod = 24 hours;
    uint256 lastRewardDate;

    constructor() public {
        lastRewardDate = now; 
    }

    function update(uint256 _id, uint32 _rarity) external onlyFarmer {
        uint256 _index;
        bool _isIndex;
        uint256 _existingIndex;
        bool _isExistingIndex;

        if (_rarity > ranking[ranking.length.sub(1)].rarity) {

            for (uint256 i = 0; i < ranking.length; i = i.add(1)) {
                if (_rarity > ranking[i].rarity && !_isIndex) {
                    _index = i;
                    _isIndex = true;
                }
                if (ranking[i].id == _id && !_isExistingIndex) {
                    _existingIndex = i;
                    _isExistingIndex = true;
                }
                if(_isIndex && _isExistingIndex) break;
            }
            if (_isExistingIndex && _index >= _existingIndex) {
                ranking[_existingIndex] = Ranking(_id, _rarity);
            } else if (_isIndex) {
                _add(_index, _existingIndex, _isExistingIndex, _id, _rarity);
            }
        }
    }

    function _add(
        uint256 _index,
        uint256 _existingIndex,
        bool _isExistingIndex,
        uint256 _id,
        uint32 _rarity
    ) internal {
        uint256 _length = ranking.length;
        uint256 _indexTo = _isExistingIndex ? _existingIndex : _length.sub(1);
        for (uint256 i = _indexTo; i > _index; i = i.sub(1)){
            ranking[i] = ranking[i.sub(1)];
        }

        ranking[_index] = Ranking(_id, _rarity);
    }

    function getTomatosFromRanking() external view returns (uint256[10] result) {
        for (uint256 i = 0; i < ranking.length; i = i.add(1)) {
            result[i] = ranking[i].id;
        }
    }

    function updateRewardTime() external onlyFarmer {
        require(lastRewardDate.add(rewardPeriod) < now, "too early"); 
        lastRewardDate = now; 
    }

    function getRewards(uint256 _remainingBean) external view returns (uint256[10] rewards) {
        for (uint8 i = 0; i < REWARDED_TOMATOS_AMOUNT; i++) {
            rewards[i] = _remainingBean.mul(uint256(2).pow(REWARDED_TOMATOS_AMOUNT.sub(1))).div(
                DISTRIBUTING_FRACTION_OF_REMAINING_BEAN.mul((uint256(2).pow(REWARDED_TOMATOS_AMOUNT)).sub(1)).mul(uint256(2).pow(i))
            );
        }
    }

    function getDate() external view returns (uint256, uint256) {
        return (lastRewardDate, rewardPeriod);
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