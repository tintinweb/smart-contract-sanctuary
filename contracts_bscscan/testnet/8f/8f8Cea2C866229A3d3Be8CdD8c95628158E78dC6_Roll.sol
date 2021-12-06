pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Roll {
    address public manager;
    address public lastWinner;
    uint8 public lastWinningNumber;
    address[] public players;
    
  receive() payable external {} 


     function enterThePlayer(address _tokenContract,address sender, uint256 amount) external{
       require(amount>=100000000000000000);
       IERC20 tokenContract = IERC20(_tokenContract);
       tokenContract.transferFrom(sender, address(this), amount);
       players.push(msg.sender);
     }


function emergencyWidthdraw(address _tokenContract,uint256 amount) public restricted {
   IERC20 tokenContract = IERC20(_tokenContract);
   tokenContract.transfer(msg.sender, amount);
}

    function pickWinner(address _tokenContract) public restricted {
      uint index=uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))) % players.length;
      IERC20 tokenContract = IERC20(_tokenContract);
      uint256 _amountToPlayer =(tokenContract.balanceOf(address(this))*80/100);
      uint256 _amountToBurn =(tokenContract.balanceOf(address(this))*20/100);
      tokenContract.transfer(players[index], _amountToPlayer);
      tokenContract.transfer(0x000000000000000000000000000000000000dEaD, _amountToBurn);
      lastWinner=players[index];
      players=new address[](0);
    }

    modifier restricted(){
      require (msg.sender==0x7d477dd546090EBF7dB262ED23CAb058623B97b8);
      _;
    }

}