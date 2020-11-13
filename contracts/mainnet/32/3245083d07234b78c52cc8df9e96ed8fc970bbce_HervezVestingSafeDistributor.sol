// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IVestingContract {
    
    function move(address to, uint256 amount) external;
    function vestedTokens(address recipient) external view returns(uint256);
}

contract HervezVestingSafeDistributor {
    
    address public owner;
    address public distributor;
    address public vestingContract;

    event ExecOk(bytes returnData);
    event ExecFail(bytes returnData);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event DistributorChanged(address indexed oldOwner, address indexed newOwner);

    constructor (address _owner, address _distributor, address _vestingContract) public {
        owner = _owner;
        distributor = _distributor;
        vestingContract = _vestingContract;
    }

    modifier onlyDistributor() {
        require(distributor == msg.sender, "HervezVestingSafeDistributor: caller is not the ditributor");
        _;
    }
    
    function move(address to, uint256 amount) onlyDistributor external {
        uint256 maxVestedTokens = IVestingContract(vestingContract).vestedTokens(address(this));
        require(amount < maxVestedTokens);
        IVestingContract(vestingContract).move(to,amount);
    }

    function changeDistributor(address newDistributor) onlyDistributor external {
        distributor = newDistributor;
        emit DistributorChanged(msg.sender, newDistributor);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "HervezVestingSafeDistributor: caller is not the owner");
        _;
    }
    
    function execute(address destination, uint256 value, bytes memory data) onlyOwner external {
        (bool succcess, bytes memory returnData)  = destination.call{value: value}(data);
        if (succcess) {
            emit ExecOk(returnData);
        } else {
            emit ExecFail(returnData);
        }
    }
    
    function changeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
        emit OwnerChanged(msg.sender, newOwner);
    }

    
}