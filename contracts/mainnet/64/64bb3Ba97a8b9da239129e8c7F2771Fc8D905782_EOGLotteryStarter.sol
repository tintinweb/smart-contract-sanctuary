////////////////////////////////////////////////////
//******** In the name of god **********************
//******** https://Helixnebula.help  ***************
////p2p blockchain based helping system/////////////
////////////Lottery Starter ////////////////////////
//This is an endless profitable cycle for everyone//
////Contact us: support@helixnebula.help////////////
////////////////////////////////////////////////////

pragma solidity ^0.5.0;
contract EOGLotteryInterface {

    function transferOwnership(address payable _newOwner) external;
    function StartLottery() external;
}

contract EOGInterface {
    function GetEOGPrice() public view returns(uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract EOGLotteryStarter
{
    address EOGLotteryAddress=0x35488195F26570a8FE0043e47186b0BC5681FE89;
    address EOGAddress=0x8Ae6AE8F172d7fc103CCfa5890883d6fE46038C9;
    address DeployerAddress=0xaFE98947D4603e6E70883CfDCDc7E4bD56d31794;
    function transferOwner(address payable _newOwner) external{
            require(msg.sender==DeployerAddress);
            EOGLotteryInterface(EOGLotteryAddress).transferOwnership(_newOwner);
    }
    
    function IsStartAvailable(address _adr) public view returns(bool){
        
        if( EOGInterface(EOGAddress).balanceOf(_adr)>500*10**18){   //Anyone who has more than 500 EOG can start the lottery.
            return true;
        }
        if(EOGInterface(EOGAddress).GetEOGPrice()> 5 * 10**17){ //When the price of each eog exceeds 0.5 Ethereum, anyone who has more than 50 EOG can start the lottery.
            return true;
        }
        if(block.timestamp>1604164560){  //When the date passes from October 31th of 2020, anyone with more than 50 EOG can start the lottery.
            return true;
        }
        return false;
    }
    function StartLottery() external{
        require(EOGInterface(EOGAddress).balanceOf(msg.sender)>50*10**18,"Not enough EOG");
        require(IsStartAvailable(msg.sender),"Not enough EOG");
        EOGLotteryInterface(EOGLotteryAddress).StartLottery();
    }
    
}