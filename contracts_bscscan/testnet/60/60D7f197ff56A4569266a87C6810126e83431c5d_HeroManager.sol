// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;



contract Constants {
    uint256 public constant BLOCK_CREATED_AT = 0;
    uint256 public constant BLOCK_BALANCE_UPDATED_AT = 1;
    uint256 public constant TIME_ALLOW_BURN = 3;

    uint256 public constant HERO_TYPE = 1000;
    uint256 public constant AMOUNT_CYRRENCY_TO_HERO = 1001;

    uint256 public constant AVATAR = 1010;

    uint256 public constant SKILL_WARRIOR = 1100;
    uint256 public constant SKILL_FARMER = 1101;
    uint256 public constant SKILL_TRADER = 1102;
    uint256 public constant SKILL_PREDICTOR = 1103;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract EconomicVariables {
    mapping (uint256 => bool) private variablesKeys;
    mapping (uint256 => uint256) private variablesValues;

    function _createOrUpdateVariable(uint256 key, uint256 value) internal {
        variablesKeys[key] = true;
        variablesValues[key] = value;
    }
    function _removeVariableKey(uint256 key) internal {
        variablesKeys[key] = false;
        variablesValues[key] = 0;
    }

    function getVariable(uint256 key) public existedVariableKeys(key) view returns (uint256) {
        return variablesValues[key];
    }

    function _updateVariable(uint256 key, uint256 value) internal existedVariableKeys(key) {
        variablesValues[key] = value;
    }

    modifier existedVariableKeys(uint256 key) {
        //require(variablesKeys[key], "EconomicVariables: key is not exists");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../vendor/interfaces/IERC20.sol";
import "../vendor/interfaces/IStorage.sol";
import "../vendor/libraries/access/Ownable.sol";
import "../vendor/libraries/proxy/Initializable.sol";
import "./EconomicVariables.sol";
import "./HeroTeam.sol";
import "./Treasury.sol"; 
import "../Constants.sol";
//import "@nomiclabs/buidler/console.sol";

contract HeroManager is Ownable, EconomicVariables, HeroTeam, Treasury, Constants, Initializable {
    using SafeMath for uint256;

    //IStorage public _HeroStorage;
    address public _HeroStorage;
    address public _incentivesPool;
 
    function initialize(  
        IERC20 PACT_,
        address HeroStorage_,
        address incentivesPool_
    ) public initializer {
        Treasury._initialize(PACT_);
        Ownable._initialize();
        _HeroStorage = HeroStorage_;
        _incentivesPool = incentivesPool_;
        _setVariablesDefaultValues();
        _editHeroTeamSettings(_enableHeroTeam(PACT_), 10e18, 100e18);
    }


    modifier onlyHeroOwner(uint256 heroId) {
        require(IStorage(_HeroStorage).ownerOf(heroId) == msg.sender, "HeroManager::onlyHeroOwner: only hero owner allowed");
        _;
    }

/////////////////////////////// BaseEconomicVariables
    uint256 public constant CREATION_COST = 10;
    uint256 public constant LEVEL_UP_COST = 11;
    uint256 public constant BURN_PART_IN_PPM_FOR_CREATION = 101;
    uint256 public constant BURN_PART_IN_PPM_FOR_MULTICAST_FEE = 102;
    uint256 public constant BURN_PART_IN_PPM_FOR_LEVEL_UP = 103;

    function _setVariablesDefaultValues() internal {
        _createOrUpdateVariable(CREATION_COST, 100e18);
        _createOrUpdateVariable(LEVEL_UP_COST, 100e18);
        _createOrUpdateVariable(BURN_PART_IN_PPM_FOR_CREATION, 20000);
        _createOrUpdateVariable(BURN_PART_IN_PPM_FOR_MULTICAST_FEE, 20000);
        _createOrUpdateVariable(BURN_PART_IN_PPM_FOR_LEVEL_UP, 20000);
    }

    function updateVariable(uint256 key, uint256 value) public onlyOwner {
        _updateVariable(key, value);
    }

/////////////////////////////// HeroTeam
    uint256 public constant HERO_TEAM_VARIABLE_MODIFIER_MIN_AMOUNT_IN_TOKEN = 1002;
    uint256 public constant HERO_TEAM_VARIABLE_MODIFIER_MAX_AMOUNT_IN_TOKEN = 1003;

    function disableHeroTeam(uint256 currencyId) public allowedHeroTeam(currencyId) onlyOwner {
        _disableHeroTeam(currencyId); 
    }
    function enableHeroTeam(
        IERC20 currency,
        uint256 minAmountInToken,
        uint256 maxAmountInToken
    ) public onlyOwner {
        _editHeroTeamSettings(
            _enableHeroTeam(currency),
            minAmountInToken,
            maxAmountInToken
        );
    }

    function editHeroTeamSettings(
        uint256 currencyId, 
        uint256 minAmountInToken,
        uint256 maxAmountInToken
    ) public allowedHeroTeam(currencyId) onlyOwner {
        _editHeroTeamSettings(
            currencyId,
            minAmountInToken,
            maxAmountInToken
        );
    }

    function _editHeroTeamSettings(
        uint256 heroTeamVariableKey,
        uint256 minAmountInToken,
        uint256 maxAmountInToken
    ) internal {
        _createOrUpdateVariable(
            heroTeamVariableKey.add(HERO_TEAM_VARIABLE_MODIFIER_MIN_AMOUNT_IN_TOKEN),
            minAmountInToken
        );
        _createOrUpdateVariable(
            heroTeamVariableKey.add(HERO_TEAM_VARIABLE_MODIFIER_MAX_AMOUNT_IN_TOKEN),
            maxAmountInToken
        );
    }

    function getHeroTeamSettingsValue(
        uint256 currencyId, 
        uint256 key
    ) public allowedHeroTeam(currencyId) view returns (uint256) {
        return getVariable(currencyId.add(key));
    }

/////////////////////////////// CreateHero
 

    function createHero(uint256 currencyId, uint256 avatarId, uint256 amountToHero) public allowedHeroTeam(currencyId) returns (uint256) {
        require(
            amountToHero >= getHeroTeamSettingsValue(currencyId, HERO_TEAM_VARIABLE_MODIFIER_MIN_AMOUNT_IN_TOKEN),
            "HeroManager::createHero: amountToHero not enough"
        );
        require(
            amountToHero <= getHeroTeamSettingsValue(currencyId, HERO_TEAM_VARIABLE_MODIFIER_MAX_AMOUNT_IN_TOKEN),
            "HeroManager::createHero: amountToHero so big"
        );

        uint256 heroId = _createHero(
            currencyId, 
            amountToHero,
            avatarId,
            1, 
            1, 
            1, 
            1,
            1 days );

        uint256 amountToTreasury = getVariable(CREATION_COST);
        _takeMoneyFromSender(IERC20(_getHeroTeamAddress(currencyId)), heroId, amountToHero, amountToTreasury);

        uint256 amountToBurn = amountToTreasury.mul(getVariable(BURN_PART_IN_PPM_FOR_CREATION)) / 1000000;
        
        _burnPACTsFromTreasury(amountToBurn);

        return heroId;
    }

    function createHeroWithMulticast(uint256 currencyId, uint256 avatarId, uint256 amountToHero) public allowedHeroTeam(currencyId) returns (uint256) {
        (
            uint256 warriorAmount,
            uint256 farmerAmount,
            uint256 traderAmount,
            uint256 predictorAmount,
            uint256 multicastFeeInPact
        ) = _calculateMulticast(amountToHero);

        uint256 heroId = _createHero(
            currencyId,
            amountToHero,
            avatarId,
            warriorAmount.add(1),
            farmerAmount.add(1),
            traderAmount.add(1),
            predictorAmount.add(1),
            1 days //30 days
        );

        uint256 creationCost = getVariable(CREATION_COST);
        uint256 amountToTreasury = creationCost.add(multicastFeeInPact);

        _takeMoneyFromSender(IERC20(_getHeroTeamAddress(currencyId)), heroId, amountToHero, amountToTreasury);

        creationCost = creationCost.mul(getVariable(BURN_PART_IN_PPM_FOR_CREATION)).div(1000000);
        multicastFeeInPact = multicastFeeInPact.mul(getVariable(BURN_PART_IN_PPM_FOR_MULTICAST_FEE)).div(1000000);
        uint256 amountToBurn = creationCost.add(multicastFeeInPact);
        _burnPACTsFromTreasury(amountToBurn);

        return heroId;
    }

    function _createHero(
        uint256 currencyId,
        uint256 amountToHero,
        uint256 avatarId,
        uint256 warriorAmount,
        uint256 farmerAmount,
        uint256 traderAmount,
        uint256 predictorAmount,
        uint256 lockTime
    ) internal returns (uint256) {
                 
        

        uint256 heroId = IStorage(_HeroStorage).mint(
            msg.sender,
            [
                BLOCK_CREATED_AT,
                BLOCK_BALANCE_UPDATED_AT,
                TIME_ALLOW_BURN,
                
                HERO_TYPE,
                AMOUNT_CYRRENCY_TO_HERO,

                AVATAR,

                SKILL_WARRIOR,
                SKILL_FARMER,
                SKILL_TRADER, 
                SKILL_PREDICTOR
            ],
            [
                block.number,
                block.number,
                block.timestamp.add(lockTime),

                currencyId,
                amountToHero,
                avatarId,
                warriorAmount,
                farmerAmount,
                traderAmount,
                predictorAmount
            ]
        );

        return heroId;
    }

/////////////////////////////// MulticastingSettings

    function _calculateMulticast(
        uint256 multicastAmount
    ) internal view returns (
        uint256 warriorAmount,
        uint256 farmerAmount,
        uint256 traderAmount,
        uint256 predictorAmount,
        uint256 feeInPact
    ) {
        uint256 min;
        uint256 max;
        uint256 maxValueChance;
        (min, max, maxValueChance, feeInPact) = getMinMaxForMulticast(multicastAmount);

        uint256 totalAmount;
        uint256 seed = __computerSeed();
        if (seed % 100 <= maxValueChance) {
            totalAmount = max;
        } else {
            totalAmount = min.add(seed.mod(max.sub(min)));
        }

        warriorAmount = totalAmount.div(4);
        farmerAmount = totalAmount.div(4);
        traderAmount = totalAmount.div(4);
        predictorAmount = totalAmount.div(4) + totalAmount % 4;
    }

    function getMinMaxForMulticast(
        uint256 multicastAmount
    ) public pure returns (
        uint256 min,
        uint256 max,
        uint256 maxValueChance,
        uint256 feeInPact
    ) {
        if (multicastAmount <= 100e18) {
            min = 0;
            max = 1;
            maxValueChance = 50;
            feeInPact = 100e18;
            return(min , max, maxValueChance, feeInPact);
        }
        if (multicastAmount <= 200e18) {
            min = 1;
            max = 2;
            maxValueChance = 25;
            feeInPact = 200e18;
            return(min , max, maxValueChance, feeInPact);
        }
        if (multicastAmount <= 1000e18) {
            min = 2;
            max = 10;
            maxValueChance = 10;
            feeInPact = 500e18;
            return(min , max, maxValueChance, feeInPact);
        }
        if (multicastAmount <= 2000e18) {
            min = 10;
            max = 20;
            maxValueChance = 5;
            feeInPact = 1000e18;
            return(min , max, maxValueChance, feeInPact);
        }
        if (multicastAmount <= 10000e18) {
            min = 20;
            max = 100;
            maxValueChance = 2;
            feeInPact = 2000e18;
            return(min , max, maxValueChance, feeInPact);
        }

        min = 100;
        max = 200;
        maxValueChance = 2;
        feeInPact = 4000e18;
    }

    function __computerSeed() private view returns (uint256) {
        // from fomo3D
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)
            )));
        return seed;
    }


