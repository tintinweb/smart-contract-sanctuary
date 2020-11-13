// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
import "./Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract FakeHegicStakingETH is ERC20("Hegic ETH Staking Lot", "hlETH"), IHegicStakingETH {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    uint public LOT_PRICE = 888_000e18;
    IERC20 public token;

    uint public totalProfit;
    
    event Claim(address account, uint profit);

    constructor(IERC20 _token) public {
        totalProfit = 0;
        token = _token;
        _setupDecimals(0);
    }

    function sendProfit() external payable override {
        totalProfit = totalProfit.add(msg.value);
    }

    function claimProfit() external override returns (uint _profit) {
        _profit = totalProfit;
        require(_profit > 0, "Zero profit");
        emit Claim(msg.sender, _profit);   
        _transferProfit(_profit);
        totalProfit = totalProfit.sub(_profit);
    }

    function _transferProfit(uint _profit) internal {
        msg.sender.transfer(_profit);
    }

    function buy(uint _amount) external override {
        require(_amount > 0, "Amount is zero");
        _mint(msg.sender, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount.mul(LOT_PRICE));

    }

    function sell(uint _amount) external override {
        _burn(msg.sender, _amount);
        token.safeTransfer(msg.sender, _amount.mul(LOT_PRICE));
    }

    function profitOf(address) public view override returns (uint _totalProfit) {
        _totalProfit = totalProfit;
    }
}


contract FakeHegicStakingWBTC is ERC20("Hegic WBTC Staking Lot", "hlWBTC"), IHegicStakingERC20 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint public totalProfit;
    IERC20 public immutable WBTC;
    IERC20 public token;

    uint public LOT_PRICE = 888_000e18;

    event Claim(address account, uint profit);

    constructor(IERC20 _wbtc, IERC20 _token) public {
        WBTC = _wbtc;
        token = _token;
        totalProfit = 0;
        _setupDecimals(0);

    }

    function sendProfit(uint _amount) external override {
        WBTC.safeTransferFrom(msg.sender, address(this), _amount);
        totalProfit = totalProfit.add(_amount);
    }

    function claimProfit() external override returns (uint _profit) {
        _profit = totalProfit;
        require(_profit > 0, "Zero profit");
        emit Claim(msg.sender, _profit);   
        _transferProfit(_profit);
        totalProfit = totalProfit.sub(_profit);
    }

    function _transferProfit(uint _profit) internal {
        WBTC.safeTransfer(msg.sender, _profit);
    }

    function buy(uint _amount) external override {
        require(_amount > 0, "Amount is zero");
        _mint(msg.sender, _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount.mul(LOT_PRICE));
    }

    function sell(uint _amount) external override {
        _burn(msg.sender, _amount);
        token.safeTransfer(msg.sender, _amount.mul(LOT_PRICE));
    }

    function profitOf(address) public view override returns (uint _totalProfit) {
        _totalProfit = totalProfit;
    }
}

contract FakeWBTC is ERC20("FakeWBTC", "FAKE") {
    constructor() public {
        _setupDecimals(8);
    }

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}


contract FakeHEGIC is ERC20("FakeHEGIC", "FAKEH") {
    using SafeERC20 for ERC20;

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
