//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

import "./AdminAccessible.sol";
import "./LandSaleCore.sol";


contract UserData is AdminAccesible, LandSaleCore {

    event CreditsSpent(address indexed user, uint common, uint rare, uint epic, uint premium);
    event DiscountsSpent(address indexed user, uint256[] singleDiscountIndexes, uint256[] multiDiscountIndexes);

    struct UserCredits {
        uint256 commonCredits;
        uint256 rareCredits;
        uint256 epicCredits;
        uint256 premiumCredits;
    }

    struct UserWhiteList {
        bool phase1;
        bool phase2;
        bool phase3;
    }

    struct Discount {
        uint128 discount;
        bool forCyberBiome;
        bool forSteampunkBiome;
        bool forWindBiome;
        bool forVolcanoBiome;
        bool forFireBiome;
        bool forWaterBiome;
        bool forNecroBiome;
        bool forMechaBiome;
        bool forDragonBiome;
        bool forMeadowBiome;
        bool forShore;
        bool forIsland;
        bool forMountainFoot;
        bool forAll;
    }

    struct UserDiscounts {
        Discount[] single;
        Discount[] multi;
    }

    //getter composition
    struct UserDataIntake {
        uint256 commonCredits;
        uint256 rareCredits;
        uint256 epicCredits;
        uint256 premiumCredits;
        Discount[] singleDiscounts;
        Discount[] multiDiscounts;
        bool whiteListPhase1;
        bool whiteListPhase2;
        bool whiteListPhase3;
    }

    // Credits
    mapping(address => mapping(Rarity => uint256)) private _userCredits;
    // Whitelist
    address private _landSaleAddress;
    uint256 private _lastUpdate;
    mapping(address => UserWhiteList) private _userWL;
    // Discounts
    mapping(address => Discount[]) private _userDiscountsSingle;
    mapping(address => Discount[]) private _userDiscountsMulti;

    modifier onlyLandsale {
        require(_landSaleAddress == msg.sender, "Forbidden");
        _;
    }

    function checkWhitelist(address user, uint256 whiteListPhase) external view {
        if (whiteListPhase == 0) {
            revert("Sale not open");
        }
        else if (whiteListPhase == 1) {
            require(
                _userWL[user].phase1,
                "Kokopelli: Not whitelisted"
                );
        }
        else if (whiteListPhase == 2) {
            require(
                _userWL[user].phase1 ||
                _userWL[user].phase2,
                "Kanaria: Not whitelisted"
                );
        }
        else if (whiteListPhase == 3) {
            require(
                _userWL[user].phase1 ||
                _userWL[user].phase2 ||
                _userWL[user].phase3,
                "WL: Not whitelisted");
        }
        // 4 is public, 5 is dutch, they require no whitelist
    }


    // LandSale
    function setLandSaleAddress(address landSaleAddress) external onlyOwnerOrAdmin {
        _landSaleAddress = landSaleAddress;
    }

    function getLandSaleAddress() external view returns(address) {
        return _landSaleAddress;
    }

    // Credits
    function setUserCredits(address user, uint256 commonCredits, uint256 rareCredits, uint256 epicCredits, uint256 premiumCredits) external onlyOwnerOrAdmin {
        _setUserCredits(user, commonCredits, rareCredits, epicCredits, premiumCredits);
        _setLastUpdate();
    }

    function setUserCreditsBatch(
        address[] calldata users,
        uint256[] calldata commonCredits,
        uint256[] calldata rareCredits,
        uint256[] calldata epicCredits,
        uint256[] calldata premiumCredits
    ) external onlyOwnerOrAdmin {
        uint numUsers = users.length;
        require(numUsers == commonCredits.length && numUsers == rareCredits.length && numUsers == epicCredits.length && numUsers == premiumCredits.length, "Arrays must have the same length");
        for (uint i; i<numUsers;) {
            _setUserCredits(users[i], commonCredits[i], rareCredits[i], epicCredits[i], premiumCredits[i]);
            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    function _setUserCredits(address user, uint256 commonCredits, uint256 rareCredits, uint256 epicCredits, uint256 premiumCredits) private {
        _userCredits[user][Rarity.Common] = commonCredits;
        _userCredits[user][Rarity.Rare] = rareCredits;
        _userCredits[user][Rarity.Epic] = epicCredits;
        _userCredits[user][Rarity.Premium] = premiumCredits;
    }

    function addUserCredits(address user, uint256 commonCredits, uint256 rareCredits, uint256 epicCredits, uint256 premiumCredits) external onlyOwnerOrAdmin {
        _addUserCredits(user, commonCredits, rareCredits, epicCredits, premiumCredits);
        _setLastUpdate();
    }

    function addUserCreditsBatch(
        address[] calldata users,
        uint256[] calldata commonCredits,
        uint256[] calldata rareCredits,
        uint256[] calldata epicCredits,
        uint256[] calldata premiumCredits
    ) external onlyOwnerOrAdmin {
        uint numUsers = users.length;
        require(numUsers == commonCredits.length && numUsers == rareCredits.length && numUsers == epicCredits.length && numUsers == premiumCredits.length, "Arrays must have the same length");
        for (uint i; i<numUsers;) {
            _addUserCredits(users[i], commonCredits[i], rareCredits[i], epicCredits[i], premiumCredits[i]);
            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    function _addUserCredits(address user, uint256 commonCredits, uint256 rareCredits, uint256 epicCredits, uint256 premiumCredits) internal {
        _userCredits[user][Rarity.Common] += commonCredits;
        _userCredits[user][Rarity.Rare] += rareCredits;
        _userCredits[user][Rarity.Epic] += epicCredits;
        _userCredits[user][Rarity.Premium] += premiumCredits;
    }

    function removeAllUserCredits(address user) external onlyOwnerOrAdmin {
        delete _userCredits[user][Rarity.Common];
        delete _userCredits[user][Rarity.Rare];
        delete _userCredits[user][Rarity.Epic];
        delete _userCredits[user][Rarity.Premium];
    }

    function getUserCreditData(address user) external view returns (UserCredits memory userCreditData) {
        userCreditData = UserCredits ({
            commonCredits: _userCredits[user][Rarity.Common],
            rareCredits: _userCredits[user][Rarity.Rare],
            epicCredits: _userCredits[user][Rarity.Epic],
            premiumCredits: _userCredits[user][Rarity.Premium]
        });
    }

    function getUserCreditsForRarity(address user, Rarity rarity) external view returns (uint256) {
        return _userCredits[user][rarity];
    }

    function spendCredits(address user, uint common, uint rare, uint epic, uint premium) external onlyLandsale {
        require(_userCredits[user][Rarity.Common] >= common, "Not enough common credits");
        require(_userCredits[user][Rarity.Rare] >= rare, "Not enough rare credits");
        require(_userCredits[user][Rarity.Epic] >= epic, "Not enough epic credits");
        require(_userCredits[user][Rarity.Premium] >= premium, "Not enough premium credits");

        _userCredits[user][Rarity.Common] -= common;
        _userCredits[user][Rarity.Rare] -= rare;
        _userCredits[user][Rarity.Epic] -= epic;
        _userCredits[user][Rarity.Premium] -= premium;
        emit CreditsSpent(user, common, rare, epic, premium);
    }

    function setUserWhitelist(address user, bool phase1, bool phase2, bool phase3) external onlyOwnerOrAdmin {
        _setUserWhitelist(user, phase1, phase2, phase3);
        _setLastUpdate();
    }

    function setUserWhitelistBatch(
        address[] calldata users,
        bool[] calldata phase1,
        bool[] calldata phase2,
        bool[] calldata phase3
    ) external onlyOwnerOrAdmin {
        uint numUsers = users.length;
        require(numUsers == phase1.length && numUsers == phase2.length && numUsers == phase3.length, "Arrays must have the same length");
        for (uint i; i<numUsers;) {
            _setUserWhitelist(users[i], phase1[i], phase2[i], phase3[i]);
            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    function setUserWhitelistBatchPhass3(
        address[] calldata users,
        bool[] calldata phase3
    ) external onlyOwnerOrAdmin {
        uint numUsers = users.length;
        require(numUsers == phase3.length, "Arrays must have the same length");
        for (uint i; i<numUsers;) {
            _userWL[users[i]].phase3 = phase3[i];
            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    function _setUserWhitelist(address user, bool phase1, bool phase2, bool phase3) private {
        _userWL[user] = UserWhiteList ({
            phase1: phase1,
            phase2: phase2,
            phase3: phase3
        });
    }

    function removeUserWhitelist(address user) external onlyOwnerOrAdmin {
        delete _userWL[user];
    }

    function getUserWhitelistStatus(address user) external view returns(UserWhiteList memory userWhitelistData) {
        userWhitelistData = _userWL[user];
    }

    // Discounts
    function setUserDiscounts(address user, Discount[] calldata singleDiscounts, Discount[] calldata multiDiscounts) external onlyOwnerOrAdmin {
        _setUserDiscounts(user, singleDiscounts, multiDiscounts);
        _setLastUpdate();
    }

    function setUserDiscountsBatch(
        address[] calldata users,
        Discount[][] calldata singleDiscounts,
        Discount[][] calldata multiDiscounts
    ) external onlyOwnerOrAdmin {
        uint numUsers = users.length;
        require(numUsers == singleDiscounts.length && numUsers == multiDiscounts.length, "Arrays must have the same length");
        for (uint i; i<numUsers;) {
            _setUserDiscounts(users[i], singleDiscounts[i], multiDiscounts[i]);
            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    function _setUserDiscounts(address user, Discount[] calldata singleDiscounts, Discount[] calldata multiDiscounts) private {
        delete _userDiscountsSingle[user];
        delete _userDiscountsMulti[user];

        _addUserDiscounts(_userDiscountsSingle[user], singleDiscounts);
        _addUserDiscounts(_userDiscountsMulti[user], multiDiscounts);
    }

    function _addUserDiscounts(Discount[] storage localDiscounts, Discount[] calldata newDiscounts) internal {
        uint numDiscounts = newDiscounts.length;
        for(uint i; i<numDiscounts;) {
            localDiscounts.push(newDiscounts[i]);
            unchecked { ++i; }
        }
    }

    function addUserDiscounts(address user, Discount[] calldata singleDiscounts, Discount[] calldata multiDiscounts) external onlyOwnerOrAdmin {
        _addUserDiscounts(_userDiscountsSingle[user], singleDiscounts);
        _addUserDiscounts(_userDiscountsMulti[user], multiDiscounts);
        _setLastUpdate();
    }

    function addUserDiscountsBatch(
        address[] calldata users,
        Discount[][] calldata singleDiscounts,
        Discount[][] calldata multiDiscounts
    ) external onlyOwnerOrAdmin {
        uint numUsers = users.length;
        require(numUsers == singleDiscounts.length && numUsers == multiDiscounts.length, "Arrays must have the same length");
        for (uint i; i<numUsers;) {
            address user = users[i];
            _addUserDiscounts(_userDiscountsSingle[user], singleDiscounts[i]);
            _addUserDiscounts(_userDiscountsMulti[user], multiDiscounts[i]);
            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    function removeAllUserDiscoutns(address user) external onlyOwnerOrAdmin {
        delete _userDiscountsSingle[user];
        delete _userDiscountsMulti[user];
    }

    function getUserDiscountData(address user) external view returns (UserDiscounts memory userDiscountData) {
        userDiscountData = UserDiscounts ({
            single: _userDiscountsSingle[user],
            multi: _userDiscountsMulti[user]
        });
    }

    function loadDiscounts(address user, uint256[] calldata singleDiscountIndexes, uint256[] calldata multiDiscountIndexes) external view returns (Discount[] memory) {
        uint numSingleDiscounts = singleDiscountIndexes.length;
        uint numMultiDiscounts = multiDiscountIndexes.length;

        Discount[] memory discounts = new Discount[](numSingleDiscounts + numMultiDiscounts);

        if (numSingleDiscounts > 0) {
            for (uint i; i<numSingleDiscounts;) {
                require(singleDiscountIndexes[i] < _userDiscountsSingle[user].length, "Bad single discount index");
                discounts[i] = _userDiscountsSingle[user][singleDiscountIndexes[i]];
                unchecked { ++i; }
            }
        }

        if (numMultiDiscounts > 0) {
            for (uint i; i<numMultiDiscounts;) {
                require(multiDiscountIndexes[i] < _userDiscountsMulti[user].length, "Bad multi discount index");
                // Mind to start from after the last index for single discounts
                discounts[numSingleDiscounts + i] = _userDiscountsMulti[user][multiDiscountIndexes[i]];
                unchecked { ++i; }
            }
        }
        return discounts;
    }

    function spendDiscounts(address user, uint256[] calldata singleDiscountIndexes, uint256[] calldata multiDiscountIndexes) external onlyLandsale {
        _removeDiscountsByIndex(_userDiscountsSingle[user], singleDiscountIndexes);
        _removeDiscountsByIndex(_userDiscountsMulti[user], multiDiscountIndexes);
        if (singleDiscountIndexes.length > 0 || multiDiscountIndexes.length > 0) {
            emit DiscountsSpent(user, singleDiscountIndexes, multiDiscountIndexes);
        }
    }

    function _removeDiscountsByIndex(Discount[] storage array, uint256[] calldata indexes) internal {
        uint numDiscounts = indexes.length;
        if (numDiscounts == 0) {
            return;
        }
        // Since we move the last element to a lower position on deletion
        // We may save gas by deleting higher indexes first, so we go last to first
        // and enforce order using lastIndex variable.
        uint lastIndex = indexes[numDiscounts - 1];
        for (uint i; i<numDiscounts;) {
            uint index = indexes[numDiscounts - i - 1];
            uint arrayLen = array.length;
            require(index <= lastIndex, "Discount indexes must be ordered");
            // This condition should be unreachable, since discounts were already loaded.
            require(index < arrayLen, "Bad array index");
            if (index != arrayLen - 1) {
                array[index] = array[arrayLen - 1];
            }
            array.pop();
            lastIndex = index;
            unchecked { ++i; }
        }
    }

    // All in one
    function getUserData(address user) external view returns (UserDataIntake memory userData) {
        UserWhiteList memory userWhitelist = _userWL[user];

        userData = UserDataIntake ({
            commonCredits: _userCredits[user][Rarity.Common],
            rareCredits: _userCredits[user][Rarity.Rare],
            epicCredits: _userCredits[user][Rarity.Epic],
            premiumCredits: _userCredits[user][Rarity.Premium],
            singleDiscounts: _userDiscountsSingle[user],
            multiDiscounts: _userDiscountsMulti[user],
            whiteListPhase1: userWhitelist.phase1,
            whiteListPhase2: userWhitelist.phase2,
            whiteListPhase3: userWhitelist.phase3
        });
    }

    function setUserData(address user, UserDataIntake calldata intakeData) external onlyOwnerOrAdmin {
        _setUserWhitelist(user, intakeData.whiteListPhase1, intakeData.whiteListPhase2, intakeData.whiteListPhase3);
        _setUserCredits(user, intakeData.commonCredits, intakeData.rareCredits, intakeData.epicCredits, intakeData.premiumCredits);
        _setUserDiscounts(user, intakeData.singleDiscounts, intakeData.multiDiscounts);
        _setLastUpdate();
    }

    function setUserDataBatch(address[] calldata users, UserDataIntake[] calldata intakeData) external onlyOwnerOrAdmin {
        uint256 len = users.length;
        require(len == intakeData.length, "Arrays must have the same length");

        for(uint i; i<len;) {
            _setUserWhitelist(users[i], intakeData[i].whiteListPhase1, intakeData[i].whiteListPhase2, intakeData[i].whiteListPhase3);
            _setUserCredits(users[i], intakeData[i].commonCredits, intakeData[i].rareCredits, intakeData[i].epicCredits, intakeData[i].premiumCredits);
            _setUserDiscounts(users[i], intakeData[i].singleDiscounts, intakeData[i].multiDiscounts);

            unchecked { ++i; }
        }
        _setLastUpdate();
    }

    // Last Update

    function _setLastUpdate() private {
        _lastUpdate = block.timestamp;
    }

    function getLastUpdate() external view returns (uint256) {
        return _lastUpdate;
    }

}