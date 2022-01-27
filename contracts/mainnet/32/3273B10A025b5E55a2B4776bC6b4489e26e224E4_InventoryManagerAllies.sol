// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManagerAllies {

    address impl_;
    address public manager;

    address public shInv;
    address public ogInv;
    address public mgInv;
    address public rgInv;

    mapping(uint8 => address) public bodies;

    function setAddresses(address sh_, address og_, address mg_, address rg_) external {
        require(msg.sender == manager, "not manager");
        shInv = sh_;
        ogInv = og_;
        mgInv = mg_;
        rgInv = rg_;
    }

    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory) {
        if (class_ == 1) return InventoryManagerAllies(shInv).getTokenURI(id_, class_, level_, modF_, skillCredits_, details_);
        if (class_ == 2) return InventoryManagerAllies(ogInv).getTokenURI(id_, class_, level_, modF_, skillCredits_, details_);
    }
   
   
}