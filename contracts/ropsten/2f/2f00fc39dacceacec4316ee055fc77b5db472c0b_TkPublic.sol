pragma solidity ^0.4.0;

contract TkAccessControl {
    address public owner;
    address public operatorAddress;

    constructor () public{
        owner = msg.sender;
        operatorAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    function setOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));
        operatorAddress = _newOperator;
    }
}
contract BadgeStorageInterface {
    function getBadgeInfo(uint256 _id) external view returns (
        uint badge_id,
        string badge_title,
        uint badge_value,
        string badge_icon_shape_material_ribbon_option,
        string champion_name,
        uint32 event_date,
        int16 lat,
        int16 lng,
        uint24 players_count,
        string event_name
    );
}

contract TkPublic is TkAccessControl{

    BadgeStorageInterface badgeContract;

    function setTkContractAddress(address _address) external onlyOwner{
        badgeContract = BadgeStorageInterface(_address);
    }

    function getBadgeInfo(uint _badgeId) external view returns(
        uint badge_id,
        string badge_title,
        uint badge_value,
        string badge_icon_shape_material_ribbon_option,
        string champion_name,
        uint32 event_date,
        int16 event_lat,
        int16 event_lng,
        uint24 players_count,
        string event_name
    ){
        return (badgeContract.getBadgeInfo(_badgeId));
    }
}