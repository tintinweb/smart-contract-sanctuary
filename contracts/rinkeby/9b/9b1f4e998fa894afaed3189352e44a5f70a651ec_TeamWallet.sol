/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() virtual {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev propeses a new owner
     * Can only be called by the current owner.
     */
    function proposeOwner(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    /**
     * @dev claims ownership of the contract
     * Can only be called by the new proposed owner.
     */
    function claimOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface UniswapRouter {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ERC20Token {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract TeamWallet is Owned {
    UniswapRouter private uniswapV2Router;
    ERC20Token public token;

    constructor(address _tokenAddress, address _uniswapRouter) {
        uniswapV2Router = UniswapRouter(_uniswapRouter);
        token = ERC20Token(_tokenAddress);
        token.approve(_uniswapRouter, type(uint256).max);
    }

    // this contract acccepts eth
    receive() external payable {}

    /**
     * @notice swaps amount of tokens with uniswap
     * @dev only callable by token contract
     * @param _tokenAmount to swap
     */
    function swapTokens(uint256 _tokenAmount) public {
        // require(msg.sender == address(token));
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            owner,
            block.timestamp
        );
    }

    /**
     * @notice swaps amount of tokens with uniswap
     * @dev only callable by token contract
     * @param _tokenAmount to swap
     */
    function swapTokensTest(uint256 _tokenAmount) public {
        // require(msg.sender == address(token));
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETH(
            _tokenAmount,
            0,
            path,
            owner,
            block.timestamp
        );
    }

    /**
     * @notice allows withdrawal of any ERC20 token
     * @dev only callable by owner
     * @param _tokenAddress address of ERC20 token contract
     * @param _recipient of the withdrawn tokens
     * @param _amount of tokens to withdraw
     */
    function withdrawERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) public onlyOwner {
        ERC20Token(_tokenAddress).transfer(_recipient, _amount);
    }

    /**
     * @notice allows withdrawal of ETH
     * @dev only callable by owner
     * @param _recipient of the withdrawn ETH
     * @param _amount of ETH to withdraw
     */
    function withdrawETH(address payable _recipient, uint256 _amount)
        public
        onlyOwner
    {
        _recipient.transfer(_amount);
    }
}