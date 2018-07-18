pragma solidity ^0.4.0;

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract MNY {
    function mine(address token, uint amount) public;
}

contract mnyminer {
    
    address mny = 0xD2354AcF1a2f06D69D8BC2e2048AaBD404445DF6;
    address futx = 0x8b7d07b6ffB9364e97B89cEA8b84F94249bE459F;
    address futr = 0xc83355eF25A104938275B46cffD94bF9917D0691;

    function futrMiner() public payable {
        require(futr.call.value(msg.value)());
        uint256 mined = ERC20(futr).balanceOf(address(this));
        ERC20(futr).approve(mny, mined);
        MNY(mny).mine(futr, mined);
        uint256 amount = ERC20(mny).balanceOf(address(this));
        ERC20(mny).transfer(msg.sender, amount);
    }
    
    
    function futxMiner() public payable {
        require(futx.call.value(msg.value)());
        uint256 mined = ERC20(futx).balanceOf(address(this));
        ERC20(futx).approve(mny, mined);
        MNY(mny).mine(futx, mined);
        uint256 amount = ERC20(mny).balanceOf(address(this));
        ERC20(mny).transfer(msg.sender, amount);
    }
}