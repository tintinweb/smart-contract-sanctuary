/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.4;

interface IWhiteListOracle {

    function whitelist(address _user) external returns(bool);

    function blacklist(address _user) external returns(bool);

    function transferGovernor(address _newGovernor) external returns(bool);

    function whitelisted(address _user) external view returns(bool);

}

contract WhiteListOracle is IWhiteListOracle {

    address public governor;

    modifier onlyGovernor() {
        require(msg.sender == governor, "Caller Not Governor");
        _;
    }

    mapping(address => bool) private Whitelisted;

    constructor(address _governor){
        governor = _governor;
    }

    event ChangeGovernor(address indexed from, address indexed to);
    event Whitelist(address indexed);
    event Blacklist(address indexed);

    function transferGovernor(address _newGovernor) public virtual override onlyGovernor returns(bool){
        require(_newGovernor != address(0),"Cannot be a zero address");
        address oldGovernor = governor;
        governor = _newGovernor;
        emit ChangeGovernor(oldGovernor, _newGovernor);
        return true;
    }

    function whitelist(address _user) public virtual override onlyGovernor returns(bool){
        require(_user != address(0),"Can't be a zero address");
        Whitelisted[_user] = true;
        emit Whitelist(_user);
        return true;
    }

    function blacklist(address _user) public virtual override onlyGovernor returns(bool){
        require(_user != address(0),"Can't be a zero address");
        Whitelisted[_user] = false;
        emit Blacklist(_user);
        return true;
    }

    function whitelisted(address _user) public view override returns(bool){
        return(Whitelisted[_user]);
    }

}