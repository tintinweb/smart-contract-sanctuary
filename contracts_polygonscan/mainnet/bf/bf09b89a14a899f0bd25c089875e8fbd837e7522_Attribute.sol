// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../access/IAccessRestriction.sol";
import "../tree/ITree.sol";
import "./IAttribute.sol";
import "../treasury/interfaces/IUniswapV2Router02New.sol";

/** @title Attribute Contract */
contract Attribute is Initializable, IAttribute {
    using SafeCastUpgradeable for uint256;

    struct SymbolStatus {
        uint128 generatedCount;
        uint128 status; // 0 free, 1 reserved , 2 set, 3 setByAdmin
    }

    /** NOTE {isAttribute} set inside the initialize to {true} */
    bool public override isAttribute;

    /** NOTE total number of special tree created */
    uint8 public override specialTreeCount;

    IAccessRestriction public accessRestriction;
    ITree public treeToken;

    /** NOTE mapping from generated attributes to count of generations */
    mapping(uint64 => uint32)
        public
        override uniquenessFactorToGeneratedAttributesCount;

    /** NOTE mapping from unique symbol id to SymbolStatus struct */
    mapping(uint64 => SymbolStatus)
        public
        override uniquenessFactorToSymbolStatus;

    IUniswapV2Router02New public dexRouter;

    address[] public override dexTokens;

    address public override baseTokenAddress;

    /** NOTE modifier for check valid address */
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    /** NOTE modifier to check msg.sender has admin role */
    modifier onlyAdmin() {
        accessRestriction.ifAdmin(msg.sender);
        _;
    }

    /** NOTE modifier for check msg.sender has TreejerContract role */
    modifier onlyTreejerContract() {
        accessRestriction.ifTreejerContract(msg.sender);
        _;
    }

    /** NOTE modifier to check msg.sender has data manager role */
    modifier onlyDataManager() {
        accessRestriction.ifDataManager(msg.sender);
        _;
    }

    /** NOTE modifier to check msg.sender has data manager or treejer contract role */
    modifier onlyDataManagerOrTreejerContract() {
        accessRestriction.ifDataManagerOrTreejerContract(msg.sender);
        _;
    }

    /** NOTE modifier for check if function is not paused*/
    modifier ifNotPaused() {
        accessRestriction.ifNotPaused();
        _;
    }

    /// @inheritdoc IAttribute
    function initialize(address _accessRestrictionAddress)
        external
        override
        initializer
    {
        IAccessRestriction candidateContract = IAccessRestriction(
            _accessRestrictionAddress
        );
        require(candidateContract.isAccessRestriction());
        isAttribute = true;

        accessRestriction = candidateContract;
    }

    /**
     * @dev admin set TreeToken contract address
     * @param _address set to the address of TreeToken contract
     */
    function setTreeTokenAddress(address _address) external override onlyAdmin {
        ITree candidateContract = ITree(_address);

        require(candidateContract.isTree());

        treeToken = candidateContract;
    }

    /// @inheritdoc IAttribute
    function setBaseTokenAddress(address _baseTokenAddress)
        external
        override
        onlyAdmin
        validAddress(_baseTokenAddress)
    {
        baseTokenAddress = _baseTokenAddress;
    }

    /// @inheritdoc IAttribute
    function setDexRouterAddress(address _dexRouterAddress)
        external
        override
        onlyAdmin
        validAddress(_dexRouterAddress)
    {
        IUniswapV2Router02New candidateContract = IUniswapV2Router02New(
            _dexRouterAddress
        );

        dexRouter = candidateContract;
    }

    /// @inheritdoc IAttribute
    function setDexTokens(address[] calldata _tokens)
        external
        override
        onlyAdmin
    {
        require(_tokens.length > 0, "Invalid tokens");
        bool flag = true;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (!_isValidToken(_tokens[i])) {
                flag = false;
                break;
            }
        }
        require(flag, "Invalid pair address");
        dexTokens = _tokens;
    }

    /// @inheritdoc IAttribute
    function reserveSymbol(uint64 _uniquenessFactor)
        external
        override
        ifNotPaused
        onlyDataManagerOrTreejerContract
    {
        require(
            _checkValidSymbol(_uniquenessFactor),
            "Invalid symbol"
        );
        require(
            uniquenessFactorToSymbolStatus[_uniquenessFactor].status == 0,
            "Duplicate symbol"
        );
        uniquenessFactorToSymbolStatus[_uniquenessFactor].status = 1;

        emit SymbolReserved(_uniquenessFactor);
    }

    /// @inheritdoc IAttribute
    function releaseReservedSymbolByAdmin(uint64 _uniquenessFactor)
        external
        override
        ifNotPaused
        onlyDataManager
    {
        require(
            uniquenessFactorToSymbolStatus[_uniquenessFactor].status == 1,
            "Attribute not exists"
        );

        uniquenessFactorToSymbolStatus[_uniquenessFactor].status = 0;

        emit ReservedSymbolReleased(_uniquenessFactor);
    }

    /// @inheritdoc IAttribute
    function releaseReservedSymbol(uint64 _uniquenessFactor)
        external
        override
        onlyTreejerContract
    {
        if (uniquenessFactorToSymbolStatus[_uniquenessFactor].status == 1) {
            uniquenessFactorToSymbolStatus[_uniquenessFactor].status = 0;
            emit ReservedSymbolReleased(_uniquenessFactor);
        }
    }

    /// @inheritdoc IAttribute
    function setAttribute(
        uint256 _treeId,
        uint64 _attributeUniquenessFactor,
        uint64 _symbolUniquenessFactor,
        uint8 _generationType,
        uint64 _coefficient
    ) external override ifNotPaused onlyDataManagerOrTreejerContract {
        require(
            _checkValidSymbol(_symbolUniquenessFactor),
            "Invalid symbol"
        );
        require(
            uniquenessFactorToSymbolStatus[_symbolUniquenessFactor].status < 2,
            "Duplicate symbol"
        );
        require(
            uniquenessFactorToGeneratedAttributesCount[
                _attributeUniquenessFactor
            ] == 0,
            "Duplicate attribute"
        );
        uniquenessFactorToGeneratedAttributesCount[
            _attributeUniquenessFactor
        ] = 1;
        uniquenessFactorToSymbolStatus[_symbolUniquenessFactor].status = 3;

        uniquenessFactorToSymbolStatus[_symbolUniquenessFactor]
            .generatedCount = 1;

        uint256 uniquenessFactor = _attributeUniquenessFactor +
            ((uint256(_symbolUniquenessFactor) + (_coefficient << 24)) << 64);

        treeToken.setAttributes(_treeId, uniquenessFactor, _generationType);

        emit AttributeGenerated(_treeId);
    }

    /// @inheritdoc IAttribute
    function createSymbol(
        uint256 _treeId,
        bytes32 _randomValue,
        address _funder,
        uint8 _funderRank,
        uint8 _generationType
    ) external override onlyTreejerContract returns (bool) {
        if (!treeToken.attributeExists(_treeId)) {
            bool flag = false;
            uint64 tempRandomValue;

            for (uint256 j = 0; j < 10; j++) {
                uint256 randomValue = uint256(
                    keccak256(
                        abi.encodePacked(
                            _funder,
                            _randomValue,
                            _generationType,
                            msg.sig,
                            _treeId,
                            j
                        )
                    )
                );

                for (uint256 i = 0; i < 4; i++) {
                    tempRandomValue = uint64(randomValue & type(uint64).max);

                    flag = _generateUniquenessFactor(
                        _treeId,
                        tempRandomValue,
                        _funderRank,
                        _generationType
                    );
                    if (flag) {
                        break;
                    }

                    randomValue >>= 64;
                }
                if (flag) {
                    break;
                }
            }
            if (flag) {
                emit AttributeGenerated(_treeId);
            } else {
                emit AttributeGenerationFailed(_treeId);
            }

            return flag;
        } else {
            return true;
        }
    }

    /// @inheritdoc IAttribute
    function createAttribute(uint256 _treeId, uint8 _generationType)
        external
        override
        onlyTreejerContract
        returns (bool)
    {
        if (!treeToken.attributeExists(_treeId)) {
            (
                bool flag,
                uint64 uniquenessFactor
            ) = _generateAttributeUniquenessFactor(_treeId);

            if (flag) {
                treeToken.setAttributes(
                    _treeId,
                    uniquenessFactor,
                    _generationType
                );
                uniquenessFactorToGeneratedAttributesCount[
                    uniquenessFactor
                ] = 1;

                emit AttributeGenerated(_treeId);
            } else {
                emit AttributeGenerationFailed(_treeId);
            }

            return flag;
        } else {
            return true;
        }
    }

    /// @inheritdoc IAttribute
    function manageAttributeUniquenessFactor(uint256 _treeId)
        external
        override
        onlyTreejerContract
        returns (uint64)
    {
        (
            bool flag,
            uint64 uniquenessFactor
        ) = _generateAttributeUniquenessFactor(_treeId);

        require(flag, "Attribute not generated");

        return uniquenessFactor;
    }

    /// @inheritdoc IAttribute
    function getFunderRank(address _funder)
        external
        view
        override
        returns (uint8)
    {
        uint256 ownedTrees = treeToken.balanceOf(_funder);

        if (ownedTrees > 1000) {
            return 3;
        } else if (ownedTrees > 100) {
            return 2;
        } else if (ownedTrees > 10) {
            return 1;
        }

        return 0;
    }

    /**
     * @dev create a unique 64 bit random number
     * @param _treeId id of tree
     * @return true when uniquenessFactor is unique and false otherwise
     * @return uniquenessFactor
     */
    function _generateAttributeUniquenessFactor(uint256 _treeId)
        private
        returns (bool, uint64)
    {
        uint64 uniquenessFactor;

        uint256 seed = uint256(
            keccak256(abi.encodePacked(_treeId, block.timestamp))
        );

        uint256 selectorDexToken = seed % dexTokens.length;

        address selectedDexToken = dexTokens[selectorDexToken];

        uint256 amount = _getDexAmount(_treeId, selectedDexToken);

        for (uint256 j = 0; j < 10; j++) {
            uint256 randomValue = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sig,
                        _treeId,
                        amount,
                        selectedDexToken,
                        seed,
                        j
                    )
                )
            );

            for (uint256 i = 0; i < 4; i++) {
                uniquenessFactor = uint64(randomValue & type(uint64).max);

                if (
                    uniquenessFactorToGeneratedAttributesCount[
                        uniquenessFactor
                    ] == 0
                ) {
                    return (true, uniquenessFactor);
                } else {
                    uniquenessFactorToGeneratedAttributesCount[
                        uniquenessFactor
                    ] += 1;

                    randomValue >>= 64;
                }
            }
        }
        return (false, 0);
    }

    /**
     * @dev calculates the random symbol parameters
     * @param _treeId id of tree
     * @param _randomValue base random value
     * @param _funderRank rank of funder based on trees owned in treejer
     * @param _generationType type of attribute assignement
     * @return if generated random symbol is unique
     */
    function _generateUniquenessFactor(
        uint256 _treeId,
        uint64 _randomValue,
        uint8 _funderRank,
        uint8 _generationType
    ) private returns (bool) {
        if (uniquenessFactorToGeneratedAttributesCount[_randomValue] == 0) {
            uint16[] memory attributes = new uint16[](4);

            uint64 tempRandomValue = _randomValue;
            for (uint256 j = 0; j < 4; j++) {
                attributes[j] = uint16(tempRandomValue & type(uint16).max);

                tempRandomValue >>= 16;
            }

            uint8 shape = _calcShape(attributes[0], _funderRank);

            uint8 trunkColor;
            uint8 crownColor;

            if (shape > 32) {
                (trunkColor, crownColor) = _calcColors(
                    attributes[1],
                    attributes[2],
                    _funderRank
                );
            } else {
                trunkColor = 1;
                crownColor = 1;
            }

            uint64 symbolUniquenessFactor = shape +
                (uint64(trunkColor) << 8) +
                (uint64(crownColor) << 16);

            if (
                uniquenessFactorToSymbolStatus[symbolUniquenessFactor].status >
                0
            ) {
                uniquenessFactorToSymbolStatus[symbolUniquenessFactor]
                    .generatedCount += 1;

                return false;
            }
            uint8 coefficient = _calcCoefficient(attributes[3], _funderRank);

            uint256 uniquenessFactor = _randomValue +
                ((symbolUniquenessFactor + (uint256(coefficient) << 24)) << 64);

            uniquenessFactorToSymbolStatus[symbolUniquenessFactor].status = 2;
            uniquenessFactorToSymbolStatus[symbolUniquenessFactor]
                .generatedCount = 1;
            uniquenessFactorToGeneratedAttributesCount[_randomValue] = 1;
            treeToken.setAttributes(_treeId, uniquenessFactor, _generationType);

            return true;
        } else {
            uniquenessFactorToGeneratedAttributesCount[_randomValue] += 1;
            return false;
        }
    }

    /**
     * @dev admin set TreeToken contract address
     * @param _token token in dex exchange with high liquidity
     */
    function _isValidToken(address _token) private view returns (bool) {
        return _getAmountsOut(2000 * 10**18, _token) > 0;
    }

    /**
     * @dev admin set TreeToken contract address
     * @param _amount dai price to get the
     * @param _token token in dex exchange with high liquidity
     */
    function _getDexAmount(uint256 _amount, address _token)
        private
        view
        returns (uint256)
    {
        uint256 amount = ((_amount % 2000) + 1) * 10**18;
        return _getAmountsOut(amount, _token);
    }

    function _getAmountsOut(uint256 _amount, address _token)
        private
        view
        returns (uint256)
    {
        address[] memory path;
        path = new address[](2);

        path[0] = baseTokenAddress;
        path[1] = _token;

        uint256[] memory amounts = dexRouter.getAmountsOut(_amount, path);

        return amounts[1];
    }

    /**
     * @dev admin set TreeToken contract address
     * @param _symbol symbol to check its validity
     */
    function _checkValidSymbol(uint64 _symbol) private pure returns (bool) {
        uint8[] memory symbs = new uint8[](8);
        for (uint256 i = 0; i < 8; i++) {
            symbs[i] = uint8(_symbol & 255);
            _symbol >>= 8;
        }

        if (
            symbs[0] > 144 ||
            symbs[1] > 65 ||
            symbs[2] > 65 ||
            symbs[3] > 8 ||
            (symbs[4] + symbs[5] + symbs[6] + symbs[7] != 0)
        ) {
            return false;
        }
        return true;
    }

    /**
     * @dev generate statistical shape based on {_randomValue} and {_funderRank}
     * @param _randomValue base random value
     * @param _funderRank rank of funder based on trees owned in treejer
     * @return shape type id
     */
    function _calcShape(uint16 _randomValue, uint8 _funderRank)
        private
        returns (uint8)
    {
        uint16[7] memory probRank0 = [2782, 1797, 987, 459, 194, 62, 1];
        uint16[7] memory probRank1 = [2985, 2065, 1191, 596, 266, 101, 2];
        uint16[7] memory probRank2 = [3114, 2264, 1389, 729, 333, 135, 3];
        uint16[7] memory probRank3 = [3246, 2462, 1656, 931, 468, 203, 5];
        uint16[7] memory selectedRankProb;

        if (_funderRank == 3) {
            selectedRankProb = probRank3;
        } else if (_funderRank == 2) {
            selectedRankProb = probRank2;
        } else if (_funderRank == 1) {
            selectedRankProb = probRank1;
        } else {
            selectedRankProb = probRank0;
        }

        uint8 shape;

        uint8 randomValueFirstFourBit = uint8(_randomValue & 15);

        uint16 probability = _randomValue >> 4;

        uint8 result = 0;

        for (uint8 j = 0; j < 7; j++) {
            if (probability > selectedRankProb[j]) {
                result = 7 - j;
                break;
            }
        }

        if (result == 0) {
            if (specialTreeCount < 16) {
                shape = 17 + specialTreeCount;
                specialTreeCount += 1;
            } else {
                shape = 33 + randomValueFirstFourBit;
            }
        } else {
            shape = (result + 1) * 16 + 1 + randomValueFirstFourBit;
        }

        return shape;
    }

    /**
     * @dev generate statistical colors based on {_randomValue1} and {_randomValue2} and
     * {_funderRank}
     * @param _randomValue1 base random1 value
     * @param _randomValue2 base random2 value
     * @param _funderRank rank of funder based on trees owned in treejer
     * @return trunk color id
     * @return crown color id
     */
    function _calcColors(
        uint16 _randomValue1,
        uint16 _randomValue2,
        uint8 _funderRank
    ) private pure returns (uint8, uint8) {
        uint16[7] memory probRank0 = [3112, 2293, 1637, 1064, 671, 343, 97];
        uint16[7] memory probRank1 = [3440, 2540, 1818, 1162, 736, 375, 113];
        uint16[7] memory probRank2 = [3603, 2947, 2128, 1391, 818, 408, 130];
        uint16[7] memory probRank3 = [3767, 3276, 2620, 1637, 981, 490, 162];
        uint16[7] memory selectedRankProb;

        if (_funderRank == 3) {
            selectedRankProb = probRank3;
        } else if (_funderRank == 2) {
            selectedRankProb = probRank2;
        } else if (_funderRank == 1) {
            selectedRankProb = probRank1;
        } else {
            selectedRankProb = probRank0;
        }

        uint8 randomValue1Last3Bit = uint8(_randomValue1 & 7);
        uint16 probability1 = _randomValue1 >> 4;
        uint8 randomValue2Last3Bit = uint8(_randomValue2 & 7);
        uint16 probability2 = _randomValue2 >> 4;

        uint8 result1 = 0;
        uint8 result2 = 0;

        for (uint8 i = 0; i < 7; i++) {
            if (probability1 > selectedRankProb[i]) {
                result1 = 7 - i;
                break;
            }
        }

        for (uint8 j = 0; j < 7; j++) {
            if (probability2 > selectedRankProb[j]) {
                result2 = 7 - j;
                break;
            }
        }

        return (
            result1 * 8 + 2 + randomValue1Last3Bit,
            result2 * 8 + 2 + randomValue2Last3Bit
        );
    }

    /**
     * @dev generate statistical coefficient value based on {_randomValue} and {_funderRank}
     * @param _randomValue base random value
     * @param _funderRank rank of funder based on trees owned in treejer
     * @return coefficient value
     */
    function _calcCoefficient(uint16 _randomValue, uint8 _funderRank)
        private
        pure
        returns (uint8)
    {
        uint16[6] memory probRank0 = [49153, 58985, 62916, 64554, 65210, 65472];
        uint16[6] memory probRank1 = [45877, 57345, 62261, 64227, 65112, 65437];
        uint16[6] memory probRank2 = [39323, 54069, 60622, 63899, 65013, 65406];
        uint16[6] memory probRank3 = [26216, 45877, 58985, 63571, 64882, 65374];

        uint16[6] memory selectedRankProb;

        if (_funderRank == 3) {
            selectedRankProb = probRank3;
        } else if (_funderRank == 2) {
            selectedRankProb = probRank2;
        } else if (_funderRank == 1) {
            selectedRankProb = probRank1;
        } else {
            selectedRankProb = probRank0;
        }

        for (uint8 j = 0; j < 6; j++) {
            if (_randomValue < selectedRankProb[j]) {
                return j + 2;
            }
        }

        return 8;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/** @title AccessRestriction interface*/

interface IAccessRestriction is IAccessControlUpgradeable {
    /** @dev pause functionality */
    function pause() external;

    /** @dev unpause functionality */
    function unpause() external;

    function initialize(address _deployer) external;

    /** @return true if AccessRestriction contract has been initialized  */
    function isAccessRestriction() external view returns (bool);

    /**
     * @dev check if given address is planter
     * @param _address input address
     */
    function ifPlanter(address _address) external view;

    /**
     * @dev check if given address has planter role
     * @param _address input address
     * @return if given address has planter role
     */
    function isPlanter(address _address) external view returns (bool);

    /**
     * @dev check if given address is admin
     * @param _address input address
     */
    function ifAdmin(address _address) external view;

    /**
     * @dev check if given address has admin role
     * @param _address input address
     * @return if given address has admin role
     */
    function isAdmin(address _address) external view returns (bool);

    /**
     * @dev check if given address is Treejer contract
     * @param _address input address
     */
    function ifTreejerContract(address _address) external view;

    /**
     * @dev check if given address has Treejer contract role
     * @param _address input address
     * @return if given address has Treejer contract role
     */
    function isTreejerContract(address _address) external view returns (bool);

    /**
     * @dev check if given address is data manager
     * @param _address input address
     */
    function ifDataManager(address _address) external view;

    /**
     * @dev check if given address has data manager role
     * @param _address input address
     * @return if given address has data manager role
     */
    function isDataManager(address _address) external view returns (bool);

    /**
     * @dev check if given address is verifier
     * @param _address input address
     */
    function ifVerifier(address _address) external view;

    /**
     * @dev check if given address has verifier role
     * @param _address input address
     * @return if given address has verifier role
     */
    function isVerifier(address _address) external view returns (bool);

    /**
     * @dev check if given address is script
     * @param _address input address
     */
    function ifScript(address _address) external view;

    /**
     * @dev check if given address has script role
     * @param _address input address
     * @return if given address has script role
     */
    function isScript(address _address) external view returns (bool);

    /**
     * @dev check if given address is DataManager or Treejer contract
     * @param _address input address
     */
    function ifDataManagerOrTreejerContract(address _address) external view;

    /** @dev check if functionality is not puased */
    function ifNotPaused() external view;

    /** @dev check if functionality is puased */
    function ifPaused() external view;

    /** @return if functionality is paused*/
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
/** @title Tree interface */
interface ITree is IERC721Upgradeable {
    /**
     * @dev initialize AccessRestriction contract, baseURI and set true for isTree
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     * @param baseURI_ initial baseURI
     */
    function initialize(
        address _accessRestrictionAddress,
        string calldata baseURI_
    ) external;

    /** @dev admin set {baseURI_} to baseURI */
    function setBaseURI(string calldata baseURI_) external;

    /**
     * @dev mint {_tokenId} to {_to}
     */
    function mint(address _to, uint256 _tokenId) external;

    /**
     * @dev set attribute and symbol for a tokenId based on {_uniquenessFactor}
     * NOTE symbol set when {_generationType} is more than 15 (for HonoraryTree and IncremetalSale)
     * @param _tokenId id of token
     * @param _uniquenessFactor uniqueness factor
     * @param _generationType type of generation
     */
    function setAttributes(
        uint256 _tokenId,
        uint256 _uniquenessFactor,
        uint8 _generationType
    ) external;

    /**
     * @dev check attribute existance for a tokenId
     * @param _tokenId id of token
     * @return true if attributes exist for {_tokenId}
     */
    function attributeExists(uint256 _tokenId) external returns (bool);

    /**
     * @return true in case of Tree contract have been initialized
     */
    function isTree() external view returns (bool);

    function baseURI() external view returns (string memory);

    /**
     * @dev return attribute data
     * @param _tokenId id of token to get data
     * @return attribute1
     * @return attribute2
     * @return attribute3
     * @return attribute4
     * @return attribute5
     * @return attribute6
     * @return attribute7
     * @return attribute8
     * @return generationType
     */
    function attributes(uint256 _tokenId)
        external
        view
        returns (
            uint8 attribute1,
            uint8 attribute2,
            uint8 attribute3,
            uint8 attribute4,
            uint8 attribute5,
            uint8 attribute6,
            uint8 attribute7,
            uint8 attribute8,
            uint8 generationType
        );

    /**
     * @dev return symbol data
     * @param _tokenId id of token to get data
     * @return shape
     * @return trunkColor
     * @return crownColor
     * @return coefficient
     * @return generationType
     */
    function symbols(uint256 _tokenId)
        external
        view
        returns (
            uint8 shape,
            uint8 trunkColor,
            uint8 crownColor,
            uint8 coefficient,
            uint8 generationType
        );

    /**
     * @dev check that _tokenId exist or not
     * @param _tokenId id of token to check existance
     * @return true if {_tokenId} exist
     */
    function exists(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/** @title Attribute interfce */
interface IAttribute {
    /**
     * @dev emitted when unique attribute generated successfully
     * @param treeId id of tree to generate attribute for
     */
    event AttributeGenerated(uint256 treeId);

    /**
     * @dev emitted when attribute genertion failed
     * @param treeId id of tree that attribute generation failed
     */
    event AttributeGenerationFailed(uint256 treeId);

    /**
     * @dev emitted when a symbol reserved
     * @param uniquenessFactor unique symbol to reserve
     */
    event SymbolReserved(uint64 uniquenessFactor);

    /**
     * @dev emitted when reservation of a unique symbol released
     * @param uniquenessFactor unique symbol to release reservation
     */
    event ReservedSymbolReleased(uint64 uniquenessFactor);

    /** @dev set {_address} to TreeToken contract address */
    function setTreeTokenAddress(address _address) external;

    /**
     * @dev admin set Base Token contract address
     * @param _baseTokenAddress set to the address of Dai contract
     */
    function setBaseTokenAddress(address _baseTokenAddress) external;

    /**
     * @dev admin set Dex tokens list
     * @param _tokens an array of tokens in dex exchange with high liquidity
     */
    function setDexTokens(address[] calldata _tokens) external;

    /**
     * @dev admin set DexRouter contract address
     * @param _dexRouterAddress set to the address of DexRouter contract
     */
    function setDexRouterAddress(address _dexRouterAddress) external;

    /**
     * @dev reserve a unique symbol
     * @param _uniquenessFactor unique symbol to reserve
     * NOTE emit a {SymbolReserved} event
     */
    function reserveSymbol(uint64 _uniquenessFactor) external;

    /**
     * @dev release reservation of a unique symbol by admin
     * @param _uniquenessFactor unique symbol to release reservation
     * NOTE emit a {ReservedSymbolReleased} event
     */
    function releaseReservedSymbolByAdmin(uint64 _uniquenessFactor) external;

    /**
     * @dev release reservation of a unique symbol
     * @param _uniquenessFactor unique symbol to release reservation
     * NOTE emit a {ReservedSymbolReleased} event
     */
    function releaseReservedSymbol(uint64 _uniquenessFactor) external;

    /**
     * @dev admin assigns symbol and attribute to the specified treeId
     * @param _treeId id of tree
     * @param _attributeUniquenessFactor unique attribute code to assign
     * @param _symbolUniquenessFactor unique symbol to assign
     * @param _generationType type of attribute assignement
     * @param _coefficient coefficient value
     * NOTE emit a {AttributeGenerated} event
     */
    function setAttribute(
        uint256 _treeId,
        uint64 _attributeUniquenessFactor,
        uint64 _symbolUniquenessFactor,
        uint8 _generationType,
        uint64 _coefficient
    ) external;

    /**
     * @dev generate a random unique symbol using tree attributes 64 bit value
     * @param _treeId id of tree
     * @param _randomValue base random value
     * @param _funder address of funder
     * @param _funderRank rank of funder based on trees owned in treejer
     * @param _generationType type of attribute assignement
     * NOTE emit a {AttributeGenerated} or {AttributeGenerationFailed} event
     * @return if unique symbol generated successfully
     */
    function createSymbol(
        uint256 _treeId,
        bytes32 _randomValue,
        address _funder,
        uint8 _funderRank,
        uint8 _generationType
    ) external returns (bool);

    /**
     * @dev generate a random unique attribute using tree attributes 64 bit value
     * @param _treeId id of tree
     * @param _generationType generation type
     * NOTE emit a {AttributeGenerated} or {AttributeGenerationFailed} event
     * @return if unique attribute generated successfully
     */
    function createAttribute(uint256 _treeId, uint8 _generationType)
        external
        returns (bool);

    /**
     * @dev check and generate random attributes for honorary trees
     * @param _treeId id of tree
     * @return a unique random value
     */
    function manageAttributeUniquenessFactor(uint256 _treeId)
        external
        returns (uint64);

    /**
     * @dev initialize AccessRestriction contract and set true for isAttribute
     * @param _accessRestrictionAddress set to the address of AccessRestriction contract
     */
    function initialize(address _accessRestrictionAddress) external;

    /** @return true in case of Attribute contract has been initialized */
    function isAttribute() external view returns (bool);

    /** @return total number of special tree created */
    function specialTreeCount() external view returns (uint8);

    /**
     * @return DaiToken address
     */
    function baseTokenAddress() external view returns (address);

    /**
     * @dev return generation count
     * @param _attribute generated attributes
     * @return generation count
     */
    function uniquenessFactorToGeneratedAttributesCount(uint64 _attribute)
        external
        view
        returns (uint32);

    /**
     * @dev return SymbolStatus
     * @param _uniqueSymbol unique symbol
     * @return generatedCount
     * @return status
     */
    function uniquenessFactorToSymbolStatus(uint64 _uniqueSymbol)
        external
        view
        returns (uint128 generatedCount, uint128 status);

    function dexTokens(uint256 _index) external view returns (address);

    /**
     * @dev the function tries to calculate the rank of funder based trees owned in Treejer
     * @param _funder address of funder
     */
    function getFunderRank(address _funder) external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.6;

import "./IUniswapV2Router01New.sol";

interface IUniswapV2Router02New is IUniswapV2Router01New {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.6;

interface IUniswapV2Router01New {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}