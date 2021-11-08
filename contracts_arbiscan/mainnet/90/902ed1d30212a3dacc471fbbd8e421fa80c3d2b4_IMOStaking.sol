// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./ISource.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

/**
 * @title IMOStaking
 * @author Alexander Schlindwein
 *
 * Staking contract for IMO.
 * Users can deposit IMO and receive additional
 * IMO payouts coming from different sources.
 */
contract IMOStaking is ERC20, Ownable {
    
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public _imo;
    EnumerableSet.AddressSet internal _sources;

    event Deposit(address indexed user, uint imoAmount, uint shares);
    event Withdraw(address indexed user, uint imoAmount, uint shares);
    event SourceAdded(address indexed source);
    event SourceRemoved(address indexed source);

    /**
     * Initializes the contract.
     *
     * @param imo The address of the IMO token
     * @param owner The address of the owner
     */
    constructor(address imo, address owner) public {
        require(imo != address(0), "invalid-params");
        setOwnerInternal(owner); // Checks owner to be non zero
        _imo = IERC20(imo);

        _name = "Staked IMO";
        _symbol = "xIMO";
        _decimals = 18;
    }

    /**
     * Deposits IMO tokens to receive shares
     *
     * @param amount The amount of IMO to deposit
     *
     * @return The amount of shares minted
     */
    function deposit(uint amount) external returns (uint) {
        require(amount > 0, "invalid-amount");
        pull();

        IERC20 imo = _imo;
        address user = msg.sender;
        uint currentBalance = imo.balanceOf(address(this));
        uint currentShares = totalSupply();

        uint mintAmount;
        if (currentBalance == 0 || currentShares == 0) {
            mintAmount = amount;
        } else {
            mintAmount = amount.mul(currentShares).div(currentBalance);
        }

        require(imo.transferFrom(user, address(this), amount), "transfer-failed");
        _mint(user, mintAmount);

        emit Deposit(user, amount, mintAmount);
    
        return mintAmount;
    }

    /**
     * Withdraws shares to receive IMO.
     *
     * @param shares The amount of shares to withdraw.
     *
     * @return The amount of IMO paid out
     */
    function withdraw(uint shares) external returns (uint) {
        require(shares > 0, "invalid-shares");
        pull();

        IERC20 imo = _imo;
        address user = msg.sender;
        uint currentBalance = imo.balanceOf(address(this));
        uint currentShares = totalSupply();
        uint payoutAmount = shares.mul(currentBalance).div(currentShares);

        _burn(user, shares);
        require(imo.transfer(user, payoutAmount), "transfer-failed");

        emit Withdraw(user, payoutAmount, shares);
    
        return payoutAmount;
    }

    /**
     * Pulls IMO from the sources. 
     * May be called by anyone.
     */
    function pull() public {
        uint numSources = _sources.length();
        for(uint i = 0; i < numSources; i++) {
            ISource source = ISource(_sources.at(i));
            source.pull();
        }
    }

    /**
     * Returns an array of the sources.
     *
     * @return An array of the sources.
     */
    function getSources() external view returns (address[] memory) {
        uint length = _sources.length();
        address[] memory sources = new address[](length);

        for(uint i = 0; i < length; i++) {
            sources[i] = _sources.at(i);
        }

        return sources;
    }

    /**
     * Adds a source.
     * May only be called by the owner.
     *
     * @param source The address of the source to be added.
     */
    function addSource(address source) external onlyOwner {
        require(source != address(0), "invalid-source");
        require(_sources.add(source), "already-added");
        emit SourceAdded(source);
    }

    /**
     * Removes a source.
     * May only be called by the owner.
     *
     * @param source The address of the source to be removed.
     */
    function removeSource(address source) external onlyOwner {
        require(source != address(0), "invalid-source");
        require(_sources.remove(source), "no-source");
        emit SourceRemoved(source);
    }
}