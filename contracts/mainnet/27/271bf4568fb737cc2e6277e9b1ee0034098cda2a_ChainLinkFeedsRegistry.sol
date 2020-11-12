pragma solidity ^0.5.17;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface Oracle {
    function latestAnswer() external view returns(uint256);
}

contract ChainLinkFeedsRegistry {
    using SafeMath for uint;
  
    mapping(address => address) public assetsUSD;
    mapping(address => address) public assetsETH;
    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    address public governance;
    
    constructor () public {
        governance = msg.sender;
        assetsUSD[weth] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
        
        assetsUSD[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // wBTC
        assetsUSD[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // renBTC
        assetsUSD[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9; // DAI
        assetsUSD[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c; // LINK
        assetsUSD[0x408e41876cCCDC0F92210600ef50372656052a38] = 0x0f59666EDE214281e956cb3b2D0d69415AfF4A01; // REN
        assetsUSD[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699; // SNX
        
        
        assetsETH[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xdeb288F737066589598e9214E782fa5A8eD689e8; // wBTC
        assetsETH[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0xdeb288F737066589598e9214E782fa5A8eD689e8; // renBTC
        assetsETH[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0x773616E4d11A78F511299002da57A0a94577F1f4; // DAI
        assetsETH[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0xDC530D9457755926550b59e8ECcdaE7624181557; // LINK
        assetsETH[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2; // MKR
        assetsETH[0x408e41876cCCDC0F92210600ef50372656052a38] = 0x3147D7203354Dc06D9fd350c7a2437bcA92387a4; // REN
        assetsETH[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = 0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c; // SNX
        assetsETH[0x57Ab1ec28D129707052df4dF418D58a2D46d5f51] = 0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757; // SUSD
        assetsETH[0x0000000000085d4780B73119b644AE5ecd22b376] = 0x3886BA987236181D98F2401c507Fb8BeA7871dF2; // TUSD
        assetsETH[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4; // USDC
        assetsETH[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46; // USDT
        assetsETH[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = 0xB7B1C8F4095D819BDAE25e7a63393CDF21fd02Ea; // YFI
    }
    
    // Returns 1e8
    function getPriceUSD(address _asset) external view returns(uint256) {
        uint256 _price = 0;
        if (assetsUSD[_asset] != address(0)) {
            _price = Oracle(assetsUSD[_asset]).latestAnswer();
        } else if (assetsETH[_asset] != address(0)) {
            _price = Oracle(assetsETH[_asset]).latestAnswer();
            _price = _price.mul(Oracle(assetsUSD[weth]).latestAnswer()).div(1e18);
        }
        return _price;
    }
    
    // Returns 1e18
    function getPriceETH(address _asset) external view returns(uint256) {
        uint256 _price = 0;
        if (assetsETH[_asset] != address(0)) {
            _price = Oracle(assetsETH[_asset]).latestAnswer();
        }
        return _price;
    }
    
    function addFeedETH(address _asset, address _feed) external {
        require(msg.sender == governance, "!governance");
        assetsETH[_asset] = _feed;
    }
    
    function addFeedUSD(address _asset, address _feed) external {
        require(msg.sender == governance, "!governance");
        assetsUSD[_asset] = _feed;
    }
    
    function removeFeedETH(address _asset) external {
        require(msg.sender == governance, "!governance");
        assetsETH[_asset] = address(0);
    }
    
    function removeFeedUSD(address _asset) external {
        require(msg.sender == governance, "!governance");
        assetsUSD[_asset] = address(0);
    }

}