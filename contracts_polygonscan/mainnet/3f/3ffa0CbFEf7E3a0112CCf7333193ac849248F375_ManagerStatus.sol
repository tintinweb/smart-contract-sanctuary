/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

pragma solidity ^0.6.12;

interface IFund {
    function owner() external view returns(address);
}

contract ManagerStatus {
    mapping(address => string) public statuses;

    event StatusUpdated(
        address id,
        string content
    );


    function updateStatus(address _fundAddress, string memory _content) public {
        // require valid content
        require(bytes(_content).length > 0, "Not valid content");
        // check permission
        require(IFund(_fundAddress).owner() == msg.sender, "Not owner");
        // update status
        statuses[_fundAddress] = _content;
        // Trigger event
        emit StatusUpdated(_fundAddress, _content);
    }
}