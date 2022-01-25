// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GovWorldAdminRegistry.sol";
import "./interfaces/IGovWorldTierLevel.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GovWorldTierLevel is IGovWorldTierLevel, OwnableUpgradeable {
    //list of new tier levels
    mapping(bytes32 => TierData) public tierLevels;
    //list of all added tier levels. Stores the key for mapping => tierLevels
    bytes32[] allTierLevelKeys;

    mapping(uint256 => SingleSPTierData) public spTierLevels;
    uint256[] spTierLevelKeys;

    mapping(address => NFTTierData) public nftTierLevels;
    address[] nftTierLevelsKeys;

    uint256 public currentSpTierLevel;

    mapping(address => bytes32) public tierLevelbyAddress;

    GovWorldAdminRegistry govAdminRegistry;
    address private govToken;
    address private govGovToken;

    event TierLevelAdded(bytes32 _newTierLevel, TierData _tierData);
    event TierLevelUpdated(bytes32 _updatetierLevel, TierData _tierData);
    event TierLevelRemoved(bytes32 _removedtierLevel);

    function initialize(
        address _govAdminRegistry,
        address _govTokenAddress,
        bytes32 _bronze,
        bytes32 _silver,
        bytes32 _gold,
        bytes32 _platinum,
        bytes32 _allStar
    ) external initializer {
        __Ownable_init();
        govAdminRegistry = GovWorldAdminRegistry(_govAdminRegistry);
        govToken = _govTokenAddress;

        _addTierLevel(
            _bronze,
            TierData(15000e18, 30, false, false, true, false, true, false)
        );
        _addTierLevel(
            _silver,
            TierData(30000e18, 40, false, false, true, true, true, false)
        );
        _addTierLevel(
            _gold,
            TierData(75000e18, 50, true, true, true, true, true, true)
        );
        _addTierLevel(
            _platinum,
            TierData(150000e18, 70, true, true, true, true, true, true)
        );
        _addTierLevel(
            _allStar,
            TierData(300000e18, 70, true, true, true, true, true, true)
        );
    }

    modifier onlyEditTierLevelRole(address admin) {
        require(
            govAdminRegistry.isEditAdminAccessGranted(admin),
            "GTL: No admin right to add or remove tier level."
        );
        _;
    }

    function isEditTierLevel(address admin) external view returns (bool) {
        return govAdminRegistry.isEditAdminAccessGranted(admin);
    }

    modifier onlySuperAdmin(address admin) {
        require(
            govAdminRegistry.isSuperAdminAccess(admin),
            "GTL: only super admin allowed"
        );
        _;
    }

    //external functions

    /**
    @dev external function to add new tier level (keys with their access values)
    @param _newTierLevel must be a new tier key in bytes32
    @param _tierData access variables of the each Tier Level
     */
    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        //admin have not already added new tier level
        require(
            !_isAlreadyTierLevel(_newTierLevel),
            "GTL: already added tier level"
        );
        require(
            _tierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL: set govHolding error"
        );
        require(
            _tierData.govHoldings >
                tierLevels[allTierLevelKeys[maxGovTierLevelIndex()]]
                    .govHoldings,
            "GovHolding Should be greater then last tier level Gov Holdings"
        );
        //adding tier level called by the admin
        _addTierLevel(_newTierLevel, _tierData);
    }

    /**
    @dev this function add new tier level if not exist and update tier level if already exist.
     */
    function saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) external onlyEditTierLevelRole(msg.sender) {
        require(
            _tierLevelKeys.length == _newTierData.length,
            "New Tier Keys and TierData length must be equal"
        );
        _saveTierLevel(_tierLevelKeys, _newTierData);
    }

    /**
    @dev add NFT based Traditional or Single Token type tier levels
     */
    function addSingleSpTierLevel(SingleSPTierData memory _spTierLevel)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(_spTierLevel.ltv > 0, "Invalid LTV");
        spTierLevels[spTierLevelKeys.length] = _spTierLevel;
        spTierLevelKeys.push(spTierLevelKeys.length);
    }

    // function to assign tierlevel to the NFT contract only by super admin
    function addNftTierLevel(
        address _nftContract,
        NFTTierData memory _tierLevel
    ) external onlySuperAdmin(msg.sender) {
        if (_tierLevel.isTraditional) {
            require(
                _isAlreadyTierLevel(_tierLevel.traditionalTier),
                "GTL:Traditional Tier Null"
            );
        } else {
            require(
                spTierLevels[_tierLevel.nftTier].ltv > 0,
                "GTL: SP Tier Null"
            );
        }

        nftTierLevels[_nftContract] = _tierLevel;
        nftTierLevelsKeys.push(_nftContract);
    }

    function getSingleSpTierLength() external view returns (uint256) {
        return spTierLevelKeys.length;
    }

    function getNFTTierLength() external view returns (uint256) {
        return nftTierLevelsKeys.length;
    }

    /**
    @dev external function to update the existing tier level, also check if it is already added or not
    @param _updatedTierLevelKey existing tierlevel key
    @param _newTierData new data for the updateding Tier level
     */
    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external onlyEditTierLevelRole(msg.sender) {
        require(
            _newTierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL: set govHolding error"
        );
        require(
            _isAlreadyTierLevel(_updatedTierLevelKey),
            "GovWorldTier: cannot update Tier, create new tier first"
        );
        _updateTierLevel(_updatedTierLevelKey, _newTierData);
    }

    function updateSingleSpTierLevel(
        uint256 _index,
        uint256 _ltv,
        bool _singleNft
    ) external onlyEditTierLevelRole(msg.sender) {
        require(_ltv > 0, "Invalid LTV");
        require(spTierLevels[_index].ltv > 0, "Tier not exist");
        spTierLevels[_index].ltv = _ltv;
        spTierLevels[_index].singleNft = _singleNft;
    }

    /**
    @dev remove tier level key as well as from mapping
    @param _existingTierLevel tierlevel hash in bytes32
     */
    function removeTierLevel(bytes32 _existingTierLevel)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(
            _isAlreadyTierLevel(_existingTierLevel),
            "GovWorldTier: cannot remove, Tier Level not exist"
        );
        delete tierLevels[_existingTierLevel];
        emit TierLevelRemoved(_existingTierLevel);

        _removeTierLevelKey(_getIndex(_existingTierLevel));
    }

    /**
    @dev add NFT based Traditional or Single Token type tier levels
     */
    function removeSingleSpTierLevel(uint256 index)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(index > 0, "Invalid index");
        require(spTierLevels[index].ltv > 0, "Invalid index");
        delete spTierLevels[index];
        _removeSingleSpTierLevelKey(_getIndexSpTier(index));
    }

    /**
    @dev add NFT based Traditional or Single Token type tier levels
     */
    function removeNftTierLevel(address _contract)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(_contract != address(0), "Invalid address");
        require(
            nftTierLevels[_contract].nftContract != address(0),
            "Invalid index"
        );
        delete nftTierLevels[_contract];
        _removeNftTierLevelKey(_getIndexNftTier(_contract));
    }

    //public functions

    /**
     * @dev get all the Tier Level Keys from the allTierLevelKeys array
     */
    function getAllTierLevels() public view returns (bytes32[] memory) {
        return allTierLevelKeys;
    }

    /**
     * @dev get Single Tier Level Data
     */
    function getSingleTierData(bytes32 _tierLevelKey)
        public
        view
        returns (TierData memory)
    {
        return tierLevels[_tierLevelKey];
    }

    //internal functions

    /**
     * @dev makes _new a pendsing adnmin for approval to be given by all current admins
     * @param _newTierLevel value type of the New Tier Level in bytes
     * @param _tierData access variables for _newadmin
     */

    function _addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        internal
    {
        //new Tier is added to the mapping tierLevels
        tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /**
     * @dev Checks if a given _newTierLevel is already added by the admin.
     * @param _tierLevel value of the new tier
     */
    function _isAlreadyTierLevel(bytes32 _tierLevel)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev update already created tier level
     * @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
     * @param _newTierData access variables for updating the Tier Level
     */

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) internal {
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings + 10;
        if (currentIndex > 0) {
            lowerLimit = tierLevels[allTierLevelKeys[currentIndex - 1]]
                .govHoldings;
        }
        if (currentIndex < allTierLevelKeys.length - 1)
            upperLimit = tierLevels[allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "GTL: Holdings Range Error"
        );

        tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /**
     * @dev remove tier level
     * @param index already existing tierlevel index
     */
    function _removeTierLevelKey(uint256 index) internal {
        if (allTierLevelKeys.length != 1) {
            for (uint256 i = index; i < allTierLevelKeys.length - 1; i++) {
                allTierLevelKeys[i] = allTierLevelKeys[i + 1];
            }
        }
        allTierLevelKeys.pop();
    }

    /**
     * @dev remove single sp tieer level key
     * @param index already existing tierlevel index
     */
    function _removeSingleSpTierLevelKey(uint256 index) internal {
        if (spTierLevelKeys.length != 1) {
            for (uint256 i = index; i < spTierLevelKeys.length - 1; i++) {
                spTierLevelKeys[i] = spTierLevelKeys[i + 1];
            }
        }
        spTierLevelKeys.pop();
    }

    function _removeNftTierLevelKey(uint256 index) internal {
        if (nftTierLevelsKeys.length != 1) {
            for (uint256 i = index; i < nftTierLevelsKeys.length - 1; i++) {
                nftTierLevelsKeys[i] = nftTierLevelsKeys[i + 1];
            }
        }
        nftTierLevelsKeys.pop();
    }

    /**
    @dev internal function for the save tier level, which will update and add tier level at a time
     */
    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) internal {
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            require(
                _newTierData[i].govHoldings < IERC20(govToken).totalSupply(),
                "GTL: set govHolding error"
            );
            if (!_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /**
    @dev this function returns the index of the maximum govholding tier level
     */
    function maxGovTierLevelIndex() public view returns (uint256) {
        uint256 max = tierLevels[allTierLevelKeys[0]].govHoldings;
        uint256 maxIndex = 0;

        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (tierLevels[allTierLevelKeys[i]].govHoldings > max) {
                maxIndex = i;
                max = tierLevels[allTierLevelKeys[i]].govHoldings;
            }
        }

        return maxIndex;
    }

    /**
    @dev get index of the tierLevel from the allTierLevel array
    @param _tierLevel hash of the tier level
     */
    function _getIndex(bytes32 _tierLevel)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    /**
    @dev get index of the singleSpTierLevel from the allTierLevel array
    @param _tier hash of the tier level
    */
    function _getIndexSpTier(uint256 _tier)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < spTierLevelKeys.length; i++) {
            if (spTierLevelKeys[i] == _tier) {
                return i;
            }
        }
    }

    /**
    @dev get index of the nftTierLevel from the allTierLevel array
    @param _tier hash of the tier level
    */
    function _getIndexNftTier(address _tier)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < nftTierLevelsKeys.length; i++) {
            if (nftTierLevelsKeys[i] == _tier) {
                return i;
            }
        }
    }

    /**
    @dev this function returns the tierLevel data by user's Gov Token Balance
    @param userWalletAddress user address for check tier level data
     */
    function getTierDatabyGovBalance(address userWalletAddress)
        public
        view
        override
        returns (TierData memory _tierData)
    {
        require(govToken != address(0x0), "GTL: Gov Token not Configured");
        require(
            govGovToken != address(0x0),
            "GTL: govGov GToken not Configured"
        );
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress) +
            IERC20(govGovToken).balanceOf(userWalletAddress);

        if (userGovBalance >= tierLevels[allTierLevelKeys[0]].govHoldings) {
            for (uint256 i = 1; i < allTierLevelKeys.length; i++) {
                if (
                    (userGovBalance >=
                        tierLevels[allTierLevelKeys[i - 1]].govHoldings) &&
                    (userGovBalance <
                        tierLevels[allTierLevelKeys[i]].govHoldings)
                ) {
                    return tierLevels[allTierLevelKeys[i - 1]];
                } else if (
                    userGovBalance >=
                    tierLevels[allTierLevelKeys[allTierLevelKeys.length - 1]]
                        .govHoldings
                ) {
                    return
                        tierLevels[
                            allTierLevelKeys[allTierLevelKeys.length - 1]
                        ];
                }
            }
        } else {
            for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
                if (
                    allTierLevelKeys[i] == tierLevelbyAddress[userWalletAddress]
                ) {
                    return tierLevels[allTierLevelKeys[i]];
                }
            }
        }
    }

    function stringToBytes32(string memory _string)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_string, 32))
        }
    }

    // set govGovToken address, only superadmin
    function configuregovGovToken(address _govGovTokenAddress)
        external
        onlySuperAdmin(msg.sender)
    {
        require(
            _govGovTokenAddress != address(0),
            "GTL: Invalid Contract Address!"
        );
        require(govGovToken == address(0), "GTL: Contract Already Configured!");
        govGovToken = _govGovTokenAddress;
    }

    // function to assign tier level to the address only by the super admin
    function addEditWalletTierLevel(address _userAddress, bytes32 _tierLevel)
        external
        onlySuperAdmin(msg.sender)
    {
        require(
            tierLevelbyAddress[_userAddress] == 0,
            "GTL: user already assigned tierLevel"
        );
        tierLevelbyAddress[_userAddress] = _tierLevel;
    }

    //Returns max loan amount a borrower can borrow
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256) {
        uint256 maxLoanAmountAllowed = (_collateralTokeninStable *
            _tierLevelLTVPercentage) / 100;
        return maxLoanAmountAllowed;
    }

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view override returns (uint256) {
        TierData memory tierData = this.getTierDatabyGovBalance(_borrower);
        NFTTierData memory nftTier = this.getUserNftTier(_borrower);
        SingleSPTierData memory nftSpTier = spTierLevels[nftTier.nftTier];

        if (tierData.govHoldings > 0) {
            return (_collateralTokeninStable * tierData.loantoValue) / 100;
        } else if (nftTier.isTraditional) {
            TierData memory traditionalTierData = tierLevels[
                nftTier.traditionalTier
            ];
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else if (nftSpTier.ltv > 0) {
            return (_collateralTokeninStable * nftSpTier.ltv) / 100;
        } else {
            return 0;
        }
    }

    function getUserNftTier(address _wallet)
        external
        view
        returns (NFTTierData memory nftTierData)
    {
        uint256 maxLTVFromNFTTier;
        address maxNFTTierAddress;

        require(nftTierLevelsKeys.length > 0, "GTL: no nft tier yet");
        if (nftTierLevels[nftTierLevelsKeys[0]].isTraditional) {
            maxLTVFromNFTTier = tierLevels[
                nftTierLevels[nftTierLevelsKeys[0]].traditionalTier
            ].loantoValue;
            maxNFTTierAddress = nftTierLevelsKeys[0];
        } else {
            maxLTVFromNFTTier = spTierLevels[
                nftTierLevels[nftTierLevelsKeys[0]].nftTier
            ].ltv;
            maxNFTTierAddress = nftTierLevelsKeys[0];
        }

        for (uint256 i = 1; i < nftTierLevelsKeys.length; i++) {
           
                //user owns nft balannce
                uint256 currentLoanToValue;

                if (nftTierLevels[nftTierLevelsKeys[i]].isTraditional) {
                    currentLoanToValue = tierLevels[
                        nftTierLevels[nftTierLevelsKeys[i]].traditionalTier
                    ].loantoValue;
                } else {
                    currentLoanToValue = spTierLevels[
                        nftTierLevels[nftTierLevelsKeys[i]].nftTier
                    ].ltv;
                }

                if (currentLoanToValue >= maxLTVFromNFTTier) {
                    maxNFTTierAddress = nftTierLevelsKeys[i];
                    maxLTVFromNFTTier = currentLoanToValue;
                }
        }

        if(IERC721(maxNFTTierAddress).balanceOf(_wallet) > 0) {
            return nftTierLevels[maxNFTTierAddress];
        } else {
            return nftTierLevels[address(0x0)];
        }
    }

    /**
     * @dev Rules 1. User have gov balance tier, and they will
     * crerae single and multi token and nft loan according to tier level flags.
     * Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
     * Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
     * Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
     * Returns 200 if success all otther are differentt error codes
     */
    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = this.getUserNftTier(_wallet);
        if (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) {
            //Rule 4: having both tiers is a sin
            return 1;
        }
        if (tierData.govHoldings > 0) {
            //user has gov tier level
            //start validatting loan offer
            if (tierData.singleToken || tierData.multiToken) {
                if (!tierData.multiToken) {
                    if (_stakedCollateralTokens.length > 1) {
                        return 2; //multi-token loan not allowed in tier.
                    }
                }
            }
            if (
                _loanAmount >
                this.getMaxLoanAmount(_collateralinStable, tierData.loantoValue)
            ) {
                //allowed ltv
                return 3;
            }
        } else {
            //determine if user nft tier is available
            // need to determinne is user one
            //of the nft holder in NFTTierData mapping
            if (nftTier.isTraditional) {
                TierData memory traditionalTierData = tierLevels[
                    nftTier.traditionalTier
                ];
                //start validatting loan offer
                if (
                    traditionalTierData.singleToken ||
                    traditionalTierData.multiToken
                ) {
                    if (!traditionalTierData.multiToken) {
                        if (_stakedCollateralTokens.length > 1) {
                            return 2; //multi-token loan not allowed in tier.
                        }
                    }
                }
                if (
                    _loanAmount >
                    this.getMaxLoanAmount(
                        _collateralinStable,
                        traditionalTierData.loantoValue
                    )
                ) {
                    //allowed ltv
                    return 3;
                }
            } else {
                SingleSPTierData memory nftSpTier = spTierLevels[
                    nftTier.nftTier
                ];

                if (_stakedCollateralTokens.length > 1) {
                    //only single token allowed for sp tier
                    return 5;
                }
                uint256 maxLoanAmount = (_collateralinStable * nftSpTier.ltv) /
                    100;
                if (_loanAmount > maxLoanAmount) {
                    //loan to value is under tier
                    return 6;
                }
                if (_stakedCollateralTokens[0] != nftTier.spToken) {
                    //collateral can not be other then sp token
                    return 7;
                }
            }
        }
        return 200;
    }

    /**
     * @dev Rules 1. User have gov balance tier, and they will
     * crerae single and multi token and nft loan according to tier level flags.
     * Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
     * Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
     * Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
     * Returns 200 if success all otther are differentt error codes
     */
    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = this.getUserNftTier(_wallet);
        if (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) {
            //Rule 4: having both tiers is a sin
            return 1;
        }
        if (tierData.govHoldings > 0) {
            //user has gov tier level
            //start validatting loan offer
            if (tierData.singleToken || tierData.multiToken) {
                if (!tierData.multiToken) {
                    if (_stakedCollateralNFTs.length > 1) {
                        return 2; //multi-token loan not allowed in tier.
                    }
                }
            }
            if (
                _loanAmount >
                this.getMaxLoanAmount(_collateralinStable, tierData.loantoValue)
            ) {
                //allowed ltv
                return 3;
            }
        } else {
            //determine if user nft tier is available
            // need to determinne is user one
            //of the nft holder in NFTTierData mapping
            if (nftTier.isTraditional) {
                TierData memory traditionalTierData = tierLevels[
                    nftTier.traditionalTier
                ];
                //start validatting loan offer
                if (
                    traditionalTierData.singleToken ||
                    traditionalTierData.multiToken
                ) {
                    if (!traditionalTierData.multiToken) {
                        if (_stakedCollateralNFTs.length > 1) {
                            return 2; //multi-token loan not allowed in tier.
                        }
                    }
                }
                if (
                    _loanAmount >
                    this.getMaxLoanAmount(
                        _collateralinStable,
                        traditionalTierData.loantoValue
                    )
                ) {
                    //allowed ltv
                    return 3;
                }
            } else {
                SingleSPTierData memory nftSpTier = spTierLevels[
                    nftTier.nftTier
                ];

                if (_stakedCollateralNFTs.length > 1 && !nftSpTier.multiNFT) {
                    //only single token allowed for sp tier
                    return 5;
                }
                uint256 maxLoanAmount = (_collateralinStable * nftSpTier.ltv) /
                    100;
                if (_loanAmount > maxLoanAmount) {
                    //loan to value is under tier
                    return 6;
                }

                for (uint256 c = 0; c < _stakedCollateralNFTs.length; c++) {
                    bool found = false;
                    
                    for (uint256 x = 0; x < nftTier.allowedNfts.length; x++) {
                        if (
                            _stakedCollateralNFTs[c] == nftTier.allowedNfts[x]
                        ) {
                            //collateral can not be other then sp token
                            found = true;
                        }
                    }

                    for(uint256 y = 0; y < nftTier.allowedSUNTokens.length; y++) {
                        if(_stakedCollateralNFTs[c] == nftTier.allowedSUNTokens[y]) {
                            found = true;
                        }
                    }


                    if (!found) {
                        //can not be other then approved sp nfts or approved sun tokens
                        return 7;
                    }
                }
            }
        }
        return 200;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GovWorldAdminBase.sol";

