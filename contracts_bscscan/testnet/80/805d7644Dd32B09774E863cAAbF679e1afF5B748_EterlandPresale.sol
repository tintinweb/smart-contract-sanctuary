// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Presale.sol";

/**
 * @title Eterland presale
 * @dev This contract will handle first eterland presale
 */
contract EterlandPresale is Presale {
    /**
     * @dev Represent the keys for items in the presale
     */
    uint8 internal constant COMMON_KIT = 0;
    uint8 internal constant RARE_KIT = 2;
    uint8 internal constant UNCOMMON_KIT = 4;
    uint8 internal constant UNKNOWN_DEPOSIT = 6;
    uint8 internal constant LOST_MAP = 8;
    uint8 internal constant GOLDEN_MAP_CHEST = 10;
    uint8 internal constant WOOD_MAP_CHEST = 12;
    uint8 internal constant GOLDEN_DEPOSIT_CHEST = 14;
    uint8 internal constant DEPOSIT_WOOD_CHEST = 16;

    struct Kit {
        uint256 price;
        uint256 supply;
    }
    /**
     * @dev Stores item price and supply
     */
    mapping(uint256 => Kit) public Kits;

    /**
     * @dev Stores owner for the items
     */
    mapping(uint8 => mapping(address => uint8)) public Ownerkits;

    /**
     * @dev Represent max items of same type for every address
     */
    uint256 public constant MAX_ITEMS_BY_USER = 5;

    /**
     * @dev Event fired when a item is sold
     */
    event BuyKit(address kitOwner, uint8 kitId, uint8 _amount);

    /**
     * @dev Set team members, kit prices,supply and presale date
     */
    constructor(
        uint256 presaleStart,
        uint256 presaleEnd,
        address ceo,
        address coo,
        address cfo,
        address inv1,
        address inv2
    ) Presale(presaleStart, presaleEnd, ceo, coo, cfo, inv1, inv2) {
        /** only test purposes,in the mainet prices and supply may be different**/
        Kits[COMMON_KIT] = Kit(45716375605741974, 1);
        Kits[UNCOMMON_KIT] = Kit(121875047607440470, 2000);
        Kits[RARE_KIT] = Kit(182812571411160720, 2000);
        Kits[UNKNOWN_DEPOSIT] = Kit(1523879186858066000, 200);
        Kits[LOST_MAP] = Kit(1067089437338983900, 400);
        Kits[GOLDEN_MAP_CHEST] = Kit(761719047546503000, 1000);
        Kits[GOLDEN_DEPOSIT_CHEST] = Kit(761719047546503000, 1000);
        Kits[WOOD_MAP_CHEST] = Kit(380749314651233630, 1000);
        Kits[DEPOSIT_WOOD_CHEST] = Kit(114240453306118720, 1000);
    }

    /**
     * @dev use this function to buy item from the presale
     */
    function buyItem(uint8 kitId, uint8 _amount)
        public
        payable
        presaleInProgress
    {
        require(
            Kits[kitId].supply >= _amount,
            "the _amount must not be greater than the supply"
        );
        uint256 value = msg.value;
        uint256 kitPrice = Kits[kitId].price;
        require(value >= kitPrice * _amount, "no enought money sended");
        uint256 itemsWithUser = Ownerkits[kitId][msg.sender];

        uint256 remainingItems = MAX_ITEMS_BY_USER - itemsWithUser;

        require(_amount <= remainingItems, "not enought remaining items");

        Kits[kitId].supply -= _amount;
        Ownerkits[kitId][msg.sender] += _amount;

        emit BuyKit(msg.sender, kitId, _amount);
    }

    /**
     * @dev this function is used by team members to add kits of lotteries
     */
    function teamAddItem(
        address _beneficiary,
        uint8 _kitId,
        uint8 _amount
    ) public onlyTeamMember presaleInProgress {
        uint256 itemsWithUser = Ownerkits[_kitId][_beneficiary];
        uint256 remainingItems = MAX_ITEMS_BY_USER - itemsWithUser;

        require(_amount <= remainingItems, "not enought remaining items");

        Ownerkits[_kitId][_beneficiary] += _amount;

        emit BuyKit(_beneficiary, _kitId, _amount);
    }

    /**
     * @dev getter for kit price
     */
    function getKitPrice(uint256 kitId) external view returns (uint256) {
        return Kits[kitId].price;
    }

    /**
     * @dev getter for remaining kit supply
     */
    function getSupply(uint8 kitId) external view returns (uint256 c) {
        c = Kits[kitId].supply;
    }

    /**
     * @dev get count of kits that the address owns
     */
    function getOwnerkit(uint8 kitId, address user)
        external
        view
        returns (uint256)
    {
        return Ownerkits[kitId][user];
    }
}