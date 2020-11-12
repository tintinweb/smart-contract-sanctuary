/*

    /     |  __    / ____|
   /      | |__) | | |
  / /    |  _  /  | |
 / ____   | |    | |____
/_/    _ |_|  _  _____|

* ARC: global/SkillsetMetadata.sol
*
* Latest source (may be newer): https://github.com/arcxgame/contracts/blob/master/contracts/global/SkillsetMetadata.sol
*
* Contract Dependencies: 
*	- Adminable
*	- SkillsetMetadataStorageV1
* Libraries: 
*	- Storage
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


pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// SPDX-License-Identifier: MIT


library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}


/**
 * @title Adminable
 * @author dYdX
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}


contract SkillsetMetadataStorageV1 {

    mapping (address => bool) public approvedSkillsets;

    address[] public skillsetsArray;

    mapping (address => uint256) public maxLevel;

}

contract SkillsetMetadata is Adminable, SkillsetMetadataStorageV1 {

    /* ========== Events ========== */

    event SkillsetStatusUpdated(address _token, bool _status);
    event SkillsetMaxLevelSet(address _token, uint256 _level);

    /* ========== View Functions ========== */

    function getSkillsetBalance(
        address _token,
        address _user
    )
        public
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_user);
    }

    function isValidSkillset(
        address _token
    )
        public
        view
        returns (bool)
    {
        return approvedSkillsets[_token];
    }

    function getAllSkillsets()
        public
        view
        returns (address[] memory)
    {
        return skillsetsArray;
    }

    /* ========== Admin Functions ========== */

    function addSkillsetToken(
        address _token
    )
        public
        onlyAdmin
    {
        require(
            approvedSkillsets[_token] != true,
            "Skillset has already been added"
        );

        skillsetsArray.push(_token);
        approvedSkillsets[_token] = true;

        emit SkillsetStatusUpdated(_token, true);
    }

    function removeSkillsetToken(
        address _token
    )
        public
        onlyAdmin
    {
        require(
            approvedSkillsets[_token] == true,
            "Skillset does not exist"
        );

        for (uint i = 0; i < skillsetsArray.length; i++) {
            if (skillsetsArray[i] == _token) {
                delete skillsetsArray[i];
                skillsetsArray[i] = skillsetsArray[skillsetsArray.length - 1];
                skillsetsArray.length--;
                break;
            }
        }

        delete approvedSkillsets[_token];

        emit SkillsetStatusUpdated(_token, false);
    }

    function setMaxLevel(
        address _token,
        uint256 _level
    )
        public
        onlyAdmin
    {
        maxLevel[_token] = _level;

        emit SkillsetMaxLevelSet(_token, _level);

    }

}