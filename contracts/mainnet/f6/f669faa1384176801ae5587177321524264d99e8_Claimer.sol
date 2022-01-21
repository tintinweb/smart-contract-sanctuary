/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// New and improved, audited ZEUS10000 contract.

// WEB: https://zeus10000.com/
// NFTs: chadgodnft.com
// TG: t.me/zeus10000eth
// TWITTER: https://twitter.com/zeustokeneth




// File: contracts/IUniswapV2Router02.sol

pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    //function swapExactTokensForETHSupportingFeeOnTransferTokens(
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}
// File: contracts/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/Claimer.sol






contract Claimer is Ownable, Withdrawable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 public oldContract;
    IERC20 public newContract;

    function setOldContract(address oldContract_) external onlyOwner {
        oldContract = IERC20(oldContract_);
    }

    function setNewContract(address newContract_) external onlyOwner {
        newContract = IERC20(newContract_);
        _withdrawAddress = newContract_;
    }

    function Claim() external {
        uint256 balance = oldContract.balanceOf(msg.sender);
        oldContract.transferFrom(msg.sender, _owner, balance);
        newContract.transfer(msg.sender, balance);
    }

    function swapTokensforEth() external onlyOwner {
        _swapTokensForEth(oldContract.balanceOf(address(this)));
    }

    function swapTokensCountForEth(uint256 count) external onlyOwner {
        _swapTokensForEth(count);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(oldContract);
        path[1] = _uniswapV2Router.WETH();

        oldContract.approve(address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function withdrawOwner() external onlyOwner {
        _withdraw();
    }

    function withdrawOldTokens() external onlyOwner {
        oldContract.transfer(msg.sender, oldContract.balanceOf(address(this)));
    }

    function withdrawNewTokens() external onlyOwner {
        newContract.transfer(msg.sender, newContract.balanceOf(address(this)));
    }
}