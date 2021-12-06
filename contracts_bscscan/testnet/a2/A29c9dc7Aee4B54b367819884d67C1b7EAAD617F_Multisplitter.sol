// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity 0.7.4;

import "./Address.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Whitelist.sol";

contract Multisplitter is Whitelist {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct User {
        address payable wallet;
        uint256 baseBalance;
        uint256 tokenBalance;
    }

    address public deployer;

    mapping(uint256 => User) _user;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ONLY_DEPLOYER");
        _;
    }

    IERC20 public token;

    event onUpdateAddress(address indexed _caller, address indexed _newAddress, uint256 _timestamp);
    event onPushPayment(address indexed _recipient, uint256 _amount, uint256 _timestamp);
    event onDistribute(address indexed _caller, uint256 _amount, uint256 _timestamp);

    constructor(
        address payable _user1, 
        address payable _user2, 
        address payable _user3, 
        address payable _user4, 
        address payable _user5
    ) {
        _user[1].wallet = _user1; // Sheep
        _user[2].wallet = _user2; // Shane
        _user[3].wallet = _user3; // Rhino
        _user[4].wallet = _user4; // MadDog
        _user[5].wallet = _user5; // JP

        addAddressToWhitelist(_user1);
        addAddressToWhitelist(_user2);
        addAddressToWhitelist(_user3);
        addAddressToWhitelist(_user4);
        addAddressToWhitelist(_user5);

        deployer = msg.sender;
    }

    receive() external payable {

    }

    function baseBalanceOf(uint256 _id) public view returns (uint256 _balance) {
        return (_user[_id].baseBalance);
    }

    function tokenBalanceOf(uint256 _id) public view returns (uint256 _balance) {
        return (_user[_id].tokenBalance);
    }

    function distribute() public onlyWhitelisted() returns (bool _success) {
        uint256 tokens = address(this).balance;

        _user[1].baseBalance += tokens.mul(2000).div(10000);
        _user[2].baseBalance += tokens.mul(2000).div(10000);
        _user[3].baseBalance += tokens.mul(2000).div(10000);
        _user[4].baseBalance += tokens.mul(2000).div(10000);
        _user[5].baseBalance += tokens.mul(2000).div(10000);

        emit onPushPayment(msg.sender, tokens, block.timestamp);
        return true;
    }

    function distributeTokens(address _token) public onlyWhitelisted() returns (bool _success) {
        token = IERC20(_token);
        uint256 tokens = token.balanceOf(address(this));

        _user[1].tokenBalance += tokens.mul(2000).div(10000);
        _user[2].tokenBalance += tokens.mul(2000).div(10000);
        _user[3].tokenBalance += tokens.mul(2000).div(10000);
        _user[4].tokenBalance += tokens.mul(2000).div(10000);
        _user[5].tokenBalance += tokens.mul(2000).div(10000);

        emit onPushPayment(msg.sender, tokens, block.timestamp);
        return true;
    }

    function updateAddress(uint256 _userId, address payable _newAddress) public returns (bool _success) {
        address _oldAddress = _user[_userId].wallet;
        require(msg.sender == _oldAddress, "CANNOT_CHANGE_FROM_OTHER_WALLET");

        _user[_userId].wallet = _newAddress;

        emit onUpdateAddress(_oldAddress, _newAddress, block.timestamp);
        return true;
    }

    function pushTokenPayment(address _token, uint256 _userId) public returns (bool _success) {
        token = IERC20(_token);

        uint256 _entitlement = _user[_userId].tokenBalance;
        require(_entitlement > 0, "NO_BALANCE");

        _user[_userId].tokenBalance = 0;

        address _recipient = _user[_userId].wallet;
        token.transfer(_recipient, _entitlement);

        emit onPushPayment(_recipient, _entitlement, block.timestamp);
        return true;
    }

    function pushPayment(uint256 _userId) public returns (bool _success) {
        uint256 _entitlement = _user[_userId].baseBalance;
        require(_entitlement > 0, "NO_BALANCE");

        _user[_userId].baseBalance = 0;

        address payable _recipient = _user[_userId].wallet;
        _recipient.transfer(_entitlement);

        emit onPushPayment(_recipient, _entitlement, block.timestamp);
        return true;
    }

    function reset(uint256 _userId, uint256 _balance) public onlyDeployer() {
        _user[_userId].baseBalance = _balance;
    }
}