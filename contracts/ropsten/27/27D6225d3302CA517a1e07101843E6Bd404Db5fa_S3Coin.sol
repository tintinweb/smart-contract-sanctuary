pragma solidity ^0.5.0;

import "./S3Stake.sol";
import "./ERC20Capped.sol";
import "./ERC20Mintable.sol";

contract S3Coin is ERC20Capped {
    using SafeMath for uint256;

    string public name = "S3 COIN";
    string public symbol = "S3C";
    uint8 public decimals = 18;

    // stake contract addresses
    uint private _stakeCount = 0;
    uint256 private _stakeTotal = 0;

    mapping (uint => address) private _stakes;

    // NewStake event
    event NewStake(address indexed account);

    constructor (uint256 cap, uint256 init) public ERC20Capped(cap) {
        // mint to sender init tokens
        mint(msg.sender, init);
    }

    /**
     * Requirements:
     * - the caller must have the `StakerRole`.
     *
     * return new stake address.
     */
    function stake(uint id, address beneficiary, uint256 amount, uint256 releaseTime, uint256 releaseAmount)
        public onlyMinter returns (address) {
        require(balanceOf(msg.sender) > amount, "S3Coin: there is no more token to stake");

        // create new stake
        S3Stake newStake = new S3Stake(IERC20(address(this)), beneficiary, releaseTime, releaseAmount);

        _stakeCount += 1;
        _stakeTotal = _stakeTotal.add(amount);
        _stakes[id] = address(newStake);

        emit NewStake(address(newStake));

        // transfer amount of token to stake address
        require(transfer(address(newStake), amount), "S3Coin: transfer stake tokens failed");
    }

    /**
     * Get a stake contract address.
     */
    function stakeAddress(uint id) public view returns (address) {
        return _stakes[id];
    }

    /**
     * Get number of stakes.
     */
    function stakeCount() public view returns (uint) {
        return _stakeCount;
    }

    /**
     * Get total tokens were staked.
     */
    function stakeTotal() public view returns (uint256) {
        return _stakeTotal;
    }

}