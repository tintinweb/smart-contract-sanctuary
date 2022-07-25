// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FractCompoundStrategy.sol";
import "./CErc20Interface.sol";
import "./ComptrollerInterface.sol";
import "./CTokenStorage.sol";
import "./IPriceFeed.sol";
import "./SafeERC20.sol";

contract FractCompoundStrategyMOVR is FractCompoundStrategy {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        CONTRACT VARIABLES
    //////////////////////////////////////////////////////////////*/

    ComptrollerInterface public comptroller;

    address public constant MOONWELL_TOKEN =
        0xBb8d88bcD9749636BC4D2bE22aaC4Bb3B01A58F1;

    /**
     * @notice Constructor
     * @param _name The name of the receipt token that will be minted by this strategy.
     * @param _symbol The symbol of the receipt token that will be minted by this strategy.
     * @param _decimals The decimal level for the receipt token.
     * @param _depositToken The address of the deposit token.
     * @param _priceFeed The address of the price feed for primary oracle.
     * @param _swapRouter The address of the uni v2 style router for swapping.
     * @param _comptroller The address of the primary comptroller.
     * @param _chainToken The address of the chain's native token (wrapped).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _depositToken,
        address _priceFeed,
        address _swapRouter,
        address _comptroller,
        address _chainToken
    )
        FractCompoundStrategy(
            _name,
            _symbol,
            _decimals,
            _depositToken,
            _priceFeed,
            _swapRouter,
            _chainToken
        )
    {
        name = _name;
        symbol = _symbol;
        depositToken = IERC20(_depositToken);
        priceFeed = IPriceFeed(_priceFeed);
        swapRouter = IUniswapV2Router02(_swapRouter);
        comptroller = ComptrollerInterface(_comptroller);
        chainToken = _chainToken;
    }

    /*///////////////////////////////////////////////////////////////
                        EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Emitted when the contract receives MOVR.
     * @param sender The addresse that sends MOVR.
     * @param amount The amount of MOVR sent.
     */
    event Received(address sender, uint256 amount);

    /**
     * @notice Emitted when tokens are deposited into the strategy contract.
     * @param token Specifies the token that was deposited.
     * @param amount Specifies the amount that was deposited.
     */
    event EmergencyDeposit(address token, uint amount);

    /*///////////////////////////////////////////////////////////////
                        RECEIVE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    /*///////////////////////////////////////////////////////////////
                        HARVEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claim and swap simultaneously by market.
     * @param mintAddress The cToken market to claim on.
     * @param borrowAddress The cToken market to claim on and swap into.
     */
    function harvestByMarket(address mintAddress, address borrowAddress)
        external onlyOwner
    {
        require(mintAddress != address(0), "0 Address");
        require(borrowAddress != address(0), "0 Address");

        uint256 rewardBalance;
        uint256 ethBalance;
        address underlyingAddress;

        claimRewardsByMarket(mintAddress, borrowAddress);
        rewardBalance = IERC20(MOONWELL_TOKEN).balanceOf(address(this));
        ethBalance = address(this).balance;
        underlyingAddress = CErc20Interface(borrowAddress).underlying();

        swapTokens(MOONWELL_TOKEN, underlyingAddress, rewardBalance, 0);
        swapETH(underlyingAddress, ethBalance, 0);
    }

    /**
     * @notice Claim rewards from moonwell comptroller by market.
     * @param mintAddress The cToken market to claim on.
     * @param borrowAddress The cToken market to claim on.
     */
    function claimRewardsByMarket(address mintAddress, address borrowAddress)
        public onlyOwner
    {
        require(mintAddress != address(0), "0 Address");
        require(borrowAddress != address(0), "0 Address");

        address[] memory claimAddresses = new address[](2);
        claimAddresses[0] = mintAddress;
        claimAddresses[1] = borrowAddress;
        //claim tokens
        comptroller.claimReward(0, address(this), claimAddresses);
        comptroller.claimReward(1, address(this), claimAddresses);
    }

    /*///////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function emergencyDeposit(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Deposit amount must be greater than 0");
        emit EmergencyDeposit(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount), "Deposit Failed");
        
    }
}