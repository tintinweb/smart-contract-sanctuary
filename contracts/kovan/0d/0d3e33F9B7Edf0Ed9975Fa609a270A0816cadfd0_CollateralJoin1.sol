/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/1wlrn04c7vjyv49wnz8wksw61k8brm6w-geb-deploy/dapp/geb-deploy/src/AdvancedTokenAdapters.sol
pragma solidity =0.6.7 >=0.6.0 <0.8.0;

////// /nix/store/1wlrn04c7vjyv49wnz8wksw61k8brm6w-geb-deploy/dapp/geb-deploy/src/utils/ReentrancyGuard.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

////// /nix/store/1wlrn04c7vjyv49wnz8wksw61k8brm6w-geb-deploy/dapp/geb-deploy/src/AdvancedTokenAdapters.sol
/// AdvancedTokenAdapters.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// (at your option) any later version.
// the Free Software Foundation, either version 3 of the License, or
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */
/* import "./utils/ReentrancyGuard.sol"; */

abstract contract SAFEEngineLike_1 {
    function modifyCollateralBalance(bytes32,address,int) virtual public;
}

// CollateralJoin1
abstract contract CollateralLike_1 {
    function decimals() virtual public view returns (uint);
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
}

contract CollateralJoin1 {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin1/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1 public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32        public collateralType;
    // The collateral token contract
    CollateralLike_1 public collateral;
    // The number of decimals the collateral has
    uint           public decimals;
    // Whether this contract is disabled or not
    uint           public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;

        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike_1(collateral_);
        decimals = collateral.decimals();

        require(decimals == 18, "CollateralJoin1/not-18-decimals");
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    // --- Administration ---
    /*
    * @notify Disable this join contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) external {
        require(contractEnabled == 1, "CollateralJoin1/not-contractEnabled");
        require(int(wad) >= 0, "CollateralJoin1/overflow");
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin1/failed-transfer");
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) external {
        require(wad <= 2 ** 255, "CollateralJoin1/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        require(collateral.transfer(usr, wad), "CollateralJoin1/failed-transfer");
        emit Exit(msg.sender, usr, wad);
    }
}

// CollateralJoin2

// For a token that does not return a bool on transfer or transferFrom (like OMG)
// This is one way of doing it. Check the balances before and after calling a transfer

abstract contract CollateralLike2 {
    function decimals() virtual public view returns (uint);
    function transfer(address,uint) virtual public;
    function transferFrom(address,address,uint) virtual public;
    function balanceOf(address) virtual public view returns (uint);
    function allowance(address,address) virtual public view returns (uint);
}

contract CollateralJoin2 {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin2/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1  public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32         public collateralType;
    // The collateral token contract
    CollateralLike2 public collateral;
    // The number of decimals the collateral has
    uint            public decimals;
    // Whether this contract is disabled or not
    uint            public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike2(collateral_);
        decimals = collateral.decimals();
        contractEnabled = 1;
        require(decimals == 18, "CollateralJoin2/not-18-decimals");
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin2/overflow");
    }

    // --- Administration ---
    /*
    * @notify Disable this join contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Collateral Gateway ---
    function transfer(int wad, address guy) internal {
        int256 prevBalance = int(collateral.balanceOf(address(this)));
        require(prevBalance >= wad, "CollateralJoin2/no-funds");
        (bool ok,) = address(collateral).call(
            abi.encodeWithSignature("transfer(address,uint256)", guy, wad)
        );
        require(ok, "CollateralJoin2/failed-transfer");
        require(uint(prevBalance + wad) == collateral.balanceOf(address(this)), "CollateralJoin2/failed-transfer");
    }
    function transferFrom(int wad) internal {
        int256 prevBalance = int(collateral.balanceOf(msg.sender));
        require(prevBalance >= wad, "CollateralJoin2/no-funds");
        require(int(collateral.allowance(msg.sender, address(this))) >= wad, "CollateralJoin2/no-allowance");
        (bool ok,) = address(collateral).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), wad)
        );
        require(ok, "CollateralJoin2/failed-transfer");
        require(uint(prevBalance - wad) == collateral.balanceOf(msg.sender), "CollateralJoin2/failed-transfer");
    }
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) public {
        require(contractEnabled == 1, "CollateralJoin2/contract-not-enabled");
        require(wad <= 2 ** 255, "CollateralJoin2/overflow");
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        transferFrom(int256(wad));
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) public {
        require(wad <= 2 ** 255, "CollateralJoin2/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        transfer(int(wad), usr);
        emit Exit(msg.sender, usr, wad);
    }
}

// CollateralJoin3
// For a token that has a lower precision than 18 and doesn't have decimals field in place

abstract contract CollateralLike3 {
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
}

contract CollateralJoin3 {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin3/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1  public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32         public collateralType;
    // The collateral token contract
    CollateralLike3 public collateral;
    // The number of decimals the collateral has
    uint            public decimals;
    // Whether this contract is disabled or not
    uint            public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_, uint decimals_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike3(collateral_);
        require(decimals_ < 18, "CollateralJoin3/decimals-higher-18");
        decimals = decimals_;
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin3/overflow");
    }
    function multiply(int x, uint y) internal pure returns (int z) {
        require(y == 0 || (z = x * int256(y)) / int256(y) == x, "CollateralJoin3/overflow");
    }

    // --- Administration ---
    /*
    * @notify Disable this join contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) public {
        require(contractEnabled == 1, "CollateralJoin3/contract-not-enabled");
        uint wad18 = multiply(wad, 10 ** (18 - decimals));
        require(wad18 <= 2 ** 255, "CollateralJoin3/overflow");
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad18));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin3/failed-transfer");
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) public {
        uint wad18 = multiply(wad, 10 ** (18 - decimals));
        require(wad18 <= 2 ** 255, "CollateralJoin3/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad18));
        require(collateral.transfer(usr, wad), "CollateralJoin3/failed-transfer");
        emit Exit(msg.sender, usr, wad);
    }
}

/// CollateralJoin4

// Copyright (C) 2019 Lorenzo Manacorda <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// For tokens that do not implement transferFrom (like GNT), meaning the usual adapter
// approach won't work: the adapter cannot call transferFrom and therefore
// has no way of knowing when users deposit gems into it.

// To work around this, we introduce the concept of a bag, which is a trusted
// (it's created by the adapter), personalized component (one for each user).

// Users first have to create their bag with `CollateralJoin4.make`, then transfer
// tokens to it, and then call `CollateralJoin4.join`, which transfer the collateral from the
// bag to the adapter.

abstract contract CollateralLike4 {
    function decimals() virtual public view returns (uint);
    function balanceOf(address) virtual public returns (uint256);
    function transfer(address, uint256) virtual public returns (bool);
}

contract GemBag {
    address         public ada;
    address         public lad;
    CollateralLike4 public collateral;

    constructor(address lad_, address collateral_) public {
        ada = msg.sender;
        lad = lad_;
        collateral = CollateralLike4(collateral_);
    }

    /*
    * @notify Transfer tokens out of this bag
    * @param usr The address that will receive tokens
    * @param wad The amount of tokens to transfer out of the bag
    */
    function exit(address usr, uint256 wad) external {
        require(msg.sender == ada || msg.sender == lad, "GemBag/invalid-caller");
        require(collateral.transfer(usr, wad), "GemBag/failed-transfer");
    }
}

