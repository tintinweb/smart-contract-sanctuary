/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

contract MyPropriety {

    event Sale(uint256 id, address assignor, address assignee, uint256 date);

    enum StateProperty {
        ON_SALE, 
        NOT_FOR_SALE,
        SOLD
    }

    struct Propriety {
        uint256 id;
        address  owner;
        uint256 lat;
        uint256 long;
        uint256 price;
        StateProperty state;
    }

    address private agentAgree;
    mapping(uint256 => Propriety) public proprieties;

    uint256[] private listProprieties;

    constructor() {
        agentAgree = msg.sender; 
    }

     modifier isAgentAgree() {
        require(msg.sender == agentAgree);
        _;
    }

    modifier isOwner(uint256 _id) {
        require(proprieties[_id].owner == msg.sender);
        _;
    }

    function addPropriety(
        uint256 _id,
        address payable _owner,
        uint256 _lat,
        uint256 _long
        ) external isAgentAgree {
            proprieties[_id] = Propriety(_id, _owner, _lat, _long, 0, StateProperty.NOT_FOR_SALE);
            listProprieties.push(_id);
    }

    function indexPropriety(uint256 _index) external view returns(Propriety memory) {
        require(_index < listProprieties.length, 'No index here :(');
        uint256 id = listProprieties[_index];
        return proprieties[id];
    }

    function totalPropriety() external view returns (uint256) {
        return listProprieties.length;
    }

    function _sellingPropriety(
        uint256 _id,
        uint256 _price
        ) external isOwner(_id) {
            proprieties[_id].price = _price;
            proprieties[_id].state = StateProperty.ON_SALE;

    }

    function buyingPropriety(
        uint256 _id
    ) payable external {
            require(proprieties[_id].state == StateProperty.ON_SALE);
            require(proprieties[_id].price > 0);
            require(proprieties[_id].price == msg.value);

            payable(proprieties[_id].owner).transfer(msg.value);
            
            emit Sale(_id, proprieties[_id].owner, msg.sender, block.timestamp);

            changeOwner(_id, payable(msg.sender));
    }

    function changeOwner(uint256 _id, 
    address payable _assignee
    ) private {
        require(_assignee != address(0x0));
        require(_id == 0);

        proprieties[_id].owner = _assignee;
        proprieties[_id].state = StateProperty.SOLD;
        proprieties[_id].price = 0;
    }

    function officialPropriety(
            uint256 _id
            ) payable external isOwner(_id) {
                require(proprieties[_id].state == StateProperty.SOLD);
        
                payable(proprieties[_id].owner).transfer(msg.value);
                proprieties[_id].state = StateProperty.NOT_FOR_SALE;
                 
    }
}