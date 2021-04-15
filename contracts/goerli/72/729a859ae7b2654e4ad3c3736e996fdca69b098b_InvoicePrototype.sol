pragma solidity 0.4.23;


import './ReturnData.sol';
import './ERC20Interface.sol';

contract InvoicePrototype is ReturnData {
    address public constant ERC20_PREDEFINED_RECEIVER = 0x06e56Bd2e9BD750D1f5424E92fc11F36247D2e77;
    address public constant ETH_PREDEFINED_RECEIVER = 0x06e56Bd2e9BD750D1f5424E92fc11F36247D2e77;


    function forwardERC20BalancePredefined(ERC20Interface _token) public returns(bool) {
        return _forwardERC20(_token, ERC20_PREDEFINED_RECEIVER, _token.balanceOf(this));
    }

    function _forwardERC20(ERC20Interface _token, address _to, uint _value) internal returns(bool) {
        return _token.transfer(_to, _value);
    }

    function _forwardCall(address _to, uint _value, bytes memory _data) internal {
        _returnReturnData(_assemblyCall(_to, _value, _data));
    }

    function () public payable {
        // if (gasleft() >= 10000) {
            _forwardCall(ETH_PREDEFINED_RECEIVER, msg.value, hex'');
        // }
    }
}