contract CollateralJoin4 {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin4/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1  public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32         public collateralType;
    // The collateral token contract
    CollateralLike4 public collateral;
    // The number of decimals the collateral has
    uint            public decimals;
    // Whether this contract is disabled or not
    uint            public contractEnabled;

    // Bags that store tokens joined in the system
    mapping(address => address) public bags;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address bag, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike4(collateral_);
        decimals = collateral.decimals();
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    // --- Administration ---
    /*
    * @notify Disable this contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // -- Bags --
    /*
    * @notify Create a new bag for msg.sender
    */
    function make() external returns (address bag) {
        bag = make(msg.sender);
    }
    /*
    * @notify Create a new bag for a custom address
    * @param usr The address to create a bag for
    */
    function make(address usr) public returns (address bag) {
        require(bags[usr] == address(0), "CollateralJoin4/bag-already-exists");
        bag = address(new GemBag(address(usr), address(collateral)));
        bags[usr] = bag;
    }

    // -- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint256 wad) external {
        require(contractEnabled == 1, "CollateralJoin4/contract-not-enabled");
        require(int256(wad) >= 0, "CollateralJoin4/negative-amount");
        GemBag(bags[msg.sender]).exit(address(this), wad);
        safeEngine.modifyCollateralBalance(collateralType, usr, int256(wad));
        emit Join(msg.sender, bags[msg.sender], usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint256 wad) external {
        require(int256(wad) >= 0, "CollateralJoin4/negative-amount");

        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        require(collateral.transfer(usr, wad), "CollateralJoin4/failed-transfer");

        emit Exit(msg.sender, usr, wad);
    }
}

// CollateralLike5
// For a token that has a lower precision than 18 and it has decimals (like USDC)
abstract contract CollateralLike5 {
    function decimals() virtual public view returns (uint8);
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
}

