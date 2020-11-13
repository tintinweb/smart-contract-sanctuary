// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./Owned.sol";

contract WhiteList is Owned {
    /// @notice Users with permissions
    mapping(address => uint256) public whiter;

    /// @notice Append address into whiteList successevent
    event AppendWhiter(address adder);

    /// @notice Remove address into whiteList successevent
    event RemoveWhiter(address remover);

    /**
     * @notice Construct a new WhiteList, default owner in whiteList
     */
    constructor() internal {
        appendWhiter(owner);
    }

    modifier onlyWhiter() {
        require(isWhiter(), "WhiteList: msg.sender not in whilteList.");
        _;
    }

    /**
     * @notice Only onwer can append address into whitelist
     * @param account The address not added, can added to the whitelist
     */
    function appendWhiter(address account) public onlyOwner {
        require(account != address(0), "WhiteList: address not zero");
        require(
            !isWhiter(account),
            "WhiteListe: the account exsit whilteList yet"
        );
        whiter[account] = 1;
        emit AppendWhiter(account);
    }

    /**
     * @notice Only onwer can remove address into whitelist
     * @param account The address in whitelist yet
     */
    function removeWhiter(address account) public onlyOwner {
        require(
            isWhiter(account),
            "WhiteListe: the account not exist whilteList"
        );
        delete whiter[account];
        emit RemoveWhiter(account);
    }

    /**
     * @notice Check whether acccount in whitelist
     * @param account Any address
     */
    function isWhiter(address account) public view returns (bool) {
        return whiter[account] == 1;
    }

    /**
     * @notice Check whether msg.sender in whitelist overrides.
     */
    function isWhiter() public view returns (bool) {
        return isWhiter(msg.sender);
    }
}
