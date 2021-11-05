// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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
    constructor(uint256 presaleStart , uint256 presaleEnd, address ceo, address coo,address cfo,address inv1,address inv2) 
    Presale(presaleStart,presaleEnd,ceo,coo,cfo,inv1,inv2) {
        
		/** only test purposes,in the mainet prices and supply may be different**/
        Kits[COMMON_KIT] = Kit(13000000000000, 30);
        Kits[UNCOMMON_KIT] = Kit(16500000000000, 30);
        Kits[RARE_KIT] = Kit(25000000000000, 30);
        Kits[UNKNOWN_DEPOSIT] = Kit(218000000000000, 30);
        Kits[LOST_MAP] = Kit(1200000000000, 30);
        Kits[GOLDEN_MAP_CHEST] = Kit(14000000000000, 30);
        Kits[GOLDEN_DEPOSIT_CHEST] = Kit(10000000000000, 30);
        Kits[WOOD_MAP_CHEST] = Kit(1060000000000000, 30);
        Kits[DEPOSIT_WOOD_CHEST] = Kit(107000000000000, 30);
    }

	/**
     * @dev use this function to buy item from the presale
     */
    function buyItem(uint8 kitId, uint8 _amount) public presaleInProgress payable {
        require(Kits[kitId].supply > _amount, "the _amount must not be greater than the supply");
        uint256 value = msg.value;
        uint256 kitPrice = Kits[kitId].price;
        require(value >= kitPrice * _amount, "no enought money sended");
        uint256 itemsWithUser = Ownerkits[kitId][msg.sender];

        uint256 remainingItems = MAX_ITEMS_BY_USER - itemsWithUser;


        require(_amount <= remainingItems ,"not enought remaining items");

        value -= kitPrice * _amount;

        if (value > 0) {

            payable(msg.sender).transfer(value);
			
        }

        Kits[kitId].supply -= _amount;
        Ownerkits[kitId][msg.sender] += _amount;

        emit BuyKit(msg.sender, kitId, _amount);
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