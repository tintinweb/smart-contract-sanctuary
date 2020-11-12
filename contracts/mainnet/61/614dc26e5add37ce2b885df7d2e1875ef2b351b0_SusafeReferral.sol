// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract SusafeReferral {
    mapping(address => address) public referrers; // account_address -> referrer_address
    mapping(address => uint256) public referredCount; // referrer_address -> num_of_referred

    event Referral(address indexed referrer, address indexed farmer);

    address public governance;

    mapping(address => bool) public isAdmin;

    constructor () public {
        governance = tx.origin;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "OnlyAdmin methods called by non-admin.");
        _;
    }

    function setReferrer(address farmer, address referrer) public onlyAdmin {
        if (referrers[farmer] == address(0) && referrer != address(0)) {
            referrers[farmer] = referrer;
            referredCount[referrer] += 1;
            emit Referral(referrer, farmer);
        }
    }

    function getReferrer(address farmer) public view returns (address) {
        return referrers[farmer];
    }

    // Set admin status.
    function setAdminStatus(address _admin, bool _status) external {
        require(msg.sender == governance, "!governance");
        isAdmin[_admin] = _status;
    }

    // owner can drain tokens that are sent here by mistake
    function emergencyERC20Drain(IERC20 token, uint amount) external {
        require(msg.sender == governance, "!governance");
        token.transfer(governance, amount);
    }
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}