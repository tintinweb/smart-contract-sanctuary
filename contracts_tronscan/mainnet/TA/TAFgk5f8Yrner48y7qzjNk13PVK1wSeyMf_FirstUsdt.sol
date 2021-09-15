//SourceUnit: FirstUsdt.sol

pragma solidity ^0.4.25;

contract FirstUsdt {

    bool public stopped = false;
    address owner;
    address cTokenAddr = 0xA614F803B6FD780986A42C78EC9C7F77E6DED13C;

    constructor() public {
        owner=msg.sender;
    }

    event Withdraw(address indexed _from,  uint indexed _value);

    function withdraw(uint256 _value,address _to) public onlyOwner isRunning  validAddress returns (bool sucess) {
        bytes4 transferMethodId = bytes4(keccak256("transfer(address,uint256)"));
        if(cTokenAddr.call(transferMethodId,_to, _value)){
            emit Withdraw(_to,_value);
            return true;
        }
        return false;
    }


    function stop(address _to) public onlyOwner returns (bool sucess) {
        stopped = true;
       return true;
    }

    function () payable public {
        revert();
    }

    function start() public onlyOwner {
        stopped = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier isRunning {
        require(!stopped);
        _;
    }
    modifier validAddress {
        require(address(0) != msg.sender);
        _;
    }
}