/////////////////////////////// UpdateHero

    function updateHero(
        uint256 heroId, 
        uint256 amountToHero
        ) public onlyHeroOwner(heroId) {

        uint256 currencyId =  IStorage(_HeroStorage).get(heroId, HERO_TYPE);
        uint256 currencyToHero =  IStorage(_HeroStorage).get(heroId, AMOUNT_CYRRENCY_TO_HERO);
       
        currencyToHero = currencyToHero.add(amountToHero);

        require(
            currencyToHero <= getHeroTeamSettingsValue(currencyId, HERO_TEAM_VARIABLE_MODIFIER_MAX_AMOUNT_IN_TOKEN),
            "HeroManager::createHero: amountToHero so big"
        );

        _takeMoneyFromSender(IERC20(_getHeroTeamAddress(currencyId)), heroId, amountToHero, 0);
        IStorage(_HeroStorage).add(heroId, AMOUNT_CYRRENCY_TO_HERO, amountToHero);

        }

/////////////////////////////// LevelUp

    function levelUp(
        uint256 heroId,
        uint256 warriorAmount,
        uint256 farmerAmount,
        uint256 traderAmount,
        uint256 predictorAmount,
        uint256 bonusDirectionKey
    ) public onlyHeroOwner(heroId) {
        // todo assert heroId has soul
        uint256 totalAmount = warriorAmount.add(farmerAmount).add(traderAmount).add(predictorAmount);
        _takeMoneyFromSenderOnlyToTreasury(totalAmount.mul(getVariable(LEVEL_UP_COST)));

        uint256 bonusAmount = calculateBonusForLevelUp(totalAmount);
        if (bonusAmount > 0) {
            if (bonusDirectionKey == SKILL_WARRIOR) {
                warriorAmount = warriorAmount.add(bonusAmount);
            }
            else if (bonusDirectionKey == SKILL_FARMER) {
                farmerAmount = farmerAmount.add(bonusAmount);
            }
            else if (bonusDirectionKey == SKILL_TRADER) {
                traderAmount = traderAmount.add(bonusAmount);
            }
            else if (bonusDirectionKey == SKILL_PREDICTOR) {
                predictorAmount = predictorAmount.add(bonusAmount);
            } else {
                warriorAmount = warriorAmount.add(bonusAmount.div(4));
                farmerAmount = farmerAmount.add(bonusAmount.div(4));
                traderAmount = traderAmount.add(bonusAmount.div(4));
                predictorAmount = predictorAmount.add(bonusAmount.div(4)).add(bonusAmount % 4);
            }
        }

        IStorage(_HeroStorage).add(heroId, SKILL_WARRIOR, warriorAmount);
        IStorage(_HeroStorage).add(heroId, SKILL_FARMER, farmerAmount);
        IStorage(_HeroStorage).add(heroId, SKILL_TRADER, traderAmount);
        IStorage(_HeroStorage).add(heroId, SKILL_PREDICTOR, predictorAmount);
    }

    function calculateBonusForLevelUp(
        uint256 totalAmount
    ) public pure returns (uint256) {
        if (totalAmount <= 10) {
            return 0;
        }
        if (totalAmount <= 50) {
            return 5;
        }
        if (totalAmount <= 100) {
            return 10;
        }
        if (totalAmount <= 500) {
            return 20;
        }
        if (totalAmount <= 2000) {
            return 50;
        }
        return 100;
    }

