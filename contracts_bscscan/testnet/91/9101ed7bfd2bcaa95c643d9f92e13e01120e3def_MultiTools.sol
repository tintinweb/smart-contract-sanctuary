// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol" ;
import "./payAPI.sol" ;

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



contract MultiTools is payAPI {

	function multiTransferToken(address token_,address[] calldata addr_,uint[] calldata amount_,uint payValue_) onlyMembersOrPay('tranferToken') external returns(bool) {
		_addPayInfo('tranferToken',payValue_) ;
        for(uint i; i < addr_.length; i++){
			TransferHelper.safeTransferFrom(token_,msg.sender,addr_[i],amount_[i]) ;
		}
        return true ;
	}

    function multiTransferETH(address[] calldata addr_,uint[] calldata value_,uint payValue_) onlyMembersOrPay('transferETH') payable external returns(bool){
        _addPayInfo('transferETH',payValue_) ;
        for(uint i; i < addr_.length; i++){
			payable(addr_[i]).transfer(value_[i]) ;
		}
        return true ;
    }

    function abiEncode(string calldata function_) public pure returns(bytes4) {
       return bytes4(keccak256(bytes(function_)));
    }


    function createToken(string memory name_, string memory symbol_,uint8 decimals_, uint256 tokenSupply_,uint payValue_) payable public onlyMembersOrPay('createToken') returns(standardToken tokenAddress) {
        _addPayInfo('createToken',payValue_) ;
        return new standardToken(name_,symbol_,decimals_,tokenSupply_,msg.sender);
    }


}