// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./TWAPOracleUpdater.sol";

contract Gyro is TWAPOracleUpdater {
    using SafeMath for uint256;
    address[] public nonCirculatingAddresses;

    constructor() TWAPOracleUpdater("Infinity DAO", "INF", 9) {}

    function mint(address account_, uint256 amount_) external onlyMinter() {
        _mint(account_, amount_);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount_) external virtual {
        _burn(msg.sender, amount_);
    }

    /*
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account_, uint256 amount_) external virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal virtual {
        uint256 decreasedAllowance =
            allowance(account_, msg.sender).sub(amount_, "ERC20: burn amount exceeds allowance");

        _approve(account_, msg.sender, decreasedAllowance);
        _burn(account_, amount_);
    }

    function circulatingSupply() external view returns (uint256) {
        uint256 circulating = totalSupply().sub(_nonCirculatingSupply());

        return circulating;
    }

    function getNonCirculatingSupply() public view returns (uint256) {
        return _nonCirculatingSupply();
    }

    function _nonCirculatingSupply() internal view returns (uint256) {
        uint256 nonCirculatingGyro;

        for (uint256 i = 0; i < nonCirculatingAddresses.length; i = i.add(1)) {
            nonCirculatingGyro = nonCirculatingGyro.add(balanceOf(nonCirculatingAddresses[i]));
        }

        return nonCirculatingGyro;
    }

    function setNonCirculatingAddresses(address[] calldata nonCirculatingAddresses_)
        external
        onlyOwner()
        returns (bool)
    {
        nonCirculatingAddresses = nonCirculatingAddresses_;

        return true;
    }
}