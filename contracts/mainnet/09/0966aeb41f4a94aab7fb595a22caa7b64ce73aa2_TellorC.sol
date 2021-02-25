/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity ^0.5.0;

contract TellorWrapper {
    function balanceOf(address _user) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    
    function withdrawStake() external;
    function getUintVar(bytes32 _data) public view returns (uint256);
}

contract TellorC {
    address private tellor = 0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5;

    bytes32 constant slotProgress = 0x6c505cb2db6644f57b42d87bd9407b0f66788b07d0617a2bc1356a0e69e66f9a; // keccak256("slotProgress")
    address private owner;
    address private miner;
    
    constructor () public {
        owner = msg.sender;
    }
    
    function changeMiner(address _addr) external {
        require(msg.sender == owner);
        
        miner = _addr;
    }

    function withdrawTrb(uint256 _amount) external {
        require(msg.sender == owner);

        TellorWrapper(tellor).transfer(msg.sender, _amount);
    }

    function withdrawEth(uint256 _amount) external {
        require(msg.sender == owner);

        msg.sender.transfer(_amount);
    }

    function depositStake() external {
        require(msg.sender == owner);

        TellorC(tellor).depositStake();
    }

    function requestStakingWithdraw() external {
        require(msg.sender == owner);

        TellorC(tellor).requestStakingWithdraw();
    }

    // Use finalize() if possible
    function withdrawStake() external {
        require(msg.sender == owner);

        TellorC(tellor).withdrawStake();
    }

    function finalize() external {
        require(msg.sender == owner);

        TellorWrapper(tellor).withdrawStake();
        uint256 _balance = TellorWrapper(tellor).balanceOf(address(this));
        TellorWrapper(tellor).transfer(msg.sender, _balance);
        selfdestruct(msg.sender);
    }

    function submitMiningSolution(string calldata _nonce,uint256[5] calldata _requestId, uint256[5] calldata _value) external {
        require(msg.sender == miner || msg.sender == owner, "Unauthorized");
        require(gasleft() > 1000000 || TellorWrapper(tellor).getUintVar(slotProgress) < 4, 'X');

        TellorC(tellor).submitMiningSolution(_nonce, _requestId, _value);
    }
    
    function() external {
        require(msg.sender == address(0), "Not allowed"); // Dont allow actual calls, only views
        
        address addr = tellor;
        bytes memory _calldata = msg.data;
        assembly {
            let result := call(not(0), addr, 0, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}