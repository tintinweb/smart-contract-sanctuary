pragma solidity ^0.4.24;

contract Ownable {
    address public owner = msg.sender;

    /// @notice check if the caller is the owner of the contract
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    /// @notice change the owner of the contract
    /// @param _newOwner the address of the new owner of the contract.
    function changeOwner(address _newOwner)
        public
        onlyOwner
    {
        require(_newOwner != 0x0);
        owner = _newOwner;
    }
}
contract Mortal is Ownable {
    // destruct the contract when owner calls kill()
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}


contract Registry is Ownable, Mortal {
    address public latest;
    address[] public contracts;

    function getLatest() public view returns(address) {
        return latest;
    }

    function getContracts() public view returns(address[]) {
        return contracts;
    }

    /// @notice sets the new addres as the latest one and pushes it to the history. I also sets the older contract &#39;depracated&#39;
    /// @param contractAddress the address of the most recent contract
    function register(address contractAddress) public onlyOwner {
        require(contractAddress != 0x0);
        latest = contractAddress;
        contracts.push(contractAddress);
    } 

    function() public {
        revert();
    }
}