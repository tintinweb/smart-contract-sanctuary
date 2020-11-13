/*

    /     |  __    / ____|
   /      | |__) | | |
  / /    |  _  /  | |
 / ____   | |    | |____
/_/    _ |_|  _  _____|

* ARC: token/KYFToken.sol
*
* Latest source (may be newer): https://github.com/arcxgame/contracts/blob/master/contracts/token/KYFToken.sol
*
* Contract Dependencies: (none)
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2020 ARC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

/* ===============================================
* Flattened with Solidifier by Coinage
* 
* https://solidifier.coina.ge
* ===============================================
*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IKYFV2 {

    function checkVerified(
        address _user
    )
        external
        view
        returns (bool);

}

// SPDX-License-Identifier: MIT


contract KYFToken {

    /* ========== Variables ========== */

    address public owner;

    mapping (address => bool) public kyfInstances;

    address[] public kyfInstancesArray;

    /* ========== Events ========== */

    event KyfStatusUpdated(address _address, bool _status);

    /* ========== Modifier ========== */

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Can only be called by owner"
        );
        _;
    }

    /* ========== View Functions ========== */

    function isVerified(
        address _user
    )
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < kyfInstancesArray.length; i++) {
            IKYFV2 kyfContract = IKYFV2(kyfInstancesArray[i]);
            if (kyfContract.checkVerified(_user) == true) {
                return true;
            }
        }

        return false;
    }

    /* ========== Owner Functions ========== */

    function transferOwnership(
        address _owner
    )
        public
        onlyOwner
    {
        owner = _owner;
    }

    function setApprovedKYFInstance(
        address _kyfContract,
        bool _status
    )
        public
        onlyOwner
    {
        if (_status == true) {
            kyfInstancesArray.push(_kyfContract);
            kyfInstances[_kyfContract] = true;
            emit KyfStatusUpdated(_kyfContract, true);
            return;
        }

        // Remove the kyfContract from the kyfInstancesArray array.
        for (uint i = 0; i < kyfInstancesArray.length; i++) {
            if (address(kyfInstancesArray[i]) == _kyfContract) {
                delete kyfInstancesArray[i];
                kyfInstancesArray[i] = kyfInstancesArray[kyfInstancesArray.length - 1];

                // Decrease the size of the array by one.
                kyfInstancesArray.length--;
                break;
            }
        }

        // And remove it from the synths mapping
        delete kyfInstances[_kyfContract];
        emit KyfStatusUpdated(_kyfContract, false);
    }

    /* ========== ERC20 Functions ========== */

    /**
     * @dev Returns the name of the token.
     */
    function name()
        public
        view
        returns (string memory)
    {
        return "ARC KYF Token";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol()
        public
        view
        returns (string memory)
    {
        return "ARCKYF";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals()
        public
        view
        returns (uint8)
    {
        return 0;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return kyfInstancesArray.length;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
        if (isVerified(account)) {
            return 1;
        }

        return 0;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        return false;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        return false;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return 0;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        return false;
    }

}