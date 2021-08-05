/**
 *Submitted for verification at Etherscan.io on 2020-12-26
*/

pragma solidity >=0.6.8 <0.8.0;


contract Ownable {
    address private _owner;

    constructor() internal {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }
}

interface ITellor {
    function addTip(uint256 _requestId, uint256 _tip) external;
    function submitMiningSolution(string calldata _nonce, uint256[5] calldata _requestId, uint256[5] calldata _value) external;
    function depositStake() external;

    function requestStakingWithdraw() external;

    function withdrawStake() external;

    function getUintVar(bytes32 _data) external view returns (uint256);

    function vote(uint256 _disputeId, bool _supportsDispute) external;

    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract TellorProxy is Ownable {
    address tellorAddress;

    constructor(address _tellorAddress)
        public
    {
        tellorAddress = _tellorAddress;
    }

    function addTip(uint256 _requestId, uint256 _tip) external onlyOwner {
        ITellor(tellorAddress).addTip(_requestId, _tip);
    }

    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value,
        uint256 _pass
    ) external onlyOwner {
        if (_pass == 0) {
            bytes32 slotProgress =
                0x6c505cb2db6644f57b42d87bd9407b0f66788b07d0617a2bc1356a0e69e66f9a;
            uint256 _soltNum = ITellor(tellorAddress).getUintVar(slotProgress);
            require(_soltNum != 4, "haha");
        }
        ITellor(tellorAddress).submitMiningSolution(_nonce, _requestId, _value);
    }

    function depositStake() external onlyOwner {
        ITellor(tellorAddress).depositStake();
    }

    function requestStakingWithdraw() external onlyOwner {
        ITellor(tellorAddress).requestStakingWithdraw();
    }

    function payment(address _to, uint256 _amount) external onlyOwner {
        ITellor(tellorAddress).transfer(_to, _amount);
    }
    
    function getSlotProgress() external view returns (uint256) {
        bytes32 slotProgress =
            0x6c505cb2db6644f57b42d87bd9407b0f66788b07d0617a2bc1356a0e69e66f9a;
        return ITellor(tellorAddress).getUintVar(slotProgress);
    }

    function withdrawStake() external onlyOwner {
        ITellor(tellorAddress).withdrawStake();
    }

    function vote(uint256 _disputeId, bool _supportsDispute)
        external
        onlyOwner
    {
        ITellor(tellorAddress).vote(_disputeId, _supportsDispute);
    }
}