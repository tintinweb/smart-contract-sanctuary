/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.8.2;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address spender, address owner)
        external
        view
        returns (uint256);
}

interface IOracle {
    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 price
    ) external view returns (uint256);

    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

/**
 * Static token data
 */
struct TokenMetadata {
    address id; // Token address
    string name; // Token name
    string symbol; // Token symbol
    uint8 decimals; // Token decimals
}

contract BalancesHelper {
    address public owner; // Owner can update storage slots
    address public oracleAddress; // Oracle address

    struct TokenBalance {
        address tokenId; // Token address
        uint256 priceUsdc; // Token price in USDC (6 decimals)
        uint256 balance; // Token balance in underlying token
        uint256 balanceUsdc; // Token balance value in USDC (6 decimals)
    }

    struct TokenPrice {
        address tokenId; // Token address
        uint256 priceUsdc; // Token price in USDC (6 decimals)
    }

    constructor(address _oracleAddress) {
        owner = msg.sender;
        oracleAddress = _oracleAddress;
    }

    /**
     * Fetch token balances given an array of token addresses and account address
     */
    function tokensBalances(
        address accountAddress,
        address[] memory tokensAddresses
    ) public view returns (TokenBalance[] memory) {
        TokenBalance[] memory _tokensBalances =
            new TokenBalance[](tokensAddresses.length);
        for (
            uint256 tokenIdx = 0;
            tokenIdx < tokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = tokensAddresses[tokenIdx];
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(accountAddress);
            uint256 priceUsdc =
                IOracle(oracleAddress).getPriceUsdcRecommended(tokenAddress);
            uint256 balanceUsdc =
                IOracle(oracleAddress).getNormalizedValueUsdc(
                    tokenAddress,
                    balance,
                    priceUsdc
                );

            _tokensBalances[tokenIdx] = TokenBalance({
                tokenId: tokenAddress,
                priceUsdc: priceUsdc,
                balance: balance,
                balanceUsdc: balanceUsdc
            });
        }
        return _tokensBalances;
    }

    /**
     * Fetch token prices given an array of token addresses
     */
    function tokensPrices(address[] memory tokensAddresses)
        public
        view
        returns (TokenPrice[] memory)
    {
        TokenPrice[] memory _tokensPrices =
            new TokenPrice[](tokensAddresses.length);
        for (
            uint256 tokenIdx = 0;
            tokenIdx < tokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = tokensAddresses[tokenIdx];
            _tokensPrices[tokenIdx] = TokenPrice({
                tokenId: tokenAddress,
                priceUsdc: IOracle(oracleAddress).getPriceUsdcRecommended(
                    tokenAddress
                )
            });
        }
        return _tokensPrices;
    }

    /**
     * Fetch basic static token metadata
     */
    function tokensMetadata(address[] memory tokensAddresses)
        public
        view
        returns (TokenMetadata[] memory)
    {
        TokenMetadata[] memory _tokensMetadata =
            new TokenMetadata[](tokensAddresses.length);
        for (
            uint256 tokenIdx = 0;
            tokenIdx < tokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = tokensAddresses[tokenIdx];
            IERC20 _token = IERC20(tokenAddress);
            _tokensMetadata[tokenIdx] = TokenMetadata({
                id: tokenAddress,
                name: _token.name(),
                symbol: _token.symbol(),
                decimals: _token.decimals()
            });
        }
        return _tokensMetadata;
    }

    function updateSlot(bytes32 slot, bytes32 value) external {
        require(msg.sender == owner);
        assembly {
            sstore(slot, value)
        }
    }
}