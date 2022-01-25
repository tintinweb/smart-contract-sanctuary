/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity 0.8.11;

contract Test {

    event Updated(uint256[] indexed list, address[] indexed access);

    event Post(address indexed poster, string message);

    event NewBoard(uint256 indexed board);

    event TestPost(address indexed poster, string indexed message);

    function NewPost(string memory message) public {
        emit Post(msg.sender, message);
    }

    function CreateBoard(uint256 i) public {
        emit NewBoard(i);
    }

    function NewTestPost(string memory message) public {
        emit TestPost(msg.sender, message);
    }

    function Update(uint256[] memory wl, address[] memory access) public {
        emit Updated(wl, access);
    }

}