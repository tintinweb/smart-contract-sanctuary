/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface InterfaceDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
}

contract Representatives {
    address DIGI;
    address public tokenAddress;
    uint representativeMin;
    uint repMaturation;
    mapping(address => Representative )  public registeredReps;


    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }

    Representative[] public representatives;

    constructor() {
        DIGI == msg.sender;
        repMaturation = 300000; //around 30 days Ropsten --- repMaturation = 1178064 on Polygon
        representativeMin = 10000 * 10 * 18; // 10000 Digitrade
    }

    modifier onlyDIGI(){
        require(msg.sender == DIGI);
        _;
    }

    function setTokenAddress(address _digitrade) public onlyDIGI{
        tokenAddress = _digitrade;
    }

    function getUnlockBlock() public view returns (uint){
        return registeredReps[msg.sender]._unlockBlock;
    }

    function getStartBlock() public view returns (uint) {
        return registeredReps[msg.sender]._startBlock;
    }

    function getRep() public view returns (address _repAddress){
        if(msg.sender == registeredReps[msg.sender]._rep){
           _repAddress = msg.sender;
        }
        return _repAddress;

    }

    function getRepMin() public view returns (uint){
        return representativeMin;
    }

    function getMaturationTime() public view returns (uint) {
        return repMaturation;
    }

    function registerRep(address _rep) public {
      require(msg.sender == _rep);
      require(InterfaceDigi(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[_rep] = Representative(_rep,block.number, _unlockBlock);
    }

}