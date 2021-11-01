pragma solidity ^0.5.0;

import "./SPTStake.sol";
import "./ERC20Capped.sol";
import "./ERC20Mintable.sol";

contract SPTCoin is ERC20Capped {
    using SafeMath for uint256;

    string public name = "SPT";
    string public symbol = "SPT";
    uint8 public decimals = 18;

    // stake contract addresses
    uint32 private _stakeCount = 0;
    uint256 private _stakeTotal = 0;

    mapping (uint32 => address) private _stakes;

    // NewStake event
    event NewStake(address indexed account);


    /**
     * - cap: 1000000000000000000000000000 (1 bil)
     * - init: 50000000000000000000000000 (50 millones)
     */
    constructor (uint256 cap, uint256 init) public ERC20Capped(cap) {
        require(cap > 1000000000000000000, "SPTCoin: cap must greater than 10^18");

        // mint to sender init tokens
        mint(msg.sender, init);
    }

    /**
     * Requirements:
     * - the caller must have the `StakerRole`.
     *
     * return new stake address.
     */
    function stake(uint32 id, address beneficiary, uint256 amount, uint256 releaseAmount, uint32 releaseTime)
        public onlyMinter returns (address) {
        require(_stakes[id] == address(0), "SPTCoin: stake with ID already exist");
        require(balanceOf(msg.sender) >= amount, "SPTCoin: there is not enough tokens to stake");
        require(amount >= releaseAmount, "SPTCoin: there is not enough tokens to stake");

        // create new stake
        SPTStake newStake = new SPTStake(SPTCoin(address(this)), beneficiary, releaseAmount, releaseTime);

        emit NewStake(address(newStake));

        // transfer amount of token to stake address
        require(transfer(address(newStake), amount), "SPTCoin: transfer tokens to new stake failed");

        // update data
        _stakeCount += 1;
        _stakeTotal = _stakeTotal.add(amount);
        _stakes[id] = address(newStake);

        return _stakes[id];
    }

    /**
     * Get a stake contract address.
     */
    function stakeAddress(uint32 id) public view returns (address) {
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