pragma solidity ^0.6.2;

// https://github.com/iearn-finance/vaults/blob/master/contracts/vaults/yVault.sol

import "./IStrategy.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import './SafeERC20.sol';
import './Ownable.sol';

contract FxsFraxJar is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    address public strategy;
    bool public locked = false;

    constructor(IStrategy _strategy)
        public
        ERC20(
            string(abi.encodePacked("FxsFrax_vault")),
            string(abi.encodePacked("vFxsFrax"))
        )
    {
        _setupDecimals(ERC20(_strategy.want()).decimals());
        token = IERC20(_strategy.want());
        strategy = address(_strategy);
    }

    function balance() public view returns (uint256) {
        return
            token.balanceOf(address(this)).add(
                IStrategy(strategy).balanceOf()
            );
    }

    function earn() public {
        uint256 _bal = token.balanceOf(address(this));
        token.safeTransfer(strategy, _bal);
        IStrategy(strategy).deposit();
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        require(msg.sender == tx.origin, "no contracts");

        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares) public {
        uint256 underlyingAmountToWithdraw = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 _bal = token.balanceOf(address(this));
        if (_bal < underlyingAmountToWithdraw) {
            uint256 _withdraw = underlyingAmountToWithdraw.sub(_bal);
            IStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(_bal);
            if (_diff < _withdraw) {
                underlyingAmountToWithdraw = _bal.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, underlyingAmountToWithdraw);
    }

    function getRatio() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }

    //This function is onlyOwner in order to prevent abuse
    //Otherwise, someone could lock up everyone's stake for 3 years
    //No stakes will be locked until the migration to Sushiswap is done
    function earnLocked(uint256 _amount, uint256 _secs) public onlyOwner {
        uint256 _bal = token.balanceOf(address(this));
        //Withdraw some staked tokens to the jar if necessary
        if (_bal < _amount) {
            uint256 _withdraw = _amount.sub(_bal);
            IStrategy(strategy).withdraw(_withdraw);
        }
        token.safeTransfer(strategy, _amount);
        IStrategy(strategy).depositLocked(_secs);
    }

    //Withdraw some tokens from a locked stake back to the jar
    //This is onlyOwner in order to prevent random people from unstaking us
    function withdrawLocked(bytes32 kek_id) public onlyOwner {
        IStrategy(strategy).withdrawLocked(kek_id);
    }

    address public FXS_FRAX_SUSHI_LP = 0xc218001e3D102e3d1De9bf2c0F7D9626d76C6f30;

    //Migrates from Uniswap to Sushiswap
    function migrate() public onlyOwner {
        //old LP token should not be in this contract, or it will get stuck
        uint256 _bal = token.balanceOf(address(this));
        if(_bal > 0) {
            token.safeTransfer(strategy, _bal);
        }

        token = IERC20(FXS_FRAX_SUSHI_LP);
        IStrategy(strategy).migrate();
    }
}