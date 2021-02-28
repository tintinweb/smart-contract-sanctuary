/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface OrFeedInterface {
    function getExchangeRate ( string calldata fromSymbol, string calldata  toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
    function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
    function getTokenAddress ( string calldata  symbol ) external view returns ( address );
    function getSynthBytes32 ( string calldata  symbol ) external view returns ( bytes32 );
    function getForexAddress ( string calldata symbol ) external view returns ( address );
    function arb(address  fundsReturnToAddress,  address liquidityProviderContractAddress, string[] calldata   tokens,  uint256 amount, string[] calldata  exchanges) external payable returns (bool);
}

interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 digits);

    function totalSupply() external view returns (uint256 supply);
}


// to support backward compatible contract name -- so function signature remains same
abstract contract ERC20 is IERC20 {

}

interface IKyberNetworkProxy {

    event ExecuteTrade(
        address indexed trader,
        IERC20 src,
        IERC20 dest,
        address destAddress,
        uint256 actualSrcAmount,
        uint256 actualDestAmount,
        address platformWallet,
        uint256 platformFeeBps
    );

    /// @notice backward compatible
    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function trade(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);

}


// ERC20 Token Smart Contract
contract oracleInfo {

    address owner;
    OrFeedInterface orfeed = OrFeedInterface(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);
    address kyberProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
    IKyberNetworkProxy kyberProxy = IKyberNetworkProxy(kyberProxyAddress);

    constructor() public payable {
        owner = msg.sender;

    }
    
    function getTokenPrice(string memory fromParam, string memory toParam, string memory venue, uint256 amount) public view returns (uint256) {
         return orfeed.getExchangeRate(fromParam, toParam, venue, amount);

    }

    function getPriceFromOracle(string memory fromParam, string memory toParam, uint256 amount) public view returns (uint256){

        address sellToken = orfeed.getTokenAddress(fromParam);
        address buyToken = orfeed.getTokenAddress(toParam);

        ERC20 sellToken1 = ERC20(sellToken);
        ERC20 buyToken1 = ERC20(buyToken);

        uint sellDecim = sellToken1.decimals();
        uint buyDecim = buyToken1.decimals();

        // uint base = 1^sellDecim;
        // uint adding;
        (uint256 price,) = kyberProxy.getExpectedRate(sellToken1, buyToken1, amount);


        uint initResp = (((price * 1000000) / (10 ** 18)) * (amount)) / 1000000;
        uint256 diff;
        if (sellDecim > buyDecim) {
            diff = sellDecim - buyDecim;
            initResp = initResp / (10 ** diff);
            return initResp;
        }

        else if (sellDecim < buyDecim) {
            diff = buyDecim - sellDecim;
            initResp = initResp * (10 ** diff);
            return initResp;
        }
        else {
            return initResp;
        }


    }


}