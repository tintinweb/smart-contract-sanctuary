// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

import "./LiquidityToken.sol";

contract WiseToken is LiquidityToken {

    address public LIQUIDITY_TRANSFORMER;
    address public transformerGateKeeper;

    constructor() ERC20("Wise Token", "WISE") {
        transformerGateKeeper = msg.sender;
    }

    receive() external payable {
        revert();
    }

    /**
     * @notice ability to define liquidity transformer contract
     * @dev this method renounce transformerGateKeeper access
     * @param _immutableTransformer contract address
     */
    function setLiquidityTransfomer(
        address _immutableTransformer
    )
        external
    {
        require(
            transformerGateKeeper == msg.sender
            // 'WISE: transformer defined'
        );
        LIQUIDITY_TRANSFORMER = _immutableTransformer;
        transformerGateKeeper = address(0x0);
    }

    /**
     * @notice allows liquidityTransformer to mint supply
     * @dev executed from liquidityTransformer upon UNISWAP transfer
     * and during reservation payout to contributors and referrers
     * @param _investorAddress address for minting WISE tokens
     * @param _amount of tokens to mint for _investorAddress
     */
    function mintSupply(
        address _investorAddress,
        uint256 _amount
    )
        external
    {
        require(
            msg.sender == LIQUIDITY_TRANSFORMER
            // 'WISE: wrong transformer'
        );

        _mint(
            _investorAddress,
            _amount
        );
    }

    /**
     * @notice allows to grant permission to CM referrer status
     * @dev called from liquidityTransformer if user referred 50 ETH
     * @param _referrer - address that becomes a CM reffer
     */
    function giveStatus(
        address _referrer
    )
        external
    {
        require(
            msg.sender == LIQUIDITY_TRANSFORMER
            // 'WISE: wrong transformer'
        );
        criticalMass[_referrer].totalAmount = THRESHOLD_LIMIT;
        criticalMass[_referrer].activationDay = _nextWiseDay();
    }

    /**
     * @notice allows to create stake directly with ETH
     * if you don't have WISE tokens method will convert
     * and use amount returned from UNISWAP to open a stake
     * @param _lockDays amount of days it is locked for.
     * @param _referrer referrer address for +10% bonus
     */
    function createStakeWithETH(
        uint64 _lockDays,
        address _referrer
    )
        external
        payable
        returns (bytes16, uint256, bytes16 referralID)
    {
        address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(this);

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactETHForTokens{value: msg.value}(
            1,
            path,
            msg.sender,
            block.timestamp + 2 hours
        );

        return createStake(
            amounts[1],
            _lockDays,
            _referrer
        );
    }

    /**
     * @notice allows to create stake with another token
     * if you don't have WISE tokens method will convert
     * and use amount returned from UNISWAP to open a stake
     * @dev the token must have WETH pair on UNISWAP
     * @param _tokenAddress any ERC20 token address
     * @param _tokenAmount amount to be converted to WISE
     * @param _lockDays amount of days it is locked for.
     * @param _referrer referrer address for +10% bonus
     */
    function createStakeWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _lockDays,
        address _referrer
    )
        external
        returns (bytes16, uint256, bytes16 referralID)
    {
        ERC20TokenI token = ERC20TokenI(
            _tokenAddress
        );

        token.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        token.approve(
            address(UNISWAP_ROUTER),
            _tokenAmount
        );

        address[] memory path = _preparePath(
            _tokenAddress,
            address(this)
        );

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactTokensForTokens(
            _tokenAmount,
            1,
            path,
            msg.sender,
            block.timestamp + 2 hours
        );

        return createStake(
            amounts[2],
            _lockDays,
            _referrer
        );
    }
}