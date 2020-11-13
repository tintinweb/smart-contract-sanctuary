// SPDX-License-Identifier: AGPL-3.0-only

/*
    SkaleToken.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

import "./OCSafeMath.sol";
import "./OCReentrancyGuard.sol";

import "./ERC777.sol";

import "./Permissions.sol";
import "./IDelegatableToken.sol";
import "./Punisher.sol";
import "./TokenState.sol";


/**
 * @title SkaleToken is ERC777 Token implementation, also this contract in skale
 * manager system
 */
contract SkaleToken is ERC777, Permissions, ReentrancyGuard, IDelegatableToken {
    using SafeMath for uint;

    string public constant NAME = "SKALE";

    string public constant SYMBOL = "SKL";

    uint public constant DECIMALS = 18;

    uint public constant CAP = 7 * 1e9 * (10 ** DECIMALS); // the maximum amount of tokens that can ever be created

    constructor(address contractsAddress, address[] memory defOps) public
    ERC777("SKALE", "SKL", defOps)
    {
        Permissions.initialize(contractsAddress);
    }

    /**
     * @dev mint - create some amount of token and transfer it to the specified address
     * @param account - address where some amount of token would be created
     * @param amount - amount of tokens to mine
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @return returns success of function call.
     */
    function mint(
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external
        allow("SkaleManager")
        //onlyAuthorized
        returns (bool)
    {
        require(amount <= CAP.sub(totalSupply()), "Amount is too big");
        _mint(
            account,
            amount,
            userData,
            operatorData
        );

        return true;
    }

    function getAndUpdateDelegatedAmount(address wallet) external override returns (uint) {
        return DelegationController(contractManager.getContract("DelegationController"))
            .getAndUpdateDelegatedAmount(wallet);
    }

    function getAndUpdateSlashedAmount(address wallet) external override returns (uint) {
        return Punisher(contractManager.getContract("Punisher")).getAndUpdateLockedAmount(wallet);
    }

    function getAndUpdateLockedAmount(address wallet) public override returns (uint) {
        return TokenState(contractManager.getContract("TokenState")).getAndUpdateLockedAmount(wallet);
    }

    // internal

    function _beforeTokenTransfer(
        address, // operator
        address from,
        address, // to
        uint256 tokenId)
        internal override
    {
        uint locked = getAndUpdateLockedAmount(from);
        if (locked > 0) {
            require(balanceOf(from) >= locked.add(tokenId), "Token should be unlocked for transferring");
        }
    }

    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override nonReentrant {
        super._callTokensToSend(operator, from, to, amount, userData, operatorData);
    }

    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal override nonReentrant {
        super._callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    // we have to override _msgData() and _msgSender() functions because of collision in Context and ContextUpgradeSafe

    function _msgData() internal view override(Context, ContextUpgradeSafe) returns (bytes memory) {
        return Context._msgData();
    }

    function _msgSender() internal view override(Context, ContextUpgradeSafe) returns (address payable) {
        return Context._msgSender();
    }
}
