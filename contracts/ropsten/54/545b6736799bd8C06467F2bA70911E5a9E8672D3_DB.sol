pragma solidity >=0.4.12 <0.9.0;

import "./2_Owner.sol";


contract DB is Owner{

    struct PlayerData{
        bool _isCreated;
        string _name;
        address _address;
        uint _balacne;
    }

    mapping ( address => PlayerData) DataToPlayer;

    function createPlayerData(string memory _name) public {
        require(DataToPlayer[msg.sender]._isCreated == false);
        PlayerData memory _data;
        _data._isCreated = true;
        _data._name = _name;
        _data._address = msg.sender;
        _data._balacne = 0;
        DataToPlayer[msg.sender] = _data;
    }

    function getMyData() public view returns(PlayerData memory){
        require(DataToPlayer[msg.sender]._isCreated != false);
        return DataToPlayer[msg.sender];
    }


}