// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./StakingToken.sol";

contract SwappToken is StakingToken {
    address public LIQUIDITY_TRANSFORMER;
    address public YIELD_FARM_STABLE;
    address public YIELD_FARM_LP;
    address public tokenMinterDefiner;

    modifier onlyMinter() {
        require(
            msg.sender == LIQUIDITY_TRANSFORMER ||
            msg.sender == YIELD_FARM_STABLE ||
            msg.sender == YIELD_FARM_LP,
            'SWAPP: Invalid token minter'
        );
        _;
    }

    constructor() ERC20("Swapp Token", "SWAPP") {
        tokenMinterDefiner = msg.sender;

        // mint 1,000,000,000 tokens to test
        _mint(0x6bDcb2F88fDc200eAa21368E2c506dCd97C591d8, 1000000000E18);
    }

    receive() external payable {
        revert();
    }

    function setMinters(
        address _transformer,
        address _yieldFarmStable,
        address _yieldFarmLP
    ) external {
        require(tokenMinterDefiner == msg.sender);
        LIQUIDITY_TRANSFORMER = _transformer;
        YIELD_FARM_STABLE = _yieldFarmStable;
        YIELD_FARM_LP = _yieldFarmLP;
    }

    function burnMinterDefiner() external {
        require(tokenMinterDefiner == msg.sender);
        tokenMinterDefiner = address(0x0);
    }

    /**
     * @notice allows liquidityTransformer to mint supply
     * @dev executed from liquidityTransformer upon UNISWAP transfer
     * and during reservation payout to contributors and referrers
     * @param _investorAddress address for minting SWAPP tokens
     * @param _amount of tokens to mint for _investorAddress
     */
    function mintSupply(address _investorAddress, uint256 _amount) external onlyMinter {
        _mint(_investorAddress, _amount);
    }

    /**
     * @notice allows to grant permission to CM referrer status
     * @dev called from liquidityTransformer if user referred 50 ETH
     * @param _referrer - address that becomes a CM reffer
     */
    function giveStatus(address _referrer) external onlyMinter {
        criticalMass[_referrer].totalAmount = THRESHOLD_LIMIT;
        criticalMass[_referrer].activationDay = nextSwappDay();
    }

    /**
     * @notice allows to create stake directly with ETH
     * if you don't have SWAPP tokens method will convert
     * and use amount returned from UNISWAP to open a stake
     * @param _lockDays amount of days it is locked for.
     * @param _referrer referrer address for +10% bonus
     */
    function createStakeWithETH(
        uint64 _lockDays,
        address _referrer
    ) external payable returns (bytes16, uint256, bytes16 referralID) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        uint256[] memory amounts = UNISWAP_ROUTER.swapExactETHForTokens{value: msg.value}(
            1,
            path,
            msg.sender,
            block.timestamp
        );

        return createStake(amounts[1], _lockDays, _referrer);
    }
}