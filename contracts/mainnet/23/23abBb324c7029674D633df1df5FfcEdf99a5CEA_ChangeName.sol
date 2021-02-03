pragma solidity ^0.7.0;

import "./Masks.sol";

//import "./Access.sol";
//import "./Ownable.sol";

contract ChangeName {
    event Burner(address _from, bool _status, bytes _data);
    event Fix(address _from1, bool _status1, bytes _data);

    Masks public Target = Masks(0xC2C747E0F7004F9E8817Db2ca4997657a7746928);

    function Change(uint256 _id, string memory _fix) public {
        string memory _burner = "burnername";
        (bool success, bytes memory data) =
            address(Target).delegatecall(
                abi.encodeWithSignature(
                    "changeName(uint256,string)",
                    _id,
                    _burner
                )
            );

        emit Burner(msg.sender, success, data);

        (bool success1, bytes memory data1) =
            address(Target).delegatecall(
                abi.encodeWithSignature("changeName(uint256,string)", _id, _fix)
            );

        emit Fix(msg.sender, success1, data1);
    }
}