contract CollateralJoin5 {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin5/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1  public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32         public collateralType;
    // The collateral token contract
    CollateralLike5 public collateral;
    // The number of decimals the collateral has
    uint            public decimals;
    // Whether this contract is disabled or not
    uint            public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        collateral = CollateralLike5(collateral_);
        decimals = collateral.decimals();
        require(decimals < 18, "CollateralJoin5/decimals-18-or-higher");

        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;

        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin5/overflow");
    }

    // --- Administration ---
    /*
    * @notify Disable this contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) public {
        require(contractEnabled == 1, "CollateralJoin5/not-contractEnabled");
        uint wad18 = multiply(wad, 10 ** (18 - decimals));
        require(int(wad18) >= 0, "CollateralJoin5/overflow");
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad18));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin5/failed-transfer");
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) public {
        uint wad18 = multiply(wad, 10 ** (18 - decimals));
        require(int(wad18) >= 0, "CollateralJoin5/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad18));
        require(collateral.transfer(usr, wad), "CollateralJoin5/failed-transfer");
        emit Exit(msg.sender, usr, wad);
    }
}

// For whitelisting addresses that are allowed to join collateral (the collateral type has 18 decimals and implements transferFrom)
contract CollateralJoin6 {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin6/account-not-authorized");
        _;
    }

    // -- Whitelisting ---
    // Allowances to join collateral into the system
    mapping(address => uint256) public allowance;
    // Amount of collateral already joined
    mapping(address => uint256) public collateralJoined;
    /**
     * @notice Change an address' allowance
     * @param account Account to change the allowance for
     * @param amount New allowance
     */
    function setAllowance(address account, uint256 amount) external isAuthorized {
        if (both(amount == 0, allowance[account] > 0)) {
          allowed = addition(allowed, -1);
        } else if (both(allowance[account] == 0, amount > 0)) {
          allowed = addition(allowed, uint(1));
        }
        allowance[account] = amount;
        emit SetAllowance(account, amount, allowed);
    }
    /**
    * @notice Checks whether msg.sender can join collateral
    * @param amount of collateral to join
    **/
    function canJoin(uint256 amount) public view returns (bool) {
        return both(allowance[msg.sender] > 0, addition(amount, collateralJoined[msg.sender]) <= allowance[msg.sender]);
    }

    // Safe engine contract
    SAFEEngineLike_1  public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32         public collateralType;
    // The collateral token contract
    CollateralLike_1  public collateral;
    // The number of decimals the collateral has
    uint            public decimals;
    // The number of allowed addresses that can add collateral in the system
    uint            public allowed;
    // Whether this contract is disabled or not
    uint            public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event SetAllowance(address account, uint amount, uint allowed);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike_1(collateral_);
        decimals = collateral.decimals();
        require(decimals == 18, "CollateralJoin6/not-18-decimals");
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- Administration ---
    /*
    * @notify Disable this contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Utils ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) external {
        require(contractEnabled == 1, "CollateralJoin6/not-contractEnabled");
        require(canJoin(wad), "CollateralJoin6/cannot-join-above-allowance");
        require(int(wad) >= 0, "CollateralJoin6/overflow");
        collateralJoined[msg.sender] = addition(collateralJoined[msg.sender], wad);
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin6/failed-transfer");
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) external {
        require(wad <= 2 ** 255, "CollateralJoin6/overflow");
        if (collateralJoined[msg.sender] >= wad) {
          collateralJoined[msg.sender] = subtract(collateralJoined[msg.sender], wad);
        } else {
          collateralJoined[msg.sender] = 0;
        }
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        require(collateral.transfer(usr, wad), "CollateralJoin6/failed-transfer");
        emit Exit(msg.sender, usr, wad);
    }
}

// AuthCollateralJoin
contract AuthCollateralJoin {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "AuthCollateralJoin/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1  public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32         public collateralType;
    // The collateral token contract
    CollateralLike_1  public collateral;
    // The number of decimals the collateral has
    uint            public decimals;
    // Whether this contract is disabled or not
    uint            public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike_1(collateral_);
        decimals = collateral.decimals();

        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    // --- Administration ---
    /*
    * @notify Disable this contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }

    // --- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) public isAuthorized {
        require(contractEnabled == 1, "AuthCollateralJoin/contract-not-enabled");
        require(int(wad) >= 0, "AuthCollateralJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "AuthCollateralJoin/failed-transfer");
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) public isAuthorized {
        require(wad <= 2 ** 255, "AuthCollateralJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        require(collateral.transfer(usr, wad), "AuthCollateralJoin/failed-transfer");
        emit Exit(msg.sender, usr, wad);
    }
}

abstract contract IERC3156FlashBorrowerLike {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external payable virtual returns (bytes32);
}

// CollateralJoin2

// For standard tokens (CollateralJoin1) that allows for flashloans

abstract contract CollateralLike7 {
    function decimals() virtual public view returns (uint);
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
    function balanceOf(address) virtual public view returns (uint);
}

contract CollateralJoin7 is ReentrancyGuard {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin7/account-not-authorized");
        _;
    }

    // Safe engine contract
    SAFEEngineLike_1   public safeEngine;
    // The name of the collateral type handled by this join contract
    bytes32          public collateralType;
    // The collateral token contract
    CollateralLike7  public collateral;
    // The number of decimals the collateral has
    uint             public decimals;
    // Whether this contract is disabled or not
    uint             public contractEnabled;
    // flashloan fee receiver
    address          public feeReceiver;
    // fee charged for flashloans (WAD, 100% == 1 WAD)
    uint256          public flashLoanFee;
    // callback success hash
    bytes32 constant public  CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 constant        WAD = 10 ** 18;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address usr, uint wad);
    event Exit(address sender, address usr, uint wad);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);

    constructor(
        address safeEngine_,
        bytes32 collateralType_,
        address collateral_,
        uint256 flashLoanFee_,
        address payable feeReceiver_
    ) public {
        require(feeReceiver_ != address(0), "CollateralJoin7/null-fee-receiver");
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;

        safeEngine = SAFEEngineLike_1(safeEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike7(collateral_);
        decimals = collateral.decimals();
        flashLoanFee = flashLoanFee_;
        feeReceiver  = feeReceiver_;

        require(decimals == 18, "CollateralJoin7/not-18-decimals");

        emit ModifyParameters("flashLoanFee", flashLoanFee_);
        emit ModifyParameters("feeReceiver", feeReceiver_);
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x, "CollateralJoin7/add-overflow");
        require(y <= 0 || z >= x, "CollateralJoin7/add-overflow");
    }
    function addition(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x, "CollateralJoin7/add-overflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin7/mul-overflow");
    }

    // --- Administration ---
    /*
    * @notify Disable this join contract
    */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    /**
     * @notice Modify an uint256 param
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "flashLoanFee") flashLoanFee = data;
        else revert("CollateralJoin7/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an uint256 param
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "CollateralJoin7/null-data");
        if (parameter == "feeReceiver") feeReceiver = payable(data);
        else revert("CollateralJoin7/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Collateral Gateway ---
    /*
    * @notify Join collateral tokens in the system
    * @dev It reverts in case the contract is disabled
    * @param usr The address that will receive tokens inside the system
    * @param wad The amount of tokens to join
    */
    function join(address usr, uint wad) external nonReentrant {
        require(contractEnabled == 1, "CollateralJoin7/not-contractEnabled");
        require(int(wad) >= 0, "CollateralJoin7/overflow");
        safeEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin7/failed-transfer");
        emit Join(msg.sender, usr, wad);
    }
    /*
    * @notify Exit collateral tokens from the system and send them to a custom address
    * @param usr The address that will receive collateral tokens after they are exited
    * @param wad The amount of tokens to exit
    */
    function exit(address usr, uint wad) external nonReentrant {
        require(wad <= 2 ** 255, "CollateralJoin7/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        require(collateral.transfer(usr, wad), "CollateralJoin7/failed-transfer");
        emit Exit(msg.sender, usr, wad);
    }

    // --- Flash Loan ---
    /**
     * @dev Initiate a flash loan.
     * @notice Token variable is unused, maintained to maintain compatibility with EIP-3156
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrowerLike receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        require(contractEnabled == 1, "CollateralJoin7/not-contractEnabled");
        require(amount > 0, "CollateralJoin7/null-amount");
        uint256 initialBalance = collateral.balanceOf(address(this));
        uint256 fee            = flashFee(token, amount);

        // transfer eth to borrower
        require(collateral.transfer(address(receiver), amount), "CollateralJoin7/transfer-failed");

        // calls borrower, payment should be sent to this contract within the callback
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            "CollateralJoin7/callback-failed"
        );

        // check repayment
        require (collateral.balanceOf(address(this)) == addition(initialBalance, fee), "CollateralJoin7/loan-not-fully-paid");

        // send fees to feeReceiver
        require(collateral.transfer(feeReceiver, fee), "CollateralJoin7/transfer-failed");
        return true;
    }


    // --- Getters ---
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256) {
        require (token == address(collateral), "CollateralJoin7/invalid-token");
        return collateral.balanceOf(address(this));
    }
    /**
     * @dev The fee to be charged for a given loan.
     * @notice Token variable is unused, maintained to maintain compatibility with EIP-3156
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        require (token == address(collateral), "CollateralJoin7/invalid-token");
        return multiply(amount, flashLoanFee) / WAD;
    }
}