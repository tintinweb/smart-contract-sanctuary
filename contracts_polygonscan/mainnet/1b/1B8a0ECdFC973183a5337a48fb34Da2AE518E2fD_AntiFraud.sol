// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title AntiFraud
 * @author Tavux <[email protected]>
 */
contract AntiFraud {

    address public _owner ;

    mapping(bytes32 => bool) private _projects;

    modifier onlyOwner {
        require(msg.sender == _owner, "Forbidden");
        _;
    }

    constructor()
    {
        _owner = msg.sender;
    }

    function setOwner(address owner) public onlyOwner {
        _owner = owner;
    }

    function setAllowed(bytes32 project_id, bool value) public onlyOwner {
        _projects[project_id] = value;
    }

    function isAllowed(bytes32 project_id) public view returns (bool){
        return _projects[project_id];
    }    
}