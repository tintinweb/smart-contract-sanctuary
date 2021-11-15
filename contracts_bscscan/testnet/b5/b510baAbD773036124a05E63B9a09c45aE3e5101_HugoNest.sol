// SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "../utils/ProxyOwnable.sol";
import "../proxy/Initializable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/INFT.sol";
import "../interfaces/IPancake.sol";
import "./HugoNestStorage.sol";


contract HugoNest is ProxyOwnable, Initializable, HugoNestStorage {
    event NewBeneficiary(address indexed new_beneficiary);
    event NewPancake(address indexed new_pancake);
    event NewHugoEggDiscount(uint256 indexed new_discount);
    event VaultDeposit(address indexed user, uint256 indexed amount, VaultLevel indexed new_vault_level);
    event VaultWithdraw(address indexed user, uint256 indexed amount, VaultLevel indexed new_vault_level);
    event VaultIncubatorReward(address indexed user, IncubatorLevel indexed incubator_level);
    event VaultConsumableReward(address indexed user, ConsumableLevel indexed consumable_level);
    event ConsumableUsed(address indexed user, uint256 indexed egg_id, uint256 indexed consumable_id, ConsumableLevel consumable_level);
    event IncubatorUsed(address indexed user, uint256 indexed egg_id, uint256 indexed incubator_id, IncubatorLevel incubator_level);
    event EggsPurchase(address indexed user, uint8[] eggs_prices_ids, CurrencyType indexed cur_type, uint256 indexed total_price);
    event EggHatched(address indexed user, uint256[] seed, uint256 indexed egg_id);

    function initialize(
        address _nft,
        address _beneficiary,
        address _pancake,
        uint16[] memory _eggs_prices_usd,
        address _wbnb,
        address _busd,
        uint16 _hugo_egg_discount
    ) public initializer {
        NFT = _nft;
        beneficiary = _beneficiary;
        Pancake = _pancake;
        eggs_prices_usd = _eggs_prices_usd;
        WBNB = _wbnb;
        BUSD = _busd;
        hugo_egg_discount = _hugo_egg_discount;
        _setOwner(msg.sender);
    }

    function setBeneficiary(address new_beneficiary) external onlyOwner {
        beneficiary = new_beneficiary;
        emit NewBeneficiary(new_beneficiary);
    }

    function setPancake(address new_pancake) external onlyOwner {
        Pancake = new_pancake;
        emit NewPancake(new_pancake);
    }

    function setHugoEggDiscount(uint16 new_discount) external onlyOwner {
        require (new_discount <= MAX_DISCOUNT, "HUGO_NEST::setHugoEggDiscount:bad discount");
        hugo_egg_discount = new_discount;
        emit NewHugoEggDiscount(new_discount);
    }

    function _calculateVaultLevel(uint256 amount) internal pure returns (VaultLevel) {
        uint hugo_decimals = 10**9;

        if (amount >= LVL3_INCUBATOR * hugo_decimals) {
            return VaultLevel.LVL_3;
        } else if (amount >= LVL2_INCUBATOR * hugo_decimals) {
            return VaultLevel.LVL_2;
        } else if (amount >= LVL1_INCUBATOR * hugo_decimals) {
            return VaultLevel.LVL_1;
        } else {
            return VaultLevel.LVL_0;
        }
    }

    function vaultDeposit(uint256 amount) external virtual onlyEOA {
        // we calculate delta, because HUGO has on-transfer fee
        uint256 balance_before = IERC20(HUGO).balanceOf(address(this));
        IERC20(HUGO).transferFrom(msg.sender, address(this), amount);
        uint256 balance_after = IERC20(HUGO).balanceOf(address(this));

        uint256 tokens_sent = balance_after - balance_before;

        UserData storage _user_data = user_data[msg.sender];

        _user_data.vault_staked_tokens += tokens_sent;
        _user_data.vault_level = _calculateVaultLevel(_user_data.vault_staked_tokens);
        _user_data.vault_reward_at = uint32(block.timestamp + VAULT_RELOAD_TIME);

        emit VaultDeposit(msg.sender, tokens_sent, _user_data.vault_level);
    }

    function vaultWithdraw(uint256 amount) external onlyEOA {
        require (user_data[msg.sender].vault_staked_tokens >= amount, 'HUGO_NEST::vaultWithdraw: amount exceeds deposit');

        IERC20(HUGO).transfer(msg.sender, amount);

        UserData storage _user_data = user_data[msg.sender];

        _user_data.vault_staked_tokens -= amount;
        _user_data.vault_level = _calculateVaultLevel(_user_data.vault_staked_tokens);

        emit VaultWithdraw(msg.sender, amount, _user_data.vault_level);
    }

    function getVaultReward(RewardType _type) external {
        UserData storage _user_data = user_data[msg.sender];

        require (!(_user_data.vault_level == VaultLevel.LVL_0), 'HUGO_NEST::getVaultReward: vault is level 0');
        require (_user_data.vault_reward_at <= block.timestamp, 'HUGO_NEST::getVaultReward: vault is reloading');

        VaultLevel vault_lvl = _user_data.vault_level;
        if (_type == RewardType.INCUBATOR) {
            // check if user already got incubator of required lvl
            for (uint i = 0; i < _user_data.incubators.length; i++) {
                Incubator memory _incubator = _user_data.incubators[i];
                if ((vault_lvl == VaultLevel.LVL_1 && _incubator.lvl == IncubatorLevel.LVL_1) ||
                    (vault_lvl == VaultLevel.LVL_2 && _incubator.lvl == IncubatorLevel.LVL_2) ||
                    (vault_lvl == VaultLevel.LVL_3 && _incubator.lvl == IncubatorLevel.LVL_3)) {
                    revert ('HUGO_NEST::getVaultReward: incubator already unlocked');
                }
            }
            // ok, give incubator to user
            Incubator memory new_incubator;
            if (vault_lvl == VaultLevel.LVL_1) {
                new_incubator = Incubator(IncubatorLevel.LVL_1, INCUBATOR_MAX_USAGES);
            } else if (vault_lvl == VaultLevel.LVL_2) {
                new_incubator = Incubator(IncubatorLevel.LVL_2, INCUBATOR_MAX_USAGES);
            } else {
                new_incubator = Incubator(IncubatorLevel.LVL_3, INCUBATOR_MAX_USAGES);
            }
            _user_data.incubators.push(new_incubator);
            emit VaultIncubatorReward(msg.sender, new_incubator.lvl);
        } else {
            ConsumableLevel _level;
            if (vault_lvl == VaultLevel.LVL_1) {
                _level = ConsumableLevel.LVL_1;
            } else if (vault_lvl == VaultLevel.LVL_2) {
                _level = ConsumableLevel.LVL_2;
            } else {
                _level = ConsumableLevel.LVL_3;
            }
            _user_data.consumables.push(_level);
            emit VaultConsumableReward(msg.sender, _level);
        }

    }

    function remainingEggs() public view returns (uint256) {
        return MAX_NFT_NUMBER - INFT(NFT).generatedNFTsAmount() - eggs_purchased;
    }

    // check if provided seed is not minted yet
    // works for full and correct seeds
    function checkNFTAvailable(uint256[] memory seed) public view returns (bool) {
        return INFT(NFT).isUsedSeed(seed);
    }

    // accepts partly empty seed
    // try fill missing parts and check if it could be used
    function checkSeedAvailable(uint256[] memory seed) public view returns (bool seed_available) {
        (seed, seed_available) = _fillSeedWithRandom(seed);
    }

    function calcPriceInCurrencies(uint256 usd) public view returns (uint256 bnb_price, uint256 hugo_price) {
        // usd is num without decimals, e.g 35$ = 35 here
        // we use busd for calculating usd prices
        address[] memory _path = new address[](3);
        _path[0] = HUGO;
        _path[1] = WBNB;
        _path[2] = BUSD;
        uint[] memory prices_arr = IPancake(Pancake).getAmountsIn(usd * 10**18, _path); // busd has 18 decimals
        bnb_price = prices_arr[1];
        hugo_price = prices_arr[0];
        // 10% discount by default
        hugo_price = (hugo_price * hugo_egg_discount) / MAX_DISCOUNT;
    }

    // eggs_to_buy - array of eggs user wants to buy
    function buyEggs(uint8[] calldata eggs_to_buy, CurrencyType cur_type) external payable onlyEOA {
        require (eggs_to_buy.length <= remainingEggs(), 'HUGO_NEST::buyEggs: eggs limit reached');
        uint256 total_price;
        for (uint i = 0; i < eggs_to_buy.length; i++) {
            require (eggs_to_buy[i] - 1 < eggs_prices_usd.length, 'HUGO_NEST::buyEggs:bad egg price id');
            total_price += eggs_prices_usd[eggs_to_buy[i] - 1];
        }

        (uint256 bnb_price, uint256 hugo_price) = calcPriceInCurrencies(total_price);
        if (cur_type == CurrencyType.BNB) {
            require (msg.value >= bnb_price, 'HUGO_NEST::buyEggs:low BNB sent');

            payable(beneficiary).transfer(bnb_price);
            if (msg.value > bnb_price) {
                // send back extra value
                payable(msg.sender).transfer(msg.value - bnb_price);
            }
            emit EggsPurchase(msg.sender, eggs_to_buy, cur_type, bnb_price);
        } else {
            IERC20(HUGO).transferFrom(msg.sender, beneficiary, hugo_price);
            emit EggsPurchase(msg.sender, eggs_to_buy, cur_type, hugo_price);
        }

        eggs_purchased += eggs_to_buy.length;
        // user 1st purchase, grant lvl 0 incubator
        if (user_data[msg.sender].incubators.length == 0) {
            // unlimited usages for lvl 0 incubator
            user_data[msg.sender].incubators.push(Incubator(IncubatorLevel.LVL_0, 0));
        }
        for (uint i = 0; i < eggs_to_buy.length; i++) {
            user_data[msg.sender].eggs.push(Egg(eggs_to_buy[i], IncubatorLevel.NONE, ConsumableLevel.NONE, 0));
        }
    }

    function _fillSeedWithRandom(uint256[] memory seed) internal view returns (uint256[] memory, bool seed_found) {
        // copy seed to avoid modifying given one
        uint256[] memory new_seed = seed;

        for (uint rand_seed = 0; rand_seed < 1000; rand_seed++) {
            for (uint j = 0; j < new_seed.length; j++) {
                // skip chosen attrs
                if (new_seed[j] > 0) {
                    continue;
                }
                uint256 max_trait = _maxTraitForNFTPart(j);
                // get random uint for every part of nft based on block and rand seed
                uint256 random = uint256(keccak256(abi.encode(j, rand_seed, blockhash(block.number)))) % max_trait + 1;
                new_seed[j] = random;
            }

            if (checkNFTAvailable(new_seed)) {
                seed_found = true;
                break;
            }
        }

        return (new_seed, seed_found);
    }

    function _maxTraitForNFTPart(uint256 _nft_part) internal view returns (uint256) {
        INFT.Trait[] memory _traits = INFT(NFT).getTraitsOfAttribute(_nft_part);
        return _traits.length;
    }

    function _checkTraitAllowed(uint256[] memory seed, NFTPart part) internal view returns (bool allowed) {
        uint256 idx = uint256(part);
        return seed[idx] > 0 && seed[idx] <= _maxTraitForNFTPart(idx);
    }

    // user should provide full seed with protected parts equal to 0 (including body)
    function hatchEgg(uint256 egg_id, uint256[] calldata seed, string calldata name, string calldata description) external onlyEOA {
        UserData storage _user_data = user_data[msg.sender];
        require (egg_id < _user_data.eggs.length, "HUGO_NEST::hatchEgg:bad egg_id");
        require (seed.length == INFT(NFT).minAttributesAmount(), "HUGO_NEST::hatchEgg:bad seed length");

        Egg memory _egg = _user_data.eggs[egg_id];

        // body is set when egg is purchased
        require (seed[uint256(NFTPart.BODY)] == 0, "HUGO_NEST::hatchEgg:body attribute cant be chosen");

        // check only allowed parts are set
        // we dont check anything for LVL3 consumable, because user can choose all parts
        if (_egg.consumable_lvl == ConsumableLevel.NONE) {
            // all parts are random when no consumable
            for (uint i = 0; i < seed.length; i++) {
                require(seed[i] == 0, "HUGO_NEST::hatchEgg:attribute not allowed");
            }
        } else if (_egg.consumable_lvl == ConsumableLevel.LVL_1) {
            // some parts should be chosen
            require (_checkTraitAllowed(seed, NFTPart.BACKGROUND), "HUGO_NEST::hatchEgg:bad attribute value");
            require (_checkTraitAllowed(seed, NFTPart.CLOTHING), "HUGO_NEST::hatchEgg:bad attribute value");
            require (_checkTraitAllowed(seed, NFTPart.HEADWEAR), "HUGO_NEST::hatchEgg:bad attribute value");

            // some are not
            require(seed[uint256(NFTPart.ACCESSORIES)] == 0, "HUGO_NEST::hatchEgg:attribute not allowed");
            require(seed[uint256(NFTPart.GLASSES)] == 0, "HUGO_NEST::hatchEgg:attribute not allowed");
        } else if (_egg.consumable_lvl == ConsumableLevel.LVL_2) {
            // some parts should be chosen
            require (_checkTraitAllowed(seed, NFTPart.BACKGROUND), "HUGO_NEST::hatchEgg:bad attribute value");
            require (_checkTraitAllowed(seed, NFTPart.CLOTHING), "HUGO_NEST::hatchEgg:bad attribute value");
            require (_checkTraitAllowed(seed, NFTPart.HEADWEAR), "HUGO_NEST::hatchEgg:bad attribute value");
            require (_checkTraitAllowed(seed, NFTPart.GLASSES), "HUGO_NEST::hatchEgg:bad attribute value");

            require (seed[uint256(NFTPart.ACCESSORIES)] == 0, "HUGO_NEST::hatchEgg:attribute not allowed");
        } else if (_egg.consumable_lvl == ConsumableLevel.LVL_3) {
            // glasses is last part
            for (uint i = 0; i < seed.length; i++) {
                if (i == uint256(NFTPart.BODY)) {
                    // body == 0
                    continue;
                }
                require (seed[i] > 0 && seed[i] <= _maxTraitForNFTPart(i), "HUGO_NEST::hatchEgg:bad attribute value");
            }
        }

        require (_egg.ready_at <= block.timestamp, "HUGO_NEST::hatchEgg:egg is not ready for hatching");

        // add body type
        uint256[] memory new_seed = seed;
        new_seed[uint256(NFTPart.BODY)] = _egg.body_type;

        if (_egg.consumable_lvl != ConsumableLevel.LVL_3) {
            // now we know that only allowed parts of seed are set, add other
            // try to create random nft 1000 times, fail otherwise
            bool seed_found;
            (new_seed, seed_found) = _fillSeedWithRandom(new_seed);
            if (!seed_found) {
                revert("HUGO_NEST::hatchEgg:cant hatch egg with provided seed");
            }
        }

        require (checkNFTAvailable(new_seed), "HUGO_NEST::hatchEgg:hatchEgg:cant hatch egg with provided seed");

        INFT(NFT).mint(msg.sender, seed, name, description);

        emit EggHatched(msg.sender, seed, egg_id);
    }

    function useConsumable(uint256 egg_id, uint256 consumable_id) external onlyEOA {
        UserData storage _user_data = user_data[msg.sender];

        require (egg_id < _user_data.eggs.length, 'HUGO_NEST::useConsumable: bad egg_id');
        require (consumable_id < _user_data.consumables.length, 'HUGO_NEST::useConsumable: bad consumable_id');
        require (_user_data.eggs[egg_id].consumable_lvl == ConsumableLevel.NONE, 'HUGO_NEST::useConsumable: consumable is set already');

        // set consumable
        _user_data.eggs[egg_id].consumable_lvl = _user_data.consumables[consumable_id];
        // remove used consumable from user
        // replace current elem by last elem
        _user_data.consumables[consumable_id] = _user_data.consumables[_user_data.consumables.length - 1];
        // delete last elem
        _user_data.consumables.pop();

        emit ConsumableUsed(msg.sender, egg_id, consumable_id, _user_data.eggs[egg_id].consumable_lvl);
    }

    function _getIncubatorHatchTime(IncubatorLevel _level) internal pure virtual returns (uint32) {
        if (_level == IncubatorLevel.LVL_3) {
            return 3 days;
        } else if (_level == IncubatorLevel.LVL_2) {
            return 4 days;
        } else if (_level == IncubatorLevel.LVL_1) {
            return 5 days;
        } else {
            return 10 days;
        }
    }

    function useIncubator(uint256 egg_id, uint256 incubator_id) external onlyEOA {
        UserData storage _user_data = user_data[msg.sender];

        require (egg_id < _user_data.eggs.length, 'HUGO_NEST::useIncubator: bad egg_id');
        require (incubator_id < _user_data.incubators.length, 'HUGO_NEST::useIncubator: bad incubator_id');
        require (_user_data.eggs[egg_id].incubator_lvl == IncubatorLevel.NONE, 'HUGO_NEST::useIncubator: incubator is set already');
        require (_user_data.incubators[incubator_id].remaining_usages > 0, 'HUGO_NEST::useIncubator: incubator exhausted');

        // set incubator
        _user_data.eggs[egg_id].incubator_lvl = _user_data.incubators[incubator_id].lvl;
        // set hatch time based on incubator lvl
        _user_data.eggs[egg_id].ready_at = uint32(block.timestamp) + _getIncubatorHatchTime(_user_data.eggs[egg_id].incubator_lvl);
        // lower remaining usages of incubator
        if (_user_data.incubators[incubator_id].lvl != IncubatorLevel.LVL_0) {
            _user_data.incubators[incubator_id].remaining_usages -= 1;
        }

        emit IncubatorUsed(msg.sender, egg_id, incubator_id, _user_data.eggs[egg_id].incubator_lvl);
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "HUGO_NEST::onlyEOA: only external accounts allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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
abstract contract ProxyOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _setOwner(address new_owner) internal {
        emit OwnershipTransferred(_owner, new_owner);
        _owner = new_owner;

    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
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


interface INFT {
    struct Trait {
        uint256 attributeId;
        uint256 traitId;
        string name;
    }
    function minAttributesAmount() external view returns (uint256);
    function generatedNFTsAmount() external view returns (uint256);
    function isUsedSeed(uint256[] calldata seed) external view returns (bool);
    function getTraitsOfAttribute(uint256 attributeId)
    external
    view
    returns (Trait[] memory);
    function mint(
        address to,
        uint256[] calldata seed,
        string calldata name,
        string calldata description
    )
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IPancake {
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


contract HugoNestStorage {
    enum IncubatorLevel { NONE, LVL_0, LVL_1, LVL_2, LVL_3 }
    enum ConsumableLevel { NONE, LVL_1, LVL_2, LVL_3 }
    enum VaultLevel { LVL_0, LVL_1, LVL_2, LVL_3 }
    enum CurrencyType { HUGO, BNB }
    enum RewardType { CONSUMABLE, INCUBATOR }
    // ordering is important!!! dont change
    enum NFTPart { BACKGROUND, BODY, CLOTHING, ACCESSORIES, HEADWEAR, GLASSES }

    // hugo nft token
    address public NFT;

    // hugo token
    address public HUGO;

    // address receiver of bnb/hugo tokens from shop
    address public beneficiary;

    // pancakeswap router
    address public Pancake;

    // address of busd token, needed for price calculation on pancake
    address public BUSD;

    // address of wbnb token, needed for price calculation on pancake
    address public WBNB;

    uint256 public eggs_purchased;

    // 1000 means no discount, 10% discount by default
    uint16 public hugo_egg_discount;

    uint16 constant public MAX_DISCOUNT = 1000;

    uint256 constant public MAX_NFT_NUMBER = 10000;

    uint32 constant public LVL3_INCUBATOR = 250000;

    uint32 constant public LVL2_INCUBATOR = 100000;

    uint32 constant public LVL1_INCUBATOR = 50000;

    uint8 constant public INCUBATOR_MAX_USAGES = 5;

    uint32 constant public VAULT_RELOAD_TIME = 5 days;

    // idx + 1 == body trait (all attr traits start from 1)
    uint16[] eggs_prices_usd;

    struct Egg {
        uint8 body_type;
        // 0 means no incubator is used
        IncubatorLevel incubator_lvl;
        // 0 means no consumable is used
        ConsumableLevel consumable_lvl;
        uint32 ready_at;
    }

    struct Incubator {
        IncubatorLevel lvl;
        uint8 remaining_usages;
    }

    struct UserData {
        // tokens staked in vault
        uint256 vault_staked_tokens;
        // lvl of vault based on staked tokens
        VaultLevel vault_level;
        // time when reward could be obtained from vault
        uint32 vault_reward_at;

        Egg[] eggs;
        // every element is a consumable with value == lvl of consumable
        ConsumableLevel[] consumables;
        Incubator[] incubators;
    }

    mapping(address => UserData) public user_data;
}

