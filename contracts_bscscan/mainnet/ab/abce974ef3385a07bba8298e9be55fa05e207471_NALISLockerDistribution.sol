// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// website : https://koaladefi.finance/
// twitter : https://twitter.com/KoalaDefi

import "./Address.sol";
import "./SafeBEP20.sol";
import "./SafeMath.sol";
import "./ILocker.sol";

contract NALISLockerDistribution {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Locker interface
    ILocker nalisLocker;

    address public nalis;

    uint256 public startReleaseBlock;
    uint256 public endReleaseBlock;

    uint256 private _totalLock;
    mapping(address => uint256) private _locks;
    mapping(address => uint256) private _released;

    //event Lock(address indexed to, uint256 value);

    constructor(
        address _nalis,
        uint256 _startReleaseBlock,
        uint256 _endReleaseBlock,
        address _nalisLockerAddress
    ) public {
        require(_endReleaseBlock > _startReleaseBlock, "endReleaseBlock < startReleaseBlock");
        nalis = _nalis;
        startReleaseBlock = _startReleaseBlock;
        endReleaseBlock = _endReleaseBlock;
        nalisLocker = ILocker(_nalisLockerAddress);
    }

    function totalLock() external view returns (uint256) {
        return _totalLock;
    }
    
    function getStartReleaseBlock() external view returns (uint256) {
        return startReleaseBlock;
    }    

    function lockOf(address _account) external view returns (uint256) {
        return _locks[_account];
    }

    function released(address _account) external view returns (uint256) {
        return _released[_account];
    }

/*
    function lock(address _account, uint256 _amount) external {
        require(block.number < startReleaseBlock, "no more lock");
        require(_account != address(0), "no lock to address(0)");
        require(_amount > 0, "zero lock");

        IBEP20(nalis).safeTransferFrom(msg.sender, address(this), _amount);

        _locks[_account] = _locks[_account].add(_amount);
        _totalLock = _totalLock.add(_amount);

        emit Lock(_account, _amount);
    }*/
    
    
    // Transfer lock amount from previous contract
    function transferLock(address _account) public {   
        require(_locks[_account] == 0, "transferLock : lock amount already transfered");
        
        _locks[_account] = ILocker(nalisLocker).lockOf(msg.sender);
        _totalLock = _totalLock.add(_locks[_account]);
    
    }

    function canUnlockAmount(address _account) public view returns (uint256) {
        if (block.number < startReleaseBlock) {
            return 0;
        } else if (block.number >= endReleaseBlock) {
            return _locks[_account].sub(_released[_account]);
        } else {
            uint256 _releasedBlock = block.number.sub(startReleaseBlock);
            uint256 _totalVestingBlock = endReleaseBlock.sub(startReleaseBlock);
            return _locks[_account].mul(_releasedBlock).div(_totalVestingBlock).sub(_released[_account]);
        }
    }

    function unlock() external {
        require(block.number > startReleaseBlock, "still locked");
        require(_locks[msg.sender] > _released[msg.sender], "no locked");

        uint256 _amount = canUnlockAmount(msg.sender);

        IBEP20(nalis).safeTransfer(msg.sender, _amount);
        _released[msg.sender] = _released[msg.sender].add(_amount);
        _totalLock = _totalLock.sub(_amount);
    }

}