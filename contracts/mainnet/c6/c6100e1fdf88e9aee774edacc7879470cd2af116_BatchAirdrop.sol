/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

pragma solidity 0.8.7;

contract BatchAirdrop {
    
    address private WFDCContract = 0x311C6769461e1d2173481F8d789AF00B39DF6d75;//0x63D6e1E46d3b72D2BB30D3A8D2C811cCb180Ab60;//0x8d2971C02ec4aE356278ECB094B349b61Fc2820A;
    WrappedFreedomDividendCoin private WFDCToken;
    
    uint private airdropAmount = 11111;//1111;
    
    address private owner;
    
    constructor() {
        owner = msg.sender;
        WFDCToken = WrappedFreedomDividendCoin(WFDCContract);
    }
    
    /*function test() external view returns(uint8) {
        return WFDCToken.decimals();
    }*/
    function batchAirdrop(address[] calldata airdropAddresses) external returns(bool) {
        require(msg.sender == owner, 'only owner');
        
        for (uint airdropCount=0; airdropCount < airdropAddresses.length; airdropCount++) {
            if (WFDCToken.balanceOf(address(this)) >= airdropAmount) {
                TransferHelper.safeTransfer(
                  WFDCContract, airdropAddresses[airdropCount], airdropAmount
                );
            }
        }
        
        return true;
    }
}

interface WrappedFreedomDividendCoin {
  function decimals() external view returns (uint8);
  
  function balanceOf(address Address) external view returns (uint);
  
  //function transfer(address to, uint value) external returns (bool);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}