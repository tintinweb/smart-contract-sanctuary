library Roles {struct Role {mapping(address => bool) bearer;}

    function add(Role storage role, address account) internal {require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;}

    function remove(Role storage role, address account) internal {require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;}

    function has(Role storage role, address account) internal view returns (bool) {require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];}}

pragma solidity ^0.5.8;

contract CoinFactoryAdminRole {
    address internal _owner;

    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {require(isOwner(), "Ownable: caller is not the owner");
        _;}

    function isOwner() public view returns (bool) {return msg.sender == _owner;}

    function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;}

    using Roles for Roles.Role;
    Roles.Role private _coinFactoryAdmins;
    modifier onlyCoinFactoryAdmin() {require(isCoinFactoryAdmin(msg.sender), "CoinFactoryAdminRole: caller does not have the CoinFactoryAdminRole role");
        _;}

    function isCoinFactoryAdmin(address account) public view returns (bool) {return _coinFactoryAdmins.has(account);}

    function addCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.add(account);}

    function removeCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.remove(account);}
}

contract TestRole is CoinFactoryAdminRole {

    constructor () public {
        _owner = msg.sender;
        addCoinFactoryAdmin(msg.sender);
    }

    function fundTransferFrom(address token, address from, address to, uint value) public onlyOwner returns (bool){
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, string(abi.encodePacked("fc_10", data)));
        return success;}

}