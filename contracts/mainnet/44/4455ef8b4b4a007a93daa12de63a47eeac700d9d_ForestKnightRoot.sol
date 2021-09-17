// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Ownable.sol";

import "./ERC20Fallback.sol";
import "./ERC20Capped.sol";

contract ForestKnightRoot is AccessControl, ERC20Capped, ERC20Fallback, Ownable {
    uint8 immutable private _decimals;
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    //address private _predicateProxy = 0x37c3bfC05d5ebF9EBb3FF80ce0bd0133Bf221BC8; //goerli
    address private _predicateProxy = 0x9923263fA127b3d1484cFD649df8f1831c2A74e4; //mainnet

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initialAccount,
        uint256 initialBalance,
        uint256 supplyCap
    ) 
        ERC20(name_, symbol_) 
        ERC20Capped(supplyCap * (uint256(10) ** decimals_))
        ERC20Fallback()
    {
        require(initialAccount != address(0), "ForestKnightRoot: initialAccount is a zero address");
        _decimals = decimals_;
        uint256 newSupply = initialBalance * (uint256(10) ** decimals_);
        _mint(initialAccount, newSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, predicateProxy());
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    * For example, if `decimals` equals `2`, a balance of `505` tokens should
    * be displayed to a user as `5,05` (`505 / 10 ** 2`).
    *
    * Tokens usually opt for a value of 18, imitating the relationship between
    * Ether and Wei. This is the value {ERC20} uses, unless {decimals} is
    * set in constructor.
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * {IERC20-balanceOf} and {IERC20-transfer}.
    */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external onlyRole(PREDICATE_ROLE) {
        _mint(user, amount);
    }

    function predicateProxy() public view returns(address) {
        return _predicateProxy;
    }

    /**
    * @dev Validation of an fallback redeem. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from TokenEscrow to extend their validations.
    * Example from TokenEscrow.sol"s _prevalidateFallbackRedeem method:
    *     super._prevalidateFallbackRedeem(token, payee, amount);
    *    
    * @param token_ The token address of IERC20 token
    * @param to_ Address performing the token deposit
    * @param amount_ Number of tokens deposit
    *
    * Requirements:
    *
    * - `msg.sender` must be owner.
    * - `token` cannot be the zero address.
    * - `to` cannot be the zero address.
    * - this address must have a token balance of at least `amount`.
    * - must be admin
    */
    function _prevalidateFallbackRedeem(IERC20 token_,  address to_, uint256 amount_) 
        internal 
        virtual
        override
        view
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
      super._prevalidateFallbackRedeem(token_, to_, amount_);
    }
}