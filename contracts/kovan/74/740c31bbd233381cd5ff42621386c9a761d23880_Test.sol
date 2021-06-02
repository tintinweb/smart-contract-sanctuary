/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity 0.6.12;

contract Test {
    uint256 public value;
    bytes public report;
    bytes32[] public rs;
    bytes32[] public ss;
    bytes32 public rawVs;
    
    event ValueSet(uint256 indexed _value, int256 indexed _value2, string _description, bytes4 _somethingElse);


    function setValue(uint256 _value, int _value2, string calldata _description, bytes4 _some) external{
        value = _value;
        emit ValueSet(_value, _value2, _description, _some);
    }

    function getValue() external view returns(uint256){
        return value;
    }

    function transmit(
        bytes calldata _report,
        bytes32[] calldata _rs,
        bytes32[] calldata _ss,
        bytes32 _rawVs
    ) external{
        report = _report;
        rs = _rs;
        ss = _ss;
        rawVs = _rawVs;
    }
}