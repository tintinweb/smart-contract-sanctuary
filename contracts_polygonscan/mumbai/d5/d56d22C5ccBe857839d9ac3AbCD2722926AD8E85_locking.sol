//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address x) external returns (uint);
    function transferFrom(address owner, address target, uint256 amount) external returns (bool);
    function transfer(address target, uint256 amount) external returns (bool);
}

contract locking {

    struct Lock {
        uint256 releaseRequest;
        uint256 amount;
        bool    locked;
    }

    address public   contractOwner;

    IERC20  public   baseToken;
   
    uint256 public   amountToken;
    

    mapping(address => Lock) public LockData;

    event LockedBaseToken(address owner, uint256 amount);
    

    
    event WithdrawBaseTokens(address owner, uint256 amount);

    event UnlockRequested(address owner);
    event UnlockCancelled(address owner);

    event SetLockAmount(uint256 amountTokenP);

    constructor (IERC20 _baseToken, uint256 _amountToken) {
        contractOwner  = msg.sender;
        baseToken   = _baseToken;
        
        updateLockAmount(_amountToken);
    }

    function lock() external {
        if (LockData[msg.sender].releaseRequest != 0) {
            LockData[msg.sender].releaseRequest = 0;
            emit UnlockCancelled(msg.sender);
            return;
        }
        uint256 _amount = amountToken;
        require(baseToken.transferFrom(msg.sender, address(this), _amount),"transfer failed");
        internalLock(msg.sender,_amount);
    }

    function internalLock(address _sender, uint256 _amount) internal {
        Lock memory ld = LockData[_sender];
        require(!ld.locked,"You already have locked tokens");
        ld.locked = true;
        ld.amount = _amount;
        LockData[_sender] = ld;
        emit LockedBaseToken(_sender,_amount);
        return;
    }

    function unlock() external {
        Lock memory ld = LockData[msg.sender];
        require(ld.locked,"You do not have locked tokens");
        require (ld.amount != 0,"Nothing to unlock"); 
        uint releaseDate = ld.releaseRequest;
        if(releaseDate != 0) {
            require(releaseDate <= block.timestamp, "release already requested but not ready");
            baseToken.transfer(msg.sender,ld.amount);
            LockData[msg.sender].releaseRequest = 0;
            LockData[msg.sender].amount = 0;
            LockData[msg.sender].locked = false;
            emit WithdrawBaseTokens(msg.sender,ld.amount);
            return;
        }
        LockData[msg.sender].releaseRequest = block.timestamp + 5 days;
        emit UnlockRequested(msg.sender);
        return;
    }

    function updateLockAmount(uint256 _amountToken) public {
        require(msg.sender == contractOwner,"Unauthorised access");
        amountToken = _amountToken;
        emit SetLockAmount(_amountToken);
    }
 
    function isLocked(address owner) external view returns (bool) {
        return LockData[owner].locked && (LockData[owner].releaseRequest == 0);
    }

    function timeToWithdraw(address owner) external view returns (uint256) {
        require(LockData[owner].locked,"Owner has no funds locked");
        uint256 releaseTime = LockData[owner].releaseRequest;
        require(releaseTime != 0,"Owner has not requested funds release");
        if (releaseTime >= block.timestamp) return 0;
        return (block.timestamp - releaseTime);
    }

    function drain(IERC20 token) external  {
        require(msg.sender == contractOwner,"Unauthorised");
        if (address(token) == 0x0000000000000000000000000000000000000000) {
            payable(contractOwner).transfer(address(this).balance);
        } else {
            require(token != baseToken, "You cannot withdraw the base token");
            token.transfer(contractOwner,token.balanceOf(address(this)));
        }
    }

    function onTokenTransfer(address _sender, uint _value, bytes memory ) external {
        require(msg.sender == payable(address(baseToken)),"Unauthorised source");
        require(_value == amountToken, "Incorrect value sent");
        internalLock(_sender,_value);
    }

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}