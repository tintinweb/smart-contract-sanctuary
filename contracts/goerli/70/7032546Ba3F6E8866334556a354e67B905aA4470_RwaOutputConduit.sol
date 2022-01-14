/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// hevm: flattened sources of src/RwaConduits.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.12 <0.7.0;

////// src/RwaConduits.sol
/* pragma solidity ^0.6.12; */

interface DSTokenLike_2 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (uint256);
}

contract RwaInputConduit {
    /// @notice The Dai token implementation.
    DSTokenLike_2 public immutable dai;
    /// @notice The destination of Dai when it is pushed into this contract.
    address public immutable to;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice `usr` was granted push access.
     * @param usr The user address.
     */
    event Mate(address indexed usr);
    /**
     * @notice `usr` push access was revoked.
     * @param usr The user address.
     */
    event Hate(address indexed usr);
    /**
     * @notice `wad` amount of Dai was pushed to `to_`.
     * @param to The destination address.
     * @param wad The amount pushed.
     */
    event Push(address indexed to, uint256 wad);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaInputConduit/not-authorized");
        _;
    }

    /**
     * @param dai_ The Dai token implementation.
     * @param to_ The destination of Dai when it is pushed into this contract.
     */
    constructor(address dai_, address to_) public {
        dai = DSTokenLike_2(dai_);
        to = to_;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Grants `usr` push access to this contract.
     * @param usr The user address.
     */
    function mate(address usr) external auth {
        may[usr] = 1;
        emit Mate(usr);
    }

    /**
     * @notice Revokes `usr` push access from this contract.
     * @param usr The user address.
     */
    function hate(address usr) external auth {
        may[usr] = 0;
        emit Hate(usr);
    }

    /**
     * @notice Transfers the outstanding Dai balance of this contract to the receiver.
     */
    function push() external {
        require(may[msg.sender] == 1, "RwaInputConduit/not-mate");

        uint256 balance = dai.balanceOf(address(this));
        dai.transfer(to, balance);

        emit Push(to, balance);
    }
}

contract RwaOutputConduit {
    /// @notice The Dai token implementation.
    DSTokenLike_2 public immutable dai;
    /// @notice The destination of Dai when drawn from this contract.
    address public to;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with operator access on this contract. `can[usr]`
    mapping(address => uint256) public can;
    /// @notice Addresses with push access on this contract. `may[usr]`
    mapping(address => uint256) public may;
    /// @notice Addresses which can receive Dai from this contract. `bud[who]`
    mapping(address => uint256) public bud;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice `usr` was granted operator access.
     * @param usr The user address.
     */
    event Hope(address indexed usr);
    /**
     * @notice `usr` operator access was revoked.
     * @param usr The user address.
     */
    event Nope(address indexed usr);
    /**
     * @notice `usr` was granted push access.
     * @param usr The user address.
     */
    event Mate(address indexed usr);
    /**
     * @notice `usr` push access was revoked.
     * @param usr The user address.
     */
    event Hate(address indexed usr);
    /**
     * @notice `who` was allowed to receive Dai from this contract.
     * @param who The user address.
     */
    event Kiss(address indexed who);
    /**
     * @notice `who` permission to receive Dai from this contract was revoked.
     * @param who The user address.
     */
    event Diss(address indexed who);
    /**
     * @notice `who` was picked as the destination of Dai for the next `push`.
     * @param who The user address.
     */
    event Pick(address indexed who);
    /**
     * @notice `wad` amount of Dai was pushed to `to_`.
     * @param to The destination address.
     * @param wad The amount pushed.
     */
    event Push(address indexed to, uint256 wad);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaOutputConduit/not-authorized");
        _;
    }

    /**
     * @param dai_ The Dai token implementation.
     */
    constructor(address dai_) public {
        dai = DSTokenLike_2(dai_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revoeks `usr` admin access to this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Grants `usr` operator access to this contract.
     * @param usr The user address.
     */
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }

    /**
     * @notice Revokes `usr` admin access to this contract.
     * @param usr The user address.
     */
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }

    /**
     * @notice Grants `usr` push access to this contract.
     * @param usr The user address.
     */
    function mate(address usr) external auth {
        may[usr] = 1;
        emit Mate(usr);
    }

    /**
     * @notice Revokes `usr` push access to this contract.
     * @param usr The user address.
     */
    function hate(address usr) external auth {
        may[usr] = 0;
        emit Hate(usr);
    }

    /**
     * @notice Allows `who` to receive Dai from this contract.
     * @param who The user address.
     */
    function kiss(address who) public auth {
        bud[who] = 1;
        emit Kiss(who);
    }

    /**
     * @notice Forbids `who` from receiving Dai from this contract.
     * @param who The user address.
     */
    function diss(address who) public auth {
        if (to == who) {
            to = address(0);
        }
        bud[who] = 0;
        emit Diss(who);
    }

    /**
     * @notice Picks `who` as the destination for Dai transferred on the next `push`.
     * @param who The user address.
     */
    function pick(address who) public {
        require(can[msg.sender] == 1, "RwaOutputConduit/not-operator");
        require(bud[who] == 1 || who == address(0), "RwaOutputConduit/not-bud");
        to = who;
        emit Pick(who);
    }

    /**
     * @notice Transfers the outstanding Dai balance of this contract to the receiver.
     */
    function push() external {
        require(may[msg.sender] == 1, "RwaOutputConduit/not-mate");
        require(to != address(0), "RwaOutputConduit/to-not-picked");
        uint256 balance = dai.balanceOf(address(this));
        address recipient = to;
        to = address(0);

        dai.transfer(recipient, balance);
        emit Push(recipient, balance);
    }
}