/////////////////////////////// RetireHero
    function retireHero(uint256 heroId) public onlyHeroOwner(heroId) {
        require(IStorage(_HeroStorage).get(heroId, TIME_ALLOW_BURN) < block.timestamp, "HeroManager::retireHero: TIME_ALLOW_BURN - not allowed yet");
        _sendAllMoneyByToken(IERC20(_getHeroTeamAddress(IStorage(_HeroStorage).get(heroId, HERO_TYPE))), heroId);
        IStorage(_HeroStorage).burn(heroId);
    }

/////////////////////////////// IncentivesPool

    function sendAllPACTsFromTreasuryToIncentivesPool() public {
        require(_incentivesPool != address(0), '');
        _sendPACTsFromTreasury(getTreasurySelfBalance(), _incentivesPool);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "../vendor/interfaces/IERC20.sol";

abstract contract HeroTeam {


    struct HeroTeamPool {
        IERC20 token;         
        bool _isHeroTeams;      
    }

    HeroTeamPool[] public allowedHeroTeams;


    //address[] public existingHeroTeams;
    uint256 public lastHeroTeamId;

    function _enableHeroTeam(IERC20 currency) internal returns (uint256) {
        allowedHeroTeams.push(HeroTeamPool({
            token: currency,
            _isHeroTeams: true
        }));
    }

    function _getHeroTeamAddress (uint id) internal view returns(address){
        return address(allowedHeroTeams[id].token);
    }

    function _disableHeroTeam(uint id) internal {
        allowedHeroTeams[id]._isHeroTeams = false;
    }

    // function getEnabledHeroTeams() public view returns (address[] memory) {
    //     address[] memory enabledHeroTeams;

    //     for (uint256 i = 0; i < existingHeroTeams.length; ++i) {
    //         address currentCurrency = existingHeroTeams[i];
    //         if (allowedHeroTeams[currentCurrency] != 0) {
    //              //enabledHeroTeams.push(currentCurrency);
    //         }
    //     }

    //     return enabledHeroTeams;
    // }

    function poolLength() external view returns (uint256) {
        return allowedHeroTeams.length;
    }

    modifier allowedHeroTeam(uint id) {
        require(allowedHeroTeams[id]._isHeroTeams != false, 'HeroTeamsRegistry :: Address is already');
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../vendor/interfaces/IERC20.sol";
import "../vendor/libraries/math/SafeMath.sol";
import "../vendor/libraries/transfer/SafeERC20.sol";

contract Treasury {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _PACT;
    function _initialize(IERC20 PACT_) internal {
        _PACT = PACT_;
    }
    
    uint256 private treasurySelfBalance;
    // ERC20 address => tokenId => balance
    mapping (address => mapping (uint256 => uint256)) public getTokenBalance;


    function __addTokenBalance(address erc20Address, uint256 tokenId, uint256 amount) private {
        getTokenBalance[erc20Address][tokenId] = getTokenBalance[erc20Address][tokenId].add(amount);
    }

    function __subTokenBalance(address erc20Address, uint256 tokenId, uint256 amount) private {
        getTokenBalance[erc20Address][tokenId] = getTokenBalance[erc20Address][tokenId].sub(amount, "Treasury:_subTokenBalance - not enough balance");
    }

    // PACTs Balance
    
    function getTreasurySelfBalance() public view returns(uint){
        return treasurySelfBalance;
    }

    function __addTreasurySelfBalance(uint256 amount) private {
        treasurySelfBalance = treasurySelfBalance.add(amount);
    }

    function __subTreasurySelfBalance(uint256 amount) private {
        treasurySelfBalance = treasurySelfBalance.sub(amount);
    }
    
    function _takeMoneyFromSender(
        IERC20 currency,
        uint256 tokenId,
        uint256 amountToTokenBalance,
        uint256 amountInPactToTreasury
    ) internal {
        if (address(currency) == address(_PACT)) {
            currency.safeTransferFrom(address(msg.sender), amountInPactToTreasury.add(amountToTokenBalance)); //* (10** uint256(_PACT.decimals())));
        } else {
            currency.safeTransferFrom(address(msg.sender), amountToTokenBalance); //* (10** uint256(currency.decimals())));
            _PACT.safeTransferFrom(address(msg.sender), amountInPactToTreasury); //* (10** uint256(_PACT.decimals())));
        }

        __addTokenBalance(address(currency), tokenId, amountToTokenBalance);
        __addTreasurySelfBalance(amountInPactToTreasury);
    }

    function _takeMoneyFromSenderOnlyToTreasury(
        uint256 amountInPactToTreasury
    ) internal {
        _PACT.safeTransferFrom(address(msg.sender), amountInPactToTreasury);

        __addTreasurySelfBalance(amountInPactToTreasury);
    }

    function _sendAllMoneyByToken(
        IERC20 currency,
        uint256 tokenId
    ) internal {
        uint256 amount = getTokenBalance[address(currency)][tokenId];
        __subTokenBalance(address(currency), tokenId, amount);
        currency.safeTransfer(address(msg.sender), amount );
    }

    function _sendPACTsFromTreasury(uint256 amount, address account) internal {
        __subTreasurySelfBalance(amount);
        _PACT.safeTransfer(account, amount );
    }

    function _burnPACTsFromTreasury(uint256 amount) internal {
        __subTreasurySelfBalance(amount);
        _PACT.safeBurn(amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IBalancesLikeERC1155
{
    event TransferSingle(uint256 indexed tokenIdFrom, uint256 indexed tokenIdTo, uint256 key, uint256 value);

    function burn(uint256 tokenId) external ;
    function mint(address to, uint256[10] memory keys, uint256[10] memory amounts) external  returns (uint256);

    function get(uint256 tokenId, uint256 key) view external  returns(uint256 balance);
    function getListBalancesForSingleId(uint256 tokenId, uint256[] memory keys) view external  returns (uint256[] memory);
    //function getListBalancesForManyIds(uint256[] memory tokenIds, uint256[] memory keys) view external  returns (uint256[][] memory);

    function set(uint256 tokenId, uint256 key, uint256 value) external ;
    function sub(uint256 tokenId, uint256 key, uint256 value) external ;
    function add(uint256 tokenId, uint256 key, uint256 value) external ;

    function setMany(uint256 tokenId, uint256[10] memory keys, uint256[10] memory values) external ;
    function transferSingle(uint256 tokenIdFrom, uint256 tokenIdTo, uint256 key, uint256 value) external ;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IBalancesLikeERC1155.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";

interface IStorage is IBalancesLikeERC1155, IERC721, IERC721Metadata, IERC721Enumerable{

   function enterTheDungeon(uint256 heroId) external;

   function leaveTheDungeon(uint256 heroId) external;
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '../GSN/Context.sol';

// Copied from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initialize() internal { 
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TRANSFER_FAILED");
    }

    function safeBurn(IERC20 token, uint256 amount) internal {
        // bytes4(keccak256(bytes('burn(uint256)')));
        //require(false, bytes4(keccak256(bytes('burn(uint256)')))); // todo fix it to correct value
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(bytes4(keccak256(bytes('burn(uint256)'))), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: BURN_FAILED");
    }

    function safeApprove(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: APPROVE_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TRANSFER_FROM_FAILED");
    }
}

