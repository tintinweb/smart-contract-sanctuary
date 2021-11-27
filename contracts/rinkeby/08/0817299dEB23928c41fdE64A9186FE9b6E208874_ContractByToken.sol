pragma solidity 0.8.10;

interface getContractInterface {
     function getStudentsList() external view returns (string[] memory); 
}

interface priceConsumerV3Inreface {
     function getLatestPrice() external view returns (int256);
}

interface ERC20interface {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
}

contract ContractByToken {
  address studentContract=0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
  address priceContract=0x71503b94560dC301E723aBcAbe412624A7402d32;
  address tokenAddress=0xd97FdBe93FADc43e1D1ef881E1Af1136fa6634dF;
  
  function getNum() public view returns(uint) {
  uint lengthArr = getContractInterface(studentContract).getStudentsList().length;
  uint priceETH = uint256(priceConsumerV3Inreface(priceContract).getLatestPrice());
  uint priceOfToken = (priceETH / lengthArr);
  return priceOfToken;
  }

  function getContractBalance() public view returns(uint) {
        return ERC20interface(tokenAddress).balanceOf(address(this))/10*10**18;
    }
  
  receive() external payable {
    uint _bal = getContractBalance();
    uint _sumToken = (msg.value/getNum())*10**10;

        if(_bal >= _sumToken) {
            ERC20interface(tokenAddress).transfer(msg.sender, _sumToken);
        } else {
            (bool sent, bytes memory data) = msg.sender.call{ value: msg.value }("Sorry, there is not enough tokens to buy");
        }
  }

}