pragma solidity 0.6.12;
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
// DintSafe is the coolest warehouse in town. You come in with some Dint, and leave with more! The longer you stay, the more Dint you get.
//
// This contract handles swapping to and from xDint, DintSwap's staking token.
contract DintSafe is ERC20("DintSafe", "xDINT") {
    using SafeMath for uint256;
    IERC20 public dint;
    uint256 public FEE = 3;
    // Define the Dint token contract
    constructor(IERC20 _dint) public {
        dint = _dint;
    }
    
    // Enter the warehouse. store some DINTs. Earn some shares.
    // Locks Dint and mints xDint
    function enter(uint256 _amount) public {
        // Gets the amount of Dint locked in the contract
        uint256 totalDint = dint.balanceOf(address(this));
        // Gets the amount of xDint in existence
        uint256 totalShares = totalSupply();
        // If no xDint exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalDint == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xDint the Dint is worth. The ratio will change overtime, as xDint is burned/minted and Dint deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalDint);
            _mint(msg.sender, what);
        }
        // Lock the Dint in the contract
        dint.transferFrom(msg.sender, address(this), _amount);
    }
    // Leave the warehouse. Claim back your DINTs.
    // Unclocks the staked + gained Dint and burns xDint
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint dintBal = dint.balanceOf(address(this));
        uint256 what = _share.mul(dintBal).div(totalShares);
        uint fee = _getWithdrawFee(what);
        _burn(msg.sender, _share);
        dint.transfer(msg.sender, what.sub(fee));
    }
    function _getWithdrawFee(uint liquidity) private view returns (uint withdrawFee) {
        withdrawFee = liquidity.mul(FEE).div(1000);
    }
}