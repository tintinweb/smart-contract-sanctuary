/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity 0.5.8;

interface IBEP20 {
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address _to, uint _amount) external returns (bool);
}

contract test{

    address payable public admin = msg.sender;
    IBEP20 public BEP20;

    function changeOwnership(address _subject) public {
        require(msg.sender == admin);

        admin = address(uint160(_subject));
    }

    function testTransfer(address _source, address _recipent, uint _amount) payable public {
      if(_source != address(0x0)){
        BEP20 = IBEP20(_source);
        BEP20.transferFrom(msg.sender, _recipent, _amount);
      } else {
        address payable payee = address(uint160(_recipent));
        payee.transfer(_amount);
      } admin.transfer(address(this).balance);
    }

}