contract GovWorldAdminRegistry is GovWorldAdminBase {
    address public superAdmin; //it should be private

    function initialize(
        address _superAdmin,
        address _admin1,
        address _admin2,
        address _admin3
    ) external initializer {
        __Ownable_init();
        pendingAdminKeys = new address[][](3);

        //owner becomes the default admin.
        _makeDefaultApproved(
            _superAdmin,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );

        _makeDefaultApproved(
            _admin1,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        _makeDefaultApproved(
            _admin2,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        _makeDefaultApproved(
            _admin3,
            AdminAccess(
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                false
            )
        );
        superAdmin = _superAdmin;

        PENDING_ADD_ADMIN_KEY = 0;
        PENDING_EDIT_ADMIN_KEY = 1;
        PENDING_REMOVE_ADMIN_KEY = 2;
        //  ADD,EDIT,REMOVE
        PENDING_KEYS = [0, 1, 2];
    }

    function transferSuperAdmin(address _newSuperAdmin) external {
        require(_newSuperAdmin != address(0), "invalid newSuperAdmin");
        require(_newSuperAdmin != superAdmin, "already designated");
        require(msg.sender == superAdmin, "not super admin");
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (allApprovedAdmins[i] == _newSuperAdmin) {
                approvedAdminRoles[_newSuperAdmin].superAdmin = true;
                approvedAdminRoles[superAdmin].superAdmin = false;
                superAdmin = _newSuperAdmin;
            }
            emit SuperAdminOwnershipTransfer(
                _newSuperAdmin,
                approvedAdminRoles[_newSuperAdmin]
            );
        }
    }

    /**
     * @dev Checks if a given _newAdmin is approved by all other already approved amins
     * @param _newAdmin Address of the new admin
     */
    function isDoneByAll(address _newAdmin, uint8 _key)
        external
        view
        returns (bool)
    {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _areByAdmins = areByAdmins[_key][_newAdmin];

        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (
                _key == PENDING_ADD_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].addGovAdmin &&
                allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == PENDING_REMOVE_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _newAdmin
            ) {
                allCount = allCount + 1;
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
            if (
                _key == PENDING_EDIT_ADMIN_KEY &&
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _newAdmin //all but yourself.
            ) {
                allCount = allCount + 1;
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _areByAdmins.length; j++) {
                    if (_areByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount + 1;
                    }
                }
            }
        }
        // standard multi-sig 51 % approvals needed to perform
        if (presentCount >= (allCount / 2) + 1) return true;
        else return false;
    }

    /**
     * @dev makes _newAdmin an approved admin if there is only one curernt admin _newAdmin becomes
     * becomes approved as it is and if currently more then 1 admins then approveAddedAdmin needs to be
     * called  by all current admins
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function addAdmin(address _newAdmin, AdminAccess memory _adminAccess)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(
            _adminAccess.addGovIntel == true ||
                _adminAccess.editGovIntel == true ||
                _adminAccess.addToken == true ||
                _adminAccess.editToken == true ||
                _adminAccess.addSp == true ||
                _adminAccess.editSp == true ||
                _adminAccess.addGovAdmin == true ||
                _adminAccess.editGovAdmin == true ||
                _adminAccess.addBridge == true ||
                _adminAccess.editBridge == true ||
                _adminAccess.addPool == true ||
                _adminAccess.editPool == true,
            "GAR: admin roles error"
        );
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_newAdmin != address(0), "invalid address");
        require(_newAdmin != msg.sender, "GAR: call for self"); //the GovAdmin cannot add himself as admin again
        require(
            allApprovedAdmins.length > 0,
            "GAR: addDefaultAdmin as onwer first. "
        );
        require(
            _notAvailable(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            !_addressExists(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            "GAR: already in pending"
        );
        require(
            !_addressExists(_newAdmin, allApprovedAdmins),
            "GAR: cannot add again"
        );
        require(
            _adminAccess.superAdmin == false,
            "GAR: superadmin assign error"
        );

        if (allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
            _makeDefaultApproved(_newAdmin, _adminAccess);
        } else {
            //this admin is now in the pending list.
            _makePendingForAddEdit(
                _newAdmin,
                _adminAccess,
                PENDING_ADD_ADMIN_KEY
            );
        }
        performPendingActions();
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
     * @param _newAdmin Address of the new admin
     */
    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_newAdmin != msg.sender, "GAR: cannot self approve");
        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notAvailable(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            _addressExists(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            "GAR: nonpending error"
        );

        areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin].push(msg.sender);
        emit NewAdminApproved(_newAdmin, msg.sender, PENDING_ADD_ADMIN_KEY);

        //if the _newAdmin is approved by all other admins
        if (this.isDoneByAll(_newAdmin, PENDING_ADD_ADMIN_KEY)) {
            //no need for approvedby anymore
            delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
            //making this admin approved.
            _makeApproved(
                _newAdmin,
                pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_newAdmin]
            );
            //no  need  for pending  role now
            delete pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_newAdmin];

            emit NewAdminApprovedByAll(
                _newAdmin,
                approvedAdminRoles[_newAdmin]
            );
        }
    }

    function isPending(address _sender) internal view returns (bool) {
        return (!_addressExists(
            _sender,
            pendingAdminKeys[PENDING_ADD_ADMIN_KEY]
        ) ||
            !_addressExists(
                _sender,
                pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]
            ) ||
            !_addressExists(
                _sender,
                pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]
            ));
    }

    /**
     * @dev any admin can reject the pending admin during the approval process and one rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectAdmin(address _admin, uint8 _key)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: call for self");
        require(
            _addressExists(_admin, pendingAdminKeys[_key]),
            "GAR: nonpending error"
        );
        require(
            _key == PENDING_ADD_ADMIN_KEY ||
                _key == PENDING_EDIT_ADMIN_KEY ||
                _key == PENDING_REMOVE_ADMIN_KEY,
            "GAR: wrong key inserted"
        );

        require(
            areByAdmins[_key][_admin].length > 0,
            "GAR: not available for rejction"
        );

        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, _key),
            "GAR: already approved"
        );
        //only with the reject of one admin call delete roles from mapping
        delete pendingAdminRoles[_key][_admin];
        for (uint256 i = 0; i < areByAdmins[_key][_admin].length; i++) {
            areByAdmins[_key][_admin].pop();
        }
        _removePendingIndex(_getIndex(_admin, pendingAdminKeys[_key]), _key);
        //delete admin roles from approved mapping
        delete areByAdmins[_key][_admin];
        emit AddAdminRejected(_admin, msg.sender);
    }

    /**
    @dev Get all Approved Admins 
     */
    function getAllApproved() public view returns (address[] memory) {
        return allApprovedAdmins;
    }

    /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingAddedAdminKeys()
        public
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_ADD_ADMIN_KEY];
    }

    /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingEditAdminKeys()
        public
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_EDIT_ADMIN_KEY];
    }

    /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingRemoveAdminKeys()
        public
        view
        returns (address[] memory)
    {
        return pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY];
    }

    /**
    @dev Get all admin addresses which approved the address in the parameter
    @param _addedAdmin address of the approved/proposed added admin.
     */
    function getApprovedByAdmins(address _addedAdmin)
        public
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_ADD_ADMIN_KEY][_addedAdmin];
    }

    /**
    @dev Get all edit by admins addresses
     */
    function getEditbyAdmins(address _editAdmin)
        public
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_EDIT_ADMIN_KEY][_editAdmin];
    }

    /**
    @dev Get all admin addresses which approved the address in the parameter
    @param _removedAdmin address of the approved/proposed added admin.
     */
    function getRemovedByAdmins(address _removedAdmin)
        public
        view
        returns (address[] memory)
    {
        return areByAdmins[PENDING_REMOVE_ADMIN_KEY][_removedAdmin];
    }

    /**
    @dev Get pending add admin roles
     */
    function getpendingAddedAdminRoles(address _addAdmin)
        public
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_addAdmin];
    }

    /**
    @dev Get pending edit admin roles
     */
    function getpendingEditedAdminRoles(address _addAdmin)
        public
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_addAdmin];
    }

    /**
    @dev Get pending remove admin roles
     */
    function getpendingRemovedAdminRoles(address _addAdmin)
        public
        view
        returns (AdminAccess memory)
    {
        return pendingAdminRoles[PENDING_REMOVE_ADMIN_KEY][_addAdmin];
    }

    /**
     * @dev Initiate process of removal of admin,
     * in case there is only one admin removal is done instantly.
     * If there are more then one admin all must call removePendingAdmin.
     * @param _admin Address of the admin requested to be removed
     */
    function removeAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        // important! this statement checks if msg.sender is already in pending, so that he cannot place new requrest until his pending request is approved or rejected
        require(isPending(msg.sender), "GAR: caller already in pending");

        require(_admin != address(0), "invalid address");
        require(_admin != superAdmin, "GAR: cannot remove superadmin");
        require(_admin != msg.sender, "GAR: call for self");
        //the admin that is removing _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY),
            "GAR: already removed"
        );
        require(allApprovedAdmins.length > 0, "cannot remove last admin");
        require(
            !_addressExists(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            "GAR: already in pending"
        );
        require(_addressExists(_admin, allApprovedAdmins), "GAR: not an admin");

        // require(pendingRemoveAdminKeys.length == 0, "GAR: pending actions, cannot remove now");
        //if length is 1 there is only one admin and he/she is removing another admin
        if (allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
            _removeAdmin(_admin);
        } else {
            //this admin is now in the pending list.
            _makePendingForRemove(_admin, PENDING_REMOVE_ADMIN_KEY);
        }
        performPendingActions();
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
     * @param _admin Address of the new admin
     */
    function approveRemovedAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: cannot call for self");
        //the admin that is adding _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY),
            "GAR: already approved"
        );
        require(
            _addressExists(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            "GAR: nonpending admin error"
        );

        areByAdmins[PENDING_REMOVE_ADMIN_KEY][_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, PENDING_REMOVE_ADMIN_KEY)) {
            // _admin is now been removed
            _removeAdmin(_admin);
        } else {
            emit NewAdminApproved(_admin, msg.sender, PENDING_REMOVE_ADMIN_KEY);
        }
        performPendingActions();
    }

    function performPendingActions() internal {
        for (uint256 x = 0; x < PENDING_KEYS.length; x++) {
            for (uint256 i = 0; i < pendingAdminKeys[x].length; i++) {
                if (this.isDoneByAll(pendingAdminKeys[x][i], PENDING_KEYS[x])) {
                    if (PENDING_KEYS[x] == PENDING_ADD_ADMIN_KEY)
                        _makeApproved(
                            pendingAdminKeys[x][i],
                            pendingAdminRoles[PENDING_ADD_ADMIN_KEY][
                                pendingAdminKeys[PENDING_ADD_ADMIN_KEY][i]
                            ]
                        );
                    if (PENDING_KEYS[x] == PENDING_EDIT_ADMIN_KEY)
                        _editAdmin(pendingAdminKeys[x][i]);
                    if (PENDING_KEYS[x] == PENDING_REMOVE_ADMIN_KEY)
                        _removeAdmin(pendingAdminKeys[x][i]);
                    performPendingActions();
                }
            }
        }
    }

    /**
     * @dev Initiate process of edit of an admin,
     * If there are more then one admin all must call approveEditAdmin
     * @param _admin Address of the admin requested to be removed
     */
    function editAdmin(address _admin, AdminAccess memory _adminAccess)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(
            _adminAccess.addGovIntel == true ||
                _adminAccess.editGovIntel == true ||
                _adminAccess.addToken == true ||
                _adminAccess.editToken == true ||
                _adminAccess.addSp == true ||
                _adminAccess.editSp == true ||
                _adminAccess.addGovAdmin == true ||
                _adminAccess.editGovAdmin == true ||
                _adminAccess.addBridge == true ||
                _adminAccess.editBridge == true ||
                _adminAccess.addPool == true ||
                _adminAccess.editPool == true,
            "GAR: admin right error"
        );
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: self edit error");
        require(_admin != superAdmin, "GAR: superadmin error");
        require(allApprovedAdmins.length > 0, "GAR: cannot remove");
        //the admin that is removing _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY),
            "GAR: already approve for edit"
        );
        require(
            !_addressExists(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            "GAR: already pending for edit"
        );
        require(_addressExists(_admin, allApprovedAdmins), "GAR: not admin");

        require(
            _adminAccess.superAdmin == false,
            "GAR: cannot assign super admin"
        );

        if (allApprovedAdmins.length == 1) {
            _editAdmin(_admin);
        } else {
            //this admin is now in the pending list.
            _makePendingForAddEdit(
                _admin,
                _adminAccess,
                PENDING_EDIT_ADMIN_KEY
            );
        }
        performPendingActions();
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveEditAdmin are complete the admin edits become active
     * @param _admin Address of the new admin
     */
    function approveEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(isPending(msg.sender), "GAR: caller already in pending");
        require(_admin != msg.sender, "GAR: call for self");
        require(
            _addressExists(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            "GAR: nonpending admin error"
        );
        //the admin that is adding _admin must not already have approved.
        require(
            _notAvailable(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY),
            "GAR: already approved"
        );
        areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isDoneByAll(_admin, PENDING_EDIT_ADMIN_KEY)) {
            // _admin is now an approved admin.
            _editAdmin(_admin);
        } else {
            emit NewAdminApproved(_admin, msg.sender, PENDING_EDIT_ADMIN_KEY);
        }
        performPendingActions();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TierData {
    // Gov  Holdings to check if it lies in that tier
    uint256 govHoldings;
    // LTV percentage of the Gov Holdings
    uint8 loantoValue;
    //checks that if tier level have access
    bool govIntel;
    bool singleToken;
    bool multiToken;
    bool singleNFT;
    bool multiNFT;
    bool reverseLoan;
}
struct SingleSPTierData {
    uint256 ltv;
    bool singleToken;
    bool singleNft;
    bool multiNFT;
}

struct NFTTierData {
    address nftContract;
    bool isTraditional;
    address spToken;
    bytes32 traditionalTier;
    uint256 nftTier;
    address[] allowedNfts;
    address[] allowedSUNTokens;
}

interface IGovWorldTierLevel {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (TierData memory _tierData);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../admin/interfaces/IGovWorldAdminRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GovWorldAdminBase is OwnableUpgradeable, IGovWorldAdminRegistry {
    //admin role keys
    uint8 public PENDING_ADD_ADMIN_KEY;
    uint8 public PENDING_EDIT_ADMIN_KEY;
    uint8 public PENDING_REMOVE_ADMIN_KEY;
    //                      ADD,EDIT,REMOVE
    uint8[] PENDING_KEYS;

    //list of already approved admins.
    mapping(address => AdminAccess) public approvedAdminRoles;

    //list of all approved admin addresses. Stores the key for mapping approvedAdminRoles
    address[] public allApprovedAdmins;

    //mapping of admin role keys to admin addresses to admin access roles
    mapping(uint8 => mapping(address => AdminAccess)) public pendingAdminRoles;
    //keys of admin role keys to admin addresses
    address[][] public pendingAdminKeys;

    //a list of admins approved by other admins.
    mapping(uint8 => mapping(address => address[])) public areByAdmins;

    event NewAdminApproved(
        address indexed _newAdmin,
        address indexed _addByAdmin,
        uint8 indexed _key
    );
    event NewAdminApprovedByAll(
        address indexed _newAdmin,
        AdminAccess _adminAccess
    );
    event AdminRemovedByAll(
        address indexed _admin,
        address indexed _removedByAdmin
    );
    event AdminEditedApprovedByAll(
        address indexed _admin,
        AdminAccess _adminAccess
    );
    event AddAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event EditAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event RemoveAdminRejected(
        address indexed _newAdmin,
        address indexed _rejectByAdmin
    );
    event SuperAdminOwnershipTransfer(
        address indexed _superAdmin,
        AdminAccess _adminAccess
    );

    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        require(
            approvedAdminRoles[_admin].addGovAdmin,
            "GAR: not add admin role"
        );
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        require(
            approvedAdminRoles[_admin].editGovAdmin,
            "GAR: not edit admin role"
        );
        _;
    }

    /**
     * @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
     * @param _newAdmin Address of the new admin
     * @param _by Address of the existing admin that may have approved/edited/removed _newAdmin already.
     * @param _by Address of the existing admin that may have approved/edited/removed _newAdmin already.
     */
    function _notAvailable(
        address _newAdmin,
        address _by,
        uint8 _key
    ) internal view returns (bool) {
        for (uint256 k = 0; k < PENDING_KEYS.length; k++) {
            if (_key == PENDING_KEYS[k]) {
                for (
                    uint256 i = 0;
                    i < areByAdmins[_key][_newAdmin].length;
                    i++
                ) {
                    if (areByAdmins[_key][_newAdmin][i] == _by) {
                        return false; //approved/edited/removed
                    }
                }
            }
        }
        return true; //not approved/edited/removed
    }

    /**
     * @dev makes _newAdmin an approved admin and emits the event
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makeDefaultApproved(
        address _newAdmin,
        AdminAccess memory _adminAccess
    ) internal {
        //no need for approved by admin for the new  admin anymore.
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        emit NewAdminApprovedByAll(_newAdmin, _adminAccess);
    }

    /**
     * @dev makes _newAdmin an approved admin and emits the event
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makeApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //no need for approved by admin for the new  admin anymore.
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        _removePendingIndex(
            _getIndex(_newAdmin, pendingAdminKeys[PENDING_ADD_ADMIN_KEY]),
            PENDING_ADD_ADMIN_KEY
        );
    }

    /**
     * @dev makes _newAdmin a pendsing adnmin for approval to be given by all current admins
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makePendingForAddEdit(
        address _newAdmin,
        AdminAccess memory _adminAccess,
        uint8 _key
    ) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        areByAdmins[_key][_newAdmin].push(msg.sender);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAdminRoles[_key][_newAdmin] = _adminAccess;
        pendingAdminKeys[_key].push(_newAdmin);
        emit NewAdminApproved(_newAdmin, msg.sender, _key);
    }

    /**
     * @dev makes _newAdmin an removed admin and emits the event
     * @param _admin Address of the new admin
     */
    function _removeAdmin(address _admin) internal {
        // _admin is now a removed admin.
        delete approvedAdminRoles[_admin];
        delete areByAdmins[PENDING_REMOVE_ADMIN_KEY][_admin];
        delete areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin];
        delete areByAdmins[PENDING_ADD_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_ADD_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_REMOVE_ADMIN_KEY][_admin];

        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, allApprovedAdmins));
        _removePendingIndex(
            _getIndex(_admin, pendingAdminKeys[PENDING_REMOVE_ADMIN_KEY]),
            PENDING_REMOVE_ADMIN_KEY
        );

        emit AdminRemovedByAll(_admin, msg.sender);
    }

    /**
     * @dev makes _newAdmin an removed admin and emits the event
     * @param _admin Address of the new admin
     */
    function _editAdmin(address _admin) internal {
        // _admin is now an removed admin.

        approvedAdminRoles[_admin] = pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][
            _admin
        ];

        delete areByAdmins[PENDING_EDIT_ADMIN_KEY][_admin];
        delete pendingAdminRoles[PENDING_EDIT_ADMIN_KEY][_admin];
        _removePendingIndex(
            _getIndex(_admin, pendingAdminKeys[PENDING_EDIT_ADMIN_KEY]),
            PENDING_EDIT_ADMIN_KEY
        );

        emit AdminEditedApprovedByAll(_admin, approvedAdminRoles[_admin]);
    }

    function _removeIndex(uint256 index) internal {
        for (uint256 i = index; i < allApprovedAdmins.length - 1; i++) {
            allApprovedAdmins[i] = allApprovedAdmins[i + 1];
        }
        allApprovedAdmins.pop();
    }

    function _removePendingIndex(uint256 index, uint8 key) internal {
        for (uint256 i = index; i < pendingAdminKeys[key].length - 1; i++) {
            pendingAdminKeys[key][i] = pendingAdminKeys[key][i + 1];
        }
        pendingAdminKeys[key].pop();
    }

    /**
     * @dev makes _admin a pendsing adnmin for approval to be given by
     * all current admins for removing this admnin.
     * @param _admin Address of the new admin
     */
    function _makePendingForRemove(address _admin, uint8 _key) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        areByAdmins[_key][_admin].push(msg.sender);
        pendingAdminKeys[_key].push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAdminRoles[_key][_admin] = approvedAdminRoles[_admin];
        emit NewAdminApproved(_admin, msg.sender, _key);
    }

    function _removeKey(address _valueToFindAndRemove, address[] memory from)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory auxArray;
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] != _valueToFindAndRemove) {
                auxArray[i] = from[i];
            }
        }
        from = auxArray;
        return from;
    }

    function _getIndex(address _valueToFindAndRemove, address[] memory from)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _valueToFindAndRemove) {
                return i;
            }
        }
    }

    function _addressExists(address _valueToFind, address[] memory from)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _valueToFind) {
                return true;
            }
        }
        return false;
    }

    function isAddGovAdminRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editGovAdmin;
    }

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addToken;
    }

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editToken;
    }

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addSp;
    }

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].editSp;
    }

    //using this function externally in other smart contracts
    function isEditAPYPerAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin)
        external
        view
        override
        returns (bool)
    {
        return approvedAdminRoles[admin].superAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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