// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol" ;


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

interface iPayAPI {
    function payStatus(string memory payName_ ,address user_) external view returns(bool) ;
    function _addPayInfo(string memory payName_,address user_, uint money_) external  returns(bool)  ;
    function _payStandard(string memory payName_) external view returns(uint) ;
}


contract multiToolsV1  {
    address private payContract = 0x9d7C19dfa9EA7AB4bdfA7341874430aB10F728E3;
    iPayAPI payAPI = iPayAPI(payContract) ;

	function multiTransferToken(address token_,address[] calldata addr_,uint[] calldata amount_) payable external returns(bool) {
		bool payStatus = payAPI.payStatus('tranferToken',msg.sender);
        if (!payStatus){
            uint money = payAPI._payStandard('tranferToken') ;
            require(msg.value >= money) ;
            payable(payContract).transfer(msg.value) ;
            payAPI._addPayInfo('tranferToken',msg.sender,msg.value) ;
        }
        for(uint i; i < addr_.length; i++){
            TransferHelper.safeTransferFrom(token_,msg.sender,addr_[i],amount_[i]) ;
        }
        return true ;
	}


    function viewPayStauts(string memory payName_,address user_) public view returns(bool){
        return payAPI.payStatus(payName_,user_);
    }

    function multiTransferETH(address[] calldata addr_,uint[] calldata value_) payable external returns(bool){
        bool payStatus = payAPI.payStatus('transferETH',msg.sender);
        if (!payStatus){
            uint money = payAPI._payStandard('transferETH') ;
            require(msg.value >= money) ;
            payable(payContract).transfer(money) ;
            payAPI._addPayInfo('transferETH',msg.sender,money) ;
        }
        for(uint i; i < addr_.length; i++){
			payable(addr_[i]).transfer(value_[i]) ;
		}
        return true ;
    }

    receive() external payable {
        
    }

    function createToken(string memory name_, string memory symbol_,uint8 decimals_, uint256 tokenSupply_) payable public  returns(standardToken tokenAddress) {
        bool payStatus = payAPI.payStatus('createToken',msg.sender);
        if (!payStatus){
            uint money = payAPI._payStandard('createToken') ;
            require(msg.value >= money) ;
            payable(payContract).transfer(msg.value) ;
            payAPI._addPayInfo('createToken',msg.sender,msg.value) ;
        }
        return new standardToken(name_,symbol_,decimals_,tokenSupply_,msg.sender);
    }


}