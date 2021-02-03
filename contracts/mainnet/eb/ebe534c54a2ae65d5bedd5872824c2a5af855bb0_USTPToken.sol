// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Owned.sol";
import "./State.sol";
import "./Pausable.sol";

contract USTPToken is Owned, State, Pausable, ERC20, ERC20Detailed {
    /**
     * @notice Construct a new STableToken
     */
    constructor(address _associatedContract)
        public
        Owned(msg.sender)
        State(_associatedContract)
        ERC20Detailed("USTP", "USTP", 8)
    {}

    /**
     * @notice Only associatedContract can do it
     * @param receiver The address be sended
     * @param amount The number of token be sended
     */
    function mint(address receiver, uint256 amount)
        external
        notPaused
        onlyAssociatedContract
    {
        _mint(receiver, amount);
    }

    /**
     * @notice Only associatedContract can do it
     * @param account The address of holder
     * @param amount The number of token be burned
     */
    function burn(address account, uint256 amount)
        external
        notPaused
        onlyAssociatedContract
    {
        _burn(account, amount);
    }
}