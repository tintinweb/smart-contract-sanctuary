// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Organization {
    event NewOwner(address newOwner);
    event AcceptOwner(address owner);
    event SendPay(address tokenAddr, address to, uint256 amount);

    address public owner;
    address private newOwner;
    mapping(address => bool) admins;

    /**
     * @dev To check the caller is organization owner
     */
    modifier onlyOwner {
        require(msg.sender == owner, "caller-is-not-organization-owner");
        _;
    }

    /**
     * @dev To check the caller is organization owner or admin
     */
    modifier isAuth {
        require(
            admins[msg.sender] || msg.sender == owner,
            "caller-is-not-admin-or-owner"
        );
        _;
    }

    /**
     * @dev Initiate organization with organization owner
     * @param _owner: Organization owner address
     */
    function initiate(address _owner) external {
        owner = _owner;
    }

    /**
     * @dev Change organization owner address
     * @param _newOwner: New owner address
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != owner, "already-an-owner");
        require(_newOwner != address(0), "not-valid-address");
        require(newOwner != _newOwner, "already-a-new-owner");
        newOwner = _newOwner;
        emit NewOwner(_newOwner);
    }

    /**
     * @dev Accept new owner of organization
     */
    function acceptOwner() external {
        require(newOwner != address(0), "not-valid-address");
        require(msg.sender == newOwner, "not-owner");
        owner = newOwner;
        newOwner = address(0);
        emit AcceptOwner(owner);
    }

    /**
     * @dev Add admin to organization
     * @param _newAdmin: Address will be added to admin list
     */
    function addAdmin(address _newAdmin) external onlyOwner {
        admins[_newAdmin] = true;
    }

    /**
     * @dev Remove admin from organization
     * @param _admin: Address will be removed from admin list
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    /**
     * @dev Send payment
     * @param _to: Address will receive payment
     * @param _tokenAddr: Token address
     * @param _amount: Transfer amount
     */
    function _send(
        address _to,
        address _tokenAddr,
        uint256 _amount
    ) internal {
        IERC20 token = IERC20(_tokenAddr);
        require(token.transfer(_to, _amount), "transfer-failed");
        emit SendPay(_tokenAddr, _to, _amount);
    }

    /**
     * @dev Send multiple payments
     * @param _to: Addresses will receive payment
     * @param _tokenAddr: Token addresses
     * @param _amount: Transfer amounts
     */
    function sendpay(
        address[] memory _to,
        address[] memory _tokenAddr,
        uint256[] memory _amount
    ) external isAuth returns (bool) {
        require(_to.length == _tokenAddr.length, "length-not-equal");
        require(_to.length == _amount.length, "length-not-equal");
        for (uint256 i = 0; i < _to.length; i++) {
            _send(_to[i], _tokenAddr[i], _amount[i]);
        }
        return true;
    }
}

