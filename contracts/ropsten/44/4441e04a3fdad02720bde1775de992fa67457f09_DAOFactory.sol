/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.5.16;

contract DAOFactory {
    NewDAO[] daos;
    function createDAO(string calldata _name, uint256 _min, uint256 _max, uint256 _soft, uint256 _hard, uint256 _preRate, uint256 _listRate) external {
        NewDAO dao = new NewDAO(_name, _min, _max, _soft, _hard, _preRate, _listRate, msg.sender);
        daos.push(dao);
        address(dao);
    }
}

contract NewDAO {
    struct DAO {
        string name;
        uint256 min;
        uint256 max;
        uint256 soft;
        uint256 hard;
        uint256 preRate;
        uint256 listRate;
        address owner;
    }

    DAO dao;

    constructor (string memory _name, uint256 _min, uint256 _max, uint256 _soft, uint256 _hard, uint256 _preRate, uint256 _listRate, address _owner) public {
        dao.name = _name;
        dao.min = _min;
        dao.max = _max;
        dao.soft = _soft;
        dao.hard = _hard;
        dao.preRate = _preRate;
        dao.listRate = _listRate;
        dao.owner = _owner;
    }

    function changeName(string calldata _name) external {
        dao.name = _name;
    }
}