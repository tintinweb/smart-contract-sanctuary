// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./interfaces/IAuthority.sol";
import "./types/AccessControlled.sol";
contract axeAuthority is AccessControlled {

    event Pushed(address indexed from, address indexed to, string role);
    mapping(string => address) public database;

    constructor() AccessControlled( IAuthority(address(this)) ) {
        database['governor'] = msg.sender;
        emit Pushed(address(0), msg.sender, 'governor');
    }
    function push(address _new, string memory _role) external onlyGovernor {
        address old = database[_role];
        database[_role] = _new;
        emit Pushed(old, _new, _role);
    }
    function get(string memory _role) external view returns (address) {
        return database[_role];
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthority.sol";

abstract contract AccessControlled {
    event AuthorityUpdated(IAuthority indexed authority);
    string UNAUTHORIZED = "UNAUTHORIZED";
    IAuthority public authority;
    constructor(IAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    modifier onlyGovernor() {
        require(msg.sender == authority.get('governor'), UNAUTHORIZED);
        _;
    }
    modifier onlyTreasury() {
        require(msg.sender == authority.get('treasury'), UNAUTHORIZED);
        _;
    }
    modifier onlyStaking() {
        require(msg.sender == authority.get('staking'), UNAUTHORIZED);
        _;
    }
    function setAuthority(IAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
interface IAuthority {
    function get(string memory _role) external view returns (address);
}