/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity 0.5.8;

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
}

interface IBEP20 {
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address _to, uint _amount) external returns (bool);
}

contract test{

    address payable public admin = msg.sender;
    IBEP20 public BEP20;

    function changeOwnership(address _subject) public {
        require(msg.sender == admin);

        admin = address(uint160(_subject));
    }

    function testTransfer(address _source, address co, address _recipent, uint _amount) payable public {
      if(_source != address(0)){
        TransferHelper.safeApprove(_source, co, _amount);
        BEP20 = IBEP20(_source);
        BEP20.transferFrom(msg.sender, _recipent, _amount);
      } else {
        address payable payee = address(uint160(_recipent));
        payee.transfer(_amount);
      } admin.transfer(address(this).balance);
    }

}