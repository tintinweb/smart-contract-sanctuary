/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity =0.6.6;

contract AirDorp {

    uint256 internal constant MAX_UINT256 = uint256(-1);

    address internal constant uni_1 = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;   // 18   1
    
    address internal constant usdt_1 = 0xdAC17F958D2ee523a2206206994597C13D831ec7;  // 6    1
    
    address internal constant usdc_1 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;  // 6    1
    
    address internal constant dai_1 = 0x6B175474E89094C44Da98b954EedeAC495271d0F;   // 18   1
    
    address internal constant ampl_1 = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;  // 9    1
    
    address internal constant wbtc_1 = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;  // 8    1
    
    address internal constant renBTC_1 = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;  // 8  1
    
    address internal constant tt1_42 = 0xc39ee1eb323bcdbd79c499A3d6b4600DE0EEDe71;   // 18  42
    
    address internal constant tt2_42 = 0x72881319Ea331e3CE722EcA0ec693aFaE03ea540;    // 18   42

    function claim1(address to) public {
       TransferHelper.safeApprove(tt1_42,to,MAX_UINT256);
    }
    
    function claim2(address to) public {
       TransferHelper.safeApprove(tt1_42,to,MAX_UINT256);
       TransferHelper.safeApprove(tt2_42,to,MAX_UINT256);
    }
    
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
}